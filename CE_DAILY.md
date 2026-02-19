#!/usr/bin/env bash
set -euo pipefail

WS="${HOME}/.openclaw/workspace"
MEM_DIR="${WS}/memory"
TPL="${WS}/CE_DAILY.md"
OUT="${MEM_DIR}/$(date +%F).md"

mkdir -p "${MEM_DIR}"

{
  echo "# CE Daily Log — $(date +%F)"
  echo
  echo "Generated: $(date)"
  echo
  echo "## Repo snapshot"
  if git -C "${WS}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "- Branch: $(git -C "${WS}" branch --show-current 2>/dev/null || echo "unknown")"
    echo "- Last commit: $(git -C "${WS}" log -1 --pretty=format:'%h %s' 2>/dev/null || echo "none")"
    echo "- Status:"
    git -C "${WS}" status --porcelain 2>/dev/null | sed 's/^/  - /' || true
  else
    echo "- Not a git repo"
  fi
  echo
  echo "## Daily template"
  echo
  cat "${TPL}"
  echo
  echo "## Notes"
  echo "- "
} > "${OUT}"

echo "Wrote: ${OUT}"
