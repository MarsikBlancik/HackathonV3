extends Node2D

@export var enemy_scene: PackedScene 
@export var offscreen_buffer: float = 100.0 # Zapas pikseli za krawędzią ekranu

var player: Node2D = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _on_timer_timeout() -> void:
	if is_instance_valid(player):
		spawn_enemy()

func spawn_enemy() -> void:
	var new_enemy = enemy_scene.instantiate()
	
	# 1. Losujemy kierunek (kąt od 0 do 360 stopni)
	var random_angle = randf() * TAU
	
	# 2. Pobieramy aktualny rozmiar okna gry (szerokość i wysokość)
	var viewport_size = get_viewport_rect().size
	
	# 3. Obliczamy połowę przekątnej ekranu. 
	# Funkcja length() liczy przeciwprostokątną trójkąta (twierdzenie Pitagorasa).
	# Gwarantuje to, że promień wyjdzie poza NAJDALSZY róg ekranu.
	var screen_diagonal_half = viewport_size.length() / 2.0
	
	# 4. Ustalamy dynamiczny promień spawnowania (przekątna + zapas bezpieczeństwa)
	var dynamic_radius = screen_diagonal_half + offscreen_buffer
	
	# Jeśli w przyszłości dodasz przybliżanie/oddalanie kamery (zoom), odznacz poniższe linie:
	# var camera = player.get_node_or_null("Camera2D")
	# if camera:
	#     dynamic_radius /= camera.zoom.x
	
	# 5. Wyliczamy pozycję i dodajemy wroga
	var direction = Vector2(cos(random_angle), sin(random_angle))
	var spawn_position = player.global_position + (direction * dynamic_radius)
	
	new_enemy.global_position = spawn_position
	get_parent().add_child(new_enemy)
