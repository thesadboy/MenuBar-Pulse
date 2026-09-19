#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "==> 正在编译 MenuBarPulse..."

APP_NAME="MenuBarPulse"
APP_BUNDLE="${DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${DIR}/Info.plist" "${CONTENTS_DIR}/Info.plist"
if [ -f "${DIR}/AppIcon.icns" ]; then
    cp "${DIR}/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi
if [ -d "${DIR}/Resources" ]; then
    cp -R "${DIR}/Resources/"* "${RESOURCES_DIR}/" 2>/dev/null || true
fi

# 动态递归收集源码文件，排除 main.swift，排序后将 main.swift 追加到最后以符合 swiftc 的顶级语句编译规则
SOURCES=($(find "${DIR}/Sources" -type f -name "*.swift" ! -name "main.swift" | sort))
SOURCES+=("${DIR}/Sources/Core/main.swift")

swiftc \
    -O \
    -parse-as-library \
    -target arm64-apple-macosx14.0 \
    -framework Cocoa \
    -framework SwiftUI \
    -framework IOKit \
    -framework ServiceManagement \
    -o "${MACOS_DIR}/${APP_NAME}" \
    "${SOURCES[@]}"

echo "==> 正在进行应用签名..."
codesign --force --deep --sign - "${APP_BUNDLE}"

# 只有在非 CI 环境且没有指定 --no-install 时才同步到 /Applications
if [ "$1" != "--no-install" ] && [ "$CI" != "true" ]; then
    echo "==> 正在同步安装至系统应用程序目录 (/Applications/${APP_NAME}.app)..."
    WAS_RUNNING=0
    if pgrep -f "MenuBarPulse.app" >/dev/null 2>&1; then
        WAS_RUNNING=1
        killall "${APP_NAME}" 2>/dev/null || true
    fi
    
    if [ -w "/Applications" ]; then
        rm -rf "/Applications/${APP_NAME}.app" 2>/dev/null || true
        cp -R "${APP_BUNDLE}" "/Applications/${APP_NAME}.app"
        rm -rf "${APP_BUNDLE}"
        rm -rf "${DIR}/../${APP_NAME}.app"
        
        if [ $WAS_RUNNING -eq 1 ]; then
            echo "==> 重新启动应用..."
            open "/Applications/${APP_NAME}.app"
        fi
        
        echo "==> 构建并安装成功！"
        echo "    系统应用位置：/Applications/${APP_NAME}.app"
    else
        echo "==> /Applications 目录无直接写入权限，保留本地构建产物：${APP_BUNDLE}"
    fi
else
    echo "==> 构建并签名成功！产物位置：${APP_BUNDLE}"
fi
