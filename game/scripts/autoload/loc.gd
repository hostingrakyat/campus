extends Node
## Dual-subtitle localization. Every piece of text is a {"id": ..., "en": ...} pair.
## Modes: Indonesian main + English subtitle, the reverse, or a single language.

signal mode_changed

enum Mode { DUAL_ID, DUAL_EN, ID, EN }

const MODE_NAMES := [
	{"id": "Indonesia + subtitle English", "en": "Indonesian + English subtitle"},
	{"id": "English + subtitle Indonesia", "en": "English + Indonesian subtitle"},
	{"id": "Bahasa Indonesia saja", "en": "Indonesian only"},
	{"id": "English saja", "en": "English only"},
]

var mode: int = Mode.DUAL_ID


func set_mode(m: int) -> void:
	mode = m
	mode_changed.emit()


func main_lang() -> String:
	return "en" if mode == Mode.DUAL_EN or mode == Mode.EN else "id"


func is_dual() -> bool:
	return mode == Mode.DUAL_ID or mode == Mode.DUAL_EN


## Main line of a text pair.
func main(p: Variant) -> String:
	if p is String:
		return p
	if p == null or (p as Dictionary).is_empty():
		return ""
	return p.get(main_lang(), p.get("id", ""))


## Subtitle line ("" when single-language or identical).
func sub(p: Variant) -> String:
	if not is_dual() or not (p is Dictionary) or p.is_empty():
		return ""
	var other := "id" if main_lang() == "en" else "en"
	var s: String = p.get(other, "")
	return "" if s == main(p) else s


## Replace {placeholders} in both languages.
func fill(p: Dictionary, args: Dictionary) -> Dictionary:
	var out := {}
	for lang in p:
		var s: String = p[lang]
		for k in args:
			var v: Variant = args[k]
			s = s.replace("{" + k + "}", v.get(lang, "") if v is Dictionary else str(v))
		out[lang] = s
	return out


func T(id_text: String, en_text: String) -> Dictionary:
	return {"id": id_text, "en": en_text}
