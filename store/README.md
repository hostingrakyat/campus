# Materi submit Google Play: Mahasigma Simulator

Semua yang dibutuhkan untuk mengisi Play Console, siap unggah.

| File | Dipakai di Play Console |
|---|---|
| `graphics/icon-512.png` | Main store listing > App icon (512×512 PNG) |
| `graphics/feature-graphic-1024x500.png` | Main store listing > Feature graphic |
| `graphics/phone-screenshots/id-ID/*.png` | Phone screenshots, bahasa Indonesia (8 gambar 1080×1920, dengan judul promo) |
| `graphics/phone-screenshots/en-US/*.png` | Phone screenshots, English translation |
| `graphics/phone-screenshots-plain/` | Versi tanpa bingkai (cadangan / untuk media sosial) |
| `listing/id-ID.md`, `listing/en-US.md` | Nama aplikasi, deskripsi singkat & lengkap, catatan rilis |
| `play-console-forms.md` | Jawaban App content, Data safety, rating konten IARC, target audiens, produk IAP |
| `privacy-policy.html` | Unggah ke web lalu isi URL-nya di App content > Privacy policy |
| `app-ads.txt` | Taruh di root domain developer (`https://<domain>/app-ads.txt`) |

## Urutan submit (production)
1. Ganti `EMAIL_KONTAK` di `privacy-policy.html` dan `play-console-forms.md`, unggah kebijakan privasi ke web.
2. Isi ID AdMob Mahasigma di `game/project.godot` (lihat `docs/MONETIZATION.md`), lalu build:
   `powershell -ExecutionPolicy Bypass -File tools\build_android.ps1 -Godot <path Godot>`.
   Skrip menolak build kalau masih memakai ID tes.
3. Play Console > Create app > isi Setelan aplikasi, App content, Data safety, Content rating (dari `play-console-forms.md`).
4. Main store listing: tempel teks dari `listing/`, unggah grafis dari `graphics/`.
5. Production > Create release > unggah `build/MahasigmaSimulator-v<versi>.aab` > tempel catatan rilis.
   Aktifkan **Play App Signing** (keystore di `keystore/` = upload key).
6. Monetize > In-app products: buat 5 produk sesuai tabel di `play-console-forms.md`, aktifkan.
7. Akun developer **personal** yang dibuat setelah Nov 2023 wajib closed testing (≥12 penguji aktif selama 14 hari)
   sebelum tombol Production terbuka. Akun organisasi bisa langsung production.

## Membuat ulang grafis
Render dari game (jendela borderless boleh lebih besar dari monitor):
```powershell
$env:SHOT_SIZE="1080x1920"; $env:SHOT_LANG="2"   # 2 = Indonesia saja, 3 = English saja
godot --path game -- --shot=week --out=<raw>\id\week.png   # create week mg_kuliah explore event war khs ending_balance
$env:SHOT_SIZE="2048x1000"; godot --path game -- --shot=stage_olahraga --out=<raw>\feature_bg.png
python tools\make_store_graphics.py <raw>
```
Pakai `SHOT_FRAMES=420` untuk `khs` dan `ending_balance` (animasi angka/teks), `200` untuk `event`.
