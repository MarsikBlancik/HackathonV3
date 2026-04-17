extends Node2D

# Pobieramy referencje do węzłów w naszej scenie
# Upewnij się, że nazwy w cudzysłowach idealnie pasują do nazw węzłów w edytorze



# Funkcja wywoływana, gdy gracz umrze
func _on_player_died() -> void:
	get_tree().change_scene_to_file("res://Restart.tscn")

# Funkcja wywoływana, gdy gracz kliknie przycisk
func _on_restart_button_pressed() -> void:
	# Przeładowuje całkowicie obecną scenę (resetuje grę)
	get_tree().reload_current_scene()
