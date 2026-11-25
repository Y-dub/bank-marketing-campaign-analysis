"""Checks on the SQL analysis.

The synthetic tests always run. The real-data tests run when data/bank-additional-full.csv exists
(locally after `python download_data.py`, and in CI, which downloads it first).
"""

from pathlib import Path

import pandas as pd
import pytest

from run_analysis import run_all

ROOT = Path(__file__).resolve().parents[1]
REAL = ROOT / "data" / "bank-additional-full.csv"

COLUMNS = (
    "age;job;marital;education;default;housing;loan;contact;month;day_of_week;duration;campaign;pdays;"
    "previous;poutcome;emp.var.rate;cons.price.idx;cons.conf.idx;euribor3m;nr.employed;y"
)


def _row(month: str, campaign: int, y: str, poutcome: str = "nonexistent", contact: str = "cellular") -> str:
    return (
        f'40;"admin.";"married";"high.school";"no";"no";"no";"{contact}";"{month}";"mon";100;{campaign};999;0;'
        f'"{poutcome}";1.1;93.9;-36.4;4.8;5191;"{y}"'
    )


@pytest.fixture()
def tiny_csv(tmp_path):
    # Two "years": may, jun, nov, then a new year starting in mar.
    rows = [
        _row("may", 1, "yes"), _row("may", 5, "no"), _row("jun", 2, "no"), _row("nov", 1, "no"),
        _row("mar", 1, "yes", "success"), _row("apr", 3, "yes"), _row("apr", 7, "no", contact="telephone"),
    ]
    path = tmp_path / "tiny.csv"
    path.write_text("\n".join([COLUMNS, *rows]) + "\n")
    return path


def test_year_inferred_from_row_order(tiny_csv):
    contacts = run_all(tiny_csv, quiet=True)["contacts"]
    assert contacts["campaign_year"].tolist() == [2008, 2008, 2008, 2008, 2009, 2009, 2009]
    assert str(contacts["campaign_month"].iloc[4])[:7] == "2009-03"


def test_cap_scenarios_arithmetic(tiny_csv):
    caps = run_all(tiny_csv, quiet=True)["04_call_cap_scenarios"].set_index("max_contacts")
    # contacts: 1,5,2,1,1,3,7 = 20 calls; capped at 3: 1,3,2,1,1,3,3 = 14
    assert caps.loc[3, "calls_now"] == 20
    assert caps.loc[3, "calls_with_cap"] == 14
    assert caps.loc[3, "calls_saved_pct"] == pytest.approx(30.0)


def test_prior_outcome_labels(tiny_csv):
    contacts = run_all(tiny_csv, quiet=True)["contacts"]
    assert set(contacts["prior_outcome"]) == {"New prospect", "Said yes before"}


real = pytest.mark.skipif(not REAL.exists(), reason="real data not downloaded")


@pytest.fixture(scope="module")
def results():
    return run_all(REAL, quiet=True)


@real
def test_real_data_shape_and_period(results):
    c = results["contacts"]
    assert len(c) == 41188
    assert (c["campaign_month"].min().strftime("%Y-%m"), c["campaign_month"].max().strftime("%Y-%m")) == (
        "2008-05",
        "2010-11",
    )


@real
def test_yearly_totals_add_up(results):
    y = results["02_overview_by_year"]
    assert y["clients_contacted"].sum() == 41188
    assert y["subscriptions"].sum() == results["contacts"]["converted"].sum() == 4640


@real
def test_headline_findings(results):
    cap3 = results["04_call_cap_scenarios"].set_index("max_contacts").loc[3]
    assert cap3["calls_saved_pct"] == pytest.approx(26.5)
    assert cap3["subscriptions_at_risk_pct"] == pytest.approx(12.0)

    prior = results["05_prior_outcome"]
    said_yes = prior[prior["prior_outcome"] == "Said yes before"]
    assert (said_yes["lift_vs_new_prospects"] > 1.5).all()  # holds within every year

    q = results["09_targeting_score"]
    assert q["clients"].sum() == 2058
    assert q.loc[0, "conversion_pct"] > 2 * q.loc[4, "conversion_pct"]


@real
def test_tableau_extract_has_no_missing_keys(results):
    c = results["contacts"]
    assert c[["record_id", "campaign_year", "campaign_month", "converted"]].notna().all().all()
    assert isinstance(c, pd.DataFrame)
