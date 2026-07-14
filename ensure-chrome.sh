#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=config.env
source "$SCRIPT_DIR/config.env"

cdp_is_ready() {
  curl -fsS "$CDP_URL/json/version" >/dev/null 2>&1
}

profile_pids() {
  pgrep -f -- "--user-data-dir=$CHROME_PROFILE_DIR" || true
}

if cdp_is_ready; then
  if [[ -n "$(profile_pids)" ]]; then
    echo "Chrome AI Profile 已在线"
    echo "CDP: $CDP_URL"
    exit 0
  fi
  echo "端口 $CDP_PORT 已被其他 Chrome 或程序占用" >&2
  exit 1
fi

pids="$(profile_pids)"
if [[ -n "$pids" ]]; then
  echo "检测到 Chrome AI Profile 进程异常，正在重启"
  kill $pids 2>/dev/null || true

  for _ in {1..25}; do
    if [[ -z "$(profile_pids)" ]]; then
      break
    fi
    sleep 0.2
  done

  pids="$(profile_pids)"
  if [[ -n "$pids" ]]; then
    kill -9 $pids 2>/dev/null || true
  fi
fi

if command -v lsof >/dev/null 2>&1 && \
  lsof -nP -iTCP:"$CDP_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "端口 $CDP_PORT 已被其他程序占用" >&2
  exit 1
fi

rm -f \
  "$CHROME_PROFILE_DIR/SingletonCookie" \
  "$CHROME_PROFILE_DIR/SingletonLock" \
  "$CHROME_PROFILE_DIR/SingletonSocket"

exec "$SCRIPT_DIR/start-chrome.sh"
