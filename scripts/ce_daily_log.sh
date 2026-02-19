#!/usr/bin/env bash
set -euo pipefail

WS="$HOME/.openclaw/workspace"
MEMDIR="$WS/memory"
TEMPLATE="$WS/CE_DAILY.md"

mkdir -p "$MEMDIR"

DATE="$(date +%F)"                # YYYY-MM-DD
OUT="$MEMDIR/$DATE.md"

# If today's file already exists, do nothing.
if [ -f "$OUT" ]; then
  exit 0
fi

{
  echo "# CE Daily Log — $DATE"
  echo
  echo "Generated: $(date)"
  echo
  echo "## Repo snapshot"
  if [ -d "$WS/.git" ]; then
    (cd "$WS" && echo "- Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)")
    (cd "$WS" && echo "- Last commit: $(git log -1 --oneline 2>/dev/null || true)")
    (cd "$WS" && echo "- Status:" && git status --porcelain 2>/dev/null | sed 's/^/  - /' || true)
  else
    echo "- Not a git repo: $WS"
  fi
  echo
  echo "## Daily template"
  if [ -f "$TEMPLATE" ]; then
    cat "$TEMPLATE"
  else
    echo "Missing template: CE_DAILY.md"
  fi
  echo
  echo "---"
  echo "Notes:"
  echo "- "
} > "$OUT"
