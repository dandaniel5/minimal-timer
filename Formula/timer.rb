class Timer < Formula
  desc "Minimalist command-line timer with smart time parsing"
  homepage "https://github.com/dandaniel5/minimal-timer"
  url "https://github.com/dandaniel5/minimal-timer/archive/v1.0.7.tar.gz"
  sha256 "ace20983a2e30c67d7532693219e527d64f670fe7b5af3c8e31be7f3e6bffe91"
  license "GPL-3.0"

  depends_on "python@3"

  def install
    bin.install "timer.py" => "timer"
  end

  test do
    system "#{bin}/timer", "-v"
  end
end
