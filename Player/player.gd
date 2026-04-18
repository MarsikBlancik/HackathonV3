extends Node2D

# 1. SYGNAŁY
signal hp_changed(current_hp: int, max_hp: int)
signal energy_changed(current_energy: int, max_energy: int)
signal xp_changed(current_xp: int, max_xp: int) # <--- NOWE
signal leveled_up(new_level: int) # <--- NOWE
signal show_upgrade_menu(choices: Array) # <--- NOWY SYGNAŁ

const DRONE_SCENE = preload("res://Gadgets/Drone.tscn")
const MINE_SCENE = preload("res://Mine.tscn")
var mine_timer: Timer
const PIPEBOMB_SCENE = preload("res://PipeBomb.tscn")
var pipe_bomb_cooldown: float = 0.0

# 2. MODUŁ STATYSTYK
const BASE_STAT: int = 1

@export var max_hp: int = BASE_STAT * 3
@export var max_energy: int = BASE_STAT * 3
@export var energy_recharge_time: float = 2.0

# --- NOWE: SYSTEM XP ---
var level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 5 # Ile XP potrzeba do 2 poziomu

var current_hp: int
var current_energy: int
var energy_timer: float = 0.0

# 3. MODUŁ RUCHU
@export var speed: float = 200.0
@export var acceleration: float = 15.0 
@export var friction: float = 15.0     
@export var dash_distance: float = 150.0
@export var dash_duration: float = 0.2

var is_dashing: bool = false
var last_direction: Vector2 = Vector2.RIGHT
var current_velocity: Vector2 = Vector2.ZERO

# --- MODUŁ ATAKU (NOWOŚĆ) ---
@export var is_auto_attack: bool = false # Czy tryb auto jest domyślnie włączony?
@export var attack_cooldown: float = 0.5 # Opóźnienie między atakami (0.5 sekundy)
@export var auto_attack_range: float = 250.0 # Jak daleko widzi auto-atak
var time_since_last_attack: float = 100.0 # Startowo ustawione wysoko, żeby od razu móc uderzyć

# EFEKTY
const BLOOD_SCENE = preload("res://EyeCandy/BloodParticles.tscn")
const BLOOD_STAIN_SCENE = preload("res://EyeCandy/BloodPixels.tscn") 

var ghost_timer: Timer
@onready var sprite: Sprite2D = $CharacterBody2D/Sprite2D 
@onready var camera: Camera2D = $Camera2D
@onready var gadget_manager: Node = $GadgetManager # <--- NOWA REFERENCJA

var shake_strength: float = 0.0
@export var shake_decay: float = 10.0 

var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_friction: float = 10.0 

func _ready() -> void:
	add_to_group("Player")
	current_hp = max_hp
	current_energy = max_energy
	hp_changed.emit(current_hp, max_hp)
	energy_changed.emit(current_energy, max_energy)
	
	# --- NOWE: Wysyłamy stan XP na start ---
	xp_changed.emit(current_xp, xp_to_next_level)
	leveled_up.emit(level)

	ghost_timer = Timer.new()
	ghost_timer.wait_time = 0.03 
	ghost_timer.timeout.connect(create_dash_ghost)
	add_child(ghost_timer)
	
	# Tworzymy zegar, który będzie tykał w tle i zrzucał miny
	mine_timer = Timer.new()
	mine_timer.timeout.connect(_drop_mine)
	add_child(mine_timer)

func _process(delta: float) -> void:
	# 1. Odnawianie energii
	if current_energy < max_energy:
		energy_timer += delta
		if energy_timer >= energy_recharge_time:
			modify_energy(1)
			energy_timer = 0.0
	else:
		energy_timer = 0.0
		
	# 2. Odliczanie cooldownów
	time_since_last_attack += delta
	if pipe_bomb_cooldown > 0:
		pipe_bomb_cooldown -= delta
	
	# Jeśli włączony jest tryb Auto (klawisz T)
	if is_auto_attack:
		# Auto-Atak Mieczem
		if time_since_last_attack >= attack_cooldown:
			perform_auto_attack()
			
		# Auto-Rzut Granatem
		if gadget_manager.gadgets["pipe_bomb"] > 0 and pipe_bomb_cooldown <= 0.0:
			auto_throw_pipe_bomb()
	
	# 3. Ruch
	var input_direction = Vector2.ZERO
	if not is_dashing:
		if Input.is_physical_key_pressed(KEY_D): input_direction.x += 1
		if Input.is_physical_key_pressed(KEY_A): input_direction.x -= 1
		if Input.is_physical_key_pressed(KEY_S): input_direction.y += 1
		if Input.is_physical_key_pressed(KEY_W): input_direction.y -= 1
			
		if input_direction.length() > 0:
			input_direction = input_direction.normalized()
			last_direction = input_direction
			
		if input_direction.length() > 0:
			current_velocity = current_velocity.lerp(input_direction * speed, acceleration * delta)
		else:
			current_velocity = current_velocity.lerp(Vector2.ZERO, friction * delta)
	else:
		current_velocity = Vector2.ZERO
		
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_friction * delta)
	position += (current_velocity + knockback_velocity) * delta
	
	# 4. Trzęsienie kamery
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
			
		# Zmiana trybu za pomocą klawisza T
		if event.physical_keycode == KEY_T:
			is_auto_attack = not is_auto_attack
			print("Tryb Auto-Ataku: ", "WŁĄCZONY" if is_auto_attack else "WYŁĄCZONY")
			
	if event is InputEventMouseButton and event.pressed:
		
		# --- LEWY KLIK: ATAK MIECZEM ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not is_auto_attack and time_since_last_attack >= attack_cooldown:
				attack_towards(get_global_mouse_position())
				
		# --- PRAWY KLIK: GRANAT RUROWY ---
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var bomb_tier = gadget_manager.gadgets["pipe_bomb"]
			if bomb_tier > 0 and pipe_bomb_cooldown <= 0.0:
				# Przekazujemy pozycję myszki jako cel!
				throw_pipe_bomb(bomb_tier, get_global_mouse_position())

# --- NOWOŚĆ: SZUKANIE NAJBLIŻSZEGO WROGA ---
func perform_auto_attack() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.is_empty(): return # Jeśli nie ma wrogów na mapie, nic nie rób
	
	var closest_enemy = null
	var min_distance = auto_attack_range
	
	# Sprawdzamy odległość każdego wroga
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			closest_enemy = enemy
			
	# Jeśli znaleźliśmy wroga w zasięgu, atakujemy w jego stronę
	if closest_enemy != null:
		attack_towards(closest_enemy.global_position)

# --- ZMIENIONA FUNKCJA ATAKU (Teraz przyjmuje pozycję celu) ---
func attack_towards(target_pos: Vector2) -> void:
	time_since_last_attack = 0.0 
	
	var attack_direction = (target_pos - global_position).normalized()
	var attack_distance = 45.0
	
	var attack_area = Area2D.new()
	# --- NOWE: Nadajemy mieczowi imię, żeby pocisk go rozpoznał ---
	attack_area.name = "Sword" 
	
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
	
	# --- ZMIENIONE WYKRYWANIE KOLIZJI ---
	attack_area.area_entered.connect(func(area: Area2D):
		# 1. Sprawdzamy czy uderzyliśmy pocisk (samo Area2D ma funkcję parry)
		if area.has_method("parry"):
			var bounce_dir = (target_pos - global_position).normalized()
			area.parry(bounce_dir)
			apply_hit_stop(0.1) # Dłuższy hit stop dla fajnego efektu odbicia!
			return # Przerywamy funkcję, bo to był pocisk

		# 2. Sprawdzamy czy to zwykły wróg (rodzic Area2D)
		var target = area.get_parent()
		if target != null and target.has_method("take_damage"):
			target.take_damage(BASE_STAT * 1, global_position)
			apply_hit_stop(0.05)
	)
	
	add_child(attack_area)
	get_tree().create_timer(0.2).timeout.connect(attack_area.queue_free)

# --- RESZTA FUNKCJI BEZ ZMIAN ---
func perform_dash() -> void:
	var dash_cost = BASE_STAT * 1
	if current_energy < dash_cost: return
		
	modify_energy(-dash_cost)
	is_dashing = true
	ghost_timer.start() 
	
	# --- NOWOŚĆ: GADŻET TARANOWANIA ---
	var ram_tier = gadget_manager.gadgets["dash_ram"]
	if ram_tier > 0:
		var ram_area = Area2D.new()
		
		# 1. OTWIERAMY "OCZY" NASZEGO TARANU NA INNE WARSTWY
		ram_area.collision_mask = 15 # Każe skanować wszystkie pierwsze 4 warstwy fizyki!
		
		var collision = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 30.0 + (ram_tier * 10.0) 
		collision.shape = circle
		ram_area.add_child(collision)
		
		var hit_enemies = []
		
		# 2. WYCIĄGAMY LOGIKĘ DO ZMIENNEJ, ŻEBY PODPIĄĆ JĄ POD CIAŁA I OBSZARY
		var hit_logic = func(node: Node):
			var target = node
			if not target.has_method("take_damage") and target.get_parent() != null and target.get_parent().has_method("take_damage"):
				target = target.get_parent()
				
			if target.is_in_group("Enemy") and target.has_method("take_damage") and not target in hit_enemies:
				hit_enemies.append(target)
				var ram_damage = ram_tier * 2 
				target.take_damage(ram_damage, global_position)
				apply_hit_stop(0.04) 
		
		# 3. PODPINAMY OBA TYPY DETEKCJI (Tak jak zrobiliśmy w minach)
		ram_area.body_entered.connect(hit_logic)
		ram_area.area_entered.connect(hit_logic)
		
		add_child(ram_area)
		get_tree().create_timer(dash_duration).timeout.connect(ram_area.queue_free)
	# -----------------------------------
	
	# Klasyczny lot dasha
	var target_position = position + (last_direction * dash_distance)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_position, dash_duration)
	
	tween.finished.connect(func(): 
		is_dashing = false
		ghost_timer.stop() 
	)

func apply_camera_shake(intensity: float) -> void:
	shake_strength = intensity

func apply_hit_stop(duration: float) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func modify_hp(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	# --- NOWOŚĆ: Nietykalność podczas dasha (i-frames) ---
	if amount < 0 and is_dashing:
		print("Dodge! Uniknięto ataku.")
		return # Przerwane! Kod poniżej się nie wykona, gracz nie dostaje obrażeń.

	current_hp = clampi(current_hp + amount, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	
	spawn_damage_number(abs(amount))
	
	if amount < 0:
		apply_camera_shake(15.0)
		apply_hit_stop(0.08)
		
		if source_position != Vector2.ZERO:
			var push_direction = (global_position - source_position).normalized()
			knockback_velocity = push_direction * 500.0
		
		if BLOOD_SCENE:
			var blood = BLOOD_SCENE.instantiate()
			blood.global_position = global_position
			get_parent().add_child(blood)
			
		if BLOOD_STAIN_SCENE:
			var stain = BLOOD_STAIN_SCENE.instantiate()
			var random_offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
			stain.global_position = global_position + random_offset
			get_parent().add_child(stain)
		
	if current_hp <= 0:
		die()

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

func modify_energy(amount: int) -> void:
	current_energy = clampi(current_energy + amount, 0, max_energy)
	energy_changed.emit(current_energy, max_energy)

func die() -> void:
	Engine.time_scale = 1.0
	# Używamy call_deferred, aby Godot spokojnie dokończył klatkę fizyki przed zmianą sceny
	get_tree().call_deferred("change_scene_to_file", "res://Menus/game_over_menu.tscn")
	
	# --- MODUŁ DOŚWIADCZENIA (XP) ---
func gain_xp(amount: int) -> void:
	current_xp += amount
	print("Zdobyto ", amount, " XP!")
	
	# Sprawdzamy, czy mamy wystarczająco XP do awansu.
	# Używamy "while" na wypadek, gdyby gracz dostał tak dużo XP, że awansuje o 2 poziomy naraz!
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level_up()
		
	# Na koniec informujemy UI o nowym pasku XP
	xp_changed.emit(current_xp, xp_to_next_level)

func level_up() -> void:
	level += 1
	# Zwiększamy wymagania na kolejny poziom
	xp_to_next_level = int(xp_to_next_level * 1.5) 
	
	print("Awans! Jesteś na poziomie: ", level)
	
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	leveled_up.emit(level)
	
	# --- NOWOŚĆ: LOGIKA WYBORU GADŻETÓW ---
	# 1. Pobieramy 3 losowe opcje z naszego Mózgu
	var upgrade_choices = gadget_manager.get_upgrade_choices()
	
	# 2. Zatrzymujemy całkowicie grę (żebyś w spokoju mógł wybrać)
	get_tree().paused = true
	
	# 3. Wysyłamy sygnał w świat. Za chwilę podepniemy do niego nowe UI!
	show_upgrade_menu.emit(upgrade_choices)
	

func update_gadgets():
	var drone_tier = gadget_manager.gadgets["drones"]
	var mine_tier = gadget_manager.gadgets["mines"]
	
	# --- 1. OBSŁUGA DRONÓW ---
	for child in get_children():
		if child.is_in_group("Drone"):
			child.queue_free()
			
	for i in range(drone_tier):
		var new_drone = DRONE_SCENE.instantiate()
		new_drone.add_to_group("Drone")
		add_child(new_drone)
		new_drone.setup(drone_tier, (PI * 2 / drone_tier) * i)
		
	# --- 2. OBSŁUGA MIN ---
	if mine_tier > 0:
		match mine_tier:
			1: mine_timer.wait_time = 3.0 # Co 3 sekundy
			2: mine_timer.wait_time = 2.0 # Co 2 sekundy
			3: mine_timer.wait_time = 1.0 # Maszyna do minowania!
		
		# Odpal stoper, jeśli jeszcze nie jest włączony
		if mine_timer.is_stopped():
			mine_timer.start()

func _drop_mine():
	var mine_tier = gadget_manager.gadgets["mines"]
	if mine_tier == 0 or not MINE_SCENE: return
	
	var mine = MINE_SCENE.instantiate()
	mine.global_position = global_position 
	
	match mine_tier:
		1:
			mine.damage = 2
			mine.explosion_radius = 80.0
		2:
			mine.damage = 4
			mine.explosion_radius = 120.0
		3:
			mine.damage = 8 
			mine.explosion_radius = 180.0
			
	# POPRAWIONE SPAWNOWANIE MINY (zamiast current_scene)
	get_parent().add_child(mine)

# --- PRZYWRÓCONA FUNKCJA DUCHÓW ---
func create_dash_ghost() -> void:
	var ghost = Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.vframes = sprite.vframes
	ghost.hframes = sprite.hframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v
	ghost.global_scale = sprite.global_scale
	ghost.global_position = sprite.global_position
	ghost.modulate = Color(0.2, 0.5, 1.0, 0.7)
	
	get_parent().add_child(ghost)
	
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.finished.connect(ghost.queue_free)

func throw_pipe_bomb(tier: int, target_pos: Vector2) -> void: # <--- DODANO target_pos
	if not PIPEBOMB_SCENE: return
	
	match tier:
		1: pipe_bomb_cooldown = 5.0
		2: pipe_bomb_cooldown = 3.0
		3: pipe_bomb_cooldown = 3.0
		
	var bomb = PIPEBOMB_SCENE.instantiate()
	get_parent().add_child(bomb)
	
	# Zamiast szukać myszki, rzucamy w podany punkt!
	bomb.throw_bomb(global_position, target_pos, tier)
	
func auto_throw_pipe_bomb() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.is_empty(): return
	
	var closest_enemy = null
	var min_distance = 600.0 # Granat ma dużo większy zasięg auto-namierzania niż miecz!
	
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			closest_enemy = enemy
			
	if closest_enemy != null:
		var bomb_tier = gadget_manager.gadgets["pipe_bomb"]
		# Rzucamy w pozycję namierzonego wroga!
		throw_pipe_bomb(bomb_tier, closest_enemy.global_position)
