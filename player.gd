extends Node2D

# 1. SYGNAŁY

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

func _ready() -> void:
	current_hp = max_hp
	current_energy = max_energy
	print("Gracz gotowy | HP: ", current_hp, " | Energia: ", current_energy)

func _process(delta: float) -> void:
	# Regeneracja energii
	if current_energy < max_energy:
		energy_timer += delta
		if energy_timer >= energy_recharge_time:
			modify_energy(1)
			energy_timer = 0.0
	else:
		energy_timer = 0.0
	
	# Ruch
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
		if event.physical_keycode == KEY_SPACE and not is_dashing:
			perform_dash()
		
		# Klawisz F = zadaje 1 punkt obrażeń (DEBUG)
		if event.physical_keycode == KEY_F:
			print("Debug: Otrzymano obrażenia!")
			modify_hp(-1)
			
	if event is InputEventMouseButton and event.pressed:
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

# 4. MODUŁ ATAKU MELEE (KIERUNKOWY)
func attack() -> void:
	# 1. Obliczamy kierunek ataku
	var mouse_pos = get_global_mouse_position()
	# Odejmujemy pozycję gracza od pozycji myszy i normalizujemy (tworzymy strzałkę kierunkową o długości 1)
	var attack_direction = (mouse_pos - global_position).normalized()
	
	# Zasięg ataku od środka gracza (np. długość ramienia/miecza)
	var attack_distance = 45.0 
	
	# 2. Tworzymy obszar ataku
	var attack_area = Area2D.new()
	# Ustawiamy go w odpowiedniej odległości W KIERUNKU myszy
	attack_area.global_position = global_position + (attack_direction * attack_distance)
	# Obracamy cały obszar ataku w stronę myszy (bardzo ważne dla prostokątnych hitboxów broni!)
	attack_area.rotation = attack_direction.angle()
	
	# 3. Tworzymy kształt kolizji - teraz używamy prostokąta, bo lepiej udaje szerokie "cięcie"
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	# Szerokość (wysunięcie do przodu) i Wysokość (rozpiętość cięcia na boki)
	rect_shape.size = Vector2(30, 80) 
	collision_shape.shape = rect_shape
	attack_area.add_child(collision_shape)
	
	# 4. Debugging - czerwony prostokąt
	var debug_rect = ColorRect.new()
	debug_rect.color = Color(1.0, 0.0, 0.0, 0.5)
	debug_rect.size = Vector2(30, 80)
	# Musimy przesunąć prostokąt graficzny, żeby jego środek pokrywał się ze środkiem kolizji
	debug_rect.position = Vector2(-15, -40) 
	attack_area.add_child(debug_rect)
	
	# 5. Dodajemy atak do sceny (nie do gracza, żeby uderzenie "zostało w powietrzu" podczas ruchu)
	get_tree().current_scene.add_child(attack_area)
	
	# 6. Usuwamy po krótkiej chwili
	get_tree().create_timer(0.2).timeout.connect(func(): attack_area.queue_free())
	
	print("Debug: Atak melee w kierunku kursora!")

func modify_hp(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp)
	print("HP: ", current_hp, "/", max_hp)
	
	if current_hp <= 0:
		die()

func modify_energy(amount: int) -> void:
	current_energy = clampi(current_energy + amount, 0, max_energy)
	print("Energia: ", current_energy, "/", max_energy)

func die() -> void:
	print("Debug: Postać zginęła!")
	get_tree().change_scene_to_file("res://Restart.tscn")
