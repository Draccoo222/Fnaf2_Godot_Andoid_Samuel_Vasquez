# --- AIManager.gd ---
extends Control

signal jumpscare(animatronic_name)
signal animatronic_moved 

@onready var ai_tick_timer = $AITickTimer
@onready var right_vent_attack_timer = $RightVentAttackTimer
@onready var left_vent_attack_timer = $LeftVentAttackTimer

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

var location_locks = {
	"RightVent": null,
	"LeftVent": null,
	"Hallway": null,
	"Office": null
}

const PATHS = {
	"ToyBonnie": {
		"CAM_09": "CAM_03", 
		"CAM_03": "CAM_04", 
		"CAM_04": "CAM_02",
		"CAM_02": "CAM_06", 
		"CAM_06": "RightVent", 
		"RightVent": "Office"
	},
	"ToyChica": {
		"CAM_09": "CAM_07", 
		"CAM_07": "CAM_05", 
		"CAM_05": "CAM_03",
		"CAM_03": "CAM_01", 
		"CAM_01": "LeftVent", 
		"LeftVent": "Office"
	},
	"ToyFreddy": {
		"CAM_09": "CAM_10", 
		"CAM_10": "CAM_07", 
		"CAM_07": "Hallway",
		"Hallway": "Office"
	}
}

func _ready():
	ai_tick_timer.timeout.connect(_on_ai_tick_timer_timeout)
	right_vent_attack_timer.timeout.connect(_on_right_vent_attack_timer_timeout)
	left_vent_attack_timer.timeout.connect(_on_left_vent_attack_timer_timeout)

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
	var next_loc = PATHS[name].get(current_loc)
	
	if next_loc == null:
		return 
	
	# Special rule: Toy Chica can only leave if Toy Bonnie has already left
	if name == "ToyChica" and current_loc == "CAM_09":
		if not has_left_stage["ToyBonnie"]:
			return
	
	# Special rule: Toy Freddy can only leave if both have left
	if name == "ToyFreddy" and current_loc == "CAM_09":
		if not has_left_stage["ToyBonnie"] or not has_left_stage["ToyChica"]:
			return
	
	# Check if next location is locked
	if location_locks.has(next_loc):
		if location_locks[next_loc] != null:
			return
	
	# Unlock current location
	if location_locks.has(current_loc):
		location_locks[current_loc] = null
	
	# Lock next location
	if location_locks.has(next_loc):
		location_locks[next_loc] = name
	
	# Mark as having left the stage
	if current_loc == "CAM_09":
		has_left_stage[name] = true
	
	locations[name] = next_loc
	print("AIManager: ¡%s se movió de %s a %s!" % [name, current_loc, next_loc])
	emit_signal("animatronic_moved")
	update_camera_visuals(current_loc, next_loc, name)
	
	# Notify office of animatronic positions
	if next_loc == "LeftVent" or next_loc == "RightVent":
		office_node.set_vent_occupant(next_loc, name)
	elif next_loc == "Hallway":
		office_node.set_hall_occupant(name)
	
	# Start attack timers
	if next_loc == "RightVent" and name == "ToyBonnie":
		right_vent_attack_timer.start()
	elif next_loc == "LeftVent" and name == "ToyChica":
		left_vent_attack_timer.start()

func update_camera_visuals(old_loc, new_loc, name):
	# For CAM_09 (Show Stage), we need special logic
	if old_loc == "CAM_09":
		# Show who's LEFT on stage
		var remaining = []
		for anim_name in ["ToyBonnie", "ToyChica", "ToyFreddy"]:
			if locations[anim_name] == "CAM_09":
				remaining.append(anim_name)
		
		if remaining.size() == 3:
			camera_system.set_camera_content("CAM_09", "All")
		elif remaining.size() == 2:
			# Show the two remaining
			var content = remaining[0] + "_" + remaining[1]
			camera_system.set_camera_content("CAM_09", content)
		elif remaining.size() == 1:
			camera_system.set_camera_content("CAM_09", remaining[0])
		else:
			camera_system.set_camera_content("CAM_09", "Empty")
	
	# For other cameras, show who just ARRIVED
	if new_loc != "CAM_09" and new_loc not in ["LeftVent", "RightVent", "Hallway", "Office"]:
		camera_system.set_camera_content(new_loc, name)
	
	# Clear the old location (if not CAM_09)
	if old_loc != "CAM_09" and old_loc not in ["LeftVent", "RightVent", "Hallway", "Office"]:
		camera_system.set_camera_content(old_loc, "Empty")

func on_hall_flashlight_success(occupant_name: String):
	print("AIManager: ¡El flash en %s funcionó!" % occupant_name)
	
	locations[occupant_name] = "CAM_08"
	location_locks["Hallway"] = null
	
	office_node.set_hall_occupant("Empty")
	
	update_camera_visuals("Hallway", "CAM_08", occupant_name)

func _on_right_vent_attack_timer_timeout():
	if location_locks["RightVent"] == "ToyBonnie":
		print("AIManager: ¡Ataque de Toy Bonnie PENDIENTE!")
		toy_bonnie_attack_pending = true

func _on_left_vent_attack_timer_timeout():
	if location_locks["LeftVent"] == "ToyChica":
		print("AIManager: ¡Ataque de Toy Chica PENDIENTE!")
		toy_chica_attack_pending = true

func reset_animatronic(name: String):
	var old_loc = locations[name] 
	
	if location_locks.has(old_loc):
		location_locks[old_loc] = null
	
	locations[name] = "CAM_09"
	
	if old_loc == "RightVent":
		office_node.set_vent_occupant("RightVent", "Empty")
	elif old_loc == "LeftVent":
		office_node.set_vent_occupant("LeftVent", "Empty")
	elif old_loc == "Hallway":
		office_node.set_hall_occupant("Empty")

	update_camera_visuals(old_loc, "CAM_09", name)

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
	# Ask office if mask is on AND if it works!
	if office_node.is_mask_on(animatronic_name):
		# SAVED!
		print("AIManager: ¡Ataque de %s bloqueado por la máscara!" % animatronic_name)
		reset_animatronic(animatronic_name)
	else:
		# JUMPSCARE!
		print("AIManager: ¡JUMPSCARE DE %s!" % animatronic_name)
		emit_signal("jumpscare", animatronic_name)
	
	# Reset attack flag
	if animatronic_name == "ToyBonnie":
		toy_bonnie_attack_pending = false
	elif animatronic_name == "ToyChica":
		toy_chica_attack_pending = false
