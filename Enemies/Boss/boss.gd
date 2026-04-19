extends Node2D

# --- USTAWIENIA BAZOWE ---
@export var xp_gem_scene: PackedScene
@export var speed: float = 150.0
@export var stop_distance: float = 50.0 
@export var coin_scene: PackedScene

# --- STATYSTYKI BOSSA ---
@export var hp: int = 50 # <--- ZMIENIONO NA 50 HP

# --- USTAWIENIA NORMALNEGO ATAKU ---
@export var attack_damage: int = 10 # <--- Zwykły atak zadaje 10 dmg
@export var attack_cooldown: float = 1.0 
@export var attack_windup_time: float = 0.5 

# --- USTAWIENIA ATAKU "SLAM" ---
@export var slam_damage: int = 30 # <--- Slam zadaje 30 dmg
@export var slam_radius: float = 120.0 
@export var slam_windup_time: float = 1.2 
@export var slam_chance: float = 0.4 # 40% szans na uderzenie Slamem

# --- FIZYKA (KNOCKBACK) ---
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_friction: float = 10.0 

# --- EFEKTY ---
const BLOOD_SCENE = preload("res://EyeCandy/BloodParticles.tscn")
const BLOOD_STAIN_SCENE = preload("res://EyeCandy/BloodPixels.tscn")
const MAGNET_SCENE = preload("res://Magnet.tscn") 
var magnet_drop_chance: float = 0.05 # Lekko podniosłem szansę u Bossa do 5%

# --- ZMIENNE POMOCNICZE ---
var player: Node2D = null
var time_since_last_attack: float = 0.0

# --- ZMIENNE ANIMACJI I STANÓW ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var is_attacking: bool = false
var is_winding_up: bool = false 
var current_attack_type: String = "Attack" # Zapamiętuje wylosowany atak

func _ready() -> void:
	add_to_group("Enemy")
	
	player = get_tree().get_first_node_in_group("Player")
	
	if player == null:
		print("Błąd: Boss nie znalazł gracza na mapie!")
		
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	if is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()
		
		var move_velocity = Vector2.ZERO
		
		# 1. Obliczanie normalnego ruchu
		if distance_to_player > stop_distance and not is_winding_up and not is_attacking:
			move_velocity = direction * speed
			
		# 2. Wygaszanie knockbacku
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_friction * delta)
		
		# 3. Poruszanie wroga
		global_position += (move_velocity + knockback_velocity) * delta
		
		# 4. Logika Animacji i Obracania
		if animated_sprite and not is_attacking:
			if direction.x != 0 and not is_winding_up:
				animated_sprite.flip_h = direction.x < 0
				
			if move_velocity.length() > 0:
				animated_sprite.play("Walk")
			else:
				animated_sprite.play("default") if animated_sprite.sprite_frames.has_animation("default") else animated_sprite.stop()
			
		# 5. Logika atakowania
		if not is_winding_up and not is_attacking:
			time_since_last_attack += delta
		
			# Jeśli jest w zasięgu (z drobnym marginesem) i minął cooldown
			if distance_to_player <= stop_distance + 5.0:
				if time_since_last_attack >= attack_cooldown:
					start_attack_windup()

# --- TELEGRAFOWANIE ATAKU I START ANIMACJI ---
func start_attack_windup() -> void:
	is_winding_up = true
	is_attacking = true # <--- Boss natychmiast przechodzi w stan ataku i przestaje się ruszać
	time_since_last_attack = 0.0 
	
	# Losowanie rodzaju ataku
	if randf() <= slam_chance:
		current_attack_type = "Slam"
	else:
		current_attack_type = "Attack"
		
	# <--- Odpalenie animacji od razu z pojawieniem się wskaźnika
	if animated_sprite:
		animated_sprite.play(current_attack_type)
		
	var indicator = Polygon2D.new()
	var current_windup_time: float
	var current_radius: float # <--- Zmienna określająca wielkość wskaźnika
	
	# Ustawiamy parametry zależnie od ataku
	if current_attack_type == "Attack":
		current_windup_time = attack_windup_time
		current_radius = stop_distance + 20.0 # DOKŁADNY rozmiar hitboxa ze zwykłego ataku
		indicator.color = Color(1.0, 0.1, 0.1, 1.0) # Czerwone koło
		
	elif current_attack_type == "Slam":
		current_windup_time = slam_windup_time
		current_radius = slam_radius # DOKŁADNY rozmiar hitboxa ze Slamu
		indicator.color = Color(1.0, 0.4, 0.0, 1.0) # Pomarańczowe koło
	
	# Generowanie kształtu koła o promieniu "current_radius"
	var points = PackedVector2Array()
	var segments = 32
	for i in range(segments):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * current_radius)
	
	indicator.polygon = points
	indicator.modulate.a = 0.1 
	indicator.show_behind_parent = true 
	add_child(indicator)
	
	# Animacja pojawiania się wskaźnika
	var tween = indicator.create_tween()
	var target_alpha = 0.8 if current_attack_type == "Attack" else 0.9
	tween.tween_property(indicator, "modulate:a", target_alpha, current_windup_time).set_ease(Tween.EASE_IN)
	
	tween.finished.connect(func():
		indicator.queue_free() 
		if is_inside_tree() and hp > 0:
			perform_attack_hit_logic() # <--- Zmieniono z perform_attack()
	)

# --- TYLKO LOGIKA OBRAŻEŃ (PO ZAKOŃCZENIU INDICATORA) ---
func perform_attack_hit_logic() -> void:
	is_winding_up = false
	# Nie ustawiamy is_attacking = false tutaj, bo dba o to funkcja _on_animation_finished
	
	if not is_instance_valid(player): return
	
	var dist = global_position.distance_to(player.global_position)
	
	# Weryfikacja trafienia
	if current_attack_type == "Attack":
		if dist <= stop_distance + 20.0:
			if player.has_method("modify_hp"):
				player.modify_hp(-attack_damage, global_position)
	elif current_attack_type == "Slam":
		if dist <= slam_radius:
			if player.has_method("modify_hp"):
				player.modify_hp(-slam_damage, global_position)
				if player.has_method("apply_camera_shake"):
					player.apply_camera_shake(15.0) # Mocniejsze trzęsienie kamery

# --- OTRZYMYWANIE OBRAŻEŃ ---
func take_damage(amount: int, source_position: Vector2) -> void:
	hp -= amount
	spawn_damage_number(abs(amount))
	
	# Zmniejszony knockback - boss jest cięższy (ze 400.0 na 150.0)
	var push_direction = (global_position - source_position).normalized()
	knockback_velocity = push_direction * 150.0 
	
	if is_instance_valid(player) and player.has_method("apply_camera_shake"):
		player.apply_camera_shake(5.0) 
		
	if BLOOD_SCENE:
		var blood = BLOOD_SCENE.instantiate()
		blood.global_position = global_position 
		get_parent().add_child(blood) 
	
	if BLOOD_STAIN_SCENE:
		var stain = BLOOD_STAIN_SCENE.instantiate()
		stain.global_position = global_position
		get_parent().add_child(stain)
		
	modulate = Color(5.0, 5.0, 5.0) 
	get_tree().create_timer(0.1).timeout.connect(func(): modulate = Color.WHITE)
	
	if hp <= 0:
		die()

func spawn_damage_number(damage_value: int) -> void:
	var label = Label.new()
	label.text = "-" + str(damage_value)
	
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_constant_override("outline_size", 12)
	
	var random_offset = Vector2(randf_range(-30, 30), randf_range(-40, -10))
	label.global_position = global_position + random_offset
	label.z_index = 10 
	get_parent().add_child(label)
	
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 40, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

func die() -> void: 
	# Szansa na magnes
	if randf() < magnet_drop_chance and MAGNET_SCENE:
		var magnet = MAGNET_SCENE.instantiate()
		magnet.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		get_parent().call_deferred("add_child", magnet)
		
	# --- BOSSKI DROP: Dużo XP ---
	if xp_gem_scene != null:
		var xp_count = randi_range(6, 12) # Zrzuca od 6 do 12 kryształów
		for i in range(xp_count):
			var gem = xp_gem_scene.instantiate()
			gem.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			get_tree().current_scene.call_deferred("add_child", gem)
		
	# --- BOSSKI DROP: Dużo Monet ---
	if coin_scene != null:
		var coin_count = randi_range(15, 25) # Zrzuca od 15 do 25 monet
		for i in range(coin_count):
			var coin = coin_scene.instantiate()
			var random_offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
			coin.global_position = global_position + random_offset
			get_tree().current_scene.call_deferred("add_child", coin)
	
	queue_free()

func _on_animation_finished() -> void:
	# Resetujemy flagę ataku dla OBU animacji
	if animated_sprite and (animated_sprite.animation == "Attack" or animated_sprite.animation == "Slam"):
		is_attacking = false
