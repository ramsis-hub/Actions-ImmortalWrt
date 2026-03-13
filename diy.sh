#!/bin/bash

# 1. 强制使用 dnsmasq-full (解决插件冲突)
sed -i 's/dnsmasq/dnsmasq-full/g' include/target.mk

# 2. 创建 R2S 自动扩容脚本
mkdir -p files/etc/uci-defaults
cat << 'EOF' > files/etc/uci-defaults/99-r2s-setup
#!/bin/sh
if [ ! -e /etc/config/resize_done ]; then
    parted -s /dev/mmcblk0 resizepart 2 100% || true
    touch /etc/config/resize_done
    
    if [ ! -f /opt/swap ]; then
        mkdir -p /opt
        dd if=/dev/zero of=/opt/swap bs=1M count=1024
        mkswap /opt/swap
        chmod 600 /opt/swap
    fi
    swapon /opt/swap
    echo "/opt/swap swap swap defaults 0 0" >> /etc/fstab
    reboot
fi

if [ -e /etc/config/resize_done ] && [ ! -e /etc/config/fs_done ]; then
    resize2fs /dev/mmcblk0p2
    touch /etc/config/fs_done
fi
exit 0
EOF

# 3. 设置脚本执行权限
chmod +x files/etc/uci-defaults/99-r2s-setup
