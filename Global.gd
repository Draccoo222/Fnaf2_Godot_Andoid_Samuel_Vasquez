extends Node2D

var current_night: int = 1
var unlocked_night: int = 1 
var stars: int = 0

const SAVE_PATH = "user://savegame.json"

func _ready():
	
	load_data()

func save_data():
	
	var data = {
		"current_night": current_night,
		"unlocked_night": unlocked_night,
		"stars": stars
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		
		var json_string = JSON.stringify(data)
		file.store_string(json_string)
		print("Global: Partida guardada exitosamente en ", SAVE_PATH)
		file.close()
	else:
		print("Global: Error al guardar los datos.")

func load_data():

	if not FileAccess.file_exists(SAVE_PATH):
		print("Global: No hay partida guardada. Usando valores por defecto.")
		return 
		
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.get_data()
			current_night = data.get("current_night", 1)
			unlocked_night = data.get("unlocked_night", 1)
			stars = data.get("stars", 0)
			print("Global: Datos cargados. Noche desbloqueada: ", unlocked_night)
		else:
			print("Global: Error al leer el JSON corrompido.")

func reset_data():
	current_night = 1
	save_data()
