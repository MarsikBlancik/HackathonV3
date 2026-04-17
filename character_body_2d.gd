extends CharacterBody2D

@export var speed: float = 100.0
@export var damage: int = 10

var player: Node2D = null

func _physics_process(_delta):
	# Krok 1: Szukanie gracza
	if not is_instance_valid(player):
		var players_in_scene = get_tree().get_nodes_in_group("player")
		if players_in_scene.size() > 0:
			player = players_in_scene[0]
			print("SUKCES: Znalazłem gracza! Zaczynam pościg.")
		else:
			print("BŁĄD: Nie widzę gracza! Szukam w grupie 'player'...")
			return 

	# Krok 2: Pościg
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
