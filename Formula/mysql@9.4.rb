class MysqlAT94 < Formula
  desc "MySQL 9.4 – pre-built official binary"
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

  def install
    prefix.install Dir["*"]
    (var/"mysql@9.4").mkpath
    (var/"log/mysql@9.4").mkpath
    (var/"run/mysql@9.4").mkpath
  end

  def post_install
    return if (var/"mysql@9.4/mysql").exist?
    system opt_bin/"mysqld", "--initialize-insecure",
           "--user=#{ENV["USER"]}",
           "--basedir=#{opt_prefix}",
           "--datadir=#{var}/mysql@9.4",
           "--tmpdir=/tmp"
  end

  test do
    assert_match "9.4", shell_output("#{bin}/mysqld --version 2>&1")
  end
end
