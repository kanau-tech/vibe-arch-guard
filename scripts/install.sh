#!/usr/bin/env bash
# Vibe Arch Guard — 1-Minute Installer
# Usage: ./scripts/install.sh [TARGET_DIR]
set -e

TARGET_DIR="${1:-.}"

echo "🛡️ Installing Vibe Arch Guard into: ${TARGET_DIR}"

# Determine base directory of this script or clone repo if run via curl
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. Create target directories
mkdir -p "${TARGET_DIR}/.claude/rules" \
         "${TARGET_DIR}/.claude/commands" \
         "${TARGET_DIR}/.cursor/rules" \
         "${TARGET_DIR}/.agents/skills/architecture-sync" \
         "${TARGET_DIR}/docs/02-ky-thuat"

# 2. Copy Claude Code rules and commands
cp "${SCRIPT_DIR}/.claude/rules/architecture-sync.md" "${TARGET_DIR}/.claude/rules/"
cp "${SCRIPT_DIR}/.claude/commands/architecture-plan.md" "${TARGET_DIR}/.claude/commands/"

# 3. Copy Cursor rules
cp "${SCRIPT_DIR}/.cursor/rules/architecture-sync.mdc" "${TARGET_DIR}/.cursor/rules/"
cp "${SCRIPT_DIR}/.cursorrules" "${TARGET_DIR}/.cursorrules" 2>/dev/null || true

# 4. Copy Antigravity & Codex skill
cp "${SCRIPT_DIR}/skills/architecture-sync/SKILL.md" "${TARGET_DIR}/.agents/skills/architecture-sync/"

# 5. Copy ARCHITECTURE template if none exists
if [ ! -f "${TARGET_DIR}/ARCHITECTURE.md" ] && [ ! -f "${TARGET_DIR}/docs/02-ky-thuat/architecture.md" ]; then
  cp "${SCRIPT_DIR}/templates/ARCHITECTURE_TEMPLATE.md" "${TARGET_DIR}/docs/02-ky-thuat/architecture.md"
  echo "📄 Created: docs/02-ky-thuat/architecture.md"
else
  echo "ℹ️ Existing architecture file detected, skipping template overwrite."
fi

# 6. Copy Interactive Flow Viewer
if [ ! -f "${TARGET_DIR}/docs/02-ky-thuat/arch-flow.html" ]; then
  cp "${SCRIPT_DIR}/templates/arch-flow-template.html" "${TARGET_DIR}/docs/02-ky-thuat/arch-flow.html"
  echo "📊 Created: docs/02-ky-thuat/arch-flow.html"
fi

echo "✅ Vibe Arch Guard installed successfully!"
echo "👉 Next step: Run '/architecture-plan' in Claude Code or Antigravity to sync with your codebase."
