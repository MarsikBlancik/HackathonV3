extends Area2D

func _ready() -> void:
	# Dodajmy fajny efekt "unoszenia się" magnesu na ziemi
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5.0, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 0.0, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		activate_magnet(body)
		
		# Opcjonalnie: odtwórz dźwięk podniesienia magnesu
		
		queue_free() # Zniszcz magnes po zebraniu

func activate_magnet(player: Node2D) -> void:
	print("Magnes zebrany! Przyciągam cały łup...")
	
	# Pobieramy wszystkie obiekty, które są w grupie "Drop"
	var all_drops = get_tree().get_nodes_in_group("Drop")
	
	for drop in all_drops:
		if is_instance_valid(drop) and drop.has_method("magnetize_to"):
			drop.magnetize_to(player)
