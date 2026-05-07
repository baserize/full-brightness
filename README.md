# Full Brightness

[한국어 문서](README.ko.md)

Full Brightness is a macOS utility for display-heavy setups. It lists connected displays, shows resolution and HiDPI details, identifies which displays can be controlled, and sets supported displays to your chosen Full brightness level on demand or automatically when a new display connects.

## Why I Built It

Have you had this experience? The monitors on our Academy desks can be adjusted directly from a Mac, so whenever I sat down at a new spot, I would first set the brightness to my preference. I like working at MAX brightness. Raising brightness is a small thing, but I did not want to think about it every time, so I built Full Brightness.

## App Overview

Full Brightness is a small macOS menu bar utility that detects brightness-adjustable displays connected to your Mac and sets them to your chosen Full brightness level in one click. It can apply Full brightness automatically when a new display connects, and it can also be triggered from Control Center, Shortcuts, Siri, and Spotlight.

Current GitHub release: [`2026.05.08.001`](https://github.com/baserize/full-brightness/releases/tag/2026.05.08.001)

## Requirements

- macOS 26 or newer
- Apple Silicon or Intel Mac
- Xcode 26+ only when building from source
- For the default Direct build: Apple-native displays exposed through macOS `DisplayServices`, or displays that expose writable brightness through public IOKit brightness parameters
- For the Store-safe build: a display path that exposes writable brightness through public IOKit brightness parameters

Some monitors, docks, cables, KVMs, and DisplayLink-style adapters block brightness control. Full Brightness still lists those displays, but marks them as unsupported instead of changing them blindly.

## Key Features

- **Brightness-capable display detection**  
  Lists connected displays and clearly marks whether brightness can be read or written.

- **Custom Full brightness level**  
  Lets you define what Full means for your setup from 1% to 100% in Settings.

- **One-click Full brightness**  
  Sets every adjustable connected display to your Full level from the main window, menu bar, Control Center, Shortcuts, Siri, or Spotlight.

- **Automatic Full brightness on connection**  
  When auto mode is enabled, newly connected adjustable displays are raised to your Full level automatically.

- **Live brightness refresh**  
  Keeps the display list in sync when brightness changes outside the app, including macOS display controls and hardware keys.

- **Control Center controls**  
  Provides two WidgetKit controls for macOS Control Center:
  - `Display Full`: instantly sets supported displays to your Full level.
  - `On connect Full`: toggles automatic Full brightness for newly connected displays.

- **Menu bar utility**  
  Includes a compact menu bar extra with refresh, one-click Full brightness, auto mode, display status, app opening, settings, and quit actions.

- **Native Settings and Launch at Login**  
  Uses a standard macOS Settings window for the Full brightness level, keyboard shortcuts, and launch at login.

- **Custom keyboard shortcuts**  
  Lets you record shortcuts for setting displays to Full and refreshing the display list. Duplicate and reserved shortcut combinations are rejected before they are saved.

- **App Shortcuts integration**  
  Exposes App Intents-backed shortcuts for Shortcuts, Siri, and Spotlight:
  - `Displays Full`
  - `Auto Full On`
  - `Auto Full Off`

- **Resolution and HiDPI details**  
  Shows logical resolution, HiDPI scale, backing pixel resolution, and refresh rate when macOS reports them.

- **English and Korean localization**  
  Supports English and Korean UI text based on the system or app language.

## Install

### GitHub Release

Download the notarized DMG from the [latest release page](https://github.com/baserize/full-brightness/releases/latest), open it, and drag `Full Brightness.app` to `Applications`.

Direct download:

```sh
curl -L -o Full-Brightness-2026.05.08.001.dmg \
  https://github.com/baserize/full-brightness/releases/download/2026.05.08.001/Full-Brightness-2026.05.08.001.dmg
open Full-Brightness-2026.05.08.001.dmg
```

The DMG and app are signed with Developer ID and notarized by Apple for distribution outside the Mac App Store. A ZIP asset is also published for automation, but the DMG is the default install path.

### Homebrew

Install through the repo's cask tap:

```sh
brew tap baserize/full-brightness https://github.com/baserize/full-brightness
brew install --cask full-brightness
```

Or install directly from the cask URL:

```sh
brew install --cask https://raw.githubusercontent.com/baserize/full-brightness/main/Casks/full-brightness.rb
```

To remove the app:

```sh
brew uninstall --cask full-brightness
```

To remove app data as well:

```sh
brew uninstall --zap --cask full-brightness
```

## Use

1. Open Full Brightness.
2. Review the display list and support status.
3. Open Settings and choose your Full brightness level if 100% is not the right target for your setup.
4. Click `Connected displays Full` to set all supported displays to that level.
5. Turn on `Auto Full on connect` if newly connected supported displays should always be raised to your Full level.
6. Use Settings from the toolbar or menu bar extra to enable launch at login.

## Control Center

After installing or running the app, open Control Center customization, search for Full Brightness, and add the two controls. If the bundle identifier or control kind changes between builds, remove the old controls and add the new ones again.

## App Shortcuts

Open Shortcuts or Spotlight and search for Full Brightness. The app provides localized App Intents-backed shortcuts for setting displays to your Full level, turning auto mode on, and turning auto mode off.

## Display Support

The default build is the **Direct distribution** build. It uses Apple's private `DisplayServices` entry points through runtime symbol loading so Apple built-in displays and other Apple-native brightness paths can be controlled outside the Mac App Store.

The Direct build falls back to public IOKit `kIODisplayBrightnessKey` when `DisplayServices` is unavailable for a display.

Direct builds use `Sources/App/FullBrightnessDirect.entitlements` for the main app, without App Sandbox, while the Control Center extension keeps its sandbox and app-group entitlements.

General external monitors that only support DDC/CI may still be listed as unsupported. They need a separate DDC backend and should be treated as a future direct-distribution expansion, not as part of the current Apple-native brightness path.

Unsupported displays usually fail because the display, dock, cable, adapter, or driver does not expose a writable brightness channel to macOS.

## Build

```sh
./script/build_and_run.sh --verify
```

By default, the build script uses `Direct Debug`, which includes `DIRECT_DISTRIBUTION` and the private `DisplayServices` backend.

For a Direct Release build without installing or launching:

```sh
./script/build_and_run.sh --release --build-only
```

For the Store-safe public-API build:

```sh
./script/build_and_run.sh --store --release --build-only
```

The script regenerates `FullBrightness.xcodeproj` from `project.yml`, builds the app with Xcode, and can install the app to `/Applications/Full Brightness.app` so macOS can discover its Control Center extension.

## Release

The public GitHub release tag uses the date-based version `2026.05.08.001`.

Apple bundle version fields use App Store-compatible numeric forms:

- `CFBundleShortVersionString`: `2026.5.8`
- `CFBundleVersion`: `20260508001`

### Direct distribution package

Use Developer ID distribution for the private-API build:

```sh
./script/package_direct.sh
```

The script requires a `Developer ID Application` certificate for public direct distribution. It archives `Direct Release`, exports with `packaging/ExportOptions-DeveloperID.plist`, stages the app as `Full Brightness.app`, creates both DMG and ZIP artifacts, prints SHA-256 values, and verifies the exported signature. Set `NOTARYTOOL_PROFILE` to submit the app and DMG with `xcrun notarytool`, then staple both before the final artifacts are published.

For local artifact checks without a Developer ID certificate:

```sh
./script/package_direct.sh --local
```

Suggested distribution order:

1. GitHub Releases notarized DMG
2. Homebrew cask in `Casks/full-brightness.rb`
3. ZIP asset for automation or troubleshooting
4. Sparkle later if automatic updates become necessary

Apple's Developer ID flow expects apps distributed outside the Mac App Store to be Developer ID signed and notarized. Homebrew Cask expects a cask file with version, SHA-256, URL, metadata, and an `app` artifact.

## App Store Status

The default Direct build is **not Mac App Store or TestFlight safe** because it uses private display services. The Store-safe `Debug` and `Release` configurations remain available for public-API-only builds, but they will not control Apple Silicon built-in brightness unless macOS exposes a public writable IOKit brightness channel for that display.
