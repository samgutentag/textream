#!/bin/bash
# Build this checkout and install it as /Applications/Textream.app.
# Fork workflow: replaces the Homebrew-installed release with the local
# build, versioned <upstream>.1 so the in-app update checker stays quiet
# until upstream actually ships something newer.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP=/Applications/Textream.app
DERIVED="$PROJECT_DIR/build/xcode"

if ! xcodebuild -version >/dev/null 2>&1; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

BASE_VERSION=$(sed -n 's/.*MARKETING_VERSION = \([0-9][0-9.]*\);.*/\1/p' \
  "$PROJECT_DIR/Textream.xcodeproj/project.pbxproj" | head -1)
LOCAL_VERSION="${BASE_VERSION}.1"

echo "Building Textream ${LOCAL_VERSION} from $(git -C "$PROJECT_DIR" branch --show-current)…"
rm -rf "$DERIVED/Build/Products/Release/Textream.app"
xcodebuild -project "$PROJECT_DIR/Textream.xcodeproj" -scheme Textream \
  -configuration Release -derivedDataPath "$DERIVED" \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= \
  MARKETING_VERSION="$LOCAL_VERSION" build -quiet

BUILT="$DERIVED/Build/Products/Release/Textream.app"
codesign --force -s - "$BUILT"

osascript -e 'quit app "Textream"' 2>/dev/null || true
pkill -x Textream 2>/dev/null || true
sleep 1
rm -rf "$APP"
ditto "$BUILT" "$APP"
echo "Installed $APP (${LOCAL_VERSION})"
open "$APP"
