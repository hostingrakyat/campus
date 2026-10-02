class_name GalleryScreen
extends Screen
## Collection of the 10 endings. Locked ones show a hint.

const HINTS := {
	"summa": {"id": "IPK 3.90+, lulus maks 8 semester, tanpa ngulang.", "en": "GPA 3.90+, graduate within 8 semesters, no retakes."},
	"balance": {"id": "Lulus maks 9 semester dengan IPK 3.00+, sosial tinggi, mental terjaga.", "en": "Graduate within 9 semesters, GPA 3.00+, high social, healthy mind."},
	"cumlaude": {"id": "IPK 3.50+ dan lulus maks 8 semester.", "en": "GPA 3.50+ and graduate within 8 semesters."},
	"tepat": {"id": "Lulus tepat 8 semester.", "en": "Graduate in 8 semesters."},
	"telat": {"id": "Lulus di semester 9-12.", "en": "Graduate in semesters 9-12."},
	"abadi": {"id": "Bertahan sampai semester 13-14...", "en": "Hang on until semester 13-14..."},
	"do": {"id": "Banyak jalan menuju surat DO.", "en": "Many roads lead to expulsion."},
	"pindah": {"id": "Merasa salah jurusan di 4 semester awal?", "en": "Feel like you picked the wrong major in the first 4 semesters?"},
	"rawat": {"id": "Saat mental habis, teman-temanmu ada di sana.", "en": "When your mind runs out, your friends are there."},
	"padam": {"id": "Saat mental habis dan tak ada yang tahu.", "en": "When your mind runs out and nobody knows."},
}


func _ready() -> void:
	main.world.set_time("malam", true)
	main.world.focus(Vector3(0, 0, 2), 22.0, true)
	var top := top_bar()
	top.add_child(Kit.button(Loc.T("< Kembali", "< Back"), Color("8a8398"), func(): main.goto("title"), 20))
	var pg := page(0.1)
	var unlocked := Meta.endings.size()
	pg.head.add_child(Kit.title(Loc.main(Loc.T("Galeri Ending  %d/10", "Endings  %d/10")) % unlocked, 38))
	var list := pg.body
	for id in Data.ENDINGS:
		var e: Dictionary = Data.endings[id]
		var got := Meta.endings.has(id)
		var tone: Color = EndingScreen.TONES.get(e.tone, Kit.BLUE)
		var p := Kit.panel(Color.WHITE if got else Color("ece7f2"), 22, 16)
		var h := Kit.hbox(12)
		p.add_child(h)
		h.add_child(Icon.make("badge", 56, tone if got else Color("bdb6c8"), "!" if got else "?"))
		var col := Kit.vbox(2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(col)
		col.add_child(Kit.label(Loc.main(e.title) if got else "???", 26, Kit.INK, Kit.font_bold))
		col.add_child(Kit.dual(HINTS[id], 19, Kit.INK_SOFT))
		if got:
			h.add_child(Kit.chip("x%d" % Meta.endings[id].count, tone, Color.WHITE, 20))
		list.add_child(p)
	Fx.stagger(list, 0.04, 0.2)


func on_back() -> bool:
	main.goto("title")
	return true
