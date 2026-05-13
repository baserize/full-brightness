# DisplayFit 2026.05.13.001

## What Changed

- Added display layout profiles keyed by connected device names and display fingerprints.
- Added Auto Fit on connect for known monitor combinations.
- Added new-display placement defaults, including optional fine tuning offsets for future monitors.
- Added a new-display prompt that can remember a placement rule for a specific device.
- Changed layout behavior so manual arrangement changes while the app is open show a warning instead of immediately snapping back. Saved layouts are applied on display connection or by pressing `Apply Saved Fit`.
- Refined the arrangement preview so adjacent monitors are shown as separate tiles without distorting the real saved coordinates.
- Updated DisplayFit branding, bundle identifiers, menu labels, README, Homebrew cask, and installation guidance.

## Install

Recommended install path:

```sh
brew tap baserize/displayfit https://github.com/baserize/displayfit
brew install --cask displayfit
```

If Gatekeeper blocks first launch because the build is not notarized, verify the checksum and then run:

```sh
xattr -dr com.apple.quarantine /Applications/DisplayFit.app
```

DMG install:

1. Download `DisplayFit-2026.05.13.001.dmg` from this release.
2. Open the DMG.
3. Drag `DisplayFit.app` to `Applications`.

## Documentation

- README: https://github.com/baserize/displayfit/blob/main/README.md
- 한국어 README: https://github.com/baserize/displayfit/blob/main/README.ko.md
- Install guide: https://github.com/baserize/displayfit/blob/main/INSTALL.md
- 한국어 설치 설명서: https://github.com/baserize/displayfit/blob/main/INSTALL.ko.md

## macOS Security Notes

DisplayFit is Developer ID signed for direct distribution. This release may require the standard macOS first-launch confirmation if notarization credentials are not available during packaging. See the install guide before removing quarantine flags manually.

## Checksums

```text
1ada542a4a086a438eb3b7cc5ad925b7df0099d420c731e7e5d0966b79f56e54  DisplayFit-2026.05.13.001.dmg
5a0587f9fc62c86e81d7e61e01036a75b25804cacb3f551bcb6494e0d57360f2  DisplayFit-2026.05.13.001.zip
```
