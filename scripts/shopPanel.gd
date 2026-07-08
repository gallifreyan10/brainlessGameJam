extends PanelContainer

@export var runManager: RunManager
@export var offeredSuit: SuitData

@onready var moneyLabel: Label = $VBoxContainer/MoneyLabel
@onready var offerNameLabel: Label = $VBoxContainer/OfferNameLabel
@onready var priceLabel: Label = $VBoxContainer/PriceLabel
@onready var buyButton: Button = $VBoxContainer/BuyButton
@onready var continueButton: Button = $VBoxContainer/ContinueButton
@onready var statusLabel: Label = $VBoxContainer/StatusLabel

func _ready() -> void:
	visible = false

	if runManager == null:
		push_error("ShopPanel needs RunManager assigned.")
		return
		
	runManager.shopRequested.connect(_on_shop_requested)
	RunEconomy.moneyChanged.connect(_on_money_changed)
	runManager.suitsCleared.connect(_refresh)
	
	buyButton.pressed.connect(_on_buy_pressed)
	continueButton.pressed.connect(_on_continue_pressed)

	_refresh()
	
func _on_shop_requested() -> void:
	visible = true
	statusLabel.text = ""
	_refresh()
	
func _on_money_changed(_wallet: int) -> void:
	_refresh()
	
func _refresh() -> void:
	var price := get_discounted_price()
	moneyLabel.text = "Money: %d" % RunEconomy.runMoney
	
	if offeredSuit == null:
		offerNameLabel.text = "No Suit Available"
		priceLabel.text = ""
		buyButton.disabled = true
		return
		
	offerNameLabel.text = offeredSuit.displayName
	priceLabel.text = "Price: %d" % price
	
	if runManager.ownedSuits.has(offeredSuit):
		buyButton.text = "Owned"
		buyButton.disabled = true
	else:
		buyButton.text = "Buy"
		buyButton.disabled = not RunEconomy.can_afford(price)

func _on_buy_pressed() -> void:
	if offeredSuit == null:
		return
		
	var bought := runManager.buy_and_equip_suit(offeredSuit, get_discounted_price())
	
	if bought:
		statusLabel.text = "Equipped %s!" % offeredSuit.displayName
	else:
		statusLabel.text = "Not enough money."
		
	_refresh()
	
func _on_continue_pressed() -> void:
	visible = false
	runManager.leave_shop_and_continue()
	
func get_discounted_price() -> int:
	if offeredSuit == null:
		return 0
		
	var multiplier := AlienCollection.get_suit_price_multiplier()
	return max(0, int(round(offeredSuit.price*multiplier)))
