#!/usr/bin/env bash
# Vibe Arch Guard — Master Test Suite Runner
# Executes all test suites and returns non-zero exit code on failure
set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

echo "=========================================================="
echo "🛡️  VIBE ARCH GUARD — MASTER TEST SUITE EXECUTION"
echo "=========================================================="
echo ""

chmod +x tests/*.sh scripts/*.sh

echo "▶ Step 1: Tool Rule Parity Verification"
./tests/test-parity.sh
echo ""

echo "▶ Step 2: Verification Script (verify-sync.sh) Integration Tests"
./tests/test-verify-sync.sh
echo ""

echo "▶ Step 3: Installer Script (install.sh) Integration Tests"
./tests/test-install.sh
echo ""

echo "▶ Step 4: Security & Attribution Audit"
if git grep -i -E "do xuan|hiendx|hiendoxuan|dxh188" 2>/dev/null; then
  echo "❌ Security Audit Failed: Personal attribution detected in repository!"
  exit 1
fi
echo "✅ Security & Attribution Audit passed: Zero personal traces detected."
echo ""

echo "=========================================================="
echo "🎉 ALL TESTS PASSED! VIBE ARCH GUARD IS FULLY VERIFIED!"
echo "=========================================================="
