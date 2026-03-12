# 请在下方输入自定义命令(一般用来安装第三方插件)(可以留空)
# Please enter the custom command below (usually used to install third-party plugins) (can be left blank)
git clone https://github.com/immortalwrt/immortalwrt
# https://github.com/immortalwrt/immortalwrt
# git clone --depth=1 https://github.com/EOYOHOO/UA2F.git package/UA2F
# git clone --depth=1 https://github.com/EOYOHOO/rkp-ipid.git package/rkp-ipid
#!/bin/bash

# Create the auto-resize script that runs on the first boot of the R2S
mkdir -p files/etc/uci-defaults
cat << 'EOF' > files/etc/uci-defaults/99-r2s-setup
#!/bin/sh
if [ ! -e /etc/config/resize_done ]; then
    # 1. Expand Partition 2 to use the whole SD Card
    parted -s /dev/mmcblk0 resizepart 2 100%
    touch /etc/config/resize_done
    
    # 2. Setup 1GB Swap (Crucial for Docker on R2S)
    mkdir -p /opt
    dd if=/dev/zero of=/opt/swap bs=1M count=1024
    mkswap /opt/swap
    echo "/opt/swap swap swap defaults 0 0" >> /etc/fstab
    
    # Reboot to apply partition changes
    reboot
fi

# 3. Expand Filesystem (Runs after the reboot above)
if [ -e /etc/config/resize_done ] && [ ! -e /etc/config/fs_done ]; then
    resize2fs /dev/mmcblk0p2
    touch /etc/config/fs_done
fi
exit 0
EOF
