#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=config.env
source "$SCRIPT_DIR/config.env"

mkdir -p "$CHROME_PROFILE_DIR" "$BROWSER_AGENT_HOME/logs" "$BROWSER_AGENT_HOME/run"

if [[ ! -x "$CHROME_BIN" ]]; then
  echo "Chrome 不存在: $CHROME_BIN" >&2
  exit 1
fi

if curl -fsS "$CDP_URL/json/version" >/dev/null 2>&1; then
  if pgrep -f -- "--user-data-dir=$CHROME_PROFILE_DIR" >/dev/null 2>&1; then
    echo "Chrome AI Profile 已运行"
    echo "CDP: $CDP_URL"
    exit 0
  fi
  echo "端口 $CDP_PORT 已被其他 Chrome 或程序占用" >&2
  exit 1
fi

if pgrep -f -- "--user-data-dir=$CHROME_PROFILE_DIR" >/dev/null 2>&1; then
  echo "Chrome AI Profile 已被占用，但 CDP 端口不可用。请先关闭该 Profile 的 Chrome。" >&2
  exit 1
fi

nohup "$CHROME_BIN" \
  --remote-debugging-address="$CDP_HOST" \
  --remote-debugging-port="$CDP_PORT" \
  --user-data-dir="$CHROME_PROFILE_DIR" \
  --profile-directory=Default \
  --restore-last-session \
  --no-first-run \
  --no-default-browser-check \
  >"$BROWSER_AGENT_HOME/logs/chrome.log" 2>&1 </dev/null &

echo "$!" >"$BROWSER_AGENT_HOME/run/chrome.pid"

for _ in {1..50}; do
  if curl -fsS "$CDP_URL/json/version" >/dev/null 2>&1; then
    echo "Chrome AI Profile 已启动"
    echo "Profile: $CHROME_PROFILE_DIR"
    echo "CDP: $CDP_URL"
    exit 0
  fi
  sleep 0.2
done

echo "Chrome 启动失败，日志: $BROWSER_AGENT_HOME/logs/chrome.log" >&2
exit 1
