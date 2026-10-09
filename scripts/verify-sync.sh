#!/usr/bin/env bash
# Vibe Arch Guard — Architectural Synchronization & Drift Verifier (v1.1)
# Ensures code modifications match ARCHITECTURE.md specifications (Fail-Closed)
set -eo pipefail

# 1. Resolve repository root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${REPO_ROOT}"

# Parse flags
MODE="working"
ALLOW_DRIFT=0
COMMIT_RANGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --staged)
      MODE="staged"
      shift
      ;;
    --ci)
      MODE="ci"
      shift
      ;;
    --range)
      MODE="range"
      COMMIT_RANGE="$2"
      shift 2
      ;;
    --allow-drift)
      ALLOW_DRIFT=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--staged | --ci | --range <base>..<head>] [--allow-drift]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ -n "${ARCH_GUARD_ALLOW_DRIFT:-}" ]; then
  ALLOW_DRIFT=1
fi

# 2. Locate architecture file
ARCH_FILE=""
if [ -f "docs/02-ky-thuat/architecture.md" ]; then
  ARCH_FILE="docs/02-ky-thuat/architecture.md"
elif [ -f "docs/ARCHITECTURE.md" ]; then
  ARCH_FILE="docs/ARCHITECTURE.md"
elif [ -f "ARCHITECTURE.md" ]; then
  ARCH_FILE="ARCHITECTURE.md"
fi

if [ -z "$ARCH_FILE" ]; then
  echo "❌ [Vibe Arch Guard] Error: Architecture specification file not found."
  echo "   Expected one of: docs/02-ky-thuat/architecture.md, docs/ARCHITECTURE.md, ARCHITECTURE.md"
  if [ "$ALLOW_DRIFT" -eq 1 ]; then
    echo "⚠️ Warning: Drift tolerated via --allow-drift."
    exit 0
  fi
  exit 1
fi

echo "🔍 [Vibe Arch Guard] Inspecting architecture sync for: ${ARCH_FILE}"

# Check if inside git work tree
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "⚠️ Warning: Not inside a git repository. Skipping verification."
  exit 0
fi

# 3. Collect changed files according to mode
CHANGED_FILES=""
if [ "$MODE" = "staged" ]; then
  CHANGED_FILES="$(git diff --cached --name-only)"
elif [ "$MODE" = "ci" ]; then
  if [ -n "${GITHUB_BASE_REF:-}" ]; then
    # In GitHub PR
    git fetch origin "${GITHUB_BASE_REF}" --depth=1 >/dev/null 2>&1 || true
    CHANGED_FILES="$(git diff --name-only "origin/${GITHUB_BASE_REF}" HEAD 2>/dev/null || git diff --name-only HEAD~1 HEAD)"
  else
    # In Push to branch
    CHANGED_FILES="$(git diff --name-only HEAD~1 HEAD 2>/dev/null || git diff --name-only HEAD)"
  fi
elif [ "$MODE" = "range" ]; then
  CHANGED_FILES="$(git diff --name-only "${COMMIT_RANGE}")"
else
  # Working directory + staged
  CHANGED_FILES="$(git status --porcelain | awk '{print $NF}')"
fi

# 4. Filter structural source files (Exclude lockfiles, markdown, gitignore)
# Included patterns:
# - Core code: .ts, .tsx, .js, .jsx, .vue, .svelte, .py, .go, .rs, .prisma, .sql, .graphql, .proto
# - System configs: Dockerfile*, docker-compose*.yml, .env.example
# - Architecture configs: *.yaml, *.yml, *.json (excluding locks)
STRUCTURAL_CHANGES=""
while IFS= read -r file; do
  [ -z "$file" ] && continue
  
  # Ignore non-structural files
  case "$file" in
    *package-lock.json|*pnpm-lock.yaml|*yarn.lock|*bun.lockb|*Cargo.lock|*poetry.lock|*go.sum)
      continue
      ;;
    *.md|*.mdx|*.txt|*.png|*.jpg|*.svg|*.gif|*.ico|.gitignore|.env)
      continue
      ;;
    .github/*|.cursor/*|.claude/*|.agents/*|skills/*)
      continue
      ;;
  esac

  # Match structural extensions and patterns
  if [[ "$file" =~ \.(ts|tsx|js|jsx|vue|svelte|py|go|rs|prisma|sql|graphql|proto)$ ]] || \
     [[ "$file" =~ (Dockerfile.*|docker-compose.*\.ya?ml|\.env\.example)$ ]] || \
     [[ "$file" =~ ^(src|apps|packages|lib|internal|cmd|api|server|client)/ ]]; then
    STRUCTURAL_CHANGES="${STRUCTURAL_CHANGES}${file}"$'\n'
  fi
done <<< "$CHANGED_FILES"

# Trim whitespace
STRUCTURAL_CHANGES="$(echo "$STRUCTURAL_CHANGES" | sed '/^[[:space:]]*$/d')"

if [ -z "$STRUCTURAL_CHANGES" ]; then
  echo "ℹ️ No structural source code changes detected. Architecture check passed."
  exit 0
fi

echo "📦 Structural changes detected in:"
echo "$STRUCTURAL_CHANGES" | sed 's/^/   • /'

# 5. Check if architecture file is updated in the same change set
ARCH_UPDATED=0
while IFS= read -r file; do
  if [ "$file" = "$ARCH_FILE" ]; then
    ARCH_UPDATED=1
    break
  fi
done <<< "$CHANGED_FILES"

if [ "$ARCH_UPDATED" -eq 1 ]; then
  # 6. Verify that ARCHITECTURE.md is not an empty/unconfirmed draft being silently left
  if grep -q "status=unconfirmed" "$ARCH_FILE" || grep -q "◼ 未確定" "$ARCH_FILE"; then
    echo "⚠️ Warning: ${ARCH_FILE} was updated but status remains '◼ 未確定' (Unconfirmed)."
    echo "   Ensure human review is conducted and status is elevated to '✅ 確定済' upon approval."
  fi
  echo "✅ [Vibe Arch Guard] Architecture synchronization check passed (${ARCH_FILE} updated)."
  exit 0
else
  echo ""
  echo "❌ [Vibe Arch Guard] FAIL-CLOSED: Architecture Drift Detected!"
  echo "   Structural files were modified without corresponding updates to ${ARCH_FILE}."
  echo ""
  echo "👉 Required Action:"
  echo "   1. Update §27 Changelog in ${ARCH_FILE} to record the architectural change."
  echo "   2. Update relevant sections (§1-§26) if modules, routes, schemas, or APIs were modified."
  echo "   3. Or run '/architecture-plan' to synchronize your design."
  echo ""
  if [ "$ALLOW_DRIFT" -eq 1 ]; then
    echo "⚠️ Warning: Drift bypass allowed via --allow-drift / ARCH_GUARD_ALLOW_DRIFT."
    exit 0
  fi
  exit 1
fi
