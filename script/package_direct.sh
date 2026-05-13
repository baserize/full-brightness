#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="DisplayFit"
SCHEME="DisplayFit"
CONFIGURATION="Release"
ARCHIVE_PATH="$ROOT_DIR/.build/archives/DisplayFit.xcarchive"
EXPORT_PATH="$ROOT_DIR/.build/export/direct"
DIST_PATH="$ROOT_DIR/.build/dist/direct"
EXPORT_OPTIONS="$ROOT_DIR/packaging/ExportOptions-DeveloperID.plist"
EXPORTED_APP_PATH=""
APP_DISPLAY_NAME="DisplayFit"
APP_PATH="$DIST_PATH/$APP_DISPLAY_NAME.app"
DMG_STAGING_PATH="$DIST_PATH/dmg-root"
PACKAGE_MODE="developer-id"
DEVELOPER_ID_APPLICATION=""
NOTARY_PROFILE="${NOTARYTOOL_PROFILE:-displayfit-notary}"

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

if [[ "$PACKAGE_MODE" == "developer-id" ]]; then
  DEVELOPER_ID_APPLICATION="$(security find-identity -p codesigning -v | awk -F '"' '/Developer ID Application/ { print $2; exit }')"
  if [[ -z "$DEVELOPER_ID_APPLICATION" ]]; then
    echo "Developer ID Application signing identity is required for public direct distribution." >&2
    echo "Install the certificate, then rerun this script. Use --local only for local artifact checks." >&2
    exit 1
  fi

  if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
    echo "Apple notarization credentials are required for public direct distribution." >&2
    echo "Store credentials first:" >&2
    echo "  xcrun notarytool store-credentials $NOTARY_PROFILE --apple-id <apple-id> --team-id 27LDR382XX --password <app-specific-password>" >&2
    echo "Use --local only for private local artifact checks; never for public releases." >&2
    exit 1
  fi
fi

rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH" "$DIST_PATH"
mkdir -p "$DIST_PATH"

if [[ "$PACKAGE_MODE" == "developer-id" ]]; then
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
  EXPORTED_APP_PATH="$ROOT_DIR/.build/DerivedData/Build/Products/Release/DisplayFit.app"
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
RELEASE_VERSION="${DISPLAYFIT_RELEASE_VERSION:-$DEFAULT_RELEASE_VERSION}"
ZIP_ARTIFACT_NAME="DisplayFit-$RELEASE_VERSION.zip"
DMG_ARTIFACT_NAME="DisplayFit-$RELEASE_VERSION.dmg"
ZIP_PATH="$DIST_PATH/$ZIP_ARTIFACT_NAME"
DMG_PATH="$DIST_PATH/$DMG_ARTIFACT_NAME"

create_dmg() {
  rm -rf "$DMG_STAGING_PATH" "$DMG_PATH"
  mkdir -p "$DMG_STAGING_PATH"

  ditto "$APP_PATH" "$DMG_STAGING_PATH/$APP_DISPLAY_NAME.app"
  ln -s /Applications "$DMG_STAGING_PATH/Applications"

  hdiutil create \
    -volname "$APP_DISPLAY_NAME" \
    -srcfolder "$DMG_STAGING_PATH" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

  rm -rf "$DMG_STAGING_PATH"

  if [[ "$PACKAGE_MODE" == "developer-id" ]]; then
    codesign --force --sign "$DEVELOPER_ID_APPLICATION" --timestamp "$DMG_PATH"
  fi
}

if [[ "$PACKAGE_MODE" == "developer-id" ]]; then
  PRE_NOTARY_ZIP="$DIST_PATH/pre-notary-$ZIP_ARTIFACT_NAME"
  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$PRE_NOTARY_ZIP"
  xcrun notarytool submit "$PRE_NOTARY_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_PATH"
  rm -f "$PRE_NOTARY_ZIP"
fi

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
create_dmg

if [[ "$PACKAGE_MODE" == "developer-id" ]]; then
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
fi

shasum -a 256 "$ZIP_PATH" "$DMG_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
if [[ "$PACKAGE_MODE" == "developer-id" ]]; then
  xcrun stapler validate "$APP_PATH"
  xcrun stapler validate "$DMG_PATH"
  spctl -a -vv --type execute "$APP_PATH"
  spctl -a -vv --type install "$DMG_PATH"
fi

echo "Packaged $ZIP_PATH"
echo "Packaged $DMG_PATH"
