#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT_DIR/.tmp/verify-logs"
TMP_ROOT="$ROOT_DIR/.tmp/xcrun"

mkdir -p "$LOG_DIR" "$TMP_ROOT"

export TMPDIR="$TMP_ROOT"

run_step() {
  local name="$1"
  shift
  local log_file="$LOG_DIR/${name}.log"

  echo "==> [$name]"
  if "$@" >"$log_file" 2>&1; then
    echo "PASS [$name]"
    return 0
  fi

  echo "FAIL [$name]"
  echo "---- last 40 lines: $log_file ----"
  tail -n 40 "$log_file" || true
  return 1
}

run_step core_tests \
  swift test --package-path Core

run_step build_macos \
  xcodebuild -project demo.xcodeproj -scheme demo -destination "platform=macOS" \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build

run_step build_ios_sim \
  xcodebuild -project demo.xcodeproj -scheme demo -destination "generic/platform=iOS Simulator" \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build

run_step swiftlint \
  swiftlint lint demo Core/Sources Core/Tests

echo "All verification steps passed."
