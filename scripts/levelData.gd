extends Resource
class_name LevelData

@export var displayName: String = "Level Name"
@export var mineralTable: Array[MineralSpawnEntry] = []
@export_range(1, 32, 1) var targetMineralCount: int = 3
@export var persistentPrizeField: bool = true
@export var testSeed: int = 12345

@export_category("Level Economy")
@export_range(1, 100000, 1) var earningsQuota: int = 30
@export_range(1, 10, 1) var plannedAttemptLimit: int = 3

@export_category("Difficulty")
@export var difficultyCurve: DifficultyCurve
@export var useExplicitQuota: bool = false


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var usedIds: Dictionary = {}
	
	for index in range(mineralTable.size()):
		var entry := mineralTable[index]
		
		if entry == null:
			errors.append("Mineral table entry %d is empty." % index)
			continue
		
		if entry.mineralScene == null:
			errors.append("Entry %d has no Mineral Scene.")
			continue
			
		if entry.mineralData == null:
			errors.append("Entry %d has no MineralData." % index)
			continue
			
		for error in entry.mineralData.get_validation_errors():
			errors.append(error)
			
		var mineralId := entry.mineralData.mineral_id
		
		if usedIds.has(mineralId):
			errors.append("Duplicate mineral ID: %s" % mineralId)
		else:
			usedIds[mineralId] = true
			
	if earningsQuota <= 0:
		errors.append("Earnings quota must be greater than zero.")
		
	var highestSaleValue: int = 0
	
	for entry in mineralTable:
		if entry == null:
			continue
		
		if entry.mineralData == null:
			continue
			
		highestSaleValue = maxi(highestSaleValue,entry.mineralData.sale_value)
	var maximumPossibleEarnings := (
		highestSaleValue* plannedAttemptLimit
	)
	
	if highestSaleValue <= 0:
		errors.append("Level has no mineral with a positive sale value.")
	elif earningsQuota > maximumPossibleEarnings:
		errors.append(
			(
				"Quota %d is unreachable. Maximum with"
				+ 
				"%d attempts is %d."
			)
			%[
				earningsQuota,plannedAttemptLimit,maximumPossibleEarnings
			]
		)
	return errors

func resolve_difficulty(
	levelIndex: int
) -> Dictionary:
	if difficultyCurve == null:
		return{
			"quota": earningsQuota,
			"common_multiplier": 1.0,
			"rare_multiplier": 1.0,
			"minimum_prize_weight": 0.5,
			"maximum_prize_weight": 5.0,
			"timer_multiplier": 1.0
		}
		
	var resolved := difficultyCurve.resolve(levelIndex)
	
	if useExplicitQuota:
		resolved["quota"] = earningsQuota
		
	return resolved
