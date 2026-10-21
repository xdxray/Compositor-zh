#!/bin/bash
# 一键构建 Compositor Release 版（免签名，适合本地自用）
# 产物会复制到桌面并自动去除 Gatekeeper 隔离属性

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="Compositor"
DEST="platform=macOS"
APP_NAME="Compositor.app"
DESKTOP_DIR="$HOME/Desktop"

echo "🛠  开始 Release 构建..."
cd "$PROJECT_DIR"

xcodebuild \
  -project Compositor.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "$DEST" \
  build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | tee /tmp/compositor-release.log | grep -E 'BUILD|SUCCEEDED|FAILED|error:|warning: Compositor' || true

# 提取产物路径
APP_PATH=$(grep -oE '/Users/[^[:space:]]+/Build/Products/Release/Compositor\.app' /tmp/compositor-release.log | tail -1)

if [ ! -d "$APP_PATH" ]; then
  echo "❌ 未找到构建产物，请检查 /tmp/compositor-release.log"
  exit 1
fi

echo "📦 产物：$APP_PATH"

# 复制到桌面并去隔离属性
rm -rf "$DESKTOP_DIR/$APP_NAME"
cp -R "$APP_PATH" "$DESKTOP_DIR/$APP_NAME"
xattr -dr com.apple.quarantine "$DESKTOP_DIR/$APP_NAME"

VERSION=$(defaults read "$DESKTOP_DIR/$APP_NAME/Contents/Info.plist" CFBundleShortVersionString)
echo "✅ 已生成桌面版 $APP_NAME（版本 $VERSION）"
echo "🚀 可直接在桌面双击打开使用"
