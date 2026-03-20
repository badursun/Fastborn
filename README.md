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

> Zero-touch bootable USB disk silme aracı. USB tak, aç, bekle, bitti.

[![GitHub Release](https://img.shields.io/github/v/release/badursun/Fastborn)](https://github.com/badursun/Fastborn/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![ISO Size](https://img.shields.io/badge/ISO_Size-~20MB-blue)](#)

---

## Hızlı Başlangıç

### 1. ISO'yu İndir

**[fastborn.iso indir (v1.0)](https://github.com/badursun/Fastborn/releases/latest/download/fastborn.iso)** — ~20MB

### 2. USB'ye Yaz

| Platform | Komut / Araç |
|----------|-------------|
| **Windows** | [Rufus](https://rufus.ie) ile DD Image modunda yaz |
| **macOS** | `sudo dd if=fastborn.iso of=/dev/rdiskX bs=1m` |
| **Linux** | `sudo dd if=fastborn.iso of=/dev/sdX bs=1M` |

### 3. Kullan

```
USB tak → Makineyi aç → GRUB menüsü gelir (3sn) → Quick Erase otomatik başlar
→ Diskler silinir → Doğrulanır → Log USB'ye yazılır → Otomatik reboot
→ USB çek → Windows CD/USB tak → Kur
```

---

## Neden FastBorn?

Internet kafe, ofis, okul lab gibi ortamlarda **50+ makineyi hızla sıfırlamak** için tasarlandı. DBAN öldü (Blancco'ya satıldı), nwipe tek başına bootable değil. FastBorn ikisinin de iyisini yapıyor:

| Özellik | FastBorn | DBAN | nwipe |
|---------|:--------:|:----:|:-----:|
| Zero-touch (dokunma, çalışır) | :white_check_mark: | :x: | :x: |
| NVMe desteği | :white_check_mark: | :x: | :white_check_mark: |
| Quick mode (1-pass) | :white_check_mark: | :x: | :white_check_mark: |
| JSON silme raporu | :white_check_mark: | :x: | :x: |
| Verification (doğrulama) | :white_check_mark: | :x: | :x: |
| Auto-reboot | :white_check_mark: | :x: | :x: |
| Modern kernel | :white_check_mark: | :x: | ~ |
| Bootable ISO | :white_check_mark: | :white_check_mark: | :x: |

---

## Silme Modları

### Quick Mode (Default)
- **1-pass zero fill** — tüm sektörlere 0x00 yazar
- MBR dahil her şey silinir
- ~80GB disk icin **~15-20 dakika**
- Internet kafe senaryosu icin ideal

### Full Mode (DoD 5220.22-M)
- **7-pass** — 0x00 → 0xFF → Random → tekrar (x7)
- Askeri standart veri imhası
- ~80GB disk icin **~2+ saat**
- Hassas veri icin

GRUB menüsünde 3 saniye bekler. Hiçbir tuşa basmazsan **Quick mode** otomatik başlar.

---

## Özellikler

- **Paralel silme** — Birden fazla disk aynı anda silinir (NVMe dahil)
- **Verification pass** — Silme sonrası 100 rastgele sektör okunarak sıfırlandığı doğrulanır
- **JSON log** — Her disk için detaylı rapor USB'ye yazılır (`/fastborn-logs/`)
- **Auto-reboot** — İş bitince 5 saniye geri sayım, otomatik restart
- **BIOS + UEFI** — Her iki boot modunu destekler
- **~20MB ISO** — RAM'den çalışır, boot sırasında disklere dokunmaz
- **USB koruması** — Boot USB'si otomatik hariç tutulur (removable=1)

---

## JSON Log Örneği

Her silme işlemi sonrası USB'ye `/fastborn-logs/` altına otomatik yazılır:

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

## USB'ye Yazma (Detaylı)

### Windows (Rufus — Önerilen)

1. [rufus.ie](https://rufus.ie) adresinden Rufus'u indir (portable, kurulum gerektirmez)
2. USB flash drive'ı tak
3. Rufus'u çalıştır:
   - **Device:** USB drive'ını seç
   - **Boot selection:** "Disk or ISO image" → SELECT → `fastborn.iso` seç
   - **Partition scheme:** MBR
   - **Target system:** BIOS or UEFI
   - START'a bas
4. "Write in DD Image mode" uyarısı çıkarsa **DD Image** seç → OK

### Windows (balenaEtcher — Alternatif)

1. [etcher.balena.io](https://etcher.balena.io) adresinden Etcher'ı indir
2. "Flash from file" → `fastborn.iso` seç
3. "Select target" → USB drive seç
4. "Flash!" bas

### macOS

```bash
# USB disk numarasını bul
diskutil list

# USB'yi unmount et (X = disk numarası)
diskutil unmountDisk /dev/diskX

# ISO'yu yaz (rdisk = hızlı)
sudo dd if=fastborn.iso of=/dev/rdiskX bs=1m status=progress

# USB'yi çıkar
diskutil eject /dev/diskX
```

### Linux

```bash
# USB disk yolunu bul
lsblk

# ISO'yu yaz (X = disk harfi, örn: sdb)
sudo dd if=fastborn.iso of=/dev/sdX bs=1M status=progress conv=fsync
```

---

## Kaynaktan Build Etme

Docker Desktop kurulu olmalı.

```bash
git clone https://github.com/badursun/Fastborn.git
cd Fastborn
chmod +x build.sh
./build.sh
```

Çıktı: `output/fastborn.iso`

---

## Güvenlik Uyarıları

> **GERİ DÖNÜŞÜ YOKTUR** — FastBorn ile silinen veriler kurtarılamaz.

- USB boot diski otomatik olarak hariç tutulur (removable=1 tespiti)
- ISO RAM'den çalışır, boot sırasında hedef disklere dokunmaz
- Silme başlamadan önce 5 saniye bekleme süresi vardır (Ctrl+C ile iptal)
- Yanlış makineye takmayın — taktığınız anda o makinenin tüm diskleri silinir

---

## Lisans

MIT License — Detaylar için [LICENSE](LICENSE) dosyasına bakın.
