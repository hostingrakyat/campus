class_name ShopPopup
extends ModalCard
## Tabs: Diamonds (IAP + rewarded), Style (cosmetics), Snacks (consumables), Exchange.

var tab := "style"
var tabs_box: HBoxContainer
var list: VBoxContainer
var wallet: HBoxContainer


func _init(m: Node, start_tab: String = "style") -> void:
	super(m, Loc.T("Toko", "Shop"), 680)
	tab = start_tab
	wallet = Kit.hbox(10)
	body.add_child(wallet)
	tabs_box = Kit.hbox(8)
	body.add_child(tabs_box)
	list = scroll_list(760)
	Meta.changed.connect(_refresh)
	Game.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	for sig in [Meta.changed, Game.changed]:
		if sig.is_connected(_refresh):
			sig.disconnect(_refresh)


func _refresh() -> void:
	for c in wallet.get_children():
		c.queue_free()
	if not Game.s.is_empty():
		wallet.add_child(Kit.currency_chip("coin", Game.s.coins))
	wallet.add_child(Kit.currency_chip("diamond", Meta.diamonds))
	for c in tabs_box.get_children():
		c.queue_free()
	var tabs := [["diamond", Loc.T("Diamond", "Diamonds")], ["style", Loc.T("Gaya", "Style")]]
	if not Game.s.is_empty():
		tabs += [["snack", Loc.T("Jajan", "Snacks")], ["exchange", Loc.T("Tukar", "Exchange")]]
	for t in tabs:
		var key: String = t[0]
		var b := Kit.compact(Kit.button(t[1], Kit.ORANGE if key == tab else Color("ddd5e8"), func():
			tab = key
			_refresh(), 20, 56, false))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs_box.add_child(b)
	for c in list.get_children():
		c.queue_free()
	match tab:
		"diamond":
			_diamond_tab()
		"style":
			_style_tab()
		"snack":
			_snack_tab()
		"exchange":
			_exchange_tab()
	if tab != get_meta("anim_tab", ""):
		set_meta("anim_tab", tab)
		Fx.stagger(list, 0.03, 0.05)


func _diamond_tab() -> void:
	var h := row_card(Color("e3f7ea"))
	list.add_child(h.get_parent())
	h.add_child(Icon.make("diamond", 56))
	var d := Kit.dual(Loc.T("Nonton iklan: +%d diamond (sisa %d hari ini)" % [Data.REWARDED_DIAMONDS, Ads.rewarded_left()], "Watch an ad: +%d diamonds (%d left today)" % [Data.REWARDED_DIAMONDS, Ads.rewarded_left()]), 22, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(d)
	var watch := Kit.button(Loc.T("Tonton", "Watch"), Kit.GREEN, func():
		Ads.show_rewarded("shop_diamonds", func(ok: bool):
			if ok:
				Audio.play("diamond")
				Meta.add_diamonds(Data.REWARDED_DIAMONDS)
				main.toast(Loc.T("+%d diamond!" % Data.REWARDED_DIAMONDS, "+%d diamonds!" % Data.REWARDED_DIAMONDS), Kit.CYAN)), 22)
	watch.disabled = Ads.rewarded_left() <= 0
	h.add_child(watch)
	for pid in Data.IAP_PRODUCTS:
		var p: Dictionary = Data.IAP_PRODUCTS[pid]
		var r := row_card()
		list.add_child(r.get_parent())
		r.add_child(Icon.make("diamond", 56))
		var col := Kit.vbox(2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(Kit.dual(p.name, 24, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true))
		var info := ""
		if p.diamonds > 0:
			info = "%d diamond" % p.diamonds
		if p.has("item"):
			info += " + " + Loc.main(Data.ITEMS[p.item].name)
		if p.get("no_ads", false):
			info = Loc.main(Loc.T("Rewarded tetap opsional", "Rewarded ads stay optional"))
		col.add_child(Kit.label(info, 20, Kit.INK_SOFT))
		r.add_child(col)
		var owned := not Iap.can_buy(pid)
		var b := Kit.button(Loc.T("Dimiliki", "Owned") if owned else p.price, Color("b9b2c6") if owned else Kit.BLUE, func(): _confirm_iap(pid), 20)
		b.disabled = owned
		r.add_child(b)
	list.add_child(Kit.label(Loc.main(Loc.T("Build sampel: pembelian disimulasikan, tidak ada uang yang ditarik.", "Sample build: purchases are simulated, no money is charged.")), 18, Kit.INK_SOFT, null, HORIZONTAL_ALIGNMENT_CENTER, true))


func _confirm_iap(pid: String) -> void:
	var p: Dictionary = Data.IAP_PRODUCTS[pid]
	var box := ModalCard.new(main, Loc.T("Konfirmasi", "Confirm"), 560, true, "compact")
	box.body.add_child(Kit.dual(Loc.T("Beli %s seharga %s? (simulasi)" % [p.name.id, p.price], "Buy %s for %s? (simulated)" % [p.name.en, p.price]), 24))
	box.body.add_child(Kit.button(Loc.T("Beli", "Buy"), Kit.GREEN, func():
		Iap.buy(pid)
		Audio.play("unlock", -3.0)
		main.close_top_modal()
		main.toast(Loc.T("Terima kasih! Pembelian berhasil.", "Thank you! Purchase complete."), Kit.GREEN)))
	main.open_modal(box)


func _style_tab() -> void:
	for id in Data.ITEMS:
		var it: Dictionary = Data.ITEMS[id]
		if it.get("price_c", 1) == 0 or it.get("npc", false):
			continue
		var r := row_card(Color("fff6d6") if it.get("premium", false) else Color.WHITE)
		list.add_child(r.get_parent())
		var col := Kit.vbox(2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(Kit.dual(it.name, 24, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true))
		col.add_child(Kit.label(Loc.main(_slot_name(it.slot)), 18, Kit.INK_SOFT))
		r.add_child(col)
		if Meta.owns(id):
			r.add_child(Kit.chip(Loc.main(Loc.T("Dimiliki", "Owned")), Color("e3f7ea"), Color("17643a"), 20))
			continue
		var is_d := it.has("price_d")
		var price := int(it.price_d if is_d else it.price_c)
		var price_box := Kit.hbox(4)
		price_box.add_child(Icon.make("diamond" if is_d else "coin", 30))
		price_box.add_child(Kit.label(Kit.fmt(price), 24, Kit.INK, Kit.font_bold))
		price_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(price_box)
		r.add_child(Kit.button(Loc.T("Beli", "Buy"), Kit.ORANGE, func():
			var res := Game.buy_item(id)
			Audio.play(("diamond" if is_d else "spend") if res.ok else "error", -2.0)
			if res.ok:
				Audio.play("unlock", -10.0)
			main.toast(res.msg, Kit.GREEN if res.ok else Kit.RED), 20))


func _snack_tab() -> void:
	for id in Data.CONSUMABLES:
		var c: Dictionary = Data.CONSUMABLES[id]
		var r := row_card()
		list.add_child(r.get_parent())
		var col := Kit.vbox(2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(Kit.dual(c.name, 24, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true))
		var fxs := []
		for f in Kit.fx_text(c.fx):
			fxs.append(f.text)
		col.add_child(Kit.label(", ".join(fxs), 18, Color("17643a")))
		r.add_child(col)
		var is_d := c.has("price_d")
		var price_box := Kit.hbox(4)
		price_box.add_child(Icon.make("diamond" if is_d else "coin", 30))
		price_box.add_child(Kit.label(str(c.price_d if is_d else c.price_c), 24, Kit.INK, Kit.font_bold))
		price_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(price_box)
		r.add_child(Kit.button(Loc.T("Beli", "Buy"), Kit.ORANGE, func():
			var res := Game.buy_consumable(id)
			Audio.play("spend" if res.ok else "error", -3.0)
			main.toast(res.msg, Kit.GREEN if res.ok else Kit.RED), 20))


func _exchange_tab() -> void:
	var ex: Dictionary = Data.DIAMOND_TO_COIN
	var r := row_card()
	list.add_child(r.get_parent())
	r.add_child(Icon.make("diamond", 48))
	r.add_child(Kit.label("%d  >  " % ex.diamonds, 28, Kit.INK, Kit.font_bold))
	r.add_child(Icon.make("coin", 48))
	var l := Kit.label(Kit.fmt(ex.coins), 28, Kit.INK, Kit.font_bold)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l)
	r.add_child(Kit.button(Loc.T("Tukar", "Exchange"), Kit.GREEN, func():
		var res := Game.exchange_diamonds()
		main.toast(res.msg, Kit.GREEN if res.ok else Kit.RED), 20))
	list.add_child(Kit.dual(Loc.T("Darurat UKT? Diamond bisa ditukar jadi koin.", "Tuition emergency? Diamonds can be exchanged for coins."), 20, Kit.INK_SOFT))


static func _slot_name(slot: String) -> Dictionary:
	return {
		"hair": Loc.T("Rambut", "Hair"), "top": Loc.T("Atasan", "Top"), "head": Loc.T("Topi", "Hat"),
		"face": Loc.T("Kacamata", "Glasses"), "back": Loc.T("Tas", "Bag"), "aura": Loc.T("Aura", "Aura"),
	}.get(slot, Loc.T(slot, slot))
