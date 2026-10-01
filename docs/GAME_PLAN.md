# Campus — Game Plan (v0.1)

> Simulasi keseharian mahasiswa Indonesia: dosen yang menghilang, birokrasi berlapis, server KRS yang selalu down.
> Target: Android · Bahasa Indonesia + English (dual subtitle) · Free-to-play dengan Shop (IAP) + AdMob.

---

## 1. Riset: Keluhan Nyata Mahasiswa (bahan konten game)

Rangkuman dari berita, opini mahasiswa, dan diskusi online (sumber di bagian bawah).

| # | Keluhan | Potensi di game |
|---|---------|-----------------|
| 1 | **Dospem ghosting**: chat cuma di-read, janji bimbingan dibatalkan sepihak, susah ditemui | Boss "Kejar Dospem", mekanik *Read Receipt* |
| 2 | **Revisi tanpa ujung**: revisi bolak-balik, kadang balik ke versi pertama | Puzzle "Revisi Hell" |
| 3 | **Mahasiswa takut lapor**: takut nilai dijelekkan kalau protes | Meter *Takut vs Berani*, pilihan event berisiko |
| 4 | **SIAKAD/KRS error**: down saat war KRS, loading lama, banyak bug | Minigame "War KRS" |
| 5 | **Portal dikunci kalau telat bayar UKT**; banding UKT ribet & dipersulit | Minigame "Banding UKT" (kumpulkan berkas) |
| 6 | **UKT naik mendadak** dan memicu demo | Event musiman "Demo UKT" |
| 7 | **Dosen wajib beli buku karangannya** (bahkan jadi syarat remedial) | Event pilihan: beli buku vs risiko nilai |
| 8 | **Dosen telat / batal mendadak**, tapi mahasiswa telat 1 menit diusir | Event harian, stat *Kesabaran* |
| 9 | **Jual-beli nilai / pungli** | Jalur "gelap" dengan risiko ketahuan (DO) |
| 10 | **Joki skripsi dinormalisasi** | Item shop satir "Jasa Joki" yang selalu berakhir buruk |
| 11 | **Birokrasi TU**: tanda tangan, cap basah, legalisir, "besok aja ya", jam istirahat panjang | Minigame "Antri TTD", "Surat Bolak-Balik" |
| 12 | **Kerja kelompok**: anggota "ghaib" numpang nama | NPC "Teman Beban" |

Catatan desain: humornya harus *relatable*, bukan menyerang institusi/orang nyata. Semua kampus, dosen, dan staf **fiktif**. Hindari nama, logo, atau almamater kampus asli (risiko UU ITE dan pelanggaran kebijakan Google Play).

---

## 2. Engine & Tooling: Apa yang Bisa Dipakai di Environment Ini

Hasil cek container cloud:

| Item | Status |
|------|--------|
| Godot 4.x (binary Linux/headless) | ✅ bisa di-download (GitHub release reachable) |
| Godot MCP server (`@coding-solo/godot-mcp`, dll.) | ✅ tersedia di npm; Node 22 terpasang |
| Unity Editor | ❌ tidak bisa jalan di sini (butuh GUI + lisensi). Unity punya MCP resmi (`com.unity.ai.assistant`), tapi hanya berguna di mesin lokal |
| Java + Gradle | ✅ terpasang (dibutuhkan untuk export Android) |
| Android SDK | ⚠️ belum ada, perlu di-install (cmdline-tools) |
| Blender | ❌ tidak terpasang (bisa di-install kalau perlu konversi/decimate model) |
| MCP game engine di connector registry claude.ai | ❌ tidak ada; MCP engine harus dipasang manual sebagai MCP lokal |

### Rekomendasi: **Godot 4 (GDScript)**

- **Bisa dibangun, dites, dan di-export APK langsung dari environment ini** → paling cocok untuk workflow bareng Claude.
- MIT license, tanpa royalti, APK kecil (penting untuk HP entry-level di Indonesia).
- AdMob: plugin **Poing Studios godot-admob-plugin** (v5.0.0, Juli 2026) mendukung rewarded, interstitial, banner, dan UMP consent.
- IAP: plugin resmi **GodotGooglePlayBilling**.
- MCP: Godot MCP (jalankan project, baca debug output, edit scene) bisa dipasang di mesin lokal kamu untuk iterasi visual.

**Kapan pilih Unity?** Kalau kamu mau mengandalkan Asset Store (paling banyak aset gratis/murah) dan mau kerja utamanya di laptop sendiri. Kekurangannya: Claude di cloud tidak bisa build/test Unity, APK lebih besar.

### Aset Gratis (CC0 / bebas komersial) yang cocok untuk Godot

- **Kenney.nl**: UI pack, ikon, karakter, furniture, suara UI (CC0)
- **KayKit (Kay Lousberg)**: low-poly karakter, kota, dungeon (CC0)
- **Quaternius**: karakter ber-animasi, kota, props (CC0)
- **Poly Pizza**: kumpulan model low-poly (cek lisensi per model)
- **Mixamo**: animasi karakter gratis (rig dulu)
- **Meshy**: untuk aset khas Indonesia (motor matic, gerobak gorengan, warkop, kos-kosan, jas almamater). Wajib *decimate* ke ≤ 5–10k tris per prop agar ringan di mobile.

**Art direction yang disarankan:** low-poly 3D dengan kamera isometrik tetap (gaya KayKit). Cocok dengan aset CC0 + Meshy, ringan, dan bagus untuk klip TikTok.

---

## 3. Konsep Game

**Genre:** Life-sim + kartu pilihan ala *Reigns* + minigame satir.
**Fantasi pemain:** "Bertahan hidup dan lulus tepat waktu dari kampus paling birokratis se-Indonesia."
**Durasi target:** 8 semester ≈ 6–10 jam. *Bad ending* jadi Mahasiswa Abadi (Semester 14) atau DO.

### Core Loop (1 hari in-game ≈ 3–5 menit)

```
Pagi    → Kuliah (absen, dosen datang/tidak, event kartu)
Siang   → Urusan birokrasi / bimbingan / kerja part-time / organisasi
Malam   → Tugas (SKS: Sistem Kebut Semalam), nongkrong, istirahat
Akhir hari → Ringkasan stat, reward, [iklan interstitial opsional]
```

### Stat Utama

| Stat | Fungsi |
|------|--------|
| IPK | Syarat lulus & beasiswa |
| Energi | Dipakai untuk aksi; pulih dengan tidur/kopi |
| Kewarasan | Kalau 0 → event "burnout" |
| Uang (Coins) | Makan, kos, bensin, fotokopi |
| Relasi | Teman, dosen, staf TU ("orang dalam") |
| Progres Skripsi | Gate untuk ending |

### Karakter (semua fiktif)

| NPC | Ciri khas |
|-----|-----------|
| Pak Dosen "Read Doang" | Membaca WA dalam 2 detik, membalas 2 minggu kemudian |
| Bu Revisi Abadi | Tiap bimbingan revisinya berubah, kadang balik ke draf awal |
| Prof. Dinas Luar | Selalu "sedang di luar kota/luar negeri" |
| Dosen Penulis Buku | Bukunya wajib dibeli, edisi baru tiap semester |
| Dosen Killer Tepat Waktu | Kamu telat 1 menit diusir; dia telat 40 menit itu "wajar" |
| Pak TU "Besok Aja" | Loket buka 09.00–09.15, istirahat 11.00–13.30 |
| Admin SIAKAD | Server down tiap war KRS |
| Teman Kelompok Ghaib | Hanya muncul pas presentasi |
| Si Ambis | Rival IPK, selalu duduk paling depan |

### Minigame (MVP pilih 3 dulu)

1. **War KRS**: tap cepat + timing melawan server lag dan pop-up error (MVP)
2. **Kejar Dospem**: stealth/runner di gedung fakultas, cegat dosen sebelum kabur ke parkiran (MVP)
3. **Antri TTD**: manajemen antrean + kumpulkan berkas (fotokopi KTP, cap basah, materai) (MVP)
4. **Revisi Hell**: puzzle drag-drop bab skripsi sesuai mood dosen
5. **Banding UKT**: kumpulkan dokumen di peta kota sebelum deadline
6. **Absen Titip**: risk/reward, ketahuan = nilai E

---

## 4. Ekonomi & Monetisasi

### Mata Uang

| Currency | Sumber | Dipakai untuk |
|----------|--------|---------------|
| **Coins** (soft) | Gameplay, kerja part-time, quest harian | Makanan, kopi, fotokopi, upgrade kos, kosmetik dasar |
| **Diamonds** (hard) | IAP, **rewarded ads (cap harian)**, achievement, Semester Pass | Kosmetik premium, skip waktu, revive dari burnout, karakter premium |

### Rewarded Ads → Diamonds (AdMob)

- Tombol "Nonton iklan +5 💎", **cap 5–8×/hari** dengan cooldown, supaya IAP tetap bernilai.
- Penempatan natural: *double reward* di akhir hari, *revive* saat burnout, *retry* minigame, *skip* antrean TU (satir: "Bayar pakai iklan, bukan pungli").
- Interstitial: hanya di transisi hari/semester, frekuensi maksimal 1 per 3 menit, **tidak** muncul di sesi pertama.
- Banner: hanya di menu, tidak saat gameplay.
- Pakai **UMP consent** (dari plugin) dan mediation/bidding untuk menaikkan eCPM.

> ⚠️ Realita: eCPM Indonesia rendah (sekitar $1–4 untuk rewarded). Iklan saja tidak cukup; IAP murah dan Semester Pass penting.

### Shop (Google Play Billing)

| Produk | Harga (perkiraan) |
|--------|-------------------|
| Diamonds kecil / sedang / besar | Rp 5rb / 15rb / 49rb / 99rb |
| **Hapus iklan interstitial** (rewarded tetap opsional) | Rp 29rb |
| **Semester Pass** (battle pass bulanan: kosmetik + diamonds harian) | Rp 25rb |
| Starter Pack "Maba" (sekali beli, diskon besar) | Rp 9rb |
| Kosmetik: jaket almamater fiktif, motor, dekorasi kos, stiker WA | via Diamonds |

Google Play mendukung pembayaran via pulsa/GoPay/DANA/OVO, ini penting untuk pasar Indonesia.
Item satir seperti "Jasa Joki" boleh ada sebagai lelucon tapi **bukan pay-to-win**, dan selalu ada konsekuensinya di cerita.

---

## 5. Bahasa: Dual Subtitle ID + EN

- Mode bahasa: **ID saja**, **EN saja**, atau **Dual** (ID di atas, EN di bawah dengan ukuran lebih kecil). Mode Dual juga cocok untuk konten sosial media internasional.
- Implementasi: Godot `TranslationServer` + CSV/PO, key-based (`EVT_DOSPEM_GHOST_01`).
- **Lokalisasi, bukan terjemahan literal.** Istilah khas (UKT, KRS, Dospem, SKS, cap basah) punya glosarium + tooltip di versi EN.
- Font harus mendukung karakter Latin + emoji; teks dialog dirancang muat 2 baris × 2 bahasa.

---

## 6. Roadmap

| Fase | Isi | Estimasi |
|------|-----|----------|
| 0. Setup | Project Godot, struktur folder, CI export APK, Android SDK, localization pipeline | 1 minggu |
| 1. Vertical slice | 1 hari loop penuh, 3 NPC dosen, 1 minigame (War KRS), 30 kartu event, dual subtitle | 3–4 minggu |
| 2. MVP / Closed test | Semester 1–2, 3 minigame, Coins/Diamonds, rewarded ads, shop dasar, save lokal | +4 minggu |
| 3. Soft launch | Play Store closed testing (wajib 12+ tester selama 14 hari untuk akun dev personal baru), analytics, balancing | +3 minggu |
| 4. Full launch | 8 semester, ending, Semester Pass, event musiman (Demo UKT, KKN, Wisuda) | +6–8 minggu |

### Kebijakan Google Play yang perlu diperhatikan

- Rating konten: target **Teen/17+**; jangan desain untuk anak-anak (Families policy membatasi iklan).
- Rewarded ads harus opsional dan jelas imbalannya.
- Semua pembelian digital via Google Play Billing.
- Satir aman selama tidak menyebut institusi/orang asli.

---

## 7. Ide Judul (untuk hook video sosial media)

| # | Bahasa Indonesia | English | Hook video |
|---|------------------|---------|------------|
| 1 | **Mahasiswa Simulator Indonesia (MSI)** | Indonesian Student Simulator | "Kalau BUSSID simulasi supir bus, ini simulasi penderitaan mahasiswa." |
| 2 | **Dospem Ghosting** | Ghosted by My Advisor | "Chat di-read 3 detik lalu… hilang 3 bulan." |
| 3 | **Revisi Lagi?!** | Revise It. Again. | "Revisi ke-27: balik ke draf pertama." |
| 4 | **Semester 14** | Semester 14 | "Game ini cuma punya satu tujuan: jangan sampai semester 14." |
| 5 | **UKT: Uang Kuliah Tega** | Tuition of Pain | "UKT naik, portal dikunci, kamu cuma bisa main game ini." |
| 6 | **War KRS** | Course Registration Royale | "Server down jam 00.01. Siapa cepat dia… tetap error." |
| 7 | **Antri TTD** | Waiting for Signature | "Butuh 1 tanda tangan. Butuh 7 hari. Butuh 3 cap basah." |
| 8 | **Read Doang** | Left on Read: Campus Edition | "Boss terakhirnya bukan naga, tapi dosen yang cuma nge-read." |
| 9 | **Kampus Bobrok Simulator** | Broken Campus Simulator | "Simulasi kampus paling realistis: semuanya rusak." |
| 10 | **Mahasiswa Abadi** | The Eternal Student | "Ending terburuk: kamu jadi legenda kampus. Bukan karena prestasi." |
| 11 | **Lulus Kapan?** | When Do I Graduate? | "Pertanyaan yang lebih ditakuti dari 'kapan nikah'." |
| 12 | **SKS: Sistem Kebut Semalam** | All-Nighter Academy | "Deadline jam 8 pagi. Sekarang jam 3. Gas." |
| 13 | **Dosen Sedang Dinas** | Professor Out of Office | "Dosennya ke luar negeri. Kamu ke luar akal." |
| 14 | **Pejuang Toga** | Gown Warrior | "Kamu kira skripsi susah? Coba urus legalisir." |
| 15 | **Bimbingan Kapan, Pak?** | Sir, When's Our Meeting? | "'Besok ya' — kata dosen, 6 minggu lalu." |

**Rekomendasi top 3:**
1. **Mahasiswa Simulator Indonesia**: kata kunci "Simulator Indonesia" sangat kuat di Play Store ID (efek BUSSID) dan bagus untuk ASO.
2. **Dospem Ghosting**: paling *relatable* dan paling mudah viral di TikTok/Reels.
3. **Semester 14**: singkat, misterius, gampang diingat lintas bahasa.

Bisa juga dikombinasikan: **"Dospem Ghosting: Mahasiswa Simulator Indonesia"** (brand + kata kunci ASO).

---

## Sumber Riset

- [Fenomena Ghosting Akademik, Masalah Struktural di Perguruan Tinggi (Suara USU)](https://suarausu.or.id/fenomena-ghosting-akademik-masalah-struktural-di-perguruan-tinggi/)
- [Fenomena Skripsi "Ghosting" (Viva)](https://padang.viva.co.id/ragam-perkara/5534-fenomena-skripsi-ghosting-mengapa-mahasiswa-menghilang-dari-dosen-pembimbing)
- [Mahasiswa ITB hingga UGM yang depresi dan diabaikan dosen saat skripsi (Mojok)](https://mojok.co/liputan/kampus/jasa-bimbingan-buat-mahasiswa-itb-hingga-ugm-selamat-dari-depresi-akibat-skripsi/)
- [Normalisasi Joki Skripsi (Mojok)](https://mojok.co/terminal/joki-skripsi-adalah-bukti-kampus-tidak-becus/)
- [Keluhan Mahasiswa Unair Hadapi Peliknya Banding UKT (Retorika)](https://www.retorika.id/info-kampus_2025-12-24_%E2%80%9Chidup-sudah-susah-malah-dipersusah%E2%80%9D-keluhan-mahasiswa-unair-hadapi-peliknya-banding-ukt.html)
- [Dosen Pembimbing: Antara Ghosting, Revisi, dan Momen Ingin Hilang Saja](https://alifiarga.wordpress.com/2025/04/07/dosen-pembimbing-antara-ghosting-revisi-dan-momen-ingin-hilang-saja/)
- [SIAKAD Error karena Over Kapasitas (Sevima)](https://sevima.com/siakad-error-karena-over-kapasitas-ini-solusinya-untuk-kampus/)
- [Dosen Ngewajibin Mahasiswa Beli Bukunya (Mojok)](https://mojok.co/terminal/dosen-ngewajibin-mahasiswa-beli-bukunya-itu-sebenernya-pantes-nggak-sih/amp/)
- [Maha Benar Dosen dengan Segala Ketelatannya (Mojok)](https://mojok.co/terminal/maha-benar-dosen-dengan-segala-ketelatannya/amp/)
- [Kasus Dosen Unima Pungli Jual Beli Nilai (Detik)](https://www.detik.com/sulsel/berita/d-6718836/kasus-dosen-unima-pungli-jual-beli-nilai-kelulusan-mahasiswa-bakal-dianulir)
- [Polemik UKT Mahal (Pajak.com)](https://www.pajak.com/ekonomi/polemik-ukt-mahal-asal-muasal-dan-respons-pemerintah/)
- [Tuition fee hikes spark student protests (Indoleft)](https://www.indoleft.org/news/2024-05-10/tuition-fee-hikes-spark-wave-of-student-protest-around-the-country.html)
- [Unity MCP vs Unreal/Godot/Blender 2026 (StraySpark)](https://www.strayspark.studio/blog/unity-mcp-server-vs-unreal-godot-blender-2026)
- [What Is Godot MCP? (Summer Engine)](https://www.summerengine.com/blog/what-is-godot-mcp)
- [Godot AdMob plugin (Godot Asset Library)](https://www.godotengine.org/asset-library/asset/2063)
- [How to Use AdMob for Game Monetization in 2026 (Segwise)](https://segwise.ai/blog/google-ads-game-monetization.md)
- [Mobile Ad Networks Ranked with Real eCPMs 2026 (AppDrift)](https://appdrift.co/blog/12-top-mobile-ad-networks)
