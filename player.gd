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

var shake_strength: float = 0.0 # Aktualna siła trzęsienia
@export var shake_decay: float = 10.0 # Jak szybko kamera wraca do normy (większa = szybciej)

func _ready() -> void:
	# KULOODPORNA METODA: Gracz dodaje się do grupy "Player"
	add_to_group("Player")
	
	current_hp = max_hp
	current_energy = max_energy
	
	# Wysyłamy sygnał na start
	hp_changed.emit(current_hp, max_hp)
	energy_changed.emit(current_energy, max_energy)
	
	print("Gracz gotowy | HP: ", current_hp, " | Energia: ", current_energy)

func _process(delta: float) -> void:
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
		
	position += input_direction * speed * delta
	
	# --- LOGIKA TRZĘSIENIA KAMERY ---
	if shake_strength > 0:
		# Płynnie zmniejszamy siłę trzęsienia do zera
		shake_strength = lerpf(shake_strength, 0.0, shake_decay * delta)
		
		# Losujemy przesunięcie (offset) w osi X i Y
		var random_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		camera.offset = random_offset * shake_strength
		
		# Kiedy siła jest już bliska zeru, zerujemy offset całkowicie
		if shake_strength < 0.1:
			shake_strength = 0.0
			camera.offset = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE and not is_dashing:
			perform_dash()
		
		# Klawisz F = obrażenia (DEBUG)
		if event.physical_keycode == KEY_F:
			modify_hp(-1)
			
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			attack()

func perform_dash() -> void:
	var dash_cost = BASE_STAT * 1
	if current_energy < dash_cost:
		return
		
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
	rect_shape.size = Vector2(30, 80) 
	collision_shape.shape = rect_shape
	attack_area.add_child(collision_shape)
	
	var debug_rect = ColorRect.new()
	debug_rect.color = Color(1.0, 0.0, 0.0, 0.5)
	debug_rect.size = Vector2(30, 80)
	debug_rect.position = Vector2(-15, -40) 
	attack_area.add_child(debug_rect)
	
	attack_area.area_entered.connect(func(area: Area2D):
		var target = area.get_parent()
		if target != null and target.has_method("take_damage"):
			target.take_damage(BASE_STAT * 1) 
	)
	
	add_child(attack_area)
	get_tree().create_timer(0.2).timeout.connect(func(): attack_area.queue_free())
	
	# Nowa funkcja, którą możemy wywołać z dowolnego miejsca
func apply_camera_shake(intensity: float) -> void:
	shake_strength = intensity

func modify_hp(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	
	# Jeśli amount jest na minusie (gracz dostał obrażenia)
	if amount < 0:
		apply_camera_shake(15.0) 
		
		# --- NOWE: DODAWANIE KRWI DLA GRACZA ---
		var blood = BLOOD_SCENE.instantiate()
		blood.global_position = global_position 
		get_parent().add_child(blood)
		
	if current_hp <= 0:
		die()

func modify_energy(amount: int) -> void:
	current_energy = clampi(current_energy + amount, 0, max_energy)
	energy_changed.emit(current_energy, max_energy)

func die() -> void:
	get_tree().change_scene_to_file("res://Restart.tscn")
