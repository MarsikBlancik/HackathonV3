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

# --- ZMIENNE POMOCNICZE ---
var player: Node2D = null
var time_since_last_attack: float = 0.0

func _ready() -> void:
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
	
	# 1. Knockback (odrzucenie w przeciwnym kierunku do źródła ataku)
	var push_direction = (global_position - source_position).normalized()
	knockback_velocity = push_direction * 400.0 # 400 to siła odrzutu
	
	# 2. Trzęsienie kamery u gracza (jeśli gracz ma tę funkcję)
	if is_instance_valid(player) and player.has_method("apply_camera_shake"):
		player.apply_camera_shake(8.0) 
		
	# 3. Generowanie krwi
	var blood = BLOOD_SCENE.instantiate()
	blood.global_position = global_position 
	get_parent().add_child(blood) 
	
	# 4. Rozbłyśnięcie na biało (oznaka trafienia)
	modulate = Color(5.0, 5.0, 5.0) 
	get_tree().create_timer(0.1).timeout.connect(func(): modulate = Color.WHITE)
	
	# 5. Sprawdzenie, czy zginął
	if hp <= 0:
		die()

func die() -> void:
	print("Przeciwnik pokonany!")
	queue_free()
