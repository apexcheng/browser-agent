#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=config.env
source "$SCRIPT_DIR/config.env"

echo "Profile: $CHROME_PROFILE_DIR"
echo "CDP: $CDP_URL"

if ! curl -fsS "$CDP_URL/json/version" >/dev/null 2>&1; then
  echo "Status: stopped"
  exit 1
fi

echo "Status: running"
python3 - "$CDP_URL" <<'PY'
import json
import sys
from urllib.request import urlopen

base_url = sys.argv[1]
with urlopen(f"{base_url}/json/list", timeout=2) as response:
    pages = json.load(response)

print(f"Pages: {len(pages)}")
for index, page in enumerate(pages):
    title = page.get("title") or "(no title)"
    url = page.get("url") or ""
    print(f"  {index}: {title} — {url}")
PY
