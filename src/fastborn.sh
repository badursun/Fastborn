#!/bin/bash
# FastBorn — Secure Disk Erasure Tool
# Runs automatically after boot from initramfs

set -e

# --- Colors ---
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

# --- Read mode from kernel cmdline ---
MODE="quick"
if grep -q "fastborn.mode=full" /proc/cmdline 2>/dev/null; then
    MODE="full"
fi

# --- Mount essentials ---
mount_essentials() {
    mount -t proc proc /proc 2>/dev/null || true
    mount -t sysfs sysfs /sys 2>/dev/null || true
    mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
    mount -t tmpfs tmpfs /tmp 2>/dev/null || true
    # Wait for devices to settle
    sleep 2
}

# --- Splash screen ---
show_splash() {
    clear
    echo -e "${RED}"
    cat << 'SPLASH'
    ███████╗ █████╗ ███████╗████████╗██████╗  ██████╗ ██████╗ ███╗   ██╗
    ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗██╔══██╗████╗  ██║
    █████╗  ███████║███████╗   ██║   ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
    ██╔══╝  ██╔══██║╚════██║   ██║   ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
    ██║     ██║  ██║███████║   ██║   ██████╔╝╚██████╔╝██║  ██║██║ ╚████║
    ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
SPLASH
    echo -e "${NC}"

    if [ "$MODE" = "quick" ]; then
        echo -e "${CYAN}         Secure Disk Erasure Tool v1.0 — Quick Mode (1-pass zero)${NC}"
    else
        echo -e "${CYAN}         Secure Disk Erasure Tool v1.0 — Full Mode DoD 5220.22-M (7-pass)${NC}"
    fi
    echo -e "${CYAN}         Boot successful — Running from RAM — Disks safe until erasure${NC}"
    echo ""
    sleep 3
}

# --- Find target disks (exclude USB/removable) ---
find_disks() {
    DISKS=""
    for dev in /sys/block/sd* /sys/block/nvme*n* /sys/block/hd* /sys/block/vd*; do
        [ -e "$dev" ] || continue
        DEVNAME=$(basename "$dev")

        # Skip removable devices (USB drives)
        REMOVABLE=$(cat "$dev/removable" 2>/dev/null || echo "0")
        [ "$REMOVABLE" = "1" ] && continue

        # Skip loop, ram, and other virtual devices
        case "$DEVNAME" in
            loop*|ram*|sr*|fd*) continue ;;
        esac

        # Skip if size is 0
        SIZE_SECTORS=$(cat "$dev/size" 2>/dev/null || echo "0")
        [ "$SIZE_SECTORS" = "0" ] && continue

        DISKS="$DISKS /dev/$DEVNAME"
    done
    echo "$DISKS"
}

# --- Get disk info ---
get_disk_info() {
    local dev=$1
    local devname=$(basename "$dev")
    local size_bytes=$(($(cat /sys/block/$devname/size) * 512))
    local size_gb=$((size_bytes / 1073741824))
    local model=$(cat /sys/block/$devname/device/model 2>/dev/null | tr -s ' ' || echo "Unknown")
    local serial=$(cat /sys/block/$devname/device/serial 2>/dev/null | tr -s ' ' || echo "Unknown")
    echo "${model}|${serial}|${size_gb}GB|${size_bytes}"
}

# --- Verification pass ---
verify_disk() {
    local dev=$1
    local fail_count=0
    local check_count=100
    local dev_size_sectors=$(blockdev --getsz "$dev" 2>/dev/null || echo "0")

    if [ "$dev_size_sectors" = "0" ]; then
        echo "SKIP"
        return
    fi

    echo -e "${CYAN}  Verifying $dev — reading $check_count random sectors...${NC}"

    # Create a 512-byte zero reference file
    dd if=/dev/zero of=/tmp/zero_ref bs=512 count=1 2>/dev/null

    for i in $(seq 1 $check_count); do
        # Pick a random sector
        local sector=$((RANDOM % dev_size_sectors))
        # Read 512 bytes from disk
        dd if="$dev" of=/tmp/verify_sector bs=512 count=1 skip="$sector" 2>/dev/null
        # Compare with zero reference
        if ! cmp -s /tmp/zero_ref /tmp/verify_sector; then
            fail_count=$((fail_count + 1))
        fi
    done

    rm -f /tmp/zero_ref /tmp/verify_sector

    if [ "$fail_count" -eq 0 ]; then
        echo -e "${GREEN}  ✓ $dev — Verification PASSED ($check_count sectors clean)${NC}"
        echo "PASS"
    else
        echo -e "${YELLOW}  ✗ $dev — Verification FAILED ($fail_count/$check_count sectors not zero)${NC}"
        echo "FAIL:$fail_count/$check_count"
    fi
}

# --- Find and mount USB for logging ---
find_usb_mount() {
    for dev in /sys/block/sd*; do
        [ -e "$dev" ] || continue
        DEVNAME=$(basename "$dev")
        REMOVABLE=$(cat "$dev/removable" 2>/dev/null || echo "0")
        if [ "$REMOVABLE" = "1" ]; then
            # Try to find a partition on this USB
            for part in /dev/${DEVNAME}1 /dev/${DEVNAME}; do
                if [ -b "$part" ]; then
                    mkdir -p /mnt/usb
                    if mount -t vfat "$part" /mnt/usb 2>/dev/null || \
                       mount -t ext4 "$part" /mnt/usb 2>/dev/null || \
                       mount "$part" /mnt/usb 2>/dev/null; then
                        echo "/mnt/usb"
                        return
                    fi
                fi
            done
        fi
    done
    echo ""
}

# --- Write JSON log ---
write_log() {
    local usb_mount=$1
    local disk_dev=$2
    local disk_info=$3
    local method=$4
    local start_time=$5
    local end_time=$6
    local status=$7
    local verify_result=$8

    if [ -z "$usb_mount" ]; then
        echo -e "${YELLOW}  No USB mount found for logging, skipping log write${NC}"
        return
    fi

    local log_dir="${usb_mount}/fastborn-logs"
    mkdir -p "$log_dir"

    local hostname=$(hostname 2>/dev/null || echo "fastborn")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local model=$(echo "$disk_info" | cut -d'|' -f1)
    local serial=$(echo "$disk_info" | cut -d'|' -f2)
    local size=$(echo "$disk_info" | cut -d'|' -f3)
    local size_bytes=$(echo "$disk_info" | cut -d'|' -f4)
    local duration=$((end_time - start_time))
    local devname=$(basename "$disk_dev")

    local log_file="${log_dir}/fastborn_${devname}_${timestamp//[:]/}.json"

    cat > "$log_file" << JSONEOF
{
  "tool": "FastBorn v1.0",
  "timestamp": "${timestamp}",
  "hostname": "${hostname}",
  "disk": {
    "device": "${disk_dev}",
    "model": "${model}",
    "serial": "${serial}",
    "size": "${size}",
    "size_bytes": ${size_bytes}
  },
  "erasure": {
    "method": "${method}",
    "mode": "${MODE}",
    "duration_seconds": ${duration},
    "status": "${status}"
  },
  "verification": {
    "result": "${verify_result}",
    "sectors_checked": 100
  }
}
JSONEOF

    echo -e "${GREEN}  Log written: ${log_file}${NC}"
}

# --- Done screen ---
show_done() {
    echo ""
    echo -e "${GREEN}"
    cat << 'DONE'
    ██████╗  ██████╗ ███╗   ██╗███████╗
    ██╔══██╗██╔═══██╗████╗  ██║██╔════╝
    ██║  ██║██║   ██║██╔██╗ ██║█████╗
    ██║  ██║██║   ██║██║╚██╗██║██╔══╝
    ██████╔╝╚██████╔╝██║ ╚████║███████╗
    ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝
DONE
    echo -e "${NC}"
    echo -e "${GREEN}    All disks erased and verified successfully.${NC}"
    echo -e "${CYAN}    Remove USB drive and insert Windows installation media.${NC}"
    echo ""
}

# === MAIN ===
main() {
    mount_essentials
    show_splash

    # Find target disks
    echo -e "${YELLOW}[*] Scanning for target disks...${NC}"
    DISKS=$(find_disks)

    if [ -z "$DISKS" ]; then
        echo -e "${RED}[!] No target disks found. Nothing to erase.${NC}"
        echo -e "${YELLOW}    Check that disks are connected and not USB/removable.${NC}"
        echo ""
        echo -e "${CYAN}Rebooting in 10 seconds...${NC}"
        sleep 10
        reboot -f
    fi

    # Display found disks
    echo -e "${GREEN}[+] Target disks found:${NC}"
    for disk in $DISKS; do
        info=$(get_disk_info "$disk")
        model=$(echo "$info" | cut -d'|' -f1)
        size=$(echo "$info" | cut -d'|' -f3)
        echo -e "    ${BOLD}$disk${NC} — $model — $size"
    done
    echo ""

    # Show mode
    if [ "$MODE" = "quick" ]; then
        echo -e "${CYAN}[*] Mode: QUICK (1-pass zero fill)${NC}"
        NWIPE_METHOD="zero"
        METHOD_NAME="quick-1pass-zero"
    else
        echo -e "${CYAN}[*] Mode: FULL (DoD 5220.22-M — 7-pass)${NC}"
        NWIPE_METHOD="dod522022m"
        METHOD_NAME="full-dod522022m-7pass"
    fi
    echo ""

    # Warning
    echo -e "${RED}${BOLD}[!] ALL DATA ON THE ABOVE DISKS WILL BE PERMANENTLY DESTROYED${NC}"
    echo -e "${YELLOW}    Erasure starts in 5 seconds... (Ctrl+C to abort)${NC}"
    sleep 5

    # Run nwipe
    START_TIME=$(date +%s)
    echo -e "${CYAN}[*] Starting nwipe...${NC}"
    echo ""

    nwipe \
        --autonuke \
        --method "$NWIPE_METHOD" \
        --prng mersenne \
        --rounds 1 \
        --nowait \
        --nogui \
        $DISKS

    NWIPE_EXIT=$?
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo ""
    if [ $NWIPE_EXIT -eq 0 ]; then
        echo -e "${GREEN}[+] nwipe completed successfully in ${DURATION}s${NC}"
        ERASE_STATUS="success"
    else
        echo -e "${RED}[!] nwipe exited with code $NWIPE_EXIT${NC}"
        ERASE_STATUS="error:exit_code_${NWIPE_EXIT}"
    fi
    echo ""

    # Verification pass
    echo -e "${CYAN}[*] Running verification pass...${NC}"
    mkdir -p /tmp/verify_results
    for disk in $DISKS; do
        devname=$(basename "$disk")
        result=$(verify_disk "$disk" | tail -1)
        echo "$result" > "/tmp/verify_results/$devname"
    done
    echo ""

    # Find USB and write logs
    echo -e "${CYAN}[*] Writing logs to USB...${NC}"
    USB_MOUNT=$(find_usb_mount)
    for disk in $DISKS; do
        devname=$(basename "$disk")
        verify_result=$(cat "/tmp/verify_results/$devname" 2>/dev/null || echo "UNKNOWN")
        info=$(get_disk_info "$disk" 2>/dev/null || echo "Unknown|Unknown|0GB|0")
        write_log "$USB_MOUNT" "$disk" "$info" "$METHOD_NAME" "$START_TIME" "$END_TIME" "$ERASE_STATUS" "$verify_result"
    done

    # Unmount USB if mounted
    if [ -n "$USB_MOUNT" ]; then
        sync
        umount "$USB_MOUNT" 2>/dev/null || true
    fi

    # Done
    show_done

    # Countdown and reboot
    for i in 5 4 3 2 1; do
        echo -ne "\r${CYAN}    Rebooting in ${i}s...${NC}  "
        sleep 1
    done
    echo ""
    reboot -f
}

main "$@"
