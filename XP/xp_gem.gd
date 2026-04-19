extends Area2D

@export var xp_value: int = 3
@export var collect_speed: float = 400.0
@export var magnet_distance: float = 200.0

var player: Node2D = null
var is_magnetized: bool = false

func _ready() -> void:
	add_to_group("Drop") # <--- NOWOŚĆ: Grupa dla Globalnego Magnesu
	
	# Podpięcie sygnałów kolizji
	body_entered.connect(_on_collected)
	area_entered.connect(_on_collected)

func _process(delta: float) -> void:
	# Szukamy gracza, jeśli go nie mamy
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		# Awaryjne szukanie po nazwie, gdyby grupa nie zadziałała
		if not player:
			player = get_tree().current_scene.find_child("Player", true, false)
		return
		
	# Włączenie lokalnego magnesu
	if not is_magnetized:
		var dist = global_position.distance_to(player.global_position)
		if dist < magnet_distance:
			is_magnetized = true
		
	# Ruch w stronę gracza
	if is_magnetized:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * collect_speed * delta
		collect_speed += 10.0 # Przyspiesza z czasem, by zawsze dogonić

# --- NOWA FUNKCJA DLA GLOBALNEGO MAGNESU ---
func magnetize_to(target_player: Node2D) -> void:
	player = target_player
	is_magnetized = true
	collect_speed = max(collect_speed, 800.0) # Nadaje wielką prędkość od razu!

func _on_collected(body_or_area: Node) -> void:
	# Sprawdzamy co w nas uderzyło
	var target = body_or_area
	if not target.is_in_group("Player") and target.name != "Player":
		target = body_or_area.get_parent()
		
	# Jeśli to gracz i potrafi przyjmować XP
	if target and target.has_method("gain_xp"):
		target.gain_xp(xp_value)
		queue_free()
