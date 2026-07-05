extends Resource
class_name LevelData

@export var mineralTable: Array[MineralSpawnEntry] = []
@export_range(1, 32, 1) var targetMineralCount: int = 3
@export var persistentPrizeField: bool = true
@export var testSeed: int = 12345
