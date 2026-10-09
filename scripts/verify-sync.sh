#!/usr/bin/env bash
# Vibe Arch Guard — Local Sync Verifier
# Checks if recent structural changes are reflected in ARCHITECTURE.md
set -e

ARCH_FILE=""
if [ -f "docs/02-ky-thuat/architecture.md" ]; then
  ARCH_FILE="docs/02-ky-thuat/architecture.md"
elif [ -f "ARCHITECTURE.md" ]; then
  ARCH_FILE="ARCHITECTURE.md"
else
  echo "❌ Error: Neither docs/02-ky-thuat/architecture.md nor ARCHITECTURE.md found."
  exit 1
fi

echo "🔍 Checking architectural synchronization for: ${ARCH_FILE}"

# 1. Check if git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "⚠️ Warning: Not a git repository. Skipping commit comparison."
  exit 0
fi

# 2. Check if architecture file is modified when source files are modified in working tree / staging
CHANGED_SRC=$(git status --porcelain | grep -E '\.(ts|js|py|go|rs|prisma|sql|json)$' || true)
CHANGED_ARCH=$(git status --porcelain | grep "$ARCH_FILE" || true)

if [ -n "$CHANGED_SRC" ] && [ -z "$CHANGED_ARCH" ]; then
  echo "⚠️ Warning: Source code has changed but ${ARCH_FILE} was not updated in this session!"
  echo "👉 Recommendation: Run '/architecture-plan' or update §27 Changelog before committing."
else
  echo "✅ Architecture synchronization check passed."
fi
