# Install DisplayFit

DisplayFit is distributed through GitHub Releases and the repo Homebrew cask.

## Homebrew

```sh
brew tap baserize/displayfit https://github.com/baserize/displayfit
brew install --cask displayfit
open -a DisplayFit
```

If macOS blocks first launch because the current build is not notarized, verify the checksum in the release notes and remove the quarantine flag from the installed app:

```sh
xattr -dr com.apple.quarantine /Applications/DisplayFit.app
open -a DisplayFit
```

To remove the app:

```sh
brew uninstall --cask displayfit
```

To remove saved preferences and app group data as well:

```sh
brew uninstall --zap --cask displayfit
```

## DMG

Download `DisplayFit-2026.05.13.001.dmg` from the latest release:

https://github.com/baserize/displayfit/releases/latest

Open the DMG and drag `DisplayFit.app` to `Applications`.

## Verify The Download

Compare the DMG checksum with the SHA-256 value printed in the release notes:

```sh
shasum -a 256 ~/Downloads/DisplayFit-2026.05.13.001.dmg
```

## macOS Security Notes

DisplayFit is Developer ID signed for direct distribution. If a release is not notarized yet, macOS Gatekeeper may ask for an extra confirmation the first time you open it.

Use the standard macOS path first:

1. Move `DisplayFit.app` to `Applications`.
2. Control-click `DisplayFit.app`.
3. Choose `Open`.
4. Confirm the dialog.

Only after verifying the release checksum, you can remove the quarantine flag manually if macOS still blocks launch:

```sh
xattr -dr com.apple.quarantine /Applications/DisplayFit.app
open -a DisplayFit
```

DisplayFit does not require Accessibility or Screen Recording permission for the main brightness and layout flows. Control Center controls may need to be added again after replacing the app because macOS caches WidgetKit extensions.
