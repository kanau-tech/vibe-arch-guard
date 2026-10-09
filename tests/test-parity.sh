#!/usr/bin/env bash
# Vibe Arch Guard — Tool Parity Test
# Verifies that all 4 AI tool definitions maintain 100% rule parity
set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

echo "🧪 [Test Parity] Checking rule parity across AI tools..."

TARGETS=(
  ".claude/rules/architecture-sync.md"
  ".cursor/rules/architecture-sync.mdc"
  ".cursorrules"
  "skills/architecture-sync/SKILL.md"
  ".agents/skills/architecture-sync/SKILL.md"
)

REQUIRED_CONCEPTS=(
  "Architecture First:Architecture First|設計先行"
  "Same-Turn Sync:Same-turn|同ターン"
  "Status Symbol In Code:✅"
  "Status Symbol Planned:◼"
  "Status Symbol Review:⚠️"
  "Changelog §27:Changelog|変更履歴|§27"
)

FAILED=0

for target in "${TARGETS[@]}"; do
  if [ ! -f "$target" ]; then
    echo "  ❌ Missing target rule file: $target"
    FAILED=1
    continue
  fi
  
  echo "  🔍 Checking: $target"
  for concept in "${REQUIRED_CONCEPTS[@]}"; do
    NAME="${concept%%:*}"
    PATTERN="${concept#*:}"
    
    if ! grep -qiE "$PATTERN" "$target"; then
      echo "    ❌ Missing concept '$NAME' (pattern: '$PATTERN') in $target"
      FAILED=1
    fi
  done
done

if [ "$FAILED" -eq 1 ]; then
  echo "❌ Tool parity check FAILED."
  exit 1
fi

echo "✅ All 4 AI tools satisfy 100% rule parity!"
