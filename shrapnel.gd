extends Area2D

var speed: float = 600.0
var damage: int = 2
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	get_tree().create_timer(0.4).timeout.connect(queue_free) # Odłamki znikają bardzo szybko!
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
	if target.is_in_group("Enemy") and target.has_method("take_damage"):
		target.take_damage(damage, global_position)
		queue_free()
