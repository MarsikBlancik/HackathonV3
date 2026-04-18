extends Node

const MAX_TIER: int = 3

var gadgets = {
	"drones": 0,
	"mines": 0,
	"dash_ram": 0,
	"pipe_bomb": 0, # <--- NOWOŚĆ
	"molotov": 0
}

func get_upgrade_choices() -> Array:
	var available_pool = []
	for gadget_name in gadgets.keys():
		if gadgets[gadget_name] < MAX_TIER:
			available_pool.append(gadget_name)
	available_pool.shuffle()
	return available_pool.slice(0, 3)

func apply_upgrade(gadget_name: String) -> void:
	if gadgets.has(gadget_name):
		gadgets[gadget_name] += 1
		# Wywołujemy funkcję aktualizacji u gracza
		get_parent().update_gadgets()
