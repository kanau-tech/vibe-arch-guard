#!/usr/bin/env bash
# Vibe Arch Guard — 1-Minute Universal Installer (v1.1)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kanau-tech/vibe-arch-guard/main/scripts/install.sh | bash
#   ./scripts/install.sh [TARGET_DIR]
set -eo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"

echo "🛡️ [Vibe Arch Guard] Installing universal architecture guard into: ${TARGET_DIR}"

# 1. Resolve source directory (support both local clone and piped curl | bash execution)
CLEANUP_TMP=0
TMP_DIR=""

if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "bash" ] && [ "${BASH_SOURCE[0]}" != "-bash" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
else
  # Piped execution via curl | bash
  echo "📦 Downloading latest vibe-arch-guard package from GitHub..."
  TMP_DIR="$(mktemp -d)"
  CLEANUP_TMP=1
  trap 'rm -rf "${TMP_DIR}"' EXIT

  REPO_TAR_URL="https://github.com/kanau-tech/vibe-arch-guard/archive/refs/heads/main.tar.gz"
  curl -fsSL "${REPO_TAR_URL}" | tar -xz -C "${TMP_DIR}"
  SOURCE_DIR="${TMP_DIR}/vibe-arch-guard-main"
fi

if [ ! -d "${SOURCE_DIR}" ]; then
  echo "❌ Error: Could not determine source directory."
  exit 1
fi

# 2. Create required directory tree in target project
mkdir -p "${TARGET_DIR}/.claude/rules" \
         "${TARGET_DIR}/.claude/commands" \
         "${TARGET_DIR}/.cursor/rules" \
         "${TARGET_DIR}/.agents/skills/architecture-sync" \
         "${TARGET_DIR}/scripts" \
         "${TARGET_DIR}/.github/workflows" \
         "${TARGET_DIR}/docs/02-ky-thuat"

# 3. Deploy Claude Code rules and commands
cp "${SOURCE_DIR}/.claude/rules/architecture-sync.md" "${TARGET_DIR}/.claude/rules/"
cp "${SOURCE_DIR}/.claude/commands/architecture-plan.md" "${TARGET_DIR}/.claude/commands/"
echo "  ✓ Installed Claude Code rule & /architecture-plan command"

# 4. Deploy Cursor / Windsurf rules (.mdc and smart .cursorrules append)
cp "${SOURCE_DIR}/.cursor/rules/architecture-sync.mdc" "${TARGET_DIR}/.cursor/rules/"

CURSORRULES_FILE="${TARGET_DIR}/.cursorrules"
if [ -f "${CURSORRULES_FILE}" ]; then
  if grep -q "Architecture Sync" "${CURSORRULES_FILE}"; then
    echo "  ℹ Existing Architecture Sync rules found in .cursorrules (preserved)"
  else
    echo "" >> "${CURSORRULES_FILE}"
    cat "${SOURCE_DIR}/.cursorrules" >> "${CURSORRULES_FILE}"
    echo "  ✓ Appended Architecture Sync rules to existing .cursorrules"
  fi
else
  cp "${SOURCE_DIR}/.cursorrules" "${CURSORRULES_FILE}"
  echo "  ✓ Created .cursorrules"
fi

# 5. Deploy Antigravity (Agy) & Codex skill
cp "${SOURCE_DIR}/skills/architecture-sync/SKILL.md" "${TARGET_DIR}/.agents/skills/architecture-sync/"
echo "  ✓ Installed Antigravity & Codex skill"

# 6. Deploy verification script & CI workflow
cp "${SOURCE_DIR}/scripts/verify-sync.sh" "${TARGET_DIR}/scripts/verify-sync.sh"
chmod +x "${TARGET_DIR}/scripts/verify-sync.sh"
echo "  ✓ Installed scripts/verify-sync.sh (executable)"

if [ ! -f "${TARGET_DIR}/.github/workflows/arch-drift-check.yml" ]; then
  cp "${SOURCE_DIR}/.github/workflows/arch-drift-check.yml" "${TARGET_DIR}/.github/workflows/arch-drift-check.yml"
  echo "  ✓ Installed GitHub Action: .github/workflows/arch-drift-check.yml"
else
  echo "  ℹ Existing .github/workflows/arch-drift-check.yml detected (preserved)"
fi

# 7. Deploy ARCHITECTURE draft template if no specification exists
if [ ! -f "${TARGET_DIR}/ARCHITECTURE.md" ] && \
   [ ! -f "${TARGET_DIR}/docs/ARCHITECTURE.md" ] && \
   [ ! -f "${TARGET_DIR}/docs/02-ky-thuat/architecture.md" ]; then
  cp "${SOURCE_DIR}/templates/ARCHITECTURE_TEMPLATE.md" "${TARGET_DIR}/docs/02-ky-thuat/architecture.md"
  echo "  ✓ Generated initial template: docs/02-ky-thuat/architecture.md (Status: ◼ Unconfirmed)"
else
  echo "  ℹ Existing architecture specification detected (preserved)"
fi

# 8. Deploy Interactive Flow Simulator if absent
if [ ! -f "${TARGET_DIR}/docs/02-ky-thuat/arch-flow.html" ]; then
  cp "${SOURCE_DIR}/templates/arch-flow-template.html" "${TARGET_DIR}/docs/02-ky-thuat/arch-flow.html"
  echo "  ✓ Installed interactive flow simulator: docs/02-ky-thuat/arch-flow.html"
fi

echo ""
echo "🎉 [Vibe Arch Guard] Installation complete!"
echo ""
echo "Next Steps:"
echo "  1. Run '/architecture-plan' in Claude Code or Antigravity to reverse-engineer and verify your codebase."
echo "  2. Review the generated specification and obtain human approval to update status to '✅ Confirmed'."
echo "  3. Run './scripts/verify-sync.sh' locally or let CI guard against architectural drift on every commit."
echo ""
