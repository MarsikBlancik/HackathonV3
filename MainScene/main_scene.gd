extends Node2D

@export var xp_gem_scene: PackedScene 
@export var initial_xp_count: int = 40
@export var spawn_range: float = 600.0

# --- ZMIENNE DLA SKLEPU ---
@export var shop_scene: PackedScene
@export var shop_max_distance: float = 800.0
@export var shop_min_distance: float = 300.0

@onready var player
@onready var ui = $UI
# Pobieramy referencję do Labela (zakładając, że jest dzieckiem UI)
@onready var time_label = $UI/Time 

# --- STAN GRY I TIMERY ---
var elapsed_seconds: int = 0 
var game_timer: Timer        
var shop_despawn_timer: Timer
var current_shop: Node2D = null

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	
	# Ustawiamy tekst początkowy na 00:00
	if time_label:
		time_label.text = "00:00"
		
	setup_timers()

func setup_timers() -> void:
	game_timer = Timer.new()
	game_timer.wait_time = 1.0
	game_timer.autostart = true
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	
	shop_despawn_timer = Timer.new()
	shop_despawn_timer.wait_time = 60.0
	shop_despawn_timer.one_shot = true
	shop_despawn_timer.timeout.connect(_on_despawn_timer_timeout)
	add_child(shop_despawn_timer)

func _on_game_timer_timeout() -> void:
	elapsed_seconds += 1
	
	# --- AKTUALIZACJA LABELA CZASU ---
	if time_label:
		var minutes = elapsed_seconds / 60
		var seconds = elapsed_seconds % 60
		# %02d oznacza, że liczba zawsze będzie miała 2 cyfry (dopisze zero z przodu)
		time_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Sprawdzanie spawnu sklepu
	if elapsed_seconds % 5 == 0:
		spawn_shop()

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
