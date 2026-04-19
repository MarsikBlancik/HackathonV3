extends Area2D

@onready var prompt = $InteractPrompt
@onready var shop_ui = $ShopUI
@onready var button1 = $ShopUI/Panel/HBoxContainer/Button1
@onready var button2 = $ShopUI/Panel/HBoxContainer/Button2
@onready var button3 = $ShopUI/Panel/HBoxContainer/Button3

var player_in_range: bool = false

func _ready() -> void:
	# --- NOWOŚĆ: Sklep przypisuje się do grupy z poziomu kodu ---
	add_to_group("Shop")
	
	prompt.hide()
	shop_ui.hide()
	
	# Podłączamy sygnały
	button1.pressed.connect(_on_button1_pressed)
	button2.pressed.connect(_on_button2_pressed)
	button3.pressed.connect(_on_button3_pressed)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		prompt.hide()
		# Jeśli gracz odejdzie, upewniamy się, że gra jest odpauzowana i zamykamy menu
		if shop_ui.visible:
			close_shop()

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		toggle_shop()

func toggle_shop() -> void:
	if shop_ui.visible:
		close_shop()
	else:
		open_shop()

func open_shop() -> void:
	shop_ui.show()
	prompt.hide()
	get_tree().paused = true # PAUZA GRY
	print("Sklep otwarty - gra zapauzowana")

func close_shop() -> void:
	shop_ui.hide()
	get_tree().paused = false # WZNOWIENIE GRY
	if player_in_range:
		prompt.show()
	print("Sklep zamknięty - gra wznowiona")

# --- FUNKCJA NISZCZĄCA SKLEP ---
func destroy_shop() -> void:
	get_tree().paused = false # Najpierw odpauzuj grę!
	queue_free() # Kurwa usuwamy go

# --- LOGIKA PRZYCISKÓW ---

func _on_button1_pressed() -> void:
	print("Wybrano opcję 1. Sklep zostaje usunięty!")
	destroy_shop()

func _on_button2_pressed() -> void:
	print("Wybrano opcję 2. Sklep zostaje usunięty!")
	destroy_shop()

func _on_button3_pressed() -> void:
	print("Wybrano opcję 3. Sklep zostaje usunięty!")
	destroy_shop()
