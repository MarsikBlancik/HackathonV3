extends Node2D

# 1. SYGNAŁY
signal hp_changed(current_hp: int, max_hp: int)
signal energy_changed(current_energy: int, max_energy: int)

# 2. MODUŁ STATYSTYK
const BASE_STAT: int = 1 

@export var max_hp: int = BASE_STAT * 3
@export var max_energy: int = BASE_STAT * 3
@export var energy_recharge_time: float = 2.0

var current_hp: int
var current_energy: int
var energy_timer: float = 0.0

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
	if Input.is_physical_key_pressed(KEY_A): input_direction.x -= 1
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
		if event.physical_keycode == KEY_F:
			modify_hp(-1)
			
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			attack()

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
	rect_shape.size = Vector2(50, 80) # Zwiększyłem nieco szerokość, by łatwiej parować
	collision_shape.shape = rect_shape
	attack_area.add_child(collision_shape)
	
	# Logika trafienia (Wrogowie ORAZ Pociski)
	attack_area.area_entered.connect(func(area: Area2D):
		# 1. Sprawdzanie czy to pocisk do sparowania
		if area.has_method("parry"):
			var parry_direction = (get_global_mouse_position() - global_position).normalized()
			area.parry(parry_direction)
			apply_camera_shake(5.0) # Lekki efekt przy udanym parowaniu
		
		# 2. Sprawdzanie czy to wróg
		var target = area.get_parent()
		if target != null and target.has_method("take_damage") and target != self:
			target.take_damage(BASE_STAT * 1, global_position) 
	)
	
	add_child(attack_area)
	
	# Bezpieczne usuwanie attack_area
	get_tree().create_timer(0.15).timeout.connect(func(): 
		if is_instance_valid(attack_area):
			attack_area.call_deferred("queue_free")
	)

func apply_camera_shake(intensity: float) -> void:
	shake_strength = intensity

func modify_hp(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	
	spawn_damage_number(abs(amount))
	
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

func spawn_damage_number(damage_value: int) -> void:
	var label = Label.new()
	label.text = "-" + str(damage_value)
	
	# Stylizacja tekstu (kolor czerwony, pogrubienie i czarny obrys dla czytelności)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_constant_override("outline_size", 12)
	
	# Losowa pozycja wokół gracza
	var random_offset = Vector2(randf_range(-30, 30), randf_range(-40, -10))
	label.global_position = global_position + random_offset
	
	# Z-Index, aby upewnić się, że tekst jest nad graczem/resztą gry
	label.z_index = 10 
	
	# Ważne: dodajemy do głównego drzewa (rodzica gracza), aby napis nie ruszał się razem z graczem
	get_parent().add_child(label)
	
	# Animacja za pomocą Tween (równoległa: unosi się i staje się przezroczysty)
	var tween = label.create_tween()
	tween.set_parallel(true)
	
	# Przesunięcie wyżej o 40 pikseli w 0.6 sekundy
	tween.tween_property(label, "global_position:y", label.global_position.y - 40, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# Zanikanie (kanał alpha) w 0.6 sekundy
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	
	# Po zakończeniu animacji usuwamy Label, żeby nie zaśmiecać pamięci
	tween.chain().tween_callback(label.queue_free)

func die() -> void:
	# Używamy call_deferred, aby uniknąć błędów fizyki przy zmianie sceny
	get_tree().call_deferred("change_scene_to_file", "res://game_over_menu.tscn")
