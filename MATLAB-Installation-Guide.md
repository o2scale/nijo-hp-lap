# MATLAB Installation Guide for HP 14s Ubuntu 24.04

Complete guide for installing MATLAB R2024b on Ubuntu 24.04 with Hyprland, optimized for heavy workloads.

## Prerequisites

- ✅ Ubuntu 24.04 LTS installed
- ✅ Hyprland + GDM setup complete
- ✅ Internet connection active
- ✅ MathWorks account (student, academic, or commercial license)
- ✅ At least 30GB free disk space

## System Specifications

Your HP 14s setup:
- **RAM**: 8GB physical + 4GB zram (compressed) + 20GB swap = ~32GB usable
- **CPU**: Intel i5-1135G7 (4 cores, 8 threads)
- **Disk**: NVMe SSD with Btrfs compression
- **Graphics**: Intel Iris Xe

## Installation Methods

### Method 1: Automated Installation (Recommended)

**Step 1: Download the installation script**

```bash
cd ~
git clone https://github.com/o2scale/nijo-hp-lap.git
cd nijo-hp-lap
chmod +x install-matlab.sh
```

**Step 2: Download MATLAB installer from MathWorks**

1. Open Firefox and go to: https://www.mathworks.com/downloads
2. Sign in with your MathWorks account
3. Select **MATLAB R2024b** (or latest version)
4. Click **Download** → Choose **Linux Installer**
5. Save to: `~/matlab-installer/` (create this folder if needed)
6. Expected file: `matlab_R2024b_glnxa64.zip` (~20GB)

**Step 3: Run the installation script**

```bash
./install-matlab.sh
```

The script will:
- Install all required dependencies
- Extract the MATLAB installer
- Launch the graphical installer
- Configure MATLAB for Hyprland/Wayland
- Create desktop shortcuts
- Add MATLAB to PATH

**Step 4: Follow the GUI installer**

When the MATLAB installer GUI opens:

1. **Login**: Sign in with your MathWorks account
2. **License**: Accept the license agreement
3. **Installation Folder**: Use `/usr/local/MATLAB/R2024b`
4. **Products**: Select products to install
   - **Recommended for engineering**:
     - MATLAB (base)
     - Simulink
     - Control System Toolbox
     - Signal Processing Toolbox
     - Statistics and Machine Learning Toolbox
     - Optimization Toolbox
   - Select what you have licensed
5. **Options**: Enable "Create symbolic links"
6. **Install**: Click Install and wait (15-30 minutes)

**Step 5: Launch MATLAB**

After installation completes:

```bash
# Recommended for Hyprland (most stable)
matlab-hyprland

# Or standard launch
matlab

# Or from application menu
# Search for "MATLAB" in your launcher
```

---

### Method 2: Manual Installation

If you prefer to install manually:

**Step 1: Install dependencies**

```bash
sudo apt update
sudo apt install -y \
    build-essential gcc g++ gfortran \
    make cmake \
    libx11-6 libxext6 libxrender1 libxtst6 libxi6 \
    libgtk-3-0 libgtk2.0-0 \
    libnss3 libnspr4 libglib2.0-0 \
    libpango-1.0-0 libpangocairo-1.0-0 \
    libcairo2 libasound2 \
    libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libgbm1 \
    libxcb1 libxcomposite1 libxcursor1 libxdamage1 \
    libxfixes3 libxrandr2 libxshmfence1 \
    ca-certificates locales

sudo locale-gen en_US.UTF-8
```

**Step 2: Download MATLAB**

Download from https://www.mathworks.com/downloads as described above.

**Step 3: Extract and install**

```bash
mkdir -p ~/matlab-installer
cd ~/matlab-installer
unzip matlab_R2024b_glnxa64.zip
cd matlab-extracted
./install
```

**Step 4: Post-installation setup**

Add MATLAB to PATH:

```bash
echo 'export PATH="/usr/local/MATLAB/R2024b/bin:$PATH"' >> ~/.bashrc
echo 'alias matlab="/usr/local/MATLAB/R2024b/bin/matlab"' >> ~/.bashrc
source ~/.bashrc
```

Create Hyprland-compatible launcher:

```bash
sudo tee /usr/local/bin/matlab-hyprland > /dev/null <<'EOF'
#!/bin/bash
export QT_QPA_PLATFORM=xcb
export GDK_BACKEND=x11
export _JAVA_AWT_WM_NONREPARENTING=1
/usr/local/MATLAB/R2024b/bin/matlab "$@"
EOF

sudo chmod +x /usr/local/bin/matlab-hyprland
```

---

## Usage

### Launching MATLAB

**Desktop GUI (Recommended):**
```bash
matlab-hyprland
```

**Standard launch:**
```bash
matlab
```

**Command-line only (no GUI):**
```bash
matlab -nodesktop -nosplash
```

**Run a script:**
```bash
matlab -batch "run('myScript.m')"
```

### First Launch

- First launch may take 30-60 seconds to start
- MATLAB will verify your license automatically
- Set up your workspace preferences

### Performance Tips

**1. Monitor Memory Usage**

Open a terminal and run:
```bash
btop
```

This shows:
- RAM usage
- Swap usage
- CPU usage
- Per-process breakdown

**2. Close Unnecessary Applications**

Before running heavy simulations:
```bash
# Close Firefox, other apps
# Keep only terminal and MATLAB open
```

**3. Pre-allocate Large Arrays**

In MATLAB, pre-allocate instead of growing arrays:
```matlab
% Good (pre-allocate)
data = zeros(1000000, 1);
for i = 1:1000000
    data(i) = i^2;
end

% Bad (slow, fragments memory)
data = [];
for i = 1:1000000
    data(i) = i^2;
end
```

**4. Use Parallel Processing**

Your i5-1135G7 has 8 threads:
```matlab
% Start parallel pool
parpool(8)

% Use parfor instead of for
parfor i = 1:1000
    % parallel operations
end
```

**5. Clear Workspace Regularly**

```matlab
% Clear unused variables
clear variableName

% Clear all
clear all

% Clear and close figures
close all; clear all;
```

### Handling Large Datasets

With 8GB RAM + 32GB total memory:

**Datasets < 8GB**: Will run entirely in RAM (fast)
**Datasets 8-20GB**: Will use zram (compressed, still fast)
**Datasets 20-30GB**: Will use swap (slower but works)
**Datasets > 30GB**: Consider using:
- `matfile()` for partial loading
- Datastore objects
- Chunked processing

Example for large files:
```matlab
% Instead of loading entire file
% load('huge_data.mat')  % Bad for >10GB

% Load partially
m = matfile('huge_data.mat');
chunk = m.data(1:1000, :);  % Load only what you need
```

---

## Troubleshooting

### MATLAB Won't Start

**Issue**: MATLAB crashes or shows blank window

**Solution**: Use Hyprland-compatible launcher
```bash
matlab-hyprland
```

### Out of Memory Errors

**Check available memory:**
```bash
free -h
swapon --show
```

**Solutions:**
1. Close other applications
2. Clear MATLAB workspace: `clear all`
3. Process data in chunks
4. Restart MATLAB to free memory

### Slow Performance / System Freeze

**Cause**: Heavy swap usage

**Solutions:**
1. Monitor with `btop`
2. Reduce dataset size
3. Use `parfor` instead of `for` loops
4. Enable swap optimization (already configured in setup script)

**Check I/O scheduler** (should be BFQ):
```bash
cat /sys/block/nvme0n1/queue/scheduler
# Should show: [bfq] none mq-deadline
```

### Graphics Issues

**Blank plots or rendering problems:**

```bash
# Run MATLAB with software OpenGL
matlab-hyprland -softwareopengl
```

### License Activation Issues

**Check license status:**
```matlab
license
```

**Re-activate license:**
1. In MATLAB: Help → Licensing → Activate Software
2. Or run: `matlab -activate`

---

## MATLAB Toolboxes

### Check Installed Toolboxes

In MATLAB:
```matlab
ver
```

### Essential Toolboxes for Engineering

- **Simulink**: Model-based design
- **Control System Toolbox**: Control design
- **Signal Processing Toolbox**: Filtering, FFT, wavelets
- **Statistics and Machine Learning**: Data analysis, ML algorithms
- **Optimization Toolbox**: Linear/nonlinear optimization
- **Symbolic Math Toolbox**: Symbolic computations

### Installing Additional Toolboxes

1. In MATLAB: Home → Add-Ons → Get Add-Ons
2. Or use Add-On Explorer
3. Requires MathWorks account login

---

## Benchmarking Your Setup

Test MATLAB performance:

```matlab
% CPU benchmark
tic
A = rand(5000);
B = rand(5000);
C = A * B;
toc

% Should take ~2-5 seconds on i5-1135G7

% Memory benchmark
tic
bigArray = zeros(10000, 10000);  % ~800MB
toc

% FFT benchmark
tic
x = rand(1, 10000000);
y = fft(x);
toc
```

---

## Useful MATLAB Commands

### System Information

```matlab
% Check MATLAB version
version

% Check Java version
version -java

% Check available memory
memory

% System information
computer
feature('numcores')  % Number of CPU cores
```

### Workspace Management

```matlab
% Show variables
whos

% Save workspace
save('myWorkspace.mat')

% Load workspace
load('myWorkspace.mat')

% Clear specific variables
clear variableName

% Clear all
clear all; close all; clc;
```

### Performance Profiling

```matlab
% Profile code
profile on
myFunction()
profile viewer

% Time execution
tic
myCode()
elapsed = toc
```

---

## PCB Design / Circuit Simulation

For PCB design workflows with MATLAB:

### Integration with KiCad/Altium

```matlab
% Export data for PCB tools
csvwrite('circuit_data.csv', data);

% Generate netlist
% Use Simulink → Simscape Electrical
```

### Circuit Analysis

```matlab
% Transfer function analysis
s = tf('s');
H = 1/(s^2 + 2*s + 1);
bode(H)

% Step response
step(H)

% Frequency response
[mag, phase, freq] = bode(H);
```

---

## Uninstalling MATLAB

If you need to remove MATLAB:

```bash
# Remove MATLAB installation
sudo rm -rf /usr/local/MATLAB

# Remove configuration
rm -rf ~/.matlab

# Remove desktop entry
rm ~/.local/share/applications/matlab.desktop

# Remove from PATH (edit ~/.bashrc)
nano ~/.bashrc
# Delete MATLAB-related lines
```

---

## Additional Resources

- **MathWorks Documentation**: https://www.mathworks.com/help/matlab/
- **MATLAB Answers**: https://www.mathworks.com/matlabcentral/answers/
- **File Exchange**: https://www.mathworks.com/matlabcentral/fileexchange/
- **Getting Started**: https://www.mathworks.com/help/matlab/getting-started-with-matlab.html

---

## Support

For issues specific to this setup:
- GitHub Issues: https://github.com/o2scale/nijo-hp-lap/issues
- Check logs: `~/matlab-install.log`

For MATLAB software issues:
- MathWorks Support: https://www.mathworks.com/support.html

---

**Happy Computing! 🚀**

*Optimized for HP 14s-dq2xxx with heavy workload support*
