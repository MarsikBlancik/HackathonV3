extends Area2D

@export var speed: float = 500.0
var damage: int = 1
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Zniknij po 2 sekundach, jeśli w nic nie trafisz
	get_tree().create_timer(2.0).timeout.connect(queue_free)
	
	# Nasłuchuj kolizji
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	_deal_damage(body)

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() != null:
		_deal_damage(area.get_parent())

func _deal_damage(target: Node) -> void:
	# Pocisk drona rani TYLKO wrogów (ignoruje gracza i jego miecz!)
	if target.is_in_group("Enemy") and target.has_method("take_damage"):
		target.take_damage(damage, global_position)
		queue_free()
