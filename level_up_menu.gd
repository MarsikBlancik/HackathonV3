extends ColorRect

@onready var container = $HBoxContainer
# Załadowanie czcionki schlop oraz obrazka tła
const SCHLOP_FONT = preload("res://shlop rg.otf")
const TABLICZKA_TEX = preload("res://Tabliczka.png")

# --- NOWE ZMIENNE DO ANIMACJI I ZABEZPIECZEŃ ---
var can_click: bool = false
var container_start_y: float = 0.0

func _ready() -> void:
	hide() # Ukrywamy menu na starcie gry
	
	# BARDZO WAŻNE: Menu musi działać, gdy gra jest zapauzowana!
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# Ustawiamy margines zewnętrzny: odstęp (w pikselach) MIĘDZY tabliczkami
	container.add_theme_constant_override("separation", 40)
	
	# Zapisujemy docelową (oryginalną) pozycję Y kontenera, żeby wiedzieć, dokąd ma spaść
	container_start_y = container.position.y
	
	# Szukamy gracza i podpinamy się pod sygnał, który stworzyliśmy wcześniej
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.show_upgrade_menu.connect(show_menu)

func show_menu(choices: Array) -> void:
	# 1. ZATRZYMUJEMY GRĘ
	get_tree().paused = true
	show()
	
	# 2. Blokujemy klikanie na czas animacji i odczekania (missclick protection)
	can_click = false
	
	# Najpierw czyścimy stare przyciski z poprzedniego awansu
	for child in container.get_children():
		child.queue_free()
		
	# Przygotowanie stylu tła na podstawie obrazka Tabliczka.png
	var tabliczka_style = StyleBoxTexture.new()
	tabliczka_style.texture = TABLICZKA_TEX
	
	tabliczka_style.texture_margin_top = 20
	tabliczka_style.texture_margin_bottom = 20
	tabliczka_style.texture_margin_left = 15
	tabliczka_style.texture_margin_right = 15
		
	# Tworzymy nowe kafelki na podstawie wylosowanej puli
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
		
		# Podmiana tła przycisku na Twój obrazek Tabliczka.png
		btn.add_theme_stylebox_override("normal", tabliczka_style)
		btn.add_theme_stylebox_override("hover", tabliczka_style)
		btn.add_theme_stylebox_override("pressed", tabliczka_style)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		# ---------------------------
		
		# Domyślnie kursor to zwykła strzałka (żeby nie sugerować, że można kliknąć)
		btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		
		# Podpinamy kliknięcie i przekazujemy nazwę gadżetu
		btn.pressed.connect(_on_choice_made.bind(gadget_name))
		
		# Dodajemy przycisk na ekran
		container.add_child(btn)

	# --- ANIMACJA WSKAKIWANIA Z GÓRY ---
	# Przesuwamy kontener z kartami wysoko poza górną krawędź ekranu
	
	# Tworzymy Tweena (działa mimo pauzy, bo process_mode tego skryptu to ALWAYS)
	var tween = create_tween()
	
	# Animujemy zjazd w dół do oryginalnej pozycji w 0.8 sekundy. 
	# TRANS_BOUNCE i EASE_OUT dodadzą fajny efekt fizycznego "odbicia się" kart na końcu.
	
	# Czekamy równe 2 sekundy (ignore_time_scale zabezpiecza przed błędami przy pauzie)
	await get_tree().create_timer(1.0, true, false, true).timeout
	
	# Po 2 sekundach odblokowujemy klikanie i zmieniamy kursor na rączkę
	can_click = true
	for btn in container.get_children():
		if btn is Button:
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func get_gadget_display_name(gadget_name: String) -> String:
	match gadget_name:
		"drones": return "Bojowe Drony\n(Strzelają we wrogów)"
		"mines": return "Wybuchowe Miny\n(Zostają na podłodze)"
		"dash_ram": return "Taranowanie\n(Ranisz wrogów podczas uniku)"
		"pipe_bomb": return "Granat Rurowy\n(Prawy Przycisk Myszy)"
		"molotov": return "Koktajl Mołotowa\n(Klawisz E)"
		_: return gadget_name

func _on_choice_made(gadget_name: String) -> void:
	# --- ZABEZPIECZENIE: Jeśli gracza klika za wcześnie, anuluj operację ---
	if not can_click:
		return
		
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_node("GadgetManager"):
		player.get_node("GadgetManager").apply_upgrade(gadget_name)
	
	hide()
	get_tree().paused = false
