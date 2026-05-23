#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$SCRIPT_DIR/LSDKeyboard/LSDKeyboard.xcodeproj"
INSTALL_DIR="$HOME/Library/Input Methods"
APP_NAME="LSDKeyboard.app"

echo "=== Cleaning previous build artifacts ==="
rm -rf /tmp/LSDKeyboard-build

echo "=== Building LSDKeyboard ==="
xcodebuild \
    -project "$PROJECT" \
    -scheme LSDKeyboard \
    -configuration Release \
    -derivedDataPath /tmp/LSDKeyboard-build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="" \
    build

BUILT_APP="/tmp/LSDKeyboard-build/Build/Products/Release/$APP_NAME"

if [ ! -d "$BUILT_APP" ]; then
    echo "ERROR: build succeeded but $BUILT_APP not found"
    exit 1
fi

echo ""
echo "=== Installing to ~/Library/Input Methods/ ==="
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME"
cp -r "$BUILT_APP" "$INSTALL_DIR/$APP_NAME"

echo "=== Verifying installed plist ==="
PLIST="$INSTALL_DIR/$APP_NAME/Contents/Info.plist"
BID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$PLIST" 2>&1)
CNX=$(/usr/libexec/PlistBuddy -c "Print :InputMethodConnectionName" "$PLIST" 2>&1)
echo "  CFBundleIdentifier:        $BID"
echo "  InputMethodConnectionName: $CNX"
if [ "$BID" != "$CNX" ]; then
    echo "WARNING: connection name does not match bundle ID — imklaunchagent will refuse"
fi

echo "=== Clearing quarantine ==="
xattr -dr com.apple.quarantine "$INSTALL_DIR/$APP_NAME" 2>/dev/null || true

echo "=== Killing old processes ==="
killall LSDKeyboard 2>/dev/null || true
# Kill imklaunchagent so launchd restarts it and rescans the updated plist.
# Without this it keeps the old InputMethodConnectionName in its cache.
killall imklaunchagent 2>/dev/null || true
sleep 1

echo "=== Refreshing TextInputMenuAgent ==="
killall -9 TextInputMenuAgent 2>/dev/null || true
sleep 1
open -a /System/Library/CoreServices/TextInputMenuAgent.app 2>/dev/null || \
    /System/Library/CoreServices/TextInputMenuAgent.app/Contents/MacOS/TextInputMenuAgent &

echo ""
echo "Done. Switch away from 'Lisan ud Dawat' in the input menu and back"
echo "to force a fresh process launch, then try typing."
echo ""
echo "If the keyboard is not listed, log out and back in, then check again."
