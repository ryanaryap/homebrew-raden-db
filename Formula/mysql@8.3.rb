class MysqlAT83 < Formula
  desc "MySQL 8.3 – pre-built official binary (pinned)"
  homepage "https://dev.mysql.com/doc/refman/8.3/en/"
  version "8.3.0"
  license "GPL-2.0-only"
  keg_only :versioned_formula

  on_arm do
    url "https://cdn.mysql.com/archives/mysql-8.3/mysql-8.3.0-macos14-arm64.tar.gz"
    sha256 "FILL_SHA256_ARM64"
  end

  on_intel do
    url "https://cdn.mysql.com/archives/mysql-8.3/mysql-8.3.0-macos14-x86_64.tar.gz"
    sha256 "FILL_SHA256_X86"
  end

  conflicts_with "mysql",
                 "mysql@8.4",
                 "mysql@8.3",
                 "mysql@8.2",
                 "mysql@8.1",
                 "mysql@8.0",
                 "mysql@9.5",
                 "mysql@9.4",
                 "mysql@9.3",
                 "mysql@9.2",
                 "mysql@9.1",
                 "mysql@9.0",
                 because: "mysql versions install binaries with conflicting names"

  def install
    prefix.install Dir["*"]
    (var/"mysql@8.3").mkpath
    (var/"log/mysql@8.3").mkpath
  end

  def post_install
    return if (var/"mysql@8.3/mysql").exist?

    system opt_bin/"mysqld", "--initialize-insecure",
           "--user=\#{ENV['USER']}",
           "--basedir=\#{opt_prefix}",
           "--datadir=\#{var}/mysql@8.3",
           "--tmpdir=/tmp"
  end

  service do
    run [opt_bin/"mysqld_safe",
         "--datadir=\#{var}/mysql@8.3",
         "--pid-file=\#{var}/mysql@8.3/mysqld.pid",
         "--socket=\#{var}/mysql@8.3/mysql.sock",
         "--log-error=\#{var}/log/mysql@8.3/error.log"]
    run_type :immediate
    working_dir HOMEBREW_PREFIX
    keep_alive true
    log_path var/"log/mysql@8.3/output.log"
    error_log_path var/"log/mysql@8.3/error.log"
  end

  def caveats
    <<~EOS
      MySQL 8.3 data directory: \#{var}/mysql@8.3

      Start:   brew services start ryanaryap/raden-db/mysql@8.3
      Stop:    brew services stop ryanaryap/raden-db/mysql@8.3
      Connect: mysql -u root --socket \#{var}/mysql@8.3/mysql.sock

      The initial root account has no password. Set one with:
        ALTER USER 'root'@'localhost' IDENTIFIED BY 'yourpassword';
    EOS
  end

  test do
    assert_match "8.3", shell_output("\#{bin}/mysqld --version 2>&1")
  end
end
