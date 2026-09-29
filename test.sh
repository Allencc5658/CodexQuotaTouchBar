#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h}
build_dir="${CODEX_QUOTA_BUILD_DIR:-$project_dir/.build}"
mkdir -p "$build_dir/ModuleCache"
cp "$project_dir/Tests/QuotaModelTests.swift" "$build_dir/main.swift"
swiftc -module-cache-path "$build_dir/ModuleCache" \
  "$project_dir/Sources/Localizer.swift" \
  "$project_dir/Sources/QuotaModel.swift" "$build_dir/main.swift" \
  -o "$build_dir/QuotaModelTests"
"$build_dir/QuotaModelTests"

CODEX_QUOTA_CODEX_PATH="$project_dir/Tests/FakeCodexServer.py" \
  "$project_dir/Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar" --probe \
  > "$build_dir/plus-probe.txt"
grep -Fq '75%' "$build_dir/plus-probe.txt"
grep -Fq '60%' "$build_dir/plus-probe.txt"

CODEX_QUOTA_TEST_NO_PLAN=1 CODEX_QUOTA_CODEX_PATH="$project_dir/Tests/FakeCodexServer.py" \
  "$project_dir/Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar" --probe \
  > "$build_dir/fallback-probe.txt"
grep -Fq '75%' "$build_dir/fallback-probe.txt"
grep -Fq '60%' "$build_dir/fallback-probe.txt"

CODEX_QUOTA_TEST_PLAN=pro CODEX_QUOTA_CODEX_PATH="$project_dir/Tests/FakeCodexServer.py" \
  "$project_dir/Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar" --probe \
  > "$build_dir/pro-probe.txt"
if [[ $(wc -l < "$build_dir/pro-probe.txt") -ne 2 ]]; then
  echo 'Pro unexpectedly displayed a 5-hour limit' >&2
  exit 1
fi
grep -Fq '60%' "$build_dir/pro-probe.txt"

CODEX_QUOTA_CODEX_PATH="$project_dir/Tests/FakeCodexServer.py" \
  "$project_dir/Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar" \
  -appLanguage en --probe > "$build_dir/en-probe.txt"
grep -Fq 'Weekly: 60% left' "$build_dir/en-probe.txt"

CODEX_QUOTA_CODEX_PATH="$project_dir/Tests/FakeCodexServer.py" \
  "$project_dir/Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar" \
  -appLanguage zh-Hant --probe > "$build_dir/zh-hant-probe.txt"
grep -Fq '每週額度：剩餘 60%' "$build_dir/zh-hant-probe.txt"

if CODEX_QUOTA_TEST_EXIT_AFTER_INIT=1 \
    CODEX_QUOTA_CODEX_PATH="$project_dir/Tests/FakeCodexServer.py" \
    "$project_dir/Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar" --probe \
    > "$build_dir/disconnect-probe.txt" 2>&1; then
  echo 'Disconnected app-server unexpectedly succeeded' >&2
  exit 1
else
  disconnect_status=$?
fi
if [[ $disconnect_status -eq 141 ]]; then
  echo 'Disconnected app-server caused SIGPIPE' >&2
  exit 1
fi
echo 'JSON-RPC probe tests passed'
