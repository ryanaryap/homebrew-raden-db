class MysqlAT94 < Formula
  desc "MySQL 9.4 – pre-built official binary (pinned)"
  homepage "https://dev.mysql.com/doc/refman/9.4/en/"
  version "9.4.0"
  license "GPL-2.0-only"
  keg_only :versioned_formula

  on_arm do
    url "https://downloads.mysql.com/archives/get/p/23/file/mysql-9.4.0-macos15-arm64.tar.gz"
    sha256 "a363ccebe8c54c5747a2a297936cf7bd794d2a672cdd7436c7b005241fd13f6b"
  end

  on_intel do
    url "https://downloads.mysql.com/archives/get/p/23/file/mysql-9.4.0-macos15-x86_64.tar.gz"
    sha256 "1ee9ca3f27cfd481278959d065b31d87d1237304f29efe498d9b38b486b3e34e"
  end

  conflicts_with "mysql",
                 "mysql@8.4",
                 "mysql@8.0",
                 "mysql@9.0",
                 "mysql@9.1",
                 "mysql@9.2",
                 "mysql@9.3",
                 because: "mysql versions install binaries with conflicting names"

  def install
    prefix.install Dir["*"]
    (var/"mysql@9.4").mkpath
    (var/"log/mysql@9.4").mkpath
  end

  def post_install
    return if (var/"mysql@9.4/mysql").exist?

    system opt_bin/"mysqld", "--initialize-insecure",
           "--user=\#{ENV["USER"]}",
           "--basedir=\#{opt_prefix}",
           "--datadir=\#{var}/mysql@9.4",
           "--tmpdir=/tmp"
  end

  service do
    run [opt_bin/"mysqld_safe",
         "--datadir=\#{var}/mysql@9.4",
         "--pid-file=\#{var}/mysql@9.4/mysqld.pid",
         "--socket=\#{var}/mysql@9.4/mysql.sock",
         "--log-error=\#{var}/log/mysql@9.4/error.log"]
    run_type :immediate
    working_dir HOMEBREW_PREFIX
    keep_alive true
    log_path var/"log/mysql@9.4/output.log"
    error_log_path var/"log/mysql@9.4/error.log"
  end

  def caveats
    <<~EOS
      MySQL 9.4 data directory: \#{var}/mysql@9.4

      Start:   brew services start ryanaryap/raden-db/mysql@9.4
      Stop:    brew services stop ryanaryap/raden-db/mysql@9.4
      Connect: mysql -u root --socket \#{var}/mysql@9.4/mysql.sock

      The initial root account has no password. Set one with:
        ALTER USER 'root'@'localhost' IDENTIFIED BY 'yourpassword';
    EOS
  end

  test do
    assert_match "9.4", shell_output("\#{bin}/mysqld --version 2>&1")
  end
end
