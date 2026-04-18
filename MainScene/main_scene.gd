extends Node2D

@export var xp_gem_scene: PackedScene 
@export var initial_xp_count: int = 40
@export var spawn_range: float = 600.0

@onready var player
@onready var ui = $UI

func _ready() -> void:
	# Usuwamy całe szukanie gracza i łączenie sygnałów, bo robi to UI
	await get_tree().process_frame
