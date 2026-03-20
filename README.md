# FastBorn — Secure Disk Erasure Tool

```
    ███████╗ █████╗ ███████╗████████╗██████╗  ██████╗ ██████╗ ███╗   ██╗
    ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗██╔══██╗████╗  ██║
    █████╗  ███████║███████╗   ██║   ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
    ██╔══╝  ██╔══██║╚════██║   ██║   ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
    ██║     ██║  ██║███████║   ██║   ██████╔╝╚██████╔╝██║  ██║██║ ╚████║
    ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝

         Secure Disk Erasure Tool — Open Source DBAN Alternative
```

> Zero-touch bootable USB disk wipe tool. Plug, boot, wait, done.

English | **[Türkçe](README-tr.md)**

[![GitHub Release](https://img.shields.io/github/v/release/badursun/Fastborn)](https://github.com/badursun/Fastborn/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![ISO Size](https://img.shields.io/badge/ISO_Size-~20MB-blue)](#)
[![Website](https://img.shields.io/badge/Website-burakdursun.com/Fastborn-00ff41)](https://burakdursun.com/Fastborn/)

---

## Quick Start

### 1. Download ISO

**[Download fastborn.iso (v1.0)](https://github.com/badursun/Fastborn/releases/latest/download/fastborn.iso)** — ~20MB

### 2. Write to USB

| Platform | Command / Tool |
|----------|---------------|
| **Windows** | [Rufus](https://rufus.ie) — write in DD Image mode |
| **macOS** | `sudo dd if=fastborn.iso of=/dev/rdiskX bs=1m` |
| **Linux** | `sudo dd if=fastborn.iso of=/dev/sdX bs=1M` |

### 3. Use

```
Plug USB → Power on → GRUB menu appears (3s) → Quick Erase auto-starts
→ Disks wiped → Verified → Log written to USB → Auto reboot
→ Pull USB → Insert Windows/OS media → Install
```

---

## Why FastBorn?

Built for **bulk PC cleanup** in internet cafes, offices, and school labs. DBAN is dead (sold to Blancco), nwipe isn't bootable on its own. FastBorn does what both should:

| Feature | FastBorn | DBAN | nwipe |
|---------|:--------:|:----:|:-----:|
| Zero-touch (plug & run) | :white_check_mark: | :x: | :x: |
| NVMe support | :white_check_mark: | :x: | :white_check_mark: |
| Quick mode (1-pass) | :white_check_mark: | :x: | :white_check_mark: |
| JSON erasure report | :white_check_mark: | :x: | :x: |
| Verification | :white_check_mark: | :x: | :x: |
| Auto-reboot | :white_check_mark: | :x: | :x: |
| Modern kernel | :white_check_mark: | :x: | ~ |
| Bootable ISO | :white_check_mark: | :white_check_mark: | :x: |

---

## Erase Modes

### Quick Mode (Default)
- **1-pass zero fill** — writes 0x00 to all sectors
- Wipes everything including MBR
- **~15-20 minutes** for an 80GB disk
- Ideal for internet cafe scenarios

### Full Mode (DoD 5220.22-M)
- **7-pass** — 0x00 → 0xFF → Random → repeat (x7)
- Military-grade data destruction
- **~2+ hours** for an 80GB disk
- For sensitive data

GRUB menu waits 3 seconds. If no key is pressed, **Quick mode** starts automatically.

---

## Features

- **Parallel wipe** — All disks wiped simultaneously (NVMe included)
- **Verification pass** — Reads 100 random sectors post-wipe to confirm zeroed
- **JSON log** — Detailed report per disk written to USB (`/fastborn-logs/`)
- **Auto-reboot** — 5-second countdown after completion, automatic restart
- **BIOS + UEFI** — Supports both boot modes
- **~20MB ISO** — Runs from RAM, never touches target disks during boot
- **USB protection** — Boot USB is automatically excluded (removable=1)

---

## JSON Log Example

Automatically written to USB under `/fastborn-logs/` after each wipe:

```json
{
  "tool": "FastBorn v1.0",
  "timestamp": "2026-03-20T14:30:00Z",
  "hostname": "PC-042",
  "disk": {
    "device": "/dev/sda",
    "model": "WDC WD5000AAKX",
    "serial": "WD-ABC123",
    "size": "465GB",
    "size_bytes": 500107862016
  },
  "erasure": {
    "method": "quick-1pass-zero",
    "mode": "quick",
    "duration_seconds": 1024,
    "status": "success"
  },
  "verification": {
    "result": "PASS",
    "sectors_checked": 100
  }
}
```

---

## Writing to USB (Detailed)

### Windows (Rufus — Recommended)

1. Download [Rufus](https://rufus.ie) (portable, no install needed)
2. Plug in USB flash drive
3. In Rufus:
   - **Device:** Select your USB drive
   - **Boot selection:** "Disk or ISO image" → SELECT → choose `fastborn.iso`
   - **Partition scheme:** MBR
   - **Target system:** BIOS or UEFI
   - Click START
4. If prompted, select **DD Image** mode → OK

### Windows (balenaEtcher — Alternative)

1. Download [Etcher](https://etcher.balena.io)
2. "Flash from file" → select `fastborn.iso`
3. "Select target" → select USB drive
4. Click "Flash!"

### macOS

```bash
# Find your USB disk number
diskutil list

# Unmount the USB (X = disk number)
diskutil unmountDisk /dev/diskX

# Write ISO (rdisk = faster)
sudo dd if=fastborn.iso of=/dev/rdiskX bs=1m status=progress

# Eject
diskutil eject /dev/diskX
```

### Linux

```bash
# Find your USB device
lsblk

# Write ISO (X = device letter, e.g. sdb)
sudo dd if=fastborn.iso of=/dev/sdX bs=1M status=progress conv=fsync
```

---

## Build from Source

Requires Docker Desktop.

```bash
git clone https://github.com/badursun/Fastborn.git
cd Fastborn
chmod +x build.sh
./build.sh
```

Output: `output/fastborn.iso`

---

## Security Warning

> **THIS IS IRREVERSIBLE** — Data erased with FastBorn cannot be recovered.

- USB boot drive is automatically excluded (removable=1 detection)
- ISO runs from RAM, never touches target disks during boot
- 5-second delay before erasure begins (Ctrl+C to abort)
- Do not plug into the wrong machine — all internal disks will be wiped on boot

---

## License

MIT License — See [LICENSE](LICENSE) for details.
