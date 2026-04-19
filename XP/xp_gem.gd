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
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		if not player:
			player = get_tree().current_scene.find_child("Player", true, false)
		return
		
	var dist = global_position.distance_to(player.global_position)
	
	# Włączenie lokalnego magnesu
	if not is_magnetized and dist < magnet_distance:
		is_magnetized = true
		
	# Ruch w stronę gracza
	if is_magnetized:
		collect_speed += 800.0 * delta 
		global_position = global_position.move_toward(player.global_position, collect_speed * delta)
		
		# Zabezpieczenie #1: Dystans
		if global_position.distance_to(player.global_position) < 40.0:
			_on_collected(player)
			
		# Zabezpieczenie #2: Odkurzacz kolizji
		for node in get_overlapping_bodies() + get_overlapping_areas():
			_on_collected(node)

# --- NOWA FUNKCJA DLA GLOBALNEGO MAGNESU ---
func magnetize_to(target_player: Node2D) -> void:
	player = target_player
	is_magnetized = true
	collect_speed = max(collect_speed, 800.0) # Nadaje wielką prędkość od razu!

func _on_collected(node: Node) -> void:
	var target = node
	
	# Szukamy funkcji na rodzicu, jeśli ten konkretny obiekt jej nie ma
	if not target.has_method("gain_xp") and target.get_parent() != null:
		target = target.get_parent()
		
	if target.has_method("gain_xp"):
		target.gain_xp(xp_value)
		queue_free()
