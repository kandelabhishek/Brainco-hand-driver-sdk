#!/bin/bash
# One-time setup for BrainCo Revo2 hands on a Unitree G1 (Jetson, aarch64).
# - Builds/installs WCH ch343 driver so hands appear as /dev/ttyCH343USB0/1
# - Adds the user to dialout
# - Builds the C++ demos
# Usage: ./tools/setup_g1_hand.sh
set -e
SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[1/4] Building WCH ch343 driver..."
cd "$SDK_DIR/tools/ch343ser_linux/driver"
make clean >/dev/null 2>&1 || true
make
sudo make install || sudo insmod ch343.ko

echo "[2/4] Switching adapter from cdc_acm to ch343..."
for d in /sys/bus/usb/drivers/cdc_acm/*:*; do
  [ -e "$d" ] && basename "$d" | sudo tee /sys/bus/usb/drivers/cdc_acm/unbind >/dev/null || true
done
sudo rmmod cdc_acm 2>/dev/null || true
echo "blacklist cdc_acm" | sudo tee /etc/modprobe.d/blacklist-cdc_acm.conf >/dev/null
sudo modprobe ch343 2>/dev/null || sudo insmod ch343.ko 2>/dev/null || true
sleep 2

echo "[3/4] Adding $USER to dialout..."
sudo usermod -aG dialout "$USER"

echo "[4/4] Building C++ demos..."
cd "$SDK_DIR/c/demo"
make clean >/dev/null
make

echo
ls -l /dev/ttyCH343USB* 2>/dev/null || echo "[WARN] No /dev/ttyCH343USB* yet - unplug/replug the hand adapter."
echo
echo "Done. Left:  sudo ./hand_demo.exe -m /dev/ttyCH343USB0 460800 126"
echo "      Right: sudo ./hand_demo.exe -m /dev/ttyCH343USB1 460800 127"
