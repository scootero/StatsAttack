<!--
=============================================================================
store/metadata/en-US.md — your App Store listing, as a file.   [core] PHASE 3
=============================================================================
WHY: the listing lives in git, so AI can draft and revise it, you get history,
and Scripts/asc-submit.mjs pushes it to App Store Connect on every release.
One file per language: en-US.md, de-DE.md, ... (file name = App Store locale).

FORMAT: each "## key" starts a field. Keep the keys exactly as written.
Everything inside these comment blocks is ignored by the script.

WHO READS WHAT: Scripts/asc-submit.mjs pushes EVERY field below to App Store
Connect (on a release, or with --metadata-only). Fields still starting with
"TODO" are skipped, so half-finished text never reaches Apple.
  name, subtitle, privacy_url  → "App Information" (shared by all versions)
  everything else              → this version's page
It also feeds the website (Scripts/build-site.mjs).

LIMITS (Apple rejects anything longer):
  name 30 (must be unique on the App Store) · subtitle 30 · promotional_text 170 · keywords 100 (comma-separated,
  no spaces needed) · description 4000 · whats_new 4000
=============================================================================
-->

## name
StatsAttack

## subtitle
<!-- ≤30 chars. The second most important search field after name. -->
Mac stats in your menu bar

## promotional_text
<!-- Can change ANY time without a new app version. Good for "New: ..." -->
See CPU, memory, disk and network at a glance, right from your menu bar. Click for the full picture.

## keywords
<!-- ≤100 chars total, comma-separated, no spaces needed. Don't repeat words already in the name/subtitle. -->
system,monitor,cpu,memory,ram,disk,network,battery,activity,performance,usage,gpu,speed

## description
<!-- DRAFT written before the app was built. Update it to match what actually ships. -->
StatsAttack puts your Mac's vital signs in the menu bar. One glance shows how hard your Mac is working; one click opens a detailed dropdown.

What you get:
• CPU — total load in the menu bar, per-core detail in the dropdown
• Memory — usage and memory pressure at a glance
• Disk — free space and live read/write speed
• Network — live upload/download speed
• Battery — charge, health and time remaining

Designed to stay out of your way:
• Tiny, fast, and light on battery
• Hover any row for live detail
• No accounts, no ads, no tracking

## support_url
https://scootero.github.io/StatsAttack/

## marketing_url
https://scootero.github.io/StatsAttack/

## privacy_url
<!-- REQUIRED by Apple. docs/privacy.html, published by pages.yml. -->
https://scootero.github.io/StatsAttack/privacy.html

## copyright
<!-- Shown on the store page, e.g. "2026 Scott Oliver". Not per-language: read from the first locale. -->
2026 Scott Oliver

## whats_new
<!-- Update this every release (bump-version.sh reminds you). Skipped automatically on the app's first version. -->
• First release.