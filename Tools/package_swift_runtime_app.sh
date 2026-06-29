#!/bin/bash
set -euo pipefail

if [ "$#" -lt 6 ]; then
  echo "usage: $0 <binary_path> <app_name> <bundle_id> <min_macos> <icon_path> <output_dir> [zip_name] [assets_car_path]" >&2
  exit 1
fi

BINARY_PATH="$1"
APP_NAME="$2"
BUNDLE_ID="$3"
MIN_MACOS="$4"
ICON_PATH="$5"
OUTPUT_DIR="$6"
ZIP_NAME="${7:-$APP_NAME.zip}"
ASSETS_CAR_PATH="${8:-}"

APP_PATH="$OUTPUT_DIR/$APP_NAME.app"
ZIP_PATH="$OUTPUT_DIR/$ZIP_NAME"
SOURCE_INFO_PLIST="$(cd "$(dirname "$BINARY_PATH")/.." && pwd)/Info.plist"

SHORT_VERSION="0.1"
BUILD_VERSION="1"
if [ -f "$SOURCE_INFO_PLIST" ]; then
  if VERSION_VALUE=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$SOURCE_INFO_PLIST" 2>/dev/null); then
    SHORT_VERSION="$VERSION_VALUE"
  fi
  if BUILD_VALUE=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$SOURCE_INFO_PLIST" 2>/dev/null); then
    BUILD_VERSION="$BUILD_VALUE"
  fi
fi

rm -rf "$APP_PATH" "$ZIP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Frameworks" "$APP_PATH/Contents/Resources"

cp "$BINARY_PATH" "$APP_PATH/Contents/MacOS/$APP_NAME"

install_name_tool -delete_rpath /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-5.5/macosx "$APP_PATH/Contents/MacOS/$APP_NAME" 2>/dev/null || true
install_name_tool -delete_rpath /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-6.2/macosx "$APP_PATH/Contents/MacOS/$APP_NAME" 2>/dev/null || true
install_name_tool -delete_rpath /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-6.3/macosx "$APP_PATH/Contents/MacOS/$APP_NAME" 2>/dev/null || true
install_name_tool -add_rpath @executable_path/../Frameworks "$APP_PATH/Contents/MacOS/$APP_NAME" 2>/dev/null || true

xcrun swift-stdlib-tool \
  --copy \
  --platform macosx \
  --scan-executable "$APP_PATH/Contents/MacOS/$APP_NAME" \
  --destination "$APP_PATH/Contents/Frameworks"

if compgen -G "$APP_PATH/Contents/Frameworks/libswift*.dylib" > /dev/null; then
  cp "$APP_PATH"/Contents/Frameworks/libswift*.dylib "$APP_PATH/Contents/MacOS/"
fi

cat > "$APP_PATH/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$SHORT_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_MACOS</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

printf 'APPL????' > "$APP_PATH/Contents/PkgInfo"
cp "$ICON_PATH" "$APP_PATH/Contents/Resources/AppIcon.icns"

if [ -n "$ASSETS_CAR_PATH" ] && [ -f "$ASSETS_CAR_PATH" ]; then
  cp "$ASSETS_CAR_PATH" "$APP_PATH/Contents/Resources/Assets.car"
fi

(
  cd "$OUTPUT_DIR"
  /usr/bin/zip -qry "$ZIP_NAME" "$APP_NAME.app"
)

echo "App: $APP_PATH"
echo "Zip: $ZIP_PATH"
