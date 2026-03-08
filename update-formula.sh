#!/usr/bin/env bash
# update-formula.sh [minor_version]
#
# Checks for new patch versions on the MySQL CDN and updates the formula file
# with the new version + SHA256.  Can update one specific minor version or all.
#
# Examples:
#   ./update-formula.sh          # check all (9.0 – 9.4)
#   ./update-formula.sh 9.4      # check only 9.4.x
#   ./update-formula.sh --check  # dry-run: report new versions, do not update
#
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORMULA_DIR="$SCRIPT_DIR/Formula"

DRY_RUN=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --check|-n) DRY_RUN=1 ;;
    *)          TARGET="$arg" ;;
  esac
done

GRN='\033[0;32m'; YEL='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'

# ── Detect macOS identifier for a given MySQL minor version ──────────────────
mac_ver_for() {
  local minor
  minor="$1"
  case "$minor" in
    9.0|9.1) echo "macos14" ;;
    *)       echo "macos15" ;;
  esac
}

# ── Build CDN URL ─────────────────────────────────────────────────────────────
cdn_url() {
  local ver arch mac
  ver="$1"; arch="$2"
  mac=$(mac_ver_for "${ver%.*}")
  echo "https://downloads.mysql.com/archives/get/p/23/file/mysql-${ver}-${mac}-${arch}.tar.gz"
}

# ── Probe latest patch for a minor version ───────────────────────────────────
# Strategy: try incrementing patch from current up to +5 max.
latest_patch_for() {
  local minor current_patch best
  minor="$1"; current_patch="$2"
  best="$current_patch"
  local major mid patch
  major="${minor%%.*}"; mid="${minor##*.}"
  patch="${current_patch##*.}"
  for delta in 1 2 3 4 5; do
    local try_patch=$(( patch + delta ))
    local try_ver="${major}.${mid}.${try_patch}"
    local url; url=$(cdn_url "$try_ver" "arm64")
    local code; code=$(curl -sIo /dev/null -w "%{http_code}" "$url")
    if [[ "$code" == "200" ]]; then
      best="$try_ver"
    else
      break
    fi
  done
  echo "$best"
}

# ── Compute SHA256 from URL (streaming, no disk) ──────────────────────────────
sha_from_url() {
  local url
  url="$1"
  curl -fsSL "$url" | shasum -a 256 | awk '{print $1}'
}

# ── Update formula file ───────────────────────────────────────────────────────
update_formula() {
  local minor new_ver rb mac
  minor="$1"; new_ver="$2"
  rb="$FORMULA_DIR/mysql@${minor}.rb"
  mac=$(mac_ver_for "$minor")

  echo "  → Downloading arm64 binary to compute SHA256…"
  local arm64_sha; arm64_sha=$(sha_from_url "$(cdn_url "$new_ver" "arm64")")
  echo "  ✓ arm64 SHA256: $arm64_sha"

  echo "  → Downloading x86_64 binary to compute SHA256…"
  local x86_sha; x86_sha=$(sha_from_url "$(cdn_url "$new_ver" "x86_64")")
  echo "  ✓ x86_64 SHA256: $x86_sha"

  local arm64_url; arm64_url=$(cdn_url "$new_ver" "arm64")
  local x86_url; x86_url=$(cdn_url "$new_ver" "x86_64")

  # Use Python for reliable in-place file editing
  python3 - "$rb" "$new_ver" "$arm64_url" "$arm64_sha" "$x86_url" "$x86_sha" << 'PYEOF'
import sys, re

rb_path, new_ver, arm64_url, arm64_sha, x86_url, x86_sha = sys.argv[1:]

with open(rb_path) as f:
    c = f.read()

# Update version
c = re.sub(r'version "[^"]*"', f'version "{new_ver}"', c)
# Update arm64 url + sha256
c = re.sub(
    r'(on_arm do\s+url ")[^"]*("\s+sha256 ")[^"]*(")',
    lambda m: f'{m.group(1)}{arm64_url}{m.group(2)}{arm64_sha}{m.group(3)}',
    c, flags=re.DOTALL
)
# Update x86_64 url + sha256
c = re.sub(
    r'(on_intel do\s+url ")[^"]*("\s+sha256 ")[^"]*(")',
    lambda m: f'{m.group(1)}{x86_url}{m.group(2)}{x86_sha}{m.group(3)}',
    c, flags=re.DOTALL
)
with open(rb_path, "w") as f:
    f.write(c)
print("formula updated")
PYEOF
}

# ── Main loop ─────────────────────────────────────────────────────────────────
all_minors=("9.0" "9.1" "9.2" "9.3" "9.4")
updated_any=0

echo "=================================================="
echo " homebrew-raden-db formula updater"
[[ "$DRY_RUN" -eq 1 ]] && echo " Mode: dry-run (--check)" || echo " Mode: update"
echo "=================================================="

for minor in "${all_minors[@]}"; do
  [[ -n "$TARGET" && "$TARGET" != "$minor" ]] && continue

  rb="$FORMULA_DIR/mysql@${minor}.rb"
  [[ ! -f "$rb" ]] && echo "${YEL}⚠ $rb not found, skipping${NC}" && continue

  current_ver=$(grep -m1 'version "' "$rb" | sed 's/.*version "//;s/"//')
  echo ""
  echo "-- mysql@${minor} (current: ${current_ver}) --"
  echo "  → Checking for newer patch on MySQL CDN…"

  latest=$(latest_patch_for "$minor" "$current_ver")

  if [[ "$latest" == "$current_ver" ]]; then
    echo -e "  ${GRN}✓ Already up-to-date (${current_ver})${NC}"
    continue
  fi

  echo -e "  ${YEL}↑ New patch available: ${current_ver} → ${latest}${NC}"
  updated_any=1

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  (dry-run — skipping download and formula update)"
    continue
  fi

  update_formula "$minor" "$latest"
  echo -e "  ${GRN}✓ mysql@${minor} updated to ${latest}${NC}"
done

echo ""
if [[ "$DRY_RUN" -eq 1 && "$updated_any" -eq 1 ]]; then
  echo "Run without --check to apply updates."
elif [[ "$updated_any" -eq 0 ]]; then
  echo "All formulas are up-to-date."
else
  echo "Done. Run: git add . && git commit -m 'chore: update MySQL formulas' && git push"
fi
