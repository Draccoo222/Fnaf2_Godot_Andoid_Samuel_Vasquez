extends Node

signal jumpscare(animatronic_name)
signal animatronic_moved(loc_from, loc_to)

@onready var ai_tick_timer = $AITickTimer
@onready var right_vent_attack_timer = $RightVentAttackTimer
@onready var left_vent_attack_timer = $LeftVentAttackTimer
@onready var office_attack_timer = $OfficeAttackTimer
@onready var mangle_vent_timer = $MangleVentTimer


var bb_in_office = false
var bb_movement_sounds = []

var camera_system: Control
var office_node: Control 

var toy_bonnie_attack_pending = false
var toy_chica_attack_pending = false

var toy_freddy_attack_pending = false
var toy_freddy_is_doomed = false

var withered_freddy_attack_pending = false
var withered_freddy_is_doomed = false
var withered_freddy_is_saved = false

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
	"WitheredFreddy": false
}

const RESET_LOCATIONS = {
	"ToyBonnie": "CAM_03",
	"ToyChica": "CAM_07",
	"ToyFreddy": "CAM_09",
	"Mangle": "CAM_11",
	"Foxy": "CAM_08",
	"BB": "CAM_10",
	"WitheredBonnie": "CAM_07",
	"WitheredChica": "CAM_04",
	"WitheredFreddy": "CAM_08"
}

var camera_content_tracker = {}
var withered_chica_attack_pending = false
var withered_chica_is_doomed = false
var withered_chica_is_saved = false

var location_locks = {
	"CAM_08_Queue":["Foxy","WitheredBonnie", "WitheredChica", "WitheredFreddy"],
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
	"BB": {
		"CAM_10": ["CAM_05"],
		"CAM_05": ["LeftVent"]
	},
	"WitheredBonnie": {
		"CAM_08":["CAM_07"],
		"CAM_07":["Hallway"],
		"Hallway":["CAM_01"],
		"CAM_01":["CAM_05"],
		"CAM_05":["Office"]
	},
		"WitheredChica": {
			"CAM_08": ["CAM_04"],           
			"CAM_04": ["CAM_02"],          
			"CAM_02": ["CAM_06"],           
			"CAM_06": ["Office"],      
	},
	"Foxy":{
		"CAM_08":["Hallway"],
	},
	"WitheredFreddy": {
		"CAM_08": ["CAM_07"],
		"CAM_07": ["CAM_03"],
		"CAM_03": ["Hallway"],
		"Hallway": ["Office"]
	}
}

var office_full_scene_occupant: String = ""
var game_over_triggered = false

var golden_freddy_active = false
var golden_freddy_pending_entry = false
var golden_freddy_location = "Hidden"
var golden_freddy_timer = 0.0
var golden_freddy_office_limit = 1.5

func _ready():
	ai_tick_timer.timeout.connect(_on_ai_tick_timer_timeout)
	right_vent_attack_timer.timeout.connect(_on_right_vent_attack_timer_timeout)
	mangle_vent_timer.timeout.connect(_on_mangle_vent_timer_timeout)
	
	office_attack_timer.timeout.connect(_on_office_attack_timer_timeout)
	set_process(false)

func _process(delta: float) -> void:
	process_golden_freddy(delta)
	
	if not locations.has("Foxy") or locations["Foxy"] != "Hallway":
		return
	
	var is_blocked = is_foxy_blocked()
	
	if is_blocked:
		print("AIManager: Foxy bloqueado por otro animatronic - ira pausada")
		return
	
	if not is_foxy_blocked():
		foxy_attack_timer -= delta
		if foxy_attack_timer <= 0:
			print("AIManager: ¡TIEMPO AGOTADO! Jumpscare de Foxy.")
			trigger_jumpscare("Foxy")
			return
	
	if office_node.get_mask_state() and no_threats_present():
		foxy_d_counter += 2.0 * delta
	else:
		foxy_d_counter += 1.0 * delta
		
	


func start_night(levels: Dictionary, cam_sys: Control, office: Control):
	set_process(true)
	
	game_over_triggered = false
	office_full_scene_occupant = ""
	
	game_over_triggered = false
	aggression_levels = levels
	camera_system = cam_sys
	office_node = office 
	
	mangle_inside_office = false
	office_node.mangle_ceiling_view.visible = false
	office_node.mangle_office_sound.stop()
	
	golden_freddy_active = false
	golden_freddy_pending_entry = false
	
	
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
		"WitheredBonnie": "CAM_08",
		"WitheredChica": "CAM_08",
		"WitheredFreddy": "CAM_08",
		"BB": "CAM_10",
		"GoldenFreddy": "Hidden"
	}
	bb_in_office = false
	has_left_stage = {
		"ToyBonnie": false,
		"ToyChica": false,
		"ToyFreddy": false
	}
	
	has_left_service = {
		"WitheredBonnie": false,
		"WitheredChica": false,
		"WitheredFreddy": false
	}
	
	location_locks = {
		"CAM_09_Queue": ["ToyBonnie", "ToyChica", "ToyFreddy"],
		"CAM_08_Queue": ["Foxy", "WitheredBonnie", "WitheredChica", "WitheredFreddy"],
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
	
	withered_chica_attack_pending = false
	withered_chica_is_doomed = false
	withered_chica_is_saved = false
	
	withered_freddy_attack_pending = false
	withered_freddy_is_doomed = false
	withered_freddy_is_saved = false
	
	camera_system.set_camera_content("CAM_09", "All")
	ai_tick_timer.start()
	

func _on_ai_tick_timer_timeout():
	var gf_level = aggression_levels.get("GoldenFreddy", 0)
	
	if gf_level > 0 and not golden_freddy_active and office_full_scene_occupant == "":
		var chance = randi_range(1, 100)
		if chance <= gf_level:
			spawn_golden_freddy()
	
	for name in aggression_levels.keys():
		if name != "Foxy" and name != "GoldenFreddy" : 
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
				trigger_jumpscare("Foxy")
			
	if location_locks["LeftVent"] == "BB":
		if office_node.get_mask_state():
			print("AIManager: Máscara espanta a BB.")
			reset_animatronic("BB")	
	

func attempt_move(name: String):
	var aggression = aggression_levels.get(name, 0)
	var chance = randi_range(1, 20)
	
	if aggression < chance:
		return

	var current_loc = locations[name]
	var next_loc: String
	
	
	
	if name == "BB":
		office_node.play_bb_sound()
	
	if name == "WitheredBonnie" and current_loc ==  "CAM_08":
		if location_locks.has("CAM_08_Queue"):
			if "WitheredBonnie" not in location_locks["CAM_08_Queue"]:
				print("Withered Bonnie bloqueado")
		location_locks["CAM_08_Queue"].erase("WitheredBonnie")
		has_left_service["WitheredBonnie"] = true
		
	if name == "WitheredChica" and current_loc == "CAM_08":
		if location_locks.has("CAM_08_Queue"):
			if "WitheredBonnie" in location_locks["CAM_08_Queue"]:
				print("AIManager: Withered Chica bloqueada - Withered Bonnie aún no se ha ido")
				return
			if "WitheredChica" not in location_locks["CAM_08_Queue"]:
				print("AIManager: Withered Chica bloqueada")
				return
			location_locks["CAM_08_Queue"].erase("WitheredChica")
			has_left_service["WitheredChica"] = true
			
	if name == "WitheredFreddy" and current_loc == "Hallway":
		if office_node.CAM_ON:
			print("AIManager: Monitor arriba -> Withered Freddy entra a la oficina.")
			withered_freddy_enters_office()
		return
		
	if name == "WitheredBonnie" and current_loc == "CAM_05":
		print("AIManager: ¡Withered Bonnie BYPASS! Entrando directo a la oficina...")
		withered_bonnie_enters_office()
		return
	
	if name == "WitheredChica" and current_loc == "CAM_06":
		print("AIManager: ¡Withered Chica BYPASS! Entrando directo a la oficina...")
		withered_chica_enters_office()
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
	
	if next_loc not in ["LeftVent", "RightVent", "Office"]:
		if name in ["ToyBonnie", "ToyChica", "ToyFreddy", "WitheredBonnie", "WitheredChica", "WitheredFreddy"]:
			office_node.play_random_footstep()


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
	
	if next_loc == "LeftVent" or next_loc == "RightVent":
		if name == "ToyBonnie" or name == "ToyChica":
			office_node.play_vent_sound("close")
	
	
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
			
	if name == "WitheredBonnie":
		update_hallway_state()

	if name == "WitheredFreddy":
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
	
	if new_loc == "CAM_08" or old_loc == "CAM_08":
		update_parts_service_camera()
		if new_loc == "CAM_08": return
		
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
		foxy_d_counter = 0

		print("AIManager: Foxy flasheado (%d veces). Timer reset a 50." % foxy_flash_counter)
	
		var threshold = 5 * + (aggression_levels.get("Foxy", 0) / 4)  
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
	
	
	
	
	if office_full_scene_occupant == name:
		office_full_scene_occupant = ""
		print("AIManager: Oficina liberada - otros pueden entrar ahora")
	
	if name == "Mangle":
		print("AIManager: Reseteando Mangle desde la ventila")
		if has_node("MangleVentTimer"):
			$MangleVentTimer.stop()
		office_node.stop_mangle_sound()
	
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
		if name != "GoldenFreddy": 
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
	elif name == "BB":
		pass
	elif name == "WitheredBonnie":  
		withered_bonnie_attack_pending = false
		withered_bonnie_is_doomed = false
		withered_bonnie_is_saved = false
		$WitheredBonnieAttackTimer.stop()
		$WitheredBonnieMaskTimer.stop()
	elif name == "WitheredChica":  
		withered_chica_attack_pending = false
		withered_chica_is_doomed = false
		withered_chica_is_saved = false
		$WitheredChicaAttackTimer.stop()
		$WitheredChicaMaskTimer.stop()
	elif name == "WitheredFreddy":
		withered_freddy_attack_pending = false
		withered_freddy_is_doomed = false
		withered_freddy_is_saved = false
		if has_node("WitheredFreddyAttackTimer"): $WitheredFreddyAttackTimer.stop()
		if has_node("WitheredFreddyMaskTimer"): $WitheredFreddyMaskTimer.stop()
	elif name == "GoldenFreddy":
		golden_freddy_active = false
		golden_freddy_location = "Hidden"
		locations["GoldenFreddy"] = "Hidden"
		if office_full_scene_occupant == "GoldenFreddy":
			office_full_scene_occupant = ""
		update_hallway_state()
	if name == "Mangle": 
		print("AIManager: Reseteando Mangle desde la ventila")
		if has_node("MangleVentTimer"): $MangleVentTimer.stop()
	if old_loc == "Hallway":
		update_hallway_state()
	update_camera_visuals(old_loc, reset_loc, name)
	print("AIManager: ===== RESETEO COMPLETO =====")

func on_cameras_lowered():
	
	right_vent_attack_timer.stop()
	left_vent_attack_timer.stop()
	
	if golden_freddy_pending_entry:
		print("AIManager: Monitor bajado -> ¡APARECE GOLDEN FREDDY!")
		golden_freddy_pending_entry = false
		activate_golden_freddy_office()
		
	
	if withered_bonnie_is_doomed:
		check_mask_and_attack("WitheredBonnie")
		return 
	if withered_chica_is_doomed:
		check_mask_and_attack("WitheredChica")
		return
	if withered_freddy_is_doomed:
		check_mask_and_attack("WitheredFreddy")
		return
	if toy_freddy_is_doomed:
		check_mask_and_attack("ToyFreddy")
		return
	
	if toy_bonnie_attack_pending:
		check_mask_and_attack("ToyBonnie")
		return 
	
	if toy_chica_attack_pending:
		check_mask_and_attack("ToyChica")
		return
	
	if mangle_inside_office:
		if randi_range(1, 10) <= 2: 
			trigger_jumpscare("Mangle")
			return
	
	if mangle_entry_pending:
		print("AIManager: Monitor bajado. Mangle ahora es hostil.")
		mangle_inside_office = true
		mangle_entry_pending = false
	
func on_cameras_raised():
	if locations.get("GoldenFreddy") == "Hallway":
		print("AIManager: Monitor subido -> Golden Freddy abandona el pasillo.")
		reset_animatronic("GoldenFreddy")
	
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
		
	if location_locks["LeftVent"] == "BB":
		print("AIManager: Monitor subido con BB en ventila. ¡ENTRANDO!")
		bb_enters_office()

		
func check_mask_and_attack(animatronic_name: String):
	print("AIManager: ===== CHECK_MASK_AND_ATTACK para %s =====" % animatronic_name)
	print("AIManager: Ubicación actual: %s" % locations[animatronic_name])
	
	if office_node.is_mask_on(animatronic_name):
		print("AIManager: ¡Ataque de %s bloqueado por la máscara!" % animatronic_name)
	else:
		print("AIManager: ¡JUMPSCARE DE %s!" % animatronic_name)
		trigger_jumpscare(animatronic_name)
	
	if animatronic_name == "ToyBonnie":
		toy_bonnie_attack_pending = false
	elif animatronic_name == "ToyChica":
		toy_chica_attack_pending = false
	
	print("AIManager: ===== CHECK_MASK_AND_ATTACK COMPLETADO =====")
	
func toy_freddy_enters_office():
	office_node.set_hall_occupant("Empty")
	if is_office_blocked_for("ToyFreddy"):
		print("AIManager: Toy Freddy NO PUEDE entrar - oficina ocupada")
		locations["ToyFreddy"] = "Hallway2"
		return
	
	locations["ToyFreddy"] = "Office"
	location_locks["Hallway2"] = null
	location_locks["Office"] = "ToyFreddy"

	office_node.force_cameras_down()
	office_node.set_office_occupant("ToyFreddy")
	
	office_full_scene_occupant = "ToyFreddy"

	office_attack_timer.start() 
	$OfficeMaskTimer.start() 
	
	toy_freddy_attack_pending = true
	toy_freddy_is_doomed = false
	toy_freddy_is_saved = false

func _on_office_attack_timer_timeout():
	if not toy_freddy_attack_pending:
		return
		
	office_node.set_office_occupant("Empty")
	if office_full_scene_occupant == "ToyFreddy":
		office_full_scene_occupant = ""
	
	
	if toy_freddy_is_saved:
		print("AIManager: Ejecutando reset de Toy Freddy.")
		reset_animatronic("ToyFreddy")
	elif toy_freddy_is_doomed:
		print("AIManager: Jugador condenado. Jumpscare pendiente.")
	else:
		if office_node.get_mask_state():
			reset_animatronic("ToyFreddy")
		else:
			trigger_jumpscare("ToyFreddy")
	toy_freddy_attack_pending = false
		

func update_parts_service_camera():
	var bonnie_here = locations.get("WitheredBonnie") == "CAM_08"
	var freddy_here = false
	var chica_here = locations.get("WitheredChica") == "CAM_08"  # ✅ ADDQ
	
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
	elif locations.get("WitheredChica") == "Office":
		office_node.stop_flicker_effect()
		withered_chica_attack_pending = false
	elif locations.get("WitheredFreddy") == "Office":
		office_node.stop_flicker_effect()
		withered_chica_attack_pending = false
	
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
	var w_freddy = locations.get("WitheredFreddy") == "Hallway"
	var golden = locations.get("GoldenFreddy") == "Hallway"
	
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
	if is_office_blocked_for("WitheredBonnie"):
		print("AIManager: WitheredBonnie NO PUEDE entrar - oficina ocupada")
		locations["WitheredBonnie"] = "CAM_05"
		return
	
	locations["WitheredBonnie"] = "Office"
	location_locks["LeftVent"] = null
	location_locks["Office"] = "WitheredBonnie"
	
	office_full_scene_occupant = "WitheredBonnie"
	
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
	foxy_d_counter = 0
	
	var all_gone = (has_left_service.get("WitheredBonnie", true) and has_left_service.get("WitheredChica", true) and has_left_service.get("WitheredFreddy", true))
	
	foxy_is_active_easteregg = all_gone
	
	update_hallway_state()
	update_camera_visuals("Hallway", "CAM_08", "Foxy")


func is_foxy_blocked() -> bool:
	if locations.get("ToyFreddy") == "Office":
		return true
	if locations.get("WitheredBonnie") == "Office":
		return true
	if locations.get("WitheredChica") == "Office":
		return true
	if locations.get("WitheredFreddy") == "Office":
		return true
	if mangle_inside_office:
		return true
	if locations.get("GoldenFreddy") == "Hallway":	
		return true
	if locations.get("WitheredFreddy") == "Hallway":
		return true
	if locations.get("ToyFreddy") == "Hallway":
		return true
	if locations.get("ToyFreddy") == "Hallway2":
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
	
	if office_full_scene_occupant == "WitheredBonnie":
		office_full_scene_occupant = ""

	if withered_bonnie_is_saved:
		print("AIManager: Ejecutando reset de Withered Bonnie.")
		reset_animatronic("WitheredBonnie")
	elif withered_bonnie_is_doomed:
		print("AIManager: Jugador condenado. Jumpscare pendiente.")
	else:
	
		if office_node.get_mask_state():
			reset_animatronic("WitheredBonnie")
		else:
			trigger_jumpscare("WitheredBonnie")
	
	withered_bonnie_attack_pending = false

func is_withered_bonnie_doomed() -> bool:
	return withered_bonnie_is_doomed
	

func withered_chica_enters_office():
	print("AIManager: ===== WITHERED CHICA ENTRA A LA OFICINA =====")
	if is_office_blocked_for("WitheredChica"):
		print("AIManager: WitheredChica NO PUEDE entrar - oficina ocupada")
		locations["WitheredChica"] = "CAM_06"
		return

	office_full_scene_occupant = "WitheredChica"
	
	locations["WitheredChica"] = "Office"
	location_locks["RightVent"] = null
	location_locks["Office"] = "WitheredChica"

	if office_node.CAM_ON:
		office_node.force_cameras_down()

	office_node.set_vent_occupant("RightVent", "Empty")
	office_node.set_office_occupant("WitheredChica")

	office_node.start_flicker_effect()

	$WitheredChicaAttackTimer.start()   
	$WitheredChicaMaskTimer.start()      

	withered_chica_attack_pending = true
	withered_chica_is_doomed = false
	withered_chica_is_saved = false

func _on_withered_bonnie_mask_timer_timeout():
	if office_node.get_mask_state():
		print("AIManager: ¡Máscara puesta a tiempo! Jugador SALVADO (esperando fin de cinemática).")
		withered_bonnie_is_saved = true
		withered_bonnie_is_doomed = false
	else:
		print("AIManager: ¡Máscara NO puesta! Jugador CONDENADO.")
		withered_bonnie_is_saved = false
		withered_bonnie_is_doomed = true
		


func _on_withered_chica_attack_timer_timeout() -> void:
	if not withered_chica_attack_pending:
		return
	
	office_node.set_office_occupant("Empty")
	
	if office_full_scene_occupant == "WitheredChica":
		office_full_scene_occupant = ""
	
	if withered_chica_is_saved:
		print("AIManager: Ejecutando reset de Withered Chica.")
		reset_animatronic("WitheredChica")
	elif withered_chica_is_doomed:
		print("AIManager: Jugador condenado (Withered Chica). Jumpscare pendiente.")
	else:
		# Rare case: timer expired but no decision made
		if office_node.get_mask_state():
			reset_animatronic("WitheredChica")
		else:
			trigger_jumpscare("WitheredChica")
	withered_chica_attack_pending = false

# 8. ADD is_withered_chica_doomed() FUNCTION:
func is_withered_chica_doomed() -> bool:
	return withered_chica_is_doomed


func _on_withered_chica_mask_timer_timeout():
	if office_node.get_mask_state():
		print("AIManager: ¡Máscara puesta a tiempo! Jugador SALVADO (Withered Chica).")
		withered_chica_is_saved = true
		withered_chica_is_doomed = false
	else:
		print("AIManager: ¡Máscara NO puesta! Jugador CONDENADO (Withered Chica).")
		withered_chica_is_saved = false
		withered_chica_is_doomed = true
		
func withered_freddy_enters_office():
	print("AIManager: ===== WITHERED FREDDY ENTRA A LA OFICINA =====")
	if is_office_blocked_for("WitheredFreddy"):
		print("AIManager: Withered Freddy NO PUEDE entrar - oficina ocupada")
		locations["WitheredFreddy"] = "Hallway"  # Or wherever he comes from
		return
	
	locations["WitheredFreddy"] = "Office"
	location_locks["Hallway"] = null
	location_locks["Office"] = "WitheredFreddy"
	
	if office_node.CAM_ON:
		office_node.force_cameras_down()
	
	
	office_node.set_hall_occupant("Empty")
	office_node.set_office_occupant("WitheredFreddy")
	
	office_node.start_flicker_effect()
	
	
	if has_node("WitheredFreddyAttackTimer"): $WitheredFreddyAttackTimer.start()    
	if has_node("WitheredFreddyMaskTimer"): $WitheredFreddyMaskTimer.start() 
	
	withered_freddy_attack_pending = true
	withered_freddy_is_doomed = false
	withered_freddy_is_saved = false
	office_full_scene_occupant = "WitheredFreddy"

func _on_withered_freddy_mask_timer_timeout():
	if office_node.get_mask_state():
		print("AIManager: Máscara puesta a tiempo (Freddy). SALVADO.")
		withered_freddy_is_saved = true
		withered_freddy_is_doomed = false
	else:
		print("AIManager: Máscara NO puesta (Freddy). CONDENADO.")
		withered_freddy_is_saved = false
		withered_freddy_is_doomed = true

func _on_withered_freddy_attack_timer_timeout():
	if not withered_freddy_attack_pending: return
	
	office_node.set_office_occupant("Empty")
	
	if office_full_scene_occupant == "WitheredFreddy":
		office_full_scene_occupant = ""
	
	if withered_freddy_is_saved:
		print("AIManager: Reseteando Withered Freddy.")
		reset_animatronic("WitheredFreddy")
	elif withered_freddy_is_doomed:
		print("AIManager: Jumpscare pendiente (Freddy).")
	else:
		if office_node.get_mask_state():
			reset_animatronic("WitheredFreddy")
		else:
			trigger_jumpscare("WitheredFreddy")
	
	withered_freddy_attack_pending = false

func is_withered_freddy_doomed() -> bool:
	return withered_freddy_is_doomed
	
func is_office_blocked_for(animatronic_name: String) -> bool:
	var full_scene_animatronics = [
		"ToyFreddy",
		"WitheredBonnie", 
		"WitheredChica",
	    "WitheredFreddy"
	]
	if animatronic_name in full_scene_animatronics:
		if office_full_scene_occupant != "" and office_full_scene_occupant != animatronic_name:
			print("AIManager: %s bloqueado - %s ya está en la oficina" % [animatronic_name, office_full_scene_occupant])
			return true
	return false
	
func bb_enters_office():
	if bb_in_office: return 
	
	print("AIManager: ===== BALLOON BOY ENTRA A LA OFICINA =====")
	bb_in_office = true
	locations["BB"] = "Office"
	
	location_locks["LeftVent"] = null
	office_node.set_vent_occupant("LeftVent", "Empty")

	office_node.activate_bb_inside()
		

func spawn_golden_freddy():
	var where = "Office" if randf() < 0.7 else "Hallway"
	
	if where == "Office":
		print("AIManager: Golden Freddy prepara emboscada en Oficina (Pendiente).")
		golden_freddy_pending_entry = true
		
		
	elif where == "Hallway":
		print("AIManager: Golden Freddy aparece en el Pasillo.")
		locations["GoldenFreddy"] = "Hallway"
		update_hallway_state()

func activate_golden_freddy_office():
	locations["GoldenFreddy"] = "Office"
	office_full_scene_occupant = "GoldenFreddy"
	golden_freddy_active = true
	office_node.spawn_golden_freddy_office()
	
	golden_freddy_timer = golden_freddy_office_limit


func process_golden_freddy(delta):
	if not locations.has("GoldenFreddy"): return
	if not golden_freddy_active: return
	if golden_freddy_pending_entry: return
	
	if locations["GoldenFreddy"] == "Office":
		if office_node.get_mask_state():
			golden_freddy_active = false
			office_node.fade_out_golden_freddy(delta, false)
			return
		golden_freddy_timer -= delta
		if golden_freddy_timer <= 0:
			trigger_jumpscare("GoldenFreddy")

 

func trigger_jumpscare(anim_name: String):
	if game_over_triggered:
		return
		
	print("AIManager: Jumpscare confirmado de: ", anim_name)
	game_over_triggered = true

	stop() 
	
	emit_signal("jumpscare", anim_name)
