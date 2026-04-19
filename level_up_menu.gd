extends ColorRect

@onready var container = $HBoxContainer
# Załadowanie czcionki schlop oraz obrazka tła
const SCHLOP_FONT = preload("res://shlop rg.otf")
const TABLICZKA_TEX = preload("res://Tabliczka.png")

func _ready() -> void:
	hide() # Ukrywamy menu na starcie gry
	
	# BARDZO WAŻNE: Menu musi działać, gdy gra jest zapauzowana!
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# Ustawiamy margines zewnętrzny: odstęp (w pikselach) MIĘDZY tabliczkami
	container.add_theme_constant_override("separation", 40)
	
	# Szukamy gracza i podpinamy się pod sygnał, który stworzyliśmy wcześniej
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.show_upgrade_menu.connect(show_menu)

func show_menu(choices: Array) -> void:
	show()
	
	# 1. Najpierw czyścimy stare przyciski z poprzedniego awansu
	for child in container.get_children():
		child.queue_free()
		
	# Przygotowanie stylu tła na podstawie obrazka Tabliczka.png
	var tabliczka_style = StyleBoxTexture.new()
	tabliczka_style.texture = TABLICZKA_TEX
	
	# Ustawiamy marginesy wewnętrzne (odległość tekstu od krawędzi obrazka)
	# Dostosuj te wartości w zależności od tego, jak grube ramki ma Twój rysunek
	tabliczka_style.texture_margin_top = 20
	tabliczka_style.texture_margin_bottom = 20
	tabliczka_style.texture_margin_left = 15
	tabliczka_style.texture_margin_right = 15
		
	# 2. Tworzymy nowe kafelki na podstawie wylosowanej puli
	for gadget_name in choices:
		var btn = Button.new()
		
		# Ustawiamy tekst przycisku
		btn.text = get_gadget_display_name(gadget_name)
		
		# Ustawiamy rozmiar przycisku, żeby wyglądał jak "Karta" (kafelek)
		btn.custom_minimum_size = Vector2(400, 600) 
		
		# --- STYLIZACJA CZCIONKI I TŁA ---
		btn.add_theme_font_override("font", SCHLOP_FONT)
		btn.add_theme_font_size_override("font_size", 36.7)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		# Podmiana tła przycisku na Twój obrazek Tabliczka.png (razem z ustawionymi marginesami wewnętrznymi)
		btn.add_theme_stylebox_override("normal", tabliczka_style)
		btn.add_theme_stylebox_override("hover", tabliczka_style)
		btn.add_theme_stylebox_override("pressed", tabliczka_style)
		
		# Ukrycie systemowej ramki, która pojawia się po kliknięciu/nawigacji klawiaturą
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		# ---------------------------
		
		# Podpinamy kliknięcie i przekazujemy nazwę gadżetu
		btn.pressed.connect(_on_choice_made.bind(gadget_name))
		
		# Dodajemy przycisk na ekran
		container.add_child(btn)

func get_gadget_display_name(gadget_name: String) -> String:
	match gadget_name:
		"drones": return "Bojowe Drony\n(Strzelają we wrogów)"
		"mines": return "Wybuchowe Miny\n(Zostają na podłodze)"
		"dash_ram": return "Taranowanie\n(Ranisz wrogów podczas uniku)"
		"pipe_bomb": return "Granat Rurowy\n(Prawy Przycisk Myszy)"
		"molotov": return "Koktajl Mołotowa\n(Klawisz E)"
		_: return gadget_name

func _on_choice_made(gadget_name: String) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("GadgetManager"):
		player.get_node("GadgetManager").apply_upgrade(gadget_name)
	
	hide()
	get_tree().paused = false
