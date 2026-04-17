extends Node2D

@export var enemy_scene: PackedScene 
@export var offscreen_buffer: float = 100.0

# --- USTAWIENIA TRUDNOŚCI ---
@export var initial_spawn_time: float = 3.0 # Początkowy średni czas
@export var min_spawn_time: float = 0.5     # Limit szybkości
@export var time_to_reach_limit: float = 300.0 # Ile sekund do limitu (300s = 5 minut)
@export var variance: float = 0.5           # Losowe odchylenie (+/- 0.5s)

var current_base_time: float
var player: Node2D = null

@onready var timer: Timer = $Timer

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	current_base_time = initial_spawn_time
	set_next_timer()

func _process(delta: float) -> void:
	# Płynnie zmniejszamy czas bazowy co klatkę.
	# Obliczamy o ile sekund czas ma spadać w ciągu JEDNEJ sekundy gry.
	var decrease_per_second = (initial_spawn_time - min_spawn_time) / time_to_reach_limit
	
	current_base_time -= decrease_per_second * delta
	
	# Pilnujemy, aby czas bazowy nie spadł poniżej limitu
	current_base_time = max(min_spawn_time, current_base_time)

func _on_timer_timeout() -> void:
	if is_instance_valid(player):
		spawn_enemy()
		
	# Odpalamy Timer na nowo (nie obniżamy już czasu tutaj!)
	set_next_timer()

func set_next_timer() -> void:
	var random_offset = randf_range(-variance, variance)
	var next_time = current_base_time + random_offset
	
	next_time = max(min_spawn_time, next_time)
	timer.start(next_time)

func spawn_enemy() -> void:
	var new_enemy = enemy_scene.instantiate()
	var random_angle = randf() * TAU
	
	var viewport_size = get_viewport_rect().size
	var screen_diagonal_half = viewport_size.length() / 2.0
	var dynamic_radius = screen_diagonal_half + offscreen_buffer
	
	var direction = Vector2(cos(random_angle), sin(random_angle))
	var spawn_position = player.global_position + (direction * dynamic_radius)
	
	new_enemy.global_position = spawn_position
	get_parent().add_child(new_enemy)
