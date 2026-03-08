class MysqlAT91 < Formula
  desc "MySQL 9.1 – pre-built official binary (pinned)"
  homepage "https://dev.mysql.com/doc/refman/9.1/en/"
  version "9.1.0"
  license "GPL-2.0-only"
  keg_only :versioned_formula

  on_arm do
    url "https://downloads.mysql.com/archives/get/p/23/file/mysql-9.1.0-macos14-arm64.tar.gz"
    sha256 "ecf95d05977dae03626e54d44a9139ac2cd5259e2e7e55c6f1cff002a6de15f2"
  end

  on_intel do
    url "https://downloads.mysql.com/archives/get/p/23/file/mysql-9.1.0-macos14-x86_64.tar.gz"
    sha256 "5116fd0178ebbd15ae379a803a798820f296b837a33fcf2e3f6c2da9071f6415"
  end

  conflicts_with "mysql",
                 "mysql@8.4",
                 "mysql@8.0",
                 "mysql@9.0",
                 "mysql@9.2",
                 "mysql@9.3",
                 "mysql@9.4",
                 because: "mysql versions install binaries with conflicting names"

  def install
    prefix.install Dir["*"]
    (var/"mysql@9.1").mkpath
    (var/"log/mysql@9.1").mkpath
  end

  def post_install
    return if (var/"mysql@9.1/mysql").exist?

    system opt_bin/"mysqld", "--initialize-insecure",
           "--user=#{ENV['USER']}",
           "--basedir=#{opt_prefix}",
           "--datadir=#{var}/mysql@9.1",
           "--tmpdir=/tmp"
  end

  service do
    run [opt_bin/"mysqld_safe",
         "--datadir=#{var}/mysql@9.1",
         "--pid-file=#{var}/mysql@9.1/mysqld.pid",
         "--socket=#{var}/mysql@9.1/mysql.sock",
         "--log-error=#{var}/log/mysql@9.1/error.log"]
    run_type :immediate
    working_dir HOMEBREW_PREFIX
    keep_alive true
    log_path var/"log/mysql@9.1/output.log"
    error_log_path var/"log/mysql@9.1/error.log"
  end

  def caveats
    <<~EOS
      MySQL 9.1 data directory: #{var}/mysql@9.1

      Start:   brew services start ryanaryap/raden-db/mysql@9.1
      Stop:    brew services stop ryanaryap/raden-db/mysql@9.1
      Connect: mysql -u root --socket #{var}/mysql@9.1/mysql.sock

      The initial root account has no password. Set one with:
        ALTER USER 'root'@'localhost' IDENTIFIED BY 'yourpassword';
    EOS
  end

  test do
    assert_match "9.1", shell_output("#{bin}/mysqld --version 2>&1")
  end
end
