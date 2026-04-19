extends Area2D

@export var coin_value: int = 1
@export var magnet_range: float = 150.0 
@export var follow_speed: float = 200.0 

var player: Node2D = null
var is_following: bool = false
var float_tween: Tween

func _ready() -> void:
	add_to_group("Drop") # <--- NOWOŚĆ: Grupa dla Globalnego Magnesu
	
	# Szukamy gracza na scenie
	player = get_tree().get_first_node_in_group("Player")
	
	# Prosta animacja "lewitowania" monety
	float_tween = create_tween().set_loops()
	float_tween.tween_property($Sprite2D, "position:y", -4.0, 0.6).as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property($Sprite2D, "position:y", 4.0, 0.6).as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	body_entered.connect(_on_collected)
	area_entered.connect(_on_collected)

func _process(delta: float) -> void:
	if is_instance_valid(player):
		# 1. Sprawdzanie czy gracz wszedł w lokalną strefę
		if not is_following:
			if global_position.distance_to(player.global_position) <= magnet_range:
				is_following = true
				if float_tween:
					float_tween.kill() # Zatrzymujemy podskakiwanie
		
		# 2. Lot w stronę gracza
		if is_following:
			var direction = (player.global_position - global_position).normalized()
			follow_speed += 600.0 * delta 
			global_position += direction * follow_speed * delta

# --- NOWA FUNKCJA DLA GLOBALNEGO MAGNESU ---
func magnetize_to(target_player: Node2D) -> void:
	player = target_player
	is_following = true
	follow_speed = max(follow_speed, 800.0) # Szybki zryw!
	if float_tween:
		float_tween.kill() # Upewniamy się, że przerywa animację zawieszenia

func _on_collected(node: Node2D) -> void:
	var player_node = null
	
	if node.is_in_group("Player"):
		player_node = node
	elif node.get_parent() != null and node.get_parent().is_in_group("Player"):
		player_node = node.get_parent()
		
	if player_node != null:
		if player_node.has_method("gain_coins"):
			player_node.gain_coins(coin_value)
			queue_free()
