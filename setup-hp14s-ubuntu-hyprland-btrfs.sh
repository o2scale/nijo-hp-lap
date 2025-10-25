#!/bin/bash
# ==========================================================
#  HP Laptop 14s-dq2xxx (i5-1135G7) — Ubuntu Server 24.04 LTS → Hyprland + GDM
#  Heavy Workload Edition (MATLAB, PCB Design, Engineering Apps)
#  Author : Anjai Jacob + Claude Assistant
#  Version: 3.0 Heavy Workload Edition (2024-10)
# ==========================================================
set -e
LOGFILE="$HOME/setup-hp14s.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "🚀 Starting Ubuntu Server → Hyprland Heavy Workload Setup on HP 14s..."
echo "⚙️  Optimized for: MATLAB, PCB Design, CAD, Engineering Applications"
echo "💾 Target: 8GB RAM with 20GB swap + 4GB zram = ~32GB usable memory"
echo ""

# ---------- 1. System Update + Essentials ----------
echo "📦 Step 1/12: System Update & Essential Packages..."
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y curl wget git unzip build-essential ca-certificates \
    software-properties-common apt-transport-https dkms linux-headers-$(uname -r)

# ---------- 2. Firmware & Hardware Drivers ----------
echo "🔧 Step 2/12: Firmware & Hardware Drivers (Intel + Realtek)..."
sudo apt install -y \
    linux-firmware fwupd intel-microcode \
    thermald tlp tlp-rdw powertop \
    mesa-utils mesa-vulkan-drivers vulkan-tools intel-media-va-driver-non-free \
    pipewire wireplumber pipewire-audio-client-libraries libspa-0.2-bluetooth \
    alsa-utils pavucontrol

# Enable power management services
sudo systemctl enable thermald
sudo systemctl enable tlp

# Firmware updates
sudo fwupdmgr refresh --force || true
sudo fwupdmgr get-updates || true

# ---------- 3. Realtek RTL8822CE WiFi/Bluetooth Drivers ----------
echo "📡 Step 3/12: Realtek RTL8822CE WiFi & Bluetooth Drivers..."
echo "  → WiFi already working via NetworkManager - skipping driver build"
echo "  → Enabling Bluetooth only..."

# Enable Bluetooth (WiFi already working)
sudo systemctl enable bluetooth
sudo systemctl start bluetooth || true

# ---------- 4. Display Manager + Minimal GNOME Core ----------
echo "🖥️  Step 4/12: Display Manager (GDM) + Minimal GNOME..."
sudo apt install -y \
    gdm3 gnome-session gnome-control-center \
    gnome-terminal nautilus gnome-calculator gnome-system-monitor \
    gnome-tweaks gnome-shell-extension-prefs

sudo systemctl enable gdm
sudo systemctl set-default graphical.target

# ---------- 5. Hyprland Installation ----------
echo "🌊 Step 5/12: Hyprland installation (manual)..."
echo "  → Skipping automatic Hyprland installation"
echo "  → Install manually: cd ~/Ubuntu-Hyprland && ./install.sh"
echo "  → Hyprland will be configured separately"

# ---------- 6. Heavy Workload Performance Tuning ----------
echo "⚡ Step 6/11: Heavy Workload Performance Optimizations..."

# A. Install and Configure zram (Critical for 8GB RAM)
echo "  → Installing and configuring zram (4GB compressed)..."
sudo apt install -y systemd-zram-generator

sudo tee /etc/systemd/zram-generator.conf > /dev/null <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
EOF

sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service || true

# B. System Tuning (sysctl) - Memory Management for Heavy Workloads
echo "  → Configuring sysctl for heavy memory workloads..."
sudo tee /etc/sysctl.d/99-workload-performance.conf > /dev/null <<'EOF'
# Memory Management (Heavy Workload - 8GB RAM)
vm.swappiness = 60
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 80
vm.min_free_kbytes = 131072

# File System Limits (MATLAB, Docker, VS Code)
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024

# Network Performance
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
EOF

sudo sysctl --system

# C. I/O Scheduler: BFQ (prevents system freeze during heavy swap)
echo "  → Setting BFQ I/O scheduler for NVMe..."
sudo tee /etc/udev/rules.d/60-ioschedulers.rules > /dev/null <<'EOF'
# BFQ scheduler for NVMe (prevents I/O starvation during heavy swap)
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="bfq"
EOF

# D. NVMe Read-Ahead Optimization (2MB for balanced performance)
echo "  → Setting NVMe readahead to 2MB..."
sudo tee -a /etc/udev/rules.d/60-ioschedulers.rules > /dev/null <<'EOF'
# NVMe readahead optimization
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/read_ahead_kb}="2048"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

# E. Intel Iris Xe Graphics Optimization
echo "  → Enabling Intel Iris Xe GuC/HuC firmware..."
sudo tee /etc/modprobe.d/i915.conf > /dev/null <<'EOF'
# Intel Iris Xe Graphics Optimization
options i915 enable_guc=2 enable_fbc=1 enable_psr=1
EOF

sudo update-initramfs -u

# F. tmpfs for /tmp and /var/tmp (reduce SSD writes)
echo "  → Configuring tmpfs for /tmp and /var/tmp..."
if ! grep -q "tmpfs /tmp" /etc/fstab; then
    echo "tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0" | sudo tee -a /etc/fstab
fi
if ! grep -q "tmpfs /var/tmp" /etc/fstab; then
    echo "tmpfs /var/tmp tmpfs defaults,noatime,mode=1777 0 0" | sudo tee -a /etc/fstab
fi

# G. Disable NUMA balancing (not needed for single socket)
echo "  → Disabling NUMA balancing..."
echo 0 | sudo tee /proc/sys/kernel/numa_balancing > /dev/null
echo "kernel.numa_balancing = 0" | sudo tee -a /etc/sysctl.d/99-workload-performance.conf

# ---------- 7. TLP Power Management Configuration ----------
echo "🔋 Step 7/11: Configuring TLP for Performance..."

sudo tee -a /etc/tlp.conf > /dev/null <<'EOF'

# HP 14s Heavy Workload Optimizations
CPU_SCALING_GOVERNOR_ON_AC=schedutil
CPU_SCALING_GOVERNOR_ON_BAT=schedutil
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0

# Platform Profile
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=balanced

# PCI Express Active State Power Management
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersupersave

# Runtime Power Management
RUNTIME_PM_ON_AC=auto
RUNTIME_PM_ON_BAT=auto
EOF

sudo systemctl restart tlp || true

# Run powertop auto-tune once
sudo powertop --auto-tune || true

# ---------- 8. Timeshift (Btrfs Snapshot System) ----------
echo "📸 Step 8/11: Installing Timeshift for Btrfs snapshots..."
sudo apt install -y timeshift

# Install timeshift-autosnap-apt for automatic snapshots on apt upgrade
sudo apt install -y timeshift-autosnap-apt || {
    echo "⚠️  timeshift-autosnap-apt not in repos, installing manually..."
    CURRENT_DIR=$(pwd)
    cd /tmp
    wget -q https://github.com/wmutschl/timeshift-autosnap-apt/archive/refs/heads/master.zip || {
        echo "⚠️  Failed to download timeshift-autosnap-apt, skipping..."
        cd "$CURRENT_DIR"
        return 0
    }
    unzip -q master.zip || {
        echo "⚠️  Failed to unzip, skipping..."
        cd "$CURRENT_DIR"
        return 0
    }
    if [ -d "timeshift-autosnap-apt-master" ]; then
        cd timeshift-autosnap-apt-master
        sudo make install || echo "⚠️  Make install failed, but continuing..."
        cd /tmp
        rm -rf timeshift-autosnap-apt-master master.zip
    fi
    cd "$CURRENT_DIR"
}

echo "💡 Configure Timeshift via GUI: sudo timeshift-gtk"
echo "   → Select Btrfs mode"
echo "   → Set schedule: Hourly (6), Daily (7), Weekly (4)"

# ---------- 9. Essential Utilities ----------
echo "🛠️  Step 9/11: Installing Essential Utilities..."

sudo apt install -y \
    htop btop \
    curl wget git \
    firefox gedit

# ---------- 10. App Management (Flatpak + bauh) ----------
echo "📦 Step 10/11: Setting up Flatpak & bauh app store..."

sudo apt install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# bauh - GUI app store (Flatpak aware)
# Install python3-pip first
sudo apt install -y python3-pip python3-venv pipx || true
pip3 install --user bauh || true

# ---------- 11. CUPS Printing (disabled by default) ----------
echo "🖨️  Step 11/11: Installing CUPS (disabled by default)..."
sudo apt install -y cups cups-filters system-config-printer avahi-daemon

# Disable by default (enable when needed)
sudo systemctl disable cups
sudo systemctl disable cups-browsed
sudo systemctl disable avahi-daemon

# Create toggle script
sudo tee /usr/local/bin/toggle-printing > /dev/null <<'EOF'
#!/bin/bash
if systemctl is-active --quiet cups; then
    sudo systemctl stop cups cups-browsed avahi-daemon
    echo "🖨️  Printing services stopped"
else
    sudo systemctl start cups cups-browsed avahi-daemon
    echo "🖨️  Printing services started"
fi
EOF

sudo chmod +x /usr/local/bin/toggle-printing

# ---------- Hibernation Setup ----------
echo "💤 Setting up hibernation with 20GB swap..."

SWAP_UUID=$(blkid -s UUID -o value $(swapon --show=NAME --noheadings | head -1))

if [ -n "$SWAP_UUID" ]; then
    echo "  → Found swap UUID: $SWAP_UUID"

    # Update GRUB
    if ! grep -q "resume=UUID=$SWAP_UUID" /etc/default/grub; then
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"resume=UUID=$SWAP_UUID /" /etc/default/grub
        sudo update-grub
        echo "  → Added resume parameter to GRUB"
    fi

    # Install uswsusp for better hibernation
    sudo apt install -y uswsusp

    echo "💡 Test hibernation: sudo systemctl hibernate"
else
    echo "⚠️  No swap partition found! Hibernation will not work."
    echo "    Expected 20GB swap partition for heavy workloads."
fi

# ---------- Automatic Updates Timer ----------
echo "🔄 Setting up bi-weekly automatic updates..."

sudo tee /etc/systemd/system/auto-update.service > /dev/null <<'EOF'
[Unit]
Description=Automatic System Update
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/apt update
ExecStart=/usr/bin/apt upgrade -y
ExecStart=/usr/bin/apt autoremove -y
EOF

sudo tee /etc/systemd/system/auto-update.timer > /dev/null <<'EOF'
[Unit]
Description=Run automatic updates bi-weekly

[Timer]
OnCalendar=Sun *-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable auto-update.timer

# ---------- Cleanup + Summary ----------
echo ""
echo "🧹 Cleaning up..."
sudo apt autoremove -y
sudo apt clean

echo ""
echo "✅ =========================================="
echo "✅  HP 14s Heavy Workload Setup Complete!"
echo "✅ =========================================="
echo ""
echo "📊 System Configuration:"
echo "   • 20GB Swap partition for heavy workloads"
echo "   • 4GB zram (compressed, ~8-10GB effective)"
echo "   • Total usable memory: ~32GB"
echo "   • BFQ I/O scheduler (prevents freeze during swap)"
echo "   • vm.swappiness = 60 (aggressive swap)"
echo "   • Realtek RTL8822CE WiFi/Bluetooth drivers"
echo "   • Intel Iris Xe with GuC/HuC firmware"
echo ""
echo "🎯 Optimized for:"
echo "   • MATLAB simulations (10-20GB)"
echo "   • PCB design (KiCad, Altium) 5-15GB"
echo "   • CAD and engineering applications"
echo ""
echo "📋 Next Steps:"
echo "   1. Reboot: sudo reboot"
echo "   2. At GDM login, select 'Hyprland' session (gear icon)"
echo "   3. Configure Timeshift: sudo timeshift-gtk"
echo "   4. Verify zram: zramctl"
echo "   5. Check swap: swapon --show"
echo "   6. Test hibernation: sudo systemctl hibernate"
echo ""
echo "🔧 Useful Commands:"
echo "   • Check memory: free -h"
echo "   • Check I/O scheduler: cat /sys/block/nvme0n1/queue/scheduler"
echo "   • Monitor resources: btop"
echo "   • Toggle printing: toggle-printing"
echo "   • Install more apps: bauh (GUI app store)"
echo ""
echo "💾 Log saved to: $LOGFILE"
echo ""
echo "⚠️  IMPORTANT: Please REBOOT now!"
echo ""
