extends Resource
class_name MineralSpawnEntry

@export var mineralScene: PackedScene
@export_range(0.0, 1000.0, 0.1) var weight: float = 1.0
@export var affectedByDiscovery: bool = false
