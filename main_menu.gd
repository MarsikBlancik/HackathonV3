extends Control

# --- Stałe i zmienne konfiguracyjne ---
# Ładujemy teksturę dziury raz
const GUN_HOLE_TEX = preload("res://Menus/GunHole.png")

# Opcja pozwalająca łatwo edytować rozmiar dziury z poziomu Inspektora
# Ustawienie 2.0 to 200% rozmiaru, 0.5 to 50%
@export var hole_scale: float = 0.1

# Referencje do węzłów
@onready var btn_play: Button = $VBoxContainer/Play
@onready var btn_settings: Button = $VBoxContainer/Settings
@onready var btn_quit: Button = $VBoxContainer/Quit
# Węzeł ColorRect odpowiedzialny za ściemnianie (pamiętaj, aby go stworzyć!)
@onready var screen_fade: ColorRect = $CanvasLayer/ScreenFade 

func _ready() -> void:
	# Podpinamy sygnały logiki
	btn_play.pressed.connect(_play_pressed)
	btn_settings.pressed.connect(_settings_pressed)
	btn_quit.pressed.connect(_quit_pressed)
	
	# Podpinamy uniwersalną funkcję efektu (strzał) pod każdy przycisk
	# Używamy connect.bind, żeby móc łatwiej kontrolować logikę w przyszłości
	btn_play.pressed.connect(_spawn_effects)
	btn_settings.pressed.connect(_spawn_effects)
	btn_quit.pressed.connect(_spawn_effects)

func _spawn_effects():
	# 1. Tworzymy Sprite dziury po pocisku
	var hole = Sprite2D.new()
	hole.texture = GUN_HOLE_TEX
	hole.global_position = get_global_mouse_position()
	
	# Ustawiamy rozmiar dziury na podstawie zmiennej hole_scale
	hole.scale = Vector2(hole_scale, hole_scale)
	
	add_child(hole)
	
	# 2. Tworzymy efekt cząsteczek (iskry)
	# (Założyłem, że masz ParticleProcessMaterial)
	var particles = GPUParticles2D.new()
	# particles.process_material = load("res://Menus/SparkMaterial.tres")
	particles.global_position = get_global_mouse_position()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.scale = Vector2(1, 1) # Domyślnie zmniejszamy particles, jeśli są za duże
	add_child(particles)
	
	# 3. Usuwanie particles po czasie
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func _play_pressed():
<<<<<<< Updated upstream:main_menu.gd
	get_tree().change_scene_to_file("res://MainScene.tscn")
=======
	# Wyłączamy przyciski, żeby gracz nie kliknął dwa razy podczas fade'u
	btn_play.disabled = true
	
	# Tworzymy Tween do animacji fade-out
	var tween = get_tree().create_tween()
	# Ustawiamy przezroczystość (property "modulate:a") ColorRect z 0.0 na 1.0
	# Trwa to 0.6 sekundy. Używamy płynnego przejścia.
	tween.tween_property(screen_fade, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Po zakończeniu animacji (tween_all_completed), zmieniamy scenę
	tween.finished.connect(_change_to_main_scene)
	
func _change_to_main_scene():
	get_tree().change_scene_to_file("res://MainScene/MainScene.tscn")
>>>>>>> Stashed changes:Menus/main_menu.gd
	
func _settings_pressed():
	print("settings")
	
func _quit_pressed():
	get_tree().quit()
