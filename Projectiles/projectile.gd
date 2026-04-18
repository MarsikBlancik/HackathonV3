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
	var target = body
	
	# --- NOWOŚĆ: SZUKANIE RODZICA ---
	# Jeśli trafiliśmy w ciało fizyczne, ale to jego rodzic ma statystyki (tak jak u Twojego gracza)
	if not target.has_method("modify_hp") and target.get_parent() != null and target.get_parent().has_method("modify_hp"):
		target = target.get_parent()
		
	# To samo zabezpieczenie dla wrogów (na przyszłość)
	if not target.has_method("take_damage") and target.get_parent() != null and target.get_parent().has_method("take_damage"):
		target = target.get_parent()

	# 1. Trafienie w gracza (jeśli pocisk nie jest sparowany)
	if not is_parried and target.is_in_group("Player") and target.has_method("modify_hp"):
		target.modify_hp(-damage, global_position) 
		queue_free()
		
	# 2. Trafienie we wroga (jeśli pocisk został odbity/sparowany)
	elif is_parried and target.has_method("take_damage") and not target.is_in_group("Player"):
		target.take_damage(damage * 2, global_position) 
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Ignorujemy całkowicie miecz gracza podczas zadawania obrażeń
	if area.name == "Sword":
		return 
		
	# Obejście na wypadek, gdyby detekcja opierała się na Area2D zamiast ciał
	var parent = area.get_parent()
	if parent != null:
		_on_body_entered(parent)

# --- FUNKCJA PAROWANIA ---
func parry(new_direction: Vector2) -> void:
	if can_be_parried and not is_parried:
		print("Pocisk sparowany!")
		is_parried = true
		direction = new_direction 
		speed *= 1.5 
		
		# Zmiana koloru na zielony, jako wskaźnik odbicia
		modulate = Color(0.0, 1.0, 0.0)
