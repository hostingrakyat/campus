class_name MiniGames
extends RefCounted
## Content and rules for the interactive moments inside weekly activities: which mini-game an
## activity gets (with some randomness so weeks differ), and the small bonus a good score earns.
## Pure functions over the run state, like Sim.

const D := preload("res://scripts/autoload/data.gd")

## Kinds: catch (tap the good bubbles, avoid the bad ones), timing (stop the needle in the zone),
## mash (tap fast to fill), quiz (one right answer), chat (pick the best reply).

const QUIZ_GENERAL := [
	{"q": {"id": "1 SKS tatap muka itu kira-kira berapa lama per minggu?", "en": "Roughly how long is 1 credit (SKS) of class time per week?"},
		"a": [{"id": "50 menit", "en": "50 minutes"}, {"id": "3 jam", "en": "3 hours"}, {"id": "Sesuka dosen", "en": "Whatever the lecturer feels like"}]},
	{"q": {"id": "IPK tertinggi di kampus Indonesia?", "en": "Highest possible GPA at Indonesian campuses?"},
		"a": [{"id": "4,00", "en": "4.00"}, {"id": "5,00", "en": "5.00"}, {"id": "100", "en": "100"}]},
	{"q": {"id": "KRS itu singkatan dari?", "en": "What does KRS stand for?"},
		"a": [{"id": "Kartu Rencana Studi", "en": "Study Plan Card"}, {"id": "Kartu Rekap Semester", "en": "Semester Recap Card"}, {"id": "Kumpulan Revisi Skripsi", "en": "Thesis Revision Pile"}]},
	{"q": {"id": "UKT singkatan dari?", "en": "What does UKT stand for?"},
		"a": [{"id": "Uang Kuliah Tunggal", "en": "Single Tuition Fee"}, {"id": "Uang Kos Tahunan", "en": "Yearly Rent Money"}, {"id": "Utang Kantin Terus", "en": "Endless Canteen Debt"}]},
	{"q": {"id": "Tri Dharma Perguruan Tinggi: pendidikan, penelitian, dan...", "en": "The three duties of higher education: teaching, research and..."},
		"a": [{"id": "Pengabdian masyarakat", "en": "Community service"}, {"id": "Penagihan UKT", "en": "Collecting tuition"}, {"id": "Rapat koordinasi", "en": "Coordination meetings"}]},
	{"q": {"id": "Cek plagiarisme skripsi biasanya pakai?", "en": "Thesis plagiarism checks usually use?"},
		"a": [{"id": "Turnitin", "en": "Turnitin"}, {"id": "Tinder", "en": "Tinder"}, {"id": "Tokopedia", "en": "Tokopedia"}]},
	{"q": {"id": "Predikat cum laude biasanya butuh IPK di atas?", "en": "Cum laude usually needs a GPA above?"},
		"a": [{"id": "3,50", "en": "3.50"}, {"id": "2,75", "en": "2.75"}, {"id": "3,00", "en": "3.00"}]},
	{"q": {"id": "KKN singkatan dari?", "en": "What does KKN stand for?"},
		"a": [{"id": "Kuliah Kerja Nyata", "en": "Community Service Program"}, {"id": "Kuliah Kurang Niat", "en": "Half-Hearted Lectures"}, {"id": "Kumpul Kebo Nasional", "en": "National Hangout Club"}]},
	{"q": {"id": "Hasil nilai satu semester dilihat di?", "en": "Where do you see a semester's grades?"},
		"a": [{"id": "KHS", "en": "KHS (Study Results Card)"}, {"id": "KTP", "en": "KTP (ID card)"}, {"id": "Story dosen", "en": "The lecturer's Instagram story"}]},
	{"q": {"id": "Daftar pustaka skripsi paling sering pakai gaya?", "en": "Most common citation style in theses?"},
		"a": [{"id": "APA", "en": "APA"}, {"id": "Asal copas", "en": "Copy-paste freestyle"}, {"id": "Screenshot", "en": "Screenshots"}]},
	{"q": {"id": "Minimal kehadiran supaya boleh ikut UAS?", "en": "Minimum attendance to sit the final exam?"},
		"a": [{"id": "75%", "en": "75%"}, {"id": "10%", "en": "10%"}, {"id": "Asal titip absen", "en": "Just ask a friend to sign in"}]},
]

const QUIZ_PRODI := {
	"IF": [
		{"q": {"id": "Kompleksitas binary search?", "en": "Time complexity of binary search?"},
			"a": [{"id": "O(log n)", "en": "O(log n)"}, {"id": "O(n)", "en": "O(n)"}, {"id": "O(n²)", "en": "O(n²)"}]},
		{"q": {"id": "Bahasa untuk query database relasional?", "en": "Language for querying relational databases?"},
			"a": [{"id": "SQL", "en": "SQL"}, {"id": "HTML", "en": "HTML"}, {"id": "CSS", "en": "CSS"}]},
		{"q": {"id": "1 byte = berapa bit?", "en": "1 byte = how many bits?"},
			"a": [{"id": "8", "en": "8"}, {"id": "10", "en": "10"}, {"id": "16", "en": "16"}]},
		{"q": {"id": "Struktur data LIFO (terakhir masuk, pertama keluar)?", "en": "Which data structure is LIFO?"},
			"a": [{"id": "Stack", "en": "Stack"}, {"id": "Queue", "en": "Queue"}, {"id": "Tree", "en": "Tree"}]},
		{"q": {"id": "HTTP 404 artinya?", "en": "HTTP 404 means?"},
			"a": [{"id": "Not Found", "en": "Not Found"}, {"id": "OK", "en": "OK"}, {"id": "Dosen tidak di tempat", "en": "Lecturer is out"}]},
		{"q": {"id": "Biner 101 = desimal?", "en": "Binary 101 = decimal?"},
			"a": [{"id": "5", "en": "5"}, {"id": "3", "en": "3"}, {"id": "101", "en": "101"}]},
	],
	"MN": [
		{"q": {"id": "Dalam analisis SWOT, S artinya?", "en": "In a SWOT analysis, S stands for?"},
			"a": [{"id": "Strengths", "en": "Strengths"}, {"id": "Sales", "en": "Sales"}, {"id": "Santai", "en": "Chill"}]},
		{"q": {"id": "Marketing mix 4P: Product, Price, Place, dan...", "en": "The 4Ps: Product, Price, Place and..."},
			"a": [{"id": "Promotion", "en": "Promotion"}, {"id": "Profit", "en": "Profit"}, {"id": "Pinjol", "en": "Payday loans"}]},
		{"q": {"id": "Aset = Liabilitas + ...", "en": "Assets = Liabilities + ..."},
			"a": [{"id": "Ekuitas", "en": "Equity"}, {"id": "Pendapatan", "en": "Revenue"}, {"id": "Diskon", "en": "Discounts"}]},
		{"q": {"id": "BEP singkatan dari?", "en": "What does BEP stand for?"},
			"a": [{"id": "Break Even Point", "en": "Break Even Point"}, {"id": "Bisnis Erat Pertemanan", "en": "Business Between Friends"}, {"id": "Bonus End Period", "en": "Bonus End Period"}]},
		{"q": {"id": "ROI mengukur?", "en": "ROI measures?"},
			"a": [{"id": "Imbal hasil investasi", "en": "Return on an investment"}, {"id": "Jumlah karyawan", "en": "Headcount"}, {"id": "Rating ojol", "en": "Ride-hailing rating"}]},
	],
	"KD": [
		{"q": {"id": "Sel darah yang membawa oksigen?", "en": "Which blood cells carry oxygen?"},
			"a": [{"id": "Eritrosit", "en": "Erythrocytes"}, {"id": "Leukosit", "en": "Leukocytes"}, {"id": "Trombosit", "en": "Platelets"}]},
		{"q": {"id": "Tulang terpanjang pada manusia?", "en": "Longest bone in the human body?"},
			"a": [{"id": "Femur", "en": "Femur"}, {"id": "Tibia", "en": "Tibia"}, {"id": "Humerus", "en": "Humerus"}]},
		{"q": {"id": "Jumlah ruang jantung manusia?", "en": "How many chambers does the human heart have?"},
			"a": [{"id": "4", "en": "4"}, {"id": "2", "en": "2"}, {"id": "6", "en": "6"}]},
		{"q": {"id": "Hormon yang menurunkan gula darah?", "en": "Which hormone lowers blood sugar?"},
			"a": [{"id": "Insulin", "en": "Insulin"}, {"id": "Adrenalin", "en": "Adrenaline"}, {"id": "Melatonin", "en": "Melatonin"}]},
		{"q": {"id": "Tekanan darah normal orang dewasa kira-kira?", "en": "Normal adult blood pressure is about?"},
			"a": [{"id": "120/80 mmHg", "en": "120/80 mmHg"}, {"id": "200/150 mmHg", "en": "200/150 mmHg"}, {"id": "60/20 mmHg", "en": "60/20 mmHg"}]},
	],
}

## Reply choices; "s" is the score each reply earns.
const CHATS := {
	"nongkrong": [
		{"who": "friend", "q": {"id": "\"Capek bro, tugas kelompok cuma gw yang ngerjain.\"", "en": "\"I'm so tired, I'm the only one doing the group project.\""},
			"a": [[{"id": "Minggu depan kita bagi tugas bareng, gw bantuin.", "en": "Let's split the work next week, I'll help."}, 1.0],
				[{"id": "Wkwk sama, kelompok gw juga beban semua.", "en": "Lol same, my group is all dead weight."}, 0.6],
				[{"id": "*scroll HP*", "en": "*scrolls phone*"}, 0.1]]},
		{"who": "friend", "q": {"id": "\"Gorengan terakhir nih. Buat lu atau gw?\"", "en": "\"Last fritter. Yours or mine?\""},
			"a": [[{"id": "Bagi dua aja, adil.", "en": "Split it, fair and square."}, 1.0],
				[{"id": "Suit dulu!", "en": "Rock paper scissors!"}, 0.8],
				[{"id": "*langsung ambil*", "en": "*grabs it*"}, 0.2]]},
		{"who": "friend", "q": {"id": "\"Gw kepikiran pindah prodi... menurut lu gimana?\"", "en": "\"I'm thinking of switching majors... what do you think?\""},
			"a": [[{"id": "Cerita dulu, kenapa? Gw dengerin.", "en": "Tell me why first. I'm listening."}, 1.0],
				[{"id": "Gas aja, hidup cuma sekali.", "en": "Go for it, you only live once."}, 0.5],
				[{"id": "Ngapain sih, ribet.", "en": "Why bother, too much hassle."}, 0.1]]},
	],
	"organisasi": [
		{"who": "senior", "q": {"id": "\"Ada usul proker bulan depan?\"", "en": "\"Any ideas for next month's program?\""},
			"a": [[{"id": "Baksos + donor darah bareng warga.", "en": "Charity drive + blood donation with locals."}, 1.0],
				[{"id": "Turnamen e-sport antar angkatan!", "en": "Inter-year e-sports tournament!"}, 0.7],
				[{"id": "Rapat lagi aja minggu depan.", "en": "Let's just have another meeting next week."}, 0.2]]},
		{"who": "senior", "q": {"id": "\"Dana acara kurang 2 juta. Gimana?\"", "en": "\"The event is 2 million short. Ideas?\""},
			"a": [[{"id": "Cari sponsor + jualan danus.", "en": "Find sponsors + sell snacks."}, 1.0],
				[{"id": "Iuran anggota aja.", "en": "Members chip in."}, 0.6],
				[{"id": "Pinjol?", "en": "Payday loan?"}, 0.0]]},
	],
	"bimbingan": [
		{"who": "dospem", "q": {"id": "\"Kenapa kamu pakai metode ini?\"", "en": "\"Why did you choose this method?\""},
			"a": [[{"id": "Sesuai rumusan masalah, ada 3 referensi pendukung.", "en": "It fits the research question, backed by 3 references."}, 1.0],
				[{"id": "Kakak tingkat pakai ini, Pak/Bu.", "en": "A senior used it, sir/ma'am."}, 0.4],
				[{"id": "Hehe, kebetulan aja.", "en": "Heh, just happened to."}, 0.1]]},
		{"who": "dospem", "q": {"id": "\"Batasan masalahnya apa?\"", "en": "\"What's the scope of your study?\""},
			"a": [[{"id": "Data 2 tahun terakhir di satu kota.", "en": "Two years of data from one city."}, 1.0],
				[{"id": "Semua hal di Indonesia.", "en": "Everything in Indonesia."}, 0.3],
				[{"id": "Nanti saya pikirkan.", "en": "I'll think about it later."}, 0.1]]},
	],
	"les": [
		{"who": "kid", "q": {"id": "\"Kak, aku nggak ngerti pecahan...\"", "en": "\"I don't get fractions...\""},
			"a": [[{"id": "Pakai contoh potong pizza, yuk.", "en": "Let's use a pizza as an example."}, 1.0],
				[{"id": "Hafalin rumusnya aja.", "en": "Just memorize the formula."}, 0.4],
				[{"id": "Kakak juga nggak ngerti.", "en": "I don't get them either."}, 0.1]]},
		{"who": "kid", "q": {"id": "\"Kak, PR-nya kerjain aja dong...\"", "en": "\"Can you just do my homework...?\""},
			"a": [[{"id": "Kita kerjain bareng, kamu yang nulis.", "en": "Let's do it together, you write."}, 1.0],
				[{"id": "Satu nomor aja ya.", "en": "Just one question."}, 0.5],
				[{"id": "Sini, kakak kerjain semua.", "en": "Fine, I'll do all of it."}, 0.1]]},
	],
}

const CATCH := {
	"kuliah": {"good": [{"id": "Poin penting!", "en": "Key point!"}, {"id": "Rumus", "en": "Formula"}, {"id": "Bakal keluar UAS", "en": "On the final"}],
		"bad": [{"id": "Ngantuk", "en": "Drowsy"}, {"id": "Notif grup", "en": "Group chat"}],
		"hint": {"id": "Catat poin penting dosen! Jangan ketuk gangguan.", "en": "Note the key points! Don't tap the distractions."}},
	"belajar": {"good": [{"id": "Definisi", "en": "Definition"}, {"id": "Contoh soal", "en": "Practice Q"}, {"id": "Rumus", "en": "Formula"}],
		"bad": [{"id": "TikTok", "en": "TikTok"}, {"id": "Flash sale", "en": "Flash sale"}],
		"hint": {"id": "Tangkap kartu materi, cuekin distraksi!", "en": "Grab the study cards, ignore distractions!"}},
	"tidur": {"good": [{"id": "Domba", "en": "Sheep"}, {"id": "Domba", "en": "Sheep"}, {"id": "Bantal", "en": "Pillow"}],
		"bad": [{"id": "Alarm", "en": "Alarm"}, {"id": "Notif dosen", "en": "Lecturer DM"}],
		"hint": {"id": "Hitung domba biar cepat pulas. Hindari alarm!", "en": "Count sheep to fall asleep. Avoid the alarm!"}},
	"bolos": {"good": [{"id": "Meme lucu", "en": "Funny meme"}, {"id": "Video kucing", "en": "Cat video"}],
		"bad": [{"id": "\"Kamu di mana?\"", "en": "\"Where are you?\""}, {"id": "Absen dibuka", "en": "Attendance open"}],
		"hint": {"id": "Rebahan maksimal: ketuk konten lucu, kabur dari chat dosen.", "en": "Max chill: tap funny stuff, dodge the lecturer's chat."}},
	"nongkrong": {"good": [{"id": "Gorengan", "en": "Fritter"}, {"id": "Es teh", "en": "Iced tea"}, {"id": "Cerita seru", "en": "Fun story"}],
		"bad": [{"id": "Bon", "en": "Bill"}, {"id": "Ditagih", "en": "Debt call"}],
		"hint": {"id": "Ambil gorengan selagi hangat!", "en": "Grab the fritters while they're hot!"}},
	"minimarket": {"good": [{"id": "Scan!", "en": "Scan!"}, {"id": "Barang", "en": "Item"}, {"id": "Struk", "en": "Receipt"}],
		"bad": [{"id": "Barang rusak", "en": "Damaged"}, {"id": "Uang palsu", "en": "Fake bill"}],
		"hint": {"id": "Scan barang secepatnya, tolak yang aneh!", "en": "Scan items fast, reject the odd ones!"}},
	"jaga_apotek": {"good": [{"id": "Resep", "en": "Prescription"}, {"id": "Obat", "en": "Medicine"}, {"id": "Vitamin", "en": "Vitamins"}],
		"bad": [{"id": "Kedaluwarsa", "en": "Expired"}, {"id": "Salah dosis", "en": "Wrong dose"}],
		"hint": {"id": "Siapkan obat yang benar, singkirkan yang salah!", "en": "Prepare the right meds, set aside the wrong ones!"}},
}

const TIMING := {
	"olahraga": {"hint": {"id": "Jaga ritme lari: ketuk saat jarum di zona hijau!", "en": "Keep your running rhythm: tap when the needle hits green!"}, "btn": {"id": "Langkah!", "en": "Step!"}},
	"konseling": {"hint": {"id": "Tarik napas... ketuk pas jarum di zona tenang.", "en": "Breathe in... tap when the needle is in the calm zone."}, "btn": {"id": "Hembuskan", "en": "Exhale"}},
	"ojol": {"hint": {"id": "Rem pas di zona hijau biar penumpang aman!", "en": "Brake in the green zone to keep your passenger safe!"}, "btn": {"id": "Rem!", "en": "Brake!"}},
	"barista": {"hint": {"id": "Tuang susu pas di zona hijau buat latte art!", "en": "Pour the milk in the green zone for latte art!"}, "btn": {"id": "Tuang!", "en": "Pour!"}},
	"default": {"hint": {"id": "Ketuk saat jarum di zona hijau!", "en": "Tap when the needle is in the green!"}, "btn": {"id": "Sekarang!", "en": "Now!"}},
}

const MASH := {
	"tugas": {"hint": {"id": "Ketik laporan secepatnya sebelum deadline!", "en": "Type the report before the deadline!"}, "btn": {"id": "Ketik!", "en": "Type!"},
		"text": "BAB I PENDAHULUAN. 1.1 Latar Belakang. Seiring perkembangan zaman yang semakin pesat, tugas ini dikumpulkan tepat waktu."},
	"garap_skripsi": {"hint": {"id": "Tulis skripsi! Satu ketukan, satu kata.", "en": "Write your thesis! One tap, one word."}, "btn": {"id": "Tulis!", "en": "Write!"},
		"text": "BAB III METODOLOGI PENELITIAN. Penelitian ini menggunakan pendekatan kuantitatif dengan sampel yang dipilih secara purposive."},
	"admin_olshop": {"hint": {"id": "Balas chat pembeli secepat kilat!", "en": "Reply to buyers lightning-fast!"}, "btn": {"id": "Balas!", "en": "Reply!"},
		"text": "Ready kak! Silakan checkout ya kak. Ready kak! Bisa COD kak. Ready kak! Makasih kak!"},
	"freelance_dev": {"hint": {"id": "Ngoding sebelum klien nanya progres!", "en": "Code before the client asks for an update!"}, "btn": {"id": "Ngoding!", "en": "Code!"},
		"text": "func main() { fix_bug(); deploy(); print(\"done\"); } // revisi ke-7 dari klien"},
	"asdos": {"hint": {"id": "Koreksi tumpukan laporan praktikum!", "en": "Grade the pile of lab reports!"}, "btn": {"id": "Koreksi!", "en": "Grade!"},
		"text": "Laporan 1: OK. Laporan 2: copas. Laporan 3: OK. Laporan 4: nama salah. Laporan 5: OK."},
}

const GRADES := [
	[0.85, {"id": "SEMPURNA!", "en": "PERFECT!"}, Color("2fbf71")],
	[0.55, {"id": "MANTAP!", "en": "NICE!"}, Color("2f6bff")],
	[0.2, {"id": "LUMAYAN", "en": "OKAY"}, Color("ff9f1c")],
	[-1.0, {"id": "MELESET...", "en": "MISSED..."}, Color("8a8398")],
]


## Mini-game config for a week log entry, or {} when the activity has none.
static func config_for(s: Dictionary, entry: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var a: String = entry.action
	var job: String = s.get("job", "")
	match a:
		"kuliah":
			if rng.randf() < 0.5:
				return _quiz(s, rng, 1, "lecturer", Loc.T("Dosen tiba-tiba nunjuk kamu!", "The lecturer suddenly calls on you!"))
			return _catch("kuliah")
		"ujian":
			return _quiz(s, rng, 3, "lecturer", Loc.T("Ujian! Jawab 3 soal secepatnya.", "Exam! Answer 3 questions fast."))
		"belajar":
			if rng.randf() < 0.35:
				return _quiz(s, rng, 2, "", Loc.T("Latihan soal: jawab yang benar!", "Practice: pick the right answers!"))
			return _catch("belajar")
		"tugas", "garap_skripsi":
			return _mash(a)
		"tidur", "bolos":
			return _catch(a)
		"nongkrong":
			if rng.randf() < 0.5:
				return _chat("nongkrong", rng)
			return _catch("nongkrong")
		"organisasi":
			return _chat("organisasi", rng)
		"bimbingan":
			if entry.get("scene_key", "") in ["ghost", "dinas"]:
				return {}
			return _chat("bimbingan", rng)
		"olahraga", "konseling", "ojol":
			return _timing(a)
		"kerja":
			match job:
				"barista":
					return _timing("barista")
				"minimarket", "jaga_apotek":
					return _catch(job)
				"les":
					return _chat("les", rng)
				"admin_olshop", "freelance_dev", "asdos":
					return _mash(job)
			return _timing("default")
	return {}


static func _quiz(s: Dictionary, rng: RandomNumberGenerator, rounds: int, who: String, hint: Dictionary) -> Dictionary:
	var pool: Array = QUIZ_GENERAL.duplicate()
	pool.append_array(QUIZ_PRODI.get(s.get("prodi", "IF"), []))
	pool.append_array(QUIZ_PRODI.get(s.get("prodi", "IF"), []))
	var qs: Array = []
	for i in rounds:
		var q: Dictionary = pool[rng.randi() % pool.size()]
		pool.erase(q)
		pool.erase(q)
		# Shuffle answers; remember where the right one (index 0 in data) went.
		var order := [0, 1, 2]
		for k in range(2, 0, -1):
			var j := rng.randi() % (k + 1)
			var t: int = order[k]
			order[k] = order[j]
			order[j] = t
		var answers: Array = []
		for k in order:
			answers.append(q.a[k])
		qs.append({"q": q.q, "a": answers, "right": order.find(0)})
	return {"kind": "quiz", "title": Loc.T("Kuis", "Quiz"), "hint": hint, "who": who, "questions": qs, "time": 7.0}


static func _chat(set_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = CHATS[set_id]
	var c: Dictionary = pool[rng.randi() % pool.size()]
	var opts: Array = c.a.duplicate()
	for k in range(opts.size() - 1, 0, -1):
		var j := rng.randi() % (k + 1)
		var t: Variant = opts[k]
		opts[k] = opts[j]
		opts[j] = t
	return {"kind": "chat", "title": Loc.T("Ngobrol", "Talk"), "hint": Loc.T("Pilih jawaban terbaik!", "Pick the best reply!"), "who": c.who, "q": c.q, "opts": opts, "time": 9.0}


static func _catch(set_id: String) -> Dictionary:
	var c: Dictionary = CATCH[set_id]
	return {"kind": "catch", "title": Loc.T("Tangkap!", "Catch!"), "hint": c.hint, "good": c.good, "bad": c.bad, "time": 6.0}


static func _timing(set_id: String) -> Dictionary:
	var c: Dictionary = TIMING.get(set_id, TIMING.default)
	return {"kind": "timing", "title": Loc.T("Pas-pasan!", "Timing!"), "hint": c.hint, "btn": c.btn, "rounds": 3, "time": 9.0}


static func _mash(set_id: String) -> Dictionary:
	var c: Dictionary = MASH[set_id]
	return {"kind": "mash", "title": Loc.T("Ngebut!", "Rush!"), "hint": c.hint, "btn": c.btn, "text": c.text, "target": 26, "time": 6.0}


## Small reward for playing well. Nothing is lost for a poor score.
static func bonus_fx(s: Dictionary, action: String, score: float) -> Dictionary:
	score = clampf(score, 0.0, 1.0)
	if score < 0.2:
		return {}
	var fx := {}
	match action:
		"kuliah":
			fx = {"knowledge": 0.35 * score}
		"ujian":
			fx = {"bonus": 1.2 * score}
		"belajar":
			fx = {"knowledge": 0.5 * score}
		"tugas":
			fx = {"tugas": 0.5 * score}
		"garap_skripsi":
			fx = {"draft": 5.0 * score}
		"bimbingan":
			fx = {"mental": 2.0 * score}
			if score >= 0.7:
				fx["rel"] = 1
		"nongkrong":
			fx = {"social": 3.0 * score, "mental": 3.0 * score}
		"organisasi":
			fx = {"social": 3.0 * score}
			if score >= 0.85:
				fx["rel"] = 1
		"olahraga":
			fx = {"mental": 4.0 * score, "energy": 3.0 * score}
		"tidur":
			fx = {"energy": 6.0 * score, "mental": 2.0 * score}
		"bolos":
			fx = {"mental": 2.0 * score}
		"konseling":
			fx = {"mental": 5.0 * score}
		"ojol":
			fx = {"coins": int(round(40.0 * score))}
		"kerja":
			var pay: int = D.JOBS.get(s.get("job", ""), {}).get("pay", 200)
			fx = {"coins": int(round(pay * 0.12 * score))}
	# Integer stats round anyway; drop the ones that would show as +0.
	for k in fx.keys():
		if k in ["energy", "mental", "social"] and int(round(fx[k])) == 0:
			fx.erase(k)
		elif k in ["energy", "mental", "social"]:
			fx[k] = int(round(fx[k]))
	return fx


## Applies the bonus to the run state and returns it (for display).
static func apply(s: Dictionary, action: String, score: float) -> Dictionary:
	var fx := bonus_fx(s, action, score)
	for k in fx:
		Sim._apply_fx(s, k, fx[k])
	s.stats["minigames"] = int(s.stats.get("minigames", 0)) + 1
	if score >= 0.85:
		s.stats["perfect"] = int(s.stats.get("perfect", 0)) + 1
	return fx


static func grade(score: float) -> Array:
	for g in GRADES:
		if score >= g[0]:
			return g
	return GRADES[-1]
