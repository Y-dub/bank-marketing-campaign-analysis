# Tableau Public build guide: Campaign Performance dashboard

Two dashboards, built from the files `run_analysis.py` writes:

| Dashboard | Worksheets |
| --- | --- |
| **1. Campaign performance** | 5 KPI cards, Volume vs conversion timeline, Mobile vs landline |
| **2. Contact strategy and targeting** | Calls per subscription by contact, Call-cap scenarios, Previous outcome by year, Age lift, Targeting quintiles |

Run `python download_data.py` and `python run_analysis.py` first. Checkpoint values are given in
**bold** so you can confirm each step.

Tableau tidies field names on screen (`contacts_this_campaign` shows as **Contacts This
Campaign**). The formulas below use the on-screen names.

---

## 1. Connect the data

1. Tableau Public → **Connect → Text file** → `tableau_data/contacts.csv`.
2. On the Data Source tab, check the types:
   - `Campaign Month` → **Date** (calendar icon). If it shows Abc, click the icon → Date.
   - `Record Id`, `Campaign Year`, `Converted` → Number (whole). Then click the type icon on
     **Campaign Year** → **String**, so it acts as a category, not a number to add up.
   - `Contact Band` → String.
3. Add the two small result files as **separate data sources** (from a worksheet: **Data → New Data
   Source → Text file**): `outputs/04_call_cap_scenarios.csv` and `outputs/09_targeting_score.csv`.
   Do not drag them onto the first source's canvas.

## 2. Calculated fields (in the `contacts` source)

Select `contacts` in the Data pane, then **Analysis → Create Calculated Field** for each:

| Name | Formula | Format |
| --- | --- | --- |
| `Clients` | `COUNT([Record Id])` | Number, 0 dp, thousands separator |
| `Calls` | `SUM([Contacts This Campaign])` | Number, 0 dp |
| `Subscriptions` | `SUM([Converted])` | Number, 0 dp |
| `Conversion rate` | `SUM([Converted]) / COUNT([Record Id])` | Percentage, 1 dp |
| `Calls per subscription` | `SUM([Contacts This Campaign]) / SUM([Converted])` | Number, 1 dp |
| `Year conversion rate` | `{ FIXED [Campaign Year] : SUM([Converted]) / COUNT([Record Id]) }` | Percentage, 1 dp |
| `Lift vs year` | `AVG([Converted] / [Year conversion rate])` | Number, 2 dp |
| `Within 3 contacts` | `IF [Contacts This Campaign] <= 3 THEN "1-3 contacts" ELSE "4 or more" END` | |

To set a default format: right-click the field in the Data pane → **Default Properties → Number Format**.

**Sort Contact Band properly:** right-click `Contact Band` → **Default Properties → Sort → Manual**,
then order: `1, 2, 3, 4-5, 6-9, 10+`. (Alphabetical order would put 10+ second.)

## 3. Worksheets for dashboard 1

**KPI cards (5 sheets).** For each: new sheet, drag the measure to **Text** on the Marks card,
set the font to about 28 pt bold, and add a smaller label line via **Text → ...** above it.
Name the sheets `KPI Clients`, `KPI Calls`, and so on.

| Sheet | Measure | Checkpoint (all years) |
| --- | --- | --- |
| KPI Clients | `Clients` | **41,188** |
| KPI Calls | `Calls` | **105,754** |
| KPI Subscriptions | `Subscriptions` | **4,640** |
| KPI Conversion | `Conversion rate` | **11.3%** |
| KPI Calls per subscription | `Calls per subscription` | **22.8** |

**Volume vs conversion timeline** (the "month trap" chart)
1. Drag `Campaign Month` to Columns. Click its arrow → choose the **second** "Month" (the one showing
   *May 2015*, continuous, green).
2. Drag `Clients` to Rows. Marks: **Bar**, colour light grey.
3. Drag `Conversion rate` to Rows, to the right of `Clients`. Right-click its axis → **Dual Axis**.
   On its Marks card choose **Line**, colour red, size thicker.
4. Checkpoint: bars of about **7,763** in May 2008 falling to about **128** in November 2010; the line
   rising from **3.1%** to around **45–57%**.
5. Title: *Volume fell 93% while conversion rose tenfold: high-conversion months are small, late months*.

**Mobile vs landline**
1. `Campaign Year` to Columns, `Channel` to Columns (to the right), `Conversion rate` to Rows.
2. `Channel` to Color. Show mark labels (toolbar **T** button).
3. Checkpoint: 2009 **19.9% vs 14.6%**, 2010 **57.7% vs 28.4%**, 2008 **5.7% vs 3.9%**.

## 4. Worksheets for dashboard 2

**Calls per subscription by contact**
1. `Contact Band` to Columns, `Calls per subscription` to Rows. Marks: Bar.
2. `Within 3 contacts` to Color: blue for 1-3, orange for 4 or more. Show labels.
3. Checkpoint: **7.7, 17.5, 27.9, 50.4, 109.0, 418.6**.
4. Title: *Each extra attempt costs more: 8 calls per subscription on the first contact, 419 after ten*.

**Call-cap scenarios** (source: `04_call_cap_scenarios`)
1. Switch to that data source. `Max Contacts` → right-click → **Convert to Dimension**, then to Columns.
2. `Measure Names` to Filters → keep only **Calls Saved Pct** and **Subscriptions At Risk Pct**.
   `Measure Names` to Columns (after Max Contacts), `Measure Values` to Rows, `Measure Names` to Color.
3. Checkpoint at cap 3: **26.5** saved vs **12.0** at risk.
4. Title: *A cap of 3 contacts cuts 26.5% of calls and risks at most 12% of subscriptions*.

**Previous outcome by year**
1. Back to `contacts`. `Campaign Year` to Columns, `Prior Outcome` to Rows, `Conversion rate` to
   Color and Label. Marks: **Square** (a heat table).
2. Checkpoint, "Said yes before": **8.6%, 56.8%, 77.0%**; "New prospect": **4.9%, 18.7%, 44.8%**.

**Age lift**
1. `Age Band` to Columns, `Lift vs year` to Rows, Bar, labels on.
2. Right-click the axis → **Add Reference Line** → constant **1**, label "Year average".
3. Checkpoint: **18-24 1.35, 25-34 1.06, 35-44 0.91, 45-54 0.88, 55-64 1.13, 65+ 1.74**.

**Targeting quintiles** (source: `09_targeting_score`)
1. `Priority Quintile` → Convert to Dimension → Columns. `Conversion Pct` to Rows, Bar, labels on.
2. Add a constant reference line at **52.1** labelled "2010 average".
3. Checkpoint: **80.6, 56.6, 58.5, 33.8, 31.1**.
4. Title: *Score learned on 2008-09, tested on unseen 2010 clients: top fifth 80.6% vs bottom 31.1%*.

## 5. Assemble the dashboards

1. **New Dashboard** → Size: **Fixed, 1200 × 900** (Automatic stretches badly on Tableau Public).
2. Dashboard 1, "Campaign performance": a horizontal container at the top with the five KPI sheets,
   the timeline full width below, Mobile vs landline at the bottom.
3. Dashboard 2, "Contact strategy and targeting": a 2 × 2 grid of Calls per subscription, Call-cap
   scenarios, Previous outcome, Targeting quintiles, with Age lift beneath.
4. Year filter on dashboard 1: on the timeline sheet, right-click `Campaign Year` in the Data pane →
   **Show Filter**. Then on the filter's arrow → **Apply to Worksheets → All Using This Data Source**.
   Check: selecting **2009** makes the KPIs read **11,440 / 24,320 / 2,228 / 19.5% / 10.9**.
5. Navigation: drag **Navigation** objects onto each dashboard for the two pages (as in the Land
   Registry dashboard), and hide the worksheets: right-click each dashboard tab → **Hide All Sheets**.
6. Add a text box at the top of each dashboard with one line of context, for example: *41,188
   telemarketing contacts by a Portuguese bank, May 2008 to Nov 2010. Compare within a year: conversion
   rose from 5% to 52% as volume fell.*

## 6. Publish

**File → Save to Tableau Public**, title it *Bank Marketing Campaign Analysis*. After it opens on your
profile, turn on **Show Sheets as Tabs** in the viz settings, copy the link into the README, and save
a screenshot of each dashboard to `docs/` for the README.
