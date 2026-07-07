extends Node

signal mineral_banked(
	data: MineralData,
	amount: int,
	context: Dictionary
)

signal moneyChanged(wallet:int)
signal levelStarted(quota:int)

signal quotaProgressChanged(
	earnedThisLevel: int,
	quota: int
)

signal quotaReached(
	earnedThisLevel: int,
	quota:int
)

var runMoney: int = 0
var earnedQuotaProgress: int = 0
var levelQuota: int = 100
var quotaWasReached: bool = false

# Called when the node enters the scene tree for the first time.
func build_capture_context() -> Dictionary:
	return{
		"alien_multiplier": 1.0,
		"suit_multiplier": 1.0,
		"alien_icon": null
	}
	
func capture_mineral(
	data: MineralData,
	context: Dictionary
) -> void:
	if data == null:
		push_error("RunEconomy recieved invalid MineralData.")
		return
		
	var alien_multiplier: float = float(context.get("alien_multiplier", 1.0))
	var suit_multiplier: float = float(context.get("suit_multiplier", 1.0))
	
	var finalValue := maxi(
		0,
		roundi(
			data.sale_value
			* alien_multiplier
			* suit_multiplier
		)
	)
	
	runMoney += finalValue
	earnedQuotaProgress += finalValue
	
	mineral_banked.emit(data, finalValue, context)
	moneyChanged.emit(runMoney)
	
	quotaProgressChanged.emit(
		earnedQuotaProgress, 
		levelQuota
	)
	
	if(
		earnedQuotaProgress>=levelQuota
		and not quotaWasReached
	):
		quotaWasReached = true
		
		quotaReached.emit(earnedQuotaProgress, levelQuota)
		
func spend_money(amount:int) -> bool:
	if amount <= 0:
		return false
	if runMoney < amount:
		return false
	runMoney -= amount
	moneyChanged.emit(runMoney)
	
	return true
	
func can_afford(amount: int) -> bool:
	return runMoney >= amount
	
func start_level(newQuota: int) -> void:
	levelQuota = maxi(1, newQuota)
	earnedQuotaProgress = 0
	quotaWasReached = false
	
	quotaProgressChanged.emit(
		earnedQuotaProgress,
		levelQuota
	)
	
	levelStarted.emit(levelQuota)
