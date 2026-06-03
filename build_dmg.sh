#!/bin/bash

# Moyu DMG 打包脚本
# 使用方法: ./build_dmg.sh

set -e

APP_NAME="Moyu"
VERSION="${VERSION:-2.1.0}"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR="build"
EXPORT_PATH="${BUILD_DIR}/Export"
DMG_DIR="${BUILD_DIR}/dmg"
FINAL_DMG="${BUILD_DIR}/${DMG_NAME}.dmg"

echo "🚀 开始打包 ${APP_NAME} v${VERSION}..."

# 清理旧构建
rm -rf "${EXPORT_PATH}" "${BUILD_DIR}/dmg" "${BUILD_DIR}"/*.dmg
mkdir -p "${BUILD_DIR}" "${EXPORT_PATH}" "${DMG_DIR}"

# 1. 构建 Release 版本
echo "📦 构建 Release 版本..."
xcodebuild -project Moyu.xcodeproj \
    -scheme Moyu \
    -configuration Release \
    -destination 'platform=macOS' \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    build

# 2. 复制 app
echo "📦 复制应用..."
cp -R "${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app" "${EXPORT_PATH}/"

# 3. 代码签名
echo "🔐 签名应用..."
codesign --force --deep --sign - "${EXPORT_PATH}/${APP_NAME}.app" || true

# 4. 移除隔离属性
echo "🔓 移除隔离属性..."
xattr -cr "${EXPORT_PATH}/${APP_NAME}.app" || true

# 5. 创建 DMG
echo "💿 创建 DMG..."
cp -R "${EXPORT_PATH}/${APP_NAME}.app" "${DMG_DIR}/"
ln -s /Applications "${DMG_DIR}/Applications"

# 创建安装说明
cat > "${DMG_DIR}/安装说明.txt" << 'EOF'
Moyu 摸鱼背单词 - 安装说明

如果遇到"无法打开，因为无法验证开发者"的提示：

方法一（推荐）：
1. 右键点击 Moyu.app
2. 选择"打开"
3. 在弹出的对话框中点击"打开"

方法二：
1. 打开"系统设置" > "隐私与安全性"
2. 在"安全性"部分，找到被阻止的应用
3. 点击"仍要打开"按钮

方法三（命令行）：
终端运行: xattr -cr /Applications/Moyu.app

安装步骤：
1. 将 Moyu.app 拖拽到 Applications 文件夹
2. 启动台或应用程序文件夹中找到 Moyu 并打开
EOF

# 创建 DMG
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov -format UDZO \
    "${FINAL_DMG}"

# 移除 DMG 隔离属性
xattr -cr "${FINAL_DMG}" || true

echo "✅ 构建完成!"
echo "📍 DMG 文件: ${FINAL_DMG}"

# 清理
rm -rf "${DMG_DIR}" "${BUILD_DIR}/DerivedData"

echo "🎉 ${APP_NAME} v${VERSION} 打包成功!"
