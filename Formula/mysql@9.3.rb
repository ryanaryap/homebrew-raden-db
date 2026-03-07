class MysqlAT93 < Formula
  desc "MySQL 9.3 – pre-built official binary"
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

  def install
    prefix.install Dir["*"]
    (var/"mysql@9.3").mkpath
    (var/"log/mysql@9.3").mkpath
    (var/"run/mysql@9.3").mkpath
  end

  def post_install
    return if (var/"mysql@9.3/mysql").exist?
    system opt_bin/"mysqld", "--initialize-insecure",
           "--user=#{ENV["USER"]}",
           "--basedir=#{opt_prefix}",
           "--datadir=#{var}/mysql@9.3",
           "--tmpdir=/tmp"
  end

  test do
    assert_match "9.3", shell_output("#{bin}/mysqld --version 2>&1")
  end
end
