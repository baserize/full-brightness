# Install DisplayFit

## For Most Users

1. Open the latest release page:
   https://github.com/baserize/displayfit/releases/latest
2. Download `DisplayFit-2026.05.13.001.dmg`.
3. Open the downloaded DMG file.
4. Drag `DisplayFit.app` to `Applications`.
5. Open DisplayFit from `Applications`.

If macOS asks whether you want to open the app, choose `Open`.

## Homebrew

If you already use Homebrew, install DisplayFit with:

```sh
brew tap baserize/displayfit https://github.com/baserize/displayfit
brew install --cask displayfit
open -a DisplayFit
```

## Details

### Verify The Download

Compare the DMG checksum with the SHA-256 value printed in the release notes:

```sh
shasum -a 256 ~/Downloads/DisplayFit-2026.05.13.001.dmg
```

### macOS Security Notes

DisplayFit is Developer ID signed for direct distribution. If a release is not notarized yet, macOS Gatekeeper may ask for an extra confirmation the first time you open it.

Use the standard macOS path first:

1. Move `DisplayFit.app` to `Applications`.
2. Control-click `DisplayFit.app`.
3. Choose `Open`.
4. Confirm the dialog.

Only after verifying the release checksum, remove the quarantine flag manually if macOS still blocks launch:

```sh
xattr -dr com.apple.quarantine /Applications/DisplayFit.app
open -a DisplayFit
```

### Uninstall

Remove the app:

```sh
brew uninstall --cask displayfit
```

Remove saved preferences and app group data as well:

```sh
brew uninstall --zap --cask displayfit
```

DisplayFit does not require Accessibility or Screen Recording permission for the main brightness and layout flows. Control Center controls may need to be added again after replacing the app because macOS caches WidgetKit extensions.
