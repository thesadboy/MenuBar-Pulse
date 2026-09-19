#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "==> 1. 重新编译最新版本 MenuBarPulse..."
bash "${DIR}/build.sh"

DMG_NAME="MenuBarPulse"
OUTPUT_DIR="${DIR}/.."
OUTPUT_DMG="${OUTPUT_DIR}/${DMG_NAME}.dmg"
STAGING_DIR="${DIR}/dmg_staging"

echo "==> 2. 准备 DMG 打包临时目录..."
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"

echo "==> 3. 复制应用与创建 /Applications 快捷方式..."
cp -R "/Applications/MenuBarPulse.app" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> 4. 生成 DMG 安装镜像..."
rm -f "${OUTPUT_DMG}" "${DIR}/${DMG_NAME}.dmg"

hdiutil create \
    -volname "${DMG_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${OUTPUT_DMG}"

echo "==> 5. 自动执行清理（移除临时挂载、多余副本与隐藏元数据）..."
bash "${DIR}/clean.sh" --all

echo "==> 6. DMG 打包完成！"
echo "    文件位置：${OUTPUT_DMG}"
ls -lh "${OUTPUT_DMG}"
