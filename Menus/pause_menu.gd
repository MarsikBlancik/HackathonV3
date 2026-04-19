extends Control

func _ready() -> void:
	hide()
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var btnContinue = $VBoxContainer/Continue
	var btnSettins = $VBoxContainer/Settings
	var btnMainMenu = $VBoxContainer/MainMenu
	
	btnContinue.pressed.connect(_continue_pressed)
	btnSettins.pressed.connect(_settings_pressed)
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
		
		_on_pause_pressed()

func _on_pause_pressed():
	if is_visible_in_tree():
		hide()
		get_tree().paused = false
	else:
		show()
		get_tree().paused = true

func _continue_pressed():
	_on_pause_pressed()
	
func _settings_pressed():
	print("settings")
	
func _main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")
