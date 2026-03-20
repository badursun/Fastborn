#!/bin/bash
# FastBorn ISO Builder — runs INSIDE Docker container
# Creates a bootable ISO with BIOS + UEFI support

set -e

echo "============================================"
echo " FastBorn ISO Builder"
echo "============================================"
echo ""

ISO_ROOT="/build/isoroot"
OUTPUT="/build/output/fastborn.iso"

# Clean previous build
rm -rf "$ISO_ROOT"
mkdir -p "$ISO_ROOT/boot/grub/x86_64-efi"
mkdir -p "$ISO_ROOT/boot/grub/i386-pc"
mkdir -p "$ISO_ROOT/EFI/BOOT"
mkdir -p /build/output

# --- Step 1: Copy kernel ---
echo "[1/6] Copying kernel..."
KERNEL=$(ls /boot/vmlinuz-* 2>/dev/null | head -1)
if [ -z "$KERNEL" ]; then
    echo "ERROR: No kernel found in /boot/"
    exit 1
fi
cp "$KERNEL" "$ISO_ROOT/boot/vmlinuz"
echo "  Kernel: $KERNEL"

# --- Step 2: Build initramfs with fastborn.sh ---
echo "[2/6] Building initramfs..."
INITRAMFS_DIR="/tmp/initramfs"
rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"/{bin,sbin,usr/bin,usr/sbin,usr/lib,lib,proc,sys,dev,tmp,mnt/usb,etc,run}

# Copy busybox and create symlinks
cp /bin/busybox "$INITRAMFS_DIR/bin/"
for cmd in sh ash cat echo ls mkdir mount umount sleep date hostname basename tr cut seq dd cmp rm reboot sync grep blockdev; do
    ln -sf busybox "$INITRAMFS_DIR/bin/$cmd"
done

# Copy bash
cp /bin/bash "$INITRAMFS_DIR/bin/" 2>/dev/null || true

# Copy nwipe
cp /usr/bin/nwipe "$INITRAMFS_DIR/usr/bin/" 2>/dev/null || \
cp /usr/sbin/nwipe "$INITRAMFS_DIR/usr/sbin/" 2>/dev/null || \
cp $(which nwipe) "$INITRAMFS_DIR/usr/bin/"
ln -sf /usr/bin/nwipe "$INITRAMFS_DIR/bin/nwipe" 2>/dev/null || true
ln -sf /usr/sbin/nwipe "$INITRAMFS_DIR/bin/nwipe" 2>/dev/null || true

# Copy required shared libraries
echo "  Copying shared libraries..."
for bin in "$INITRAMFS_DIR"/bin/bash "$INITRAMFS_DIR"/usr/bin/nwipe "$INITRAMFS_DIR"/usr/sbin/nwipe; do
    [ -f "$bin" ] || continue
    for lib in $(ldd "$bin" 2>/dev/null | grep -o '/[^ ]*'); do
        if [ -f "$lib" ]; then
            libdir="$INITRAMFS_DIR$(dirname $lib)"
            mkdir -p "$libdir"
            cp -n "$lib" "$libdir/" 2>/dev/null || true
        fi
    done
done

# Also copy ld-musl
for ld in /lib/ld-musl-*.so.1; do
    [ -f "$ld" ] && cp -n "$ld" "$INITRAMFS_DIR/lib/" 2>/dev/null || true
done

# Copy jq for potential JSON formatting
cp /usr/bin/jq "$INITRAMFS_DIR/usr/bin/" 2>/dev/null || true

# Copy fastborn.sh
cp /build/src/fastborn.sh "$INITRAMFS_DIR/fastborn.sh"
chmod +x "$INITRAMFS_DIR/fastborn.sh"

# Create init script
cat > "$INITRAMFS_DIR/init" << 'INITEOF'
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
exec /bin/bash /fastborn.sh
INITEOF
chmod +x "$INITRAMFS_DIR/init"

# Pack initramfs
echo "  Packing initramfs..."
(cd "$INITRAMFS_DIR" && find . | cpio -H newc -o 2>/dev/null | gzip -9) > "$ISO_ROOT/boot/initramfs"
echo "  Initramfs size: $(du -sh "$ISO_ROOT/boot/initramfs" | cut -f1)"

# --- Step 3: GRUB configs ---
echo "[3/6] Setting up GRUB..."
cp /build/src/grub.cfg "$ISO_ROOT/boot/grub/grub.cfg"
cp /build/src/grub-efi.cfg "$ISO_ROOT/EFI/BOOT/grub.cfg"

# --- Step 4: Create EFI boot image ---
echo "[4/6] Creating EFI boot image..."

# Build GRUB EFI binary
if [ -d /usr/lib/grub/x86_64-efi ]; then
    grub-mkimage \
        -O x86_64-efi \
        -o "$ISO_ROOT/EFI/BOOT/BOOTX64.EFI" \
        -p /EFI/BOOT \
        -c /build/src/grub-efi.cfg \
        part_gpt part_msdos fat iso9660 normal boot linux configfile loopback chain \
        search search_fs_uuid search_label ls cat echo test true
    echo "  UEFI: BOOTX64.EFI created"
else
    echo "  WARNING: x86_64-efi modules not found, skipping UEFI"
fi

# Create EFI FAT image for ISO embedding
EFI_IMG="$ISO_ROOT/boot/efi.img"
dd if=/dev/zero of="$EFI_IMG" bs=1M count=4 2>/dev/null
mkfs.fat -F 12 "$EFI_IMG" >/dev/null 2>&1
mmd -i "$EFI_IMG" ::/EFI
mmd -i "$EFI_IMG" ::/EFI/BOOT
if [ -f "$ISO_ROOT/EFI/BOOT/BOOTX64.EFI" ]; then
    mcopy -i "$EFI_IMG" "$ISO_ROOT/EFI/BOOT/BOOTX64.EFI" ::/EFI/BOOT/
    mcopy -i "$EFI_IMG" "$ISO_ROOT/EFI/BOOT/grub.cfg" ::/EFI/BOOT/
fi

# --- Step 5: Create BIOS boot image ---
echo "[5/6] Creating BIOS boot support..."
if [ -d /usr/lib/grub/i386-pc ]; then
    grub-mkimage \
        -O i386-pc \
        -o /tmp/core.img \
        -p /boot/grub \
        -c /build/src/grub.cfg \
        biosdisk iso9660 normal boot linux configfile loopback chain \
        search search_fs_uuid search_label ls cat echo test true part_msdos part_gpt

    cat /usr/lib/grub/i386-pc/cdboot.img /tmp/core.img > "$ISO_ROOT/boot/grub/i386-pc/eltorito.img"
    echo "  BIOS: eltorito.img created"
else
    echo "  WARNING: i386-pc modules not found, skipping BIOS"
fi

# --- Step 6: Build ISO ---
echo "[6/6] Building ISO..."

XORRISO_ARGS="-as mkisofs -R -J -joliet-long -V FASTBORN"

# Add BIOS boot if available
if [ -f "$ISO_ROOT/boot/grub/i386-pc/eltorito.img" ]; then
    XORRISO_ARGS="$XORRISO_ARGS -b boot/grub/i386-pc/eltorito.img -no-emul-boot -boot-load-size 4 -boot-info-table"
fi

# Add UEFI boot if available
if [ -f "$EFI_IMG" ]; then
    XORRISO_ARGS="$XORRISO_ARGS -eltorito-alt-boot -e boot/efi.img -no-emul-boot"
fi

XORRISO_ARGS="$XORRISO_ARGS -o $OUTPUT $ISO_ROOT"

xorriso $XORRISO_ARGS 2>/dev/null

echo ""
echo "============================================"
echo " BUILD COMPLETE"
echo "============================================"
echo ""
echo "  Output: /build/output/fastborn.iso"
echo "  Size:   $(du -sh $OUTPUT | cut -f1)"
echo "  MD5:    $(md5sum $OUTPUT | cut -d' ' -f1)"
echo ""
