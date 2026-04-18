extends Sprite2D

func _ready() -> void:
	# 1. Losowy obrót plamy (od 0 do 360 stopni)
	rotation = randf() * TAU
	
	# 2. Losowy rozmiar (niektóre plamy będą małe, inne większe)
	var random_scale = randf_range(0.5, 1.5)
	scale = Vector2(random_scale, random_scale)
	
	# 3. System sprzątania (optymalizacja)
	# Plama leży przez 30 sekund, a potem przez 5 sekund płynnie zanika
	var tween = create_tween()
	tween.tween_interval(30.0) # Czas leżenia na podłodze
	tween.tween_property(self, "modulate:a", 0.0, 5.0) # Zanikanie przezroczystości (a)
	tween.finished.connect(queue_free) # Usunięcie plamy po zaniknięciu
