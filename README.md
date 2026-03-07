# homebrew-raden-db

Custom Homebrew tap for **RADEN** – provides pinned MySQL 9.x versions as pre-built official binaries (no compilation from source).

## Formulas in this tap

| Formula | Version | Binary source |
|---|---|---|
| `mysql@9.4` | 9.4.0 | downloads.mysql.com (macos15, arm64 + x86_64) |
| `mysql@9.3` | 9.3.0 | downloads.mysql.com (macos15, arm64 + x86_64) |
| `mysql@9.2` | 9.2.0 | downloads.mysql.com (macos15, arm64 + x86_64) |
| `mysql@9.1` | 9.1.0 | downloads.mysql.com (macos14, arm64 + x86_64) |
| `mysql@9.0` | 9.0.1 | downloads.mysql.com (macos14, arm64 + x86_64) |

> **Why only MySQL 9.x?**  
> MariaDB only publishes Linux binary tarballs — macOS is covered by homebrew-core.  
> MySQL 5.7/8.x are in homebrew-core. MySQL 9.x pinned versions are not in homebrew-core.

**Versions already in homebrew-core** (no tap needed, install directly):
- MySQL: `mysql` (latest 9.x), `mysql@8.4`, `mysql@8.0`
- MariaDB: `mariadb`, `mariadb@10.11`, `mariadb@11.4`, `mariadb@11.5`, `mariadb@11.6`
- PostgreSQL: `postgresql@13` through `postgresql@17`

## Setup (for developers publishing this tap)

### 1. Fill SHA256 checksums (do this once)
```bash
cd scripts/homebrew-raden-db
chmod +x fill-sha256.sh
./fill-sha256.sh --check   # verify URLs first (fast, no download)
./fill-sha256.sh           # fill SHA256 for all formulas
```

### 2. Push to GitHub
```bash
cd scripts/homebrew-raden-db
chmod +x setup-github.sh
./setup-github.sh YOUR_GITHUB_USERNAME
```

### 3. Configure RADEN tap
```bash
echo 'RADEN_DB_TAP="YOUR_GITHUB_USERNAME/raden-db"' >> ~/.raden/config.sh
```

## Usage (for end users via RADEN app)

RADEN handles tapping and installation automatically. Manual usage:
```bash
brew tap YOUR_GITHUB_USERNAME/raden-db
brew install YOUR_GITHUB_USERNAME/raden-db/mysql@9.4
brew install YOUR_GITHUB_USERNAME/raden-db/mariadb@10.6
```

## Architecture

All formulas download **official pre-built binaries** directly from:
- MySQL: `downloads.mysql.com` (Oracle official CDN)
- MariaDB: `archive.mariadb.org` (MariaDB Foundation official archive)

No cmake, no compilation, no 30-minute builds.
