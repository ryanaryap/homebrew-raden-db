class MysqlAT93 < Formula
  desc "MySQL 9.3 – pre-built official binary (pinned)"
  homepage "https://dev.mysql.com/doc/refman/9.3/en/"
  version "9.3.0"
  license "GPL-2.0-only"
  keg_only :versioned_formula

  on_arm do
    url "https://downloads.mysql.com/archives/get/p/23/file/mysql-9.3.0-macos15-arm64.tar.gz"
    sha256 "5b8ca2df717b04b79075ca5edc5723eee9e15fa811fc52e91974c6dc69a25d17"
  end

  on_intel do
    url "https://downloads.mysql.com/archives/get/p/23/file/mysql-9.3.0-macos15-x86_64.tar.gz"
    sha256 "9b9c161d111f8e6f443a89a1733766d34e7bbd26a23768f17b3669266734791d"
  end

  conflicts_with "mysql",
                 "mysql@8.4",
                 "mysql@8.0",
                 "mysql@9.0",
                 "mysql@9.1",
                 "mysql@9.2",
                 "mysql@9.4",
                 because: "mysql versions install binaries with conflicting names"

  def install
    prefix.install Dir["*"]
    (var/"mysql@9.3").mkpath
    (var/"log/mysql@9.3").mkpath
  end

  def post_install
    return if (var/"mysql@9.3/mysql").exist?

    system opt_bin/"mysqld", "--initialize-insecure",
           "--user=#{ENV['USER']}",
           "--basedir=#{opt_prefix}",
           "--datadir=#{var}/mysql@9.3",
           "--tmpdir=/tmp"
  end

  service do
    run [opt_bin/"mysqld_safe",
         "--datadir=#{var}/mysql@9.3",
         "--pid-file=#{var}/mysql@9.3/mysqld.pid",
         "--socket=#{var}/mysql@9.3/mysql.sock",
         "--log-error=#{var}/log/mysql@9.3/error.log"]
    run_type :immediate
    working_dir HOMEBREW_PREFIX
    keep_alive true
    log_path var/"log/mysql@9.3/output.log"
    error_log_path var/"log/mysql@9.3/error.log"
  end

  def caveats
    <<~EOS
      MySQL 9.3 data directory: #{var}/mysql@9.3

      Start:   brew services start ryanaryap/raden-db/mysql@9.3
      Stop:    brew services stop ryanaryap/raden-db/mysql@9.3
      Connect: mysql -u root --socket #{var}/mysql@9.3/mysql.sock

      The initial root account has no password. Set one with:
        ALTER USER 'root'@'localhost' IDENTIFIED BY 'yourpassword';
    EOS
  end

  test do
    assert_match "9.3", shell_output("#{bin}/mysqld --version 2>&1")
  end
end
