extends Area2D

@onready var prompt = $InteractPrompt
@onready var shop_ui = $ShopUI
@onready var button1 = $ShopUI/Panel/HBoxContainer/Button1
@onready var button2 = $ShopUI/Panel/HBoxContainer/Button2
@onready var button3 = $ShopUI/Panel/HBoxContainer/Button3
@onready var exit_button = $ShopUI/Panel/HBoxContainer/Button4 # <--- Przycisk wyjścia
@onready var reroll_button = $ShopUI/Panel/HBoxContainer/Button5 # <--- Referencja do przycisku


var base_reroll_price: int = 2 # Startowa cena po darmowych próbach

var player_node: Node2D = null
var player_in_range: bool = false

# --- PULA ULEPSZEŃ ---
# Struktura: "klucz": {"name": Nazwa, "boosts": [Tier1, Tier2, Tier3], "base_price": Cena bazowa}
var upgrade_pool = {
	"base_damage": {"name": "Siła Ciosu", "boosts": [2, 5, 10], "base_price": 10},
	"crit_chance": {"name": "Szansa na Krytyk", "boosts": [0.05, 0.10, 0.20], "base_price": 8},
	"crit_multiplier": {"name": "Moc Krytyka", "boosts": [0.5, 1.0, 2.0], "base_price": 8},
	"dash_distance": {"name": "Zasięg Uniku", "boosts": [30.0, 60.0, 100.0], "base_price": 5},
	"max_hp": {"name": "Max Zdrowie", "boosts": [1, 3, 5], "base_price": 6},
	"speed": {"name": "Prędkość Ruchu", "boosts": [15.0, 30.0, 50.0], "base_price": 5},
	"attack_cooldown": {"name": "Szybkość Ataku", "boosts": [0.05, 0.1, 0.2], "base_price": 10},
	"max_energy": {"name": "Max Energia (Dashe)", "boosts": [1, 2, 3], "base_price": 7}
}

var current_offers = [] # Tu będziemy trzymać aktualnie wylosowane przedmioty

func _ready() -> void:
	exit_button.text = "Wyjdź \n (za darmo)"
	prompt.hide()
	shop_ui.hide()
	
	# Podłączenie sygnałów
	button1.pressed.connect(_on_button1_pressed)
	button2.pressed.connect(_on_button2_pressed)
	button3.pressed.connect(_on_button3_pressed)
	exit_button.pressed.connect(_on_button4_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("spend_coins"):
			player_node = body
		elif body.get_parent() != null and body.get_parent().has_method("spend_coins"):
			player_node = body.get_parent()
			
		if player_node != null:
			player_in_range = true
			prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		player_node = null
		prompt.hide()
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
	update_reroll_button_text()
	roll_shop_items() # Losujemy przedmioty przed pokazaniem UI!
	shop_ui.show()
	prompt.hide()
	get_tree().paused = true
	print("Sklep otwarty - gra zapauzowana")

func close_shop() -> void:
	shop_ui.hide()
	get_tree().paused = false
	if player_in_range:
		prompt.show()
	print("Sklep zamknięty - gra wznowiona")

func destroy_shop() -> void:
	get_tree().paused = false 
	queue_free() # Kurwa usuwamy go

# --- SYSTEM LOSOWANIA I TIERÓW ---
# --- SYSTEM LOSOWANIA I TIERÓW ---
func roll_shop_items() -> void:
	current_offers.clear()
	var keys = upgrade_pool.keys()
	keys.shuffle() # Mieszamy dostępną pulę
	
	for i in range(3):
		var stat_key = keys[i]
		var stat_data = upgrade_pool[stat_key]
		
		# Sprawdzamy, ile razy gracz już to kupił
		var current_level = 0
		if player_node and "purchased_upgrades" in player_node:
			current_level = player_node.purchased_upgrades.get(stat_key, 0)
		
		# Losowanie jakości (Tier 1-3)
		var r = randf()
		var tier = 1
		if r < 0.05: tier = 3
		elif r < 0.30: tier = 2
		
		var boost = stat_data["boosts"][tier-1]
		
		# --- NOWY SYSTEM CEN (INFLACJA) ---
		# Każdy poprzedni zakup tej statystyki podnosi jej cenę o 40% (0.4)
		var inflation_multiplier = 1.0 + (current_level * 0.4)
		var price = int(stat_data["base_price"] * tier * inflation_multiplier * randf_range(0.8, 1.2)) 
		
		if price < 1: price = 1 
		
		current_offers.append({
			"key": stat_key,
			"name": stat_data["name"],
			"tier": tier,
			"boost": boost,
			"price": price
		})
	
	update_buttons_ui()

func update_buttons_ui() -> void:
	var buttons = [button1, button2, button3]
	
	for i in range(3):
		var offer = current_offers[i]
		var tier_text = "⭐".repeat(offer.tier) # Gwiazdki zależne od tieru
		
		# Ładne formatowanie boosta (żeby +0.05 wyświetlało się jako +5%)
		var boost_display = str(offer.boost)
		if offer.key in ["crit_chance"]:
			boost_display = str(offer.boost * 100) + "%"
		elif offer.key in ["attack_cooldown"]:
			boost_display = "-" + str(offer.boost) + "s" # Na minus, bo to cooldown
		else:
			boost_display = "+" + boost_display
			
		buttons[i].text = "%s %s\n%s\n(%s monet)" % [offer.name, tier_text, boost_display, offer.price]

# --- LOGIKA ZAKUPÓW ---

func try_buy(index: int) -> void:
	if current_offers.size() <= index: return
	var offer = current_offers[index]
	
	if player_node and player_node.spend_coins(offer.price):
		apply_upgrade(offer)
		destroy_shop()
	else:
		print("Brak kasy na: ", offer.name)

func apply_upgrade(offer: Dictionary) -> void:
	# Zapisujemy w pamięci gracza, że kupił to ulepszenie (+1 do licznika)
	if player_node and "purchased_upgrades" in player_node:
		var current_count = player_node.purchased_upgrades.get(offer.key, 0)
		player_node.purchased_upgrades[offer.key] = current_count + 1

	# Aplikujemy statystyki
	match offer.key:
		"base_damage": player_node.base_damage += offer.boost
		"crit_chance": player_node.crit_chance += offer.boost
		"crit_multiplier": player_node.crit_multiplier += offer.boost
		"dash_distance": player_node.dash_distance += offer.boost
		"max_hp": player_node.upgrade_max_hp(offer.boost)
		"speed": player_node.upgrade_speed(offer.boost)
		"attack_cooldown": player_node.upgrade_attack_speed(offer.boost)
		"max_energy": player_node.upgrade_max_energy(offer.boost)

func _on_button1_pressed() -> void:
	try_buy(0)

func _on_button2_pressed() -> void:
	try_buy(1)

func _on_button3_pressed() -> void:
	try_buy(2)

func _on_button4_pressed() -> void:
	close_shop()

# Funkcja obliczająca aktualny koszt odświeżenia
func get_reroll_price() -> int:
	# Odczytujemy licznik bezpośrednio z gracza
	var global_rerolls = 0
	if player_node:
		global_rerolls = player_node.shop_reroll_count
		
	if global_rerolls < 2:
		return 0
	return base_reroll_price + (global_rerolls - 2) * 2

func update_reroll_button_text() -> void:
	var price = get_reroll_price()
	var global_rerolls = 0
	if player_node:
		global_rerolls = player_node.shop_reroll_count

	if price == 0:
		# Pokazujemy postęp darmowych rzutów (np. 1/2, 2/2)
		reroll_button.text = "Odśwież\n(Darmowe: %d/2)" % [global_rerolls + 1]
	else:
		reroll_button.text = "Odśwież\n(%d monet)" % [price]

func _on_reroll_pressed() -> void:
	var price = get_reroll_price()
	
	# Jeśli cena > 0, sprawdzamy portfel gracza
	if price > 0:
		if player_node and player_node.spend_coins(price):
			execute_reroll()
		else:
			print("Brak monet na odświeżenie!")
	else:
		# Darmowe odświeżenie
		execute_reroll()

func execute_reroll() -> void:
	# Zwiększamy licznik u gracza, a nie w sklepie!
	if player_node:
		player_node.shop_reroll_count += 1
		
	roll_shop_items()
	update_reroll_button_text()
