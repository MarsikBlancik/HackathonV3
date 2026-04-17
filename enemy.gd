extends Node2D

@export var speed: float = 120.0
@export var stop_distance: float = 50.0 

# --- USTAWIENIA ATAKU ---
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0 # Czas między atakami w sekundach

# --- STATYSTYKI PRZECIWNIKA ---
@export var hp: int = 3 # Ilość trafień potrzebnych do zabicia wroga

var player: Node2D = null
var time_since_last_attack: float = 0.0 # Licznik czasu

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
	if player == null:
		print("Błąd: Przeciwnik nie znalazł gracza na mapie!")

func _process(delta: float) -> void:
	if is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# 1. Poruszanie się (jeśli jest za daleko)
		if distance_to_player > stop_distance:
			var direction = (player.global_position - global_position).normalized()
			global_position += direction * speed * delta
			
		# 2. Atakowanie
		# Dodajemy czas, który upłynął od ostatniej klatki (delta) do naszego licznika
		time_since_last_attack += delta
		
		# Sprawdzamy, czy przeciwnik jest wystarczająco blisko gracza
		# (dodajemy mały bufor 5 pikseli, aby na pewno załapał zasięg, gdy się zatrzyma)
		if distance_to_player <= stop_distance + 5.0:
			# Sprawdzamy, czy minął już czas odnowienia (cooldown)
			if time_since_last_attack >= attack_cooldown:
				perform_attack()

func perform_attack() -> void:
	print("Przeciwnik: Uderzam gracza!")
	
	# Bezpiecznie sprawdzamy, czy obiekt gracza posiada funkcję "modify_hp"
	if player.has_method("modify_hp"):
		# Wywołujemy funkcję gracza, podając wartość obrażeń na minusie
		player.modify_hp(-attack_damage)
		
	# Zerujemy licznik czasu, żeby przeciwnik musiał znów poczekać na kolejny atak
	time_since_last_attack = 0.0

# --- NOWA FUNKCJA: OTRZYMYWANIE OBRAŻEŃ ---
func take_damage(amount: int) -> void:
	hp -= amount
	print("Przeciwnik dostał! Zostało mu ", hp, " HP.")
	
	# Opcjonalnie: Zmiana koloru na ułamek sekundy (efekt trafienia)
	modulate = Color(5.0, 5.0, 5.0) # Rozbłyśnięcie
	get_tree().create_timer(0.1).timeout.connect(func(): modulate = Color.WHITE)
	
	if hp <= 0:
		die()

func die() -> void:
	print("Przeciwnik pokonany!")
	queue_free() # Usuwa przeciwnika ze sceny
