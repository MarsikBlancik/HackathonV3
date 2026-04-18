extends Node2D

var tier: int = 1
const PUDDLE_SCENE = preload("res://FirePuddle.tscn")

func throw_bottle(start_pos: Vector2, target_pos: Vector2, current_tier: int) -> void:
	global_position = start_pos
	tier = current_tier
	
	var throw_duration = 0.5 
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Lot bazy do celu
	tween.tween_property(self, "global_position", target_pos, throw_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Skok grafiki w górę i w dół (łuk)
	var arc_tween = create_tween()
	var jump_height = -60.0
	arc_tween.tween_property($Sprite2D, "position:y", jump_height, throw_duration / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	arc_tween.tween_property($Sprite2D, "position:y", 0.0, throw_duration / 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD).set_delay(throw_duration / 2.0)
	
	# Rotacja butelki w locie
	tween.tween_property($Sprite2D, "rotation", PI * 5, throw_duration) 
	
	# Kiedy doleci, rozbijamy butelkę
	await tween.finished
	shatter()

func shatter() -> void:
	if PUDDLE_SCENE:
		var puddle = PUDDLE_SCENE.instantiate()
		puddle.global_position = global_position
		puddle.tier = tier # Przekazujemy Tier do kałuży!
		get_parent().add_child(puddle)
		
	queue_free() # Usuwamy butelkę
