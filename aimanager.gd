# --- AIManager.gd ---
extends Control

signal jumpscare(animatronic_name)
signal animatronic_moved 

@onready var ai_tick_timer = $AITickTimer  # Should be set to 5.01 seconds in editor
@onready var right_vent_attack_timer = $RightVentAttackTimer  # Should be set to 17 seconds
@onready var left_vent_attack_timer = $LeftVentAttackTimer  # Should be set to 17 seconds

var camera_system: Control
var office_node: Control 

var toy_bonnie_attack_pending = false
var toy_chica_attack_pending = false

var aggression_levels = {}
var locations = {}

# Track if animatronics have LEFT the show stage
var has_left_stage = {
	"ToyBonnie": false,
	"ToyChica": false,
	"ToyFreddy": false
}

const RESET_LOCATIONS = {
	"ToyBonnie": "CAM_03",  # Vuelve a Party Room 3
	"ToyChica": "CAM_07",   # Vuelve al Main Hall
	"ToyFreddy": "CAM_09"   # El único que vuelve al Show Stage
	# (Añadiremos más aquí)
}

# Track who's at each camera (for shared cameras)
var camera_content_tracker = {}

var location_locks = {
	"RightVent": null,
	"LeftVent": null,
	"Hallway": null,
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
		"CAM_07": ["CAM_04", "Hallway"], # ¡BIFURCACIÓN! Ruta de Ventilación O Ruta de Pasillo
		"CAM_04": ["CAM_01"],          # -> Ruta de Ventilación
		"CAM_01": ["CAM_05"],        # -> Ruta de Ventilación
		"CAM_05": ["LeftVent"],
		"Hallway": ["CAM_07", "CAM_04"]          # -> Ataque de Pasillo
	},
	"ToyFreddy": {
		"CAM_09": ["CAM_10"], 
		"CAM_10": ["CAM_07"], 
		"CAM_07": ["Hallway"],
		"Hallway": ["Office"]
	}
}

func _ready():
	ai_tick_timer.timeout.connect(_on_ai_tick_timer_timeout)
	right_vent_attack_timer.timeout.connect(_on_right_vent_attack_timer_timeout)


func start_night(levels: Dictionary, cam_sys: Control, office: Control):
	aggression_levels = levels
	camera_system = cam_sys
	office_node = office 
	
	# Reset locations at night start
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
	
	camera_content_tracker = {}
	
	toy_bonnie_attack_pending = false
	toy_chica_attack_pending = false
	
	# Show all animatronics on stage initially
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
	var next_loc: String # Declaramos la variable vacía

	# --- LÓGICA DE MOVIMIENTO ---
	var next_loc_options = PATHS[name].get(current_loc)
	
	# Si no hay opciones (llegó al final o es un error)
	if next_loc_options == null or next_loc_options.is_empty():
		print("AIManager: %s no tiene siguiente ubicación desde %s" % [name, current_loc])
		return
	
	# ¡Elige un camino al azar de las opciones!
	next_loc = next_loc_options.pick_random()
	# --- FIN DE LA LÓGICA DE MOVIMIENTO ---
	
	print("AIManager: %s intentando moverse de %s a %s" % [name, current_loc, next_loc])

	# (El resto de tu lógica de 'Special rule' (cola del stage) es perfecta)
	if name == "ToyChica" and current_loc == "CAM_09":
		if not has_left_stage["ToyBonnie"]:
			print("AIManager: Toy Chica no puede salir - Toy Bonnie aún no se ha ido")
			return
	if name == "ToyFreddy" and current_loc == "CAM_09":
		if not has_left_stage["ToyBonnie"] or not has_left_stage["ToyChica"]:
			print("AIManager: Toy Freddy no puede salir - otros animatrónicos aún en el escenario")
			return
	
	# (El resto de tu lógica de 'location_locks' es perfecta)
	if location_locks.has(next_loc):
		if location_locks[next_loc] != null:
			print("AIManager: %s está bloqueado por %s" % [next_loc, location_locks[next_loc]])
			return
	
	# (El resto de tu función para actualizar cámaras y oficina es perfecto)
	# Unlock current location (only if it's a locked location)
	if location_locks.has(current_loc):
		location_locks[current_loc] = null
	
	# Lock next location (only if it's a lockable location)
	if location_locks.has(next_loc):
		location_locks[next_loc] = name
	
	# Mark as having left the stage
	if current_loc == "CAM_09":
		has_left_stage[name] = true
	
	locations[name] = next_loc
	emit_signal("animatronic_moved")
	update_camera_visuals(current_loc, next_loc, name)
	
	# Notify office of animatronic positions
	if next_loc == "LeftVent":
		office_node.set_vent_occupant("LeftVent", name)
	elif next_loc == "RightVent":
		office_node.set_vent_occupant("RightVent", name)
	elif next_loc == "Hallway":
		office_node.set_hall_occupant(name)
	
	# Start attack timers
	if next_loc == "RightVent" and name == "ToyBonnie":
		right_vent_attack_timer.start()
	elif next_loc == "LeftVent" and name == "ToyChica":
		left_vent_attack_timer.start()

func update_camera_visuals(old_loc, new_loc, name):
	print("DEBUG: Actualizando visuales - %s movió de %s a %s" % [name, old_loc, new_loc])
	
	# Clear old office notification FIRST if it was in a special location
	if old_loc == "Hallway":
		print("DEBUG: Limpiando Hallway de la oficina (animatronic se fue)")
		office_node.set_hall_occupant("Empty")
	elif old_loc == "LeftVent":
		print("DEBUG: Limpiando LeftVent de la oficina (animatronic se fue)")
		office_node.set_vent_occupant("LeftVent", "Empty")
	elif old_loc == "RightVent":
		print("DEBUG: Limpiando RightVent de la oficina (animatronic se fue)")
		office_node.set_vent_occupant("RightVent", "Empty")
	
	# Clear old camera location - BUT handle shared cameras!
	if old_loc != "CAM_09" and old_loc not in ["LeftVent", "RightVent", "Hallway", "Office"]:
		# Check if another animatronic is at this camera
		var someone_else_here = false
		for other_name in locations.keys():
			if other_name != name and locations[other_name] == old_loc:
				print("DEBUG: %s también está en %s, no limpiar" % [other_name, old_loc])
				someone_else_here = true
				# Update camera to show the other animatronic
				camera_system.set_camera_content(old_loc, other_name)
				break
		
		if not someone_else_here:
			print("DEBUG: Limpiando cámara antigua: %s" % old_loc)
			camera_system.set_camera_content(old_loc, "Empty")
	
	# Update CAM_09 (Show Stage) based on who's LEFT on stage
	if old_loc == "CAM_09" or new_loc == "CAM_09":
		update_show_stage()
	
	# Show animatronic at NEW location (if it's a camera)
	if new_loc not in ["CAM_09", "LeftVent", "RightVent", "Hallway", "Office"]:
		# Check if someone is already at this camera (shared camera)
		var current_occupant = camera_content_tracker.get(new_loc, "Empty")
		if current_occupant != "Empty" and current_occupant != name:
			print("DEBUG: %s ya está en %s, %s también aparece aquí (cámara compartida)" % [current_occupant, new_loc, name])
			# For shared cameras, we could show "Multiple" or just the newest one
			# In FNAF 2, usually shows the newest arrival
			camera_system.set_camera_content(new_loc, name)
		else:
			print("DEBUG: Mostrando %s en cámara: %s" % [name, new_loc])
			camera_system.set_camera_content(new_loc, name)
		
		# Track who's at this camera
		camera_content_tracker[new_loc] = name

func update_show_stage():
	# Determine what to show based on the EXACT order: All -> ToyBonnie Left -> ToyBonnie+ToyChica Left -> ToyFreddy Left -> Empty
	var bonnie_on_stage = locations["ToyBonnie"] == "CAM_09"
	var chica_on_stage = locations["ToyChica"] == "CAM_09"
	var freddy_on_stage = locations["ToyFreddy"] == "CAM_09"
	
	print("DEBUG Show Stage: Bonnie=%s, Chica=%s, Freddy=%s" % [bonnie_on_stage, chica_on_stage, freddy_on_stage])
	
	if bonnie_on_stage and chica_on_stage and freddy_on_stage:
		# All three on stage
		print("DEBUG: Mostrando TODOS en el escenario")
		camera_system.set_camera_content("CAM_09", "All")
	elif not bonnie_on_stage and chica_on_stage and freddy_on_stage:
		# Only Toy Bonnie left
		print("DEBUG: Toy Bonnie se fue - Mostrando Chica+Freddy")
		camera_system.set_camera_content("CAM_09", "ToyChica_ToyFreddy")
	elif not bonnie_on_stage and not chica_on_stage and freddy_on_stage:
		# Toy Bonnie AND Toy Chica left
		print("DEBUG: Bonnie y Chica se fueron - Mostrando solo Freddy")
		camera_system.set_camera_content("CAM_09", "ToyFreddy")
	elif not bonnie_on_stage and not chica_on_stage and not freddy_on_stage:
		# All gone
		print("DEBUG: Todos se fueron - Escenario vacío")
		camera_system.set_camera_content("CAM_09", "Empty")
	else:
		# Shouldn't happen with proper logic, but just in case
		print("DEBUG: Estado inesperado - Mostrando vacío")
		camera_system.set_camera_content("CAM_09", "Empty")

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
	print("AIManager: Ubicación antigua de %s: %s" % [name, old_loc])
	
	if old_loc not in ["RightVent", "LeftVent", "Hallway"]:
		print("AIManager: ADVERTENCIA - %s no está en una posición de ataque (%s), cancelando reset" % [name, old_loc])
		return
	
	# --- LÓGICA DE RESETEO MODIFICADA ---
	
	# 1. Obtiene la nueva ubicación de reseteo
	var reset_loc = RESET_LOCATIONS.get(name, "CAM_09") # Vuelve a CAM_09 si no se encuentra
	locations[name] = reset_loc
	print("AIManager: %s ahora está en %s (locations actualizado)" % [name, reset_loc])
	
	# 2. Limpia el rastreador de cámaras
	if camera_content_tracker.has(old_loc):
		camera_content_tracker.erase(old_loc)
	
	# 3. Limpia el bloqueo de ubicación
	if location_locks.has(old_loc):
		print("AIManager: Desbloqueando: %s" % old_loc)
		location_locks[old_loc] = null
	
	# 4. Resetea las banderas de ataque
	if name == "ToyBonnie":
		print("AIManager: Reseteando flags de ataque de Toy Bonnie")
		toy_bonnie_attack_pending = false
		right_vent_attack_timer.stop()
	elif name == "ToyChica":
		print("AIManager: Reseteando flags de ataque de Toy Chica")
		toy_chica_attack_pending = false
		left_vent_attack_timer.stop()
		
	# 5. Limpia la oficina
	if old_loc == "RightVent":
		print("AIManager: Limpiando RightVent de la oficina")
		office_node.set_vent_occupant("RightVent", "Empty")
	elif old_loc == "LeftVent":
		print("AIManager: Limpiando LeftVent de la oficina")
		office_node.set_vent_occupant("LeftVent", "Empty")
	elif old_loc == "Hallway":
		print("AIManager: Limpiando Hallway de la oficina")
		office_node.set_hall_occupant("Empty")
	
	# 6. Si es Toy Freddy, resetea el estado del escenario
	if name == "ToyFreddy":
		has_left_stage[name] = false
		# (Opcional: podrías añadirlo de nuevo a la cola del stage si quieres)
		# if not "ToyFreddy" in location_locks["CAM_09_Queue"]:
		# 	location_locks["CAM_09_Queue"].push_back(name)
	
	# 7. Actualiza las cámaras
	update_camera_visuals(old_loc, reset_loc, name)
	print("AIManager: ===== RESETEO COMPLETO =====")

func on_cameras_lowered():
	# Pause all attack timers
	right_vent_attack_timer.stop()
	left_vent_attack_timer.stop()
	
	# Check for pending attacks (INSTANT JUMPSCARE!)
	if toy_bonnie_attack_pending:
		check_mask_and_attack("ToyBonnie") 
	
	if toy_chica_attack_pending:
		check_mask_and_attack("ToyChica")
	
func on_cameras_raised():
	# If Toy Bonnie is waiting, start timer
	if location_locks["RightVent"] == "ToyBonnie":
		right_vent_attack_timer.start()
		
	# If Toy Chica is waiting, start timer
	if location_locks["LeftVent"] == "ToyChica":
		left_vent_attack_timer.start()
		
func check_mask_and_attack(animatronic_name: String):
	print("AIManager: ===== CHECK_MASK_AND_ATTACK para %s =====" % animatronic_name)
	print("AIManager: Ubicación actual: %s" % locations[animatronic_name])
	
	# Ask office if mask is on AND if it works!
	if office_node.is_mask_on(animatronic_name):
		# SAVED! Office will handle the reset
		print("AIManager: ¡Ataque de %s bloqueado por la máscara!" % animatronic_name)
		# Don't reset here - let the office/cinematic handle it
	else:
		# JUMPSCARE!
		print("AIManager: ¡JUMPSCARE DE %s!" % animatronic_name)
		emit_signal("jumpscare", animatronic_name)
	
	# Reset attack flags
	if animatronic_name == "ToyBonnie":
		toy_bonnie_attack_pending = false
	elif animatronic_name == "ToyChica":
		toy_chica_attack_pending = false
	
	print("AIManager: ===== CHECK_MASK_AND_ATTACK COMPLETADO =====")

func stop():
	ai_tick_timer.stop()
	right_vent_attack_timer.stop()
	left_vent_attack_timer.stop()
	set_process(false) # Detiene su _process si lo tuviera
