class_name WardrobePopup
extends ModalCard
## Equip owned cosmetics; the character in the world updates live.

var slot := "top"
var tabs_box: HBoxContainer
var list: VBoxContainer


func _init(m: Node) -> void:
	super(m, Loc.T("Lemari", "Wardrobe"), 660, true, "lower")
	tabs_box = Kit.hbox(6)
	body.add_child(tabs_box)
	list = scroll_list(300)
	body.add_child(Kit.button(Loc.T("Beli gaya baru di Toko", "Buy new styles in the Shop"), Kit.ORANGE, func():
		main.close_top_modal()
		main.open_modal(ShopPopup.new(main, "style")), 22))
	_refresh()


func _ready() -> void:
	var p: VinylChar = main.world.player
	main.world.focus(p.position + Vector3(0, 1.0, 0), 5.0, false, 0.24)


func _exit_tree() -> void:
	main.world.follow(12.0, 0.36)


func _refresh() -> void:
	for c in tabs_box.get_children():
		c.queue_free()
	for sl in ["top", "hair", "head", "face", "back", "aura"]:
		var key: String = sl
		var b := Kit.compact(Kit.button(ShopPopup._slot_name(sl), Kit.PINK if sl == slot else Color("ddd5e8"), func():
			slot = key
			_refresh(), 18, 52, false), 4)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs_box.add_child(b)
	for c in list.get_children():
		c.queue_free()
	for id in Data.ITEMS:
		var it: Dictionary = Data.ITEMS[id]
		if it.slot != slot or not Meta.owns(id):
			continue
		var on: bool = Game.s.look.get(slot, "") == id
		var b := Kit.button(it.name, Kit.BLUE if on else Color.WHITE, func():
			Game.equip(id)
			Audio.play("pop", -2.0)
			main.world.player.hop()
			_refresh(), 24)
		list.add_child(b)
