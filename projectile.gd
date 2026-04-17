extends Area2D

@export var speed: float = 300.0
@export var damage: int = 1
@export var can_be_parried: bool = true

var direction: Vector2 = Vector2.ZERO
var is_parried: bool = false

func _ready() -> void:
	# Usuń pocisk po 4 sekundach, żeby nie leciał w nieskończoność
	get_tree().create_timer(4.0).timeout.connect(queue_free)
	
	# Podłączenie detekcji kolizji
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func set_direction(dir: Vector2) -> void:
	direction = dir
	rotation = dir.angle()

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	# 1. Trafienie w gracza (jeśli pocisk nie jest sparowany)
	if not is_parried and body.is_in_group("Player") and body.has_method("modify_hp"):
		# Przekazujemy global_position, żeby gracz dostał knockback od pocisku!
		body.modify_hp(-damage, global_position) 
		queue_free()
		
	# 2. Trafienie we wroga (jeśli pocisk został odbity/sparowany)
	elif is_parried and body.has_method("take_damage") and not body.is_in_group("Player"):
		# Sparowany pocisk zadaje np. podwójne obrażenia
		body.take_damage(damage * 2, global_position) 
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Obejście na wypadek, gdyby detekcja opierała się na Area2D zamiast ciał
	var parent = area.get_parent()
	if parent != null:
		_on_body_entered(parent)

# --- FUNKCJA PAROWANIA ---
func parry(new_direction: Vector2) -> void:
	if can_be_parried and not is_parried:
		print("Pocisk sparowany!")
		is_parried = true
		direction = new_direction # Odbijamy w nowym kierunku
		speed *= 1.5 # Odbity pocisk przyspiesza
		
		# Zmiana koloru na zielony, jako wskaźnik odbicia
		modulate = Color(0.0, 1.0, 0.0)
