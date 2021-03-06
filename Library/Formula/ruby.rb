require 'formula'

class Ruby < Formula
  url 'http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p180.tar.bz2'
  homepage 'http://www.ruby-lang.org/en/'
  head 'http://svn.ruby-lang.org/repos/ruby/trunk/', :using => :svn
  md5 '68510eeb7511c403b91fe5476f250538'
  GNU_GCC = '/usr/bin/gcc-4.2'

  depends_on 'readline'
  depends_on 'libyaml'

  fails_with_llvm :build => 2326

  # Stripping breaks dynamic linking
  skip_clean :all

  def options
    [
      ["--with-suffix", "Add a 19 suffix to commands"],
      ["--with-doc", "Install with the Ruby documentation"],
      ["--universal", "Compile a universal binary (arch=x86_64,i386)"],
    ]
  end

  def install
    # Fibers don't work with when compiling Ruby with LLVM gcc.
    if File.exist?(GNU_GCC)
      ENV['CC'] = GNU_GCC
    else
      puts "Warning! real GNU GCC not found. May have problems with Fibers"
      puts "when using LLVM gcc. Get real gcc at:"
      puts "https://github.com/jcliff/osx-gcc-installer/downloads"
    end

    ruby_lib = HOMEBREW_PREFIX+"lib/ruby"

    if File.exist? ruby_lib and File.symlink? ruby_lib
      opoo "#{ruby_lib} exists as a symlink"
      puts <<-EOS.undent
        The previous Ruby formula symlinked #{ruby_lib} into Ruby's Cellar.

        This version creates this as a "real folder" in HOMEBREW_PREFIX
        so that installed gems will survive between Ruby updates.

        Please remove this existing symlink before continuing:
          rm #{ruby_lib}
      EOS
      exit 1
    end

    system "autoconf" unless File.exists? 'configure'

    args = ["--prefix=#{prefix}",
            "--disable-debug",
            "--disable-dependency-tracking",
            "--enable-shared"]

    args << "--program-suffix=19" if ARGV.include? "--with-suffix"
    args << "--with-arch=x86_64,i386" if ARGV.build_universal?

    # Put gem, site and vendor folders in the HOMEBREW_PREFIX

    (ruby_lib+'site_ruby').mkpath
    (ruby_lib+'vendor_ruby').mkpath
    (ruby_lib+'gems').mkpath

    (lib+'ruby').mkpath
    ln_s (ruby_lib+'site_ruby'), (lib+'ruby')
    ln_s (ruby_lib+'vendor_ruby'), (lib+'ruby')
    ln_s (ruby_lib+'gems'), (lib+'ruby')

    system "./configure", *args
    system "make"
    system "make install"
    system "make install-doc" if ARGV.include? "--with-doc"

  end

  def caveats; <<-EOS.undent
    NOTE: By default, gem installed binaries will be placed into:
      #{bin}

    You may want to add this to your PATH.
    EOS
  end
end
