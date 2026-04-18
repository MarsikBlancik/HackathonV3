extends CanvasLayer

@onready var hp_bar = $HPBar
@onready var energy_bar = $EnergyBar

# Pobieramy referencje do naszych nowych tekstów (upewnij się, że nazwy się zgadzają!)
@onready var hp_label
@onready var energy_label

func _ready() -> void:
	# Czekamy jedną klatkę, żeby upewnić się, że Player zdążył załadować się do gry
	await get_tree().process_frame
	
	# Szukamy jedynego węzła w grupie "Player"
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		# Podpinamy sygnały BEZPOŚREDNIO pod gracza
		player.hp_changed.connect(update_hp)
		player.energy_changed.connect(update_energy)
		
		# Wymuszamy pierwszą aktualizację pasków
		update_hp(player.current_hp, player.max_hp)
		update_energy(player.current_energy, player.max_energy)
		print("UI: Pomyślnie podłączono do Gracza!")
	else:
		print("BŁĄD: UI nie znalazło Gracza. Upewnij się, że masz gracza na scenie!")

# Funkcje odbierające sygnał
func update_hp(current: int, max_val: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current
	
	# Aktualizujemy tekst na pasku
	if hp_label:
		hp_label.text = str(current) + " / " + str(max_val)

func update_energy(current: int, max_val: int) -> void:
	if energy_bar:
		energy_bar.max_value = max_val
		energy_bar.value = current
		
	# Aktualizujemy tekst na pasku (np. "3 / 3")
	if energy_label:
		energy_label.text = str(current) + " / " + str(max_val)
func update_xp(current_xp: int, max_xp: int) -> void:
	# Zakładając, że Twój pasek nazywa się XPBar
	if has_node("XPBar"):
		$XPBar.max_value = max_xp
		$XPBar.value = current_xp
