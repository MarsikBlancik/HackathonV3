extends Control


func _ready() -> void:
	var BtnRestart = $VBoxContainer/Restart
	var BtnMainMenu = $VBoxContainer/MainMenu
	
	BtnRestart.pressed.connect(_restart_pressed)
	BtnMainMenu.pressed.connect(_main_menu_pressed)
	
func _restart_pressed():
	get_tree().change_scene_to_file("res://MainScene/MainScene.tscn")
	
func _main_menu_pressed():
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")
