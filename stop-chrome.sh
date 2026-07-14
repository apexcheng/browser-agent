#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=config.env
source "$SCRIPT_DIR/config.env"

pids="$(pgrep -f -- "--user-data-dir=$CHROME_PROFILE_DIR" || true)"
if [[ -z "$pids" ]]; then
  echo "Chrome AI Profile 未运行"
  exit 0
fi

kill $pids

for _ in {1..25}; do
  if ! curl -fsS "$CDP_URL/json/version" >/dev/null 2>&1; then
    rm -f "$BROWSER_AGENT_HOME/run/chrome.pid"
    echo "Chrome AI Profile 已停止"
    exit 0
  fi
  sleep 0.2
done

echo "Chrome 未在预期时间内停止，请手动关闭该窗口" >&2
exit 1
