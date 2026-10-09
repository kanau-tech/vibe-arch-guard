#!/usr/bin/env bash
# Vibe Arch Guard — Integration Tests for verify-sync.sh
# Tests all modes and boundary conditions in isolated temporary git repos
set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERIFY_SCRIPT="${REPO_ROOT}/scripts/verify-sync.sh"

echo "🧪 [Test Verifier] Running comprehensive verify-sync.sh test suite..."

BASE_TMP="$(mktemp -d)"
trap 'rm -rf "${BASE_TMP}"' EXIT

setup_sandbox() {
  local sb
  sb="$(mktemp -d "${BASE_TMP}/sb.XXXXXX")"
  cd "${sb}"
  git init -q
  git config user.name "Kanau Tech"
  git config user.email "contact@kanautech.jp"
  
  mkdir -p docs/02-ky-thuat src
  cat << 'EOF' > docs/02-ky-thuat/architecture.md
<!-- archguard: synced=initial status=confirmed date=2026-10-09 -->
# ARCHITECTURE.md
> 最終更新: 2026-10-09 · 同期コミット: `initial` · ステータス: ✅ 確定済 (2026-10-09)
### 1. Overview
EOF

  echo "console.log('init');" > src/index.ts
  git add .
  git commit -q -m "initial commit"
}

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

# --- TC-01: Clean repo ---
setup_sandbox
run_test "Clean repository passes with exit 0" bash -c "${VERIFY_SCRIPT} >/dev/null 2>&1"

# --- TC-02: Non-structural file changed ---
setup_sandbox
echo "# Title" > README.md
run_test "Documentation-only modification passes with exit 0" bash -c "${VERIFY_SCRIPT} >/dev/null 2>&1"

# --- TC-03: Lockfile changed ---
setup_sandbox
echo '{"lockfileVersion": 3}' > package-lock.json
run_test "Lockfile-only modification is excluded and passes with exit 0" bash -c "${VERIFY_SCRIPT} >/dev/null 2>&1"

# --- TC-04: Structural file changed WITHOUT architecture update (FAIL-CLOSED) ---
setup_sandbox
echo "export const add = (a, b) => a + b;" > src/math.ts
run_test "FAIL-CLOSED: Structural change without arch update exits with code 1" bash -c "! ${VERIFY_SCRIPT} >/dev/null 2>&1"

# --- TC-05: Structural file changed WITH architecture update ---
setup_sandbox
echo "export const add = (a, b) => a + b;" > src/math.ts
echo "- 2026-10-09 · add math module" >> docs/02-ky-thuat/architecture.md
run_test "Structural change with architecture update passes with exit 0" bash -c "${VERIFY_SCRIPT} >/dev/null 2>&1"

# --- TC-06: Staged mode verification ---
setup_sandbox
echo "export const sub = (a, b) => a - b;" > src/sub.ts
git add src/sub.ts
run_test "--staged detects unstaged arch update and exits with code 1" bash -c "! ${VERIFY_SCRIPT} --staged >/dev/null 2>&1"

echo "- 2026-10-09 · add sub module" >> docs/02-ky-thuat/architecture.md
git add docs/02-ky-thuat/architecture.md
run_test "--staged passes when architecture update is also staged" bash -c "${VERIFY_SCRIPT} --staged >/dev/null 2>&1"

# --- TC-07: Escape hatch --allow-drift ---
setup_sandbox
echo "export const multiply = (a, b) => a * b;" > src/mul.ts
run_test "--allow-drift bypasses drift error and exits with code 0" bash -c "${VERIFY_SCRIPT} --allow-drift >/dev/null 2>&1"

# --- TC-08: Subdirectory execution ---
setup_sandbox
echo "export const div = (a, b) => a / b;" > src/div.ts
echo "- 2026-10-09 · add div module" >> docs/02-ky-thuat/architecture.md
run_test "Execution from subdirectory correctly resolves root" bash -c "cd src && ${VERIFY_SCRIPT} >/dev/null 2>&1"

# --- TC-09: Missing architecture file ---
setup_sandbox
rm -f docs/02-ky-thuat/architecture.md
run_test "Missing architecture file exits with code 1" bash -c "! ${VERIFY_SCRIPT} >/dev/null 2>&1"

echo ""
echo "🎉 All ${PASSED}/${TOTAL} verifier integration tests passed!"
