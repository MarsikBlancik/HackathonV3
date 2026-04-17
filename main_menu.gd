extends Control


func _ready() -> void:
	var play = $VBoxContainer/Play
	var settings = $VBoxContainer/Settings
	var quit = $VBoxContainer/Quit
	
	play.pressed.connect(_play_pressed)
	settings.pressed.connect(_settings_pressed)
	quit.pressed.connect(_quit_pressed)
	

func _play_pressed():
	get_tree().change_scene_to_file("res://Player.tscn")
	
func _settings_pressed():
	print("settings")
	
func _quit_pressed():
	get_tree().quit()
