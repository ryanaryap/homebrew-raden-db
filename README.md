# homebrew-raden-db

> Homebrew tap for **RADEN** — pre-built MySQL 9.x binaries for macOS (arm64 + x86_64).

[![Check Formula URLs](https://github.com/ryanaryap/homebrew-raden-db/actions/workflows/check-urls.yml/badge.svg)](https://github.com/ryanaryap/homebrew-raden-db/actions/workflows/check-urls.yml)
[![Check New Releases](https://github.com/ryanaryap/homebrew-raden-db/actions/workflows/check-new-releases.yml/badge.svg)](https://github.com/ryanaryap/homebrew-raden-db/actions/workflows/check-new-releases.yml)

---

## Why this tap?

Homebrew-core only keeps the **latest stable** MySQL release. If you need pinned older MySQL 9.x minor versions (for testing, production parity, or client-specific requirements), homebrew-core regularly removes them when a new minor is released.

This tap installs **official Oracle pre-built binaries** directly from `downloads.mysql.com/archives` — no compilation, no waiting.

---

## Available formulas

| Formula | MySQL Version | macOS Support | Arch |
|---|---|---|---|
| `mysql@9.4` | 9.4.0 | macOS 15 (Sequoia)+ | arm64, x86_64 |
| `mysql@9.3` | 9.3.0 | macOS 15 (Sequoia)+ | arm64, x86_64 |
| `mysql@9.2` | 9.2.0 | macOS 15 (Sequoia)+ | arm64, x86_64 |
| `mysql@9.1` | 9.1.0 | macOS 14 (Sonoma)+ | arm64, x86_64 |
| `mysql@9.0` | 9.0.1 | macOS 14 (Sonoma)+ | arm64, x86_64 |

> **Note:** MySQL 5.7, MySQL 8.x, and MariaDB 10.3–10.6 are **not included** because Oracle/MariaDB
> Foundation does not publish macOS binary tarballs for those versions in their archive servers.
>
> For MySQL 8.0, 8.4, and latest MySQL 9.x → use `homebrew-core` (`brew install mysql@8.4`).
> For MariaDB 10.11+ → use `homebrew-core` (`brew install mariadb@10.11`).

---

## Install

```bash
brew tap ryanaryap/raden-db
brew install ryanaryap/raden-db/mysql@9.4
```

### Start / Stop MySQL via brew services

```bash
brew services start ryanaryap/raden-db/mysql@9.4
brew services stop  ryanaryap/raden-db/mysql@9.4
```

### Connect

```bash
mysql -u root --socket $(brew --prefix)/var/mysql@9.4/mysql.sock
```

---

## How binaries are sourced

All binaries come directly from the **official MySQL CDN**:

```
https://downloads.mysql.com/archives/get/p/23/file/mysql-{VERSION}-{macos14|macos15}-{arm64|x86_64}.tar.gz
```

SHA256 hashes are computed from the official downloads and embedded in each formula.
Homebrew verifies these automatically at install time.

---

## Long-term maintenance

### Automated CI (GitHub Actions — every Monday)

| Workflow | What it does |
|---|---|
| **Check Formula URLs** | Verifies all 10 download URLs (5 formulas × 2 arch) return HTTP 200. Opens a GitHub issue if any are broken. |
| **Check New Releases** | Probes the MySQL CDN for newer patch versions. Opens a GitHub issue with update instructions if found. |

### Manual update script

When a new MySQL patch drops (e.g., 9.4.1):

```bash
cd RADEN/scripts/homebrew-raden-db

# Dry-run: see what would be updated
./update-formula.sh --check

# Apply updates (downloads ~300-600 MB per formula to compute SHA256)
./update-formula.sh          # all versions
./update-formula.sh 9.4      # specific version only

# Push
git add Formula/
git commit -m "chore: bump MySQL formulas to latest patch"
git push
```

---

## License

Tap scripts: MIT.
MySQL binaries: [GPL-2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) — downloaded
from Oracle's official servers, not redistributed here.
