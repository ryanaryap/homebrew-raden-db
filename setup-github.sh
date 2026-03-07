#!/usr/bin/env bash
# setup-github.sh <github-username>
# Initializes the homebrew-raden-db git repo and pushes to GitHub.
# Requires: git, gh (GitHub CLI) or manual PAT setup.
set -euo pipefail

GITHUB_USER="${1:-}"
if [[ -z "$GITHUB_USER" ]]; then
  echo "Usage: ./setup-github.sh <your-github-username>"
  echo "Example: ./setup-github.sh johndoe"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

REPO_NAME="homebrew-raden-db"
REMOTE_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

echo "=================================================="
echo " Setting up: github.com/${GITHUB_USER}/${REPO_NAME}"
echo "=================================================="

# ── Check for unfilled SHA256 placeholders ────────────────────────────────────
UNFILLED=$(grep -l "FILL_SHA256" Formula/*.rb 2>/dev/null | wc -l | tr -d ' ')
if [[ "$UNFILLED" -gt "0" ]]; then
  echo ""
  echo "⚠️  WARNING: $UNFILLED formula(s) still have placeholder SHA256 values:"
  grep -l "FILL_SHA256" Formula/*.rb | sed 's|.*/||' | sed 's/\.rb//' | sed 's/^/   ✗ /'
  echo ""
  echo "Run ./fill-sha256.sh first to download binaries and fill in SHA256."
  echo "Pushing formulas with placeholder SHA256 will cause 'brew install' to fail."
  read -p "Continue anyway? [y/N] " -n 1 -r
  echo
  [[ "$REPLY" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

# ── Init git repo if needed ───────────────────────────────────────────────────
if [[ ! -d .git ]]; then
  echo "Initializing git repo…"
  git init
  git branch -m main
fi

# ── Commit all files ──────────────────────────────────────────────────────────
echo "Adding files…"
git add .
git diff --cached --quiet && echo "Nothing to commit." || git commit -m "chore: add RADEN DB tap formulas"

# ── Create GitHub repo via gh CLI (preferred) or prompt for manual ─────────────
if command -v gh &>/dev/null; then
  echo "Creating GitHub repo via gh CLI…"
  gh repo create "${GITHUB_USER}/${REPO_NAME}" --public --description "Homebrew tap for RADEN — MySQL, MariaDB pre-built binaries" 2>/dev/null || true
  git remote remove origin 2>/dev/null || true
  git remote add origin "$REMOTE_URL"
  git push -u origin main
  echo ""
  echo "✓ Pushed to: $REMOTE_URL"
else
  echo ""
  echo "GitHub CLI (gh) not found. To push manually:"
  echo ""
  echo "  1. Create repo at: https://github.com/new"
  echo "     Name: ${REPO_NAME}   Visibility: Public"
  echo ""
  echo "  2. Then run:"
  echo "     git remote add origin $REMOTE_URL"
  echo "     git push -u origin main"
fi

echo ""
echo "=================================================="
echo " After pushing, configure RADEN:"
echo ""
echo "   echo 'RADEN_DB_TAP=\"${GITHUB_USER}/raden-db\"' >> ~/.raden/config.sh"
echo ""
echo " Then in RADEN, all DB versions will be installable via the tap."
echo "=================================================="
