extends Node2D

# --- USTAWIENIA BAZOWE ---
@export var xp_gem_scene: PackedScene
@export var speed: float = 150.0
@export var stop_distance: float = 50.0 
@export var coin_scene: PackedScene

# --- USTAWIENIA ATAKU ---
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0 # Czas między atakami
@export var attack_windup_time: float = 0.5 # <--- NOWE: Czas "ładowania" (szykowania się) do ataku

# --- STATYSTYKI PRZECIWNIKA ---
@export var hp: int = 3 

# --- FIZYKA (KNOCKBACK) ---
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_friction: float = 10.0 # Jak szybko wróg się zatrzymuje

# --- EFEKTY ---
const BLOOD_SCENE = preload("res://EyeCandy/BloodParticles.tscn")
const BLOOD_STAIN_SCENE = preload("res://EyeCandy/BloodPixels.tscn")

# --- ZMIENNE POMOCNICZE ---
var player: Node2D = null
var time_since_last_attack: float = 0.0
# Upewnij się, że ścieżka do Magnet.tscn jest poprawna!
const MAGNET_SCENE = preload("res://Magnet.tscn") 
var magnet_drop_chance: float = 0.015 # 1.5% szansy na wypadnięcie magnesu

# --- ZMIENNE ANIMACJI I STANÓW ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var is_attacking: bool = false
var is_winding_up: bool = false # <--- NOWE: Czy wróg aktualnie "ładuje" atak

func _ready() -> void:
	add_to_group("Enemy")
	
	player = get_tree().get_first_node_in_group("Player")
	
	if player == null:
		print("Błąd: Przeciwnik nie znalazł gracza na mapie!")
		
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	if is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()
		
		var move_velocity = Vector2.ZERO
		
		# 1. Obliczanie normalnego ruchu (Zatrzymuje się też, gdy się ładuje do ataku lub atakuje)
		if distance_to_player > stop_distance and not is_winding_up and not is_attacking:
			move_velocity = direction * speed
			
		# 2. Wygaszanie knockbacku
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_friction * delta)
		
		# 3. Poruszanie wroga
		global_position += (move_velocity + knockback_velocity) * delta
		
		# 4. Logika Animacji i Obracania
		if animated_sprite and not is_attacking:
			# Obracanie w stronę gracza tylko jeśli nie atakuje/nie ładuje
			if direction.x != 0 and not is_winding_up:
				animated_sprite.flip_h = direction.x < 0
				
			if move_velocity.length() > 0:
				animated_sprite.play("Walk")
			else:
				# Jeśli zatrzymany, odtwórz klatkę stania (lub animację idle)
				animated_sprite.play("default") if animated_sprite.sprite_frames.has_animation("default") else animated_sprite.stop()
			
		# 5. Logika atakowania
		if not is_winding_up and not is_attacking:
			time_since_last_attack += delta
		
			# Jeśli jest w zasięgu i minął cooldown – zaczynamy ładować atak!
			if distance_to_player <= stop_distance + 5.0:
				if time_since_last_attack >= attack_cooldown:
					start_attack_windup()

# --- NOWE: TELEGRAFOWANIE ATAKU (ŁADOWANIE) ---
func start_attack_windup() -> void:
	is_winding_up = true
	time_since_last_attack = 0.0 
	
	# Tworzymy wskaźnik zagrożenia na podłodze (Czerwony prostokąt)
	var indicator = Polygon2D.new()
	var w = 30.0 # Szerokość strefy ataku
	var l = stop_distance + 15.0 # Długość strefy ataku
	
	indicator.polygon = PackedVector2Array([
		Vector2(-w/2.0, 0),
		Vector2(w/2.0, 0),
		Vector2(w/2.0, l),
		Vector2(-w/2.0, l)
	])
	
	indicator.color = Color(1.0, 0.1, 0.1, 1.0) # Krwisto czerwony
	indicator.modulate.a = 0.1 # Zaczynamy od prawie niewidocznego
	
	# --- POPRAWKA: Zamiast z_index = -1, chowamy to tylko pod sprite wroga ---
	indicator.show_behind_parent = true 
	
	# Obracamy wskaźnik tak, aby patrzył na gracza
	var dir_to_player = (player.global_position - global_position).normalized()
	indicator.rotation = dir_to_player.angle() - PI/2.0
	
	add_child(indicator)
	
	# Animujemy stawkę "modulate:a" (przezroczystość) z 0.1 do 0.8 przez czas windup_time (0.5s)
	var tween = indicator.create_tween()
	tween.tween_property(indicator, "modulate:a", 0.8, attack_windup_time).set_ease(Tween.EASE_IN)
	
	# Co ma się stać po zakończeniu "ładowania"
	tween.finished.connect(func():
		indicator.queue_free() # Usuwamy wskaźnik z podłogi
		
		# Upewniamy się, że przeciwnik nadal żyje i jest na mapie, zanim uderzy
		if is_inside_tree() and hp > 0:
			perform_attack()
	)

func perform_attack() -> void:
	is_winding_up = false
	is_attacking = true
	print("Przeciwnik: Uderzam gracza!")
	
	if animated_sprite:
		animated_sprite.play("Attack")
	
	# Sprawdzamy czy gracz na pewno nie zdążył uciec z zasięgu przez to pół sekundy!
	# Dajemy mu drobną taryfę ulgową (+20 do dystansu), żeby unik musiał być faktycznie unikiem.
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= stop_distance + 20.0:
		if player.has_method("modify_hp"):
			player.modify_hp(-attack_damage, global_position)
	else:
		print("Gracz uniknął uderzenia!")

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
		
	# 3. Generowanie tryskającej krwi
	if BLOOD_SCENE:
		var blood = BLOOD_SCENE.instantiate()
		blood.global_position = global_position 
		get_parent().add_child(blood) 
	
	# Generowanie plamy na podłodze
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
	
	if randf() < magnet_drop_chance and MAGNET_SCENE:
		var magnet = MAGNET_SCENE.instantiate()
		magnet.global_position = global_position
		# Dodajemy mały rozrzut, żeby magnes nie upadł idealnie w tym samym pikselu co XP
		var random_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		magnet.global_position += random_offset
		get_parent().call_deferred("add_child", magnet)
	# Wyrzucanie XP
	if xp_gem_scene != null:
		var gem = xp_gem_scene.instantiate()
		gem.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", gem)
		
	# --- NOWE: Wyrzucanie od 1 do 3 monet ---
	if coin_scene != null:
		var coin_count = randi_range(1, 3)
		for i in range(coin_count):
			var coin = coin_scene.instantiate()
			# Losowe przesunięcie, żeby monety nie leżały idealnie na sobie
			var random_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
			coin.global_position = global_position + random_offset
			get_tree().current_scene.call_deferred("add_child", coin)
	
	queue_free()

func _on_animation_finished() -> void:
	if animated_sprite and animated_sprite.animation == "Attack":
		is_attacking = false
