class MysqlAT95 < Formula
  desc "MySQL 9.5 – pre-built official binary (pinned)"
  homepage "https://dev.mysql.com/doc/refman/9.5/en/"
  version "9.5.0"
  license "GPL-2.0-only"
  keg_only :versioned_formula

  on_arm do
    url "https://cdn.mysql.com/archives/mysql-9.5/mysql-9.5.0-macos15-arm64.tar.gz"
    sha256 "077a1c8441629564dc11f149b89358befb2664d79b313876bf46715972ad6ca2"
  end

  on_intel do
    url "https://cdn.mysql.com/archives/mysql-9.5/mysql-9.5.0-macos15-x86_64.tar.gz"
    sha256 "c67db65a22311c1b1fc5972c3edd1dfcd60e87e5c7be1cc88606ab7dcd5cfaf3"
  end

  conflicts_with "mysql",
                 "mysql@8.4",
                 "mysql@8.0",
                 "mysql@9.4",
                 "mysql@9.3",
                 "mysql@9.2",
                 "mysql@9.1",
                 "mysql@9.0",
                 because: "mysql versions install binaries with conflicting names"

  def install
    prefix.install Dir["*"]
    (var/"mysql@9.5").mkpath
    (var/"log/mysql@9.5").mkpath
  end

  def post_install
    return if (var/"mysql@9.5/mysql").exist?

    system opt_bin/"mysqld", "--initialize-insecure",
           "--user=#{ENV['USER']}",
           "--basedir=#{opt_prefix}",
           "--datadir=#{var}/mysql@9.5",
           "--tmpdir=/tmp"
  end

  service do
    run [opt_bin/"mysqld_safe",
         "--datadir=#{var}/mysql@9.5",
         "--pid-file=#{var}/mysql@9.5/mysqld.pid",
         "--socket=#{var}/mysql@9.5/mysql.sock",
         "--log-error=#{var}/log/mysql@9.5/error.log"]
    run_type :immediate
    working_dir HOMEBREW_PREFIX
    keep_alive true
    log_path var/"log/mysql@9.5/output.log"
    error_log_path var/"log/mysql@9.5/error.log"
  end

  def caveats
    <<~EOS
      MySQL 9.5 data directory: #{var}/mysql@9.5

      Start:   brew services start ryanaryap/raden-db/mysql@9.5
      Stop:    brew services stop ryanaryap/raden-db/mysql@9.5
      Connect: mysql -u root --socket #{var}/mysql@9.5/mysql.sock

      The initial root account has no password. Set one with:
        ALTER USER 'root'@'localhost' IDENTIFIED BY 'yourpassword';
    EOS
  end

  test do
    assert_match "9.5", shell_output("#{bin}/mysqld --version 2>&1")
  end
end
