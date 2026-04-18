extends Node2D

# --- USTAWIENIA BAZOWE ---
@export var xp_gem_scene: PackedScene
@export var speed: float = 80.0 # Strzelec jest wolniejszy
@export var stop_distance: float = 250.0 # Zatrzymuje się dalej od gracza

# --- USTAWIENIA ATAKU ---
@export var attack_cooldown: float = 1.5 # Czas między strzałami
@export var projectile_scene: PackedScene # Tu podepnij plik Projectile.tscn w Inspektorze!

# --- STATYSTYKI PRZECIWNIKA ---
@export var hp: int = 2 # Strzelec jest zazwyczaj "bardziej miękki"

# --- FIZYKA (KNOCKBACK) ---
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_friction: float = 10.0 

# --- EFEKTY ---
const BLOOD_SCENE = preload("res://EyeCandy/BloodParticles.tscn")

# --- ZMIENNE POMOCNICZE ---
var player: Node2D = null
var time_since_last_attack: float = 0.0

func _ready() -> void:
	add_to_group("Enemy")
	player = get_tree().get_first_node_in_group("Player")
	
	if player == null:
		print("Błąd: RangedEnemy nie znalazł gracza na mapie!")

func _process(delta: float) -> void:
	if is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()
		
		# 1. Obliczanie normalnego ruchu
		var move_velocity = Vector2.ZERO
		if distance_to_player > stop_distance:
			move_velocity = direction * speed
			
		# 2. Wygaszanie knockbacku
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_friction * delta)
		
		# 3. Poruszanie wroga
		global_position += (move_velocity + knockback_velocity) * delta
			
		# 4. Logika atakowania
		time_since_last_attack += delta
		
		# Strzela, jeśli jest w miarę blisko swojej strefy zatrzymania
		if distance_to_player <= stop_distance + 50.0:
			if time_since_last_attack >= attack_cooldown:
				perform_attack()

func perform_attack() -> void:
	time_since_last_attack = 0.0
	
	if projectile_scene != null:
		var projectile = projectile_scene.instantiate()
		# Dodajemy pocisk do sceny głównej
		get_tree().current_scene.add_child(projectile)
		
		# Ustawiamy pocisk tam, gdzie wróg
		projectile.global_position = global_position
		
		# Obliczamy kierunek i wysyłamy pocisk
		var direction = (player.global_position - global_position).normalized()
		projectile.set_direction(direction)
	else:
		print("BŁĄD: RangedEnemy nie ma przypisanej sceny pocisku!")

# --- OTRZYMYWANIE OBRAŻEŃ (Z Twoimi efektami) ---
func take_damage(amount: int, source_position: Vector2) -> void:
	hp -= amount
	
	spawn_damage_number(abs(amount))
	
	# 1. Knockback 
	var push_direction = (global_position - source_position).normalized()
	knockback_velocity = push_direction * 400.0 
	
	# 2. Trzęsienie kamery u gracza 
	if is_instance_valid(player) and player.has_method("apply_camera_shake"):
		player.apply_camera_shake(8.0) 
		
	# 3. Generowanie krwi
	var blood = BLOOD_SCENE.instantiate()
	blood.global_position = global_position 
	get_parent().add_child(blood) 
	
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

func die() -> void: # Możesz mieć tę funkcję pod inną nazwą, np. take_damage
	
	# --- Tworzenie diamencika ---
	if xp_gem_scene != null:
		var gem = xp_gem_scene.instantiate()
		
		# Ustawiamy pozycję diamencika dokładnie tam, gdzie zginął wróg
		gem.global_position = global_position
		
		# KLUCZOWE: Dodajemy gem do głównej sceny, a nie do wroga!
		# Używamy call_deferred, żeby silnik fizyczny Godota się nie zablokował
		get_tree().current_scene.call_deferred("add_child", gem)
	
	# --- Koniec tworzenia ---
	
	queue_free() # Przeciwnik znika
