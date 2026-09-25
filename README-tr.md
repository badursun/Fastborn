<div align="center">

<a href="https://burakdursun.com/Fastborn/"><img src="docs/assets/og-image.png" alt="FastBorn — güvenli disk silme aracı" width="100%"></a>

### USB tak. Aç. Bekle. Bitti.

Makinedeki tüm dahili diskleri silen ve arkasında doğrulanmış bir rapor bırakan, dokunmadan çalışan boot edilebilir USB.<br>
İnternet kafeler, ofisler ve okul laboratuvarları için açık kaynak DBAN alternatifi.

[![GitHub Release](https://img.shields.io/github/v/release/badursun/Fastborn?color=22ff5e&labelColor=0b1a10)](https://github.com/badursun/Fastborn/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-22ff5e?labelColor=0b1a10)](LICENSE)
[![ISO size](https://img.shields.io/badge/ISO-~20%20MB-22ff5e?labelColor=0b1a10)](https://github.com/badursun/Fastborn/releases/latest)
[![BIOS + UEFI](https://img.shields.io/badge/boot-BIOS%20%2B%20UEFI-22ff5e?labelColor=0b1a10)](#özellikler)
[![Website](https://img.shields.io/badge/website-burakdursun.com%2FFastborn-ff2b44?labelColor=1a0b0d)](https://burakdursun.com/Fastborn/)

**[⬇ fastborn.iso indir (v1.0)](https://github.com/badursun/Fastborn/releases/latest/download/fastborn.iso)** &nbsp;·&nbsp; **[▶ Canlı demo](https://burakdursun.com/Fastborn/#lab)** &nbsp;·&nbsp; **[English](README.md)**

</div>

---

> [!CAUTION]
> **Geri dönüşü yoktur.** Bu USB ile açılan makinenin **tüm dahili diskleri silinir**; otomatik modda onay sorulmaz. Yanlış makineye takmayın. Boot USB'si otomatik olarak hariç tutulur (`removable=1`) ve silme başlamadan önce 5 saniyelik bir iptal süresi vardır (Ctrl+C).

## Hızlı başlangıç

| Adım | Ne yapılır |
|---|---|
| **1. İndir** | [`fastborn.iso`](https://github.com/badursun/Fastborn/releases/latest/download/fastborn.iso) — ~20 MB |
| **2. USB'ye yaz** | Windows: [Rufus](https://rufus.ie) ile **DD Image** modunda · macOS: `sudo dd if=fastborn.iso of=/dev/rdiskX bs=1m` · Linux: `sudo dd if=fastborn.iso of=/dev/sdX bs=1M` |
| **3. Aç** | USB'yi tak → makineyi aç → uzaklaş |

```
USB tak → Makineyi aç → GRUB menüsü (3sn) → Quick Erase otomatik başlar
→ Tüm diskler paralel silinir → Doğrulanır → JSON log USB'ye yazılır → Otomatik reboot
→ USB'yi çek → İşletim sistemi kurulum medyasını tak → Kur
```

<details>
<summary><b>İndirmeyi doğrula (SHA-256)</b></summary>

```
6f1380a91a61bec991f5e6787a75df8b62c86ed69685c9539fdd86d9bf6a29dc  fastborn.iso
```

```bash
shasum -a 256 fastborn.iso      # macOS
sha256sum fastborn.iso          # Linux
certutil -hashfile fastborn.iso SHA256   # Windows
```

</details>

## Nasıl çalıştığını gör

<div align="center">
<a href="https://burakdursun.com/Fastborn/#lab"><img src="docs/assets/wipe-demo.gif" alt="Simüle edilmiş DoD 7 geçişli silme: her sektör geçiş geçiş üzerine yazılıyor, sonra 100 rastgele sektör doğrulanıyor" width="100%"></a>
<br><sub>Tam mod (DoD 7 geçiş) silmenin simülasyonu. <a href="https://burakdursun.com/Fastborn/#lab">Etkileşimli silme laboratuvarında</a> kendin dene.</sub>
</div>

## Silme modları

GRUB menüsü **3 saniye** bekler. Hiçbir tuşa basmazsan Quick mod başlar; hassas veri için menüden Full'u seç.

| | **Quick** (varsayılan) | **Full** |
|---|---|---|
| Yöntem | 1 geçiş sıfır doldurma (`0x00`) | DoD 5220.22-M, nwipe ile 7 geçiş |
| Desen | `0x00` | `0x00 → 0xFF → RND → 0x00 → 0xFF → RND → RND` |
| Süre (80 GB) | ~15–20 dk | ~2+ saat |
| Uygun olduğu yer | İnternet kafe, ofis, laboratuvar — boot sektörü zararlılarını da temizler | Hassas veri barındırmış diskler |
| Log yöntemi | `quick-1pass-zero` | `full-dod522022m-7pass` |

## Özellikler

- **Dokunmadan çalışır** — tak, aç, hiçbir şeye dokunma
- **Paralel silme** — tüm dahili diskler aynı anda: SATA, HDD, SSD ve NVMe
- **Doğrulama** — silme sonrası her diskten 100 rastgele sektör geri okunur
- **JSON rapor** — her disk için USB'de `/fastborn-logs/` altına bir log
- **Otomatik reboot** — iş bitince 5 saniye geri sayım; USB'yi çek, işletim sistemini kur
- **BIOS + UEFI** — tek hibrit ISO, USB'den veya CD'den açılır
- **~20 MB, RAM'den çalışır** — boot sırasında hedef disklere dokunmaz
- **Boot USB koruması** — çıkarılabilir aygıtlar (`removable=1`) her zaman atlanır
- **Güncel çekirdek** — Linux 6.6 LTS

## Neden FastBorn?

DBAN, Blancco'ya satıldı ve çok eski bir çekirdekte kaldı; nwipe iyi ama tek başına boot edilemiyor. FastBorn, güncel bir çekirdekle nwipe'ı herkese verilebilecek bir USB'de birleştiriyor.

| Özellik | FastBorn | DBAN | nwipe |
|---|:---:|:---:|:---:|
| Dokunmadan çalışma | ✅ | ❌ | ❌ |
| NVMe desteği | ✅ | ❌ | ✅ |
| Quick mod (1 geçiş) | ✅ | ❌ | ✅ |
| JSON silme raporu | ✅ | ❌ | ❌ |
| Doğrulama | ✅ | ❌ | ❌ |
| Otomatik reboot | ✅ | ❌ | ❌ |
| Güncel çekirdek | ✅ 6.6 LTS | ❌ 2.6.x | ~ dağıtıma bağlı |
| Boot edilebilir ISO | ✅ | ✅ | ❌ ShredOS gerekir |
| Aktif geliştirme | ✅ | ❌ | ✅ |

## Silme raporu

USB'de `/fastborn-logs/` altına, her disk için ayrı dosya olarak otomatik yazılır:

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

## Yol haritası — V2

V2 geliştiriliyor; FastBorn'u hata anında güvenli duran bir yapı ve doğrulanabilir kanıtlar üzerine yeniden kuruyor:

- **Yerel sanitize komutları** — NVMe Format / Sanitize ve ATA Sanitize; HDD üzerine yazmada tam geri okuma
- **Donanım yeterliliği** — onaylı cihaz profillerinin birebir eşleşen, varsayılanı red olan kaydı
- **Paralel koordinatör** — özeti alınmış, dondurulmuş bir çalışma planıyla yönetilen, birbirinden yalıtılmış işçiler
- **İmzalı kanıt** — ayrık Ed25519 rapor imzaları ve NIST Appendix C ile uyumlu silme sertifikaları

> [!NOTE]
> V2 henüz **kullanıma hazır bir sürüm değil**. Bugün gerçek iş için v1.0'ı kullanın.

## USB'ye yazma (detaylı)

<details>
<summary><b>Windows — Rufus (önerilen)</b></summary>

1. [Rufus](https://rufus.ie)'u indir (portable, kurulum gerektirmez)
2. USB'yi tak
3. Rufus'ta:
   - **Device:** USB'n
   - **Boot selection:** "Disk or ISO image" → SELECT → `fastborn.iso`
   - **Partition scheme:** MBR
   - **Target system:** BIOS or UEFI
   - **START**'a bas
4. Sorulursa **DD Image** modunu seç → OK

</details>

<details>
<summary><b>Windows — balenaEtcher</b></summary>

1. [Etcher](https://etcher.balena.io)'ı indir
2. "Flash from file" → `fastborn.iso`
3. "Select target" → USB'n
4. "Flash!"

</details>

<details>
<summary><b>macOS</b></summary>

```bash
diskutil list                                   # USB disk numarasını bul
diskutil unmountDisk /dev/diskX                 # X = disk numarası
sudo dd if=fastborn.iso of=/dev/rdiskX bs=1m status=progress   # rdisk = daha hızlı
diskutil eject /dev/diskX
```

</details>

<details>
<summary><b>Linux</b></summary>

```bash
lsblk                                           # USB aygıtını bul
sudo dd if=fastborn.iso of=/dev/sdX bs=1M status=progress conv=fsync
```

</details>

## Kaynaktan derleme

Docker Desktop gerekir.

```bash
git clone https://github.com/badursun/Fastborn.git
cd Fastborn
chmod +x build.sh
./build.sh
```

Çıktı: `output/fastborn.iso`

## Lisans

MIT — detaylar için [LICENSE](LICENSE). Olduğu gibi, hiçbir garanti olmadan sunulur; kullanım sorumluluğu size aittir.

<div align="center"><sub><b>Diskler biter. Mahremiyet yaşar.</b> · <a href="https://burakdursun.com/Fastborn/">burakdursun.com/Fastborn</a></sub></div>
