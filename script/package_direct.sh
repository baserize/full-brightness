#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="FullBrightness"
SCHEME="FullBrightness"
CONFIGURATION="Direct Release"
ARCHIVE_PATH="$ROOT_DIR/.build/archives/FullBrightness.xcarchive"
EXPORT_PATH="$ROOT_DIR/.build/export/direct"
DIST_PATH="$ROOT_DIR/.build/dist/direct"
EXPORT_OPTIONS="$ROOT_DIR/packaging/ExportOptions-DeveloperID.plist"
EXPORTED_APP_PATH=""
APP_PATH="$DIST_PATH/Full Brightness.app"
PACKAGE_MODE="developer-id"

for arg in "$@"; do
  case "$arg" in
    --local)
      PACKAGE_MODE="local"
      ;;
    --developer-id)
      PACKAGE_MODE="developer-id"
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

if [[ "${DEVELOPER_DIR:-}" == "" && -d "/Applications/Xcode.app/Contents/Developer" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required to generate $PROJECT_NAME.xcodeproj" >&2
  exit 1
fi

xcodegen generate --spec project.yml --quiet
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH" "$DIST_PATH"
mkdir -p "$DIST_PATH"

if [[ "$PACKAGE_MODE" == "developer-id" ]]; then
  if ! security find-identity -p codesigning -v | grep -q "Developer ID Application"; then
    echo "Developer ID Application signing identity is required for public direct distribution." >&2
    echo "Install the certificate, then rerun this script. Use --local only for local ZIP checks." >&2
    exit 1
  fi

  xcodebuild \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    archive

  xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_PATH" \
    -allowProvisioningUpdates

  EXPORTED_APP_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -name "*.app" -type d -print -quit)"
else
  ./script/build_and_run.sh --release --build-only --no-install
  EXPORTED_APP_PATH="$ROOT_DIR/.build/DerivedData/Build/Products/Direct Release/FullBrightness.app"
fi

if [[ -z "$EXPORTED_APP_PATH" || ! -d "$EXPORTED_APP_PATH" ]]; then
  echo "Built app not found" >&2
  exit 1
fi

ditto "$EXPORTED_APP_PATH" "$APP_PATH"

VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Contents/Info.plist")"
DEFAULT_RELEASE_VERSION="$VERSION.$BUILD"
if [[ "$BUILD" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{3})$ ]]; then
  DEFAULT_RELEASE_VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}.${BASH_REMATCH[4]}"
fi
ARTIFACT_NAME="Full-Brightness-${FULL_BRIGHTNESS_RELEASE_VERSION:-$DEFAULT_RELEASE_VERSION}.zip"
ZIP_PATH="$DIST_PATH/$ARTIFACT_NAME"

if [[ "$PACKAGE_MODE" == "developer-id" && -n "${NOTARYTOOL_PROFILE:-}" ]]; then
  PRE_NOTARY_ZIP="$DIST_PATH/pre-notary-$ARTIFACT_NAME"
  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$PRE_NOTARY_ZIP"
  xcrun notarytool submit "$PRE_NOTARY_ZIP" --keychain-profile "$NOTARYTOOL_PROFILE" --wait
  xcrun stapler staple "$APP_PATH"
  rm -f "$PRE_NOTARY_ZIP"
elif [[ -n "${NOTARYTOOL_PROFILE:-}" ]]; then
  echo "Ignoring NOTARYTOOL_PROFILE because --local packages are not Developer ID exports." >&2
fi

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl -a -vv --type execute "$APP_PATH"

echo "Packaged $ZIP_PATH"
