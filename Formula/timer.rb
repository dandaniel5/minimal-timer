class Timer < Formula
  desc "Minimalist command-line timer with smart time parsing"
  homepage "https://github.com/dandaniel5/minimal-timer"
  url "https://github.com/dandaniel5/minimal-timer/archive/refs/tags/v1.0.4.tar.gz"
  sha256 "a5090cadabe2aa3f2c032a160baedb5781737756e851a114284b82be8afef28d"
  license "GPL-3.0"

  depends_on "python@3"

  def install
    bin.install "timer.py" => "timer"
  end

  test do
    system "#{bin}/timer", "--help"
  end
end
