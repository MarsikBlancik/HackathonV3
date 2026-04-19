extends CanvasLayer

# --- ISTNIEJĄCE REFERENCJE ---
@onready var hp_bar = $HPBar
@onready var energy_bar = $EnergyBar
@onready var xp_bar = $XPBar

@onready var hp_label = get_node_or_null("HPLabel")
@onready var energy_label = get_node_or_null("EnergyLabel")
@onready var level_label = find_child("LevelLabel", true, false)
@onready var coin_label = get_node_or_null("CoinLabel")

# --- NOWE: REFERENCJE DLA BOSSA ---
# Upewnij się, że w scenie UI masz TextureProgressBar o nazwie BossHealthBar
@onready var boss_bar = get_node_or_null("BossHealthBar") 
var active_boss = null

func _ready():
	# Ukrywamy pasek bossa na starcie
	if boss_bar:
		boss_bar.hide()

	var player = get_tree().get_first_node_in_group("Player") 
	
	if player:
		player.hp_changed.connect(update_hp)
		player.energy_changed.connect(update_energy)
		player.xp_changed.connect(update_xp)
		
		if player.has_signal("coins_changed"):
			player.coins_changed.connect(update_coins)
		
		if player.has_signal("leveled_up"):
			player.leveled_up.connect(update_level)
		
		print("UI: Pomyślnie podłączono do Gracza!")
		
		update_hp(player.current_hp, player.max_hp)
		update_energy(player.current_energy, player.max_energy)
		update_xp(player.current_xp, player.xp_to_next_level)
		update_level(player.level)
		
		if "coins" in player:
			update_coins(player.coins)
	else:
		print("UI BŁĄD: Nie znaleziono Gracza w grupie 'Player'!")

# --- NOWE: LOGIKA BOSSA ---

# Ta funkcja zostanie wywołana przez sygnał z Twojego skryptu Node2D (Mapy)
func _on_boss_spawned(boss_node: Node2D) -> void:
	if boss_bar and boss_node:
		active_boss = boss_node
		
		# Inicjalizacja paska statystykami bossa
		# Zakładamy, że boss ma zmienne 'health' i 'max_health'
		boss_bar.max_value = boss_node.max_health
		boss_bar.value = boss_node.health
		
		boss_bar.show()
		print("UI: Boss wykryty, pasek zdrowia aktywny!")

func _process(_delta: float) -> void:
	# Aktualizacja paska zdrowia bossa w czasie rzeczywistym
	if is_instance_valid(active_boss) and boss_bar:
		boss_bar.value = active_boss.health
	elif boss_bar and boss_bar.visible:
		# Jeśli boss zniknął (zginął), chowamy pasek
		boss_bar.hide()
		active_boss = null

# --- ISTNIEJĄCE FUNKCJE AKTUALIZUJĄCE ---

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
