#!/bin/bash

# Moyu DMG 打包脚本
# 使用方法: ./build_dmg.sh

set -e

APP_NAME="Moyu"
# 支持从环境变量读取版本号，用于 CI/CD
VERSION="${VERSION:-1.0.0}"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
DESTINATION="platform=macOS"
EXPORT_PATH="${BUILD_DIR}/Export"
DMG_DIR="${BUILD_DIR}/dmg"
FINAL_DMG="${BUILD_DIR}/${DMG_NAME}.dmg"

echo "🚀 开始打包 ${APP_NAME} v${VERSION}..."

# 检查是否需要重新构建
if [ "${FORCE_REBUILD}" = "1" ]; then
    echo "🔁 检测到 FORCE_REBUILD=1，强制重新构建应用..."
    rm -rf "${EXPORT_PATH:?}/${APP_NAME}.app" "${ARCHIVE_PATH}" "${BUILD_DIR}/DerivedData"
    echo "📦 使用 Release 配置重新构建..."
    xcodebuild -project Moyu.xcodeproj \
        -scheme Moyu \
        -configuration Release \
        -destination "${DESTINATION}" \
        -derivedDataPath "${BUILD_DIR}/DerivedData" \
        build
fi

# 如果没有现成的构建，才进行完整构建流程
if [ -d "${EXPORT_PATH}/${APP_NAME}.app" ]; then
    echo "✅ 发现已有构建好的应用，直接使用..."
else
    echo "📦 需要重新构建应用..."
    mkdir -p "${BUILD_DIR}"
    
    # 1. 构建 Release 版本
    echo "📦 构建 Release 版本..."
    xcodebuild -project Moyu.xcodeproj \
        -scheme Moyu \
        -configuration Release \
        -destination "${DESTINATION}" \
        -archivePath "${ARCHIVE_PATH}" \
        archive || {
        echo "⚠️ Archive 构建失败，尝试直接构建..."
        xcodebuild -project Moyu.xcodeproj \
            -scheme Moyu \
            -configuration Release \
            -destination "${DESTINATION}" \
            -derivedDataPath "${BUILD_DIR}/DerivedData" \
            build
        # 尝试从构建目录复制
        if [ -d "${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app" ]; then
            mkdir -p "${EXPORT_PATH}"
            cp -R "${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app" "${EXPORT_PATH}/"
        fi
    }
    
    # 2. 导出 app
    echo "📤 导出应用..."
    cat > "${BUILD_DIR}/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF
    
    # 如果没有开发者证书，直接从 archive 复制 app
    if [ -d "${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app" ]; then
        mkdir -p "${EXPORT_PATH}"
        cp -R "${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app" "${EXPORT_PATH}/"
    else
        # 尝试使用 xcodebuild export
        xcodebuild -exportArchive \
            -archivePath "${ARCHIVE_PATH}" \
            -exportPath "${EXPORT_PATH}" \
            -exportOptionsPlist "${BUILD_DIR}/ExportOptions.plist" || {
            echo "⚠️ 导出失败，尝试从构建目录复制..."
            mkdir -p "${EXPORT_PATH}"
            cp -R "${BUILD_DIR}/Release/${APP_NAME}.app" "${EXPORT_PATH}/" 2>/dev/null || true
        }
    fi
fi

# 确保应用存在
if [ ! -d "${EXPORT_PATH}/${APP_NAME}.app" ]; then
    # 尝试从 DerivedData 查找
    if [ -d "${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app" ]; then
        mkdir -p "${EXPORT_PATH}"
        cp -R "${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app" "${EXPORT_PATH}/"
    else
        echo "❌ 错误: 找不到 ${APP_NAME}.app，无法打包"
        exit 1
    fi
fi

# 2.5. 代码签名（使用 ad-hoc 签名）
echo "🔐 签名应用..."
codesign --force --deep --sign - "${EXPORT_PATH}/${APP_NAME}.app" || {
    echo "⚠️ 签名失败，继续打包..."
}

# 移除隔离属性（quarantine）
echo "🔓 移除隔离属性..."
xattr -cr "${EXPORT_PATH}/${APP_NAME}.app" 2>/dev/null || true

# 3. 创建 DMG
echo "💿 创建 DMG..."
mkdir -p "${DMG_DIR}"

# 复制 app 到 DMG 目录
cp -R "${EXPORT_PATH}/${APP_NAME}.app" "${DMG_DIR}/"

# 创建 Applications 符号链接
ln -s /Applications "${DMG_DIR}/Applications"

# 创建安装说明文件
cat > "${DMG_DIR}/安装说明.txt" << 'EOF'
═══════════════════════════════════════════════════════
  Moyu 摸鱼背单词 - 安装说明
═══════════════════════════════════════════════════════

如果遇到"无法打开，因为无法验证开发者"的提示，请按以下步骤操作：

方法一（推荐）：
1. 右键点击 Moyu.app
2. 选择"打开"
3. 在弹出的对话框中点击"打开"

方法二：
1. 打开"系统设置" > "隐私与安全性"
2. 在"安全性"部分，找到被阻止的应用
3. 点击"仍要打开"按钮

方法三（命令行）：
在终端中运行以下命令：
  xattr -cr /Applications/Moyu.app

═══════════════════════════════════════════════════════
安装步骤：
1. 将 Moyu.app 拖拽到 Applications 文件夹
2. 在启动台或应用程序文件夹中找到并打开 Moyu
3. 首次运行可能需要按照上述方法允许运行

═══════════════════════════════════════════════════════
EOF

# 创建 DMG
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov -format UDZO \
    "${FINAL_DMG}"

# 移除 DMG 的隔离属性
echo "🔓 移除 DMG 隔离属性..."
xattr -cr "${FINAL_DMG}" 2>/dev/null || true

echo "✅ 构建完成!"
echo "📍 DMG 文件位置: ${FINAL_DMG}"

# 清理临时文件
rm -rf "${DMG_DIR}"
rm -f "${BUILD_DIR}/ExportOptions.plist"

echo "🎉 ${APP_NAME} v${VERSION} 打包成功!"
