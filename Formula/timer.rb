class Timer < Formula
  desc "Minimalist command-line timer with smart time parsing"
  homepage "https://github.com/dandaniel5/minimal-timer"
  url "https://github.com/dandaniel5/minimal-timer/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "fe958e184fc77dccc87328587b7a703dade1c95551ae3ef8e2dc6f7d6b6684bb"
  license "GPL-3.0"

  depends_on "python@3"

  def install
    bin.install "timer.py" => "timer"
  end

  test do
    system "#{bin}/timer", "--help"
  end
end
