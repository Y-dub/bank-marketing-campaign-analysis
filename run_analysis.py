"""Run every SQL file in sql/ in order against DuckDB, print each result and save it.

    python run_analysis.py                 # uses data/bank-additional-full.csv
    python run_analysis.py --csv path.csv

Writes outputs/<file>.csv for each analysis and tableau_data/contacts.csv (one row per client)
for the Tableau dashboard.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import duckdb
import pandas as pd

ROOT = Path(__file__).parent
SQL_DIR = ROOT / "sql"


def connect(csv_path: Path) -> duckdb.DuckDBPyConnection:
    con = duckdb.connect()
    con.execute("SET VARIABLE csv_path = $path", {"path": str(csv_path)})
    return con


def run_file(con: duckdb.DuckDBPyConnection, path: Path) -> pd.DataFrame | None:
    """Execute every statement in a file; return the result of the last one if it is a query."""
    statements = [s for s in con.extract_statements(path.read_text())]
    result = None
    for stmt in statements:
        result = con.execute(stmt)
    try:
        return result.df() if result is not None else None
    except duckdb.Error:  # last statement was DDL
        return None


def run_all(csv_path: Path, out_dir: Path | None = None, quiet: bool = False) -> dict[str, pd.DataFrame]:
    con = connect(csv_path)
    results: dict[str, pd.DataFrame] = {}
    for path in sorted(SQL_DIR.glob("*.sql")):
        df = run_file(con, path)
        if df is None or path.stem.startswith("00_"):
            continue
        results[path.stem] = df
        if out_dir:
            (out_dir / "outputs").mkdir(parents=True, exist_ok=True)
            df.to_csv(out_dir / "outputs" / f"{path.stem}.csv", index=False)
        if not quiet:
            print(f"\n== {path.stem} ==")
            print(df.to_string(index=False))
    if out_dir:
        (out_dir / "tableau_data").mkdir(parents=True, exist_ok=True)
        con.execute("SELECT * FROM contacts ORDER BY record_id").df().to_csv(
            out_dir / "tableau_data" / "contacts.csv", index=False
        )
    results["contacts"] = con.execute("SELECT * FROM contacts ORDER BY record_id").df()
    return results


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv", type=Path, default=ROOT / "data" / "bank-additional-full.csv")
    args = parser.parse_args()
    if not args.csv.exists():
        raise SystemExit(f"{args.csv} not found: run `python download_data.py` first")
    run_all(args.csv, out_dir=ROOT)
    print("\nSaved outputs/*.csv and tableau_data/contacts.csv")


if __name__ == "__main__":
    main()
