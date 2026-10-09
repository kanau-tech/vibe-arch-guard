#!/usr/bin/env bash
# Vibe Arch Guard — Integration Tests for install.sh
# Tests local installation, piped execution, and preservation of existing assets
set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="${REPO_ROOT}/scripts/install.sh"

echo "🧪 [Test Installer] Running comprehensive install.sh test suite..."

BASE_TMP="$(mktemp -d)"
trap 'rm -rf "${BASE_TMP}"' EXIT

PASSED=0
TOTAL=0

run_test() {
  local desc="$1"
  shift
  TOTAL=$((TOTAL + 1))
  echo -n "  Test ${TOTAL}: ${desc} ... "
  if "$@"; then
    echo "✅ PASS"
    PASSED=$((PASSED + 1))
  else
    echo "❌ FAIL"
    exit 1
  fi
}

# --- TC-01: Fresh local install ---
sb1="$(mktemp -d "${BASE_TMP}/fresh.XXXXXX")"
"${INSTALL_SCRIPT}" "${sb1}" >/dev/null 2>&1
run_test "Fresh local install copies all expected files" bash -c "
  [ -f '${sb1}/.claude/rules/architecture-sync.md' ] && \
  [ -f '${sb1}/.claude/commands/architecture-plan.md' ] && \
  [ -f '${sb1}/.cursor/rules/architecture-sync.mdc' ] && \
  [ -f '${sb1}/.cursorrules' ] && \
  [ -f '${sb1}/.agents/skills/architecture-sync/SKILL.md' ] && \
  [ -x '${sb1}/scripts/verify-sync.sh' ] && \
  [ -f '${sb1}/.github/workflows/arch-drift-check.yml' ] && \
  [ -f '${sb1}/docs/02-ky-thuat/architecture.md' ] && \
  [ -f '${sb1}/docs/02-ky-thuat/arch-flow.html' ]
"

# --- TC-02: Existing ARCHITECTURE.md preservation ---
sb2="$(mktemp -d "${BASE_TMP}/preserve-arch.XXXXXX")"
mkdir -p "${sb2}/docs/02-ky-thuat"
echo "# CUSTOM ARCHITECTURE" > "${sb2}/docs/02-ky-thuat/architecture.md"
"${INSTALL_SCRIPT}" "${sb2}" >/dev/null 2>&1
run_test "Existing architecture.md is not overwritten" grep -q "CUSTOM ARCHITECTURE" "${sb2}/docs/02-ky-thuat/architecture.md"

# --- TC-03: Existing .cursorrules smart append ---
sb3="$(mktemp -d "${BASE_TMP}/append-rules.XXXXXX")"
echo "ORIGINAL USER RULE" > "${sb3}/.cursorrules"
"${INSTALL_SCRIPT}" "${sb3}" >/dev/null 2>&1
run_test "Existing .cursorrules preserves user rules and appends new ones" bash -c "
  grep -q 'ORIGINAL USER RULE' '${sb3}/.cursorrules' && \
  grep -q 'Architecture Sync' '${sb3}/.cursorrules'
"

# --- TC-04: Piped execution simulation ---
sb4="$(mktemp -d "${BASE_TMP}/pipe.XXXXXX")"
cat "${INSTALL_SCRIPT}" | bash -s -- "${sb4}" >/dev/null 2>&1
run_test "Piped execution (curl | bash simulation) succeeds completely" bash -c "
  [ -f '${sb4}/.claude/rules/architecture-sync.md' ] && \
  [ -x '${sb4}/scripts/verify-sync.sh' ] && \
  [ -f '${sb4}/docs/02-ky-thuat/architecture.md' ]
"

echo ""
echo "🎉 All ${PASSED}/${TOTAL} installer integration tests passed!"
