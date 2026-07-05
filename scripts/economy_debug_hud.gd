extends VBoxContainer

@onready var moneyLabel: Label = $MoneyLabel
@onready var quotaLabel: Label = $QuotaLabel
@onready var saleLabel: Label = $SaleLabel

func _ready() -> void:
	RunEconomy.moneyChanged.connect(_on_money_changed)
	RunEconomy.quotaProgressChanged.connect(_on_quota_progress_changed)
	RunEconomy.mineral_banked.connect(_on_mineral_banked)

	_on_money_changed(RunEconomy.runMoney)
	_on_quota_progress_changed(
		RunEconomy.earnedQuotaProgress,
		RunEconomy.levelQuota
	)

func _on_money_changed(wallet: int) -> void:
	moneyLabel.text = "Money %d" % wallet
	pulse_label(moneyLabel)

func _on_quota_progress_changed(
	earned: int,
	quota: int
) -> void:
	quotaLabel.text = "Quota %d / %d" % [earned,quota]
	
	if earned >= quota:
		quotaLabel.text += "- REACHED!"
		
	pulse_label(quotaLabel)
func _on_mineral_banked(
	data: MineralData,
	finalValue: int,
	_context: Dictionary
) -> void:
	saleLabel.text = "%s sold for %d" % [data.displayName, finalValue]
	
func pulse_label(label:Label) -> void:
	label.scale = Vector2(1.15,1.15)
	
	var tween := create_tween()
	tween.tween_property(
		label,
		"scale",
		Vector2.ONE,
		0.2
	)
