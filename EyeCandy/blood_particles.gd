extends CPUParticles2D

func _ready() -> void:
	# Odpalamy cząsteczki od razu po pojawieniu się na mapie
	emitting = true
	
	# Godot 4 ma wbudowany sygnał "finished", który wysyła się, gdy cząsteczki znikną.
	# Łączymy go od razu z funkcją queue_free, która niszczy obiekt.
	finished.connect(queue_free)
