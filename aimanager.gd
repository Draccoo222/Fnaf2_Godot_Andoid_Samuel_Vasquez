extends Node

signal jumpscare(animatronic_name)
signal animatronic_moved(loc_from, loc_to)

@onready var ai_tick_timer = $AITickTimer
@onready var right_vent_attack_timer = $RightVentAttackTimer
@onready var left_vent_attack_timer = $LeftVentAttackTimer
@onready var office_attack_timer = $OfficeAttackTimer
@onready var mangle_vent_timer = $MangleVentTimer

var camera_system: Control
var office_node: Control 

var toy_bonnie_attack_pending = false
var toy_chica_attack_pending = false

var toy_freddy_attack_pending = false
var toy_freddy_is_doomed = false

var mangle_inside_office = true

var toy_freddy_is_saved = false
var mangle_entry_pending = false

var aggression_levels = {}
var locations = {}

var foxy_anger: float = 0.0
var foxy_threshold: float = 50.0
var foxy_attack_threshold: float = 100.0
var foxy_drain_speed: float = 15.0 

var foxy_d_counter: float = 0.0 
var foxy_flash_counter: int = 0 
var foxy_attack_timer: float = 50.0  


var foxy_is_active_easteregg = false

var withered_bonnie_attack_pending = false
var withered_bonnie_is_doomed = false
var withered_bonnie_is_saved = false


var has_left_stage = {
	"ToyBonnie": false,
	"ToyChica": false,
	"ToyFreddy": false
}

var has_left_service = {
	"WitheredBonnie": false,
	"WitheredChica": false,
	"Freddy": false
}

const RESET_LOCATIONS = {
	"ToyBonnie": "CAM_03",
	"ToyChica": "CAM_07",
	"ToyFreddy": "CAM_09",
	"Mangle": "CAM_11",
	"Foxy": "CAM_08",
	"WitheredBonnie": "CAM_07"
}

var camera_content_tracker = {}

var location_locks = {
	"CAM_08_Queue":["Foxy","WitheredBonnie", "Freddy", "Chica"],
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
	},
	"Mangle":{
		"CAM_12": ["CAM_11"], 
		"CAM_11": ["CAM_10"],
		"CAM_10": ["CAM_07"],
		"CAM_07": ["Hallway", "CAM_01"],
		"CAM_01": ["CAM_02"],
		"CAM_02": ["CAM_06"],
		"Hallway": ["CAM_07", "CAM_01"],
		"CAM_06": ["RightVent"],
		"RightVent": ["RightVent"]
	},
	"WitheredBonnie": {
		"CAM_08":["CAM_07"],
		"CAM_07":["Hallway"],
		"Hallway":["CAM_01"],
		"CAM_01":["CAM_05"],
		"CAM_05":["OFFICE"]
	},
	"Foxy":{
		"CAM_08":["Hallway"],
	}
}

func _ready():
	ai_tick_timer.timeout.connect(_on_ai_tick_timer_timeout)
	right_vent_attack_timer.timeout.connect(_on_right_vent_attack_timer_timeout)
	mangle_vent_timer.timeout.connect(_on_mangle_vent_timer_timeout)
	
	office_attack_timer.timeout.connect(_on_office_attack_timer_timeout)
	set_process(false)

func _process(delta: float) -> void:
	if locations["Foxy"] == "Hallway":
		if office_node.get_mask_state() and no_threats_present():
			foxy_d_counter += 2.0 * delta
		else:
			foxy_d_counter += 1.0 * delta
	
		foxy_attack_timer -= delta
		if foxy_attack_timer <= 0:
			emit_signal("jumpscare", "Foxy")


func start_night(levels: Dictionary, cam_sys: Control, office: Control):
	set_process(true)
	aggression_levels = levels
	camera_system = cam_sys
	office_node = office 
	
	mangle_inside_office = false
	office_node.mangle_ceiling_view.visible = false
	office_node.mangle_office_sound.stop()
	
	foxy_d_counter = 0.0
	foxy_flash_counter = 0
	foxy_attack_timer = 50.0
	
	foxy_is_active_easteregg = false
	
	locations = {
		"ToyBonnie": "CAM_09",
		"ToyChica": "CAM_09",
		"ToyFreddy": "CAM_09",
		"Mangle": "CAM_12",
		"Foxy": "CAM_08",
		"WitheredBonnie": "CAM_08"
	}
	
	has_left_stage = {
		"ToyBonnie": false,
		"ToyChica": false,
		"ToyFreddy": false
	}
	
	has_left_service = {
		"WitheredBonnie": false,
		"Chica": false,
		"Freddy": false
	}
	
	location_locks = {
		"CAM_09_Queue": ["ToyBonnie", "ToyChica", "ToyFreddy"],
		"CAM_08_Queue": ["Foxy", "WitheredBonnie", "Chica", "Freddy"],
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
	
	withered_bonnie_attack_pending = false
	withered_bonnie_is_doomed = false
	withered_bonnie_is_saved = false
	mangle_entry_pending = false
	
	camera_system.set_camera_content("CAM_09", "All")
	ai_tick_timer.start()
	

func _on_ai_tick_timer_timeout():
	
	for name in aggression_levels.keys():
		if name != "Foxy": 
			attempt_move(name)
			
	check_foxy_movement()
	
	var foxy_lvl = aggression_levels.get("Foxy", 0)
	if foxy_lvl > 0:
		var current = locations["Foxy"]
		
		
		if current == "CAM_08":
			var chance = randi_range(1, 20)
			if foxy_lvl >= chance:
				move_foxy_to_hallway()
		
	
		elif current == "Hallway":	
			if is_foxy_blocked():	
				pass
			else:
				if not office_node.CAM_ON:
					foxy_anger += foxy_lvl * 1.5
				else:
					foxy_anger += foxy_lvl * 0.5
				
				print("AIManager: Ira de Foxy: %d / %d" % [foxy_anger, foxy_attack_threshold])
		
			if foxy_anger > foxy_attack_threshold:
				print("AIManager: ¡JUMPSCARE DE FOXY!")
				emit_signal("jumpscare", "Foxy")
	

func attempt_move(name: String):
	var aggression = aggression_levels.get(name, 0)
	var chance = randi_range(1, 20)
	
	if aggression < chance:
		return

	var current_loc = locations[name]
	var next_loc: String
	
	if name == "WitheredBonnie" and current_loc ==  "CAM_08":
		if location_locks.has("CAM_08_Queue"):
			if "WitheredBonnie" not in location_locks["CAM_08_Queue"]:
				print("Withered Bonnie bloqueado")
		location_locks["CAM_08_Queue"].erase("WitheredBonnie")
		has_left_service["WitheredBonnie"] = true
		
	if name == "WitheredBonnie" and current_loc == "CAM_05":
		print("AIManager: ¡Withered Bonnie BYPASS! Entrando directo a la oficina...")
		withered_bonnie_enters_office()
		return
	

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
	
	if name == "Mangle" and next_loc == "Office":
		mangle_enters_office()
		return
		
	if name == "Mangle" or name == "Foxy": 
		update_hallway_state()
	
	if name == "Mangle" and next_loc == "CAM_11":
		camera_system.set_camera_content("CAM_12", "Mangle") 
		return
		
	if name == "Mangle" and next_loc == "RightVent":
		print("AIManager: Mangle llegó a la ventila. Iniciando cuenta atrás...")

		if has_node("MangleVentTimer"):
			$MangleVentTimer.start()
			
	if name == "Bonnie":
		update_hallway_state()
	
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
	if name == "Mangle":
		camera_system.set_mangle_location(new_loc)
		
		var background_cameras = ["CAM_06", "CAM_12", "RightVent"]
		if new_loc in background_cameras:
			camera_system.set_camera_content(new_loc, "Mangle")
	
		if old_loc in background_cameras:
			camera_system.set_camera_content(old_loc, "Empty")
			
		return
	
	if new_loc == "CAM_06" or old_loc == "CAM_06":
		update_parts_service_camera()
		if new_loc == "CAM_06": return
		
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
	
	if "Foxy" in occupant_name:
		foxy_flash_counter += 1
		foxy_attack_timer = 50.0  

		print("AIManager: Foxy flasheado (%d veces)" % foxy_flash_counter)
		var threshold = 5 * 1
		if foxy_flash_counter >= threshold:
			print("AIManager: ¡Foxy se rinde después de %d flashes!" % foxy_flash_counter)
			reset_foxy_to_parts_service()
		return
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
	
	if old_loc == "RightVent":
		office_node.set_vent_occupant("RightVent", "Empty")
	elif old_loc == "LeftVent":
		office_node.set_vent_occupant("LeftVent", "Empty")
	elif old_loc == "Hallway" or old_loc == "Hallway2":
		office_node.set_hall_occupant("Empty")
	elif old_loc == "Office":
		office_node.set_office_occupant("Empty")
	
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
	elif name == "WitheredBonnie":  
		withered_bonnie_attack_pending = false
		withered_bonnie_is_doomed = false
		withered_bonnie_is_saved = false
		$WitheredBonnieAttackTimer.stop()
	if name == "Mangle": 
		print("AIManager: Reseteando Mangle desde la ventila")
		if has_node("MangleVentTimer"): $MangleVentTimer.stop()
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
		
	if withered_bonnie_is_doomed:
		check_mask_and_attack("WitheredBonnie")
	
	if mangle_inside_office:
		emit_signal("jumpscare", "Mangle")
	
	if mangle_entry_pending:
		print("AIManager: Monitor bajado. Mangle ahora es hostil.")
		mangle_inside_office = true
		mangle_entry_pending = false
	
func on_cameras_raised():
	if location_locks["RightVent"] == "ToyBonnie":
		right_vent_attack_timer.start()
	
	if location_locks["LeftVent"] == "ToyChica":
		left_vent_attack_timer.start()
	
	
	if location_locks["RightVent"] == "ToyBonnie":
		
		var instant_attack_chance = randi_range(1, 3)
		if instant_attack_chance == 1:
			print("Office: ¡Toy Bonnie ataca al subir cámaras!")
			check_mask_and_attack("ToyBonnie")
			return
	
	if location_locks["LeftVent"] == "ToyChica":
		var instant_attack_chance = randi_range(1, 3)
		if instant_attack_chance == 1:
			print("Office: ¡Toy Chica ataca al subir cámaras!")
			check_mask_and_attack("ToyChica")
			return
	
	
	if locations.get("ToyFreddy") == "Hallway2":
		print("AIManager: ¡El jugador subió las cámaras! Toy Freddy entra a la oficina.")
		toy_freddy_enters_office()
	
	
	if locations["Mangle"] == "RightVent":
		print("AIManager: ¡Monitor subido con Mangle en Ventila! Entrando al techo...")
		if has_node("MangleVentTimer"):
			$MangleVentTimer.stop()
		mangle_enters_office()

		
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

	office_attack_timer.start() 
	$OfficeMaskTimer.start() 
	
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
		

func update_parts_service_camera():
	var bonnie_here = locations.get("WitheredBonnie") == "CAM_08"
	var freddy_here = false
	var chica_here = false
	
	var content = "Empty"
	
	if bonnie_here or freddy_here or chica_here:
		content = "Withered_Group"
	else:
		if locations["Foxy"] == "CAM_08" and foxy_is_active_easteregg:
			content = "Foxy" 
		else:
			content = "Empty" 
	camera_system.set_camera_content("CAM_08", content)

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
	if  locations.get("ToyFreddy") == "Office":
		office_node.office_animatronic_view.hide()
		office_node.stop_flicker_effect()
		toy_freddy_attack_pending = false
	elif locations.get("WitheredBonnie") == "Office":
		office_node.stop_flicker_effect()
		withered_bonnie_attack_pending = false
	
func check_foxy_movement():
	var foxy_lvl = aggression_levels.get("Foxy", 0)
	if foxy_lvl == 0 or locations["Foxy"] != "CAM_08":
		return
	
	var random_offset = randi_range(1, 4)
	if foxy_lvl >= (foxy_d_counter - random_offset):
		move_foxy_to_hallway()
		foxy_d_counter = 0.0

func update_hallway_state():
	var foxy = locations.get("Foxy") == "Hallway"
	var mangle = locations.get("Mangle") == "Hallway"
	var toy_chica = locations.get("ToyChica") == "Hallway"
	var toy_freddy_far = locations.get("ToyFreddy") == "Hallway"
	var toy_freddy_close = locations.get("ToyFreddy") == "Hallway2"
	var bonnie = locations.get("WitheredBonnie") == "Hallway"
	var w_freddy = false
	var golden = false
	
	var state = "Empty"
	
	
	if golden:
		state = "GoldenFreddy"
	elif mangle and foxy:
		state = "Foxy_Mangle"
	elif mangle:
		state = "Mangle"
	elif toy_chica:
		state = "ToyChica"
	elif toy_freddy_far:
		state = "ToyFreddy_Far"
	elif bonnie and foxy:
		state = "WitheredBonnie_Foxy"
	elif bonnie:
		state = "WitheredBonnie"
	elif toy_freddy_close:
		state = "ToyFreddy_Close"
	elif w_freddy:
		state = "WitheredFreddy"
	elif foxy:
		state = "Foxy"
	
	print("AIManager: Estado del Pasillo calculado: ", state)
	office_node.set_hall_occupant(state)  
	
	
	
func mangle_enters_office():
	if not office_node.CAM_ON:
		print("AIManager: BLOQUEADO - Mangle intentó entrar sin monitor.")
		return
		
		
	mangle_entry_pending = true
	locations["Mangle"] = "Office"
	
	office_node.set_vent_occupant("RightVent", "Empty")
	
	camera_system.set_camera_content("RightVent", "Empty")
	
	office_node.activate_mangle_inside()
	
func _on_mangle_vent_timer_timeout():
	if location_locks["RightVent"] == "Mangle":
		print("AIManager: Mangle se cansó de esperar en la ventila. Entrando al techo...")
		mangle_enters_office()
		
func move_foxy_to_hallway():
	print("AIManager: Foxy sale de Parts & Service al Pasillo.")
	locations["Foxy"] = "Hallway"
	
	
	foxy_is_active_easteregg = false 
	
	
	update_camera_visuals("CAM_08", "Hallway", "Foxy")
	update_hallway_state() 
	
func withered_bonnie_enters_office():
	print("AIManager: ===== WITHERED BONNIE ENTRA A LA OFICINA =====")
	
	
	locations["WitheredBonnie"] = "Office"
	location_locks["LeftVent"] = null
	location_locks["Office"] = "WitheredBonnie"
	
	
	if office_node.CAM_ON:
		office_node.force_cameras_down()
	
	
	office_node.set_vent_occupant("LeftVent", "Empty")
	office_node.set_office_occupant("WitheredBonnie")
	
   
	office_node.start_flicker_effect()
	
	
	$WitheredBonnieAttackTimer.start()    
	$WitheredBonnieMaskTimer.start() 
	
	withered_bonnie_attack_pending = true
	withered_bonnie_is_doomed = false
	withered_bonnie_is_saved = false
	
func reset_foxy_to_parts_service():
	print("AIManager: Foxy regresa a Parts & Service.")
	locations["Foxy"] = "CAM_08"
	foxy_anger = 0.0
	foxy_flash_counter = 0
	foxy_attack_timer = 50.0
	
	
	var all_gone = (has_left_service.get("WitheredBonnie", true) and has_left_service.get("Chica", true) and has_left_service.get("Freddy", true))
	
	foxy_is_active_easteregg = all_gone
	
	update_hallway_state()
	update_camera_visuals("Hallway", "CAM_08", "Foxy")


func is_foxy_blocked() -> bool:
	if locations.get("ToyFreddy") == "Office" or mangle_inside_office:
		return true
		
	if locations.get("ToyFreddy") == "Hallway" or locations.get("ToyFreddy") == "Hallway2":
		return true
	if locations.get("ToyChica") == "Hallway": 
		return true
	return false
	
func no_threats_present() -> bool:
	return (location_locks["LeftVent"] == null and location_locks["RightVent"] == null and location_locks["Office"] == null)

func _on_office_mask_timer_timeout():
	if office_node.get_mask_state():
		print("AIManager: Máscara puesta a tiempo. Jugador SALVADO (esperando fin de cinemática).")
		toy_freddy_is_saved = true
		toy_freddy_is_doomed = false
	else:
		print("AIManager: Máscara NO puesta. Jugador CONDENADO.")
		toy_freddy_is_saved = false
		toy_freddy_is_doomed = true


func _on_withered_bonnie_attack_timer_timeout():
	if not withered_bonnie_attack_pending:
		return
	office_node.set_office_occupant("Empty")

	if withered_bonnie_is_saved:
		print("AIManager: Ejecutando reset de Withered Bonnie.")
		reset_animatronic("WitheredBonnie")
	elif withered_bonnie_is_doomed:
		print("AIManager: Jugador condenado. Jumpscare pendiente.")
	else:
	
		if office_node.get_mask_state():
			reset_animatronic("WitheredBonnie")
		else:
			emit_signal("jumpscare", "WitheredBonnie")
	
	withered_bonnie_attack_pending = false

func is_withered_bonnie_doomed() -> bool:
	return withered_bonnie_is_doomed

func _on_withered_bonnie_mask_timer_timeout():
	if office_node.get_mask_state():
		print("AIManager: ¡Máscara puesta a tiempo! Jugador SALVADO (esperando fin de cinemática).")
		withered_bonnie_is_saved = true
		withered_bonnie_is_doomed = false
	else:
		print("AIManager: ¡Máscara NO puesta! Jugador CONDENADO.")
		withered_bonnie_is_saved = false
		withered_bonnie_is_doomed = true
		
