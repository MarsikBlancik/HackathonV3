extends CanvasLayer

# Referencje do pasków postępu
@onready var hp_bar = $HPBar
@onready var energy_bar = $EnergyBar
@onready var xp_bar = $XPBar

# Referencje do tekstów
@onready var hp_label = get_node_or_null("HPLabel")
@onready var energy_label = get_node_or_null("EnergyLabel")
@onready var level_label = find_child("LevelLabel", true, false)
@onready var coin_label = get_node_or_null("CoinLabel") # <--- NOWE: Referencja do labela monet

func _ready():
	var player = get_tree().get_first_node_in_group("Player") 
	
	if player:
		# Łączymy istniejące sygnały
		player.hp_changed.connect(update_hp)
		player.energy_changed.connect(update_energy)
		player.xp_changed.connect(update_xp)
		
		# Łączymy sygnał monet (dodany w poprzednim kroku do player.gd)
		if player.has_signal("coins_changed"):
			player.coins_changed.connect(update_coins)
		
		if player.has_signal("leveled_up"):
			player.leveled_up.connect(update_level)
		
		print("UI: Pomyślnie podłączono do Gracza!")
		
		# Ustawiamy wartości startowe
		update_hp(player.current_hp, player.max_hp)
		update_energy(player.current_energy, player.max_energy)
		update_xp(player.current_xp, player.xp_to_next_level)
		update_level(player.level)
		
		# Inicjalizacja liczby monet (zakładając, że gracz ma zmienną 'coins')
		if "coins" in player:
			update_coins(player.coins)
			
	else:
		print("UI BŁĄD: Nie znaleziono Gracza w grupie 'Player'!")

# --- FUNKCJE AKTUALIZUJĄCE ---

# NOWE: Funkcja aktualizująca tekst monet
func update_coins(amount: int) -> void:
	if coin_label:
		coin_label.text = "Monety: " + str(amount)

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

func update_level(level: int) -> void:
	if level_label:
		level_label.text = "Poziom: " + str(level)
