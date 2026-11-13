# =============================================================================
# Homebrew cask — lets people run  brew install --cask <you>/tap/<app>   [mac] OPTIONAL
# =============================================================================
# Only for Mac apps distributed as a DMG (release-mac.yml). Homebrew reads
# casks from a separate "tap" repo named homebrew-tap, so to use this:
#   1. Create github.com/scootero/homebrew-tap
#   2. Copy this file there as Casks/<app-name-lowercase>.rb
#   3. Bump `version` after each release (or automate it in release-mac.yml)
# Users then install with:  brew install --cask scootero/tap/<name>
# =============================================================================
cask "StatsAttack" do
  version "0.1.0"
  sha256 :no_check   # skips checksum; fine for a personal tap

  url "https://github.com/scootero/StatsAttack/releases/download/v#{version}/StatsAttack.dmg"
  name "StatsAttack"
  desc "TODO: one-line description"
  homepage "https://scootero.github.io/StatsAttack/"

  depends_on macos: ">= :sonoma"   # match MACOS_MIN in ship.config

  app "StatsAttack.app"
end
