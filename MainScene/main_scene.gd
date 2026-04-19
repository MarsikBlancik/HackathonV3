extends Node2D

# --- SYGNAŁY ---
signal boss_spawned(boss_node)

# --- KONFIGURACJA PRZEJŚCIA (BRAMA) ---
const GATE_TEX = preload("res://Menus/Gate.png")
@export_group("Animacja Startowa")
@export var gate_size_pixels: Vector2 = Vector2(1940, 1100)
@export var gate_lift_time: float = 1.5
@export var shake_intensity: float = 4.0
@export var shake_speed: float = 50.0

@export_group("Sceny i Statystyki")
@export var xp_gem_scene: PackedScene 
@export var initial_xp_count: int = 40
@export var spawn_range: float = 600.0
@export var shop_scene: PackedScene
@export var shop_max_distance: float = 800.0
@export var shop_min_distance: float = 300.0
@export var boss_scene: PackedScene
@export var boss_spawn_distance: float = 500.0 

@onready var player
@onready var ui = $UI
@onready var time_label = $UI/Time 

var elapsed_seconds: int = 0 
var game_timer: Timer        
var shop_despawn_timer: Timer
var current_shop: Node2D = null

# Zmienne dla efektu bramy
var is_gate_shaking: bool = false
var original_ui_offset: Vector2 # ZMIANA: position -> offset

func _ready() -> void:
	# ZMIANA: Zapamiętujemy offset warstwy UI
	if ui:
		original_ui_offset = ui.offset
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	
	if time_label:
		time_label.text = "00:00"
		
	setup_timers()
	
	if ui and ui.has_method("_on_boss_spawned"):
		boss_spawned.connect(ui._on_boss_spawned)

	# --- NOWE: ODPALENIE ANIMACJI OTWARCIA BRAMY ---
	start_gate_opening()

func _process(delta: float) -> void:
	if is_gate_shaking and ui:
		var time = Time.get_ticks_msec() / 1000.0
		# ZMIANA: Używamy ui.offset zamiast ui.position
		ui.offset.x = original_ui_offset.x + sin(time * shake_speed) * shake_intensity
		ui.offset.y = original_ui_offset.y + cos(time * shake_speed * 1.1) * (shake_intensity * 0.5)
	elif ui:
		ui.offset = original_ui_offset

# --- FUNKCJA OTWIERANIA BRAMY ---
func start_gate_opening():
	if not ui: return
	
	# Tworzymy bramę jako element UI
	var gate = TextureRect.new()
	gate.texture = GATE_TEX
	gate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gate.stretch_mode = TextureRect.STRETCH_SCALE
	gate.size = gate_size_pixels
	
	# Dodajemy bramę do UI (CanvasLayer)
	ui.add_child(gate)
	
	var screen_size = get_viewport_rect().size
	
	# Pozycjonujemy na środku ekranu
	gate.global_position.x = (screen_size.x - gate.size.x) / 2
	var target_y = -gate.size.y
	var start_y = (screen_size.y - gate.size.y) / 2
	
	gate.global_position.y = start_y
	
	# Start efektów
	is_gate_shaking = true
	var tween = create_tween()
	
	# Animacja podnoszenia
	tween.tween_property(gate, "global_position:y", target_y, gate_lift_time)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	# Sprzątanie
	is_gate_shaking = false
	ui.offset = original_ui_offset
	gate.queue_free()

# --- RESZTA TWOJEJ LOGIKI ---

func setup_timers() -> void:
	game_timer = Timer.new()
	game_timer.wait_time = 1.0
	game_timer.autostart = true
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	
	shop_despawn_timer = Timer.new()
	shop_despawn_timer.wait_time = 30.0
	shop_despawn_timer.one_shot = true
	shop_despawn_timer.timeout.connect(_on_despawn_timer_timeout)
	add_child(shop_despawn_timer)

func _on_game_timer_timeout() -> void:
	elapsed_seconds += 1
	if time_label:
		var minutes = elapsed_seconds / 60
		var seconds = elapsed_seconds % 60
		time_label.text = "%02d:%02d" % [minutes, seconds]
	
	if elapsed_seconds % 5 == 0:
		spawn_shop()
		
	if elapsed_seconds == 600: 
		spawn_boss()

func _on_despawn_timer_timeout() -> void:
	despawn_shop()

func spawn_shop() -> void:
	despawn_shop()
	if shop_scene == null or player == null:
		return
		
	current_shop = shop_scene.instantiate()
	var random_angle = randf() * TAU
	var random_distance = randf_range(shop_min_distance, shop_max_distance)
	var spawn_offset = Vector2.UP.rotated(random_angle) * random_distance
	
	current_shop.global_position = player.global_position + spawn_offset
	add_child(current_shop)
	shop_despawn_timer.start()

func despawn_shop() -> void:
	if is_instance_valid(current_shop):
		current_shop.queue_free()
		current_shop = null

func spawn_boss() -> void:
	if boss_scene == null or player == null:
		return
	var boss = boss_scene.instantiate()
	var random_angle = randf() * TAU
	var spawn_offset = Vector2.UP.rotated(random_angle) * boss_spawn_distance
	boss.global_position = player.global_position + spawn_offset
	add_child(boss)
	boss_spawned.emit(boss)
