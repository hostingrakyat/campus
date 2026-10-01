# Monetisasi — dari mock ke produksi

Build sampel memakai **mock** supaya seluruh alur bisa dimainkan tanpa akun AdMob/Play Console:
`scripts/autoload/ads.gd` (overlay iklan palsu 2–3 detik) dan `scripts/autoload/iap.gd` (pembelian disimulasikan).
API publiknya sudah final; cukup ganti isinya.

## Mata uang

| | Sumber | Dipakai untuk |
|---|---|---|
| Koin (per run) | Kiriman ortu, gaji part-time, event, tukar diamond | UKT, makan/kos, kosmetik "khilaf", jajan |
| Diamond (permanen) | IAP, rewarded ad (+5, maks 8/hari) | Kosmetik premium, minuman energi, tukar 10💎 → 500 koin |

Kosmetik & diamond tersimpan di `Meta` (lintas run); koin hanya untuk run berjalan.

## Penempatan iklan

| Placement | Jenis | Kapan |
|---|---|---|
| `shop_diamonds` / tombol "+" diamond | Rewarded | Kapan saja, cap harian |
| `double_wages` | Rewarded | Setiap 3 minggu bila ada gaji |
| `ukt_om` | Rewarded | Sekali per semester di layar UKT |
| `krs_retry` | Rewarded | Sekali setelah War KRS bila ada Kelas B |
| `semester_end`, `week_N` | Interstitial | Transisi saja, cooldown 150 dtk, tidak di 3 menit pertama, hilang dengan "Hapus Iklan" |

Tidak ada iklan atau pembelian yang terkait ending kesehatan mental.

## Produk IAP (Google Play Billing)

`diamonds_60` Rp15.000 · `diamonds_250` Rp49.000 · `diamonds_600` Rp99.000 ·
`starter_maba` Rp9.000 (sekali: 100💎 + Hoodie Sigma Emas) · `no_ads` Rp29.000 (sekali).

## Langkah integrasi

1. **Gradle build**: Project → Install Android Build Template; di preset Android set `gradle_build/use_gradle_build=true`.
2. **AdMob**: pasang plugin *Poing Studios godot-admob-plugin* (Asset Library, v5.x untuk Godot 4.2+).
   - Isi App ID AdMob di pengaturan plugin (manifest).
   - Di `ads.gd`: inisialisasi `MobileAds` saat `_ready`, minta consent UMP (wajib untuk pengguna EEA/UK),
     pre-load `RewardedAd` dan `InterstitialAd` memakai unit ID kamu (ID tes Google sudah ada di konstanta).
   - Ganti `_show_mock(true, …)` dengan `rewarded.show(listener)`; panggil `on_done.call(true)` hanya di callback
     `on_user_earned_reward`. Ganti mock interstitial dengan `interstitial.show()`. Muat ulang iklan setelah ditutup.
   - Tambahkan `app-ads.txt` di domain developer.
3. **Billing**: pasang plugin resmi *GodotGooglePlayBilling*; buat produk dengan ID di atas di Play Console
   (`diamonds_*` = consumable, `starter_maba` & `no_ads` = non-consumable).
   - Di `iap.gd`: `startConnection` → `queryProductDetails` (tampilkan harga lokal dari Play, bukan string hard-code) →
     `purchase(id)` → saat `purchases_updated`, **acknowledge/consume** lalu panggil logika `buy()` yang ada untuk memberi item.
   - Restore non-consumable dengan `queryPurchases` saat start.
4. **Kebijakan Play**: rewarded selalu opsional & jelas imbalannya; rating konten via kuesioner IARC (tema kesehatan mental &
   satire → remaja/17+); jangan ikut program Designed for Families; isi Data Safety (AdMob mengumpulkan advertising ID).
5. **Testing**: akun penguji lisensi untuk Billing, ID iklan tes untuk AdMob; untuk akun developer personal baru Play
   mensyaratkan closed testing (≥12 penguji, 14 hari) sebelum produksi.
