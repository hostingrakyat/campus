"""Generates data/activities.json: weekly modifiers ("Kabar Minggu Ini") and per-activity variants.

Each variant has flavour text, a small stat tweak, and a scene description that the 3D Director
stages (stage, player spot/pose/animation, cast with their own spots/animations, speech bubbles).

    python3 tools/gen_activities.py
"""
import json
import os


def T(i, e):
    return {"id": i, "en": e}


def SC(stage, spot, pose="stand", anim="idle", cast=None, bubbles=None, hold="", walk=False):
    d = {"stage": stage, "spot": spot, "pose": pose, "anim": anim}
    if cast:
        d["cast"] = cast
    if bubbles:
        d["bubbles"] = bubbles
    if hold:
        d["hold"] = hold
    if walk:
        d["walk"] = True
    return d


def C(npc, spot, anim="idle", pose="stand", hold=""):
    d = {"npc": npc, "spot": spot, "anim": anim, "pose": pose}
    if hold:
        d["hold"] = hold
    return d


def B(who, i, e, delay=0.3):
    return {"who": who, "text": T(i, e), "delay": delay}


def V(id, text, fx=None, scene=None, weight=1.0, when=None):
    d = {"id": id, "text": text, "fx": fx or {}, "weight": weight}
    if scene:
        d["scene"] = scene
    if when:
        d["when"] = when
    return d


EXTRAS = C("extras", "seats", "listen", "sit")

KELAS_LISTEN = SC("kelas", "seat", "sit", "write", [C("lecturer", "lecturer", "point"), EXTRAS])

VARIANTS = {
    "kuliah": [
        V("ceramah", T("Dosen ceramah 2 jam. Kamu mencatat sampai tangan pegal.", "Two-hour lecture. You take notes until your hand cramps."), {},
          SC("kelas", "seat", "sit", "write", [C("lecturer", "lecturer", "point"), EXTRAS],
             [B("lecturer", "Ini keluar di UAS ya.", "This will be on the final.")]), 2.0),
        V("kuis", T("KUIS DADAKAN! Untung kamu sempat baca semalam.", "POP QUIZ! Good thing you read last night."), {"knowledge": 0.4, "mental": -3},
          SC("kelas", "seat", "sit", "nervous", [C("lecturer", "lecturer", "point"), C("extras", "seats", "nervous", "sit")],
             [B("lecturer", "Tutup buku. Kuis sekarang.", "Close your books. Quiz now.")])),
        V("telat", T("Dosen telat 45 menit. Kelas cuma 30 menit.", "The lecturer is 45 minutes late. Class lasts 30 minutes."), {"knowledge": -0.3, "energy": 5},
          SC("kelas", "seat", "sit", "sleep", [C("extras", "seats", "talk", "sit")],
             [B("player", "Dosennya mana sih...", "Where's the lecturer...")])),
        V("presentasi", T("Giliran kelompokmu presentasi. Dimas absen lagi.", "Your group presents. Dimas is absent again."), {"tugas": 0.6, "mental": -3, "social": 2},
          SC("kelas", "front", "stand", "talk", [C("lecturer", "lecturer_seat", "listen", "sit"), C("extras", "seats", "listen", "sit")],
             [B("player", "Jadi kesimpulannya...", "So in conclusion...")])),
        V("diskusi", T("Diskusi kelas seru. Dosen puas sama jawabanmu.", "A lively class discussion. The lecturer likes your answer."), {"rel": 1, "knowledge": 0.2},
          SC("kelas", "seat", "sit", "talk", [C("lecturer", "lecturer", "listen"), EXTRAS],
             [B("lecturer", "Bagus! Siapa namamu?", "Good! What's your name?")])),
        V("slide_jadul", T("Slide dosen dari 2009. Font Comic Sans.", "The slides are from 2009. In Comic Sans."), {"knowledge": -0.2},
          SC("kelas", "seat", "sit", "sleep", [C("lecturer", "lecturer", "talk"), C("extras", "seats", "sleep", "sit")],
             [B("lecturer", "...dan seterusnya, dan seterusnya.", "...and so on, and so on.")])),
    ],
    "ujian": [
        V("ujian", T("Ujian berlangsung. Pengawas mondar-mandir.", "Exam in progress. The invigilator paces around."), {},
          SC("kelas", "seat", "sit", "nervous", [C("lecturer", "aisle", "walk"), C("extras", "seats", "write", "sit")])),
    ],
    "bolos": [
        V("rebahan", T("Bolos, rebahan sambil scroll video kucing.", "Skipped class, scrolling cat videos in bed."), {},
          SC("kamar", "bed", "lie", "phone", hold="phone"), 2.0),
        V("ketahuan", T("Bolos... lalu dosen absen pakai foto kelas. Ups.", "Skipped... then the lecturer took a class photo for attendance. Oops."), {"mental": -4},
          SC("kamar", "bed_edge", "sit", "sad", hold="phone")),
    ],
    "belajar": [
        V("perpus", T("Belajar di perpus. Sunyi, adem, wifi lumayan.", "Studying at the library. Quiet, cool, decent wifi."), {},
          SC("perpus", "seat", "sit", "read", [C("extras", "seats", "read", "sit")], hold="book"), 2.0),
        V("tutorial", T("Nonton tutorial di YouTube, kecepatan 2x. Paham!", "Watched a tutorial at 2x speed. Got it!"), {"knowledge": 0.5},
          SC("kamar", "desk", "sit", "type")),
        V("ketiduran", T("Ketiduran di atas buku. Ilmunya meresap lewat pipi?", "Fell asleep on the book. Knowledge by osmosis?"), {"knowledge": -0.6, "energy": 10},
          SC("perpus", "seat", "sit", "sleep", [C("extras", "seats", "read", "sit")])),
        V("bareng", T("Belajar bareng Nadia. Dia ngajarin, kamu manggut-manggut.", "Studied with Nadia. She explained, you nodded."), {"knowledge": 0.3, "social": 2},
          SC("perpus", "seat", "sit", "listen", [C("ambis", "seat_b", "talk", "sit")], [B("ambis", "Rumusnya gini, gampang kok!", "The formula's like this, easy!")])),
        V("kipas", T("Belajar di kos. Kipas angin berisik, tapi fokus.", "Studying in your room. The fan is loud, but you focus."), {},
          SC("kamar", "desk", "sit", "read", hold="book"), 1.5),
    ],
    "tugas": [
        V("laprak", T("Ngerjain laporan sampai jam 2 pagi.", "Writing the report until 2 a.m."), {"energy": -3},
          SC("kamar", "desk", "sit", "type"), 2.0),
        V("kelompok", T("Kerja kelompok di perpus. Cuma kamu yang kerja.", "Group work at the library. Only you are working."), {"social": 1, "mental": -2},
          SC("perpus", "seat", "sit", "type", [C("beban", "seat_b", "phone", "sit", "phone")], [B("beban", "Bagianku yang mana ya?", "Which part is mine?")])),
        V("deadline", T("Deadline 23.59, submit 23.58. Adrenalin!", "Deadline 11:59 p.m., submitted 11:58. Adrenaline!"), {"tugas": 0.4, "mental": -3},
          SC("kamar", "desk", "sit", "nervous")),
        V("lancar", T("Tugas lancar jaya. Mood bagus, kopi enak.", "Assignment went smoothly. Good mood, good coffee."), {"mental": 3},
          SC("kamar", "desk", "sit", "type")),
    ],
    "nongkrong": [
        V("gorengan", T("Nongkrong di warkop, gorengan 5 biji, ngobrol ngalor-ngidul.", "Hanging out at the warkop: five fritters, endless chatter."), {},
          SC("warkop", "bench", "sit", "laugh", [C("bestie", "bench_b", "laugh", "sit", "cup"), C("friend", "bench_c", "talk", "sit")],
             [B("bestie", "Sumpah dosennya lucu banget!", "I swear that lecturer is hilarious!")]), 2.0),
        V("ditraktir", T("Ditraktir kating yang baru gajian. Rezeki anak soleh.", "A senior who just got paid treats everyone. Blessed."), {"coins": 30, "mental": 2},
          SC("warkop", "bench", "sit", "laugh", [C("senior", "bench_b", "talk", "sit", "cup"), C("bestie", "bench_c", "laugh", "sit")],
             [B("senior", "Santai, gue yang bayar!", "Relax, it's on me!")])),
        V("curhat", T("Curhat sampai jam 1 malam. Lega banget.", "Venting until 1 a.m. Such a relief."), {"mental": 4},
          SC("warkop", "bench", "sit", "talk", [C("bestie", "bench_b", "listen", "sit", "cup")],
             [B("bestie", "Kamu nggak sendirian kok.", "You're not alone, you know.")])),
        V("remi", T("Main kartu remi. Kalah, mukanya dicoreng bedak.", "Played cards. Lost, face smeared with powder."), {"social": 2},
          SC("warkop", "bench", "sit", "laugh", [C("friend", "bench_b", "laugh", "sit"), C("beban", "bench_c", "cheer", "sit")])),
    ],
    "organisasi": [
        V("rapat", T("Rapat 4 jam. Keputusannya: rapat lagi minggu depan.", "Four-hour meeting. Decision: meet again next week."), {"mental": -2},
          SC("sekre", "seat", "sit", "listen", [C("senior", "head", "talk"), C("extras", "seats", "sleep", "sit")],
             [B("senior", "Oke, kita bahas ulang dari awal.", "Okay, let's go over it again from the top.")]), 2.0),
        V("proker", T("Proker sukses! Acara ramai, sponsor senang.", "The event was a success! Packed, sponsors happy."), {"social": 3, "mental": 3},
          SC("sekre", "head", "stand", "cheer", [C("extras", "seats", "cheer", "sit")])),
        V("proposal", T("Bikin proposal kegiatan. Revisi 6 kali dari kemahasiswaan.", "Wrote an event proposal. Six revisions from student affairs."), {"tugas": 0.3},
          SC("sekre", "seat", "sit", "type", [C("friend", "seat_b", "type", "sit")])),
    ],
    "olahraga": [
        V("jogging", T("Jogging keliling lapangan. Napas ngos-ngosan, pikiran jernih.", "Jogged around the field. Out of breath, clear mind."), {},
          SC("lapangan", "track", "stand", "run", walk=True), 2.0),
        V("futsal", T("Futsal antar jurusan. Menang 3-2!", "Inter-major futsal. Won 3-2!"), {"social": 3},
          SC("lapangan", "field", "stand", "cheer", [C("extras", "field", "cheer")])),
        V("senam", T("Senam pagi bareng ibu-ibu kompleks. Seru juga.", "Morning aerobics with the neighbourhood moms. Actually fun."), {"mental": 2},
          SC("lapangan", "field", "stand", "wave", [C("ibu_kos", "field_b", "wave")])),
    ],
    "tidur": [
        V("nyenyak", T("Tidur nyenyak 9 jam. Bangun seperti manusia baru.", "Slept nine hours. Woke up a new person."), {},
          SC("kamar", "bed", "lie", "sleep"), 2.0),
        V("karaoke", T("Tetangga kos karaokean jam 1 pagi. Tidur kurang.", "The neighbour sang karaoke at 1 a.m. Not enough sleep."), {"energy": -10, "mental": -2},
          SC("kamar", "bed", "lie", "sad", bubbles=[B("player", "Hhhh... lagu dangdut lagi...", "Ugh... dangdut again...")])),
        V("mimpi", T("Mimpi sidang skripsi. Kebangun keringetan.", "Dreamt of the thesis defense. Woke up sweating."), {"mental": -2},
          SC("kamar", "bed", "lie", "sleep")),
    ],
    "konseling": [
        V("cerita", T("Cerita ke Bu Laras. Didengarkan tanpa dihakimi.", "Talked to Bu Laras. Listened to without judgement."), {},
          SC("konseling", "chair_a", "sit", "talk", [C("konselor", "chair_b", "listen", "sit")],
             [B("konselor", "Pelan-pelan saja. Saya dengarkan.", "Take your time. I'm listening.")]), 2.0),
        V("napas", T("Belajar teknik napas 4-7-8. Badan lebih rileks.", "Learned 4-7-8 breathing. Body feels calmer."), {"energy": 4},
          SC("konseling", "chair_a", "sit", "listen", [C("konselor", "chair_b", "talk", "sit")],
             [B("konselor", "Tarik napas... tahan... buang.", "Breathe in... hold... out.")])),
    ],
    "ojol": [
        V("orderan", T("Narik ojol keliling kota. Lumayan buat makan.", "Rode around the city. Enough for food."), {},
          SC("jalan", "road", "ride", "ride", [C("extras", "pillion", "ride", "ride")]), 2.0),
        V("tip", T("Dapat penumpang baik hati, kasih tip.", "Got a kind passenger who tipped."), {"coins": 60, "mental": 2},
          SC("jalan", "road", "ride", "ride", [C("ibu_kos", "pillion", "wave", "ride")], [B("ibu_kos", "Ini buat jajan ya, Nak.", "Here's a little extra, dear.")])),
        V("bocor", T("Ban bocor di tengah jalan. Tambal ban 15 ribu.", "Flat tyre mid-ride. Patch costs 15K."), {"coins": -40, "mental": -3},
          SC("jalan", "road", "stand", "sad")),
    ],
    "garap_skripsi": [
        V("bab2", T("Nulis Bab 2. Kopi ketiga hari ini.", "Writing Chapter 2. Third coffee today."), {},
          SC("kamar", "desk", "sit", "type"), 2.0),
        V("jurnal", T("Cari jurnal Sinta. Dapat 3, yang open access cuma 1.", "Hunting for journal papers. Found three, only one open access."), {},
          SC("perpus", "seat", "sit", "read", [C("extras", "seats", "read", "sit")], hold="book")),
        V("dafpus", T("Rapiin daftar pustaka 3 jam. APA edisi 7, katanya.", "Formatting references for 3 hours. APA 7th edition, apparently."), {"mental": -2},
          SC("kamar", "desk", "sit", "nervous")),
    ],
    "kerja": [
        V("ramai", T("Shift ramai, pelanggan antre panjang.", "Busy shift, long queue."), {"energy": -3},
          SC("kafe", "counter", "stand", "type", [C("boss", "boss", "point"), C("extras", "queue", "idle")]), 2.0),
        V("ditraktir_bos", T("Bos traktir makan siang. Bos idaman.", "The boss bought lunch. Dream boss."), {"mental": 3},
          SC("kafe", "counter", "stand", "laugh", [C("boss", "boss", "talk")], [B("boss", "Makan dulu, kerja nanti!", "Eat first, work later!")])),
        V("ditegur", T("Ditegur bos karena salah kembalian.", "Scolded for giving the wrong change."), {"mental": -3},
          SC("kafe", "counter", "stand", "sad", [C("boss", "boss", "talk")], [B("boss", "Hitung lagi, ya!", "Count it again!")])),
        V("sepi", T("Shift sepi. Bisa sambil baca materi.", "Quiet shift. Got some reading done."), {"knowledge": 0.3},
          SC("kafe", "counter", "stand", "read", hold="book")),
    ],
    "kerja_home": [
        V("klien", T("Klien minta revisi \"yang simpel aja\" untuk ke-14 kali.", "The client asks for \"something simple\" for the 14th time."), {"mental": -2},
          SC("kamar", "desk", "sit", "type"), 2.0),
        V("lancar", T("Kerjaan beres lebih cepat. Rebahan sebentar.", "Work done early. Quick lie-down."), {"energy": 4},
          SC("kamar", "desk", "sit", "type")),
    ],
    "kerja_les": [
        V("les", T("Ngajarin anak SMA persamaan kuadrat. Dia paham!", "Taught a high schooler quadratic equations. They got it!"), {"mental": 2},
          SC("perpus", "seat", "sit", "talk", [C("kid", "seat_b", "write", "sit")], [B("kid", "Ohh, gitu toh Kak!", "Ohh, that's how it works!")]), 2.0),
    ],
    "kerja_asdos": [
        V("asdos", T("Jadi asdos: ngawas praktikum & koreksi laporan.", "TA duty: supervising the lab and grading reports."), {},
          SC("kelas", "front", "stand", "point", [C("extras", "seats", "write", "sit")]), 2.0),
    ],
}

# Bimbingan scenes depend on the advisor's response, not on a random variant.
BIMBINGAN_SCENES = {
    "ghost": SC("ruang_dosen", "door", "stand", "phone", hold="phone",
                bubbles=[B("player", "Pak... Bu... ada?", "Sir... Ma'am... anyone?")]),
    "dinas": SC("ruang_dosen", "door", "stand", "sad",
                bubbles=[B("player", "\"Sedang dinas luar kota.\" Lagi.", "\"Out of town.\" Again.")]),
    "revisi": SC("ruang_dosen", "guest", "sit", "sad", [C("dospem", "dosen_chair", "talk", "sit")],
                 [B("dospem", "Ganti judul ya.", "Change the title.")]),
    "acc": SC("ruang_dosen", "guest", "sit", "cheer", [C("dospem", "dosen_chair", "talk", "sit")],
              [B("dospem", "Oke, lanjut.", "Okay, continue.")]),
    "kosong": SC("ruang_dosen", "guest", "sit", "nervous", [C("dospem", "dosen_chair", "talk", "sit")],
                 [B("dospem", "Mana progresnya?", "Where's the progress?")]),
}

WEEKLY = [
    {"id": "normal", "weight": 2.0, "title": T("Minggu Biasa", "A Normal Week"),
     "text": T("Tidak ada kabar istimewa. Semangat!", "Nothing special this week. Keep going!"), "mods": {}},
    {"id": "tanggal_merah", "weight": 0.8, "when": {"not_exam": True}, "title": T("Tanggal Merah!", "Public Holiday!"),
     "text": T("Libur nasional: tidak ada kuliah pagi, kehadiran tetap dihitung.", "National holiday: no morning class, attendance still counts."),
     "no_class": True, "mods": {}},
    {"id": "kuis_dadakan", "weight": 1.0, "when": {"not_exam": True}, "title": T("Musim Kuis Dadakan", "Pop-Quiz Season"),
     "text": T("Kuliah lebih menegangkan: ilmu +50%, mental -3.", "Classes are tense: knowledge +50%, mental -3."),
     "mods": {"kuliah": {"mult": {"knowledge": 1.5}, "add": {"mental": -3}}}},
    {"id": "dosen_seminar", "weight": 0.9, "when": {"not_exam": True}, "title": T("Dosen Seminar ke Luar Negeri", "Lecturers Abroad for a Seminar"),
     "text": T("Kelas sering kosong: ilmu kuliah turun, tapi tugas resume nambah.", "Classes are often empty: less lecture knowledge, more summary homework."),
     "mods": {"kuliah": {"mult": {"knowledge": 0.4}, "add": {"tugas": 0.3, "energy": 4}}}},
    {"id": "deadline", "weight": 1.0, "title": T("Deadline Numpuk", "Deadlines Pile Up"),
     "text": T("Tugas dikejar: progres tugas +40%, tapi lebih bikin stres.", "Assignments rush: +40% task progress, but more stress."),
     "mods": {"tugas": {"mult": {"tugas": 1.4}, "add": {"mental": -2}}}},
    {"id": "promo_kopi", "weight": 0.9, "title": T("Promo Kopi Warkop", "Warkop Coffee Promo"),
     "text": T("Nongkrong gratis kopi: tanpa biaya, mental +4.", "Free coffee at the warkop: no cost, mental +4."),
     "mods": {"nongkrong": {"mult": {"coins": 0.0}, "add": {"mental": 4}}}},
    {"id": "hujan", "weight": 0.9, "title": T("Hujan Seminggu Penuh", "A Week of Rain"),
     "text": T("Ojol dapat tarif hujan (+40%), tapi olahraga & nongkrong kurang seru.", "Rides pay surge rates (+40%), but sports and hangouts are less fun."),
     "mods": {"ojol": {"mult": {"coins": 1.4}}, "olahraga": {"mult": {"mental": 0.5}}, "nongkrong": {"mult": {"mental": 0.6}}}},
    {"id": "gajian", "weight": 0.8, "when": {"job": True}, "title": T("Bonus dari Bos", "Boss Bonus"),
     "text": T("Penjualan naik! Gaji shift minggu ini +25%.", "Sales are up! Shift pay +25% this week."),
     "mods": {"kerja": {"mult": {"coins": 1.25}}}},
    {"id": "festival", "weight": 0.8, "title": T("Festival Kampus", "Campus Festival"),
     "text": T("Organisasi sibuk tapi seru: sosial +50%, energi -5.", "Orgs are busy but fun: social +50%, energy -5."),
     "mods": {"organisasi": {"mult": {"social": 1.5}, "add": {"energy": -5}}}},
    {"id": "flu", "weight": 0.7, "title": T("Flu Menyebar di Kos", "Flu Spreads in the Kos"),
     "text": T("Pemulihan energi minggu ini berkurang. Tidur lebih penting.", "Less energy recovery this week. Sleep matters more."),
     "energy_regen": -10, "mods": {"tidur": {"add": {"energy": 8}}}},
    {"id": "listrik", "weight": 0.7, "title": T("Listrik Kos Padam Bergilir", "Rolling Blackouts at the Kos"),
     "text": T("Ngerjain tugas di kos susah (-30%). Perpus aman.", "Doing assignments at home is hard (-30%). The library is fine."),
     "mods": {"tugas": {"mult": {"tugas": 0.7}}, "belajar": {"add": {"knowledge": 0.3}}}},
    {"id": "seminar_gratis", "weight": 0.8, "title": T("Seminar Gratis + Sertifikat", "Free Seminar + Certificate"),
     "text": T("Belajar minggu ini lebih efektif (+0,5 ilmu).", "Studying is more effective this week (+0.5 knowledge)."),
     "mods": {"belajar": {"add": {"knowledge": 0.5}}}},
    {"id": "tanggal_tua", "weight": 0.9, "title": T("Tanggal Tua", "End-of-Month Broke"),
     "text": T("Dompet tipis, mie instan menu utama. Nongkrong lebih mahal terasa.", "Wallet's thin, instant noodles for every meal. Hanging out stings more."),
     "mods": {"nongkrong": {"mult": {"coins": 1.5}}, "ojol": {"add": {"coins": 20}}}},
]

out = os.path.join(os.path.dirname(__file__), "..", "data", "activities.json")
json.dump({"variants": VARIANTS, "bimbingan": BIMBINGAN_SCENES, "weekly": WEEKLY}, open(out, "w"), ensure_ascii=False, indent=1)
print(sum(len(v) for v in VARIANTS.values()), "variants,", len(WEEKLY), "weekly modifiers")
