class MysqlAT92 < Formula
  desc "MySQL 9.2 – pre-built official binary"
  homepage "https://dev.mysql.com/doc/refman/9.2/en/"
  version "9.2.0"
  license "GPL-2.0-only"
  keg_only :versioned_formula

  on_arm do
    url "https://downloads.mysql.com/archives/get/p/23/file/mysql-9.2.0-macos15-arm64.tar.gz"
    sha256 "b00639f8a1da97a64031997467f5d8c899e1977a2750cf4bbbcb1b4417cb8a44"
  end

  on_intel do
    url "https://downloads.mysql.com/archives/get/p/23/file/mysql-9.2.0-macos15-x86_64.tar.gz"
    sha256 "e73048bbcca244845fc0c0115acba556875ccbbb352e400559fdb85e5d6e0113"
  end

  def install
    prefix.install Dir["*"]
    (var/"mysql@9.2").mkpath
    (var/"log/mysql@9.2").mkpath
    (var/"run/mysql@9.2").mkpath
  end

  def post_install
    return if (var/"mysql@9.2/mysql").exist?
    system opt_bin/"mysqld", "--initialize-insecure",
           "--user=#{ENV["USER"]}",
           "--basedir=#{opt_prefix}",
           "--datadir=#{var}/mysql@9.2",
           "--tmpdir=/tmp"
  end

  test do
    assert_match "9.2", shell_output("#{bin}/mysqld --version 2>&1")
  end
end
