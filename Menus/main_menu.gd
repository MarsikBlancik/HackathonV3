extends Control


func _ready() -> void:
	var BtnPlay = $VBoxContainer/Play
	var BtnSettings = $VBoxContainer/Settings
	var BtnQuit = $VBoxContainer/Quit
	
	BtnPlay.pressed.connect(_play_pressed)
	BtnSettings.pressed.connect(_settings_pressed)
	BtnQuit.pressed.connect(_quit_pressed)
	

func _play_pressed():
	get_tree().change_scene_to_file("res://MainScene/MainScene.tscn")
	
func _settings_pressed():
	print("settings")
	
func _quit_pressed():
	get_tree().quit()
