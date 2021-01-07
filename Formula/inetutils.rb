class Inetutils < Formula
  desc "GNU utilities for networking"
  homepage "https://www.gnu.org/software/inetutils/"
  url "https://ftp.gnu.org/gnu/inetutils/inetutils-1.9.4.tar.xz"
  mirror "https://ftpmirror.gnu.org/inetutils/inetutils-1.9.4.tar.xz"
  sha256 "849d96f136effdef69548a940e3e0ec0624fc0c81265296987986a0dd36ded37"
  revision 2

  livecheck do
    url :stable
  end

  bottle do
    sha256 "c91540c2e73378ddc2da24503537e096647b084e10bffd1d29311848c896f8b5" => :big_sur
    sha256 "cb29bc9d6c805fec9e9957dd2f67c2883bc0f4d141a0e1d9164fb6914c5fca77" => :arm64_big_sur
    sha256 "9f227bd3a357e822a8fbc399828a5ac3c06cc32c1d8d8e8da9a03a11f3df92e8" => :catalina
    sha256 "cd8d9c2d67518442b03bd4c6573a22408136fbfa54822db89db9236dca9d31bb" => :mojave
    sha256 "52c3e2f7e4d62cf0e0c742e81c026f591b9c331a338d110619b285d02a9d8b2f" => :high_sierra
    sha256 "40fc6bf3589516e420a3452c7effc46cb9463150680ab08ceed27206ddfe0b2a" => :sierra
  end

  depends_on "libidn"

  conflicts_with "telnet", because: "both install `telnet` binaries"
  conflicts_with "tnftp", because: "both install `ftp` binaries"

  def noshadow
    # List of binaries that do not shadow macOS utils
    list = %w[dnsdomainname rcp rexec rlogin rsh]
    list += %w[ftp telnet] if MacOS.version >= :high_sierra
    list
  end

  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --with-idn
    ]

    on_macos do
      args << "--program-prefix=g"
    end
    system "./configure", *args
    system "make", "install"

    on_macos do
      # Binaries not shadowing macOS utils symlinked without 'g' prefix
      noshadow.each do |cmd|
        bin.install_symlink "g#{cmd}" => cmd
        man1.install_symlink "g#{cmd}.1" => "#{cmd}.1"
      end

      # Symlink commands without 'g' prefix into libexec/gnubin and
      # man pages into libexec/gnuman
      bin.find.each do |path|
        next if !File.executable?(path) || File.directory?(path)

        cmd = path.basename.to_s.sub(/^g/, "")
        (libexec/"gnubin").install_symlink bin/"g#{cmd}" => cmd
        (libexec/"gnuman"/"man1").install_symlink man1/"g#{cmd}.1" => "#{cmd}.1"
      end
    end

    libexec.install_symlink "gnuman" => "man"
  end

  def caveats
    <<~EOS
      The following commands have been installed with the prefix 'g'.

          #{noshadow.sort.join("\n    ")}

      If you really need to use these commands with their normal names, you
      can add a "gnubin" directory to your PATH from your bashrc like:

          PATH="#{opt_libexec}/gnubin:$PATH"
    EOS
  end

  test do
    on_macos do
      output = pipe_output("#{libexec}/gnubin/ftp -v",
                         "open ftp.gnu.org\nanonymous\nls\nquit\n")
      assert_match "Connected to ftp.gnu.org.\n220 GNU FTP server ready", output
    end
    on_linux do
      output = pipe_output("#{bin}/ftp -v",
                         "open ftp.gnu.org\nanonymous\nls\nquit\n")
      assert_match "Connected to ftp.gnu.org.\n220 GNU FTP server ready", output
    end
  end
end
