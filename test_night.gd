extends Control

# --- Node References ---
@onready var officeBG = $MaskView/OfficeBG
@onready var leftBtn = $LeftMove
@onready var rightBtn = $RightMove
@onready var desk = $MaskView/desk
@onready var maskAnim = $FreddyMask
@onready var monitorAnim = $Monitor
@onready var camera_system = $Cameras
@onready var ai_manager = $ai_manager
@onready var flashlight_fail_timer = $FlashlightFailTimer
@onready var animatronic_slide_view = $Animatronic_Slide_View
@onready var office_darken_overlay = $OfficeDarkenOverlay

# --- Texture Exports ---
@export var desk_offset_x: float = 0.0
@export var parralax_factor_desk: float = 1.2

@export var toy_bonnie_slide_texture: Texture2D
@export var toy_chica_slide_texture: Texture2D

@export_group("Idle Mask Movement")
@export var idle_amplitude_x: float = 8.0
@export var idle_amplitude_y: float = 4.0
@export var idle_speed: float = 1.0

@export_group("Office Light Textures")
@export var office_dark_default: Texture2D
# Hallway
@export var office_lit_hall_empty: Texture2D
@export var office_lit_hall_fail: Texture2D
@export var office_lit_hall_toyfreddy: Texture2D
@export var office_lit_hall_toyfreddy2: Texture2D
@export var office_lit_hall_foxy: Texture2D
@export var office_lit_hall_mangle: Texture2D
@export var office_lit_hall_foxy_mangle: Texture2D
@export var office_lit_hall_witheredbonnie: Texture2D
@export var office_lit_hall_witheredbonnie_foxy: Texture2D
@export var office_lit_hall_witheredfreddy: Texture2D
@export var office_lit_hall_toyChica: Texture2D
@export var office_lit_hall_goldenFreddy: Texture2D
# Left Vent
@export var office_lit_left_empty: Texture2D
@export var office_lit_left_toychica: Texture2D
@export var office_lit_left_bb: Texture2D
# Right Vent
@export var office_lit_right_empty: Texture2D
@export var office_lit_right_toybonnie: Texture2D
@export var office_lit_right_mangle: Texture2D

# --- State Variables ---
var hall_light_textures = {}
var left_vent_light_textures = {}
var right_vent_light_textures = {}

var right_vent_occupant = "Empty"
var left_vent_occupant = "Empty"
var hall_occupant = "Empty"

var is_flashlight_failing = false
const STROBE_ANIMATRONICS = ["Foxy", "WitheredBonnie", "WitheredChica", "WitheredFreddy"]

var widthScreen: float
var movementLim: float
var panSpeed = 400.0

var CAM_ON = false
var MASK_ON = false
var mask_is_fully_on = false
var idle_time_counter: float = 0.0
var initial_mask_pos: Vector2

var slide_tween: Tween
var is_playing_defense_cinematic = false

func _ready():
	await ready
	
	# Panning setup
	widthScreen = get_viewport_rect().size.x
	movementLim = officeBG.get_rect().size.x - widthScreen
	if movementLim <= 0:
		movementLim = 0
	desk.play("default")
	
	# Build light texture dictionaries
	hall_light_textures = {
		"Empty": office_lit_hall_empty,
		"Fail": office_lit_hall_fail,
		"ToyFreddy": office_lit_hall_toyfreddy,
		"ToyFreddy2": office_lit_hall_toyfreddy2,
		"Foxy": office_lit_hall_foxy,
		"Mangle": office_lit_hall_mangle,
		"Foxy_Mangle": office_lit_hall_foxy_mangle,
		"WitheredBonnie": office_lit_hall_witheredbonnie,
		"WitheredBonnie_Foxy": office_lit_hall_witheredbonnie_foxy,
		"WitheredFreddy": office_lit_hall_witheredfreddy,
		"ToyChica": office_lit_hall_toyChica,
		"GoldenFreddy": office_lit_hall_goldenFreddy
	}
	left_vent_light_textures = {
		"Empty": office_lit_left_empty,
		"ToyChica": office_lit_left_toychica,
		"BB": office_lit_left_bb
	}
	right_vent_light_textures = {
		"Empty": office_lit_right_empty,
		"ToyBonnie": office_lit_right_toybonnie,
		"Mangle": office_lit_right_mangle
	}
	
	if officeBG:
		officeBG.texture = office_dark_default
	
	initial_mask_pos = maskAnim.position
	
	# Setup darken overlay (create if doesn't exist)
	if not office_darken_overlay:
		office_darken_overlay = ColorRect.new()
		office_darken_overlay.name = "OfficeDarkenOverlay"
		add_child(office_darken_overlay)
	
	office_darken_overlay.color = Color(0, 0, 0, 0)
	office_darken_overlay.size = get_viewport_rect().size
	office_darken_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	office_darken_overlay.z_index = 10
	office_darken_overlay.hide()
	
	flashlight_fail_timer.timeout.connect(_on_flashlight_fail_timer_timeout)
	
	# START THE AI!
	var night_1_levels = {
		"ToyBonnie": 5,
		"ToyChica": 5,
		"ToyFreddy": 0
	}
	ai_manager.start_night(night_1_levels, camera_system, self)

func _process(delta):
	# Office panning logic
	if not MASK_ON and not CAM_ON and not is_playing_defense_cinematic:
		if leftBtn.is_pressed():
			officeBG.position.x += panSpeed * delta
		if rightBtn.is_pressed():
			officeBG.position.x -= panSpeed * delta
		officeBG.position.x = clamp(officeBG.position.x, -movementLim + 5, -5)
		desk.position.x = (officeBG.position.x * parralax_factor_desk) + desk_offset_x
		$LeftLight.position.x = (officeBG.position.x) + 100
		$RightLight.position.x = (officeBG.position.x) + 1425
	
	# Idle mask movement
	if mask_is_fully_on and not is_playing_defense_cinematic:
		idle_time_counter += delta * idle_speed
		var offset_x = sin(idle_time_counter) * idle_amplitude_x
		var offset_y = cos(idle_time_counter * 2.0) * idle_amplitude_y
		maskAnim.position = initial_mask_pos + Vector2(offset_x, offset_y)

# --- Mask Logic ---
func _on_mask_button_pressed() -> void:
	if CAM_ON or is_playing_defense_cinematic:
		return
		
	MASK_ON = not MASK_ON
	maskAnim.show()
	
	if MASK_ON:
		mask_is_fully_on = false
		maskAnim.play("activate")
		var scale_tween = create_tween()
		scale_tween.tween_property(maskAnim, "scale:x", 1.2, 0.25)
		
		# Wait for mask animation to progress a bit
		await get_tree().create_timer(0.3).timeout
		
		# DEFENSE LOGIC - Check vents when mask is put on
		print("Office: Máscara puesta, revisando ventilaciones...")
		print("Office: RightVent ocupado por: %s" % right_vent_occupant)
		print("Office: LeftVent ocupado por: %s" % left_vent_occupant)
		
		# TOY BONNIE: Has slide cinematic
		if right_vent_occupant == "ToyBonnie":
			print("Office: ¡Toy Bonnie detectado en RightVent! Iniciando cinemática...")
			play_defense_cinematic("ToyBonnie", toy_bonnie_slide_texture)
		
		# TOY CHICA: NO cinematic, just instant reset
		elif left_vent_occupant == "ToyChica":
			print("Office: ¡Toy Chica detectada en LeftVent! Reseteando sin cinemática...")
			ai_manager.reset_animatronic("ToyChica")
			print("Office: Reset de Toy Chica completado")
		
		# BB: Special, doesn't leave
		elif left_vent_occupant == "BB":
			print("Office: BB detectado (no hace nada)")
			pass
		else:
			print("Office: No hay nadie en las ventilaciones")
	else:
		mask_is_fully_on = false 
		maskAnim.position = initial_mask_pos 
		maskAnim.play("deactivate")
		var scale_tween = create_tween()
		scale_tween.tween_property(maskAnim, "scale:x", 1.0, 0.25)

func _on_freddy_mask_animation_finished() -> void:
	if MASK_ON:
		mask_is_fully_on = true
		idle_time_counter = 0.0 
	else:
		maskAnim.hide()

# --- Defense Cinematic (Slow like FNAF 2) ---
func play_defense_cinematic(animatronic_name: String, slide_texture: Texture2D):
	if is_playing_defense_cinematic:
		print("Office: Ya hay una cinemática en progreso, cancelando...")
		return
	
	is_playing_defense_cinematic = true
	print("Office: ===== INICIANDO CINEMÁTICA DE %s =====" % animatronic_name)
	
	# 1. Darken the office gradually
	office_darken_overlay.show()
	var darken_tween = create_tween()
	darken_tween.tween_property(office_darken_overlay, "color:a", 0.75, 0.5)
	await darken_tween.finished
	print("Office: Oficina oscurecida")
	
	# 2. Setup slide texture
	animatronic_slide_view.texture = slide_texture
	animatronic_slide_view.position.x = get_viewport_rect().size.x # Start off-screen right
	animatronic_slide_view.modulate.a = 1.0
	animatronic_slide_view.z_index = 15 # Above everything
	animatronic_slide_view.visible = true
	print("Office: Iniciando deslizamiento de %s" % animatronic_name)
	
	# 3. SLOW slide across office (4 seconds like original)
	slide_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	slide_tween.tween_property(animatronic_slide_view, "position:x", -animatronic_slide_view.size.x, 4.0)
	await slide_tween.finished
	print("Office: Deslizamiento completado")
	
	# 4. Hide animatronic
	animatronic_slide_view.hide()
	
	# 5. Brighten office again
	var brighten_tween = create_tween()
	brighten_tween.tween_property(office_darken_overlay, "color:a", 0.0, 0.5)
	await brighten_tween.finished
	office_darken_overlay.hide()
	print("Office: Oficina iluminada de nuevo")
	
	# 6. Reset animatronic in AI - THIS IS CRITICAL!
	print("Office: Llamando a reset_animatronic para %s" % animatronic_name)
	ai_manager.reset_animatronic(animatronic_name)
	
	# Force update the office background if lights were on
	if not is_flashlight_failing:
		officeBG.texture = office_dark_default
	
	# Small delay to ensure reset completes
	await get_tree().create_timer(0.1).timeout
	
	is_playing_defense_cinematic = false
	print("Office: ===== CINEMÁTICA COMPLETADA =====")

# --- Light Logic ---
func _on_left_light_button_down() -> void:
	if MASK_ON or is_flashlight_failing or is_playing_defense_cinematic:
		return
	print("Office: Luz izquierda - Mostrando: %s" % left_vent_occupant)
	officeBG.texture = left_vent_light_textures.get(left_vent_occupant, office_lit_left_empty)

func _on_left_light_button_up() -> void:
	if not is_playing_defense_cinematic:
		officeBG.texture = office_dark_default

func _on_right_light_button_down() -> void:
	if MASK_ON or is_flashlight_failing or is_playing_defense_cinematic:
		return
	print("Office: Luz derecha - Mostrando: %s" % right_vent_occupant)
	officeBG.texture = right_vent_light_textures.get(right_vent_occupant, office_lit_right_empty)

func _on_right_light_button_up() -> void:
	if not is_playing_defense_cinematic:
		officeBG.texture = office_dark_default

func _on_hall_light_button_down() -> void:
	if MASK_ON or is_flashlight_failing or is_playing_defense_cinematic:
		return
	
	print("Office: Luz del pasillo - Mostrando: %s" % hall_occupant)
	
	if hall_occupant in STROBE_ANIMATRONICS:
		is_flashlight_failing = true
		officeBG.texture = hall_light_textures["Fail"]
		flashlight_fail_timer.start()
		ai_manager.on_hall_flashlight_success(hall_occupant)
	else:
		officeBG.texture = hall_light_textures.get(hall_occupant, office_lit_hall_empty)

func _on_hall_light_button_up() -> void:
	if is_flashlight_failing or is_playing_defense_cinematic:
		return
	officeBG.texture = office_dark_default

func _on_flashlight_fail_timer_timeout():
	is_flashlight_failing = false
	if not is_playing_defense_cinematic:
		officeBG.texture = office_dark_default

# --- Camera Logic ---
func _on_camera_toggle_pressed() -> void:
	if MASK_ON or is_playing_defense_cinematic:
		return
		
	CAM_ON = not CAM_ON
	monitorAnim.show()
	
	if CAM_ON:
		monitorAnim.play("monitorOn")
	else:
		ai_manager.on_cameras_lowered() 
		camera_system.hide()
		monitorAnim.play("monitorOff")

func _on_monitor_animation_finished() -> void:
	if CAM_ON and monitorAnim.animation == "monitorOn":
		camera_system.show()
		ai_manager.on_cameras_raised() 
	elif not CAM_ON and monitorAnim.animation == "monitorOff":
		monitorAnim.hide()

# --- PUBLIC FUNCTIONS (For AIManager to call) ---
func is_mask_on(animatronic_name: String) -> bool:
	if not mask_is_fully_on:
		return false
	
	if animatronic_name == "ToyBonnie":
		var chance = randi_range(1, 3)
		if chance == 1: # 33% success rate with mask
			print("Office: ¡La máscara funcionó contra Toy Bonnie!")
			play_defense_cinematic("ToyBonnie", toy_bonnie_slide_texture)
			return true
		else:
			print("Office: ¡La máscara falló contra Toy Bonnie!")
			return false
			
	elif animatronic_name == "ToyChica":
		print("Office: ¡La máscara funcionó contra Toy Chica! (sin cinemática)")
		# Toy Chica just gets reset instantly, no cinematic
		ai_manager.reset_animatronic("ToyChica")
		return true # Toy Chica is always fooled
	
	return true

func set_hall_occupant(occupant_name: String):
	print("Office: Pasillo cambiando de '%s' a '%s'" % [hall_occupant, occupant_name])
	hall_occupant = occupant_name
	print("Office: ===== Pasillo ahora ocupado por: '%s' =====" % hall_occupant)

func set_vent_occupant(vent_name: String, occupant_name: String):
	if vent_name == "LeftVent":
		print("Office: Ventilación Izquierda cambiando de '%s' a '%s'" % [left_vent_occupant, occupant_name])
		left_vent_occupant = occupant_name
		print("Office: ===== Ventilación Izquierda ahora ocupada por: '%s' =====" % left_vent_occupant)
	elif vent_name == "RightVent":
		print("Office: Ventilación Derecha cambiando de '%s' a '%s'" % [right_vent_occupant, occupant_name])
		right_vent_occupant = occupant_name
		print("Office: ===== Ventilación Derecha ahora ocupada por: '%s' =====" % right_vent_occupant)
