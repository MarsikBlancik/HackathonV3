extends Node2D

# --- USTAWIENIA BAZOWE ---
@export var speed: float = 150.0
@export var stop_distance: float = 50.0 

# --- USTAWIENIA ATAKU ---
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0 # Czas między atakami

# --- STATYSTYKI PRZECIWNIKA ---
@export var hp: int = 3 

# --- FIZYKA (KNOCKBACK) ---
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_friction: float = 10.0 # Jak szybko wróg się zatrzymuje

# --- EFEKTY ---
# Upewnij się, że masz plik BloodParticles.tscn w tym samym folderze
const BLOOD_SCENE = preload("res://BloodParticles.tscn")
const BLOOD_STAIN_SCENE = preload("res://BloodPixels.tscn")

# --- ZMIENNE POMOCNICZE ---
var player: Node2D = null
var time_since_last_attack: float = 0.0

func _ready() -> void:
	add_to_group("Enemy")
	
	player = get_tree().get_first_node_in_group("Player")
	
	if player == null:
		print("Błąd: Przeciwnik nie znalazł gracza na mapie!")

func _process(delta: float) -> void:
	if is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()
		
		# 1. Obliczanie normalnego ruchu (idzie w stronę gracza, jeśli jest za daleko)
		var move_velocity = Vector2.ZERO
		if distance_to_player > stop_distance:
			move_velocity = direction * speed
			
		# 2. Wygaszanie knockbacku (siła odrzutu płynnie spada do zera z powodu tarcia)
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_friction * delta)
		
		# 3. Poruszanie wroga (Ruch własny + ewentualna siła odrzutu)
		global_position += (move_velocity + knockback_velocity) * delta
			
		# 4. Logika atakowania
		time_since_last_attack += delta
		
		# Bufor +5 pikseli, żeby na pewno zaatakował po zatrzymaniu się
		if distance_to_player <= stop_distance + 5.0:
			if time_since_last_attack >= attack_cooldown:
				perform_attack()

func perform_attack() -> void:
	print("Przeciwnik: Uderzam gracza!")
	
	if player.has_method("modify_hp"):
		# PODAJEMY DRUGI ARGUMENT: global_position (pozycję przeciwnika)
		player.modify_hp(-attack_damage, global_position)
		
	time_since_last_attack = 0.0

# --- OTRZYMYWANIE OBRAŻEŃ ---
func take_damage(amount: int, source_position: Vector2) -> void:
	hp -= amount
	print("Przeciwnik dostał! Zostało mu ", hp, " HP.")
	
	spawn_damage_number(abs(amount))
	
	# 1. Knockback 
	var push_direction = (global_position - source_position).normalized()
	knockback_velocity = push_direction * 400.0 
	
	# 2. Trzęsienie kamery u gracza
	if is_instance_valid(player) and player.has_method("apply_camera_shake"):
		player.apply_camera_shake(8.0) 
		
	# 3. Generowanie tryskającej krwi (Cząsteczki)
	if BLOOD_SCENE:
		var blood = BLOOD_SCENE.instantiate()
		blood.global_position = global_position 
		get_parent().add_child(blood) 
	
	# --- NOWE: GENEROWANIE PLAMY NA PODŁODZE ---
	if BLOOD_STAIN_SCENE:
		var stain = BLOOD_STAIN_SCENE.instantiate()
		stain.global_position = global_position
		get_parent().add_child(stain)
		
	# 4. Rozbłyśnięcie na biało 
	modulate = Color(5.0, 5.0, 5.0) 
	get_tree().create_timer(0.1).timeout.connect(func(): modulate = Color.WHITE)
	
	# 5. Sprawdzenie, czy zginął
	if hp <= 0:
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

func die() -> void:
	print("Przeciwnik pokonany!")
	queue_free()
