class Timer < Formula
  desc "Minimalist command-line timer with smart time parsing"
  homepage "https://github.com/dandaniel5/minimal-timer"
  url "https://github.com/dandaniel5/minimal-timer/archive/refs/tags/v1.0.7.tar.gz"
  sha256 "4d490c64b0f3ab3c6edda811da10c1c1a31747231a20f37b5fafa0a66acb83f3"
  license "GPL-3.0"

  depends_on "python@3"

  def install
    bin.install "timer.py" => "timer"
  end

  test do
    system "#{bin}/timer", "-v"
  end
end
