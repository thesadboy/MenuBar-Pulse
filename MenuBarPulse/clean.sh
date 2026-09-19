#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}/.."

echo "==> 正在清理构建过程与多余临时文件..."

# 1. 清理 DMG 暂存目录与临时挂载
rm -rf "${DIR}/dmg_staging"
rm -rf "${ROOT_DIR}/dmg_staging"

# 2. 清理临时测试文件与编译产物
rm -f "${DIR}/test_*" "${DIR}/scratch_*" "${DIR}/main.swift"
rm -f "${DIR}/*.o" "${DIR}/*.dSYM"

# 3. 清理系统隐藏元数据 .DS_Store
find "${ROOT_DIR}" -name ".DS_Store" -depth -exec rm -f {} \; 2>/dev/null || true

# 4. 如果传入 --all 参数，则同时清理本地编译生成的 .app 副本（仅保留源码与发布用 .dmg）
if [ "$1" == "--all" ]; then
    echo "==> 正在清理本地生成的 .app 副本..."
    # 如果当前正在运行，先友好提示
    if pgrep -f "${DIR}/MenuBarPulse.app" >/dev/null 2>&1; then
        echo "    注意：检测到 MenuBarPulse 正在运行，跳过删除正在运行的 .app"
    else
        rm -rf "${DIR}/MenuBarPulse.app"
    fi
    rm -rf "${ROOT_DIR}/MenuBarPulse.app"
else
    # 默认清理外层冗余的 .app 副本，仅保留最终发布件 .dmg 与源码目录开发调试用 .app
    rm -rf "${ROOT_DIR}/MenuBarPulse.app"
fi

echo "==> 清理完成！"
echo "    当前目录状态："
ls -la "${ROOT_DIR}"
