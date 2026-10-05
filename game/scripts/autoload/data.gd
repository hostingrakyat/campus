extends Node
## Static game content and balance numbers. Text is always a {"id", "en"} pair.

const WEEKS_PER_SEMESTER := 12
const EXAM_WEEKS := [6, 12]
const MAX_SEMESTER := 14
const SKS_TO_GRADUATE := 144
const SLOTS := ["pagi", "siang", "malam", "weekend"]

# --- Balance -----------------------------------------------------------------
const ENERGY_REGEN := 28
const SOCIAL_DECAY := 2
const WEEKEND_MENTAL := 3
const FOOD_PER_WEEK := 120
const KOS_PER_MONTH := 500
const TARGET_KNOWLEDGE := 20.0
const TARGET_TUGAS := 15.0
const ATTENDANCE_MIN := 0.75
const MENTAL_WARNING := 25
const PHK_ALLOWANCE := 400
const CUTI_EARNINGS := 4200
const MAX_CUTI := 2
const PINJOL_RATE := 1.5
const DIAMOND_TO_COIN := {"diamonds": 10, "coins": 500}

const SLOT_NAMES := {
	"pagi": {"id": "Pagi", "en": "Morning"},
	"siang": {"id": "Siang", "en": "Afternoon"},
	"malam": {"id": "Malam", "en": "Night"},
	"weekend": {"id": "Akhir Pekan", "en": "Weekend"},
}

const PRODI := {
	"IF": {
		"name": {"id": "Informatika", "en": "Computer Science"},
		"tag": {"id": "Ngoding sampai subuh, debug sampai lupa mandi.", "en": "Code till dawn, debug till you forget to shower."},
		"ukt": 6500, "allowance": 1500, "diff": 1.0, "color": Color("2f6bff"),
	},
	"MN": {
		"name": {"id": "Manajemen", "en": "Management"},
		"tag": {"id": "Presentasi tiap minggu, networking tiap hari.", "en": "Presentations weekly, networking daily."},
		"ukt": 5500, "allowance": 1500, "diff": 0.92, "color": Color("ff9f1c"),
	},
	"KD": {
		"name": {"id": "Kedokteran", "en": "Medicine"},
		"tag": {"id": "Blok demi blok. Tidur itu mitos.", "en": "Block after block. Sleep is a myth."},
		"ukt": 14000, "allowance": 2000, "diff": 1.05, "color": Color("33c47a"),
	},
}

# Grade table used across Indonesian universities (A/AB/B/BC/C/D/E).
const GRADES := [
	{"letter": "A", "min": 80, "point": 4.0},
	{"letter": "AB", "min": 74, "point": 3.5},
	{"letter": "B", "min": 67, "point": 3.0},
	{"letter": "BC", "min": 60, "point": 2.5},
	{"letter": "C", "min": 52, "point": 2.0},
	{"letter": "D", "min": 44, "point": 1.0},
	{"letter": "E", "min": -999, "point": 0.0},
]

# --- Weekly actions -------------------------------------------------------------
# fx keys: energy, mental, social, coins, knowledge, tugas, attend, rel
const ACTIONS := {
	"kuliah": {
		"slots": ["pagi"], "loc": "fakultas", "icon": "K",
		"name": {"id": "Kuliah", "en": "Attend Class"},
		"desc": {"id": "Hadir & absen. Minimal 75% kehadiran buat ikut UAS.", "en": "Show up & sign in. 75% attendance needed to sit the final."},
		"fx": {"energy": -12, "mental": -2, "knowledge": 0.6, "tugas": 0.2, "attend": 1},
	},
	"ujian": {
		"slots": ["pagi"], "loc": "fakultas", "icon": "U", "forced": true,
		"name": {"id": "Ujian", "en": "Exam"},
		"desc": {"id": "UTS/UAS. Nggak bisa dihindari.", "en": "Midterm/final. Unavoidable."},
		"fx": {"energy": -15, "mental": -6, "attend": 1},
	},
	"bolos": {
		"slots": ["pagi"], "loc": "kos", "icon": "Z",
		"name": {"id": "Bolos & Rebahan", "en": "Skip & Lie Down"},
		"desc": {"id": "Enak sih. Absen bolong tapi.", "en": "Feels great. Attendance doesn't."},
		"fx": {"energy": 18, "mental": 4},
	},
	"belajar": {
		"slots": ["pagi", "siang", "malam", "weekend"], "loc": "perpus", "icon": "B",
		"name": {"id": "Belajar", "en": "Study"},
		"desc": {"id": "Baca materi, latihan soal. Nambah pemahaman.", "en": "Read, practice problems. Builds understanding."},
		"fx": {"energy": -15, "mental": -4, "knowledge": 1.5},
	},
	"tugas": {
		"slots": ["siang", "malam", "weekend"], "loc": "kos", "icon": "T",
		"name": {"id": "Ngerjain Tugas", "en": "Do Assignments"},
		"desc": {"id": "Laporan, makalah, tugas kelompok (yang dikerjain sendiri).", "en": "Reports, papers, group work (done alone)."},
		"fx": {"energy": -15, "mental": -4, "tugas": 1.5},
	},
	"nongkrong": {
		"slots": ["siang", "malam", "weekend"], "loc": "warkop", "icon": "N",
		"name": {"id": "Nongkrong di Warkop", "en": "Hang Out at Warkop"},
		"desc": {"id": "Kopi, gorengan, curhat. Mental & sosial naik.", "en": "Coffee, fritters, venting. Mental & social up."},
		"fx": {"energy": -5, "mental": 12, "social": 6, "coins": -30},
	},
	"organisasi": {
		"slots": ["siang", "malam", "weekend"], "loc": "lapangan", "icon": "O",
		"name": {"id": "Rapat Organisasi", "en": "Org Meeting"},
		"desc": {"id": "Rapat sampai malam. Relasi & sosial naik.", "en": "Meetings till late. Network & social up."},
		"fx": {"energy": -10, "mental": 3, "social": 8, "rel": 1},
	},
	"olahraga": {
		"slots": ["pagi", "siang", "weekend"], "loc": "lapangan", "icon": "L",
		"name": {"id": "Olahraga", "en": "Exercise"},
		"desc": {"id": "Lari keliling lapangan. Mental lebih jernih.", "en": "Jog around the field. Clearer mind."},
		"fx": {"energy": -8, "mental": 9},
	},
	"tidur": {
		"slots": ["pagi", "siang", "malam", "weekend"], "loc": "kos", "icon": "S",
		"name": {"id": "Tidur Cukup", "en": "Proper Sleep"},
		"desc": {"id": "Recharge energi. Bukan kemalasan, ini investasi.", "en": "Recharge energy. Not laziness — investment."},
		"fx": {"energy": 40, "mental": 6},
	},
	"konseling": {
		"slots": ["siang"], "loc": "rektorat", "icon": "C",
		"name": {"id": "Konseling Kampus", "en": "Campus Counseling"},
		"desc": {"id": "Gratis di UPT Konseling. Cerita itu bukan lemah.", "en": "Free at the counseling unit. Talking isn't weakness."},
		"fx": {"mental": 22, "energy": 2},
	},
	"ojol": {
		"slots": ["pagi", "siang", "malam", "weekend"], "loc": "jalan", "icon": "J",
		"name": {"id": "Narik Ojol", "en": "Ride-hailing Gig"},
		"desc": {"id": "Fleksibel, capek, lumayan buat makan.", "en": "Flexible, tiring, pays for food."},
		"fx": {"energy": -18, "mental": -4, "coins": 170},
	},
	"kerja": {
		"slots": [], "loc": "kafe", "icon": "W",
		"name": {"id": "Kerja Part-time", "en": "Part-time Shift"},
		"desc": {"id": "Shift dari kerjaan kamu.", "en": "Your job's shift."},
		"fx": {},
	},
	"garap_skripsi": {
		"slots": ["pagi", "siang", "malam", "weekend"], "loc": "perpus", "icon": "D", "needs": "skripsi",
		"name": {"id": "Garap Skripsi", "en": "Write Thesis"},
		"desc": {"id": "Nambah draf. Nanti tetap harus di-ACC dospem.", "en": "Grow the draft. Still needs advisor approval."},
		"fx": {"energy": -15, "mental": -5},
	},
	"bimbingan": {
		"slots": ["siang"], "loc": "fakultas", "icon": "P", "needs": "skripsi",
		"name": {"id": "Bimbingan Dospem", "en": "Advisor Meeting"},
		"desc": {"id": "Minta ACC. Kalau dosennya ada. Kalau dibalas.", "en": "Ask for approval. If they're there. If they reply."},
		"fx": {"energy": -8, "mental": -6},
	},
}

# --- Part-time jobs (one contract at a time, fixed slot) ---------------------
## Free exploration: coins lying around campus each week.
const EXPLORE_COIN := 15
const EXPLORE_COINS_PER_WEEK := 4

const JOBS := {
	"barista": {
		"slot": "pagi", "pay": 340, "energy": -16, "mental": -3, "loc": "kafe",
		"name": {"id": "Barista Kopi Kekinian", "en": "Trendy Coffee Barista"},
		"desc": {"id": "Gaji gede, tapi shift pagi = BENTROK sama kuliah.", "en": "Good pay, but the morning shift CLASHES with class."},
	},
	"minimarket": {
		"slot": "malam", "pay": 290, "energy": -22, "mental": -6, "loc": "minimarket",
		"name": {"id": "Kasir Minimarket Shift Malam", "en": "Night-shift Convenience Store Cashier"},
		"desc": {"id": "Aman dari jadwal kuliah. Kantuk tidak aman.", "en": "Safe from class schedule. Not safe from sleepiness."},
	},
	"les": {
		"slot": "siang", "pay": 330, "energy": -14, "mental": -2, "loc": "jalan", "min_ipk": 3.0, "min_sem": 2,
		"name": {"id": "Guru Les Privat", "en": "Private Tutor"},
		"desc": {"id": "Ngajarin anak SMA. Butuh IPK minimal 3.00.", "en": "Tutor high schoolers. Needs GPA 3.00+."},
	},
	"admin_olshop": {
		"slot": "malam", "pay": 260, "energy": -12, "mental": -4, "loc": "kos",
		"name": {"id": "Admin Olshop", "en": "Online Shop Admin"},
		"desc": {"id": "Balas chat \"kak, ready?\" ratusan kali.", "en": "Reply \"is this in stock?\" hundreds of times."},
	},
	"freelance_dev": {
		"slot": "malam", "pay": 460, "energy": -20, "mental": -7, "loc": "kos", "prodi": "IF", "min_sem": 3,
		"name": {"id": "Freelance Bikin Website", "en": "Freelance Web Developer"},
		"desc": {"id": "Klien minta \"yang simpel aja\", revisi 14 kali.", "en": "Client wants \"something simple\", 14 revisions."},
	},
	"jaga_apotek": {
		"slot": "malam", "pay": 320, "energy": -18, "mental": -4, "loc": "minimarket", "prodi": "KD", "min_sem": 3,
		"name": {"id": "Jaga Apotek Malam", "en": "Night Pharmacy Assistant"},
		"desc": {"id": "Sambil hafalan nama obat.", "en": "Memorize drug names on the job."},
	},
	"asdos": {
		"slot": "siang", "pay": 200, "energy": -10, "mental": -2, "loc": "fakultas", "min_ipk": 3.25, "min_sem": 3, "rel": 2,
		"name": {"id": "Asisten Dosen", "en": "Teaching Assistant"},
		"desc": {"id": "Gaji kecil, relasi dosen besar. Butuh IPK 3.25.", "en": "Small pay, big faculty network. Needs GPA 3.25."},
	},
}

# --- Cosmetics -----------------------------------------------------------------
# slot: hair | top | head | face | back | aura. price_c = coins, price_d = diamonds.
const ITEMS := {
	"hair_short": {"slot": "hair", "price_c": 0, "name": {"id": "Rambut Pendek", "en": "Short Hair"}},
	"hair_fringe": {"slot": "hair", "price_c": 0, "name": {"id": "Rambut Poni", "en": "Fringe"}},
	"hair_long": {"slot": "hair", "price_c": 0, "name": {"id": "Rambut Panjang", "en": "Long Hair"}},
	"hair_hijab": {"slot": "hair", "price_c": 0, "name": {"id": "Hijab", "en": "Hijab"}},
	"hair_buzz": {"slot": "hair", "price_c": 0, "name": {"id": "Cepak", "en": "Buzz Cut"}},
	"hair_curly": {"slot": "hair", "price_c": 250, "name": {"id": "Rambut Keriting", "en": "Curly Hair"}},
	"top_tee": {"slot": "top", "price_c": 0, "color": Color("f4f1ea"), "name": {"id": "Kaos Polos", "en": "Plain Tee"}},
	"top_almamater": {"slot": "top", "price_c": 0, "color": Color("2f6bff"), "almamater": true, "name": {"id": "Jaket Almamater", "en": "Campus Jacket"}},
	"top_flanel": {"slot": "top", "price_c": 450, "color": Color("c8423b"), "pattern": "flanel", "name": {"id": "Kemeja Flanel", "en": "Flannel Shirt"}},
	"top_hoodie_ungu": {"slot": "top", "price_c": 700, "color": Color("7b5cff"), "hood": true, "name": {"id": "Hoodie Ungu", "en": "Purple Hoodie"}},
	"top_batik": {"slot": "top", "price_c": 900, "color": Color("8a5a2b"), "pattern": "batik", "name": {"id": "Kemeja Batik", "en": "Batik Shirt"}},
	"top_varsity": {"slot": "top", "price_c": 1200, "color": Color("1d2a4d"), "name": {"id": "Jaket Varsity", "en": "Varsity Jacket"}},
	"top_snelli": {"slot": "top", "price_c": 600, "color": Color("fbfbfb"), "name": {"id": "Jas Lab / Snelli", "en": "Lab Coat"}},
	"top_hoodie_gold": {"slot": "top", "price_d": 120, "color": Color("ffc83d"), "hood": true, "premium": true, "name": {"id": "Hoodie Sigma Emas", "en": "Golden Sigma Hoodie"}},
	# NPC-only wardrobe (never sold; "npc" keeps them out of the shop).
	"top_pns": {"slot": "top", "npc": true, "color": Color("c3a46b"), "name": {"id": "Seragam Staf", "en": "Staff Uniform"}},
	"top_daster": {"slot": "top", "npc": true, "color": Color("e85d75"), "pattern": "batik", "name": {"id": "Daster", "en": "House Dress"}},
	"top_apron": {"slot": "top", "npc": true, "color": Color("2f5d50"), "name": {"id": "Apron", "en": "Apron"}},
	"top_cardigan": {"slot": "top", "npc": true, "color": Color("8fb996"), "name": {"id": "Kardigan", "en": "Cardigan"}},
	"top_ojol": {"slot": "top", "npc": true, "color": Color("1fa463"), "name": {"id": "Jaket Ojol", "en": "Rider Jacket"}},
	"head_helm": {"slot": "head", "npc": true, "color": Color("1fa463"), "name": {"id": "Helm", "en": "Helmet"}},
	"head_none": {"slot": "head", "price_c": 0, "name": {"id": "Tanpa Topi", "en": "No Hat"}},
	"head_bucket": {"slot": "head", "price_c": 350, "color": Color("e9d8a6"), "name": {"id": "Topi Bucket", "en": "Bucket Hat"}},
	"head_cap": {"slot": "head", "price_c": 300, "color": Color("ff5a4e"), "name": {"id": "Topi Baseball", "en": "Baseball Cap"}},
	"head_peci": {"slot": "head", "price_c": 250, "color": Color("1a1420"), "name": {"id": "Peci", "en": "Peci Cap"}},
	"head_toga": {"slot": "head", "price_d": 80, "color": Color("1a1420"), "premium": true, "name": {"id": "Topi Toga (Halu Duluan)", "en": "Grad Cap (Manifesting)"}},
	"face_none": {"slot": "face", "price_c": 0, "name": {"id": "Tanpa Kacamata", "en": "No Glasses"}},
	"face_round": {"slot": "face", "price_c": 300, "name": {"id": "Kacamata Bulat", "en": "Round Glasses"}},
	"face_shades": {"slot": "face", "price_d": 60, "premium": true, "name": {"id": "Kacamata Hitam Sigma", "en": "Sigma Shades"}},
	"back_none": {"slot": "back", "price_c": 0, "name": {"id": "Tanpa Tas", "en": "No Bag"}},
	"back_ransel": {"slot": "back", "price_c": 400, "color": Color("33c47a"), "name": {"id": "Tas Ransel", "en": "Backpack"}},
	"back_tote": {"slot": "back", "price_c": 280, "color": Color("f2e2c4"), "name": {"id": "Tote Bag Estetik", "en": "Aesthetic Tote Bag"}},
	"aura_none": {"slot": "aura", "price_c": 0, "name": {"id": "Tanpa Aura", "en": "No Aura"}},
	"aura_sigma": {"slot": "aura", "price_d": 200, "premium": true, "name": {"id": "Aura Sigma", "en": "Sigma Aura"}},
}
const DEFAULT_LOOK := {
	"skin": 1, "hair": "hair_short", "hair_color": 0, "top": "top_almamater",
	"head": "head_none", "face": "face_none", "back": "back_none", "aura": "aura_none",
}
const SKIN_TONES := [Color("f6d7b8"), Color("e8b98f"), Color("c98f63"), Color("a36a43"), Color("70462c")]
const HAIR_COLORS := [Color("231c2b"), Color("4a2f22"), Color("8a5a3c"), Color("d9d2c3"), Color("e85d75"), Color("3c6e71")]

const CONSUMABLES := {
	"kopi_sachet": {"price_c": 25, "fx": {"energy": 18}, "name": {"id": "Kopi Sachet", "en": "Instant Coffee"}},
	"es_kopi_aren": {"price_c": 45, "fx": {"energy": 28, "mental": 4}, "name": {"id": "Es Kopi Gula Aren", "en": "Palm Sugar Iced Coffee"}},
	"nasi_padang": {"price_c": 35, "fx": {"energy": 12, "mental": 6}, "name": {"id": "Nasi Padang", "en": "Padang Rice"}},
	"energy_drink": {"price_d": 10, "fx": {"energy": 60}, "name": {"id": "Minuman Energi Premium", "en": "Premium Energy Drink"}},
}

const IAP_PRODUCTS := {
	"diamonds_60": {"diamonds": 60, "price": "Rp 15.000", "name": {"id": "Segenggam Diamond", "en": "Handful of Diamonds"}},
	"diamonds_250": {"diamonds": 250, "price": "Rp 49.000", "name": {"id": "Sekantong Diamond", "en": "Bag of Diamonds"}},
	"diamonds_600": {"diamonds": 600, "price": "Rp 99.000", "name": {"id": "Sekoper Diamond", "en": "Suitcase of Diamonds"}},
	"starter_maba": {"diamonds": 100, "price": "Rp 9.000", "once": true, "item": "top_hoodie_gold", "name": {"id": "Paket Maba (sekali beli)", "en": "Freshman Pack (one-time)"}},
	"no_ads": {"diamonds": 0, "price": "Rp 29.000", "once": true, "no_ads": true, "name": {"id": "Hapus Iklan Interstitial", "en": "Remove Interstitial Ads"}},
}
const REWARDED_DIAMONDS := 5
const REWARDED_DAILY_CAP := 8
## One-time thank-you for following the studio on TikTok (trust-based: granted on tap).
const TIKTOK_URL := "https://www.tiktok.com/@hostingrakyat"
const TIKTOK_HANDLE := "@hostingrakyat"
const TIKTOK_DIAMONDS := 20

# --- NPCs (all fictional) ------------------------------------------------------
const NPCS := {
	"senior": {"name": "Bang Jarwo", "role": {"id": "Kating Semester 13", "en": "13th-Semester Senior"}, "color": Color("ff9f1c")},
	"dosen_read": {"name": "Pak Haryo, M.Kom.", "role": {"id": "Dosen \"Read Doang\"", "en": "The \"Left-on-Read\" Lecturer"}, "color": Color("5b6c8f")},
	"dosen_revisi": {"name": "Dr. Ratna Revisiana", "role": {"id": "Dosen Revisi Abadi", "en": "The Eternal-Revision Lecturer"}, "color": Color("c8423b")},
	"dosen_dinas": {"name": "Prof. Bambang Dinasputra", "role": {"id": "Dosen yang Selalu Dinas", "en": "The Always-Away Professor"}, "color": Color("3c6e71")},
	"dosen_buku": {"name": "Dr. Sutomo Bukuwijaya", "role": {"id": "Dosen Penulis Buku Wajib", "en": "The Mandatory-Textbook Author"}, "color": Color("8a5a2b")},
	"dosen_killer": {"name": "Dr. Killiana Tepatwaktu", "role": {"id": "Dosen Killer", "en": "The Strict Lecturer"}, "color": Color("1a1420")},
	"tu": {"name": "Pak Darto", "role": {"id": "Staf Tata Usaha", "en": "Admin Office Staff"}, "color": Color("6c757d")},
	"siakad": {"name": "SIAKAD", "role": {"id": "Sistem Informasi Akademik", "en": "Academic Information System"}, "color": Color("2f6bff")},
	"ibu": {"name": "Ibu", "role": {"id": "Ibu di Kampung", "en": "Mom back home"}, "color": Color("e85d75")},
	"ayah": {"name": "Ayah", "role": {"id": "Ayah di Kampung", "en": "Dad back home"}, "color": Color("4a2f22")},
	"ambis": {"name": "Nadia", "role": {"id": "Si Ambis Kelas", "en": "The Overachiever"}, "color": Color("7b5cff")},
	"beban": {"name": "Dimas", "role": {"id": "Teman Kelompok Ghaib", "en": "The Phantom Groupmate"}, "color": Color("9aa5b1")},
	"bestie": {"name": "Sari", "role": {"id": "Bestie Sejak Ospek", "en": "Bestie Since Orientation"}, "color": Color("ff6b9a")},
	"ibu_kos": {"name": "Bu Endang", "role": {"id": "Ibu Kos", "en": "Landlady"}, "color": Color("33c47a")},
	"bos": {"name": "Mas Bram", "role": {"id": "Bos Part-time", "en": "Part-time Boss"}, "color": Color("1d2a4d")},
	"pinjol": {"name": "DanaKilat", "role": {"id": "Aplikasi Pinjaman (fiktif)", "en": "Loan App (fictional)"}, "color": Color("ff5a4e")},
	"konselor": {"name": "Bu Laras", "role": {"id": "Konselor Kampus", "en": "Campus Counselor"}, "color": Color("33c47a")},
	"dekan": {"name": "Pak Dekan", "role": {"id": "Dekan Fakultas", "en": "Dean of Faculty"}, "color": Color("1d2a4d")},
	"kades": {"name": "Pak Kades", "role": {"id": "Kepala Desa Lokasi KKN", "en": "KKN Village Head"}, "color": Color("4a2f22")},
	"narator": {"name": "", "role": {"id": "", "en": ""}, "color": Color("2a2238")},
}

const DOSPEM_POOL := ["dosen_read", "dosen_revisi", "dosen_dinas"]
const LECTURERS := ["dosen_read", "dosen_revisi", "dosen_dinas", "dosen_buku", "dosen_killer"]

## How each NPC looks as a 3D vinyl character in cutscenes and activity scenes.
const NPC_LOOKS := {
	"senior": {"skin": 2, "hair": "hair_long", "hair_color": 0, "top": "top_flanel", "back": "back_ransel"},
	"dosen_read": {"skin": 1, "hair": "hair_buzz", "hair_color": 3, "top": "top_batik", "face": "face_round"},
	"dosen_revisi": {"skin": 1, "hair": "hair_hijab", "hair_color": 5, "top": "top_batik", "face": "face_round"},
	"dosen_dinas": {"skin": 2, "hair": "hair_buzz", "hair_color": 3, "top": "top_varsity", "face": "face_shades", "back": "back_tote"},
	"dosen_buku": {"skin": 3, "hair": "hair_short", "hair_color": 3, "top": "top_batik", "face": "face_round", "head": "head_peci"},
	"dosen_killer": {"skin": 0, "hair": "hair_long", "hair_color": 0, "top": "top_varsity", "face": "face_round"},
	"tu": {"skin": 3, "hair": "hair_buzz", "hair_color": 0, "top": "top_pns"},
	"ibu": {"skin": 2, "hair": "hair_hijab", "hair_color": 1, "top": "top_daster"},
	"ayah": {"skin": 3, "hair": "hair_short", "hair_color": 3, "top": "top_batik", "head": "head_peci"},
	"ambis": {"skin": 0, "hair": "hair_fringe", "hair_color": 0, "top": "top_almamater", "face": "face_round", "back": "back_ransel"},
	"beban": {"skin": 2, "hair": "hair_curly", "hair_color": 0, "top": "top_hoodie_ungu", "head": "head_cap"},
	"bestie": {"skin": 1, "hair": "hair_hijab", "hair_color": 5, "top": "top_tee", "back": "back_tote"},
	"ibu_kos": {"skin": 2, "hair": "hair_curly", "hair_color": 3, "top": "top_daster"},
	"bos": {"skin": 1, "hair": "hair_short", "hair_color": 0, "top": "top_apron", "head": "head_cap"},
	"konselor": {"skin": 1, "hair": "hair_hijab", "hair_color": 2, "top": "top_cardigan"},
	"dekan": {"skin": 2, "hair": "hair_buzz", "hair_color": 3, "top": "top_varsity", "face": "face_round", "head": "head_peci"},
	"kades": {"skin": 3, "hair": "hair_short", "hair_color": 0, "top": "top_batik", "head": "head_peci"},
	"ojol": {"skin": 3, "hair": "hair_short", "hair_color": 0, "top": "top_ojol", "head": "head_helm"},
}

# --- Endings -------------------------------------------------------------------
const ENDINGS := ["summa", "balance", "cumlaude", "tepat", "telat", "abadi", "do", "pindah", "rawat", "padam"]

var curriculum: Dictionary = {}
var events: Array = []
var endings: Dictionary = {}
var activities: Dictionary = {}


func _ready() -> void:
	curriculum = _load_json("res://data/curriculum.json")
	events = _load_json("res://data/events.json")
	endings = _load_json("res://data/endings.json")
	activities = _load_json("res://data/activities.json")


func _load_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cannot open " + path)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed == null:
		push_error("Invalid JSON in " + path)
		return {}
	return parsed


func grade_for(score: float) -> Dictionary:
	for g in GRADES:
		if score >= g.min:
			return g
	return GRADES[-1]


func item_color(item_id: String, prodi: String) -> Color:
	var it: Dictionary = ITEMS.get(item_id, {})
	if it.get("almamater", false):
		return PRODI[prodi].color
	return it.get("color", Color.WHITE)
