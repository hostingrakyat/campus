"""Generates data/events.json. Edit the story here, then run: python3 tools/gen_events.py"""
import json, os

def T(i, e): return {"id": i, "en": e}
def C(li, le, fx=None, ri="", re="", **kw):
    c = {"label": T(li, le), "fx": fx or {}, "result": T(ri, re)}
    if "fri" in kw: c["fail_result"] = T(kw.pop("fri"), kw.pop("fre"))
    c.update(kw)
    return c
EV = []
def E(id, speaker, when, ti, te, choices, **kw):
    e = {"id": id, "speaker": speaker, "when": when, "text": T(ti, te), "choices": choices}
    e.update(kw)
    EV.append(e)

# ---------------------------------------------------------------- forced story beats
E("ospek", "senior", {"sem_max": 1, "week": 1},
  "Selamat datang, Maba! Gue Bang Jarwo, semester 13. Satu tips dari gue: jangan jadi kayak gue.",
  "Welcome, freshman! I'm Bang Jarwo, 13th semester. One tip from me: don't end up like me.",
  [C("Siap, Bang!", "Yes, sir!", {"social": 5}, "Bang Jarwo menepuk pundakmu. \"Semangat. Nanti juga ngerti.\"", "Bang Jarwo pats your shoulder. \"Hang in there. You'll get it eventually.\""),
   C("Bang, kok bisa semester 13?", "How are you in semester 13?", {"mental": 3, "social": 2}, "\"Panjang ceritanya. Dospem gue dinas dari 2019.\"", "\"Long story. My advisor's been on a work trip since 2019.\"")],
  force=True, priority=50)
E("bestie", "bestie", {"sem_max": 1, "week": 2},
  "Hai! Aku Sari, kita satu kelompok ospek kemarin. Mau gabung grup belajar bareng?",
  "Hi! I'm Sari, we were in the same orientation group. Want to join our study group?",
  [C("Gas, temenan!", "Let's be friends!", {"social": 8, "mental": 4}, "Kamu resmi punya bestie. Hidup terasa sedikit lebih ringan.", "You officially have a bestie. Life feels a little lighter.", set=["bestie"]),
   C("Aku agak introvert...", "I'm kind of an introvert...", {"social": 3, "mental": 2}, "Sari tetap memasukkanmu ke grup. \"Nggak usah aktif, yang penting ada.\"", "Sari adds you to the group anyway. \"You don't have to talk, just be there.\"", set=["bestie"])],
  force=True, priority=40)
E("mental_warning", "bestie", {"mental_max": 25, "not_flags": ["warned"]},
  "{name}, kamu kelihatan capek banget akhir-akhir ini. Mau cerita? UPT Konseling kampus gratis lho, aku temenin.",
  "{name}, you've looked really exhausted lately. Want to talk? The campus counseling unit is free, I'll come with you.",
  [C("Iya... temenin aku ke konseling.", "Yeah... come with me to counseling.", {"mental": 22}, "Bu Laras mendengarkan tanpa menghakimi. Ternyata cerita itu melegakan. (Kamu bisa pilih aksi Konseling Kampus kapan saja di slot siang.)", "Bu Laras listens without judging. Talking actually helps. (You can pick Campus Counseling any time in the afternoon slot.)", set=["pernah_konseling"]),
   C("Aku baik-baik aja kok.", "I'm fine, really.", {"social": 3}, "\"Oke... tapi aku di sini ya kalau kamu butuh.\" Tolong jaga energi & mentalmu.", "\"Okay... but I'm here if you need me.\" Please watch your energy and mental health.")],
  force=True, priority=100, once=False, sets_warned=True)
E("dospem_assigned", "dekan", {"skripsi": True, "not_flags": ["dospem_known"]},
  "SK Pembimbing keluar! Dosen pembimbing skripsimu: {dospem}. Semoga beruntung.",
  "The advisor decree is out! Your thesis advisor: {dospem}. Good luck.",
  [C("Bismillah.", "Here goes nothing.", {"mental": -2}, "Mulai sekarang ada aksi Garap Skripsi dan Bimbingan Dospem (siang). Draf harus ditulis, lalu di-ACC.", "You can now pick Write Thesis and Advisor Meeting (afternoon). Write the draft, then get it approved.", set=["dospem_known"])],
  force=True, priority=60)
E("sidang", "dekan", {"flags": ["sidang_ready"]},
  "SIDANG SKRIPSI. Penguji membolak-balik draftmu lalu bertanya: \"Kenapa kamu memilih metode ini?\"",
  "THESIS DEFENSE. The examiner flips through your draft and asks: \"Why did you choose this method?\"",
  [C("Jelaskan dengan tenang & runtut", "Explain calmly and clearly", {"mental": 5}, "\"Baik. Selamat, Anda LULUS sidang!\" Kamu hampir pingsan karena lega.", "\"Very well. Congratulations, you PASSED!\" You nearly faint from relief.",
     p=0.65, p_bonus={"knowledge": 0.02, "rel": 0.02}, fail_fx={"acc": -20, "mental": -8}, fri="\"Konsepnya belum matang. Revisi mayor, sidang ulang.\"", fre="\"The concept isn't ready. Major revisions, defend again.\"", unset=["sidang_ready"]),
   C("Jurus pamungkas: \"Itu limitasi penelitian, Pak/Bu.\"", "Ultimate move: \"That's a limitation of the study.\"", {"mental": 5}, "Penguji tertawa. \"Jawaban klasik. Oke, lulus dengan revisi minor.\"", "The examiner laughs. \"Classic answer. Fine, pass with minor revisions.\"",
     p=0.45, p_bonus={"social": 0.005, "rel": 0.02}, fail_fx={"acc": -20, "mental": -10}, fri="\"Semua jadi limitasi kalau begitu. Sidang ulang.\"", fre="\"Then everything's a limitation. Defend again.\"", unset=["sidang_ready"])],
  force=True, priority=90, once=False)
E("kkn_start", "kades", {"has_kkn": True, "week_max": 2},
  "Selamat datang di Desa Sukamaju, adik-adik KKN! Kami butuh program kerja. Sinyal cuma ada di atas pohon jambu.",
  "Welcome to Sukamaju Village, KKN students! We need a work program. The only signal is on top of the guava tree.",
  [C("Proker ambisius: digitalisasi desa!", "Ambitious: digitize the village!", {"social": 8, "energy": -12, "rel": 1}, "Warga antusias. Kamu naik pohon jambu tiap hari buat upload laporan.", "The villagers are thrilled. You climb the guava tree daily to upload reports.", set=["kkn_ok"]),
   C("Proker realistis: plang nama gang", "Realistic: street name signs", {"social": 5, "mental": 4}, "Plang selesai dalam 3 hari. Warga senang, kamu bisa tidur.", "Signs done in 3 days. Villagers happy, you can sleep.", set=["kkn_ok"])],
  force=True, priority=55)
E("phk", "ayah", {"flags": ["phk_new"]},
  "\"Nak... Ayah kena PHK. Pabriknya tutup. Mulai semester ini Ayah belum bisa bayar UKT-mu. Kiriman juga cuma bisa sedikit.\"",
  "\"Kid... Dad got laid off. The factory closed. Starting this semester I can't pay your tuition. I can only send a little each month.\"",
  [C("\"Aku bakal cari kerja sendiri, Yah.\"", "\"I'll find a job myself, Dad.\"", {"mental": -5}, "Ayah terdiam lama. \"Maafin Ayah ya.\" Mulai sekarang UKT & hidupmu tanggung sendiri. Cek Papan Lowongan.", "Dad is quiet for a long time. \"I'm sorry.\" From now on, tuition and living costs are on you. Check the Job Board.", set=["mandiri"], unset=["phk_new"]),
   C("\"...Iya, Yah. Nggak apa-apa.\"", "\"...Okay, Dad. It's fine.\"", {"mental": -10}, "Kamu menutup telepon dan menatap langit-langit kos lama sekali. Opsi: kerja part-time, banding UKT, beasiswa, atau cuti.", "You hang up and stare at the ceiling for a long time. Options: part-time work, tuition appeal, scholarship, or a leave semester.", unset=["phk_new"])],
  force=True, priority=200)
E("ukt_naik", "siakad", {"sem_min": 2, "sem_max": 6, "week_min": 3},
  "PENGUMUMAN: UKT semester depan naik 25% \"demi peningkatan mutu layanan\". Mahasiswa geram, BEM siap demo.",
  "ANNOUNCEMENT: Next semester's tuition rises 25% \"to improve service quality\". Students are furious; the student union plans a protest.",
  [C("Ikut demo!", "Join the protest!", {"social": 8, "energy": -10, "mental": 4}, "Aksi damai ribuan mahasiswa viral. Kenaikan UKT DIBATALKAN!", "A peaceful protest of thousands goes viral. The tuition hike is CANCELLED!",
     p=0.45, p_bonus={"social": 0.004}, fail_fx={"ukt_mult": 1.25, "mental": -4}, fri="Demo diterima Rektor, \"akan dikaji\". Kenaikan tetap berlaku.", fre="The rector receives the protesters, \"it will be reviewed\". The hike goes ahead."),
   C("Pasrah, rebahan saja", "Give up, lie down", {"ukt_mult": 1.25, "mental": -3}, "UKT naik. Rebahan tidak menurunkan UKT, ternyata.", "Tuition went up. Lying down doesn't lower tuition, it turns out.")],
  weight=1.2)

# ---------------------------------------------------------------- lecturers & bureaucracy
E("read_doang", "dosen_read", {"sem_max": 6},
  "Kamu chat Pak Haryo minta jadwal kuis susulan. Centang biru. Tiga hari. Satu minggu. Masih centang biru.",
  "You message Pak Haryo about a make-up quiz. Blue ticks. Three days. One week. Still blue ticks.",
  [C("Chat lagi dengan salam super sopan", "Message again, extra polite", {"rel": 1, "bonus": 1}, "Dibalas: \"Ok.\" Hanya \"Ok.\" Tapi itu cukup.", "Reply: \"Ok.\" Just \"Ok.\" But it's enough.",
     p=0.5, fail_fx={"mental": -4}, fri="Di-read lagi. Kali ini beliau sempat ganti foto profil.", fre="Read again. This time he even updated his profile picture."),
   C("Datangi langsung ruangannya", "Go to his office in person", {"energy": -8, "bonus": 1.5}, "Beruntung, beliau ada! Urusan beres dalam 2 menit.", "Lucky, he's there! Sorted in 2 minutes.",
     p=0.4, fail_fx={"energy": -8, "mental": -5}, fri="Pintu terkunci. Tulisan \"Sedang Rapat\" tertempel sejak 2021.", fre="Locked door. A \"In a Meeting\" sign has hung there since 2021.")],
  weight=1.4)
E("buku_wajib", "dosen_buku", {"sem_max": 6},
  "\"Buku saya edisi ke-7 wajib dibeli. 150 ribu. Yang tidak punya, tidak boleh ikut remedial.\"",
  "\"My textbook, 7th edition, is mandatory. 150K. No book, no remedial exam.\"",
  [C("Beli bukunya (150 koin)", "Buy the book (150 coins)", {"coins": -150, "bonus": 3}, "Isinya sama persis dengan edisi 6. Cuma ganti cover dan harga.", "It's identical to the 6th edition. Only the cover and price changed.", set=["buku"]),
   C("Fotokopi punya teman (30 koin)", "Photocopy a friend's (30 coins)", {"coins": -30}, "Aman. Kamu menghemat 120 ribu.", "Safe. You saved 120K.",
     p=0.6, fail_fx={"coins": -30, "bonus": -4}, fri="Ketahuan! \"Kamu tidak menghargai karya intelektual saya.\"", fre="Caught! \"You don't respect my intellectual work.\""),
   C("Lapor ke prodi", "Report it to the department", {"rel": -1}, "Prodi menegur beliau. Kewajiban dicabut, tapi beliau ingat wajahmu.", "The department reprimands him. Mandate dropped, but he remembers your face.",
     p=0.3, p_bonus={"rel": 0.04}, fail_fx={"rel": -2, "bonus": -3, "mental": -5}, fri="Laporan \"sedang diproses\". Nilaimu juga \"sedang diproses\".", fre="Report \"being processed\". Your grade is also \"being processed\".")])
E("dosen_telat", "dosen_killer", {},
  "Dosen killer masuk kelas 45 menit telat. Lalu mengusir mahasiswa yang telat 2 menit.",
  "The strict lecturer arrives 45 minutes late. Then kicks out a student who was 2 minutes late.",
  [C("Diam, catat dalam hati", "Stay quiet, note it mentally", {"mental": -3}, "Kamu menulis di buku: \"Sabar itu SKS tak terlihat.\"", "You write in your notebook: \"Patience is an invisible credit unit.\""),
   C("Bisik-bisik ke teman", "Whisper to a friend", {"social": 3}, "Temanmu ngakak tanpa suara. Bonding tercipta.", "Your friend laughs silently. A bond is formed.",
     p=0.7, fail_fx={"attend": -1, "bonus": -2, "mental": -5}, fri="\"KAMU yang ngobrol, keluar!\" Absenmu dicoret.", fre="\"YOU, the one talking, out!\" Your attendance is crossed out.")])
E("kelas_kosong", "siakad", {},
  "Dosen tidak datang. Info di grup: \"Kuliah diganti tugas resume 20 halaman, kumpul besok pagi.\"",
  "The lecturer doesn't show up. Group chat: \"Class replaced with a 20-page summary, due tomorrow morning.\"",
  [C("Kerjain sekarang", "Do it now", {"energy": -10, "tugas": 1}, "Selesai jam 2 pagi. Tangan pegal, hati bangga.", "Done at 2 a.m. Sore hands, proud heart."),
   C("Copas dari kating, edit dikit", "Copy a senior's, tweak it", {"tugas": 0.5, "mental": 2}, "Lolos! Dosennya juga nggak baca.", "It passed! The lecturer didn't read it either.",
     p=0.6, fail_fx={"bonus": -4, "mental": -4}, fri="Ketahuan: nama kating masih ada di header.", fre="Caught: the senior's name was still in the header.")])
E("siakad_down", "siakad", {},
  "SIAKAD error 504 tepat 5 menit sebelum deadline upload tugas.",
  "The academic portal throws a 504 error exactly 5 minutes before the upload deadline.",
  [C("Kirim via email + screenshot error", "Email it with an error screenshot", {}, "Dosen menerima. Screenshot adalah senjata mahasiswa.", "The lecturer accepts it. Screenshots are a student's weapon.",
     p=0.65, fail_fx={"tugas": -1.5, "mental": -6}, fri="\"Itu bukan urusan saya.\" Tugas dianggap tidak dikumpul.", fre="\"Not my problem.\" Assignment marked as missing."),
   C("Refresh 200 kali", "Refresh 200 times", {"mental": 3}, "Masuk di detik ke-59! Adrenalin level dewa.", "Uploaded at second 59! God-tier adrenaline.",
     p=0.35, fail_fx={"tugas": -1.5, "mental": -8}, fri="Server baru pulih jam 00.01. Telat 1 menit.", fre="The server recovers at 00:01. One minute late.")],
  weight=1.3)
E("tu_besok", "tu", {},
  "Kamu butuh tanda tangan surat aktif kuliah. Pak Darto: \"Besok aja ya, Dik. Bapak lagi istirahat.\" (Ini jam 10.15.)",
  "You need a signed proof-of-enrollment letter. Pak Darto: \"Come back tomorrow. I'm on my break.\" (It's 10:15 a.m.)",
  [C("Balik besok", "Come back tomorrow", {"energy": -6}, "Besoknya beres! Sebuah keajaiban birokrasi.", "Done the next day! A bureaucratic miracle.",
     p=0.5, fail_fx={"energy": -6, "mental": -5}, fri="Besoknya: \"Yang tanda tangan lagi cuti, Dik.\"", fre="Next day: \"The signatory is on leave.\""),
   C("Bawakan gorengan buat Pak Darto", "Bring fritters for Pak Darto", {"coins": -20, "social": 2, "rel": 1}, "Langsung ditandatangani. Gorengan adalah kunci birokrasi.", "Signed instantly. Fritters are the key to bureaucracy.",
     p=0.85, fail_fx={"coins": -20, "mental": -3}, fri="Gorengannya dimakan. Suratnya tetap besok.", fre="He eats the fritters. The letter is still tomorrow.")],
  weight=1.3, once=False)
E("cap_basah", "tu", {"sem_min": 2},
  "Legalisir harus cap basah, 3 rangkap, pakai map biru tua. \"Bukan biru muda ya, Dik.\"",
  "Certification requires wet stamps, 3 copies, in a dark blue folder. \"Not light blue.\"",
  [C("Beli map biru tua", "Buy a dark blue folder", {"coins": -10, "energy": -5}, "Diterima! Setelah antre 2 jam.", "Accepted! After a 2-hour queue."),
   C("Nekat pakai map biru muda", "Risk the light blue folder", {"mental": 3}, "Lolos! Pak Darto sedang tidak pakai kacamata.", "It passed! Pak Darto wasn't wearing his glasses.",
     p=0.3, fail_fx={"mental": -5, "energy": -5}, fri="Ditolak. \"Ulang besok, Dik.\"", fre="Rejected. \"Try again tomorrow.\"")])
E("akreditasi", "dekan", {},
  "Kampus mau akreditasi! Semua mahasiswa wajib pakai almamater dan tersenyum ke asesor. Toilet tiba-tiba direnovasi.",
  "Accreditation visit! Everyone must wear the campus jacket and smile at the assessors. The toilets are suddenly renovated.",
  [C("Jadi \"mahasiswa teladan\" dadakan", "Be an instant \"model student\"", {"rel": 2, "energy": -6}, "Asesor terkesan. Dekan ingat namamu (salah eja, tapi tetap).", "The assessors are impressed. The dean remembers your name (misspelled, but still)."),
   C("Kabur ke kantin", "Escape to the canteen", {"mental": 3}, "Kantin sepi. Surga.", "The canteen is empty. Paradise.")])
E("dosen_curhat", "dosen_killer", {"sem_min": 2},
  "Di akhir kelas, dosen killer tiba-tiba curhat: dosen juga tenggelam di laporan BKD, akreditasi, dan rapat tanpa akhir.",
  "After class, the strict lecturer suddenly vents: lecturers are drowning in workload reports, accreditation and endless meetings too.",
  [C("Dengarkan dengan empati", "Listen with empathy", {"rel": 2, "mental": 2}, "Ternyata dosen juga korban sistem. Beliau tersenyum untuk pertama kalinya.", "Turns out lecturers are victims of the system too. She smiles for the first time."),
   C("Main HP diam-diam", "Scroll your phone secretly", {}, "Kamu melewatkan momen langka itu.", "You missed a rare moment.")])
E("dosen_wa_malam", "dosen_read", {"sem_min": 3},
  "Jam 23.07, pesan masuk: \"Besok jam 7 pagi ke ruangan saya.\" Tanpa konteks.",
  "11:07 p.m., a message arrives: \"Come to my office at 7 a.m. tomorrow.\" No context.",
  [C("Datang jam 6.45", "Show up at 6:45", {"energy": -10, "rel": 2}, "Beliau datang jam 10. Tapi senang kamu rajin.", "He arrives at 10. But he's pleased you're diligent.",
     p=0.6, fail_fx={"energy": -10, "mental": -4}, fri="Beliau tidak datang sama sekali. Pesan berikutnya: \"Besok saja.\"", fre="He never shows. Next message: \"Tomorrow instead.\""),
   C("Balas \"Baik, Pak\" lalu overthinking", "Reply \"Yes, sir\" then overthink", {"mental": -3, "rel": 1}, "Ternyata cuma minta tolong angkat proyektor.", "Turns out he just needed help carrying a projector.")])
E("titip_absen", "bestie", {},
  "Temanmu nawarin: \"Bolos aja, nanti aku titip absenin.\"",
  "Your friend offers: \"Skip class, I'll sign you in.\"",
  [C("Iya, titip!", "Yes please!", {"attend": 1, "energy": 5}, "Aman. Kamu tercatat hadir sambil rebahan.", "Safe. Marked present while lying in bed.",
     p=0.7, fail_fx={"attend": -1, "bonus": -3, "mental": -5}, fri="Dosen memanggil nama satu-satu. Ketahuan!", fre="The lecturer calls names one by one. Busted!"),
   C("Nggak ah, takut dosa", "No, feels wrong", {"mental": -1}, "Integritas terjaga. Kantuk juga terjaga.", "Integrity intact. Sleepiness also intact.")])
E("joki", "pinjol", {"sem_min": 2},
  "DM masuk: \"Jasa joki tugas & skripsi. Murah, amanah, bergaransi. Ready semua prodi.\"",
  "A DM arrives: \"Assignment & thesis ghostwriting. Cheap, trustworthy, guaranteed. All majors.\"",
  [C("Pakai joki tugas (300 koin)", "Hire a ghostwriter (300 coins)", {"coins": -300, "tugas": 3, "knowledge": -1}, "Tugas beres... tapi kamu tidak paham isinya sama sekali.", "Assignment done... but you don't understand any of it.",
     p=0.7, fail_fx={"coins": -300, "bonus": -6, "mental": -8}, fri="Turnitin: 98% plagiat. Kamu dipanggil prodi.", fre="Plagiarism checker: 98% match. The department summons you."),
   C("Report & block", "Report & block", {"mental": 2}, "Integritas +100. Tidak ada di stat, tapi kamu tahu.", "Integrity +100. Not on your stats, but you know.")])
E("jual_nilai", "dosen_buku", {"sem_min": 2, "sem_max": 6},
  "Seorang \"oknum\" berbisik: \"Nilai A bisa diatur. Transfer saja, aman.\"",
  "A shady \"someone\" whispers: \"An A can be arranged. Just transfer the money, it's safe.\"",
  [C("Transfer 500 koin", "Transfer 500 coins", {"coins": -500, "bonus": 8}, "Nilai \"aman\". Untuk sekarang.", "Grades \"secured\". For now.",
     p=0.6, fail_fx={"coins": -500}, fri="Kasus jual-beli nilai terbongkar. Semua yang terlibat di-DO.", fre="The grade-selling scheme is exposed. Everyone involved is expelled.", fail_end="do", end_reason="jual_nilai"),
   C("Tolak dan laporkan", "Refuse and report", {"rel": 2}, "Oknum itu diperiksa. Kampus sedikit lebih bersih.", "The person is investigated. Campus is a little cleaner.",
     p=0.55, fail_fx={"rel": -1, "mental": -4}, fri="Laporanmu \"hilang\" di meja seseorang.", fre="Your report \"went missing\" on someone's desk.")],
  weight=0.6)

# ---------------------------------------------------------------- classmates & social
E("kelompok_beban", "beban", {},
  "Tugas kelompok 5 orang. Dimas baru muncul H-1 presentasi: \"Bagian gue yang mana ya?\"",
  "A 5-person group project. Dimas shows up the day before the presentation: \"So which part is mine?\"",
  [C("Kerjain sendiri aja", "Just do it yourself", {"tugas": 1.5, "energy": -15, "mental": -6}, "Selesai. Nama Dimas tetap tercantum. Hidup memang begitu.", "Done. Dimas's name is still on it. That's life."),
   C("Coret namanya dari laporan", "Remove his name from the report", {"bonus": 1, "social": -2}, "Dosen mengapresiasi kejujuranmu.", "The lecturer appreciates your honesty.",
     p=0.6, fail_fx={"social": -6, "mental": -4}, fri="Grup jadi drama. Dimas bikin story galau.", fre="Group drama ensues. Dimas posts a sad story."),
   C("Kasih bagian \"bawa laptop\"", "Give him \"bring the laptop\" duty", {"social": 3, "mental": -2}, "Dimas bawa laptop. Tanpa charger.", "Dimas brings the laptop. Without the charger.")],
  weight=1.3)
E("ambis", "ambis", {},
  "\"Kamu udah baca 3 jurnal buat minggu depan? Aku udah 12.\"",
  "\"Have you read the 3 journal papers for next week? I've read 12.\"",
  [C("Ikut belajar bareng Nadia", "Study with Nadia", {"knowledge": 1.5, "energy": -8, "social": 2}, "Ternyata Nadia baik. Cuma ambisnya volume maksimal.", "Turns out Nadia is nice. Her ambition is just on max volume."),
   C("\"Aku baca 0. Dan aku tenang.\"", "\"I've read 0. And I'm at peace.\"", {"mental": 4}, "Nadia menatapmu seperti melihat alien.", "Nadia stares at you like you're an alien.")])
E("ketua_hima", "senior", {"sem_min": 2, "sem_max": 5, "social_min": 50},
  "Kamu dicalonkan jadi Ketua Himpunan Mahasiswa!",
  "You've been nominated for Student Association President!",
  [C("Maju!", "Run for it!", {"social": 10, "energy": -10, "rel": 2, "mental": -3}, "Terpilih! Jadwal rapatmu sekarang 3x lipat.", "Elected! Your meeting schedule just tripled.", set=["ketua"]),
   C("Jadi anggota aja", "Stay a member", {"mental": 2}, "Kamu tetap aktif tanpa beban jabatan.", "You stay active without the burden of office.")])
E("lomba", "dosen_revisi", {"sem_min": 2, "sem_max": 6, "ipk_min": 3.2},
  "Seorang dosen mengajakmu ikut lomba nasional. Deadline proposal: minggu depan.",
  "A lecturer invites you to a national competition. Proposal deadline: next week.",
  [C("Gas!", "Let's go!", {"energy": -20, "coins": 1000, "rel": 3, "bonus": 2}, "JUARA 2 NASIONAL! Hadiah 1 juta dan sertifikat.", "2ND PLACE NATIONALLY! 1 million prize and a certificate.",
     p=0.4, p_bonus={"knowledge": 0.02}, fail_fx={"energy": -20, "rel": 1, "mental": -4}, fri="Belum juara, tapi dosen mulai kenal kamu.", fre="No prize, but the lecturer knows you now."),
   C("Skip, fokus kuliah", "Skip, focus on classes", {"knowledge": 0.5}, "Fokus itu juga strategi.", "Focus is also a strategy.")])
E("seminar_snack", "senior", {},
  "Seminar nasional GRATIS! Dapat sertifikat, snack box, dan nasi kotak.",
  "FREE national seminar! Certificate, snack box and a boxed lunch.",
  [C("Datang (demi nasi kotak)", "Go (for the boxed lunch)", {"energy": -5, "coins": 35, "social": 3, "rel": 1}, "Materinya lumayan. Nasi kotaknya juara.", "The talk was okay. The boxed lunch was champion-tier."),
   C("Skip", "Skip", {"energy": 4}, "Kamu tidur siang dengan damai.", "You take a peaceful nap.")])
E("grup_drama", "ambis", {},
  "Grup WhatsApp kelas ribut soal pembagian kelompok. 287 pesan belum dibaca.",
  "The class WhatsApp group is fighting over group assignments. 287 unread messages.",
  [C("Ikut debat", "Join the debate", {"social": -2, "mental": -3}, "Debat selesai tanpa keputusan. Seperti rapat pada umumnya.", "The debate ends with no decision. Like every meeting."),
   C("Mute grup 1 minggu", "Mute the group for a week", {"mental": 4}, "Damai.", "Peace.", p=0.6, fail_fx={"mental": 2, "bonus": -1.5}, fri="Damai... sampai kamu sadar ketinggalan info kuis.", fre="Peaceful... until you realize you missed the quiz announcement.")])
E("ospek_panitia", "senior", {"sem_min": 3, "sem_max": 5, "week_max": 2},
  "Kamu jadi panitia ospek. Seorang maba bertanya polos: \"Kak, kuliah itu enak nggak?\"",
  "You're on the orientation committee. A freshman asks innocently: \"Is college fun?\"",
  [C("Jujur", "Be honest", {"social": 4}, "Maba itu mengangguk pelan. Kamu baru saja menjadi Bang Jarwo versi baru.", "The freshman nods slowly. You've just become the new Bang Jarwo."),
   C("\"Seru banget kok!\"", "\"It's super fun!\"", {"mental": 2}, "Bohong demi kebaikan. Kamu tersenyum getir.", "A white lie. You smile bitterly.")])
E("glowing", "bestie", {"mental_min": 70, "social_min": 50},
  "\"Kamu lagi glowing banget sih akhir-akhir ini. Rahasianya apa?\"",
  "\"You've been glowing lately. What's your secret?\"",
  [C("\"Tidur cukup & nongkrong secukupnya\"", "\"Enough sleep, enough hangouts\"", {"mental": 3, "social": 3}, "Social campus balance: unlocked.", "Social campus balance: unlocked.")])
E("kucing", "narator", {},
  "Kucing kampus tidur di atas laptopmu, persis di tombol Delete.",
  "The campus cat falls asleep on your laptop, right on the Delete key.",
  [C("Elus-elus", "Pet the cat", {"mental": 6, "tugas": -0.5}, "Paragraf terakhirmu hilang, tapi hatimu hangat.", "Your last paragraph is gone, but your heart is warm."),
   C("Pindahkan pelan-pelan", "Gently move it", {"mental": 3}, "Si kucing pindah ke tasmu. Kompromi.", "The cat relocates to your bag. A compromise.")])

# ---------------------------------------------------------------- money & family
E("flash_sale", "narator", {"coins_min": 400},
  "Notifikasi tengah malam: FLASH SALE! Hoodie ungu lucu diskon 70%, sisa 3 lagi!",
  "Midnight notification: FLASH SALE! Cute purple hoodie 70% off, only 3 left!",
  [C("Checkout! (khilaf, 250 koin)", "Check out! (impulse, 250 coins)", {"coins": -250, "mental": 6, "item": "top_hoodie_ungu"}, "Paket datang 3 hari kemudian. Dompet menangis, hati senang. (Hoodie masuk Lemari.)", "The package arrives 3 days later. Wallet crying, heart happy. (Hoodie added to your Wardrobe.)", set=["khilaf"]),
   C("Tutup aplikasi, tidur", "Close the app, sleep", {"mental": -2}, "Kamu kuat. Kamu sigma.", "You're strong. You're sigma.")])
E("ibu_telpon", "ibu", {"not_flags": ["phk"]},
  "\"Nak, udah makan belum? Kapan pulang? Jangan lupa salat/ibadah ya.\"",
  "\"Have you eaten, dear? When are you coming home? Don't forget to pray.\"",
  [C("Cerita jujur kalau lagi capek", "Honestly say you're tired", {"mental": 10}, "Ibu mendengarkan. \"Capek boleh, menyerah jangan dulu.\"", "Mom listens. \"It's okay to be tired, just don't give up yet.\""),
   C("\"Baik-baik aja kok, Bu\"", "\"I'm fine, Mom\"", {"mental": 3}, "Ibu tahu kamu bohong. Ibu selalu tahu.", "Mom knows you're lying. Moms always know.")],
  once=False, weight=0.8)
E("ibu_maaf", "ibu", {"flags": ["phk"]},
  "\"Maaf ya, Nak, kiriman bulan ini cuma segini. Ayah masih cari kerja.\"",
  "\"Sorry, dear, this month's allowance is all we could send. Dad is still job hunting.\"",
  [C("\"Nggak apa-apa, Bu. Aku kerja part-time kok.\"", "\"It's okay, Mom. I work part-time.\"", {"mental": -2, "social": 2}, "Ibu menangis pelan di telepon. Kamu juga, setelah teleponnya ditutup.", "Mom cries softly on the phone. So do you, after hanging up."),
   C("Kirim balik sedikit uang (100 koin)", "Send a little money back (100 coins)", {"coins": -100, "mental": 5}, "\"Kamu sudah besar ya, Nak.\"", "\"You've really grown up, dear.\"")])
E("ibu_kos", "ibu_kos", {},
  "\"Galon kos habis, gantian beli ya. Sekalian token listrik.\"",
  "\"The water gallon is empty, it's your turn to buy. And the electricity token.\"",
  [C("Beli (40 koin)", "Buy it (40 coins)", {"coins": -40, "social": 2}, "Bu Endang memberimu pisang goreng sebagai bonus.", "Bu Endang gives you fried bananas as a bonus."),
   C("Pura-pura tidur", "Pretend to be asleep", {}, "Berhasil! Anak kamar sebelah yang kena.", "It worked! The kid next door got stuck with it.",
     p=0.5, fail_fx={"coins": -40, "mental": -3, "social": -2}, fri="Bu Endang mengetuk pintu selama 15 menit. Kamu menyerah.", fre="Bu Endang knocks for 15 minutes. You give in.")],
  once=False, weight=0.7)
E("warkop_bon", "narator", {"coins_max": 150},
  "Mas warkop: \"Bon kamu udah 15 gelas lho, Mas/Mbak.\"",
  "The warkop owner: \"Your tab is up to 15 coffees, you know.\"",
  [C("Bayar setengah (60 koin)", "Pay half (60 coins)", {"coins": -60, "social": 2}, "\"Sip, sisanya pas kiriman ya.\"", "\"Cool, the rest when your allowance arrives.\""),
   C("Janji bayar pas kiriman", "Promise to pay later", {"social": -2, "mental": -3}, "Mas warkop mengangguk. Matanya tidak.", "He nods. His eyes don't.")])
E("pinjol_sms", "pinjol", {"sem_min": 2, "coins_max": 250, "not_flags": ["pinjol"]},
  "SMS: \"Butuh dana cepat? DanaKilat cair 5 menit! Tanpa jaminan!\"",
  "SMS: \"Need cash fast? DanaKilat pays out in 5 minutes! No collateral!\"",
  [C("Pinjam 1.000 koin", "Borrow 1,000 coins", {"coins": 1000, "debt": 1500, "mental": -3}, "Cair. Bunganya juga cair. Utang 1.500 ditagih awal semester depan.", "Money's in. So is the interest. 1,500 debt due next semester.", set=["pinjol"]),
   C("Hapus SMS", "Delete the SMS", {"mental": 1}, "Keputusan finansial terbaik bulan ini.", "Best financial decision of the month.")])
E("dc_call", "pinjol", {"flags": ["pinjol"], "coins_max": 300},
  "Debt collector DanaKilat menghubungi semua kontakmu. Termasuk dosen pembimbing akademikmu.",
  "DanaKilat's debt collector contacts everyone in your phone. Including your academic advisor.",
  [C("Tutup muka pakai bantal", "Hide your face in a pillow", {"mental": -10, "rel": -1, "social": -3}, "Pelajaran mahal: pinjol bukan solusi.", "An expensive lesson: loan apps aren't a solution.")])
E("pulang_kampung", "ibu", {"week": 7},
  "Libur tengah semester. Ibu masak rendang. Pulang kampung?",
  "Mid-semester break. Mom is cooking rendang. Go home?",
  [C("Pulang (200 koin)", "Go home (200 coins)", {"coins": -200, "mental": 15, "energy": 10}, "Rendang Ibu menyembuhkan segalanya. Hampir.", "Mom's rendang heals everything. Almost."),
   C("Stay, nyicil tugas", "Stay, catch up on work", {"tugas": 1.5, "mental": -2}, "Kos sepi. Tugas maju. Rindu juga maju.", "The boarding house is quiet. Work progresses. So does homesickness.")])
E("motor_mogok", "narator", {},
  "Hujan deras, motor matic-mu mogok di depan gerbang kampus.",
  "Pouring rain, your scooter breaks down at the campus gate.",
  [C("Dorong ke bengkel (60 koin)", "Push it to a repair shop (60 coins)", {"energy": -12, "coins": -60}, "Basah kuyup, tapi motor hidup lagi.", "Soaked, but the scooter lives again."),
   C("Titip satpam, pulang naik ojol", "Leave it with security, take a ride", {"coins": -25}, "Pak Satpam menjaga motormu seperti anak sendiri.", "The security guard guards it like his own child.")])
E("laptop_rusak", "narator", {"sem_min": 2},
  "Laptopmu bluescreen pas lagi ngerjain tugas besar. Belum di-save.",
  "Your laptop bluescreens mid-project. Unsaved.",
  [C("Servis (400 koin)", "Get it repaired (400 coins)", {"coins": -400}, "Hidup lagi. Pelajaran: Ctrl+S tiap 5 detik.", "Back alive. Lesson: Ctrl+S every 5 seconds."),
   C("Pinjam laptop teman", "Borrow a friend's laptop", {"tugas": -1, "social": 2}, "Kamu mengulang dari nol di laptop orang. Pahit.", "You redo everything on someone else's laptop. Bitter.")])
E("banjir", "narator", {},
  "Banjir! Kampus diliburkan mendadak.",
  "Flood! Campus closes unexpectedly.",
  [C("Syukuri, istirahat", "Be grateful, rest", {"energy": 15, "mental": 5}, "Libur dadakan adalah hadiah terindah.", "Surprise holidays are the best gift."),
   C("Tetap belajar online", "Keep studying online", {"knowledge": 1}, "Sinyal naik-turun seperti mood dosen.", "The signal goes up and down like a lecturer's mood.")])
E("demam", "narator", {"mental_max": 45},
  "Badanmu demam tinggi. Kata dokter klinik kampus: gejala tifus, harus istirahat.",
  "You have a high fever. The campus clinic says: typhoid symptoms, you need rest.",
  [C("Istirahat total (150 koin obat)", "Rest completely (150 coins for meds)", {"energy": 30, "mental": 4, "coins": -150, "attend": -1}, "Tubuhmu berterima kasih. Absen bolong satu.", "Your body thanks you. One absence."),
   C("Paksa tetap kuliah", "Force yourself to class", {"energy": -15, "mental": -6}, "Kamu hadir secara fisik. Jiwamu di kasur.", "Your body attended. Your soul stayed in bed.")])

# ---------------------------------------------------------------- jobs
E("kelas_pengganti", "dosen_killer", {"job_slot": "malam"},
  "Dosen memindahkan kelas pengganti ke jam 19.00 — tepat jam shift kerjamu. BENTROK!",
  "The lecturer moves a make-up class to 7 p.m. — exactly your work shift. CLASH!",
  [C("Masuk kelas, izin kerja", "Attend class, skip work", {"job_izin": 1, "coins": -150, "knowledge": 0.5}, "Ilmu dapat, gaji kepotong. Bos mencatat izinmu.", "Knowledge gained, pay docked. The boss logs your absence."),
   C("Masuk kerja, bolos kelas", "Go to work, skip class", {"attend": -1}, "Kamu dianggap tidak hadir. Kehadiranmu makin tipis.", "Marked absent. Your attendance gets thinner.")],
  once=False, weight=1.2)
E("kelas_pengganti_siang", "dosen_read", {"job_slot": "siang"},
  "Kuliah pengganti dadakan jam 13.00. Kamu ada shift les privat jam segitu.",
  "Surprise make-up class at 1 p.m. You have a tutoring shift then.",
  [C("Masuk kelas, izin kerja", "Attend class, skip work", {"job_izin": 1, "coins": -150, "knowledge": 0.5}, "Murid lesmu kecewa. Dosen tidak sadar kamu hadir.", "Your student is disappointed. The lecturer didn't notice you came."),
   C("Tetap kerja", "Keep working", {"attend": -1}, "Absen bolong satu. Dompet aman.", "One absence. Wallet safe.")],
  once=False, weight=1.2)
E("lembur", "bos", {"job": True},
  "\"Besok lembur ya, pas jam kuliah pagi kamu. Dibayar dobel!\"",
  "\"Overtime tomorrow, during your morning class. Double pay!\"",
  [C("Ambil lembur (+300 koin)", "Take it (+300 coins)", {"coins": 300, "attend": -1, "energy": -10}, "Uang masuk. Absen keluar.", "Money in. Attendance out."),
   C("Tolak, kuliah dulu", "Decline, class first", {}, "\"Oke, paham. Kuliah yang bener ya.\"", "\"Okay, I get it. Study hard.\"",
     p=0.6, fail_fx={"job_izin": 1}, fri="Mas Bram cemberut. Dicatat sebagai izin.", fre="Mas Bram frowns. Logged as a skipped shift.")],
  once=False, weight=0.9)
E("magang", "dekan", {"sem_min": 5},
  "Tawaran magang berbayar di startup unicorn (katanya). 600 koin, tapi kerjanya kayak karyawan tetap.",
  "A paid internship at a (supposed) unicorn startup. 600 coins, but they work you like full-time staff.",
  [C("Ambil", "Take it", {"coins": 600, "energy": -20, "rel": 1, "mental": -3}, "Pengalaman dapat, CV makin berkilau.", "Experience gained, your CV sparkles."),
   C("Tolak", "Decline", {"mental": 2}, "Belum waktunya.", "Not yet.")])

# ---------------------------------------------------------------- thesis advisors
E("revisi_font", "dosen_revisi", {"skripsi": True, "dospem": "dosen_revisi"},
  "Catatan revisi: \"Font Times New Roman 12 diganti Times New Roman 12.\"",
  "Revision note: \"Change Times New Roman 12 to Times New Roman 12.\"",
  [C("Ganti... jadi sama", "Change it... to the same", {"mental": -2, "acc": 4}, "ACC! Ternyata itu tes kesabaran.", "Approved! It was a patience test."),
   C("Tanya maksudnya", "Ask what she means", {}, "\"Oh, maksud saya spasinya.\" Masuk akal.", "\"Oh, I meant the spacing.\" Makes sense.",
     p=0.5, fail_fx={"draft": -6, "mental": -4}, fri="\"Kamu meragukan saya? Ulang Bab 2.\"", fre="\"Are you questioning me? Redo Chapter 2.\"")],
  once=False, weight=1.5)
E("dinas_jenewa", "dosen_dinas", {"skripsi": True, "dospem": "dosen_dinas"},
  "\"Saya di Jenewa sampai bulan depan. Bimbingan via email saja ya.\"",
  "\"I'm in Geneva until next month. Let's do supervision by email.\"",
  [C("Kirim email bimbingan", "Send the draft by email", {"acc": 12}, "Dibalas dari bandara! \"Lanjut.\"", "Reply from the airport! \"Continue.\"",
     p=0.45, fail_fx={"mental": -4}, fri="Email terpental: inbox penuh.", fre="Email bounced: inbox full."),
   C("Tunggu beliau pulang", "Wait until he's back", {"mental": -2}, "Kamu menunggu. Dan menunggu.", "You wait. And wait.")],
  once=False, weight=1.5)
E("read_jam2", "dosen_read", {"skripsi": True, "dospem": "dosen_read"},
  "Jam 2 pagi Pak Haryo online. \"Sedang mengetik...\" lalu berhenti. Pesanmu tetap di-read.",
  "2 a.m. Pak Haryo is online. \"Typing...\" then it stops. Still left on read.",
  [C("Kirim stiker kucing memohon", "Send a begging cat sticker", {"acc": 10, "mental": 3}, "Dibalas stiker jempol. Itu artinya ACC!", "He replies with a thumbs-up sticker. That's approval!",
     p=0.45, fail_fx={"mental": -5}, fri="Stikermu juga di-read.", fre="Your sticker was also left on read."),
   C("Tidur, coba besok", "Sleep, try tomorrow", {"energy": 8}, "Keputusan dewasa.", "A mature decision.")],
  once=False, weight=1.5)
E("kkn_rebahan", "kades", {"has_kkn": True, "week_min": 4},
  "Teman KKN-mu cuma rebahan di posko. Proker tinggal 2 minggu lagi.",
  "Your KKN teammate just lies around at base. The program ends in 2 weeks.",
  [C("Tegur baik-baik", "Gently call them out", {"social": 3}, "Dia malu, lalu ikut bantu. Kerja tim!", "They're embarrassed, then help out. Teamwork!",
     p=0.6, fail_fx={"social": -4, "mental": -3}, fri="Dia baper. Posko jadi dingin.", fre="They take it personally. Base camp turns icy."),
   C("Kerjakan sendiri", "Do it yourself", {"energy": -12, "social": 2}, "Warga menyayangimu. Temanmu tetap rebahan.", "Villagers adore you. Your teammate keeps lying down.")])
E("kkn_cinlok", "bestie", {"has_kkn": True, "week_min": 3},
  "Ada teman KKN yang mulai perhatian: bawain kopi tiap pagi, nemenin rapat sampai malam.",
  "A KKN teammate starts paying attention: brings coffee every morning, stays with you through late meetings.",
  [C("Ehem...", "Ahem...", {"mental": 6, "social": 4}, "Cinlok KKN: mitos atau fakta? Kamu tidak mau menjawab.", "KKN romance: myth or fact? You refuse to answer."),
   C("Fokus proker", "Focus on the program", {"social": 1}, "Profesional. Sangat sigma.", "Professional. Very sigma.")])

# ---------------------------------------------------------------- prodi specific
E("if_bug", "narator", {"prodi": ["IF"]},
  "Program tugas besar error di production 1 jam sebelum demo. Pesannya: \"undefined is not a function\".",
  "Your big project crashes 1 hour before the demo: \"undefined is not a function\".",
  [C("Debug sampai ketemu", "Debug until it's fixed", {"energy": -12, "knowledge": 1, "tugas": 0.5}, "Ternyata kurang titik koma. Satu. Titik koma.", "It was a missing semicolon. One. Semicolon.", p=0.6, fail_fx={"tugas": -1, "mental": -6}, fri="Demo pakai screenshot. Dosen tidak terkesan.", fre="You demo with screenshots. The lecturer is unimpressed."),
   C("Tanya ke AI", "Ask an AI", {"tugas": 0.5}, "Jalan! Kamu tidak tahu kenapa. Tidak apa-apa.", "It works! You don't know why. That's fine.")])
E("mn_presentasi", "narator", {"prodi": ["MN"]},
  "Presentasi wajib pakai jas, di ruangan tanpa AC, jam 1 siang.",
  "Mandatory presentation in a suit, in a room without AC, at 1 p.m.",
  [C("Tampil percaya diri", "Present confidently", {"bonus": 2, "energy": -8}, "Keringatmu deras, tapi slide-mu lebih deras. Dosen kagum.", "You sweat buckets, but your slides flow. The lecturer is impressed.", p=0.65, p_bonus={"social": 0.004}, fail_fx={"mental": -5}, fri="Proyektor mati di slide 2.", fre="The projector dies on slide 2."),
   C("Jadi operator slide saja", "Just run the slides", {"social": -1}, "Aman, tapi nilaimu ikut \"aman\".", "Safe, and so is your grade: \"safe\".")])
E("kd_anatomi", "narator", {"prodi": ["KD"]},
  "Praktikum anatomi jam 6 pagi, hafalan 200 istilah Latin, ujian besok.",
  "Anatomy lab at 6 a.m., 200 Latin terms to memorize, exam tomorrow.",
  [C("Hafalan sistem jembatan keledai", "Use silly mnemonics", {"knowledge": 1.5, "energy": -10}, "\"Some Lovers Try Positions...\" Kamu tidak akan pernah lupa.", "You'll never forget those mnemonics. Ever.", p=0.7, fail_fx={"mental": -6}, fri="Mnemonicnya lebih susah dari istilahnya.", fre="The mnemonics were harder than the terms."),
   C("Belajar bareng sambil gantian kuis", "Quiz each other in a group", {"knowledge": 1, "social": 3}, "Belajar bareng ternyata efektif.", "Group study actually works.")])

out = os.path.join(os.path.dirname(__file__), "..", "data", "events.json")
ids = [e["id"] for e in EV]
assert len(ids) == len(set(ids)), "duplicate ids"
json.dump(EV, open(out, "w"), ensure_ascii=False, indent=1)
print(len(EV), "events")
