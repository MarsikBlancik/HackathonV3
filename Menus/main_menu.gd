extends Control

# --- Stałe i zmienne konfiguracyjne ---
const GUN_HOLE_TEX = preload("res://Menus/GunHole.png")
const GATE_TEX = preload("res://Menus/Gate.png") 

@export_group("Efekty Strzału")
@export var hole_scale: float = 0.1
@export var shoot_sound: AudioStream 

@export_group("Muzyka")
@export var bgm_sound: AudioStream 

# --- NOWE: ROZMIAR BRAMY W PIKSELACH ---
@export_group("Animacja Bramy")
@export var gate_size_pixels: Vector2 = Vector2(1920, 1080) # <--- TU USTAWISZ ROZMIAR
@export var gate_fall_time: float = 1.0
@export var post_fall_delay: float = 0.2
@export var shake_intensity: float = 4.0
@export var shake_speed: float = 60.0

@onready var btn_play: Button = $VBoxContainer/Play
@onready var btn_quit: Button = $VBoxContainer/Quit

var audio_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer 

var is_gate_falling: bool = false
var original_menu_position: Vector2

func _ready() -> void:
	original_menu_position = position
	
	btn_play.pressed.connect(_play_pressed)
	if $VBoxContainer.has_node("Settings"):
		$VBoxContainer/Settings.pressed.connect(_settings_pressed)
	btn_quit.pressed.connect(_quit_pressed)
	
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = shoot_sound
	add_child(audio_player)

	if bgm_sound != null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.stream = bgm_sound
		add_child(bgm_player)
		bgm_player.play()

func _process(delta: float) -> void:
	if is_gate_falling:
		var current_time = Time.get_ticks_msec() / 1000.0
		position.x = original_menu_position.x + sin(current_time * shake_speed) * shake_intensity
		position.y = original_menu_position.y + cos(current_time * shake_speed * 1.1) * shake_intensity * 0.5
	else:
		position = original_menu_position

func _spawn_effects():
	var hole = Sprite2D.new()
	hole.texture = GUN_HOLE_TEX
	hole.global_position = get_global_mouse_position()
	hole.scale = Vector2(hole_scale, hole_scale)
	add_child(hole)

func _play_pressed():
	btn_play.disabled = true
	btn_quit.disabled = true
	
	if audio_player.stream != null:
		audio_player.play()
	
	_spawn_effects()
	
	# --- TWORZENIE BRAMY JAKO TEXTURERECT (Łatwiejsza kontrola rozmiaru) ---
	var gate = TextureRect.new()
	gate.texture = GATE_TEX
	
	# Pozwala na dowolne skalowanie tekstury bez zachowania proporcji oryginału
	gate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE 
	gate.stretch_mode = TextureRect.STRETCH_SCALE
	
	# Ustawiamy rozmiar w pikselach z zmiennej @export
	gate.size = gate_size_pixels
	
	# Ustawiamy punkt obrotu/skalowania na środek dla łatwiejszego pozycjonowania
	gate.pivot_offset = gate.size / 2
	
	# Brama nad wszystkim
	gate.z_index = 100
	add_child(gate)
	
	var screen_size = get_viewport_rect().size
	
	# Pozycjonowanie poziome (środek ekranu)
	gate.global_position.x = (screen_size.x - gate.size.x) / 2
	
	# Pozycja startowa: nad ekranem
	var start_y = -gate.size.y
	# Pozycja docelowa: środek ekranu (w pionie)
	var target_y = (screen_size.y - gate.size.y) / 2
	
	gate.global_position.y = start_y
	
	# --- ANIMACJA ---
	is_gate_falling = true
	var tween = create_tween()
	
	# Animujemy opadanie bramy do środka ekranu
	tween.tween_property(gate, "global_position:y", target_y, gate_fall_time)\
		.set_trans(Tween.TRANS_QUART)\
		.set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	is_gate_falling = false
	position = original_menu_position
	
	await get_tree().create_timer(post_fall_delay).timeout
	get_tree().change_scene_to_file("res://MainScene/MainScene.tscn")

func _settings_pressed():
	_spawn_effects()
	
func _quit_pressed():
	btn_quit.disabled = true
	if audio_player.stream != null:
		audio_player.play()
	_spawn_effects()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
