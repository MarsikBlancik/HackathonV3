extends Area2D

@export var xp_value: int = 5
@export var collect_speed: float = 450.0
@export var magnet_distance: float = 20.0 # Zasięg przyciągania

var player: Node2D = null
var being_collected: bool = false

func _ready() -> void:
	# Szukamy gracza na starcie
	_find_player()
	
	# Łączymy kolizję (zbieranie)
	area_entered.connect(_on_collected)
	body_entered.connect(_on_collected)

func _find_player():
	# Najpierw po grupie
	player = get_tree().get_first_node_in_group("Player")
	# Jeśli nie ma, to po nazwie w całej scenie
	if player == null:
		player = get_tree().root.find_child("Player", true, false)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		if Engine.get_frames_drawn() % 60 == 0: # Szukaj gracza co 60 klatek
			_find_player()
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	# Aktywacja magnesu
	if dist < magnet_distance:
		being_collected = true
		
	if being_collected:
		var direction = (player.global_position - global_position).normalized()
		# Ruch globalny
		global_position += direction * collect_speed * delta
		# Przyspieszanie lotu
		collect_speed += 10.0

func _on_collected(thing: Node) -> void:
	# Sprawdzamy czy to gracz (bezpośrednio lub rodzic)
	var p = thing if (thing.is_in_group("Player") or thing.name == "Player") else thing.get_parent()
	
	if p and (p.is_in_group("Player") or p.name == "Player"):
		if p.has_method("gain_xp"):
			p.gain_xp(xp_value)
			queue_free()
