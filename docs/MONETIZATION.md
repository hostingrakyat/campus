# Monetisasi: AdMob & Google Play Billing

Sejak v0.5.0 game memakai SDK asli, dengan fallback otomatis kalau belum aktif.

| | Asli | Fallback (kalau plugin/iklan/produk belum siap) |
|---|---|---|
| Iklan berhadiah | AdMob via plugin **Poing Studios godot-admob 5.1.0** | Iklan internal Mahasigma (hadiah tetap diberikan, maks 8/hari) |
| Interstitial | AdMob | Dilewati di build rilis; iklan internal hanya di build debug/desktop |
| IAP | **GodotGooglePlayBilling 3.3.0** (Billing Library 9.1) | Debug/desktop: disimulasikan. Rilis: ditolak dengan pesan (diamond tidak gratis) |

Kode: `scripts/autoload/ads.gd`, `scripts/autoload/iap.gd` (facade, API publik tetap),
`scripts/monetization/admob_backend.gd`, `scripts/monetization/play_billing_backend.gd` (hanya dimuat di Android saat singleton native ada).
Plugin: `game/addons/admob`, `game/addons/GodotGooglePlayBilling` (keduanya aktif di `project.godot`, wajib Gradle build).

## Yang harus kamu isi sebelum rilis

Semua ID di bawah saat ini memakai **ID tes Google** (iklan tes tampil, tidak menghasilkan uang).

1. **AdMob** (apps.admob.com): buat app Android `com.mahasigma.simulator`, buat 2 unit iklan (Rewarded, Interstitial).
   Isi di `game/project.godot` (atau Project Settings di editor):
   ```ini
   [admob]
   general/android/app_id="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"

   [mahasigma]
   ads/rewarded_unit="ca-app-pub-XXXXXXXXXXXXXXXX/1111111111"
   ads/interstitial_unit="ca-app-pub-XXXXXXXXXXXXXXXX/2222222222"
   ```
   Lalu: buat pesan GDPR di AdMob > Privacy & messaging (UMP; form consent otomatis muncul untuk EEA/UK, tombol
   "Privasi iklan" muncul di Pengaturan bila diwajibkan), dan pasang `app-ads.txt` di domain developer.
   **Jangan klik iklan asli sendiri**; untuk tes di HP sendiri tetap pakai ID tes atau daftarkan HP sebagai test device.
2. **Play Console > Monetize > Products > In-app products**, ID harus persis:

   | ID | Jenis | Harga acuan |
   |---|---|---|
   | `diamonds_60` | consumable | Rp15.000 |
   | `diamonds_250` | consumable | Rp49.000 |
   | `diamonds_600` | consumable | Rp99.000 |
   | `starter_maba` | sekali beli (100💎 + Hoodie Sigma Emas) | Rp9.000 |
   | `no_ads` | sekali beli | Rp29.000 |

   Harga yang tampil di game diambil dari Play (mata uang lokal); harga acuan hanya dipakai kalau Play belum menjawab.
   Produk baru bisa dibeli setelah AAB diunggah ke track mana pun (internal testing cukup) dan akun penguji
   ditambahkan di **License testing**.
3. Naikkan `version/code` di `game/export_presets.cfg` tiap upload, build dengan `tools/build_android.ps1`.

## Alur teknis

- **Iklan:** UMP consent → `MobileAds.initialize` (max rating T, bukan child-directed) → preload 1 rewarded + 1 interstitial,
  muat ulang setelah dipakai, retry dengan backoff (8 dtk … 3 menit) saat gagal/no fill. Hadiah hanya diberikan pada callback
  `on_user_earned_reward`; menutup lebih awal = tidak dapat hadiah. Kalau iklan gagal tampil, otomatis pindah ke iklan internal.
- **IAP:** connect → query produk + query pembelian (restore). Consumable diberikan setelah `consume` sukses; sekali-beli
  diberikan lalu `acknowledge` (Play me-refund pembelian yang tidak di-acknowledge dalam 3 hari). Tiap purchase token hanya
  diberikan sekali (disimpan di save meta). Status PENDING ditampilkan, item masuk saat pembayaran selesai.
  Tombol "Pulihkan pembelian" ada di tab Diamond.
- Verifikasi pembelian dilakukan di perangkat (tanpa server). Untuk skala besar, tambahkan verifikasi server via
  Google Play Developer API.

## Penempatan iklan

| Placement | Jenis | Kapan |
|---|---|---|
| `shop_diamonds` / tombol "+" diamond | Rewarded | Kapan saja, cap harian 8 |
| `double_wages` | Rewarded | Setiap 3 minggu bila ada gaji |
| `ukt_om` | Rewarded | Sekali per semester di layar UKT |
| `krs_retry` | Rewarded | Sekali setelah War KRS bila ada Kelas B |
| `semester_end`, `week_N` | Interstitial | Transisi saja, cooldown 150 dtk, tidak di 3 menit pertama, hilang dengan "Hapus Iklan" |

Tidak ada iklan atau pembelian yang terkait ending kesehatan mental.

## Kebijakan Play

Rewarded selalu opsional & jelas imbalannya; rating konten via kuesioner IARC (tema kesehatan mental & satire → remaja);
jangan ikut program Designed for Families; isi **Data Safety** (AdMob mengumpulkan advertising ID & data diagnostik,
Play Billing memproses pembayaran). Akun developer personal baru wajib closed testing (≥12 penguji, 14 hari) sebelum produksi.
