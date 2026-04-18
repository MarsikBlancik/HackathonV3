extends Area2D

var damage: int = 2
var explosion_radius: float = 80.0
var is_armed: bool = false # Zabezpieczenie, żeby mina nie wybuchła 2 razy naraz

func _ready() -> void:
	modulate = Color(1.0, 1.0, 1.0, 0.5) 
	await get_tree().create_timer(0.5).timeout
	
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	is_armed = true
	
	# Podpinamy OBA typy kolizji (dla pewności!)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node) -> void:
	_check_trigger(body)

func _on_area_entered(area: Area2D) -> void:
	_check_trigger(area)
	if area.get_parent() != null:
		_check_trigger(area.get_parent())

func _check_trigger(target: Node) -> void:
	if is_armed and target.is_in_group("Enemy"):
		is_armed = false # Rozbrajamy, żeby nie odpalić kilka razy
		print("BUM! Mina wykryła wroga: ", target.name)
		explode()

func explode() -> void:
	# 1. OBRAŻENIA OBSZAROWE (AoE) - Rani wszystkich w promieniu wybuchu
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			if global_position.distance_to(enemy.global_position) <= explosion_radius:
				if enemy.has_method("take_damage"):
					# Przekazujemy punkt wybuchu, żeby wróg dostał knockback odrzucony OD miny!
					enemy.take_damage(damage, global_position) 
					
	# 2. EFEKT WIZUALNY WYBUCHU (Szybki pomarańczowy prostokąt generowany w kodzie)
	var boom = ColorRect.new()
	boom.color = Color(1.0, 0.4, 0.0, 0.8) # Pomarańczowy
	boom.size = Vector2(explosion_radius * 2, explosion_radius * 2)
	boom.position = -boom.size / 2 # Wyśrodkowanie na minie
	
	var fx_node = Node2D.new()
	fx_node.global_position = global_position
	fx_node.add_child(boom)
	get_tree().current_scene.add_child(fx_node)
	
	# Płynne zanikanie wybuchu
	var tween = fx_node.create_tween()
	tween.tween_property(boom, "modulate:a", 0.0, 0.3)
	tween.finished.connect(fx_node.queue_free)
	
	# 3. Zniszcz samą minę
	queue_free()
