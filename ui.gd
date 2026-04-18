extends CanvasLayer

# Referencje do pasków postępu
@onready var hp_bar = $HPBar
@onready var energy_bar = $EnergyBar
@onready var xp_bar = $XPBar

# Referencje do tekstów (Upewnij się, że masz takie nazwy w drzewie UI!)
@onready var hp_label = get_node_or_null("HPLabel")
@onready var energy_label = get_node_or_null("EnergyLabel")
@onready var level_label = find_child("LevelLabel", true, false)

func _ready():
	# Szukamy gracza w grupie "Player" (najbezpieczniejsza metoda)
	var player = get_tree().get_first_node_in_group("Player") 
	
	if player:
		# Łączymy wszystkie sygnały
		player.hp_changed.connect(update_hp)
		player.energy_changed.connect(update_energy)
		player.xp_changed.connect(update_xp)
		
		# POPRAWKA: Zmiana "level_changed" na "leveled_up" zgodnie z player.gd!
		if player.has_signal("leveled_up"):
			player.leveled_up.connect(update_level)
		
		print("UI: Pomyślnie podłączono do Gracza!")
		
		# Ustawiamy wartości startowe, żeby UI nie było puste na początku
		update_hp(player.current_hp, player.max_hp)
		update_energy(player.current_energy, player.max_energy)
		update_xp(player.current_xp, player.xp_to_next_level)
		update_level(player.level)
	else:
		print("UI BŁĄD: Nie znaleziono Gracza w grupie 'Player'!")

# --- FUNKCJE AKTUALIZUJĄCE ---

func update_hp(current: int, max_val: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current
	if hp_label:
		hp_label.text = str(current) + " / " + str(max_val)

func update_energy(current: int, max_val: int) -> void:
	if energy_bar:
		energy_bar.max_value = max_val
		energy_bar.value = current
	if energy_label:
		energy_label.text = str(current) + " / " + str(max_val)

func update_xp(current_xp: int, max_xp: int) -> void:
	if xp_bar:
		xp_bar.max_value = max_xp
		xp_bar.value = current_xp
		# Opcjonalnie: print("UI: XP zaktualizowane")

func update_level(level: int) -> void:
	if level_label:
		level_label.text = "Poziom: " + str(level)
