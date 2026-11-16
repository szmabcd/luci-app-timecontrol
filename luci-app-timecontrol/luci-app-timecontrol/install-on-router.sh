#!/bin/sh
# luci-app-timecontrol 3.2.4 一键安装脚本（路由器上直接运行）
# 适用平台：apm821xx/nand + ImmortalWrt 24.10.6 / LuCI 26.114
# 用法：把整个 luci-app-timecontrol 目录拷到路由器（如 /tmp/），
#       然后 cd 进入该目录，执行: sh install-on-router.sh

SRC="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo " luci-app-timecontrol 3.2.4 安装"
echo " 源码目录: $SRC"
echo "=========================================="

# ---------- 1. 安装依赖 ----------
echo "[1/5] 安装依赖 (bash/nftables/conntrack/bc) ..."
if command -v opkg >/dev/null 2>&1; then
    opkg update >/dev/null 2>&1
    opkg install bash nftables conntrack bc 2>&1 | tail -5
    echo "      依赖安装结束（若已安装会提示 up to date）"
else
    echo "      未找到 opkg，跳过（固件可能已自带依赖）"
fi

# ---------- 2. 创建目录 ----------
echo "[2/5] 创建目标目录 ..."
mkdir -p /etc/config /etc/init.d /etc/uci-defaults \
         /usr/bin /usr/libexec \
         /usr/share/luci/menu.d /usr/share/rpcd/acl.d \
         /www/luci-static/resources/view/timecontrol

# ---------- 3. 复制文件（已存在的配置不覆盖） ----------
echo "[3/5] 复制文件 ..."
[ -s /etc/config/timecontrol ] || cp -f "$SRC/root/etc/config/timecontrol" /etc/config/timecontrol
cp -f "$SRC/root/etc/init.d/timecontrol"        /etc/init.d/timecontrol
cp -f "$SRC/root/etc/uci-defaults/luci-timecontrol" /etc/uci-defaults/
cp -f "$SRC/root/usr/bin/"*                     /usr/bin/
cp -f "$SRC/root/usr/libexec/"*                 /usr/libexec/
cp -f "$SRC/root/usr/share/luci/menu.d/luci-app-timecontrol.json" /usr/share/luci/menu.d/
cp -f "$SRC/root/usr/share/rpcd/acl.d/luci-app-timecontrol.json"  /usr/share/rpcd/acl.d/
cp -f "$SRC/htdocs/luci-static/resources/view/timecontrol/"*.js \
      /www/luci-static/resources/view/timecontrol/

# ---------- 4. 权限 + 初始化 ----------
echo "[4/5] 设置权限并初始化 ..."
chmod +x /etc/init.d/timecontrol /etc/uci-defaults/luci-timecontrol \
         /usr/bin/timecontrol* /usr/libexec/timecontrol-call
# 执行 uci-defaults：注册 ucitrack、确保默认配置存在
/etc/uci-defaults/luci-timecontrol >/dev/null 2>&1

# ---------- 5. 重启服务 ----------
echo "[5/5] 重启服务 ..."
/etc/init.d/rpcd restart       >/dev/null 2>&1
/etc/init.d/uhttpd restart     >/dev/null 2>&1
/etc/init.d/timecontrol enable >/dev/null 2>&1
/etc/init.d/timecontrol restart

echo ""
echo "=========================================="
echo " 安装完成！"
echo " 请退出 LuCI 并重新登录（ACL 变更需重登生效）。"
echo " 菜单位置：系统 -> Time Control"
echo ""
echo " 验证命令："
echo "   uci show timecontrol"
echo "   /etc/init.d/timecontrol status"
echo "   nft list table inet timecontrol | head"
echo "=========================================="
