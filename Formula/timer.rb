class Timer < Formula
  desc "Minimalist command-line timer with smart time parsing"
  homepage "https://github.com/dandaniel5/minimal-timer"
  url "https://github.com/dandaniel5/minimal-timer/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "e0e979bc78fc13b39a673054e9453dca1df3a17eec0df092c080262e9a741b01"
  license "MIT"

  depends_on "python@3"

  def install
    bin.install "timer.py" => "timer"
  end

  test do
    system "#{bin}/timer", "--help"
  end
end
