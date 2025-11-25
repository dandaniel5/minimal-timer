class Timer < Formula
  desc "Minimalist command-line timer with smart time parsing"
  homepage "https://github.com/dandaniel5/minimal-timer"
  url "https://github.com/dandaniel5/minimal-timer/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "4f22d14de8ff4fb9e764d128f7cdca61f0686bdd9606fcf112ffa495b529784d"
  license "MIT"

  depends_on "python@3"

  def install
    bin.install "timer.py" => "timer"
  end

  test do
    system "#{bin}/timer", "--help"
  end
end
