extends Control

func _ready() -> void:
	# Na wszelki wypadek upewniamy się, że przycisk jest ukryty na starcie
	#hide() 
	
	# Szukamy gracza w scenie i łączymy się z jego sygnałem
	# Zakładamy, że gracz nazywa się "Player" w drzewie sceny
	var player = get_tree().current_scene.find_child("Player")
	if player:
		player.died.connect(_on_player_died)

# Ta funkcja wywoła się, gdy gracz wyśle sygnał 'died'
func _on_player_died() -> void:
	show() # Pokazuje przycisk

# Podepnij ten sygnał w Inspektorze (z zakładki Node -> pressed())
func _on_pressed() -> void:
	# Przeładowuje obecną scenę od nowa
	get_tree().reload_current_scene()
