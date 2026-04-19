extends Control

func _ready() -> void:
	hide() # Ukrywa całe menu (w tym ColorRect i przyciski) na starcie
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var btnContinue = $VBoxContainer/Continue
	var btnMainMenu = $VBoxContainer/MainMenu
	
	# Dobra praktyka: sprawdzanie czy sygnały nie są już podłączone, 
	# choć w _ready zazwyczaj nie jest to konieczne, chyba że sceneria jest resetowana.
	btnContinue.pressed.connect(_continue_pressed)
	btnMainMenu.pressed.connect(_main_menu_pressed)

func _input(_event):
	if Input.is_action_just_pressed("Pause"):
		
		# --- BRAMKARZ (Działa tylko, gdy próbujemy OTWORZYĆ menu pauzy) ---
		if not is_visible_in_tree():
			var current_scene = get_tree().current_scene
			if current_scene:
				# Szukamy na scenie węzłów Sklepu i Level Upu
				var shop_ui = current_scene.find_child("ShopUI", true, false)
				var level_up_menu = current_scene.find_child("LevelUpMenu", true, false)
				
				var is_shop_open = shop_ui != null and shop_ui.visible
				var is_level_up_open = level_up_menu != null and level_up_menu.visible
				
				# Jeśli któreś z nich jest otwarte, blokujemy włączenie Menu Pauzy
				if is_shop_open or is_level_up_open:
					print("Zablokowano Menu Pauzy - inne menu jest otwarte!")
					return # Przerywa kod, menu się nie otwiera
		# ------------------------------------------------------------------
		
		_toggle_pause() # Zmieniono nazwę dla jasności

func _toggle_pause():
	# is_visible_in_tree sprawdza, czy ten węzeł I jego rodzice są widoczni.
	if is_visible_in_tree():
		hide() # Ukrywa menu + zaciemnienie
		get_tree().paused = false
	else:
		show() # Pokazuje menu + zaciemnienie
		get_tree().paused = true

func _continue_pressed():
	_toggle_pause()
	
func _settings_pressed():
	# Zakładam, że masz przycisk Settings, ale nie podłączyłeś sygnału w _ready
	print("settings")
	
func _main_menu_pressed():
	# Zawsze wyłączaj pauzę przed zmianą sceny, 
	# inaczej nowa scena może wystartować spauzowana!
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")
