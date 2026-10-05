extends Node
## Real AdMob via the Poing Studios plugin. Ads (autoload) only loads this script on Android when the
## native plugin singleton exists, so desktop runs and tests never touch the SDK.
## Flow: UMP consent -> MobileAds.initialize -> preload one rewarded + one interstitial, reload after use.

const RETRY_BASE := 8.0
const RETRY_MAX := 180.0

var rewarded_unit := ""
var interstitial_unit := ""
var initialized := false

var _rewarded: RewardedAd
var _interstitial: InterstitialAd
var _rewarded_loader := RewardedAdLoader.new()
var _interstitial_loader := InterstitialAdLoader.new()
var _loading := {"rewarded": false, "interstitial": false}
var _fails := {"rewarded": 0, "interstitial": 0}


func start(p_rewarded_unit: String, p_interstitial_unit: String) -> void:
	rewarded_unit = p_rewarded_unit
	interstitial_unit = p_interstitial_unit
	var info := UserMessagingPlatform.consent_information
	info.update(ConsentRequestParameters.new(), func():
		if info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED and info.get_is_consent_form_available():
			UserMessagingPlatform.load_consent_form(
				func(form: ConsentForm): form.show(func(_err: FormError): _init_sdk()),
				func(_err: FormError): _init_sdk())
		else:
			_init_sdk(),
		func(err: FormError):
			push_warning("[Ads] consent update failed: %s" % (err.message if err else "?"))
			_init_sdk())


## True when the user must be able to reopen the consent form (EEA/UK); shown in Settings.
func privacy_options_required() -> bool:
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form(func(_err: FormError): pass)


func _init_sdk() -> void:
	if initialized:
		return
	var cfg := RequestConfiguration.new()
	# Campus satire with mental-health themes: teen content at most, never child-directed.
	cfg.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_T
	MobileAds.set_request_configuration(cfg)
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus):
		initialized = true
		_load_rewarded()
		_load_interstitial()
	MobileAds.initialize(listener)


func has_rewarded() -> bool:
	return _rewarded != null


func has_interstitial() -> bool:
	return _interstitial != null


## on_done(result: String) with "earned", "skipped" (closed early) or "failed" (could not show).
func show_rewarded(on_done: Callable) -> void:
	var ad := _rewarded
	_rewarded = null
	if ad == null:
		on_done.call("failed")
		return
	var earned := [false]
	var fsc := FullScreenContentCallback.new()
	fsc.on_ad_showed_full_screen_content = func(): Audio.duck(true)
	fsc.on_ad_dismissed_full_screen_content = func():
		ad.destroy()
		Audio.duck(false)
		_load_rewarded()
		# The reward callback can land a moment after the dismiss on some devices.
		await get_tree().create_timer(0.25).timeout
		on_done.call("earned" if earned[0] else "skipped")
	fsc.on_ad_failed_to_show_full_screen_content = func(err: AdError):
		push_warning("[Ads] rewarded failed to show: %s" % err.message)
		ad.destroy()
		Audio.duck(false)
		_load_rewarded()
		on_done.call("failed")
	ad.full_screen_content_callback = fsc
	var reward := OnUserEarnedRewardListener.new()
	reward.on_user_earned_reward = func(_item: RewardedItem): earned[0] = true
	ad.show(reward)


## on_done(shown: bool)
func show_interstitial(on_done: Callable) -> void:
	var ad := _interstitial
	_interstitial = null
	if ad == null:
		on_done.call(false)
		return
	var fsc := FullScreenContentCallback.new()
	fsc.on_ad_showed_full_screen_content = func(): Audio.duck(true)
	fsc.on_ad_dismissed_full_screen_content = func():
		ad.destroy()
		Audio.duck(false)
		_load_interstitial()
		on_done.call(true)
	fsc.on_ad_failed_to_show_full_screen_content = func(err: AdError):
		push_warning("[Ads] interstitial failed to show: %s" % err.message)
		ad.destroy()
		Audio.duck(false)
		_load_interstitial()
		on_done.call(false)
	ad.full_screen_content_callback = fsc
	ad.show()


func _load_rewarded() -> void:
	if _loading.rewarded or _rewarded != null or rewarded_unit == "":
		return
	_loading.rewarded = true
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd):
		_loading.rewarded = false
		_fails.rewarded = 0
		_rewarded = ad
	cb.on_ad_failed_to_load = func(err: LoadAdError):
		_loading.rewarded = false
		push_warning("[Ads] rewarded load failed (%d): %s" % [err.code, err.message])
		_retry_later("rewarded", _load_rewarded)
	_rewarded_loader.load(rewarded_unit, AdRequest.new(), cb)


func _load_interstitial() -> void:
	if _loading.interstitial or _interstitial != null or interstitial_unit == "":
		return
	_loading.interstitial = true
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd):
		_loading.interstitial = false
		_fails.interstitial = 0
		_interstitial = ad
	cb.on_ad_failed_to_load = func(err: LoadAdError):
		_loading.interstitial = false
		push_warning("[Ads] interstitial load failed (%d): %s" % [err.code, err.message])
		_retry_later("interstitial", _load_interstitial)
	_interstitial_loader.load(interstitial_unit, AdRequest.new(), cb)


## Exponential backoff so a device without network (or no fill) doesn't hammer the SDK.
func _retry_later(kind: String, loader: Callable) -> void:
	_fails[kind] += 1
	var wait := minf(RETRY_MAX, RETRY_BASE * pow(2.0, _fails[kind] - 1))
	await get_tree().create_timer(wait).timeout
	loader.call()
