extends Node2D

# 1. SYGNAŁY
signal hp_changed(current_hp: int, max_hp: int)
signal energy_changed(current_energy: int, max_energy: int)
signal xp_changed(current_xp: int, max_xp: int) 
signal leveled_up(new_level: int) 


# 2. MODUŁ STATYSTYK
const BASE_STAT: int = 1

@export var max_hp: int = BASE_STAT * 3
@export var max_energy: int = BASE_STAT * 3
@export var energy_recharge_time: float = 2.0

# --- SYSTEM XP ---
var level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 5 

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
var dash_tween: Tween # <--- DODANE: Referencja do Tweena dasha

# --- MODUŁ ATAKU I AKCJI ---
@export var is_auto_attack: bool = false 
@export var attack_cooldown: float = 0.5 
@export var auto_attack_range: float = 250.0 
var time_since_last_attack: float = 100.0 

var is_attacking: bool = false 
var is_parrying: bool = false 

# EFEKTY
const BLOOD_SCENE = preload("res://EyeCandy/BloodParticles.tscn")
const BLOOD_STAIN_SCENE = preload("res://EyeCandy/BloodPixels.tscn") 
const SLASH_TEXTURE = preload("res://Player/Trail.png") # <--- ZMIEŃ NAZWĘ PLIKU!

var ghost_timer: Timer

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D 
@onready var camera: Camera2D = $Camera2D

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
	
	xp_changed.emit(current_xp, xp_to_next_level)
	leveled_up.emit(level)

	ghost_timer = Timer.new()
	ghost_timer.wait_time = 0.03 
	ghost_timer.timeout.connect(create_dash_ghost)
	add_child(ghost_timer)
	
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	# 1. Odnawianie energii
	if current_energy < max_energy:
		energy_timer += delta
		if energy_timer >= energy_recharge_time:
			modify_energy(1)
			energy_timer = 0.0
	else:
		energy_timer = 0.0
		
	# 2. Licznik czasu do ataku
	time_since_last_attack += delta
	
	if is_auto_attack and time_since_last_attack >= attack_cooldown:
		perform_auto_attack()
	
	# 3. Ruch
	var input_direction = Vector2.ZERO
	# Blokujemy poruszanie się podczas Dasha oraz Parowania
	if not is_dashing and not is_parrying:
		if Input.is_physical_key_pressed(KEY_D): input_direction.x += 1
		if Input.is_physical_key_pressed(KEY_A): input_direction.x -= 1
		if Input.is_physical_key_pressed(KEY_S): input_direction.y += 1
		if Input.is_physical_key_pressed(KEY_W): input_direction.y -= 1
			
		if input_direction.length() > 0:
			input_direction = input_direction.normalized()
			last_direction = input_direction
			current_velocity = current_velocity.lerp(input_direction * speed, acceleration * delta)
		else:
			current_velocity = current_velocity.lerp(Vector2.ZERO, friction * delta)
	elif is_parrying:
		current_velocity = current_velocity.lerp(Vector2.ZERO, friction * delta)
	else:
		current_velocity = Vector2.ZERO
		
	# 4. SYSTEM ANIMACJI
	if animated_sprite:
		if input_direction.x != 0 and not is_attacking and not is_dashing and not is_parrying:
			animated_sprite.flip_h = input_direction.x < 0
			
		if is_dashing:
			animated_sprite.play("Dash")
			if is_attacking:
				animated_sprite.play("Attack")
		elif is_attacking:
			animated_sprite.play("Attack")
			if is_dashing:
				animated_sprite.play("Dash")
		elif is_parrying:
			pass
		elif current_velocity.length() > 5.0:
			animated_sprite.play("Walk")
		else:
			animated_sprite.play("default")
			
	# Zastosowanie prędkości do pozycji
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_friction * delta)
	position += (current_velocity + knockback_velocity) * delta
	
	# 5. Trzęsienie kamery
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
			
		if event.physical_keycode == KEY_T:
			is_auto_attack = not is_auto_attack
			print("Tryb Auto-Ataku: ", "WŁĄCZONY" if is_auto_attack else "WYŁĄCZONY")
			
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not is_auto_attack and time_since_last_attack >= attack_cooldown and not is_parrying:
				attack_towards(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not is_dashing and not is_attacking and not is_parrying:
				perform_parry()

func perform_auto_attack() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.is_empty(): return 
	
	var closest_enemy = null
	var min_distance = auto_attack_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			closest_enemy = enemy
			
	if closest_enemy != null:
		attack_towards(closest_enemy.global_position)

# --- ZMIENIONO: attack_towards z nowym trailem na bazie maski (ProgressBar) i przerywaniem dasha ---
func attack_towards(target_pos: Vector2) -> void:
	# --- PRZERYWANIE DASHA ATAKIEM ---
	if is_dashing:
		is_dashing = false
		ghost_timer.stop()
		if dash_tween and dash_tween.is_valid():
			dash_tween.kill() 
			
	time_since_last_attack = 0.0 
	
	var attack_direction = (target_pos - global_position).normalized()
	
	is_attacking = true
	if animated_sprite:
		animated_sprite.play("Attack")
		animated_sprite.flip_h = attack_direction.x < 0
	
	var base_angle = attack_direction.angle()
	var attack_distance = 50.0 
	
	# --- NOWY SYSTEM TRAILU: Węzeł paska postępu jako maska ---
	var slash = TextureProgressBar.new()
	slash.texture_progress = SLASH_TEXTURE
	
	slash.scale = Vector2(0.45, 0.45) 
	slash.pivot_offset = SLASH_TEXTURE.get_size() / 2.0
	
	slash.min_value = 0
	slash.max_value = 100
	slash.value = 0 
	
	slash.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	
	get_parent().add_child(slash)
	
	slash.global_position = global_position + (attack_direction * attack_distance) - (slash.pivot_offset * slash.scale)
	slash.rotation = base_angle
	slash.z_index = z_index + 1 
	
	if attack_direction.x < 0:
		slash.fill_mode = TextureProgressBar.FILL_COUNTER_CLOCKWISE
		
	var tween = slash.create_tween()
	tween.tween_property(slash, "value", 100, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(slash, "modulate:a", 0.0, 0.15).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(slash.queue_free)

	# --- Hitbox ataku ---
	var attack_area = Area2D.new()
	attack_area.name = "Sword" 
	
	attack_area.position = attack_direction * (attack_distance + 10.0)
	attack_area.rotation = attack_direction.angle()
	
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	
	rect_shape.size = Vector2(120, 180) 
	collision_shape.shape = rect_shape
	attack_area.add_child(collision_shape)
	
	attack_area.area_entered.connect(func(area: Area2D):
		if area.has_method("parry"):
			var bounce_dir = (target_pos - global_position).normalized()
			area.parry(bounce_dir)
			apply_hit_stop(0.1) 
			
			is_attacking = false
			is_parrying = true
			if animated_sprite:
				animated_sprite.play("Parry")
			return 

		var target = area.get_parent()
		if target != null and target.has_method("take_damage"):
			target.take_damage(BASE_STAT * 1, global_position)
			apply_hit_stop(0.05)
	)
	
	add_child(attack_area)
	get_tree().create_timer(0.15).timeout.connect(attack_area.queue_free)

func perform_parry() -> void:
	is_parrying = true
	if animated_sprite:
		animated_sprite.play("Parry")

func perform_dash() -> void:
	var dash_cost = BASE_STAT * 1
	if current_energy < dash_cost: return
		
	modify_energy(-dash_cost)
	
	# Anulujemy atak/parowanie przy uniku
	is_attacking = false
	is_parrying = false
	
	is_dashing = true
	ghost_timer.start() 
	
	var target_position = position + (last_direction * dash_distance)
	
	# --- NOWE: Przypisywanie do zmiennej globalnej ---
	if dash_tween and dash_tween.is_valid():
		dash_tween.kill()
		
	dash_tween = create_tween()
	dash_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	dash_tween.tween_property(self, "position", target_position, dash_duration)
	
	dash_tween.finished.connect(func(): 
		is_dashing = false
		ghost_timer.stop() 
	)

func create_dash_ghost() -> void:
	if not animated_sprite: return
		
	var ghost = Sprite2D.new()
	ghost.texture = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	
	ghost.flip_h = animated_sprite.flip_h
	ghost.flip_v = animated_sprite.flip_v
	ghost.global_scale = animated_sprite.global_scale
	ghost.global_position = animated_sprite.global_position
	ghost.modulate = Color(1.0, 1.0, 1.0, 0.7)
	
	get_parent().add_child(ghost)
	
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.finished.connect(ghost.queue_free)

func apply_camera_shake(intensity: float) -> void:
	shake_strength = intensity

func apply_hit_stop(duration: float) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func modify_hp(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if amount < 0 and (is_dashing or is_parrying):
		print("Dodge/Parry! Uniknięto ataku.")
		return 

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

func modify_energy(amount: int) -> void:
	current_energy = clampi(current_energy + amount, 0, max_energy)
	energy_changed.emit(current_energy, max_energy)

func die() -> void:
	Engine.time_scale = 1.0
	get_tree().call_deferred("change_scene_to_file", "res://Menus/game_over_menu.tscn")
	
func gain_xp(amount: int) -> void:
	current_xp += amount
	print("Zdobyto ", amount, " XP!")
	
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level_up()
		
	xp_changed.emit(current_xp, xp_to_next_level)

func level_up() -> void:
	level += 1
	xp_to_next_level = int(xp_to_next_level * 1.5) 
	
	print("Awans! Jesteś na poziomie: ", level)
	
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	
	leveled_up.emit(level)

# --- Resetuje stan akcji po zakończeniu animacji ---
func _on_animation_finished() -> void:
	if animated_sprite:
		if animated_sprite.animation == "Attack":
			is_attacking = false
		elif animated_sprite.animation == "Parry":
			is_parrying = false
