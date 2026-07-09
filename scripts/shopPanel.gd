extends PanelContainer

@export var runManager: RunManager 
@export var suitCatalog: Array[SuitData] = []
@export var offeredSuits: Array[SuitData] = []
@export var rerollCost: int = 5
@export var offerCount: int = 3
var rng := RandomNumberGenerator.new()

@onready var moneyLabel: Label = $VBoxContainer/MoneyLabel
@onready var offersContainer: VBoxContainer = $VBoxContainer/OffersContainer
@onready var rerollButton: Button = $VBoxContainer/RerollButton
@onready var continueButton: Button = $VBoxContainer/ContinueButton
@onready var statusLabel: Label = $VBoxContainer/StatusLabel

func _ready() -> void:
	visible = false
	rng.randomize()

	if runManager == null:
		push_error("ShopPanel needs RunManager assigned.")
		return
		
	runManager.shopRequested.connect(_on_shop_requested)
	RunEconomy.moneyChanged.connect(_on_money_changed)
	runManager.suitsCleared.connect(_refresh)
	runManager.newRunStarted.connect(_on_new_run_started)
	
	rerollButton.pressed.connect(_on_reroll_pressed)
	continueButton.pressed.connect(_on_continue_pressed)

	repopulate_shop()
	_refresh()
	
func _on_shop_requested() -> void:
	visible = true
	statusLabel.text = ""
	_refresh()
	
func _on_money_changed(_wallet: int) -> void:
	_refresh()
	
func _refresh() -> void:
	moneyLabel.text = "Money: %d" % RunEconomy.runMoney
	
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

func create_offer_row(suit: SuitData) -> Control:
	var row := HBoxContainer.new()
	
	var nameLabel := Label.new()
	var priceLabel := Label.new()
	var buyButton := Button.new()
	
	var price := get_discounted_price(suit)
	
	nameLabel.text = suit.displayName
	priceLabel.text = "%d" % price
	
	nameLabel.custom_minimum_size = Vector2(150,0)
	priceLabel.custom_minimum_size = Vector2(70,0)
	
	if runManager.ownedSuits.has(suit):
		buyButton.text = "Owned"
		buyButton.disabled = true
	elif not RunEconomy.can_afford(price):
		buyButton.text = "Buy"
		buyButton.disabled = true
	else:
		buyButton.text = "Buy"
		buyButton.disabled = false
		
	buyButton.pressed.connect(func() -> void: _on_buy_pressed(suit))
	
	row.add_child(nameLabel)
	row.add_child(priceLabel)
	row.add_child(buyButton)
	
	return row

func _on_buy_pressed(suit: SuitData) -> void:
	if suit == null:
		return
		
	var price := get_discounted_price(suit)	
	var bought := runManager.buy_and_equip_suit(suit, price)
	
	if bought:
		statusLabel.text = "Equipped %s!" % suit.displayName
	else:
		statusLabel.text = "Not enough money."
		
	_refresh()
	
func _on_reroll_pressed() -> void:
	if not RunEconomy.spend_money(rerollCost):
		statusLabel.text = "Not enough money to reroll."
		_refresh()
		return	
	
	repopulate_shop()
	statusLabel.text = "Shop Rerolled."
	_refresh()
	
func _on_continue_pressed() -> void:
	visible = false
	runManager.leave_shop_and_continue()
	
func get_discounted_price(suit: SuitData) -> int:
	if suit == null:
		return 0
		
	var multiplier := AlienCollection.get_suit_price_multiplier()
	return max(0, int(round(suit.price*multiplier)))
	
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
