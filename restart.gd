extends Control

@export var defeat_music: AudioStream # <--- NOWE: Muzyka porażki do przypisania w Inspektorze
var music_player: AudioStreamPlayer # <--- NOWE: Odtwarzacz muzyki

func _ready() -> void:
	# --- NOWE: Konfiguracja i odtwarzanie muzyki ---
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	if defeat_music:
		music_player.stream = defeat_music
		music_player.play()
	# -----------------------------------------------

	var BtnRestart = $VBoxContainer/Restart
	var BtnMainMenu = $VBoxContainer/MainMenu
	
	BtnRestart.pressed.connect(_restart_pressed)
	BtnMainMenu.pressed.connect(_main_menu_pressed)
	
func _restart_pressed():
	get_tree().change_scene_to_file("res://MainScene/MainScene.tscn")
	
func _main_menu_pressed():
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")
