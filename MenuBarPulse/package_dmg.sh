#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "==> 1. 重新编译最新版本 MenuBarPulse..."
bash "${DIR}/build.sh" --no-install

DMG_NAME="MenuBarPulse"
OUTPUT_DIR="${DIR}/.."
OUTPUT_DMG="${OUTPUT_DIR}/${DMG_NAME}.dmg"
STAGING_DIR="${DIR}/dmg_staging"

echo "==> 2. 准备 DMG 打包临时目录..."
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"

echo "==> 3. 复制应用与创建 /Applications 快捷方式..."
if [ -d "${DIR}/MenuBarPulse.app" ]; then
    cp -R "${DIR}/MenuBarPulse.app" "${STAGING_DIR}/"
elif [ -d "/Applications/MenuBarPulse.app" ]; then
    cp -R "/Applications/MenuBarPulse.app" "${STAGING_DIR}/"
fi
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> 4. 清除暂存目录中残留的系统隔离与扩展属性..."
xattr -rc "${STAGING_DIR}" 2>/dev/null || true

echo "==> 5. 生成 DMG 安装镜像..."
rm -f "${OUTPUT_DMG}" "${DIR}/${DMG_NAME}.dmg"

hdiutil create \
    -volname "${DMG_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${OUTPUT_DMG}"

SIGN_ID="${CODESIGN_IDENTITY:--}"
echo "==> 6. 对 DMG 安装镜像执行代码签名 (签名标识: ${SIGN_ID})..."
codesign --force --sign "${SIGN_ID}" "${OUTPUT_DMG}" || {
    echo "    警告: DMG 签名失败，保留未签名产物"
}

echo "==> 7. 自动执行清理（移除临时挂载、多余副本与隐藏元数据）..."
bash "${DIR}/clean.sh" --all

echo "==> 8. DMG 打包完成！"
echo "    文件位置：${OUTPUT_DMG}"
ls -lh "${OUTPUT_DMG}"

