extends Node2D

@export var xp_gem_scene: PackedScene 
@export var initial_xp_count: int = 50
@export var spawn_range: float = 500.0 

@onready var player 
@onready var ui = $UI

func _ready() -> void:
	# KLUCZOWE: Inicjalizuje generator liczb losowych
	randomize() 
	
	await get_tree().create_timer(0.2).timeout
	
	if player == null: player = get_node_or_null("Player")
	if ui == null: ui = get_node_or_null("UI")
	
	spawn_initial_xp()
	
	# Połączenia sygnałów
	if player and ui:
		if not player.hp_changed.is_connected(ui.update_hp):
			player.hp_changed.connect(ui.update_hp)
		if not player.energy_changed.is_connected(ui.update_energy):
			player.energy_changed.connect(ui.update_energy)
		if player.has_signal("xp_changed"):
			player.xp_changed.connect(ui.update_xp)
			ui.update_xp(player.current_xp, player.xp_to_next_level)

func spawn_initial_xp() -> void:
	if xp_gem_scene == null: return

	# Pobieramy pozycję startową (środek mapy)
	var center = Vector2.ZERO
	if is_instance_valid(player):
		center = player.global_position

	for i in range(initial_xp_count):
		var gem = xp_gem_scene.instantiate()
		
		# Losujemy pozycję Wewnątrz pętli
		var rx = randf_range(-spawn_range, spawn_range)
		var ry = randf_range(-spawn_range, spawn_range)
		var random_offset = Vector2(rx, ry)
		
		# Dodajemy do MainScene (self), a nie do gracza!
		add_child(gem)
		
		# Ustawiamy pozycję
		gem.global_position = center + random_offset
		
		# Debug: Sprawdźmy w konsoli czy liczby są różne
		if i < 5: 
			print("Gem ", i, " pozycja: ", gem.global_position)
