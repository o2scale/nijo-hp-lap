# HP Laptop 14s-dq2xxx Ubuntu Setup

Ubuntu Server 24.04 LTS setup scripts and guides optimized for HP Laptop 14s-dq2xxx with Hyprland desktop environment.

## Hardware Specifications

- **Model**: HP Laptop 14s-dq2xxx
- **CPU**: Intel Core i5-1135G7 (11th Gen, 4 cores, 8 threads)
- **RAM**: 8GB DDR4 (upgradeable)
- **Graphics**: Intel Iris Xe Graphics
- **WiFi**: Realtek RTL8822CE
- **Storage**: 512GB NVMe SSD

## Features

- **Ubuntu Server 24.04 LTS** (minimal installation)
- **Hyprland** Wayland compositor via JaKooLit
- **GDM** display manager
- **Heavy workload optimizations** for MATLAB, PCB design, CAD
- **Memory management**: 8GB RAM + 4GB zram + 20GB swap = ~32GB effective
- **BTRFS filesystem** with compression and snapshots
- **NetworkManager** for easy WiFi connectivity

## Files

- `setup-hp14s-ubuntu-hyprland-btrfs.sh` - Main automated setup script
- `setup-hp14s-ubuntu-hyprland-btrfs-LEGACY.sh` - Legacy version with automatic Hyprland install
- `HP-14s-Ubuntu-Hyprland-Guide.md` - Comprehensive installation guide
- `download-networkmanager.txt` - Offline NetworkManager installation guide
- `00-installer-config.yaml` - Netplan WiFi configuration

## Quick Start

1. Install Ubuntu Server 24.04 LTS (disconnect WiFi during installation if it hangs)
2. Install NetworkManager for WiFi (see `download-networkmanager.txt`)
3. Clone this repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/NijoHP14S.git
   cd NijoHP14S
   ```
4. Run the setup script:
   ```bash
   bash setup-hp14s-ubuntu-hyprland-btrfs.sh
   ```
5. Manually install Hyprland:
   ```bash
   cd ~/Ubuntu-Hyprland
   ./install.sh
   ```
6. Reboot and select Hyprland at login

## Memory Optimization

The system is optimized for heavy workloads (MATLAB 10-20GB, PCB design 5-15GB):

- **zram**: 4GB compressed swap (priority 100)
- **Swap partition**: 20GB (priority 10)
- **BFQ I/O scheduler**: Prevents system freeze during heavy swap usage
- **vm.swappiness = 60**: Aggressive swap usage
- **Btrfs compression**: zstd:3 for space efficiency

## Performance Features

- Intel Iris Xe GuC/HuC firmware optimization
- TLP power management
- Thermald thermal management
- Pipewire audio
- Timeshift Btrfs snapshots
- Flatpak support

## Troubleshooting

### WiFi not working after installation
Install NetworkManager using the offline method in `download-networkmanager.txt`

### Slow boot (systemd-networkd-wait-online)
```bash
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service
sudo systemctl disable systemd-networkd
```

### Hyprland login loop
Hyprland may not have installed correctly. Manually run:
```bash
cd ~/Ubuntu-Hyprland
./install.sh
```

## Credits

- Setup by: Anjai Jacob + Claude Assistant
- Hyprland installer: [JaKooLit/Ubuntu-Hyprland](https://github.com/JaKooLit/Ubuntu-Hyprland)
- Timeshift autosnap: [wmutschl/timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt)

## License

MIT License - Feel free to use and modify
