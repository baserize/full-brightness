# DisplayFit

[한국어 문서](README.ko.md)

DisplayFit is a macOS menu bar utility that restores connected displays to your preferred brightness and desk layout. Use it from the main window, menu bar, Control Center, Shortcuts, Siri, or Spotlight.

Current release: [`2026.05.13.001`](https://github.com/baserize/displayfit/releases/tag/2026.05.13.001)

## Why

I built DisplayFit for shared desk setups where monitor brightness and arrangement are always left in someone else's state. The desk monitors at the Apple Developer Academy I attend can be adjusted directly from a Mac, but every time I moved to a new seat I had to set brightness and layout again. I wanted that setup step to disappear.

## Features

- **Choose your own Full level**
  Set the brightness level that counts as Full for your setup, from 1% to 100%.

- **Set connected displays at once**
  Apply your Full level to every connected display that macOS allows the app to control.

- **Auto Full on connect**
  When enabled, newly connected supported displays are raised to your Full level automatically.

- **Save display layout fits**
  Save the current monitor positions as a DisplayFit profile and apply it again later.

- **Auto Fit on connect**
  Apply a saved display layout when known monitors connect.

- **New display prompt**
  When a new monitor appears, DisplayFit can ask whether to save the current layout, apply a saved fit, or place the display to the left, right, above, or below the main display.

- **Default placement for future displays**
  Pick where an unseen display should appear before it is connected. Fine tuning is available when you need precise horizontal or vertical offsets.

- **Layout drift warning**
  If you move displays manually while DisplayFit is already open, the app shows that the current layout differs from the saved fit instead of forcing it back immediately. Auto Fit runs when a display connects.

- **Display support status**
  See which displays are brightness-adjustable and which ones are read-only or unsupported.

- **Resolution and HiDPI details**
  Shows logical resolution, backing pixel resolution, HiDPI scale, and refresh rate when macOS reports them.

- **Live brightness refresh**
  Updates the display list when brightness changes outside the app, including macOS display controls and hardware keys.

- **Control Center controls**
  Adds two WidgetKit controls:
  - `Display Full`: apply your Full level now.
  - `On connect Full`: toggle automatic Full brightness for newly connected displays.

- **Menu bar utility**
  Access refresh, one-click Full brightness, saved layout application, auto modes, display status, settings, app opening, and quit from the menu bar.

- **App Shortcuts**
  Provides localized Shortcuts, Siri, and Spotlight actions:
  - `Displays Full`
  - `Auto Full On`
  - `Auto Full Off`

- **Custom keyboard shortcuts**
  Record shortcuts for setting displays to Full and refreshing the display list. Duplicate and reserved shortcuts are rejected before they are saved.

- **English and Korean**
  Includes English and Korean UI strings and documentation.

## Requirements

- macOS 26 or newer
- Apple Silicon or Intel Mac
- Xcode 26 or newer only when building from source

## Install

### DMG, Recommended

Download the DMG from the [latest release page](https://github.com/baserize/displayfit/releases/latest), open it, and drag the app to `Applications`.

Direct download:

```sh
curl -L -o DisplayFit-2026.05.13.001.dmg \
  https://github.com/baserize/displayfit/releases/download/2026.05.13.001/DisplayFit-2026.05.13.001.dmg
open DisplayFit-2026.05.13.001.dmg
```

The DMG is the default install path. See [INSTALL.md](INSTALL.md) for Homebrew, DMG verification, and macOS Gatekeeper notes. A ZIP asset is also published for automation and troubleshooting.

### Homebrew

Install through the repo cask tap:

```sh
brew tap baserize/displayfit https://github.com/baserize/displayfit
brew install --cask displayfit
```

If Gatekeeper blocks first launch for an unnotarized build, follow [INSTALL.md](INSTALL.md) before removing quarantine manually.

Or install directly from the cask URL:

```sh
brew install --cask https://raw.githubusercontent.com/baserize/displayfit/main/Casks/displayfit.rb
```

Uninstall:

```sh
brew uninstall --cask displayfit
```

Remove app data as well:

```sh
brew uninstall --zap --cask displayfit
```

## Why Direct Distribution

DisplayFit is not targeting App Store distribution. To control Apple built-in displays in a way that matches macOS brightness behavior, the direct distribution build uses a runtime-loaded private `DisplayServices` brightness path with a public IOKit fallback. Public APIs alone are limited for this use case, especially on Apple-native display brightness paths.

Because that private display path may not satisfy App Store review requirements, DisplayFit is distributed through GitHub Releases and Homebrew instead.

## Use

1. Open DisplayFit.
2. Review the display list and support status.
3. Open Settings and choose your Full brightness level if 100% is not the right target.
4. Click `Connected displays Full` to apply that level to all supported displays.
5. Turn on `Auto Full on connect` if new supported displays should be raised automatically.
6. Open Arrangement and click `Save Current Layout` to save the current monitor placement.
7. Turn on `Auto Fit on connect` if known displays should be arranged automatically.
8. Enable launch at login from Settings if you want the app ready after restart.

## Control Center

After installing or running the app, open Control Center customization and search for DisplayFit. Add the controls if you want one-click brightness control without opening the app.

If macOS still shows an older control after a local rebuild, remove the old control, run the app from `/Applications/DisplayFit.app`, and add the controls again.

## Display Support

DisplayFit can control brightness when macOS exposes a writable brightness path. The current Direct build targets:

- Apple built-in displays and Apple-native display brightness paths exposed through macOS `DisplayServices`
- Displays that expose writable brightness through public IOKit `kIODisplayBrightnessKey`

Some displays will still appear as unsupported. Common causes:

- The monitor only supports DDC/CI brightness control
- A dock, KVM, cable, adapter, or DisplayLink-style driver hides the brightness channel
- macOS reports the display but does not expose writable brightness controls for it

Unsupported displays are still listed so you can confirm that macOS sees them. The app does not guess or simulate brightness when the display does not expose a real writable control path.

## Display Arrangement

DisplayFit reads each connected display's bounds with Core Graphics and saves positions by display fingerprint. A fingerprint combines vendor ID, product ID, serial number when available, display name, and logical resolution so saved layouts can be matched again later.

Saved layouts are applied with a Core Graphics display configuration transaction. DisplayFit uses session-level application by default, so a layout can be restored without permanently rewriting the user's macOS display arrangement.

Saving the current layout creates a device fit keyed by the connected display names and fingerprint set. When the same monitor combination reconnects, DisplayFit selects that profile automatically, and `Auto Fit on connect` applies the saved layout for that device set when a display connection event occurs.

You can also choose the default position for the next new display before it is connected. Set `New Display Defaults` in Settings, and DisplayFit will place the new display left, right, above, or below the main display without showing the prompt first. For more exact desk layouts, the collapsed `Fine tune position` controls add horizontal and vertical offsets to that default.

For an external display that does not have its own device fit yet, the new-display prompt can remember the chosen position for that display, so the next reconnect can use the same placement rule without creating a full device fit.

If you manually rearrange displays while DisplayFit is already open, the app does not immediately restore the saved layout. It shows a warning that the current layout differs from the saved fit, then waits for the next display connection event or an explicit `Apply Saved Fit` action.

Some setups can still be ambiguous:

- Multiple identical monitors may report no serial number
- A dock, KVM, adapter, or DisplayLink-style driver can change display identity
- macOS may adjust requested positions to remove gaps or overlaps

## Build From Source

```sh
./script/build_and_run.sh --verify
```

The script regenerates `DisplayFit.xcodeproj` from `project.yml`, builds the app with Xcode, installs it to `/Applications/DisplayFit.app` by default, and launches it for verification.

Build without installing or launching:

```sh
./script/build_and_run.sh --build-only --no-install
```

Build Release:

```sh
./script/build_and_run.sh --release --build-only --no-install
```

Both Debug and Release include `DIRECT_DISTRIBUTION` and the runtime-loaded `DisplayServices` brightness backend. The main app uses `Sources/App/DisplayFitDirect.entitlements`; the Control Center extension keeps its sandbox and app-group entitlements.

## Package

Create a Developer ID release package:

```sh
./script/package_direct.sh
```

With notarization:

```sh
NOTARYTOOL_PROFILE=displayfit-notary ./script/package_direct.sh
```

For a local package check without a Developer ID certificate:

```sh
./script/package_direct.sh --local
```

Artifacts are written to `.build/dist/direct/`. The package script stages `DisplayFit.app`, creates DMG and ZIP artifacts, prints SHA-256 values, verifies the exported signature, and staples notarization tickets when `NOTARYTOOL_PROFILE` is set.

## Version

The current release uses:

- GitHub release tag: `2026.05.13.001`
- `CFBundleShortVersionString`: `2026.5.13`
- `CFBundleVersion`: `20260513001`
