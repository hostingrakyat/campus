# Mahasigma Simulator — Game Design (v0.1)

**Fantasi pemain:** jadi "mahasigma" — bertahan dari dosen yang menghilang, birokrasi kampus, UKT, dan kerja
part-time, lalu lulus dengan ending yang ditentukan cara kamu menyeimbangkan nilai, uang, dan kewarasan.

## Loop

```
Awal semester → UKT (bayar / banding / beasiswa / pinjol / cuti) → Isi KRS → War KRS
→ 12 minggu (rencana 4 slot: Pagi · Siang · Malam · Akhir Pekan → animasi → kartu cerita)
→ KHS (IPS, IPK, nilai per matkul) → cek ending → semester berikutnya
```

- **Minggu 6 & 12** = UTS/UAS (slot pagi terkunci "Ujian").
- **Kehadiran < 75%** → semua matkul E ("tidak boleh ikut UAS"). Kerja shift pagi = bentrok kuliah.
- **War KRS**: ketuk AMBIL secepatnya di SIAKAD yang lag (42% "503"). Dapat = Kelas A (dosen baik, +3),
  sisa = Kelas B (dosen killer, −4). Rewarded ad: "refresh SIAKAD" sekali.
- **Batas SKS** dari IPS lalu: ≥3.0 → 24, ≥2.5 → 21, ≥2.0 → 18, lainnya 15.

## Variasi mingguan

- **Kabar Minggu Ini** (acak tiap minggu, tidak pernah sama dua kali berturut): Tanggal Merah (tidak ada kuliah, kehadiran
  tetap dihitung), Musim Kuis Dadakan, Dosen Seminar ke Luar Negeri, Deadline Numpuk, Promo Kopi Warkop, Hujan Seminggu
  (ojol tarif hujan), Bonus dari Bos, Festival Kampus, Flu di Kos, Listrik Padam Bergilir, Seminar Gratis, Tanggal Tua.
- **Varian aktivitas** (47 total): setiap aktivitas punya beberapa kejadian acak dengan efek kecil berbeda — mis. Kuliah:
  ceramah 2 jam / kuis dadakan / dosen telat 45 menit / presentasi kelompok / diskusi seru / slide Comic Sans; Nongkrong:
  gorengan / ditraktir kating / curhat / main remi; Ojol: orderan biasa / dapat tip / ban bocor; dst.
- Rencana default ikut bervariasi menurut energi, mental, sosial, dan uang; tombol **Acak** untuk mengocok ulang.
- Data di `game/tools/gen_activities.py` → `data/activities.json`.

## Cutscene

- **Aktivitas** dimainkan sebagai montase 3D: panel rencana turun, layar fade ke set yang sesuai, karakter berpose dan
  beranimasi, NPC ikut tampil dan bicara (balon teks), caption menampilkan kejadian varian + perubahan stat.
  Tombol **Cepat** (diingat) dan **Lewati**.
- **Set**: kelas (dosen di papan tulis, kursi kuliah lipat), kamar kos (kasur, meja + laptop, kipas angin berputar, lemari),
  perpustakaan, sekretariat organisasi, kafe/toko 24 jam/apotek, ruang konseling, ruang dosen (pintu "SEDANG RAPAT" /
  "DINAS LUAR KOTA" saat ghosting), plus warkop, lapangan (jogging/futsal), jalan raya (ojol berboncengan).
- **Event** = cutscene: letterbox, NPC 3D (tiap NPC punya penampilan sendiri) berjalan menghampiri atau sudah duduk di
  tempatnya, dialog gaya visual novel (nama, avatar, teks diketik, ketuk untuk lanjut), pilihan, pemain mengucapkan pilihannya,
  reaksi (sorak + lompat / lesu + geleng kepala), lalu hasil + perubahan stat. Telepon ortu/pinjol: pemain di kos memegang HP.
- Karakter punya sendi bahu/pinggul: jalan dengan ayunan, duduk, berbaring, naik motor, mengetik, mencatat, membaca, menelepon,
  tertawa, bersorak, sedih, menunjuk, melambai, plus emote ("!", "?", "...", "z z z").

## Stat

| Stat | Fungsi |
|---|---|
| Energi 0–100 | Biaya aksi; regen +28/minggu. <15 = efisiensi ½ |
| Mental 0–100 | <30 efisiensi belajar 60%; <25 peringatan + saran konseling; 0 → ending Rawat/Padam |
| Sosial 0–100 | Nilai KKN, peluang event, ending Balance & Rawat; turun 2/minggu |
| Koin | Makan 120/minggu, kos 500/bulan, UKT, belanja; kiriman ortu tiap bulan |
| Ilmu & Tugas | Akumulasi per semester → nilai (target 20 & 15, diskalakan kesulitan matkul × prodi × beban SKS) |
| Relasi dosen | Mengurangi ghosting, menaikkan peluang banding/beasiswa/sidang |

Nilai matkul = 20% kehadiran + 42% ilmu + 38% tugas + bonus event/kelas ± acak 5 → A/AB/B/BC/C/D/E.

## Uang & kerja

- Semester 1–2: UKT dibayar ortu + kiriman bulanan. **Semester 3 atau 4: Ayah di-PHK** → UKT tanggung sendiri, kiriman 400.
- Opsi UKT: tabungan · banding (sukses → golongan terendah 25% bila PHK) · beasiswa (IPK ≥3.50, ≥3.00 bila PHK) ·
  pinjol (utang 150%, ditagih awal semester, bunga 10% kalau telat + debt collector) · cuti (maks 2, +4.200 koin, semester tidak bertambah) ·
  tukar diamond · rewarded "transfer dari Om".
- Part-time (1 kontrak, slot tetap, bolos 3× = dipecat): Barista (pagi, bentrok kuliah), Minimarket malam, Guru les (IPK ≥3.0),
  Admin olshop, Freelance web (IF), Jaga apotek (KD), Asisten dosen (IPK ≥3.25, +relasi). Ojol = gig bebas slot.
- Event kelas pengganti / lembur memaksa pilihan kerja vs kuliah.
- **Khilaf**: kosmetik dibeli pakai koin (bisa bikin UKT kurang), event flash sale tengah malam.

## Skripsi

Mulai semester 7 (≥100 SKS lulus). *Garap Skripsi* menambah draf; *Bimbingan* (siang) mengubah draf jadi ACC —
dospem acak: **Pak Haryo** (read doang, 45% ghost), **Dr. Ratna** (revisi abadi), **Prof. Bambang** (selalu dinas).
ACC 100% → sidang (peluang dari ilmu, relasi, sosial). Gagal = ACC −20.

## 10 Ending

| Ending | Syarat |
|---|---|
| Summa Cum Laude | IPK ≥3.90, ≤8 semester, tanpa mengulang |
| **Social Campus Balance** (ending sejati) | IPK ≥3.00, ≤9 semester, sosial ≥60, rata-rata mental ≥60 |
| Cum Laude | IPK ≥3.50, ≤8 semester |
| Lulus Tepat Waktu | ≤8 semester |
| Lulus Juga Akhirnya | semester 9–12 |
| Mahasiswa Abadi | lulus semester 13–14 (di semester 14 cukup skripsi selesai: "dikasihani") |
| Drop Out | UKT tak terbayar · IPS <1.00 dua kali berturut · gagal evaluasi semester 4 (IPK <2.00 / <48 SKS) · lewat semester 14 · ketahuan jual-beli nilai |
| Pindah Prodi | dipilih di KHS semester 1–4 → mulai ulang di prodi baru, koin terbawa |
| Rehat: Rawat Inap di RSJ | mental 0 dan sosial ≥35 (teman menolong) |
| Lampu Kamar yang Padam | mental 0 dan sosial <35 |

**Kebijakan tema sensitif:** ending Padam tidak menampilkan metode apa pun (tersirat: kamar gelap, kursi kosong di wisuda),
selalu didahului peringatan dalam game, menampilkan Healing119 (119 ext 8 / healing119.id), konseling kampus selalu gratis,
dan **tidak pernah dimonetisasi** (tidak ada revive berbayar/iklan untuk ending mental). Ada catatan konten saat pertama kali buka.
Kedua ending ini menaikkan rating konten — targetkan rating remaja/17+ (IARC), bukan "anak-anak".

## Prodi awal

| Prodi | UKT | Kiriman | Kesulitan | Khas |
|---|---|---|---|---|
| Informatika | 6.500 | 1.500 | 1.00 | Freelance web (gaji tinggi) |
| Manajemen | 5.500 | 1.500 | 0.92 | Presentasi, sosial |
| Kedokteran | 14.000 | 2.000 | 1.05 + blok 6 SKS sulit | Jaga apotek, hafalan |

## Karakter & dunia

- Karakter vinyl low-poly dibangun prosedural: kepala bulat glossy, mata titik, **tanpa mulut**, pipi merona.
  Rambut: pendek, poni, panjang, hijab, cepak, keriting. Kosmetik: almamater (warna prodi), flanel, batik, hoodie, varsity, snelli,
  topi bucket/baseball/peci/toga, kacamata, ransel/tote, aura sigma.
- Kampus: gedung kuliah bersama, rektorat & loket TU (pita antre), perpustakaan, Kos Bu Endang (jemuran, galon, motor matic),
  warkop terpal + gorengan, gerobak bakso, kafe/toko 24 jam, lapangan + tiang merah putih, spanduk "Selamat Datang Mahasiswa Baru",
  gapura & pos satpam, pohon mangga, kelapa, beringin. Siang/malam dengan lampu jalan.
- Siap diganti/ditambah aset Meshy: ganti mesh di `campus_world.gd` / `vinyl_character.gd` (pertahankan skala ±1 unit = 1 m,
  karakter ±1.9 m, decimate ≤10k tris per prop).

## Audio

- **Musik orisinal** (dibangkitkan `game/tools/gen_music.py`, tanpa sampel): angklung (bambu digoyang) + bonang (gong-chime)
  di tangga nada pentatonik di atas groove pop/lo-fi.
  - `kampus_pagi` — judul, buat karakter, gameplay siang (104 BPM, ceria)
  - `kampus_malam` — UKT, KRS, dan otomatis saat mental kritis (lo-fi 78 BPM, piano FM + crackle)
  - `sedih` — ending DO/Rawat/Padam (piano minor pelan, berakhir lebih hangat)
  - `lulus` — fanfare wisuda (brass + bonang + angklung), lalu kembali ke `kampus_pagi`
- **SFX** dari Kenney (CC0): klik tombol otomatis, buka/tutup modal, kartu event, koin & diamond, error/glitch SIAKAD "503",
  detik terakhir War KRS, langkah kaki karakter, fanfare unlock, dll.
- Bus terpisah Music/SFX, crossfade antar lagu, slider volume di Pengaturan (tersimpan), musik di-duck saat iklan.

## Animasi UI

Transisi layar (fade + bottom sheet naik), modal pop & tutup beranimasi, tombol squash-spring saat ditekan, daftar muncul bertahap,
angka koin/diamond menghitung, bar stat bergerak per slot saat minggu berjalan, pita "MINGGU N" & slot aktif, teks event
diketik, nilai KHS terbuka satu per satu + IPS menghitung, ending muncul bertahap + konfeti, karakter melompat saat ganti baju.

## Bahasa

4 mode: Indonesia + subtitle English (default), English + subtitle Indonesia, ID saja, EN saja.
Semua teks = pasangan id/en; istilah khas (UKT, KRS, SKS, dospem) dilokalisasi, bukan diterjemahkan literal.
