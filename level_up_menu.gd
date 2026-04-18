extends ColorRect

@onready var container = $HBoxContainer

func _ready() -> void:
	hide() # Ukrywamy menu na starcie gry
	
	# BARDZO WAŻNE: Menu musi działać, gdy gra jest zapauzowana!
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# Szukamy gracza i podpinamy się pod sygnał, który stworzyliśmy wcześniej
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.show_upgrade_menu.connect(show_menu)

func show_menu(choices: Array) -> void:
	show()
	
	# 1. Najpierw czyścimy stare przyciski z poprzedniego awansu
	for child in container.get_children():
		child.queue_free()
		
	# 2. Tworzymy nowe kafelki na podstawie wylosowanej puli
	for gadget_name in choices:
		var btn = Button.new()
		
		# Ustawiamy tekst przycisku
		btn.text = get_gadget_display_name(gadget_name)
		
		# Ustawiamy rozmiar przycisku, żeby wyglądał jak "Karta" (kafelek)
		btn.custom_minimum_size = Vector2(200, 300) 
		
		# Magia Godota: podpinamy kliknięcie i przekazujemy nazwę gadżetu!
		btn.pressed.connect(_on_choice_made.bind(gadget_name))
		
		# Dodajemy przycisk na ekran
		container.add_child(btn)

# Tłumacz systemowych nazw na ładne nazwy dla gracza
func get_gadget_display_name(gadget_name: String) -> String:
	match gadget_name:
		"drones": return "Bojowe Drony\n(Strzelają we wrogów)"
		"mines": return "Wybuchowe Miny\n(Zostają na podłodze)"
		"dash_ram": return "Taranowanie\n(Ranisz wrogów podczas uniku)"
		"pipe_bomb": return "Granat Rurowy\n(Prawy Przycisk Myszy)" # <--- NOWOŚĆ
		"molotov": return "Koktajl Mołotowa\n(Klawisz E)"
		_: return gadget_name

func _on_choice_made(gadget_name: String) -> void:
	# 1. Znajdujemy menadżera gadżetów u gracza i aplikujemy wybór
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("GadgetManager"):
		player.get_node("GadgetManager").apply_upgrade(gadget_name)
	
	# 2. Ukrywamy menu i wznawiamy grę!
	hide()
	get_tree().paused = false
