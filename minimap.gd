extends Control

@export var map_scale: float = 0.05 # Skala (im mniejsza, tym bardziej "oddalony" widok)
@export var map_radius: float = 1500.0 # Maksymalny zasięg "widzenia" radaru w pikselach gry

var player: Node2D = null

func _ready() -> void:
	# Szukamy gracza na starcie
	player = get_tree().get_first_node_in_group("Player")
	
	# Upewniamy się, że kliknięcia myszką "przelatują" przez minimapę do gry
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		# Co klatkę wymuszamy ponowne narysowanie kropek
		queue_redraw() 

func _draw() -> void:
	if not is_instance_valid(player): return
	
	# Środek naszego panelu minimapy
	var center = size / 2.0
	
	# 1. Rysowanie tła minimapy (półprzezroczyste czarne)
	# Możesz to usunąć, jeśli wolisz przezroczyste tło
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.4))
	
	# Opcjonalnie: ramka dookoła minimapy
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.8, 0.8, 0.8, 0.8), false, 2.0)
	
	# 2. Rysowanie przeciwników (Czerwone kropki)
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		
		# Sprawdzamy dystans
		var dist = player.global_position.distance_to(enemy.global_position)
		if dist <= map_radius:
			# Obliczamy relatywną pozycję względem gracza i skalujemy
			var relative_pos = (enemy.global_position - player.global_position) * map_scale
			
			# Rysujemy kropkę
			draw_circle(center + relative_pos, 3.0, Color(1.0, 0.2, 0.2)) # Czerwony
			
	# 3. Rysowanie XP (Zielone kropki)
	var xps = get_tree().get_nodes_in_group("XP")
	for xp in xps:
		if not is_instance_valid(xp): continue
		
		var dist = player.global_position.distance_to(xp.global_position)
		if dist <= map_radius:
			var relative_pos = (xp.global_position - player.global_position) * map_scale
			draw_circle(center + relative_pos, 2.0, Color(0.2, 1.0, 0.2)) # Zielony, lekko mniejsza kropka
			
	# 4. Rysowanie Gracza (Biała kropka, zawsze na środku)
	draw_circle(center, 4.0, Color.WHITE)
