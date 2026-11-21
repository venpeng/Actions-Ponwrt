#!/bin/sh
# ==============================================================
# patch-fitblk-prompt.sh —— 解除 fitblk 的 HIDDEN，让 .config 的 =y 生效
#
# 背景：
#   package/utils/fitblk/Makefile 里 `HIDDEN:=1` 会让 metadata 生成的 Kconfig
#   变成没有 prompt 的 `tristate`，而 Kconfig 只接受有 prompt 的符号从
#   .config 赋值 —— 所以 configs/*.config 里的 `CONFIG_PACKAGE_fitblk=y`
#   在 make defconfig 时被直接丢弃（符号整个消失，连 "is not set" 都不留）。
#
#   而各 airoha 机型的 DEVICE_PACKAGES 都引用 fitblk（FIT 升级必需），
#   image.mk 组装时 apk add 不会跳过缺失包 → target/linux install 阶段硬失败。
#
#   去掉 HIDDEN 后 fitblk 恢复成普通可选包，机型配置的 =y 才会被接受，
#   它依赖的 fit-check-sign 也会由 Kconfig 的 select 自动带出。
#
# 用法: sh scripts/patch-fitblk-prompt.sh [openwrt_dir]
# 幂等：已无 HIDDEN:=1 时直接跳过。
# ==============================================================
set -u

OW="${1:-$PWD}"
MK="$OW/package/utils/fitblk/Makefile"

if [ ! -f "$MK" ]; then
  echo "::warning::未找到 $MK，跳过 fitblk 补丁（上游改了路径？）"
  exit 0
fi

if ! grep -qE "^[[:space:]]*HIDDEN[[:space:]]*:=[[:space:]]*1[[:space:]]*$" "$MK"; then
  echo "fitblk 已无可选的 HIDDEN:=1（上游已修或已打过补丁），跳过"
  exit 0
fi

sed -i -E '/^[[:space:]]*HIDDEN[[:space:]]*:=[[:space:]]*1[[:space:]]*$/d' "$MK"

if grep -qE "^[[:space:]]*HIDDEN[[:space:]]*:=[[:space:]]*1[[:space:]]*$" "$MK"; then
  echo "::error::fitblk 的 HIDDEN:=1 未能移除，CONFIG_PACKAGE_fitblk=y 会被 defconfig 丢弃"
  exit 1
fi

echo "✅ 已移除 fitblk 的 HIDDEN:=1（恢复为可选包，机型配置的 =y 才能生效）"
