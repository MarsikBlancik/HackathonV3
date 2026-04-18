extends Area2D

var tier: int = 1
var damage: int = 2
var lifetime: float = 3.0
var is_napalm: bool = false # Dla Tier 3

func _ready() -> void:
	# Dostosowujemy statystyki na podstawie Tieru
	match tier:
		1:
			damage = 2
			lifetime = 3.0
			scale = Vector2(1.0, 1.0)
		2:
			damage = 4
			lifetime = 5.0
			scale = Vector2(1.5, 1.5) # Kałuża jest o 50% większa!
		3:
			damage = 6
			lifetime = 5.0
			scale = Vector2(1.5, 1.5)
			is_napalm = true # Odblokowujemy podpalenie!
			
	# Zniszcz kałużę po upływie jej czasu życia
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	
	# Zegar zadający obrażenia ("Tick rate" - co 0.5 sekundy)
	var tick_timer = Timer.new()
	tick_timer.wait_time = 0.5
	tick_timer.autostart = true
	tick_timer.timeout.connect(_deal_tick_damage)
	add_child(tick_timer)

func _deal_tick_damage() -> void:
	# Szukamy wszystkich, którzy stoją w ogniu
	for body in get_overlapping_bodies():
		_try_damage(body)
	for area in get_overlapping_areas():
		if area.get_parent() != null:
			_try_damage(area.get_parent())

func _try_damage(target: Node) -> void:
	if target.is_in_group("Enemy") and target.has_method("take_damage"):
		target.take_damage(damage, global_position)
		
		# --- TIER 3: EFEKT NAPALMU ---
		# Jeśli to Tier 3 i wróg jeszcze nie płonie, przyczepiamy do niego ogień!
		if is_napalm and not target.has_node("BurnEffect"):
			apply_burn_effect(target)

func apply_burn_effect(target: Node) -> void:
	# Tworzymy węzeł "pasożyta", który przyczepi się do wroga i będzie go ranił
	var burn = Node.new()
	burn.name = "BurnEffect"
	target.add_child(burn)
	
	var burn_ticks = 0
	var burn_timer = Timer.new()
	burn_timer.wait_time = 1.0 # Obrażenia z poparzenia co 1 sekundę
	burn.add_child(burn_timer)
	
	burn_timer.timeout.connect(func():
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(2, target.global_position) # 2 DMG z samego poparzenia
			burn_ticks += 1
			# Gaśnie po 3 sekundach
			if burn_ticks >= 3:
				burn.queue_free()
		else:
			burn.queue_free()
	)
	burn_timer.start()
