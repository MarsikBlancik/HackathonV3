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
	get_tree().change_scene_to_file("res://main_menu.tscn")
