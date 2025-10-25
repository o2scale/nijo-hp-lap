#!/bin/bash
# ==========================================================
#  MATLAB R2024b Installation Script for Ubuntu 24.04
#  HP Laptop 14s-dq2xxx (i5-1135G7, 8GB RAM)
#  Author: Anjai Jacob + Claude Assistant
#  Version: 1.0 (2024-10)
# ==========================================================

set -e
LOGFILE="$HOME/matlab-install.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=============================================="
echo "  MATLAB Installation for Ubuntu 24.04"
echo "  HP 14s Heavy Workload Edition"
echo "=============================================="
echo ""

# Check if running with sudo
if [ "$EUID" -eq 0 ]; then
   echo "⚠️  ERROR: Please run this script as a regular user (without sudo)"
   echo "   The script will prompt for sudo when needed."
   exit 1
fi

# ---------- Step 1: Install Dependencies ----------
echo "📦 Step 1/6: Installing MATLAB dependencies..."

sudo apt update
sudo apt install -y \
    build-essential \
    gcc g++ gfortran \
    make cmake \
    libx11-6 libxext6 libxrender1 libxtst6 libxi6 \
    libgtk-3-0 libgtk2.0-0 \
    libnss3 libnspr4 \
    libglib2.0-0 \
    libpango-1.0-0 libpangocairo-1.0-0 \
    libcairo2 \
    libasound2 \
    libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 libgbm1 \
    libxcb1 libxcomposite1 libxcursor1 libxdamage1 \
    libxfixes3 libxrandr2 \
    libxshmfence1 \
    ca-certificates \
    locales

# Set locale (MATLAB needs proper locale)
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8

echo "✅ Dependencies installed"
echo ""

# ---------- Step 2: Prepare Installation Directory ----------
echo "📁 Step 2/6: Preparing installation directories..."

INSTALL_DIR="/usr/local/MATLAB"
DOWNLOAD_DIR="$HOME/matlab-installer"

# Create directories
mkdir -p "$DOWNLOAD_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo chown $USER:$USER "$INSTALL_DIR"

echo "  → Installation directory: $INSTALL_DIR"
echo "  → Download directory: $DOWNLOAD_DIR"
echo ""

# ---------- Step 3: Download MATLAB ----------
echo "📥 Step 3/6: Download MATLAB Installer"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MANUAL STEP REQUIRED:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "You need to download MATLAB installer from MathWorks:"
echo ""
echo "1. Go to: https://www.mathworks.com/downloads"
echo "2. Sign in with your MathWorks account"
echo "3. Download: MATLAB R2024b for Linux"
echo "4. Download type: Choose 'Linux Installer'"
echo "5. Save the .zip file to: $DOWNLOAD_DIR/"
echo ""
echo "Expected file: matlab_R2024b_glnxa64.zip (or similar)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Press ENTER when you have downloaded the MATLAB installer zip file..."

# Find the installer zip file
INSTALLER_ZIP=$(find "$DOWNLOAD_DIR" -name "matlab_*_glnxa64.zip" | head -1)

if [ -z "$INSTALLER_ZIP" ]; then
    echo "⚠️  ERROR: MATLAB installer zip not found in $DOWNLOAD_DIR"
    echo "   Please download the installer and run this script again."
    exit 1
fi

echo "✅ Found installer: $(basename $INSTALLER_ZIP)"
echo ""

# ---------- Step 4: Extract Installer ----------
echo "📦 Step 4/6: Extracting MATLAB installer..."

cd "$DOWNLOAD_DIR"
unzip -q "$INSTALLER_ZIP" -d matlab-extracted
cd matlab-extracted

echo "✅ Installer extracted"
echo ""

# ---------- Step 5: Run MATLAB Installer ----------
echo "🚀 Step 5/6: Running MATLAB installer..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  INTERACTIVE INSTALLATION:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The MATLAB installer GUI will now open."
echo ""
echo "During installation:"
echo "  1. Sign in with your MathWorks account"
echo "  2. Accept the license agreement"
echo "  3. Select installation folder: $INSTALL_DIR/R2024b"
echo "  4. Select products to install (recommended: all)"
echo "  5. Create symbolic links: YES"
echo "  6. Wait for installation (may take 15-30 minutes)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Press ENTER to launch the MATLAB installer..."

# Launch installer
./install

echo ""
echo "✅ MATLAB installation completed"
echo ""

# ---------- Step 6: Post-Installation Setup ----------
echo "⚙️  Step 6/6: Post-installation configuration..."

# Create desktop entry
echo "  → Creating desktop application entry..."

mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/matlab.desktop <<EOF
[Desktop Entry]
Type=Application
Name=MATLAB R2024b
Comment=MATLAB - The Language of Technical Computing
Exec=/usr/local/MATLAB/R2024b/bin/matlab -desktop
Icon=/usr/local/MATLAB/R2024b/bin/glnxa64/cef_resources/matlab_icon.png
Terminal=false
Categories=Development;Science;Math;
StartupNotify=true
StartupWMClass=MATLAB R2024b - academic use
EOF

chmod +x ~/.local/share/applications/matlab.desktop

# Add MATLAB to PATH
echo "  → Adding MATLAB to PATH..."

if ! grep -q "MATLAB/R2024b/bin" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# MATLAB" >> ~/.bashrc
    echo 'export PATH="/usr/local/MATLAB/R2024b/bin:$PATH"' >> ~/.bashrc
fi

# Create convenient alias
if ! grep -q "alias matlab=" ~/.bashrc; then
    echo "alias matlab='/usr/local/MATLAB/R2024b/bin/matlab'" >> ~/.bashrc
fi

source ~/.bashrc

# Install additional MATLAB dependencies for better performance
echo "  → Installing additional libraries for optimal performance..."

sudo apt install -y \
    libncurses5 \
    libncurses5-dev \
    libfreetype6 \
    libfontconfig1 \
    libxss1 \
    libxft2

# Configure MATLAB for Wayland (Hyprland)
echo "  → Configuring MATLAB for Wayland/Hyprland..."

mkdir -p ~/.matlab/R2024b

cat > ~/.matlab/R2024b/matlab.prf <<EOF
% MATLAB Preferences for Hyprland/Wayland
% Force X11 backend (more stable than native Wayland)
java.awt.headless=false
EOF

# Create MATLAB launcher script for Hyprland
echo "  → Creating Hyprland-optimized launcher..."

sudo tee /usr/local/bin/matlab-hyprland > /dev/null <<'EOF'
#!/bin/bash
# MATLAB launcher for Hyprland (Wayland)
# Forces X11 backend for better compatibility

export QT_QPA_PLATFORM=xcb
export GDK_BACKEND=x11
export _JAVA_AWT_WM_NONREPARENTING=1

/usr/local/MATLAB/R2024b/bin/matlab "$@"
EOF

sudo chmod +x /usr/local/bin/matlab-hyprland

echo "✅ Post-installation setup complete"
echo ""

# ---------- Cleanup ----------
echo "🧹 Cleaning up installation files..."

cd "$HOME"
rm -rf "$DOWNLOAD_DIR/matlab-extracted"

echo "✅ Cleanup complete"
echo ""

# ---------- Summary ----------
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ MATLAB INSTALLATION COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Installation Location:"
echo "   /usr/local/MATLAB/R2024b/"
echo ""
echo "🚀 How to Launch MATLAB:"
echo ""
echo "   Method 1 (Recommended for Hyprland):"
echo "   $ matlab-hyprland"
echo ""
echo "   Method 2 (Standard):"
echo "   $ matlab"
echo ""
echo "   Method 3 (Desktop):"
echo "   Search for 'MATLAB' in your application launcher"
echo ""
echo "💡 First Launch Tips:"
echo "   • First launch may take 30-60 seconds"
echo "   • MATLAB will activate license automatically if signed in"
echo "   • For better performance, close other heavy applications"
echo "   • Uses system memory: can utilize full RAM + swap"
echo ""
echo "⚙️  MATLAB Toolboxes Installed:"
echo "   Check by running: ver (inside MATLAB)"
echo ""
echo "🔧 Useful Commands:"
echo "   • Check MATLAB version: matlab -batch \"ver\""
echo "   • Run script: matlab -batch \"run('script.m')\""
echo "   • Command line only: matlab -nodesktop -nosplash"
echo ""
echo "📊 Memory Management:"
echo "   Your system: 8GB RAM + 4GB zram + 20GB swap"
echo "   MATLAB can use: ~25-28GB for large simulations"
echo "   Monitor usage: Run 'btop' in another terminal"
echo ""
echo "⚠️  Important Notes:"
echo "   • If MATLAB crashes on Hyprland, use 'matlab-hyprland'"
echo "   • For heavy workloads, ensure sufficient swap space"
echo "   • Close browser/other apps during large simulations"
echo ""
echo "📝 Log saved to: $LOGFILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎉 Enjoy using MATLAB on your HP 14s!"
echo ""
