class Timer < Formula
  desc "Minimalist command-line timer with smart time parsing"
  homepage "https://github.com/dandaniel5/minimal-timer"
  url "https://github.com/dandaniel5/minimal-timer/archive/refs/tags/v1.0.3.tar.gz"
  sha256 "a1ced2407cd2c653644672000f10f3b64566159dfa8a87f4ce92812550311071"
  license "GPL-3.0"

  depends_on "python@3"

  def install
    bin.install "timer.py" => "timer"
  end

  test do
    system "#{bin}/timer", "--help"
  end
end
