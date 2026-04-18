extends Node2D

# 1. SYGNAŁY
signal hp_changed(current_hp: int, max_hp: int)
signal energy_changed(current_energy: int, max_energy: int)
signal xp_changed(current_xp: int, next_level_xp: int)
signal leveled_up(new_level: int)

# 2. MODUŁ STATYSTYK I POZIOMÓW
const BASE_STAT: int = 1 

@export var max_hp: int = BASE_STAT * 3
@export var max_energy: int = BASE_STAT * 3
@export var energy_recharge_time: float = 2.0

var current_hp: int
var current_energy: int
var energy_timer: float = 0.0

# --- NOWE: SYSTEM LEVELI ---
var level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 10 # XP potrzebne na 1 -> 2 level

# 3. MODUŁ RUCHU
@export var speed: float = 200.0
@export var dash_distance: float = 150.0 
@export var dash_duration: float = 0.2    

var is_dashing: bool = false
var last_direction: Vector2 = Vector2.RIGHT 

const BLOOD_SCENE = preload("res://BloodParticles.tscn")

# --- MODUŁ KAMERY (SHAKE) ---
@onready var camera: Camera2D = $Camera2D
var shake_strength: float = 0.0
@export var shake_decay: float = 10.0

# --- MODUŁ FIZYKI (KNOCKBACK) ---
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_friction: float = 10.0

func _ready() -> void:
	add_to_group("Player")
	current_hp = max_hp
	current_energy = max_energy
	
	hp_changed.emit(current_hp, max_hp)
	energy_changed.emit(current_energy, max_energy)
	xp_changed.emit(current_xp, xp_to_next_level)

func _process(delta: float) -> void:
	# Regeneracja energii
	if current_energy < max_energy:
		energy_timer += delta
		if energy_timer >= energy_recharge_time:
			modify_energy(1)
			energy_timer = 0.0
	else:
		energy_timer = 0.0
	
	if is_dashing: return
		
	var input_direction = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_D): input_direction.x += 1
	if Input.is_physical_key_pressed(KEY_A): input_direction.x -= 1 # Poprawione (było x-=1)
	if Input.is_physical_key_pressed(KEY_S): input_direction.y += 1
	if Input.is_physical_key_pressed(KEY_W): input_direction.y -= 1
		
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
		last_direction = input_direction 
		
	# Ruch i Knockback
	var move_velocity = input_direction * speed
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_friction * delta)
	position += (move_velocity + knockback_velocity) * delta
	
	# Shake kamery
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0.0, shake_decay * delta)
		var random_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		camera.offset = random_offset * shake_strength
		if shake_strength < 0.1:
			shake_strength = 0.0
			camera.offset = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE and not is_dashing:
			perform_dash()
		# DEBUG: Klawisz L dodaje XP do testów
		if event.physical_keycode == KEY_L:
			gain_xp(5)
			
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			attack()

# --- NOWE: FUNKCJA XP ---
func gain_xp(amount: int) -> void:
	current_xp += amount
	print("XP: ", current_xp, "/", xp_to_next_level)
	
	while current_xp >= xp_to_next_level:
		level_up()
	
	xp_changed.emit(current_xp, xp_to_next_level)

func level_up() -> void:
	current_xp -= xp_to_next_level
	level += 1
	xp_to_next_level = int(xp_to_next_level * 1.5) # Każdy kolejny level trudniej wbić
	
	leveled_up.emit(level)
	print("LEVEL UP! Obecny poziom: ", level)
	
	# Bonus za level up (np. pełne leczenie)
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	
	# Tutaj możesz otworzyć menu ulepszeń
	# get_tree().paused = true ...

func perform_dash() -> void:
	var dash_cost = BASE_STAT * 1
	if current_energy < dash_cost: return
		
	modify_energy(-dash_cost)
	is_dashing = true
	var target_position = position + (last_direction * dash_distance)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_position, dash_duration)
	tween.finished.connect(func(): is_dashing = false)

func attack() -> void:
	var mouse_pos = get_global_mouse_position()
	var attack_direction = (mouse_pos - global_position).normalized()
	var attack_distance = 45.0 
	
	var attack_area = Area2D.new()
	attack_area.position = attack_direction * attack_distance
	attack_area.rotation = attack_direction.angle()
	
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(50, 80)
	collision_shape.shape = rect_shape
	attack_area.add_child(collision_shape)
	
	attack_area.area_entered.connect(func(area: Area2D):
		if area.has_method("parry"):
			var parry_direction = (get_global_mouse_position() - global_position).normalized()
			area.parry(parry_direction)
			apply_camera_shake(5.0)
		
		var target = area.get_parent()
		if target != null and target.has_method("take_damage") and target != self:
			target.take_damage(BASE_STAT * 1, global_position) 
	)
	
	add_child(attack_area)
	get_tree().create_timer(0.15).timeout.connect(func(): 
		if is_instance_valid(attack_area):
			attack_area.call_deferred("queue_free")
	)

func apply_camera_shake(intensity: float) -> void:
	shake_strength = intensity

func modify_hp(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	
	if amount < 0:
		apply_camera_shake(15.0) 
		if source_position != Vector2.ZERO:
			var push_direction = (global_position - source_position).normalized()
			knockback_velocity = push_direction * 500.0
		
		if BLOOD_SCENE:
			var blood = BLOOD_SCENE.instantiate()
			blood.global_position = global_position 
			get_parent().add_child(blood)
		
	if current_hp <= 0:
		die()

func modify_energy(amount: int) -> void:
	current_energy = clampi(current_energy + amount, 0, max_energy)
	energy_changed.emit(current_energy, max_energy)

func die() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://game_over_menu.tscn")
