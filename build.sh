#!/bin/bash
# FastBorn Build Script — runs Docker to create bootable ISO
# Safe: everything happens inside Docker, nothing touches host disks

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "  ███████╗ █████╗ ███████╗████████╗██████╗  ██████╗ ██████╗ ███╗   ██╗"
echo "  ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗██╔══██╗████╗  ██║"
echo "  █████╗  ███████║███████╗   ██║   ██████╔╝██║   ██║██████╔╝██╔██╗ ██║"
echo "  ██╔══╝  ██╔══██║╚════██║   ██║   ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║"
echo "  ██║     ██║  ██║███████║   ██║   ██████╔╝╚██████╔╝██║  ██║██║ ╚████║"
echo "  ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝"
echo ""
echo "  Build System — Creating bootable ISO via Docker"
echo ""

# Ensure output directory exists
mkdir -p output

# Step 1: Build Docker image
echo "[1/3] Building Docker image..."
docker build -t fastborn-builder . --platform linux/amd64

# Step 2: Run builder container
echo ""
echo "[2/3] Running ISO builder inside Docker container..."
docker run --rm \
    --platform linux/amd64 \
    -v "$SCRIPT_DIR/output:/build/output" \
    fastborn-builder

# Step 3: Verify output
echo ""
if [ -f "output/fastborn.iso" ]; then
    echo "[3/3] ✅ ISO created successfully!"
    echo ""
    echo "  File: output/fastborn.iso"
    echo "  Size: $(du -sh output/fastborn.iso | cut -f1)"
    echo "  MD5:  $(md5 -q output/fastborn.iso)"
    echo ""
    echo "=========================================="
    echo " USB YAZMA TALİMATLARI (macOS)"
    echo "=========================================="
    echo ""
    echo "  # 1. USB diskini bul:"
    echo "  diskutil list"
    echo ""
    echo "  # 2. USB'yi unmount et (X = disk numarası):"
    echo "  diskutil unmountDisk /dev/diskX"
    echo ""
    echo "  # 3. ISO'yu USB'ye yaz:"
    echo "  sudo dd if=output/fastborn.iso of=/dev/rdiskX bs=1m status=progress"
    echo ""
    echo "  # 4. USB'yi çıkar:"
    echo "  diskutil eject /dev/diskX"
    echo ""
    echo "=========================================="
    echo " USB YAZMA TALİMATLARI (Windows)"
    echo "=========================================="
    echo ""
    echo "  Rufus (önerilen): rufus.ie"
    echo "  1. Rufus'u aç → Device: USB seç"
    echo "  2. Boot selection: fastborn.iso seç"
    echo "  3. Partition: MBR | Target: BIOS or UEFI"
    echo "  4. START → DD Image mode seç → OK"
    echo ""
    echo "  Alternatif: balenaEtcher (etcher.balena.io)"
    echo ""
else
    echo "[3/3] ❌ BUILD FAILED — ISO not found"
    exit 1
fi
