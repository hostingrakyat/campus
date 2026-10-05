extends Node
## In-app purchases. Uses Google Play Billing when the native plugin is present and the product is
## live on Play; otherwise falls back:
##  - debug builds / desktop: the purchase is simulated (nothing is charged) so the shop stays testable;
##  - release builds: the purchase is refused with a clear message (no free diamonds), unless
##    ProjectSettings "mahasigma/iap/simulate_when_unavailable" is true.

signal purchased(product_id: String)
## message is a {"id","en"} pair; product_id may be "" when Play doesn't say which product.
signal purchase_failed(product_id: String, status: String, message: Dictionary)
signal prices_changed

const BACKEND := "res://scripts/monetization/play_billing_backend.gd"
const CONSUMABLES := ["diamonds_60", "diamonds_250", "diamonds_600"]

var backend: Node


func _ready() -> void:
	if OS.get_name() == "Android" and Engine.has_singleton("GodotGooglePlayBilling"):
		backend = load(BACKEND).new()
		add_child(backend)
		backend.products_changed.connect(prices_changed.emit)
		backend.grant.connect(_grant)
		backend.purchase_problem.connect(func(pid: String, status: String, msg: Dictionary):
			purchase_failed.emit(pid, status, msg))
		backend.start(Data.IAP_PRODUCTS.keys(), CONSUMABLES)


## "play" (real billing), "simulated" (test fallback) or "off" (release without billing).
func mode() -> String:
	if backend and backend.connected:
		return "play"
	return "simulated" if _may_simulate() else "off"


func is_owned(product_id: String) -> bool:
	return Meta.purchases.get(product_id, false)


func can_buy(product_id: String) -> bool:
	var p: Dictionary = Data.IAP_PRODUCTS[product_id]
	return not (p.get("once", false) and is_owned(product_id))


## Localized price from Play when known, otherwise the reference price.
func price_text(product_id: String) -> String:
	if backend:
		var live: String = backend.price(product_id)
		if live != "":
			return live
	return Data.IAP_PRODUCTS[product_id].price


## Starts a purchase. The outcome arrives as `purchased` or `purchase_failed`.
func buy(product_id: String) -> void:
	if not can_buy(product_id):
		purchase_failed.emit(product_id, "error", {"id": "Sudah dimiliki.", "en": "Already owned."})
		return
	if backend and backend.has_product(product_id):
		backend.purchase(product_id)
	elif _may_simulate():
		_grant(product_id, "")
	else:
		purchase_failed.emit(product_id, "error", {"id": "Pembayaran Google Play belum aktif. Coba lagi nanti.", "en": "Google Play payments aren't active yet. Please try again later."})


func restore() -> void:
	if backend:
		backend.restore()


func status_note() -> Dictionary:
	match mode():
		"play":
			return {"id": "Pembayaran aman lewat Google Play.", "en": "Payments are handled securely by Google Play."}
		"simulated":
			return {"id": "Mode uji: pembelian disimulasikan, tidak ada uang yang ditarik.", "en": "Test mode: purchases are simulated, no money is charged."}
	return {"id": "Pembayaran Google Play belum aktif di perangkat ini.", "en": "Google Play payments aren't active on this device."}


func _may_simulate() -> bool:
	return OS.is_debug_build() or OS.get_name() != "Android" or bool(ProjectSettings.get_setting("mahasigma/iap/simulate_when_unavailable", false))


## Gives the product. Each Play purchase token is honored once, even across restarts.
func _grant(product_id: String, token: String) -> void:
	if not Data.IAP_PRODUCTS.has(product_id):
		push_warning("[IAP] unknown product " + product_id)
		return
	var p: Dictionary = Data.IAP_PRODUCTS[product_id]
	if token != "":
		if Meta.purchases.has("tok:" + token):
			return
		Meta.purchases["tok:" + token] = true
	if p.get("once", false) and is_owned(product_id):
		Meta.save_meta()
		return
	Meta.purchases[product_id] = true
	if p.get("no_ads", false):
		Meta.no_ads = true
	if p.has("item"):
		Meta.owned[p.item] = true
	Meta.add_diamonds(int(p.get("diamonds", 0)))
	Meta.save_meta()
	purchased.emit(product_id)
