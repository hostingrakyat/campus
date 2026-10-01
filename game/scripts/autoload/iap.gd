extends Node
## In-app purchase facade. Sample build simulates purchases after a confirmation.
## To ship: use the official GodotGooglePlayBilling plugin (see docs/MONETIZATION.md).

signal purchased(product_id: String)


func is_owned(product_id: String) -> bool:
	return Meta.purchases.get(product_id, false)


func can_buy(product_id: String) -> bool:
	var p: Dictionary = Data.IAP_PRODUCTS[product_id]
	return not (p.get("once", false) and is_owned(product_id))


## Called by the shop after the user confirms. Grants the product.
func buy(product_id: String) -> bool:
	if not can_buy(product_id):
		return false
	var p: Dictionary = Data.IAP_PRODUCTS[product_id]
	Meta.purchases[product_id] = true
	if p.get("no_ads", false):
		Meta.no_ads = true
	if p.has("item"):
		Meta.owned[p.item] = true
	Meta.add_diamonds(int(p.get("diamonds", 0)))
	purchased.emit(product_id)
	return true
