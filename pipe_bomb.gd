extends Node2D

var tier: int = 1
var damage: int = 10
var explosion_radius: float = 100.0

const SHRAPNEL_SCENE = preload("res://Shrapnel.tscn")

func throw_bomb(start_pos: Vector2, target_pos: Vector2, current_tier: int) -> void:
	global_position = start_pos
	tier = current_tier
	
	# Statystyki zależne od Tieru
	match tier:
		1:
			damage = 15
			explosion_radius = 100.0
		2:
			damage = 30
			explosion_radius = 150.0
		3:
			damage = 45
			explosion_radius = 150.0 # Tier 3 dodaje też odłamki (logika w explode)

	# --- ANIMACJA RZUTU (Lot na miejsce + podskok grafiki) ---
	var throw_duration = 0.5 # Pół sekundy w powietrzu
	
	var tween = create_tween()
	tween.set_parallel(true) # Wykonuj animacje równocześnie
	
	# 1. Ruch bazy do celu (po ziemi)
	tween.tween_property(self, "global_position", target_pos, throw_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# 2. Ruch Sprite'a w górę i w dół (symulacja łuku)
	var arc_tween = create_tween()
	var jump_height = -80.0
	arc_tween.tween_property($Sprite2D, "position:y", jump_height, throw_duration / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	arc_tween.tween_property($Sprite2D, "position:y", 0.0, throw_duration / 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD).set_delay(throw_duration / 2.0)
	
	# 3. Kręcenie się w powietrzu
	tween.tween_property($Sprite2D, "rotation", PI * 4, throw_duration) 
	
	# Po zakończeniu lotu... wybuch!
	await tween.finished
	explode()

func explode() -> void:
	# 1. OBRAŻENIA OBSZAROWE
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			if global_position.distance_to(enemy.global_position) <= explosion_radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage, global_position)
					
	# 2. EFEKT WIZUALNY WYBUCHU
	var boom = ColorRect.new()
	boom.color = Color(1.0, 0.2, 0.0, 0.8) # Czerwono-pomarańczowy
	boom.size = Vector2(explosion_radius * 2, explosion_radius * 2)
	boom.position = -boom.size / 2
	
	var fx_node = Node2D.new()
	fx_node.global_position = global_position
	fx_node.add_child(boom)
	get_parent().add_child(fx_node)
	
	var tween = fx_node.create_tween()
	tween.tween_property(boom, "modulate:a", 0.0, 0.2)
	tween.finished.connect(fx_node.queue_free)
	
	# 3. TIER 3 - SZRAPNEL (Rozrzut na wszystkie strony)
	if tier >= 3 and SHRAPNEL_SCENE:
		var directions = 8
		for i in range(directions):
			var shrapnel = SHRAPNEL_SCENE.instantiate()
			shrapnel.global_position = global_position
			var angle = (PI * 2 / directions) * i
			shrapnel.direction = Vector2(cos(angle), sin(angle))
			shrapnel.rotation = shrapnel.direction.angle()
			get_parent().add_child(shrapnel)

	# 4. Zniszcz granat
	queue_free()
