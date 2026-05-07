# Full Brightness

Full Brightness is a macOS utility that lists displays whose brightness can be controlled, sets all supported displays to 100%, and can automatically max brightness when a new display connects.

## Key Features

- **Brightness-capable display detection**  
  Lists every connected display and clearly marks whether the app can read and write its brightness.

- **One-click 100% brightness**  
  Sets every adjustable connected display to full brightness with a single action from the main window, menu bar, Control Center, Shortcuts, Siri, or Spotlight.

- **Automatic 100% brightness on connection**  
  Watches macOS display reconfiguration events and automatically applies 100% brightness when a new adjustable display is connected while auto mode is enabled.

- **Live brightness refresh**  
  Keeps the display list in sync when brightness changes outside the app, including changes made from macOS controls or hardware keys.

- **Control Center controls**  
  Provides two WidgetKit controls for macOS Control Center:
  - `Display 100%`: instantly sets supported displays to 100%.
  - `On connect 100%`: toggles automatic full brightness for newly connected displays.

- **Menu bar utility**  
  Includes a compact menu bar extra with refresh, one-click 100%, auto mode, display status, and quick access to the main app.

- **Native Settings and Launch at Login**  
  Provides a standard macOS Settings window for app-level options, including launch at login for automatic display handling after sign-in.

- **App Shortcuts integration**  
  Exposes App Intents-backed shortcuts for Shortcuts, Siri, and Spotlight:
  - `Displays 100%`: immediately sets adjustable displays to 100%.
  - `Auto 100% On`: enables automatic 100% brightness on new display connection.
  - `Auto 100% Off`: disables automatic 100% brightness on new display connection.

- **Resolution and HiDPI details**  
  Shows logical resolution, HiDPI scale, backing pixel resolution, and refresh rate when macOS reports them.

- **English and Korean localization**  
  Supports English and Korean UI text based on the system or app language.

- **Native macOS app structure**  
  Uses SwiftUI, Observation, App Intents, WidgetKit controls, App Shortcuts, and a single-window macOS utility layout.

## Build

```sh
./script/build_and_run.sh --verify
```

The script regenerates `FullBrightness.xcodeproj` from `project.yml`, builds the app with Xcode, installs it to `/Applications/Full Brightness.app` so macOS can discover its Control Center extension, launches it, and verifies the process.

## Control Center

After installing or running the app, open Control Center customization, search for Full Brightness, and add the two controls. WidgetKit controls for Mac require macOS 26 or newer.

## App Shortcuts

Open Shortcuts or Spotlight and search for Full Brightness. The app provides App Intents-backed shortcuts for setting displays to 100%, turning auto mode on, and turning auto mode off. The shortcut titles and intent metadata are localized in English and Korean.

## Display Support

The app tries these hardware brightness paths in order:

- Apple DisplayServices native brightness, which covers built-in displays and Apple-supported displays such as LG UltraFine.
- macOS IOKit display brightness parameters, which cover some older Apple-supported display paths.
- Apple Silicon DCP/IOAVService DDC/CI, which covers many external monitors on modern Apple Silicon Macs.
- IOFramebuffer I2C DDC/CI, which covers older Intel-style display paths.

Some monitors, docks, cables, and DisplayLink-style adapters block DDC/CI. Those displays are listed as unsupported instead of being changed blindly.

This app includes app icon assets, localized UI strings, version metadata, and sandbox entitlements needed for distribution packaging.

App Store review still has a functional blocker: the app uses private macOS display APIs for brightness control. Apple's current Mac App Store requirements require sandboxing and public APIs, so an App Store-safe version would need a different, public API-compatible brightness strategy or reduced functionality.
