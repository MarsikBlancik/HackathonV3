extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var restart = $VBoxContainer/Button
	restart.pressed.connect(restart_pressed)
	
func restart_pressed():
	get_tree().change_scene_to_file("res://MainScene.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
