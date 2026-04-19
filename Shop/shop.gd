extends Area2D

@onready var prompt = $InteractPrompt


@onready var shop_ui = $ShopUI


@onready var coin_label = $ShopUI/Panel/CoinLabel



# --- ZAKTUALIZOWANE ŚCIEŻKI DO PRZYCISKÓW ---


@onready var button1 = $ShopUI/Panel/VBoxContainer/UpgradesRow/Button1


@onready var button2 = $ShopUI/Panel/VBoxContainer/UpgradesRow/Button2


@onready var button3 = $ShopUI/Panel/VBoxContainer/UpgradesRow/Button3



@onready var exit_button = $ShopUI/Panel/VBoxContainer/ActionsRow/Button4 


@onready var reroll_button = $ShopUI/Panel/VBoxContainer/ActionsRow/Button5



# --- ŚCIEŻKI DO KONTENERÓW ---


@onready var upgrades_row = $ShopUI/Panel/VBoxContainer/UpgradesRow


@onready var actions_row = $ShopUI/Panel/VBoxContainer/ActionsRow



# --- ZAŁADOWANIE ZASOBÓW DO WYGLĄDU ---


const SCHLOP_FONT = preload("res://shlop rg.otf")


const TABLICZKA_TEX = preload("res://Tabliczka.png")



var player_node: Node2D = null


var player_in_range: bool = false


var base_reroll_price: int = 2 



# --- PULA ULEPSZEŃ ---


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



var current_offers = [] 



func _ready() -> void:


	prompt.hide()


	shop_ui.hide()


	exit_button.text = "Wyjdź\n(Za darmo)"


	


	# Aplikujemy wygląd dla przycisków


	setup_button_styles()


	


	button1.pressed.connect(_on_button1_pressed)


	button2.pressed.connect(_on_button2_pressed)


	button3.pressed.connect(_on_button3_pressed)


	exit_button.pressed.connect(_on_button4_pressed)


	reroll_button.pressed.connect(_on_reroll_pressed)



# --- POPRAWIONA FUNKCJA DO STYLIZOWANIA PRZYCISKÓW ---


func setup_button_styles() -> void:


	# 1. Marginesy zewnętrzne (odstęp MIĘDZY przyciskami w rzędzie poziomo)


	upgrades_row.add_theme_constant_override("separation", 40)


	actions_row.add_theme_constant_override("separation", 40)


	


	# 2. Przygotowanie stylu tła kafelka


	var tabliczka_style = StyleBoxTexture.new()


	tabliczka_style.texture = TABLICZKA_TEX


	tabliczka_style.texture_margin_top = 20


	tabliczka_style.texture_margin_bottom = 20


	tabliczka_style.texture_margin_left = 15


	tabliczka_style.texture_margin_right = 15


	


	# Podział przycisków na odpowiednie grupy


	var upgrade_buttons = [button1, button2, button3]


	var action_buttons = [exit_button, reroll_button] # Przyciski dolne (bez tabliczek)


	var all_buttons = [button1, button2, button3, exit_button, reroll_button]


	


	# 3. Nakładamy TABLICZKĘ i wymiary TYLKO na 3 główne przyciski ulepszeń


	for btn in upgrade_buttons:


		btn.custom_minimum_size = Vector2(400, 600) 


		btn.add_theme_stylebox_override("normal", tabliczka_style)


		btn.add_theme_stylebox_override("hover", tabliczka_style)


		btn.add_theme_stylebox_override("pressed", tabliczka_style)


		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


		


	# 4. NOWE: Tworzymy styl dla przycisków bez tabliczek, żeby miały odstęp (margines górny)


	var action_style = StyleBoxEmpty.new()


	action_style.content_margin_top = 150 # Zmień tę wartość na 100 lub 200 wg. upodobania


	


	# Nakładamy pusty styl z marginesem na przyciski Wyjdź i Odśwież


	for btn in action_buttons:


		btn.add_theme_stylebox_override("normal", action_style)


		btn.add_theme_stylebox_override("hover", action_style)


		btn.add_theme_stylebox_override("pressed", action_style)


		


	# 5. Nakładamy samą CZCIONKĘ i usuwamy systemową ramkę (focus) ze WSZYSTKICH przycisków


	for btn in all_buttons:


		btn.add_theme_font_override("font", SCHLOP_FONT)


		btn.add_theme_font_size_override("font_size", 36.7)


		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())




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


	roll_shop_items()


	update_reroll_button_text()


	update_coin_display() 


	shop_ui.show()


	prompt.hide()


	get_tree().paused = true



func close_shop() -> void:


	shop_ui.hide()


	get_tree().paused = false


	if player_in_range:


		prompt.show()



func destroy_shop() -> void:


	get_tree().paused = false 


	queue_free()



func update_coin_display() -> void:


	if player_node and coin_label:


		coin_label.text = "Twoje Monety: " + str(player_node.coins)



# --- SYSTEM LOSOWANIA I TIERÓW ---


func roll_shop_items() -> void:


	current_offers.clear()


	var keys = upgrade_pool.keys()


	keys.shuffle() 


	


	for i in range(3):


		var stat_key = keys[i]


		var stat_data = upgrade_pool[stat_key]


		


		var current_level = 0


		if player_node and "purchased_upgrades" in player_node:


			current_level = player_node.purchased_upgrades.get(stat_key, 0)


		


		var r = randf()


		var tier = 1


		if r < 0.05: tier = 3


		elif r < 0.30: tier = 2


		


		var boost = stat_data["boosts"][tier-1]


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


		var tier_text = "⭐".repeat(offer.tier) 


		


		var boost_display = str(offer.boost)


		if offer.key in ["crit_chance"]:


			boost_display = str(offer.boost * 100) + "%"


		elif offer.key in ["attack_cooldown"]:


			boost_display = "-" + str(offer.boost) + "s" 


		else:


			boost_display = "+" + boost_display


			


		buttons[i].text = "%s %s\n%s\n(%s monet)" % [offer.name, tier_text, boost_display, offer.price]



# --- LOGIKA ODŚWIEŻANIA (REROLL) ---


func get_reroll_price() -> int:


	var global_rerolls = 0


	if player_node and "shop_reroll_count" in player_node:


		global_rerolls = player_node.shop_reroll_count


		


	if global_rerolls < 2:


		return 0


	return base_reroll_price + (global_rerolls - 2) * 2



func update_reroll_button_text() -> void:


	var global_rerolls = 0


	if player_node and "shop_reroll_count" in player_node:


		global_rerolls = player_node.shop_reroll_count


	


	var price = get_reroll_price()



	if price == 0:


		reroll_button.text = "Odśwież\n(Darmowe: %d/2)" % [global_rerolls + 1]


	else:


		reroll_button.text = "Odśwież\n(%d monet)" % [price]



func _on_reroll_pressed() -> void:


	var price = get_reroll_price()


	


	if price > 0:


		if player_node and player_node.spend_coins(price):


			execute_reroll()


	else:


		execute_reroll()



func execute_reroll() -> void:


	if player_node:


		player_node.shop_reroll_count += 1


		


	roll_shop_items()


	update_reroll_button_text()


	update_coin_display()



# --- LOGIKA ZAKUPÓW ---


func try_buy(index: int) -> void:


	if current_offers.size() <= index: return


	var offer = current_offers[index]


	


	if player_node and player_node.spend_coins(offer.price):


		apply_upgrade(offer)


		update_coin_display() 


		destroy_shop()


	else:


		print("Brak kasy na: ", offer.name)



func apply_upgrade(offer: Dictionary) -> void:


	if player_node and "purchased_upgrades" in player_node:


		var current_count = player_node.purchased_upgrades.get(offer.key, 0)


		player_node.purchased_upgrades[offer.key] = current_count + 1



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
