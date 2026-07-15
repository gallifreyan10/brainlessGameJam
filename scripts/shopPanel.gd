extends PanelContainer

@export var runManager: RunManager 
@export var suitCatalog: Array[SuitData] = []
@export var offeredSuits: Array[SuitData] = []
@export var rerollCost: int = 5
@export var offerCount: int = 3
var rng := RandomNumberGenerator.new()
var purchase_in_progress: bool = false
const TITLE_COLOR := Color("#FFD36A")
const DETAIL_COLOR := Color("#7CFFD6")

@onready var offersContainer: VBoxContainer = $VBoxContainer/OffersContainer
@onready var rerollButton: Button = $VBoxContainer/RerollButton
@onready var continueButton: Button = $VBoxContainer/ContinueButton
@onready var statusLabel: Label = $VBoxContainer/StatusLabel
@onready var contentBox: VBoxContainer = $VBoxContainer

@export var button_hover_sfx: AudioStream
@export var button_click_sfx: AudioStream

func _ready() -> void:
	visible = false
	_set_panel_rect(Vector2(460, 310), Vector2(150, 30))
	_wrap_content_in_margin(34)
	
	var title_label := Label.new()
	title_label.text = "Suit Shop"
	title_label.add_theme_color_override("font_color", TITLE_COLOR)
	title_label.add_theme_font_size_override("font_size", 14)
	contentBox.add_child(title_label)
	contentBox.move_child(title_label, 0)
	
	contentBox.add_theme_constant_override("separation", 6)
	
	var scroll := ScrollContainer.new()
	scroll.name = "OffersScroll"
	scroll.custom_minimum_size = Vector2(360, 160)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var offers_index := offersContainer.get_index()
	contentBox.remove_child(offersContainer)
	contentBox.add_child(scroll)
	contentBox.move_child(scroll, offers_index)
	scroll.add_child(offersContainer)
	
	offersContainer.custom_minimum_size = Vector2(360, 160)
	
	rerollButton.custom_minimum_size = Vector2(130, 28)
	continueButton.custom_minimum_size = Vector2(130, 28)
	rerollButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continueButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	statusLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	statusLabel.custom_minimum_size = Vector2(360, 0)
	
	rng.randomize()

	if runManager == null:
		push_error("ShopPanel needs RunManager assigned.")
		return
		
	runManager.shopRequested.connect(_on_shop_requested)
	RunEconomy.moneyChanged.connect(_on_money_changed)
	runManager.suitsCleared.connect(_refresh)
	runManager.newRunStarted.connect(_on_new_run_started)
	runManager.suitEquipped.connect(_on_suit_equipped)
	
	rerollButton.pressed.connect(_on_reroll_pressed)
	continueButton.pressed.connect(_on_continue_pressed)
	UIStyleHelper.apply_hologram_button_style(rerollButton)
	UIStyleHelper.apply_hologram_button_style(continueButton)
	rerollButton.mouse_entered.connect(_on_button_hovered)
	continueButton.mouse_entered.connect(_on_button_hovered)

	repopulate_shop()
	_refresh()
	
func _on_shop_requested() -> void:
	visible = true
	statusLabel.text = ""
	_refresh()

func _on_suit_equipped(_suit: SuitData) -> void:
	_refresh()
	
func _on_money_changed(_wallet: int) -> void:
	_refresh()
	
func _refresh() -> void:
	
	for child in offersContainer.get_children():
		child.queue_free()
		
	if suitCatalog.is_empty():
		statusLabel.text = "No Suits available."
		rerollButton.disabled = true
		return
		
	for suit in offeredSuits:
		var row := create_offer_row(suit)
		offersContainer.add_child(row)
		
	rerollButton.text = "Reroll: %d" % rerollCost
	rerollButton.disabled = not RunEconomy.can_afford(rerollCost)
	
func _on_button_hovered() -> void:
	SFXManager.play_sfx(button_hover_sfx, -6.0)
	
func create_offer_row(suit: SuitData) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(350, 72)
	row.add_theme_constant_override("separation", 6)
	
	var iconRect := TextureRect.new()
	var textBox := VBoxContainer.new()
	var nameLabel := Label.new()
	var stateLabel := Label.new()
	var buffLabel := Label.new()
	var priceLabel := Label.new()
	var buyButton := Button.new()
	buyButton.mouse_entered.connect(_on_button_hovered)
	
	var price : int = get_discounted_price(suit)
	var owned : bool = runManager.ownedSuits.has(suit)
	var equipped : bool= runManager.equippedSuit == suit
	var affordable : bool = RunEconomy.can_afford(price)
	
	iconRect.texture = suit.icon
	iconRect.custom_minimum_size = Vector2(48,48)
	iconRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	iconRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	nameLabel.text = suit.displayName
	nameLabel.add_theme_font_size_override("font_size", 10)
	nameLabel.add_theme_color_override("font_color", DETAIL_COLOR)
	stateLabel.text = get_suit_state_text(suit)
	buffLabel.text = get_suit_buff_text(suit)
	
	if price != suit.price:
		priceLabel.text = "Price: %d Original %d" % [price, suit.price]
	else:
		priceLabel.text = "Price: %d" % price
		
	textBox.custom_minimum_size = Vector2(230, 0)
	textBox.add_theme_constant_override("separation", 1)
	buffLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buffLabel.add_theme_font_size_override("font_size", 8)
	stateLabel.add_theme_font_size_override("font_size", 8)
	priceLabel.add_theme_font_size_override("font_size", 8)
	nameLabel.custom_minimum_size = Vector2(170,0)
	priceLabel.custom_minimum_size = Vector2(130,0)
	
	buyButton.custom_minimum_size = Vector2(70, 28)
	buyButton.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buyButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyleHelper.apply_hologram_button_style(buyButton)
	
	if equipped:
		buyButton.text = "Equipped"
		buyButton.disabled = true
	elif owned:
		buyButton.text = "Equip"
		buyButton.disabled = false
	elif affordable:
		buyButton.text = "Buy"
		buyButton.disabled = false
	else:
		buyButton.text = "Need %d" % (price - RunEconomy.runMoney)
		buyButton.disabled = true
	
	buyButton.tooltip_text = get_purchase_reason(suit)
	buyButton.pressed.connect(func() -> void: _on_buy_pressed(suit))
	
	textBox.add_child(nameLabel)
	textBox.add_child(stateLabel)
	textBox.add_child(buffLabel)
	textBox.add_child(priceLabel)
	
	row.add_child(iconRect)
	row.add_child(textBox)
	row.add_child(buyButton)
	
	return row

func _on_buy_pressed(suit: SuitData) -> void:
	SFXManager.play_sfx(button_click_sfx)
	if purchase_in_progress:
		return
	
	purchase_in_progress = true
	
	if suit == null:
		statusLabel.text = "Missing Suit Data."
		_refresh()
		return
		
	var price := get_discounted_price(suit)	
	
	if runManager.equippedSuit == suit:
		statusLabel.text = "%s is already equipped." % suit.displayName
		purchase_in_progress = false
		_refresh()
		return
		
	if runManager.ownedSuits.has(suit):
		if runManager.equip_owned_suit(suit):
			statusLabel.text = "Equipped %s." % suit.displayName
		else:
			statusLabel.text = "Could not equip %s." % suit.displayName
		
		purchase_in_progress = false
		_refresh()
		return
		
	if not RunEconomy.can_afford(price):
		statusLabel.text = "Not enough money in wallet. Need %d more." % (price-RunEconomy.runMoney)
		purchase_in_progress = false
		_refresh()
		return
	
	var wallet_before : int = RunEconomy.runMoney	
	var bought := runManager.buy_and_equip_suit(suit, price)
	
	if bought:
		var wallet_after : int = RunEconomy.runMoney
		statusLabel.text = "Bought %s for %d. Wallet: %d → %d" % [
			suit.displayName,
			price,
			wallet_before,
			wallet_after
		]
	else:
		statusLabel.text = "Purchase failed. Wallet was not changed."
	
	purchase_in_progress = false	
	_refresh()
	
func _on_reroll_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	if not RunEconomy.spend_money(rerollCost):
		statusLabel.text = "Not enough money to reroll."
		_refresh()
		return	
	
	repopulate_shop()
	statusLabel.text = "Shop Rerolled."
	_refresh()
	
func _on_continue_pressed() -> void:
	SFXManager.play_sfx(button_click_sfx)
	visible = false
	runManager.leave_shop_and_continue()
	
func get_discounted_price(suit: SuitData) -> int:
	if suit == null:
		return 0
		
	var multiplier : float = AlienCollection.get_suit_price_multiplier()
	return max(1, int(round(suit.price*multiplier)))
	
func _on_new_run_started() -> void:
	repopulate_shop()
	_refresh()
	
func repopulate_shop() -> void:
	offeredSuits.clear()
	
	var availableSuits: Array[SuitData] = []
	
	for suit in suitCatalog:
		if suit == null:
			continue
			
		if runManager != null and runManager.ownedSuits.has(suit):
			continue
		
		availableSuits.append(suit)
	
	if availableSuits.is_empty():
		return
		
	while offeredSuits.size() < offerCount and not availableSuits.is_empty():
		var index := rng.randi_range(0, availableSuits.size()-1)
		var suit := availableSuits[index]
		
		offeredSuits.append(suit)
		availableSuits.remove_at(index)

func get_suit_buff_text(suit: SuitData) -> String:
	if suit == null:
		return "No buffs."
		
	var parts: Array[String] = []
	
	if suit.drop_depth_bonus != 0.0:
		parts.append("Drop depth + %.1f" % suit.drop_depth_bonus)
		
	if suit.horizontal_speed_multiplier != 1.0:
		parts.append("Move speed x %.2f" % suit.horizontal_speed_multiplier)
		
	if suit.grab_area_scale_multiplier != 1.0:
		parts.append("Grab area x %.2f" % suit.grab_area_scale_multiplier)
		
	if suit.max_tilt_angle_bonus != 0.0:
		parts.append("Tilt %+0.1f" % suit.max_tilt_angle_bonus)
		
	if suit.second_chance_regrabs > 0:
		parts.append("Second Chance x %d" % suit.second_chance_regrabs)
		
	if suit.blocks_cabinet_shake:
		parts.append("Blocks cabinet shake")
	
	if parts.is_empty():
		return "No buffs"
		
	return "\n".join(parts)

func get_suit_state_text(suit: SuitData) -> String:
	if runManager == null or suit == null:
		return "Unavialable"
		
	if runManager.equippedSuit == suit:
		return "Equipped"
		
	if runManager.ownedSuits.has(suit):
		return "Owned"
		
	var price := get_discounted_price(suit)
	
	if RunEconomy.can_afford(price):
		return "Available"
		
	return "Cannot afford"
	
func get_purchase_reason(suit: SuitData) -> String:
	if suit == null:
		return "Missing suit data."
		
	if runManager == null:
		return "Shop Unavailable."
		
	if runManager.equippedSuit == suit:
		return "Already Equipped."
		
	if runManager.ownedSuits.has(suit):
		return "Owned. Click to equip"
		
	var price := get_discounted_price(suit)
	
	if not RunEconomy.can_afford(price):
		return "Need %d more wallet." % (price - RunEconomy.runMoney)
		
	return "Spends %d wallet. Remaining wallet: %d." % [
		price,
		RunEconomy.runMoney - price
	]

func _set_panel_rect(panel_size: Vector2, top_left: Vector2) -> void:
	custom_minimum_size = panel_size
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = top_left.x
	offset_top = top_left.y
	offset_right = top_left.x + panel_size.x
	offset_bottom = top_left.y + panel_size.y

func _wrap_content_in_margin(padding: int) -> void:
	if contentBox.get_parent() is MarginContainer:
		return
	
	var margin_container := MarginContainer.new()
	margin_container.name = "RuntimeMargin"
	margin_container.add_theme_constant_override("margin_left", padding)
	margin_container.add_theme_constant_override("margin_right", padding)
	margin_container.add_theme_constant_override("margin_top", padding)
	margin_container.add_theme_constant_override("margin_bottom", padding)
	
	remove_child(contentBox)
	add_child(margin_container)
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.add_child(contentBox)
		
