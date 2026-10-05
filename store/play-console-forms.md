# Jawaban formulir Play Console: Mahasigma Simulator

Disesuaikan dengan kode v0.5.0 (AdMob + Play Billing, tanpa akun/server).

## Setelan aplikasi
| Kolom | Isi |
|---|---|
| Nama aplikasi | Mahasigma: Simulator Mahasiswa |
| Bahasa default | Indonesia (id-ID) · terjemahan: English (en-US) |
| Aplikasi atau game | Game |
| Gratis / berbayar | Gratis |
| Kategori | Simulasi |
| Tag (pilih s.d. 5) | Simulasi kehidupan, Kasual, Bergaya kartun/3D, Pemain tunggal, Offline |
| Email developer | EMAIL_KONTAK |
| Situs | https://hostingrakyat.co.id (opsional) |
| Kebijakan privasi (URL) | Unggah `store/privacy-policy.html`, mis. ke `https://hostingrakyat.co.id/mahasigma/privacy-policy.html` |

## Konten aplikasi (App content)
| Bagian | Jawaban |
|---|---|
| Kebijakan privasi | URL di atas |
| Iklan | **Ya, aplikasi berisi iklan** (AdMob: rewarded + interstitial) |
| Akses aplikasi | Semua fitur tersedia tanpa login / tanpa akses khusus |
| Target audiens | **16-17 dan 18+** (jangan centang di bawah 13; jangan ikut Designed for Families). 13-15 boleh ditambah, tapi iklan jadi wajib family-safe |
| Konten yang menarik minat anak? | Tidak |
| Aplikasi berita | Bukan |
| Pelacakan kontak/status COVID-19 | Bukan |
| Fitur keuangan | Tidak ada (pinjol di game adalah fiksi/satire, tidak ada layanan keuangan nyata) |
| Aplikasi kesehatan | Bukan aplikasi kesehatan |
| Aplikasi pemerintah | Bukan |
| ID iklan | **Ya, menggunakan advertising ID** (untuk iklan & analitik oleh AdMob) |

## Data safety (Keamanan data)
**Apakah aplikasi mengumpulkan atau membagikan data pengguna?** Ya (melalui SDK Google Mobile Ads).
**Semua data dienkripsi saat transit?** Ya. **Cara meminta penghapusan data?** Tidak ada akun; data game hanya di perangkat
(pilih "Tidak" untuk mekanisme penghapusan, karena tidak ada data yang kami simpan di server).

| Jenis data | Dikumpulkan | Dibagikan | Wajib/opsional | Tujuan |
|---|---|---|---|---|
| Lokasi > Perkiraan lokasi (dari IP) | Ya | Ya (Google AdMob) | Wajib | Iklan/pemasaran, Analitik, Pencegahan penipuan |
| ID perangkat atau ID lainnya (advertising ID) | Ya | Ya (Google AdMob) | Wajib | Iklan/pemasaran, Analitik, Pencegahan penipuan |
| Aktivitas aplikasi > Interaksi aplikasi (interaksi iklan) | Ya | Ya (Google AdMob) | Wajib | Iklan/pemasaran, Analitik |
| Info & performa aplikasi > Log error, Diagnostik | Ya | Ya (Google AdMob) | Wajib | Analitik, Pencegahan penipuan |
| Info keuangan > Riwayat pembelian | Tidak (diproses Google Play, tidak dikirim ke server kami) | - | - | - |
| Info pribadi, Pesan, Foto, Kontak, Lokasi persis | Tidak | - | - | - |

Data diproses sementara: tidak. Pengumpulan bersifat wajib selama iklan aktif (pengguna EEA/UK dapat menolak personalisasi lewat UMP).

## Rating konten (kuesioner IARC)
Kategori: **Game**. Jawab jujur sesuai isi game:

| Pertanyaan | Jawaban | Catatan |
|---|---|---|
| Kekerasan | Tidak | Tidak ada pertarungan/darah |
| Rasa takut / horor | Tidak | |
| Seksualitas / ketelanjangan | Tidak | |
| Bahasa kasar | Tidak | Hanya slang ringan ("gw", "bro") |
| Narkoba, alkohol, tembakau | Tidak | (cek ulang: tidak ada rokok/alkohol di game) |
| Perjudian (simulasi / uang asli) | Tidak | Tidak ada gacha/loot box; semua item dibeli langsung |
| Tema dewasa / kontroversial | **Ya** | Satir birokrasi; kesehatan mental termasuk ending rawat inap dan **rujukan bunuh diri yang tidak eksplisit** + catatan konten & info bantuan |
| Interaksi pengguna / chat | Tidak | |
| Berbagi lokasi | Tidak | |
| Pembelian digital | **Ya** | Diamond, kosmetik, hapus iklan |
| Konten buatan pengguna | Tidak | Hanya nama karakter lokal |

Perkiraan hasil: PEGI 12 / ESRB Teen / IARC 12+–16+ (karena tema kesehatan mental).

## Produk dalam aplikasi (Monetize > Products > In-app products)
| ID produk | Nama | Jenis | Harga |
|---|---|---|---|
| `diamonds_60` | Segenggam Diamond (60) | Consumable (beli berulang) | Rp15.000 |
| `diamonds_250` | Sekantong Diamond (250) | Consumable | Rp49.000 |
| `diamonds_600` | Sekoper Diamond (600) | Consumable | Rp99.000 |
| `starter_maba` | Paket Maba: 100 diamond + Hoodie Sigma Emas | Sekali beli | Rp9.000 |
| `no_ads` | Hapus Iklan Interstitial | Sekali beli | Rp29.000 |

Deskripsi produk (contoh): "60 diamond untuk kosmetik premium, minuman energi, atau ditukar koin." / "Menghapus iklan
interstitial selamanya. Iklan berhadiah tetap opsional."
Produk baru bisa diaktifkan setelah AAB pertama diunggah ke track mana pun.

## AdMob
- Hubungkan app AdMob ke listing Play setelah app terbit (AdMob > Apps > App settings > Add store).
- `store/app-ads.txt` ditaruh di root domain developer yang dicantumkan di listing: `https://hostingrakyat.co.id/app-ads.txt`.
- Isi pesan GDPR di AdMob > Privacy & messaging agar form persetujuan muncul untuk EEA/UK.
