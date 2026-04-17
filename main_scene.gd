extends Node2D

@onready var player = $player
@onready var ui = $UI

func _ready() -> void:
	print("--- MAIN SCENE START ---")
	if player == null:
		print("BŁĄD: Nie mogę znaleźć węzła Player! (Sprawdź nazwę)")
	if ui == null:
		print("BŁĄD: Nie mogę znaleźć węzła UI! (Sprawdź nazwę)")
		
	if player and ui:
		print("SUKCES: Znalazłem Gracza i UI. Łączę sygnały...")
		player.hp_changed.connect(ui.update_hp)
		player.energy_changed.connect(ui.update_energy)
		
		# Pierwsza aktualizacja na starcie
		ui.update_hp(player.current_hp, player.max_hp)
		ui.update_energy(player.current_energy, player.max_energy)

func _on_player_died() -> void:
	get_tree().change_scene_to_file("res://Restart.tscn")

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
