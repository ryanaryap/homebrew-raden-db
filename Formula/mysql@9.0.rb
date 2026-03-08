class MysqlAT90 < Formula
  desc "MySQL 9.0 – pre-built official binary (pinned)"
  homepage "https://dev.mysql.com/doc/refman/9.0/en/"
  version "9.0.1"
  license "GPL-2.0-only"
  keg_only :versioned_formula

  on_arm do
    url "https://downloads.mysql.com/archives/get/p/23/file/mysql-9.0.1-macos14-arm64.tar.gz"
    sha256 "2bb8f95404e9cc6ab3122de76ff1e65a833ef6b873a3242e858168c32e0569ac"
  end

  on_intel do
    url "https://downloads.mysql.com/archives/get/p/23/file/mysql-9.0.1-macos14-x86_64.tar.gz"
    sha256 "12db0136d5de5f660881961ba12edad78a42780ec1d4683bfce432f50ce12e89"
  end

  conflicts_with "mysql",
                 "mysql@8.4",
                 "mysql@8.0",
                 "mysql@9.1",
                 "mysql@9.2",
                 "mysql@9.3",
                 "mysql@9.4",
                 because: "mysql versions install binaries with conflicting names"

  def install
    prefix.install Dir["*"]
    (var/"mysql@9.0").mkpath
    (var/"log/mysql@9.0").mkpath
  end

  def post_install
    return if (var/"mysql@9.0/mysql").exist?

    system opt_bin/"mysqld", "--initialize-insecure",
           "--user=#{ENV['USER']}",
           "--basedir=#{opt_prefix}",
           "--datadir=#{var}/mysql@9.0",
           "--tmpdir=/tmp"
  end

  service do
    run [opt_bin/"mysqld_safe",
         "--datadir=#{var}/mysql@9.0",
         "--pid-file=#{var}/mysql@9.0/mysqld.pid",
         "--socket=#{var}/mysql@9.0/mysql.sock",
         "--log-error=#{var}/log/mysql@9.0/error.log"]
    run_type :immediate
    working_dir HOMEBREW_PREFIX
    keep_alive true
    log_path var/"log/mysql@9.0/output.log"
    error_log_path var/"log/mysql@9.0/error.log"
  end

  def caveats
    <<~EOS
      MySQL 9.0 data directory: #{var}/mysql@9.0

      Start:   brew services start ryanaryap/raden-db/mysql@9.0
      Stop:    brew services stop ryanaryap/raden-db/mysql@9.0
      Connect: mysql -u root --socket #{var}/mysql@9.0/mysql.sock

      The initial root account has no password. Set one with:
        ALTER USER 'root'@'localhost' IDENTIFIED BY 'yourpassword';
    EOS
  end

  test do
    assert_match "9.0", shell_output("#{bin}/mysqld --version 2>&1")
  end
end
