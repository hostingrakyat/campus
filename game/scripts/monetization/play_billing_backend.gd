extends Node
## Google Play Billing via the official GodotGooglePlayBilling plugin. Iap (autoload) only loads this
## on Android when the native singleton exists.
## Consumables are granted after a successful consume; one-time products are granted then acknowledged
## (Play refunds unacknowledged purchases after 3 days). Owned purchases are restored on every connect.

signal products_changed
## status: "pending" | "canceled" | "error"; message is a {"id","en"} pair.
signal purchase_problem(product_id: String, status: String, message: Dictionary)
## Ask Iap to grant a product. token dedups grants across restarts.
signal grant(product_id: String, token: String)

const RETRY_BASE := 5.0
const RETRY_MAX := 120.0

var connected := false
var details: Dictionary = {}

var _client: BillingClient
var _product_ids: PackedStringArray
var _consumables: Array = []
var _consuming: Dictionary = {}
var _fails := 0


func start(product_ids: Array, consumables: Array) -> void:
	_product_ids = PackedStringArray(product_ids)
	_consumables = consumables
	_client = BillingClient.new()
	add_child(_client)
	_client.connected.connect(_on_connected)
	_client.disconnected.connect(_on_disconnected)
	_client.connect_error.connect(_on_connect_error)
	_client.query_product_details_response.connect(_on_product_details)
	_client.query_purchases_response.connect(_on_query_purchases)
	_client.on_purchase_updated.connect(_on_purchase_updated)
	_client.consume_purchase_response.connect(_on_consumed)
	_client.acknowledge_purchase_response.connect(_on_acknowledged)
	_client.start_connection()


func has_product(product_id: String) -> bool:
	return connected and details.has(product_id)


func price(product_id: String) -> String:
	var d: Dictionary = details.get(product_id, {})
	var offers: Variant = d.get("one_time_purchase_offer_details_list")
	if offers is Array and not offers.is_empty():
		return str(offers[0].get("formatted_price", ""))
	return ""


## Opens the Play purchase sheet. Results arrive through grant / purchase_problem.
func purchase(product_id: String) -> void:
	if not has_product(product_id):
		purchase_problem.emit(product_id, "error", {"id": "Produk belum tersedia di Google Play.", "en": "This product isn't available on Google Play yet."})
		return
	var r: Dictionary = _client.purchase(product_id)
	if int(r.get("response_code", -99)) != BillingClient.BillingResponseCode.OK:
		purchase_problem.emit(product_id, "error", _error_text(int(r.get("response_code", -99))))


## Re-checks owned purchases (also called on every connect).
func restore() -> void:
	if connected:
		_client.query_purchases(BillingClient.ProductType.INAPP)


func _on_connected() -> void:
	connected = true
	_fails = 0
	_client.query_product_details(_product_ids, BillingClient.ProductType.INAPP)
	restore()


func _on_disconnected() -> void:
	connected = false
	products_changed.emit()
	_reconnect_later()


func _on_connect_error(code: int, msg: String) -> void:
	connected = false
	push_warning("[IAP] billing connect error %d: %s" % [code, msg])
	if code != BillingClient.BillingResponseCode.BILLING_UNAVAILABLE and code != BillingClient.BillingResponseCode.FEATURE_NOT_SUPPORTED:
		_reconnect_later()


func _reconnect_later() -> void:
	_fails += 1
	await get_tree().create_timer(minf(RETRY_MAX, RETRY_BASE * pow(2.0, _fails - 1))).timeout
	if not connected:
		_client.start_connection()


func _on_product_details(res: Dictionary) -> void:
	if int(res.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		push_warning("[IAP] product query failed: %s" % res.get("debug_message", ""))
		return
	details.clear()
	for d in res.get("product_details", []):
		details[str(d.get("product_id", ""))] = d
	products_changed.emit()


func _on_query_purchases(res: Dictionary) -> void:
	if int(res.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		return
	for p in res.get("purchases", []):
		_process(p)


func _on_purchase_updated(res: Dictionary) -> void:
	var code := int(res.get("response_code", -1))
	match code:
		BillingClient.BillingResponseCode.OK:
			for p in res.get("purchases", []):
				_process(p)
		BillingClient.BillingResponseCode.USER_CANCELED:
			purchase_problem.emit("", "canceled", {"id": "Pembelian dibatalkan.", "en": "Purchase canceled."})
		BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
			restore()
		_:
			purchase_problem.emit("", "error", _error_text(code))


func _process(p: Dictionary) -> void:
	var ids: Array = Array(p.get("product_ids", []))
	if ids.is_empty():
		return
	var pid: String = ids[0]
	var token: String = p.get("purchase_token", "")
	match int(p.get("purchase_state", 0)):
		BillingClient.PurchaseState.PURCHASED:
			if pid in _consumables:
				if not _consuming.has(token):
					_consuming[token] = pid
					_client.consume_purchase(token)
			else:
				grant.emit(pid, token)
				if not p.get("is_acknowledged", false):
					_client.acknowledge_purchase(token)
		BillingClient.PurchaseState.PENDING:
			purchase_problem.emit(pid, "pending", {"id": "Pembayaran tertunda. Item masuk otomatis setelah pembayaran selesai.", "en": "Payment pending. You'll get the item once it completes."})


func _on_consumed(res: Dictionary) -> void:
	var token: String = res.get("token", "")
	var pid: String = _consuming.get(token, "")
	_consuming.erase(token)
	if int(res.get("response_code", -1)) == BillingClient.BillingResponseCode.OK and pid != "":
		grant.emit(pid, token)
	else:
		push_warning("[IAP] consume failed: %s" % res.get("debug_message", ""))


func _on_acknowledged(res: Dictionary) -> void:
	if int(res.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		push_warning("[IAP] acknowledge failed: %s" % res.get("debug_message", ""))


func _error_text(code: int) -> Dictionary:
	match code:
		BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE, BillingClient.BillingResponseCode.NETWORK_ERROR, BillingClient.BillingResponseCode.SERVICE_DISCONNECTED:
			return {"id": "Tidak bisa terhubung ke Google Play. Cek internet lalu coba lagi.", "en": "Couldn't reach Google Play. Check your connection and try again."}
		BillingClient.BillingResponseCode.BILLING_UNAVAILABLE:
			return {"id": "Pembayaran Google Play tidak tersedia di perangkat ini.", "en": "Google Play billing isn't available on this device."}
		BillingClient.BillingResponseCode.ITEM_UNAVAILABLE:
			return {"id": "Produk ini sedang tidak tersedia.", "en": "This product is currently unavailable."}
	return {"id": "Pembelian gagal (kode %d)." % code, "en": "Purchase failed (code %d)." % code}
