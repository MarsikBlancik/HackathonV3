extends Control

# --- Stałe i zmienne konfiguracyjne ---
const GUN_HOLE_TEX = preload("res://Menus/GunHole.png")

@export var hole_scale: float = 0.1
@export var shoot_sound: AudioStream 

# ZMIANA: Zmienna na plik z muzyką w tle
@export var bgm_sound: AudioStream 

@onready var btn_play: Button = $VBoxContainer/Play
@onready var btn_quit: Button = $VBoxContainer/Quit

var audio_player: AudioStreamPlayer
# ZMIANA: Referencja do odtwarzacza muzyki
var bgm_player: AudioStreamPlayer 

func _ready() -> void:
	btn_play.pressed.connect(_play_pressed)
	btn_quit.pressed.connect(_quit_pressed)
	
	# Tworzymy i konfigurujemy odtwarzacz dźwięku strzału
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = shoot_sound
	add_child(audio_player)

	# ZMIANA: Tworzymy i uruchamiamy muzykę w tle
	if bgm_sound != null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.stream = bgm_sound
		# Możesz tu zmniejszyć głośność muzyki, jeśli jest za głośna, odkomentowując linię niżej:
		# bgm_player.volume_db = -10.0 
		add_child(bgm_player)
		bgm_player.play() # Odpalamy muzykę od razu po załadowaniu menu

func _spawn_effects():
	# Funkcja tylko tworzy efekt wizualny
	var hole = Sprite2D.new()
	hole.texture = GUN_HOLE_TEX
	hole.global_position = get_global_mouse_position()
	hole.scale = Vector2(hole_scale, hole_scale)
	add_child(hole)

func _play_pressed():
	# 1. Wyłączamy przycisk, żeby gracz nie kliknął dwa razy
	btn_play.disabled = true
	
	# Odtwarzamy dźwięk strzału
	if audio_player.stream != null:
		audio_player.play()
	
	# 2. Tworzymy dziurę po kuli
	_spawn_effects()
	
	# 3. Czekamy ułamek sekundy, aby gracz nacieszył się efektem (i dźwięk zdążył wybrzmieć)
	await get_tree().create_timer(0.3).timeout
	
	# 4. Zmieniamy scenę
	get_tree().change_scene_to_file("res://MainScene/MainScene.tscn")
	
func _settings_pressed():
	# Tu nie zmieniamy sceny, więc nie musimy czekać
	_spawn_effects()
	print("settings")
	
func _quit_pressed():
	# Wyłączamy przycisk, żeby zapobiec spamowaniu
	btn_quit.disabled = true
	
	if audio_player.stream != null:
		audio_player.play()
	
	_spawn_effects()
	
	# Podobnie jak przy Play, dajemy grze chwilę na wyświetlenie dziury
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
