extends Node
## Data that persists across runs: diamonds, owned cosmetics, endings gallery, settings, purchases.

signal changed

const PATH := "user://meta.json"

var diamonds := 0
var owned: Dictionary = {}
var endings: Dictionary = {}
var purchases: Dictionary = {}
var no_ads := false
var settings := {"lang": 0, "content_note_seen": false}
var ads_day := ""
var ads_count := 0
var runs := 0


func _ready() -> void:
	load_meta()
	Loc.mode = int(settings.get("lang", 0))
	Loc.mode_changed.connect(func():
		settings.lang = Loc.mode
		save_meta())


func load_meta() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		return
	diamonds = int(d.get("diamonds", 0))
	owned = d.get("owned", {})
	endings = d.get("endings", {})
	purchases = d.get("purchases", {})
	no_ads = d.get("no_ads", false)
	settings.merge(d.get("settings", {}), true)
	ads_day = d.get("ads_day", "")
	ads_count = int(d.get("ads_count", 0))
	runs = int(d.get("runs", 0))


func save_meta() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"diamonds": diamonds, "owned": owned, "endings": endings, "purchases": purchases,
		"no_ads": no_ads, "settings": settings, "ads_day": ads_day, "ads_count": ads_count, "runs": runs,
	}))
	changed.emit()


func owns(item_id: String) -> bool:
	var it: Dictionary = Data.ITEMS.get(item_id, {})
	if it.is_empty():
		return false
	if it.get("price_c", -1) == 0:
		return true
	return owned.get(item_id, false)


func grant_item(item_id: String) -> void:
	owned[item_id] = true
	save_meta()


func add_diamonds(n: int) -> void:
	diamonds = maxi(0, diamonds + n)
	save_meta()


func record_ending(id: String, player_name: String) -> bool:
	var first := not endings.has(id)
	var e: Dictionary = endings.get(id, {"count": 0, "first": player_name})
	e.count = int(e.count) + 1
	endings[id] = e
	save_meta()
	return first


func rewarded_left() -> int:
	var today := Time.get_date_string_from_system()
	if ads_day != today:
		ads_day = today
		ads_count = 0
	return maxi(0, Data.REWARDED_DAILY_CAP - ads_count)


func count_rewarded() -> void:
	rewarded_left()
	ads_count += 1
	save_meta()
