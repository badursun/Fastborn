# FastBorn — Secure Disk Erasure Tool

Bootable USB ile çalışan, sıfır dokunuşlu (zero-touch) disk silme aracı. Internet kafe, ofis, okul lab gibi ortamlarda onlarca makineyi hızla sıfırlamak için tasarlandı.

## Özellikler

- **Zero-touch** — USB tak, makineyi aç, hiçbir tuşa basma. Otomatik çalışır
- **2 Mod** — Quick (1-pass zero, ~15-20dk) ve Full (DoD 7-pass, ~2+ saat)
- **Quick mode default** — 3 saniye GRUB menüsünde bekler, geçilmezse Quick başlar
- **Paralel silme** — Tüm diskler aynı anda silinir (NVMe dahil)
- **Verification** — Silme sonrası 100 rastgele sektör okunarak doğrulama
- **JSON log** — Sonuçlar USB'ye otomatik yazılır (kurumsal kanıt)
- **Auto-reboot** — Bitti, otomatik restart. Windows CD tak, kur
- **~80MB ISO** — RAM'den çalışır, hedef disklere boot sırasında dokunmaz
- **BIOS + UEFI** — Her iki boot modunu destekler

## Gereksinimler

- **Docker Desktop** (macOS, Linux veya Windows)
- USB flash drive (minimum 256MB)

## Build

```bash
git clone https://github.com/badursun/fastborn.git
cd fastborn
chmod +x build.sh
./build.sh
```

Build çıktısı: `output/fastborn.iso`

## USB'ye Yazma (macOS)

```bash
# USB diskini bul
diskutil list

# USB'yi unmount et (X = disk numarası)
diskutil unmountDisk /dev/diskX

# ISO'yu yaz
sudo dd if=output/fastborn.iso of=/dev/rdiskX bs=1m status=progress

# USB'yi çıkar
diskutil eject /dev/diskX
```

## USB'ye Yazma (Windows)

### Yöntem 1: Rufus (Önerilen)

1. [rufus.ie](https://rufus.ie) adresinden Rufus'u indir (portable, kurulum gerektirmez)
2. USB flash drive'ı tak
3. Rufus'u çalıştır:
   - **Device:** USB drive'ını seç
   - **Boot selection:** "Disk or ISO image" → SELECT → `fastborn.iso` seç
   - **Partition scheme:** MBR (BIOS uyumluluğu için)
   - **Target system:** BIOS or UEFI
   - **File system:** FAT32
   - START'a bas
4. "Write in DD Image mode" uyarısı çıkarsa **DD Image** seç → OK

### Yöntem 2: balenaEtcher

1. [etcher.balena.io](https://etcher.balena.io) adresinden Etcher'ı indir
2. "Flash from file" → `fastborn.iso` seç
3. "Select target" → USB drive seç
4. "Flash!" bas

### Yöntem 3: PowerShell (Komut Satırı)

```powershell
# 1. USB disk numarasını bul
Get-Disk | Where-Object BusType -eq 'USB'

# 2. USB'yi temizle (X = disk numarası)
# DİKKAT: Doğru diski seçtiğinden emin ol!
$disk = Get-Disk -Number X
$disk | Clear-Disk -RemoveData -Confirm:$false

# 3. ISO'yu yaz
$iso = "C:\path\to\fastborn.iso"
$usb = "\\.\PhysicalDriveX"
dd.exe if=$iso of=$usb bs=1M status=progress

# dd.exe yoksa Git Bash veya WSL üzerinden:
# dd if=/mnt/c/path/to/fastborn.iso of=/dev/sdX bs=1M status=progress
```

> **Not:** Windows'ta en kolay yöntem Rufus'tur. DD Image modunda yazınca birebir ISO kopyası oluşur.

## Kullanım

1. USB'yi makineye tak
2. Makineyi USB'den boot et (BIOS'ta boot order ayarla)
3. GRUB menüsü gelir:
   - **Quick Erase (default)** — 3 saniye bekler, otomatik başlar
   - **Full Erase** — Manuel seçim gerekir
4. Silme tamamlanır, doğrulama yapılır, log USB'ye yazılır
5. Makine otomatik reboot eder
6. USB'yi çek, Windows kurulum CD/USB'sini tak

## Silme Modları

### Quick Mode (1-pass zero)
- Tüm sektörlere 0x00 yazar
- MBR dahil
- ~80GB disk için ~15-20 dakika
- MBR virüs temizliği ve hızlı sıfırlama için yeterli

### Full Mode (DoD 5220.22-M — 7-pass)
- Pass 1: 0x00
- Pass 2: 0xFF
- Pass 3: Random
- Pass 4-7: Tekrar
- ~80GB disk için ~2+ saat
- Hassas veri imhası için

## Log Formatı

Her silme işlemi sonrası USB'ye `/fastborn-logs/` altına JSON dosyası yazılır:

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

## Güvenlik Uyarıları

- **GERİ DÖNÜŞÜ YOKTUR** — Silinen veriler kurtarılamaz
- USB boot diski otomatik olarak hariç tutulur (removable=1)
- ISO RAM'den çalışır, boot sırasında hedef disklere dokunmaz
- Silme başlamadan önce 5 saniye bekleme süresi vardır (Ctrl+C ile iptal)

## DBAN/nwipe ile Karşılaştırma

| Özellik | FastBorn | DBAN | nwipe |
|---------|----------|------|-------|
| Zero-touch | ✅ | ❌ (menü seçimi) | ❌ (CLI) |
| NVMe desteği | ✅ | ❌ | ✅ |
| Quick mode | ✅ | ❌ | ✅ |
| JSON log | ✅ | ❌ | ❌ |
| Verification | ✅ | ❌ | ❌ |
| Auto-reboot | ✅ | ❌ | ❌ |
| Modern kernel | ✅ | ❌ (2.6.x) | Dağıtıma bağlı |
| Bootable ISO | ✅ | ✅ | ❌ (ShredOS gerekli) |

## Lisans

MIT License — Detaylar için [LICENSE](LICENSE) dosyasına bakın.
