extends Node

signal jumpscare(animatronic_name)
signal animatronic_moved(loc_from, loc_to)

@onready var ai_tick_timer = $AITickTimer
@onready var right_vent_attack_timer = $RightVentAttackTimer
@onready var left_vent_attack_timer = $LeftVentAttackTimer
@onready var office_attack_timer = $OfficeAttackTimer

var camera_system: Control
var office_node: Control 

var toy_bonnie_attack_pending = false
var toy_chica_attack_pending = false
var toy_freddy_attack_pending = false
var toy_freddy_is_doomed = false

var toy_freddy_is_saved = false

var aggression_levels = {}
var locations = {}

var has_left_stage = {
	"ToyBonnie": false,
	"ToyChica": false,
	"ToyFreddy": false
}

const RESET_LOCATIONS = {
	"ToyBonnie": "CAM_03",
	"ToyChica": "CAM_07",
	"ToyFreddy": "CAM_09"
}

var camera_content_tracker = {}

var location_locks = {
	"CAM_09_Queue": ["ToyBonnie", "ToyChica", "ToyFreddy"],
	"RightVent": null,
	"LeftVent": null,
	"Hallway": null,
	"Hallway2": null,
	"Office": null
}

const PATHS = {
	"ToyBonnie": {
		"CAM_09": ["CAM_03"], 
		"CAM_03": ["CAM_04"], 
		"CAM_04": ["CAM_02"],
		"CAM_02": ["CAM_06"], 
		"CAM_06": ["RightVent"],
	},
	"ToyChica": {
		"CAM_09": ["CAM_07"], 
		"CAM_07": ["CAM_04", "Hallway"],
		"CAM_04": ["CAM_01"],
		"CAM_01": ["CAM_05"],
		"CAM_05": ["LeftVent"],
		"Hallway": ["CAM_07", "CAM_04"]
	},
	"ToyFreddy": {
		"CAM_09": ["CAM_10"], 
		"CAM_10": ["Hallway"], 
		"Hallway": ["Hallway2"],
	}
}

func _ready():
	ai_tick_timer.timeout.connect(_on_ai_tick_timer_timeout)
	right_vent_attack_timer.timeout.connect(_on_right_vent_attack_timer_timeout)
	
	office_attack_timer.timeout.connect(_on_office_attack_timer_timeout)

func start_night(levels: Dictionary, cam_sys: Control, office: Control):
	aggression_levels = levels
	camera_system = cam_sys
	office_node = office 
	
	locations = {
		"ToyBonnie": "CAM_09",
		"ToyChica": "CAM_09",
		"ToyFreddy": "CAM_09"
	}
	
	has_left_stage = {
		"ToyBonnie": false,
		"ToyChica": false,
		"ToyFreddy": false
	}
	
	location_locks = {
		"CAM_09_Queue": ["ToyBonnie", "ToyChica", "ToyFreddy"],
		"RightVent": null,
		"LeftVent": null,
		"Hallway": null,
		"Hallway2": null,
		"Office": null
	}
	
	camera_content_tracker = {}
	
	toy_bonnie_attack_pending = false
	toy_chica_attack_pending = false
	toy_freddy_attack_pending = false
	toy_freddy_is_doomed = false
	
	camera_system.set_camera_content("CAM_09", "All")
	ai_tick_timer.start()

func _on_ai_tick_timer_timeout():
	for name in aggression_levels.keys():
		attempt_move(name)

func attempt_move(name: String):
	var aggression = aggression_levels.get(name, 0)
	var chance = randi_range(1, 20)
	
	if aggression < chance:
		return

	var current_loc = locations[name]
	var next_loc: String

	if name == "ToyFreddy" and current_loc == "Hallway2":
		if office_node.CAM_ON:
			print("AIManager: ¡El jugador subió las cámaras! Toy Freddy entra a la oficina.")
			toy_freddy_enters_office()
		return
		
	var next_loc_options = PATHS[name].get(current_loc)
	
	if next_loc_options == null or next_loc_options.is_empty():
		print("AIManager: %s no tiene siguiente ubicación desde %s" % [name, current_loc])
		return
	
	next_loc = next_loc_options.pick_random()
	
	print("AIManager: %s intentando moverse de %s a %s" % [name, current_loc, next_loc])

	if name == "ToyChica" and current_loc == "CAM_09":
		if not has_left_stage["ToyBonnie"]:
			print("AIManager: Toy Chica no puede salir - Toy Bonnie aún no se ha ido")
			return
	if name == "ToyFreddy" and current_loc == "CAM_09":
		if not has_left_stage["ToyBonnie"] or not has_left_stage["ToyChica"]:
			print("AIManager: Toy Freddy no puede salir - otros animatrónicos aún en el escenario")
			return
	
	if location_locks.has(next_loc):
		if location_locks[next_loc] != null:
			print("AIManager: %s está bloqueado por %s" % [next_loc, location_locks[next_loc]])
			return
	
	if location_locks.has(current_loc):
		location_locks[current_loc] = null
	
	if location_locks.has(next_loc):
		location_locks[next_loc] = name
	
	if current_loc == "CAM_09":
		has_left_stage[name] = true
	
	locations[name] = next_loc
	emit_signal("animatronic_moved", current_loc, next_loc)
	update_camera_visuals(current_loc, next_loc, name)
	
	if next_loc == "LeftVent":
		office_node.set_vent_occupant("LeftVent", name)
	elif next_loc == "RightVent":
		office_node.set_vent_occupant("RightVent", name)
	elif next_loc == "Hallway":
		if name == "ToyFreddy":
			office_node.set_hall_occupant("ToyFreddy_Far")
		else:
			office_node.set_hall_occupant(name)
	elif next_loc == "Hallway2":
		if name == "ToyFreddy":
			office_node.set_hall_occupant("ToyFreddy_Close")
		else:
			office_node.set_hall_occupant(name)

func update_camera_visuals(old_loc, new_loc, name):
	print("DEBUG: Actualizando visuales - %s movió de %s a %s" % [name, old_loc, new_loc])
	
	if old_loc == "Hallway" or old_loc == "Hallway2":
		print("DEBUG: Limpiando Hallway de la oficina (animatronic se fue)")
		office_node.set_hall_occupant("Empty")
	elif old_loc == "LeftVent":
		print("DEBUG: Limpiando LeftVent de la oficina (animatronic se fue)")
		office_node.set_vent_occupant("LeftVent", "Empty")
	elif old_loc == "RightVent":
		print("DEBUG: Limpiando RightVent de la oficina (animatronic se fue)")
		office_node.set_vent_occupant("RightVent", "Empty")
	
	if old_loc != "CAM_09" and old_loc not in ["LeftVent", "RightVent", "Hallway", "Hallway2", "Office"]:
		var someone_else_here = false
		for other_name in locations.keys():
			if other_name != name and locations[other_name] == old_loc:
				print("DEBUG: %s también está en %s, no limpiar" % [other_name, old_loc])
				someone_else_here = true
				camera_system.set_camera_content(old_loc, other_name)
				break
		
		if not someone_else_here:
			print("DEBUG: Limpiando cámara antigua: %s" % old_loc)
			camera_system.set_camera_content(old_loc, "Empty")
	
	if old_loc == "CAM_09" or new_loc == "CAM_09":
		update_show_stage()
	
	if new_loc not in ["CAM_09", "LeftVent", "RightVent", "Hallway", "Hallway2", "Office"]:
		var current_occupant = camera_content_tracker.get(new_loc, "Empty")
		if current_occupant != "Empty" and current_occupant != name:
			print("DEBUG: %s ya está en %s, %s también aparece aquí (cámara compartida)" % [current_occupant, new_loc, name])
			camera_system.set_camera_content(new_loc, name)
		else:
			print("DEBUG: Mostrando %s en cámara: %s" % [name, new_loc])
			camera_system.set_camera_content(new_loc, name)
		
		camera_content_tracker[new_loc] = name

func update_show_stage():
	# Verificamos quién está en el escenario
	var bonnie_on_stage = locations["ToyBonnie"] == "CAM_09"
	var chica_on_stage = locations["ToyChica"] == "CAM_09"
	var freddy_on_stage = locations["ToyFreddy"] == "CAM_09"
	
	print("DEBUG Stage: Bonnie=%s, Chica=%s, Freddy=%s" % [bonnie_on_stage, chica_on_stage, freddy_on_stage])
	
	if bonnie_on_stage and chica_on_stage and freddy_on_stage:
		camera_system.set_camera_content("CAM_09", "Empty")
		
	elif not bonnie_on_stage and chica_on_stage and freddy_on_stage:
		camera_system.set_camera_content("CAM_09", "ToyBonnie") 
		
	elif not bonnie_on_stage and not chica_on_stage and freddy_on_stage:
		camera_system.set_camera_content("CAM_09", "ToyChica")
		
	elif not bonnie_on_stage and not chica_on_stage and not freddy_on_stage:
		camera_system.set_camera_content("CAM_09", "ToyFreddy")
	else:
	
		camera_system.set_camera_content("CAM_09", "ToyFreddy")

func on_hall_flashlight_success(occupant_name: String):
	print("AIManager: ¡El flash en %s funcionó!" % occupant_name)
	
	locations[occupant_name] = "CAM_08"
	location_locks["Hallway"] = null
	
	office_node.set_hall_occupant("Empty")
	
	camera_system.set_camera_content("Hallway", "Empty")
	camera_system.set_camera_content("CAM_08", occupant_name)

func _on_right_vent_attack_timer_timeout():
	if location_locks["RightVent"] == "ToyBonnie":
		print("AIManager: ¡Ataque de Toy Bonnie PENDIENTE!")
		toy_bonnie_attack_pending = true

func _on_left_vent_attack_timer_timeout():
	if location_locks["LeftVent"] == "ToyChica":
		print("AIManager: ¡Ataque de Toy Chica PENDIENTE!")
		toy_chica_attack_pending = true

func reset_animatronic(name: String):
	print("AIManager: ===== RESETEANDO %s =====" % name)
	var old_loc = locations[name]
	
	if old_loc not in ["RightVent", "LeftVent", "Hallway", "Hallway2", "Office"]:
		return
	
	var reset_loc = RESET_LOCATIONS.get(name, "CAM_09")
	locations[name] = reset_loc
	
	if camera_content_tracker.has(old_loc):
		camera_content_tracker.erase(old_loc)
	
	if location_locks.has(old_loc):
		location_locks[old_loc] = null
	
	# --- NUEVA LÓGICA DE LIMPIEZA EXPLÍCITA ---
	if old_loc == "RightVent":
		office_node.set_vent_occupant("RightVent", "Empty")
	elif old_loc == "LeftVent":
		office_node.set_vent_occupant("LeftVent", "Empty")
	elif old_loc == "Hallway" or old_loc == "Hallway2":
		office_node.set_hall_occupant("Empty")
	elif old_loc == "Office":
		office_node.set_office_occupant("Empty")
	
	# --- Resetea banderas de ataque (tu código original) ---
	if name == "ToyBonnie":
		toy_bonnie_attack_pending = false
		right_vent_attack_timer.stop()
	elif name == "ToyChica":
		toy_chica_attack_pending = false
		left_vent_attack_timer.stop()
	elif name == "ToyFreddy":
		toy_freddy_attack_pending = false
		toy_freddy_is_doomed = false
		office_attack_timer.stop()
		has_left_stage[name] = false
		if not "ToyFreddy" in location_locks["CAM_09_Queue"]:
			location_locks["CAM_09_Queue"].push_back(name)
	
	update_camera_visuals(old_loc, reset_loc, name)
	print("AIManager: ===== RESETEO COMPLETO =====")

func on_cameras_lowered():
	right_vent_attack_timer.stop()
	left_vent_attack_timer.stop()
	
	if toy_bonnie_attack_pending:
		check_mask_and_attack("ToyBonnie") 
	
	if toy_chica_attack_pending:
		check_mask_and_attack("ToyChica")
	
	if toy_freddy_is_doomed:
		check_mask_and_attack("ToyFreddy")
	
func on_cameras_raised():
	if location_locks["RightVent"] == "ToyBonnie":
		right_vent_attack_timer.start()
		
	if location_locks["LeftVent"] == "ToyChica":
		left_vent_attack_timer.start()
		
	if locations.get("ToyFreddy") == "Hallway2":
		print("AIManager: ¡El jugador subió las cámaras! Toy Freddy entra a la oficina.")
		toy_freddy_enters_office()
		
func check_mask_and_attack(animatronic_name: String):
	print("AIManager: ===== CHECK_MASK_AND_ATTACK para %s =====" % animatronic_name)
	print("AIManager: Ubicación actual: %s" % locations[animatronic_name])
	
	if office_node.is_mask_on(animatronic_name):
		print("AIManager: ¡Ataque de %s bloqueado por la máscara!" % animatronic_name)
	else:
		print("AIManager: ¡JUMPSCARE DE %s!" % animatronic_name)
		emit_signal("jumpscare", animatronic_name)
	
	if animatronic_name == "ToyBonnie":
		toy_bonnie_attack_pending = false
	elif animatronic_name == "ToyChica":
		toy_chica_attack_pending = false
	
	print("AIManager: ===== CHECK_MASK_AND_ATTACK COMPLETADO =====")
	
func toy_freddy_enters_office():
	office_node.set_hall_occupant("Empty")
	
	
	locations["ToyFreddy"] = "Office"
	location_locks["Hallway2"] = null
	location_locks["Office"] = "ToyFreddy"

	office_node.force_cameras_down()
	office_node.set_office_occupant("ToyFreddy")

	office_attack_timer.start() # Duración total (ej. 5s)
	$OfficeMaskTimer.start()   # Ventana de reacción (ej. 1.5s)
	
	toy_freddy_attack_pending = true
	toy_freddy_is_doomed = false
	toy_freddy_is_saved = false

func _on_office_attack_timer_timeout():
	if not toy_freddy_attack_pending:
		return
		
	office_node.set_office_occupant("Empty")
	if toy_freddy_is_saved:
		print("AIManager: Ejecutando reset de Toy Freddy.")
		reset_animatronic("ToyFreddy")
	elif toy_freddy_is_doomed:
		print("AIManager: Jugador condenado. Jumpscare pendiente.")
	else:
		if office_node.get_mask_state():
			reset_animatronic("ToyFreddy")
		else:
			emit_signal("jumpscare", "ToyFreddy")
	toy_freddy_attack_pending = false
		



func is_toy_freddy_doomed() -> bool:
	return toy_freddy_is_doomed
	
func emitScare(animName):
	emit_signal("jumpscare", animName)

func stop():
	ai_tick_timer.stop()
	right_vent_attack_timer.stop()
	left_vent_attack_timer.stop()
	office_attack_timer.stop()
	set_process(false)


func _on_fake_out_timer_timeout() -> void:
	office_node.office_animatronic_view.hide()
	office_node.stop_flicker_effect()
	toy_freddy_attack_pending = false


func _on_office_mask_timer_timeout():
	if office_node.get_mask_state():
		print("AIManager: Máscara puesta a tiempo. Jugador SALVADO (esperando fin de cinemática).")
		toy_freddy_is_saved = true
		toy_freddy_is_doomed = false
	else:
		print("AIManager: Máscara NO puesta. Jugador CONDENADO.")
		toy_freddy_is_saved = false
		toy_freddy_is_doomed = true
