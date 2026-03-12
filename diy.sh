#!/bin/bash

# =========================================================
# 1. FIX DNSMASQ CONFLICTS
# =========================================================
# This replaces the standard dnsmasq with dnsmasq-full in the build system
# to prevent "multiple packages providing dnsmasq" errors.
sed -i 's/dnsmasq/dnsmasq-full/g' include/target.mk

# =========================================================
# 2. CREATE FIRST-BOOT SETUP SCRIPT (R2S)
# =========================================================
# This script handles SD card expansion and creates 1GB of swap
mkdir -p files/etc/uci-defaults
cat << 'EOF' > files/etc/uci-defaults/99-r2s-setup
#!/bin/sh
# Check if we need to resize the partition
if [ ! -e /etc/config/resize_done ]; then
    # Expand Partition 2 to use the whole SD Card
    parted -s /dev/mmcblk0 resizepart 2 100%
    touch /etc/config/resize_done
    
    # Create 1GB Swap file (Essential for Docker/OpenClash on 1GB RAM)
    mkdir -p /opt
    dd if=/dev/zero of=/opt/swap bs=1M count=1024
    mkswap /opt/swap
    swapon /opt/swap
    echo "/opt/swap swap swap defaults 0 0" >> /etc/fstab
    
    # Reboot to apply partition table changes
    reboot
fi

# Expand Filesystem (Runs after the reboot above)
if [ -e /etc/config/resize_done ] && [ ! -e /etc/config/fs_done ]; then
    resize2fs /dev/mmcblk0p2
    touch /etc/config/fs_done
fi
exit 0
EOF

# =========================================================
# 3. SET PERMISSIONS
# =========================================================
# Ensure the setup script is executable by the system
chmod +x files/etc/uci-defaults/99-r2s-setup

# =========================================================
# 4. (OPTIONAL) ADD CUSTOM FEEDS/PLUGINS
# =========================================================
# If you want to add specific plugins via git, do it here:
# Example: git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
