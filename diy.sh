#!/bin/bash

# 1. 修复 DNSMasq 冲突 (强制使用 dnsmasq-full)
sed -i 's/dnsmasq/dnsmasq-full/g' include/target.mk

# 2. 保持默认 IP 为 192.168.1.1
# 已移除修改 IP 的 sed 命令

# 3. 创建首次启动设置脚本 (针对 R2S 的分区扩容和 Swap 设置)
# 注意：我们是在源码目录下创建 files 文件夹，它会被编译进固件
mkdir -p files/etc/uci-defaults
cat << 'EOF' > files/etc/uci-defaults/99-r2s-setup
#!/bin/sh
# 检查是否需要扩容
if [ ! -e /etc/config/resize_done ]; then
    # 将分区 2 扩展到整个 SD 卡
    parted -s /dev/mmcblk0 resizepart 2 100% || true
    touch /etc/config/resize_done
    
    # 为 1GB 内存设备创建 1GB Swap (如果你跑 Docker，这很重要)
    if [ ! -f /opt/swap ]; then
        mkdir -p /opt
        dd if=/dev/zero of=/opt/swap bs=1M count=1024
        mkswap /opt/swap
        chmod 600 /opt/swap
    fi
    
    # 立即启用并写入挂载表
    swapon /opt/swap
    echo "/opt/swap swap swap defaults 0 0" >> /etc/fstab
    
    # 重启以应用分区更改
    reboot
fi

# 重启后扩容文件系统
if [ -e /etc/config/resize_done ] && [ ! -e /etc/config/fs_done ]; then
    resize2fs /dev/mmcblk0p2
    touch /etc/config/fs_done
fi
exit 0
EOF

# 4. 设置脚本执行权限
chmod +x files/etc/uci-defaults/99-r2s-setup
