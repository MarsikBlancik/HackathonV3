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
		var dist = global_position.distance_to(player.global_position)
		
		# 1. Sprawdzanie czy gracz wszedł w strefę magnesu
		if not is_following:
			if dist <= magnet_range:
				is_following = true
				if float_tween:
					float_tween.kill() # Zatrzymujemy podskakiwanie
		
		# 2. Lot w stronę gracza
		if is_following:
			follow_speed += 800.0 * delta 
			global_position = global_position.move_toward(player.global_position, follow_speed * delta)
			
			# Zabezpieczenie #1: Dystans (wymusza zebranie z bliska)
			if global_position.distance_to(player.global_position) < 40.0:
				_on_collected(player)
				
			# Zabezpieczenie #2: Odkurzacz (zbiera wszystko, co go dotyka w klatce lotu)
			for node in get_overlapping_bodies() + get_overlapping_areas():
				_on_collected(node)

# --- NOWA FUNKCJA DLA GLOBALNEGO MAGNESU ---
func magnetize_to(target_player: Node2D) -> void:
	player = target_player
	is_following = true
	follow_speed = max(follow_speed, 800.0) # Szybki zryw!
	if float_tween:
		float_tween.kill() # Upewniamy się, że przerywa animację zawieszenia

func _on_collected(node: Node) -> void:
	var target = node
	
	# PANCERNY DETEKTYW: Jeśli trafiliśmy w ramię/hitbox gracza, idziemy wzwyż do głównego skryptu
	if not target.has_method("gain_coins") and target.get_parent() != null:
		target = target.get_parent()
		
	# Jeśli po sprawdzeniu mamy cel z portfelem - zbieramy!
	if target.has_method("gain_coins"):
		target.gain_coins(coin_value)
		queue_free()
