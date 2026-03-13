#!/bin/bash

# 1. Fix DNSMasq Conflicts (Force dnsmasq-full)
sed -i 's/dnsmasq/dnsmasq-full/g' include/target.mk

# 2. Change default IP (Optional but highly recommended for R2S)
# This changes the default IP from 192.168.1.1 to 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 3. Create First-Boot Setup Script
mkdir -p files/etc/uci-defaults
cat << 'EOF' > files/etc/uci-defaults/99-r2s-setup
#!/bin/sh
# Check if we need to resize the partition
if [ ! -e /etc/config/resize_done ]; then
    # Expand Partition 2 to use the whole SD Card
    # We use '|| true' so the script continues even if parted returns a minor warning
    parted -s /dev/mmcblk0 resizepart 2 100% || true
    touch /etc/config/resize_done
    
    # Create 1GB Swap file (Crucial for 1GB RAM devices running Docker)
    if [ ! -f /opt/swap ]; then
        mkdir -p /opt
        dd if=/dev/zero of=/opt/swap bs=1M count=1024
        mkswap /opt/swap
        chmod 600 /opt/swap
    fi
    
    # Enable swap immediately and on boot
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

# 4. Set Permissions
chmod +x files/etc/uci-defaults/99-r2s-setup
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
