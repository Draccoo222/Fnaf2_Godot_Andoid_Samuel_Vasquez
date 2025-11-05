extends Node2D

signal jumpscare(animatronic_name)

@onready var ai_tick_timer = $AITickTimer
@onready var right_vent_attack_timer = $RightVentAttackTimer
# (Más adelante añadiremos timers para la ventilación izquierda y el pasillo)

# --- Referencias a Escenas Externas ---
var camera_system: Control
var office_node: Control # Esta es una referencia a tu script Oficina.gd

# --- Estado de la IA ---
var aggression_levels = {
	"ToyBonnie": 0,
	"ToyChica": 0,
	"ToyFreddy": 0
	# (Aquí añadiremos a Foxy, Mangle, BB, etc.)
}

var locations = {
	"ToyBonnie": "CAM_09",
	"ToyChica": "CAM_09",
	"ToyFreddy": "CAM_09"
}


var location_locks = {
	
	"CAM_09_Queue": ["ToyBonnie", "ToyChica", "ToyFreddy"],
	
	"RightVent": null,
	"LeftVent": null,
	"Hallway": null,
	"Office": null
}


const PATHS = {
	"ToyBonnie": {
		"CAM_09": "CAM_03", "CAM_03": "CAM_04", "CAM_04": "CAM_02",
		"CAM_02": "CAM_06", "CAM_06": "RightVent", "RightVent": "Office"
	},
	"ToyChica": {
		"CAM_09": "CAM_07", "CAM_07": "CAM_05", "CAM_05": "CAM_03",
		"CAM_03": "CAM_01", "CAM_01": "LeftVent", "LeftVent": "Office"
	},
	"ToyFreddy": {
		"CAM_09": "CAM_10", "CAM_10": "CAM_07", "CAM_07": "Hallway",
		"Hallway": "Office"
	}
	
}


func _ready():
	ai_tick_timer.timeout.connect(_on_ai_tick_timer_timeout)
	right_vent_attack_timer.timeout.connect(_on_right_vent_attack_timer_timeout)


func start_night(levels: Dictionary, cam_sys: Control, office: Control):
	aggression_levels = levels
	camera_system = cam_sys
	office_node = office 
	
	camera_system.set_camera_content("CAM_09", "All")
	
	ai_tick_timer.start()

func _on_ai_tick_timer_timeout():
	# Intenta mover a cada animatrónico
	for name in aggression_levels.keys():
		attempt_move(name)

# --- Lógica de Movimiento ---

func attempt_move(name: String):
	var aggression = aggression_levels.get(name, 0)
	var chance = randi_range(1, 20)
	
	# 1. Prueba de Agresividad
	if aggression < chance:
		# print("%s falló el movimiento (Nivel: %d, Azar: %d)" % [name, aggression, chance])
		return

	var current_loc = locations[name]
	var next_loc = PATHS[name].get(current_loc)
	
	if next_loc == null:
		return # Ya está en la oficina, no se mueve más

	# 2. Prueba de Cola (Show Stage)
	if current_loc == "CAM_09":
		if location_locks["CAM_09_Queue"][0] != name:
			# print("%s intentó salir de CAM_09, pero es el turno de %s" % [name, location_locks["CAM_09_Queue"][0]])
			return
	
	# 3. Prueba de Bloqueo (Ventilaciones, Pasillo, etc.)
	if location_locks.has(next_loc):
		if location_locks[next_loc] != null:
			# print("%s intentó moverse a %s, pero está ocupado por %s" % [name, next_loc, location_locks[next_loc]])
			return
			
	# --- ¡MOVIMIENTO EXITOSO! ---
	
	# a. Libera su posición antigua
	if location_locks.has(current_loc):
		location_locks[current_loc] = null # Libera la ventilación/oficina/pasillo
	elif current_loc == "CAM_09":
		location_locks["CAM_09_Queue"].pop_front() # Sale de la cola del stage
	
	# b. Ocupa la nueva posición
	if location_locks.has(next_loc):
		location_locks[next_loc] = name # Ocupa la ventilación/oficina/pasillo
	
	# c. Actualiza su ubicación interna
	locations[name] = next_loc
	print("AIManager: ¡%s se movió de %s a %s!" % [name, current_loc, next_loc])

	# d. Actualiza el sistema de cámaras
	update_camera_visuals(current_loc, next_loc, name)
	
	# e. Actualiza la Oficina (si es una zona de ataque)
	if next_loc == "LeftVent" or next_loc == "RightVent":
		office_node.set_vent_occupant(next_loc, name)
	elif next_loc == "Hallway":
		office_node.set_hall_occupant(next_loc)
	
	# f. Inicia el temporizador de ataque si corresponde
	if next_loc == "RightVent" and name == "ToyBonnie":
		right_vent_attack_timer.start()
	# (Aquí añadiremos 'elif next_loc == "LeftVent" and name == "ToyChica": ...')


func update_camera_visuals(old_loc, new_loc, name):
	# 1. Actualiza la CÁMARA NUEVA
	camera_system.set_camera_content(new_loc, name)
	
	# 2. Actualiza la CÁMARA ANTIGUA
	var who_is_left_in_old_loc = "Empty" # Por defecto
	
	if old_loc == "CAM_09":
		if not location_locks["CAM_09_Queue"].is_empty():
			who_is_left_in_old_loc = location_locks["CAM_09_Queue"][0]
	
	camera_system.set_camera_content(old_loc, who_is_left_in_old_loc)

# --- Lógica de Ataque y Respuesta ---

# Se llama cuando el jugador flashea el pasillo con éxito
func on_hall_flashlight_success(occupant_name: String):
	print("AIManager: ¡El flash en %s funcionó!" % occupant_name)
	
	# Mueve al animatrónico de vuelta (ej. a Parts/Service)
	locations[occupant_name] = "CAM_08" # O a donde deba ir
	location_locks["Hallway"] = null
	
	# Avisa a la oficina que el pasillo está vacío
	office_node.set_hall_occupant("Empty")
	
	# Actualiza las cámaras
	update_camera_visuals("Hallway", "CAM_08", occupant_name)

# Se llama 5 segundos después de que Toy Bonnie llega a la ventilación
func _on_right_vent_attack_timer_timeout():
	if location_locks["RightVent"] != "ToyBonnie":
		return # Ya se ha ido
	
	# ¡PREGUNTA A LA OFICINA! ¿Está la máscara puesta?
	if office_node.is_mask_on():
		# ¡SALVADO!
		print("AIManager: ¡Ataque de Toy Bonnie bloqueado por la máscara!")
		reset_animatronic("ToyBonnie")
	else:
		# ¡JUMPSCARE!
		print("AIManager: ¡JUMPSCARE DE TOY BONNIE!")
		emit_signal("jumpscare", "ToyBonnie")

# Función útil para reiniciar a un animatrónico
func reset_animatronic(name: String):
	var old_loc = locations[name] 
	
	# 1. Libera la ubicación actual
	if location_locks.has(old_loc):
		location_locks[old_loc] = null
	
	# 2. Resetea su posición interna
	locations[name] = "CAM_09" # De vuelta al Show Stage
	
	# 3. Añádelo de nuevo al FINAL de la cola del Show Stage
	location_locks["CAM_09_Queue"].push_back(name) 
	
	# 4. Actualiza la Oficina
	if old_loc == "RightVent":
		office_node.set_vent_occupant("RightVent", "Empty")
	elif old_loc == "LeftVent":
		office_node.set_vent_occupant("LeftVent", "Empty")
	elif old_loc == "Hallway":
		office_node.set_hall_occupant("Empty")
	
	# 5. Actualiza las Cámaras
	update_camera_visuals(old_loc, "CAM_09", name)
