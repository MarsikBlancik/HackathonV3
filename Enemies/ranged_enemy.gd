extends Node2D

# --- USTAWIENIA BAZOWE ---
@export var xp_gem_scene: PackedScene
@export var speed: float = 80.0 # Strzelec jest wolniejszy
@export var stop_distance: float = 250.0 # Zatrzymuje się dalej od gracza
@export var coin_scene: PackedScene

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
var is_attacking: bool = false # <--- NOWE: Blokada animacji

# --- WĘZŁY ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # <--- NOWE: Referencja do Sprite'a

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
	if player == null:
		print("Błąd: RangedEnemy nie znalazł gracza na mapie!")
		
	# Podpinamy sygnał końca animacji
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

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
		
		# 3. Poruszanie wroga (nie porusza się, jeśli atakuje)
		if not is_attacking:
			global_position += (move_velocity + knockback_velocity) * delta
		else:
			# Jeśli atakuje, aplikuj tylko knockback
			global_position += knockback_velocity * delta
			
		# --- NOWE: SYSTEM ANIMACJI ---
		if animated_sprite and not is_attacking:
			# Obracanie w stronę gracza
			animated_sprite.flip_h = direction.x < 0
			
			if move_velocity.length() > 0:
				animated_sprite.play("Walk")
			else:
				animated_sprite.play("default")
		# -----------------------------
			
		# 4. Logika atakowania
		time_since_last_attack += delta
		
		# Strzela, jeśli jest w miarę blisko swojej strefy zatrzymania i nie jest w trakcie innego ataku
		if distance_to_player <= stop_distance + 50.0 and not is_attacking:
			if time_since_last_attack >= attack_cooldown:
				perform_attack()

func perform_attack() -> void:
	time_since_last_attack = 0.0
	is_attacking = true # <--- NOWE: Rozpoczęcie ataku
	
	if animated_sprite:
		animated_sprite.play("Attack")
	
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

# --- OTRZYMYWANIE OBRAŻEŃ ---
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

# --- NOWE: Resetowanie ataku po zakończeniu animacji ---
func _on_animation_finished() -> void:
	if animated_sprite and animated_sprite.animation == "Attack":
		is_attacking = false
