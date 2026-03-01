#!/usr/bin/env sh
# Tests for scripts/keepassxc-entry.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KEEPASSXC_ENTRY="$SCRIPT_DIR/scripts/keepassxc-entry.sh"
TEST_DB=""
PASS="testpass"

# Prevent tests from accidentally using default database
export KEEPASSXC_DB="/tmp/test_should_not_be_used.kdbx"

run_test() {
  printf "  %s ... " "$1"
  if eval "$2" >/dev/null 2>&1; then
    echo "ok"
    return 0
  else
    echo "FAIL"
    return 1
  fi
}

run_cmd() {
  sh "$KEEPASSXC_ENTRY" "$@"
}

run_test_output() {
  printf "  %s ... " "$1"
  output=$(eval "$2" 2>&1)
  if echo "$output" | grep -q "$3"; then
    echo "ok"
    return 0
  else
    echo "FAIL (expected: $3)"
    echo "    got: $output"
    return 1
  fi
}

run_test_exit() {
  printf "  %s ... " "$1"
  output=$(eval "$2" 2>&1) || exitcode=$?
  exitcode=${exitcode:-$?}
  if [ "$exitcode" = "$3" ]; then
    echo "ok"
    return 0
  else
    echo "FAIL (expected exit $3, got $exitcode)"
    echo "    output: $output"
    return 1
  fi
}

cleanup() {
  if [ -n "$TEST_DB" ] && [ -f "$TEST_DB" ]; then
    rm -f "$TEST_DB"
  fi
}

trap cleanup EXIT

failed=0

echo "keepassxc-entry.sh tests"
echo "========================"

echo ""
echo "1. Help and usage"
run_test_output "help shows usage" "run_cmd --help" "Usage:" || failed=$((failed + 1))
run_test_output "help lists add command" "run_cmd --help" "add" || failed=$((failed + 1))
run_test_output "no args shows help" "run_cmd" "Usage:" || failed=$((failed + 1))
run_test_output "help lists edit" "run_cmd -h" "edit" || failed=$((failed + 1))
run_test_output "help lists rm" "run_cmd -h" "rm" || failed=$((failed + 1))

echo ""
echo "2. Unknown command"
run_test_exit "unknown command exits 1" "run_cmd invalid 2>&1" 1 || failed=$((failed + 1))
run_test_output "unknown command shows error" "run_cmd invalid 2>&1" "Unknown command" || failed=$((failed + 1))

echo ""
echo "3. Subcommand defined"
for cmd in add show edit rm ls search; do
  run_test "script defines $cmd" "grep -q \"$cmd)\" '$KEEPASSXC_ENTRY'" || failed=$((failed + 1))
done

echo ""
echo "4. Integration test (requires keepassxc-cli, run with TTY for full test)"
if ! command -v keepassxc-cli >/dev/null 2>&1; then
  echo "  skip (keepassxc-cli not installed)"
elif [ ! -t 0 ]; then
  echo "  skip (no TTY, pipe stdin may not work for keepassxc-cli password prompts)"
else
  TEST_DB="/tmp/keepassxc_test_$$.kdbx"

  inputs_add=$(printf '%s\n%s\n\n\n\n%s\n%s\n%s\n%s\n%s\n' \
    "$TEST_DB" "TestEntry" "" "" "" "$PASS" "$PASS" "$PASS" "$PASS" "$PASS")
  inputs_show=$(printf '%s\n%s\n%s\n' "$TEST_DB" "TestEntry" "$PASS")
  inputs_ls=$(printf '%s\n%s\n' "$TEST_DB" "$PASS")
  inputs_search=$(printf '%s\n%s\n%s\n' "$TEST_DB" "Test" "$PASS")
  inputs_edit=$(printf '%s\n%s\n\n\nhttps://example.com\n\n%s\n%s\n' "$TEST_DB" "TestEntry" "$PASS" "$PASS")
  inputs_rm=$(printf '%s\n%s\ny\n%s\n' "$TEST_DB" "TestEntry" "$PASS")

  int_failed=0
  printf "  add entry ... "
  if echo "$inputs_add" | run_cmd add 2>/dev/null | grep -q "Done"; then
    echo "ok"
  else
    echo "FAIL"
    int_failed=$((int_failed + 1))
  fi

  printf "  show entry ... "
  if echo "$inputs_show" | run_cmd show 2>/dev/null | grep -q "TestEntry"; then
    echo "ok"
  else
    echo "FAIL"
    int_failed=$((int_failed + 1))
  fi

  printf "  ls entries ... "
  if echo "$inputs_ls" | run_cmd ls 2>/dev/null | grep -q "TestEntry"; then
    echo "ok"
  else
    echo "FAIL"
    int_failed=$((int_failed + 1))
  fi

  printf "  search entries ... "
  if echo "$inputs_search" | run_cmd search 2>/dev/null | grep -q "TestEntry"; then
    echo "ok"
  else
    echo "FAIL"
    int_failed=$((int_failed + 1))
  fi

  printf "  edit entry ... "
  if echo "$inputs_edit" | run_cmd edit 2>/dev/null | grep -q "Done"; then
    echo "ok"
  else
    echo "FAIL"
    int_failed=$((int_failed + 1))
  fi

  printf "  rm entry ... "
  if echo "$inputs_rm" | run_cmd rm 2>/dev/null | grep -q "Done"; then
    echo "ok"
  else
    echo "FAIL"
    int_failed=$((int_failed + 1))
  fi

  [ "$int_failed" -gt 0 ] && failed=$((failed + int_failed))
  rm -f "$TEST_DB"
fi

echo ""
if [ "$failed" -gt 0 ]; then
  echo "Failed: $failed test(s)"
  exit 1
else
  echo "All tests passed"
  exit 0
fi
