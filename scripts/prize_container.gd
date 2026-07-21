extends Node2D
@export_category("Alien Spawning")
@export var alien_Scene: PackedScene
@export_range(0,30,1) var targetAlienCount: int = 30
@export var chuteArea: Area2D
@export var killZone: Area2D

@export_category("Shared Spawn Area")
@export var spawn_top_left: Marker2D
@export var spawn_bottom_right: Marker2D
@export var minimumSpawnSeparation: float = 10.0
@export var spawnAttemptCount: int = 240
@export var killZoneAvoidDistance: float = 24.0

@export_category("Mineral Spawning")
@export var levelData: LevelData
@export var discoveryMultiplier: float = 1.0
@export var chuteAvoidDistance: float = 160.0

var rng := RandomNumberGenerator.new()
var mineralRng := RandomNumberGenerator.new()
var reset_count: int = 0

var activeDifficulty: Dictionary = {}

const ALIEN_RESOURCE_FOLDER := "res://resources/aliens/"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if not validate_spawn_area():
		#return
	if levelData != null:
		for error in levelData.get_validation_errors():
			push_warning(error)
			
		mineralRng.seed = levelData.testSeed
		rng.seed = levelData.testSeed + 1
	else:
		mineralRng.randomize()
		rng.randomize()
		
	#spawnLittleGuys()
	#prepare_next_attempt()
	
func validate_spawn_area() -> bool:
	if spawn_top_left == null:
		push_error("PrizeSpawnTopLeft is not assigned.")
		return false
		
	if spawn_bottom_right == null:
		push_error("PrizeSpawnBottomRight is not assigned.")
		return false
		
	return true
	
func spawnLittleGuys() -> void:
	if alien_Scene == null:
		push_warning("No alien scene assigned.")
		return

	for index in range(targetAlienCount):
		spawnLittleGuy()
		

func spawnLittleGuy() -> void:
		
	var alien := alien_Scene.instantiate() as AlienPrize
	
	if alien == null:
		push_error("Alien scene root must use AlienPrize.")
		return
		
	var chosen_data := choose_alien_data()
	alien.set_meta("can_score_in_chute", false)
	
	if chosen_data != null:
		alien.alien_data = chosen_data
		
	add_child(alien)
	
	alien.global_position = get_clear_spawn_position(rng)
	alien.rotation = rng.randf_range(-1.0, 1.0)
	alien.freeze = true
	alien.linear_velocity = Vector2.ZERO
	alien.angular_velocity = 0.0
	alien.collision_layer = 2
	alien.collision_mask = 35

	call_deferred("_unfreeze_prize", alien)
	
func get_all_alien_data() -> Array[AlienData]:
	var aliens: Array[AlienData] = []
	var files := DirAccess.get_files_at(ALIEN_RESOURCE_FOLDER)
	
	for file_name in files:
		if not file_name.ends_with(".tres"):
			continue
			
		var path := ALIEN_RESOURCE_FOLDER + file_name
		var resource := load(path)
	
		if resource is AlienData:
			aliens.append(resource as AlienData)
			
	return aliens
	
func choose_alien_data() -> AlienData:
	var aliens := get_all_alien_data()
	
	if aliens.is_empty():
		return null
		
	var total_weight := 0.0
	var last_valid_alien: AlienData = null
	
	for alien_data in aliens:
		if alien_data == null:
			continue
			
		var effective_weight := get_effective_alien_spawn_weight(alien_data)
		
		if effective_weight <= 0.0:
			continue	
			
		total_weight += effective_weight
		last_valid_alien = alien_data
		
	if total_weight <= 0.0:
		return last_valid_alien
		
	var roll := rng.randf_range(0.0, total_weight)
	
	for alien_data in aliens:
		if alien_data == null:
			continue
			
		var effective_weight := get_effective_alien_spawn_weight(alien_data)
		
		if effective_weight <= 0.0:
			continue
			
		roll -= effective_weight
		
		if roll <= 0.0:
			return alien_data
			
	return last_valid_alien
	
func get_random_spawn_position(
	generator: RandomNumberGenerator
) -> Vector2:
	if spawn_top_left == null or spawn_bottom_right == null:
		return global_position
		
	var minimumX := minf(
		spawn_top_left.global_position.x,
		spawn_bottom_right.global_position.x
	)
	var maximumX := maxf(
		spawn_top_left.global_position.x,
		spawn_bottom_right.global_position.x
	)
	var minimumY := minf(
		spawn_top_left.global_position.y,
		spawn_bottom_right.global_position.y
	)
	var maximumY := maxf(
		spawn_top_left.global_position.y,
		spawn_bottom_right.global_position.y
	)
	
	return Vector2(
		generator.randf_range(minimumX, maximumX),
		generator.randf_range(minimumY, maximumY)
	)
	
func get_clear_spawn_position(
	generator: RandomNumberGenerator, ignoredPrize: RigidBody2D = null
) -> Vector2:
	for attempt in range(spawnAttemptCount):
		var candidate := get_random_spawn_position(
			generator
		)
		
		if is_spawn_position_clear(
			candidate, ignoredPrize
		):
			return candidate
			
	var fallbackPosition := get_best_fallback_spawn_position(ignoredPrize)
	push_warning("No clear spawn position found. Using best fallback spawn position.")
	return fallbackPosition
	
func get_spawn_area_center() -> Vector2:
	if spawn_top_left == null or spawn_bottom_right == null:
		return global_position
	
	return (spawn_top_left.global_position + spawn_bottom_right.global_position)*0.5

func get_spawn_rect() -> Rect2:
	if spawn_top_left == null or spawn_bottom_right == null:
		return Rect2(global_position, Vector2.ZERO)
		
	var minimumX := minf(
		spawn_top_left.global_position.x,
		spawn_bottom_right.global_position.x
	)
	var maximumX := maxf(
		spawn_top_left.global_position.x,
		spawn_bottom_right.global_position.x
	)
	var minimumY := minf(
		spawn_top_left.global_position.y,
		spawn_bottom_right.global_position.y
	)
	var maximumY := maxf(
		spawn_top_left.global_position.y,
		spawn_bottom_right.global_position.y
	)
	
	return Rect2(
		Vector2(minimumX, minimumY),
		Vector2(maximumX - minimumX, maximumY - minimumY)
	)

func get_best_fallback_spawn_position(
	ignoredPrize: RigidBody2D = null
) -> Vector2:
	var spawnRect := get_spawn_rect()
	
	if spawnRect.size == Vector2.ZERO:
		return global_position
		
	var bestPosition := spawnRect.get_center()
	var bestScore := -INF
	var sampleCount := 8
	
	for xIndex in range(sampleCount):
		for yIndex in range(sampleCount):
			var candidate := Vector2(
				spawnRect.position.x
				+ spawnRect.size.x
				* ((float(xIndex) + 0.5) / float(sampleCount)),
				spawnRect.position.y
				+ spawnRect.size.y
				* ((float(yIndex) + 0.5) / float(sampleCount))
			)
			
			if is_position_near_chute(candidate):
				continue
				
			if is_position_near_kill_zone(candidate):
				continue
				
			var score := get_spawn_spacing_score(
				candidate,
				ignoredPrize
			)
			
			if score > bestScore:
				bestScore = score
				bestPosition = candidate
				
	return bestPosition

func get_spawn_spacing_score(
	candidate: Vector2,
	ignoredPrize: RigidBody2D = null
) -> float:
	var closestDistance := 100000.0
	
	for child in get_children():
		if not child is RigidBody2D:
			continue
			
		var prize := child as RigidBody2D
		
		if prize == ignoredPrize:
			continue
			
		if prize.is_queued_for_deletion():
			continue
			
		closestDistance = minf(
			closestDistance,
			prize.global_position.distance_to(candidate)
		)
		
	return closestDistance
	
func is_spawn_position_clear(
	candidate: Vector2,
	ignoredPrize: RigidBody2D = null
) -> bool:

	if is_position_near_chute(candidate):
		return false
		
	if is_position_near_kill_zone(candidate):
		return false
		
	for child in get_children():
		if not child is RigidBody2D:
			continue
			
		var prize := child as RigidBody2D
		
		if prize == ignoredPrize:
			continue
		
		if prize.is_queued_for_deletion():
			continue
			
		if prize.global_position.distance_to(candidate) < minimumSpawnSeparation:
			return false
			
	return true
	
func is_position_near_chute(world_position: Vector2) -> bool:

	if chuteArea == null:
		return false
		
	if world_position.distance_to(chuteArea.global_position) < chuteAvoidDistance:
		return true
		
	return is_position_near_area_collision(
		chuteArea,
		world_position,
		chuteAvoidDistance
	)
	
func is_position_near_kill_zone(world_position: Vector2) -> bool:
	if killZone == null:
		return false
		
	return is_position_near_area_collision(
		killZone,
		world_position,
		killZoneAvoidDistance
	)
	
func is_position_near_area_collision(
	area: Area2D,
	world_position: Vector2,
	padding: float
) -> bool:
	for child in area.get_children():
		if not child is CollisionShape2D:
			continue
			
		var collisionShape := child as CollisionShape2D
		
		if collisionShape.disabled:
			continue
			
		if collisionShape.shape == null:
			continue
			
		var localPosition := collisionShape.to_local(world_position)
		
		if collisionShape.shape is RectangleShape2D:
			var rectangle := collisionShape.shape as RectangleShape2D
			var paddedHalfSize := (
				rectangle.size * 0.5
				+ Vector2.ONE * padding
			)
			
			if (
				abs(localPosition.x) <= paddedHalfSize.x
				and abs(localPosition.y) <= paddedHalfSize.y
			):
				return true
				
		elif collisionShape.shape is CircleShape2D:
			var circle := collisionShape.shape as CircleShape2D
			
			if localPosition.length() <= circle.radius + padding:
				return true
				
	return false
	
func _on_kill_zone_body_entered(body: Node2D) -> void:
	if not body is RigidBody2D:
		return
	
	var prize := body as RigidBody2D
	
	if not prize.is_in_group("prizes"):
		return
	
	if not is_instance_valid(prize):
		return
		
	call_deferred("reset_prize", prize)

func reset_prize(prize: RigidBody2D) -> void:
	if not is_instance_valid(prize):
		return

	if prize.is_queued_for_deletion():
		return

	prize.freeze = true

	if prize is MineralPrize:
		prize.global_position = get_clear_spawn_position(mineralRng, prize)
	else:
		prize.global_position = get_clear_spawn_position(rng, prize)

	prize.linear_velocity = Vector2.ZERO
	prize.angular_velocity = 0.0
	prize.rotation = 0.0

	# Restore expected prize collision settings.
	prize.collision_layer = 2
	prize.collision_mask = 35

	prize.set_meta("can_score_in_chute", false)
	prize.freeze = false
	prize.sleeping = false

	reset_count += 1
	print("Escaped prizes reset: ", reset_count)

func prepare_next_attempt() -> void:
	if levelData == null:
		push_error("Prize container has no LevelData.")
		return
		
	var activeMinerals := get_active_minerals()
	
	if not levelData.persistentPrizeField:
		for mineral in activeMinerals:
			mineral.queue_free()
			
		activeMinerals.clear()
		
	var missingCount := maxi(
		0,
		levelData.targetMineralCount-activeMinerals.size()
	)
	
	for index in range(missingCount):
		spawn_mineral()
		
func get_active_minerals() -> Array[MineralPrize]:
	var minerals: Array[MineralPrize] = []
	for child in get_children():
		if not child is MineralPrize:
			continue
			
		var mineral := child as MineralPrize
		
		if mineral.is_queued_for_deletion():
			continue
			
		minerals.append(mineral)
		
	return minerals
	
func spawn_mineral() -> void:
	var mineralScene := choose_mineral_scene()
	
	if mineralScene == null:
		push_warning("No Mineral Scene is avialable.")
		return
		
	var mineral := mineralScene.instantiate() as MineralPrize
	mineral.set_meta("can_score_in_chute", false)
	
	if mineral == null:
		push_error("Mineral scene root must use MineralPrize.")
		return
		
	add_child(mineral)
	
	var minimumWeight := float(
		activeDifficulty.get(
			"minimum_prize_weight", 
			0.5
		)
	)
	
	var maximumWeight := float(
		activeDifficulty.get(
			"maximum_prize_weight", 
			5.0
		)
	)
	
	if mineral.mineral_data != null:
		mineral.mass = clampf(
			mineral.mineral_data.weight,
			minimumWeight,
			maximumWeight
		)
	else:
		push_warning("Spawned mineral is missing MineralData.")
		
	mineral.freeze = true
	mineral.set_meta("can_score_in_chute", false)
	mineral.global_position = get_clear_spawn_position(mineralRng)
	mineral.rotation = 0.0
	mineral.linear_velocity = Vector2.ZERO
	mineral.angular_velocity = 0.0
	
	call_deferred("_unfreeze_prize", mineral)
	
func choose_mineral_scene() -> PackedScene:
	if levelData == null:
		return null
		
	if levelData.mineralTable.is_empty():
		return null
		
	var totalWeight: float = 0.0
	var lastValidScene: PackedScene = null
	
	for entry in levelData.mineralTable:
		if entry == null:
			continue
			
		if entry.mineralScene == null:
			continue
			
		if entry.mineralData == null:
			continue
			
		var effectiveWeight := (get_effective_spawn_weight(entry))
		
		if effectiveWeight <= 0.0:
			continue
			
		totalWeight += effectiveWeight
		lastValidScene = entry.mineralScene
		
	if totalWeight <= 0.0:
		return null
			
	var roll := mineralRng.randf_range(0.0, totalWeight)
		
	for entry in levelData.mineralTable:
		if entry == null:
			continue
				
		if entry.mineralScene == null:
			continue
			
		if entry.mineralData == null:
			continue
			
		var effectiveWeight := (
			get_effective_spawn_weight(entry)
		)
			

		if effectiveWeight <= 0.0:
			continue
				
		roll -= effectiveWeight
			
		if roll <= 0.0:
			return entry.mineralScene
				
	return lastValidScene
	
func _on_attempt_finished() -> void:
	call_deferred("prepare_next_attempt")	

func _unfreeze_prize(prize: RigidBody2D) -> void:
	if not is_instance_valid(prize):
		return
		
	prize.freeze = false
	prize.sleeping = false
	
func load_level(newLevelData: LevelData, resolvedDifficulty: Dictionary) -> void:
	if newLevelData == null:
		push_error("Cannot load null LevelData.")
		return
	levelData = newLevelData
	activeDifficulty = resolvedDifficulty
	
	for error in levelData.get_validation_errors():
		push_warning(error)
	mineralRng.seed = levelData.testSeed
	rng.seed = levelData.testSeed + 1
	
	for mineral in get_active_minerals():
		mineral.queue_free()
		
	call_deferred("_finish_level_load")
	
func _finish_level_load() -> void:
	var resolvedQuota := int(
		activeDifficulty.get(
			"quota",
			levelData.earningsQuota
		)
	)
	
	if not validate_spawn_area():
		return
	RunEconomy.start_level(
		resolvedQuota
	)
	
	clear_aliens()
	spawnLittleGuys()
	prepare_next_attempt()

func clear_aliens() -> void:
	for child in get_children():
		if child is AlienPrize:
			child.queue_free()
func get_effective_alien_spawn_weight(alien_data: AlienData) -> float:
	if alien_data == null:
		return 0.0
		
	var effective_weight := alien_data.spawn_weight
	
	match alien_data.rarity:
		AlienData.Rarity.RARE, AlienData.Rarity.EPIC, AlienData.Rarity.LEGENDARY, AlienData.Rarity.THECHOSEN:
			effective_weight *= AlienCollection.get_rare_alien_spawn_multiplier()
			
	return maxf(0.0, effective_weight)
	
func get_effective_spawn_weight(
	entry: MineralSpawnEntry
) -> float:
	if entry == null or entry.mineralData == null:
		return 0.0
		
	var effectiveWeight := (
		entry.mineralData.spawn_weight
	)
	
	match entry.mineralData.rarity:
		MineralData.Rarity.COMMON,\
		MineralData.Rarity.UNCOMMON,\
		MineralData.Rarity.RARE:
			effectiveWeight *= float(
				activeDifficulty.get(
					"common_multiplier",
					1.0
				)
			)
		
		_:
			effectiveWeight *= float(
				activeDifficulty.get(
					"rare_multiplier",
					1.0
				)
			)
			
			effectiveWeight *= AlienCollection.get_rare_mineral_spawn_multiplier()
			
	if entry.affectedByDiscovery:
		effectiveWeight *= discoveryMultiplier
		
	return maxf(0.0, effectiveWeight)
