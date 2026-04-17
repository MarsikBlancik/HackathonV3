extends Node2D

func _ready() -> void:
	# 1. Losujemy, ile pikseli krwi ma wypaść z wroga (np. od 4 do 10)
	var drops_count = randi_range(4, 10)
	
	for i in range(drops_count):
		var pixel = ColorRect.new()
		
		# 2. Losowy rozmiar pojedynczego piksela (1x1, 2x2 lub 3x3)
		var size = randf_range(1.0, 3.0)
		pixel.size = Vector2(size, size)
		
		# 3. Ustawiamy ciemnoczerwony, krwisty kolor
		pixel.color = Color(0.5, 0.0, 0.0) 
		
		# 4. Losujemy pozycję (rozrzut pikseli wokół punktu centralnego)
		# Im większe liczby, tym szerzej poleci krew
		var random_x = randf_range(-15.0, 15.0)
		var random_y = randf_range(-15.0, 15.0)
		pixel.position = Vector2(random_x, random_y)
		
		# 5. Dodajemy piksel do naszej sceny
		add_child(pixel)
		
	# --- SYSTEM SPRZĄTANIA (OPTYMALIZACJA) ---
	# Chociaż piksele fajnie wyglądają, po 10 minutach gry tysiące węzłów zacięłoby grę.
	# Zostawiamy je na 60 sekund, a potem płynnie znikają.
	var tween = create_tween()
	tween.tween_interval(60.0) 
	tween.tween_property(self, "modulate:a", 0.0, 5.0) # Powolne zanikanie
	tween.finished.connect(queue_free)
