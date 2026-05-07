#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="FullBrightness"
APP_NAME="FullBrightness"
DISPLAY_NAME="Full Brightness"
APP_BUNDLE_IDENTIFIER="com.baserize.fullbrightness"
LEGACY_APP_BUNDLE_IDENTIFIERS=("com.hellosunghyun.fullbrightness")
CONTROL_EXTENSION_BUNDLE_IDENTIFIER="com.baserize.fullbrightness.controls"
LEGACY_CONTROL_EXTENSION_BUNDLE_IDENTIFIERS=("com.hellosunghyun.fullbrightness.controls")
DERIVED_DATA_PATH="$ROOT_DIR/.build/DerivedData"
BUILD_STYLE="debug"
CONFIGURATION="Debug"
INSTALL_PATH="${FULL_BRIGHTNESS_INSTALL_PATH:-/Applications/$DISPLAY_NAME.app}"
MODE="run"
INSTALL_APP=1

if [[ "${DEVELOPER_DIR:-}" == "" && -d "/Applications/Xcode.app/Contents/Developer" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

for arg in "$@"; do
  case "$arg" in
    --verify)
      MODE="verify"
      ;;
    --build-only)
      MODE="build"
      ;;
    --release)
      BUILD_STYLE="release"
      ;;
    --logs)
      MODE="logs"
      ;;
    --no-install)
      INSTALL_APP=0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

if [[ "$BUILD_STYLE" == "release" ]]; then
  CONFIGURATION="Release"
else
  CONFIGURATION="Debug"
fi

bundle_identifier() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$1/Contents/Info.plist" 2>/dev/null || true
}

is_known_install_identifier() {
  local identifier="$1"

  if [[ "$identifier" == "$APP_BUNDLE_IDENTIFIER" ]]; then
    return 0
  fi

  for legacy_identifier in "${LEGACY_APP_BUNDLE_IDENTIFIERS[@]}"; do
    if [[ "$identifier" == "$legacy_identifier" ]]; then
      return 0
    fi
  done

  return 1
}

is_known_control_extension_identifier() {
  local identifier="$1"

  if [[ "$identifier" == "$CONTROL_EXTENSION_BUNDLE_IDENTIFIER" ]]; then
    return 0
  fi

  for legacy_identifier in "${LEGACY_CONTROL_EXTENSION_BUNDLE_IDENTIFIERS[@]}"; do
    if [[ "$identifier" == "$legacy_identifier" ]]; then
      return 0
    fi
  done

  return 1
}

stop_running_processes() {
  local matched_processes

  matched_processes="$(
    ps -axo pid=,ppid=,args= | awk '
      index($0, "FullBrightness.app/Contents/MacOS/FullBrightness") ||
      index($0, "FullBrightnessControls.appex/Contents/MacOS/FullBrightnessControls") {
        print $1 " " $2
      }
    '
  )"

  while read -r pid ppid; do
    if [[ -n "${pid:-}" && "$pid" != "$$" ]]; then
      kill "$pid" >/dev/null 2>&1 || true
    fi

    if [[ -n "${ppid:-}" && "$ppid" != "1" && "$ppid" != "$$" ]]; then
      kill "$ppid" >/dev/null 2>&1 || true
    fi
  done <<< "$matched_processes"

  sleep 0.2
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  pkill -x "FullBrightnessControls" >/dev/null 2>&1 || true
  sleep 0.2
  pkill -9 -x "$APP_NAME" >/dev/null 2>&1 || true
  pkill -9 -x "FullBrightnessControls" >/dev/null 2>&1 || true
}

unregister_discovered_control_extensions() {
  while IFS= read -r extension_path; do
    if [[ -d "$extension_path" ]]; then
      pluginkit -r "$extension_path" >/dev/null 2>&1 || true
    fi
  done < <(
    mdfind "kMDItemCFBundleIdentifier == '$CONTROL_EXTENSION_BUNDLE_IDENTIFIER'" 2>/dev/null || true
  )

  for legacy_identifier in "${LEGACY_CONTROL_EXTENSION_BUNDLE_IDENTIFIERS[@]}"; do
    while IFS= read -r extension_path; do
      if [[ -d "$extension_path" ]]; then
        pluginkit -r "$extension_path" >/dev/null 2>&1 || true
      fi
    done < <(
      mdfind "kMDItemCFBundleIdentifier == '$legacy_identifier'" 2>/dev/null || true
    )
  done
}

register_installed_app() {
  local installed_app_path="$1"
  local extension_path="$installed_app_path/Contents/PlugIns/FullBrightnessControls.appex"

  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$installed_app_path"

  if [[ -d "$extension_path" ]]; then
    pluginkit -a "$extension_path"
  fi

  if command -v mdimport >/dev/null 2>&1; then
    mdimport "$installed_app_path" >/dev/null 2>&1 || true
  fi
}

install_app_bundle() {
  local built_app_path="$1"

  if [[ -e "$INSTALL_PATH" && ! -d "$INSTALL_PATH" ]]; then
    echo "Install path exists but is not an app bundle: $INSTALL_PATH" >&2
    exit 1
  fi

  if [[ -d "$INSTALL_PATH" ]]; then
    local existing_identifier
    existing_identifier="$(bundle_identifier "$INSTALL_PATH")"

    if ! is_known_install_identifier "$existing_identifier"; then
      echo "Refusing to replace $INSTALL_PATH because its bundle identifier is '$existing_identifier'." >&2
      exit 1
    fi

    local existing_extension_path="$INSTALL_PATH/Contents/PlugIns/FullBrightnessControls.appex"
    if [[ -d "$existing_extension_path" ]]; then
      pluginkit -r "$existing_extension_path" >/dev/null 2>&1 || true
    fi
  fi

  local built_extension_path="$built_app_path/Contents/PlugIns/FullBrightnessControls.appex"
  if [[ -d "$built_extension_path" ]]; then
    local built_extension_identifier
    built_extension_identifier="$(bundle_identifier "$built_extension_path")"

    if is_known_control_extension_identifier "$built_extension_identifier"; then
      pluginkit -r "$built_extension_path" >/dev/null 2>&1 || true
    fi
  fi

  unregister_discovered_control_extensions
  rm -rf "$INSTALL_PATH"
  ditto "$built_app_path" "$INSTALL_PATH"
  register_installed_app "$INSTALL_PATH"
}

cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required to generate $PROJECT_NAME.xcodeproj" >&2
  exit 1
fi

xcodegen generate --spec project.yml --quiet

stop_running_processes

xcodebuild \
  -project "$PROJECT_NAME.xcodeproj" \
  -scheme "$PROJECT_NAME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"

if [[ "$MODE" == "build" ]]; then
  echo "Built $APP_PATH"
  exit 0
fi

RUN_APP_PATH="$APP_PATH"

if [[ "$INSTALL_APP" == "1" ]]; then
  install_app_bundle "$APP_PATH"
  RUN_APP_PATH="$INSTALL_PATH"
  echo "Installed $RUN_APP_PATH"
fi

/usr/bin/open -n "$RUN_APP_PATH"

if [[ "$MODE" == "logs" ]]; then
  /usr/bin/log stream --style compact --predicate 'process == "FullBrightness"'
  exit 0
fi

if [[ "$MODE" == "verify" ]]; then
  for _ in {1..30}; do
    if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
      echo "$APP_NAME is running"
      exit 0
    fi
    sleep 0.2
  done

  echo "$APP_NAME did not start" >&2
  exit 1
fi
