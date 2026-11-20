#!/bin/bash
# ================================================================
# diy-part3.sh —— 可选额外插件（由 workflow 的 extra_plugins 开关控制，默认关）
# 运行目录: ponwrt 源码根目录（.config 已加载、defconfig 之前）
# 作用: 等价于手工流程在 make menuconfig 里勾选下列插件，把对应的
#       CONFIG_PACKAGE_*=y 写进 .config，交给随后的 defconfig 展开。
#
# 对应手工编译流程（AN7581-PON自编译插件配置）:
#   Extra packages -> autocore / automount
#   LuCI -> Applications -> autoreboot / ddns / homeproxy / ttyd / upnp / wechatpush / wol
#   LuCI -> Themes -> luci-theme-argon
#   Network -> IP Addresses and Names -> ddns-scripts-cloudflare
#
# ⚠ 这些包都在 ponwrt 自带 feeds 里，不需要 git clone；本体由 kconfig
#   依赖自动带出（如 luci-app-ddns -> ddns-scripts）。
# ⚠ 必须先于 defconfig 运行：defconfig 会重新展开符号，之后写的 =y 无效。
# ================================================================

set -euo pipefail

# workflow 用 if: env.EXTRA_PLUGINS == 'true' 控制是否调用；本地手工跑
# 默认开启，可用 EXTRA_PLUGINS=false ./diy-part3.sh 跳过。
EXTRA_PLUGINS="${EXTRA_PLUGINS:-true}"

if [ "$EXTRA_PLUGINS" != "true" ]; then
  echo "额外插件开关关闭（EXTRA_PLUGINS=$EXTRA_PLUGINS），跳过 diy-part3.sh"
  exit 0
fi

echo "=========================================="
echo "额外插件注入 (diy-part3.sh)"
echo "=========================================="

if [ ! -f .config ]; then
  echo "::error::当前目录没有 .config（cwd=$PWD），diy-part3.sh 必须在机型配置加载之后运行"
  exit 1
fi

# 包名 + 手工 menuconfig 路径对照。只用空格分隔包名，注释放行尾，解析取第一列。
EXTRA_PKGS="
autocore                  # Extra packages -> autocore
automount                 # Extra packages -> automount（自动挂载）
luci-app-autoreboot       # LuCI -> Applications -> 计划重启
luci-app-ddns             # LuCI -> Applications -> 动态域名 DNS
luci-app-homeproxy        # LuCI -> Applications -> HomeProxy 代理
luci-app-ttyd             # LuCI -> Applications -> ttyd 终端
luci-app-upnp             # LuCI -> Applications -> UPnP 端口自动转发
luci-app-wechatpush       # LuCI -> Applications -> 微信推送
luci-app-wol              # LuCI -> Applications -> WOL 网络唤醒
luci-theme-argon          # LuCI -> Themes -> argon 主题
ddns-scripts-cloudflare   # Network -> IP Addresses and Names -> Cloudflare DDNS
"

added=0
while read -r pkg _rest; do
  case "$pkg" in ''|\#*) continue ;; esac

  # 先删同名旧行（含 =y/=m 与 "# ... is not set"），再追加 =y。
  # 不删干净会留下重复行，defconfig/diffconfig 都以最后一行为准，人工排查易误判。
  sed -i "/^CONFIG_PACKAGE_${pkg}=/d; /^# CONFIG_PACKAGE_${pkg} is not set/d" .config
  echo "CONFIG_PACKAGE_${pkg}=y" >> .config
  echo "  + CONFIG_PACKAGE_${pkg}=y"
  added=$((added + 1))
done <<EOF
$EXTRA_PKGS
EOF

echo "✅ 额外插件已写入 .config（$added 项），等待 defconfig 展开"
echo "ℹ 若某项 defconfig 后被剔除，说明当前源码树 feeds 里没有该包（会被静默删符号）"
