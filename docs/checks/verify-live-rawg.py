#!/usr/bin/env python3
"""Bir canlı RAWG araması yapar. Anahtar yoksa kabulü geçmez."""

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "evidence" / "live-rawg.json"
QUOTA_HEADER_NAMES = (
    "x-ratelimit-limit",
    "x-ratelimit-remaining",
    "x-ratelimit-reset",
    "retry-after",
)


def main():
    key = os.environ.get("RAWG_API_KEY", "").strip()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    if not key:
        record = {
            "accepted": False,
            "reason": "RAWG_API_KEY yok. Canlı arama ve gerçek kota ölçülmedi.",
        }
        OUT.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n")
        print(record["reason"])
        return 2

    query = urllib.parse.urlencode({"search": "Portal", "page": "1", "page_size": "1", "key": key})
    request = urllib.request.Request(
        f"https://api.rawg.io/api/games?{query}",
        headers={"Accept": "application/json", "User-Agent": "oyun-kutuphanesi-acceptance"},
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.loads(response.read().decode())
            status = response.status
            headers = {name.lower(): response.headers.get(name) for name in QUOTA_HEADER_NAMES}
    except urllib.error.HTTPError as error:
        status = error.code
        payload = {}
        headers = {name.lower(): error.headers.get(name) if error.headers else None for name in QUOTA_HEADER_NAMES}
    results = payload.get("results") if isinstance(payload, dict) else None
    names = [row.get("name") for row in results or [] if isinstance(row, dict) and row.get("name")]
    record = {
        "accepted": status == 200 and len(names) == 1,
        "status": status,
        "result_count": len(names),
        "quota_headers": headers,
    }
    OUT.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({k: record[k] for k in ("accepted", "status", "result_count", "quota_headers")}, ensure_ascii=False))
    return 0 if record["accepted"] else 1


if __name__ == "__main__":
    sys.exit(main())
