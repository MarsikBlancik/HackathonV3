extends Node2D

# --- MODUŁ STATYSTYK ---
const BASE_STAT: int = 1 

@export var max_hp: int = BASE_STAT * 3
@export var max_energy: int = BASE_STAT * 3

# Ustawienia regeneracji
@export var energy_recharge_time: float = 2.0
var energy_timer: float = 0.0

var current_hp: int
var current_energy: int

# --- MODUŁ RUCHU ---
@export var speed: float = 200.0
@export var dash_distance: float = 150.0 
@export var dash_duration: float = 0.2    

var is_dashing: bool = false
var last_direction: Vector2 = Vector2.RIGHT 

func _ready() -> void:
	current_hp = max_hp
	current_energy = max_energy
	print("Postać gotowa | HP: ", current_hp, " | Energia: ", current_energy)

func _process(delta: float) -> void:
	# Regeneracja energii
	if current_energy < max_energy:
		energy_timer += delta
		if energy_timer >= energy_recharge_time:
			modify_energy(1)
			energy_timer = 0.0
	else:
		energy_timer = 0.0
	
	# Ruch WASD
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

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Spacja = Dash
		if event.physical_keycode == KEY_SPACE and not is_dashing:
			perform_dash()
		
		# Klawisz F = DEBUG OBRAŻENIA
		if event.physical_keycode == KEY_F:
			print("Debug: Otrzymano obrażenia!")
			modify_hp(-1)
			
	if event is InputEventMouseButton and event.pressed:
		# LPM = Atak
		if event.button_index == MOUSE_BUTTON_LEFT:
			attack()

func perform_dash() -> void:
	var dash_cost = BASE_STAT * 1
	if current_energy < dash_cost:
		print("Debug: Za mało energii!")
		return
		
	modify_energy(-dash_cost)
	is_dashing = true
	var target_position = position + (last_direction * dash_distance)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_position, dash_duration)
	tween.finished.connect(func(): is_dashing = false)

func attack() -> void:
	print("Debug: CIACH!")

# --- FUNKCJE MODYFIKUJĄCE STATYSTYKI ---

func modify_hp(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp)
	print("HP: ", current_hp, "/", max_hp)
	
	# Jeśli HP spadnie do 0, wywołaj śmierć
	if current_hp <= 0:
		die()

func modify_energy(amount: int) -> void:
	current_energy = clampi(current_energy + amount, 0, max_energy)
	print("Energia: ", current_energy, "/", max_energy)

func die() -> void:
	print("Debug: Postać zginęła! Usuwanie z planszy...")
	# queue_free() usuwa cały węzeł (Node2D) i wszystkie dzieci (Sprite, Bronie itp.)
	queue_free()
