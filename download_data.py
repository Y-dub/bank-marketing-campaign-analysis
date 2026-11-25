"""Download the UCI Bank Marketing data (bank-additional-full.csv) into data/.

Source: Moro, S., Rita, P. & Cortez, P. (2014). Bank Marketing. UCI Machine Learning Repository.
https://doi.org/10.24432/C5K306 (CC BY 4.0)
"""

import io
import urllib.request
import zipfile
from pathlib import Path

URL = "https://archive.ics.uci.edu/static/public/222/bank+marketing.zip"
TARGET = Path(__file__).parent / "data" / "bank-additional-full.csv"


def main() -> None:
    TARGET.parent.mkdir(exist_ok=True)
    with urllib.request.urlopen(URL, timeout=60) as resp:
        outer = zipfile.ZipFile(io.BytesIO(resp.read()))
    # The download is a zip containing bank-additional.zip, which contains the CSV.
    inner = zipfile.ZipFile(io.BytesIO(outer.read("bank-additional.zip")))
    member = next(n for n in inner.namelist() if n.endswith("bank-additional-full.csv"))
    TARGET.write_bytes(inner.read(member))
    rows = sum(1 for _ in TARGET.open()) - 1
    print(f"Saved {TARGET} ({rows:,} rows)")


if __name__ == "__main__":
    main()
