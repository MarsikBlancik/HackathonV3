extends Node2D

# 1. ZWIĘKSZONA ODLEGŁOŚĆ! (z 60 na 120, żeby dron latał dalej od ciała)
@export var orbit_distance: float = 120.0 
@export var orbit_speed: float = 2.0

var detection_range: float = 400.0
var damage: int = 1
var tier: int = 1

var angle: float = 0.0
var target_enemy = null

const PROJECTILE_SCENE = preload("res://DroneProjectile.tscn")

# 2. NAPRAWIONE: Funkcja _ready, która łączy Timer z kodem!
func _ready() -> void:
	if not $ShootTimer.timeout.is_connected(_on_shoot_timer_timeout):
		$ShootTimer.timeout.connect(_on_shoot_timer_timeout)

func _process(delta: float) -> void:
	angle += orbit_speed * delta
	var offset = Vector2(cos(angle), sin(angle)) * orbit_distance
	position = offset
	
	find_closest_enemy()
	
	# Zamiast kręcić całym dronem, po prostu odwracamy obrazek (Sprite) w lewo lub prawo!
	if is_instance_valid(target_enemy):
		# Jeśli wróg jest po lewej stronie drona -> odwróć obrazek
		if target_enemy.global_position.x < global_position.x:
			$Sprite2D.flip_h = true
		# Jeśli po prawej -> wróć do normalności
		else:
			$Sprite2D.flip_h = false

func setup(new_tier: int, start_angle: float):
	tier = new_tier
	angle = start_angle
	var shoot_timer = $ShootTimer
	
	match tier:
		1:
			detection_range = 400.0
			damage = 1
			shoot_timer.wait_time = 1.0
		2:
			detection_range = 800.0
			damage = 2
			shoot_timer.wait_time = 0.6
		3:
			detection_range = 1200.0
			damage = 3
			shoot_timer.wait_time = 0.3
			
	shoot_timer.start()

func find_closest_enemy():
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var closest_dist = detection_range
	target_enemy = null
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				target_enemy = enemy

func _on_shoot_timer_timeout() -> void:
	if is_instance_valid(target_enemy):
		shoot()

func shoot():
	if not PROJECTILE_SCENE: return
	
	var proj = PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position
	proj.direction = (target_enemy.global_position - global_position).normalized()
	proj.rotation = proj.direction.angle()
	proj.damage = damage
	
	# Zrzucamy pocisk na główną scenę, żeby nie krążył razem z dronem
	get_tree().current_scene.add_child(proj)
