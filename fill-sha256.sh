#!/usr/bin/env bash
# fill-sha256.sh — populate SHA256 in MySQL formula files before pushing to GitHub.
# Downloads each binary from the official Oracle CDN, computes SHA256, updates .rb.
#
# Usage:
#   ./fill-sha256.sh            # fill all formulas
#   ./fill-sha256.sh mysql@9.4  # fill one formula
#   ./fill-sha256.sh --check    # check URLs only (no download)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORMULA_DIR="$SCRIPT_DIR/Formula"

ARCH=$(uname -m)
CHECK_ONLY=0
TARGET="${1:-all}"
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=1 && TARGET="all"

RED='\033[0;31m'; YEL='\033[0;33m'; GRN='\033[0;32m'; NC='\033[0m'
ok()   { echo -e "${GRN}\u2713${NC} $*"; }
err()  { echo -e "${RED}\u2717${NC} $*" >&2; }
warn() { echo -e "${YEL}!${NC} $*"; }
info() { echo "  \u2192 $*"; }

# macOS build version per MySQL patch release
# Returns the macos<N> string that Oracle shipped that version for.
mysql_mac_ver() {
  local ver="$1"
  case "$ver" in
    8.0.26|8.0.27)         echo "macos11" ;;
    8.0.28|8.0.29|8.0.30|\
    8.0.31)                echo "macos12" ;;
    8.0.32|8.0.33|8.0.34|\
    8.0.35)                echo "macos13" ;;
    8.0.36|8.0.37|8.0.38|\
    8.0.39|8.0.40)         echo "macos14" ;;
    8.0.4*|8.0.3[6-9])     echo "macos14" ;;
    8.0.41|8.0.42|8.0.43|\
    8.0.44)                echo "macos15" ;;
    8.1.*)                 echo "macos13" ;;
    8.2.*)                 echo "macos13" ;;
    8.3.*)                 echo "macos14" ;;
    8.4.0|8.4.1|8.4.2|\
    8.4.3)                 echo "macos14" ;;
    8.4.4|8.4.5|8.4.6|\
    8.4.7)                 echo "macos15" ;;
    9.0.*|9.1.*)           echo "macos14" ;;
    9.*)                   echo "macos15" ;;
    *)                     echo "macos15" ;;
  esac
}

# MySQL download URL — uses cdn.mysql.com direct links (no redirects for Homebrew SHA256 verification)
mysql_url() {
  local ver arch mac_ver
  ver="$1"; arch="$2"
  mac_ver=$(mysql_mac_ver "$ver")
  echo "https://cdn.mysql.com/archives/mysql-${ver%.*}/mysql-${ver}-${mac_ver}-${arch}.tar.gz"
}
mysql_url_alt() {
  local ver arch mac_ver
  ver="$1"; arch="$2"
  # Alternate: try adjacent macOS version as fallback
  mac_ver=$(mysql_mac_ver "$ver")
  case "$mac_ver" in
    macos11) echo "https://cdn.mysql.com/archives/mysql-${ver%.*}/mysql-${ver}-macos12-${arch}.tar.gz" ;;
    macos12) echo "https://cdn.mysql.com/archives/mysql-${ver%.*}/mysql-${ver}-macos13-${arch}.tar.gz" ;;
    macos13) echo "https://cdn.mysql.com/archives/mysql-${ver%.*}/mysql-${ver}-macos14-${arch}.tar.gz" ;;
    macos14) echo "https://cdn.mysql.com/archives/mysql-${ver%.*}/mysql-${ver}-macos15-${arch}.tar.gz" ;;
    macos15) echo "https://cdn.mysql.com/archives/mysql-${ver%.*}/mysql-${ver}-macos14-${arch}.tar.gz" ;;
  esac
}

url_ok() {
  local code
  code=$(curl -sSL --head --write-out '%{http_code}' -o /dev/null --max-time 15 "$1" 2>/dev/null || echo "000")
  [[ "$code" == "200" || "$code" == "302" ]]
}

resolve_url() {
  local ver arch primary alt
  ver="$1"; arch="$2"
  primary=$(mysql_url "$ver" "$arch")
  alt=$(mysql_url_alt "$ver" "$arch")
  if url_ok "$primary"; then echo "$primary"; return 0; fi
  if url_ok "$alt";     then echo "$alt";     return 0; fi
  return 1
}

sha256_url() { curl -sSL "$1" | shasum -a 256 | awk '{print $1}'; }

update_sha256() {
  local file placeholder hash
  file="$1"; placeholder="$2"; hash="$3"
  grep -q "\"$placeholder\"" "$file" || return 1
  sed -i '' "s|\"$placeholder\"|\"$hash\"|g" "$file"
}

process() {
  local name rb all_ok patch_ver arch placeholder resolved_url hash
  name="$1"
  rb="$FORMULA_DIR/${name}.rb"
  [[ -f "$rb" ]] || { err "Formula not found: $rb"; return 1; }
  echo ""
  echo "-- $name --"

  local patch_ver
  patch_ver=$(grep -m1 '^\s*version "' "$rb" | sed 's/.*version "\(.*\)"/\1/' | tr -d '[:space:]')
  [[ -z "$patch_ver" ]] && patch_ver="$(echo "$name" | cut -d@ -f2).0"
  info "Patch version: $patch_ver"

  local all_ok=1
  for arch in arm64 x86_64; do
    local placeholder
    [[ "$arch" == "arm64" ]] && placeholder="FILL_SHA256_ARM64" || placeholder="FILL_SHA256_X86"
    if ! grep -q "\"$placeholder\"" "$rb" 2>/dev/null; then
      ok "$arch: already filled"; continue
    fi

    info "Resolving $arch URL..."
    local resolved_url
    if ! resolved_url=$(resolve_url "$patch_ver" "$arch"); then
      err "$arch: no working URL found"; all_ok=0; continue
    fi
    ok "$arch URL: $resolved_url"
    [[ "$CHECK_ONLY" == "1" ]] && continue

    info "Downloading and computing SHA256 (~300-600 MB)..."
    local hash; hash=$(sha256_url "$resolved_url")
    ok "$arch SHA256: $hash"
    sed -i '' "s|url \"[^\"]*mysql-${patch_ver}[^\"]*${arch}[^\"]*\"|url \"$resolved_url\"|g" "$rb" 2>/dev/null || true
    update_sha256 "$rb" "$placeholder" "$hash" && ok "$arch: formula updated" || warn "$arch: already replaced"
  done
  [[ "$all_ok" == "1" ]] && ok "$name: done" || warn "$name: check errors above"
}

echo "============================================="
echo " homebrew-raden-db SHA256 filler"
echo " Architecture: $ARCH"
[[ "$CHECK_ONLY" == "1" ]] && echo " Mode: URL check only (no download)"
echo "============================================="

if [[ "$TARGET" == "all" ]]; then
  for f in mysql@9.5 mysql@9.4 mysql@9.3 mysql@9.2 mysql@9.1 mysql@9.0 \
            mysql@8.4 mysql@8.3 mysql@8.2 mysql@8.1 mysql@8.0; do
    process "$f" || true
  done
else
  process "$TARGET"
fi

echo ""
echo "Formulas with FILL_SHA256 placeholders remaining:"
found=0
for rb in "$FORMULA_DIR"/*.rb; do
  if grep -q "FILL_SHA256" "$rb" 2>/dev/null; then
    echo "  x $(basename "$rb" .rb)"; found=1
  fi
done
[[ "$found" == "0" ]] && echo "  (none - all filled!)"
echo ""
echo "Next: git add . && git commit -m 'Fill SHA256' && git push"
