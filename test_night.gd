extends Control

@onready var officeBG = $MaskView/OfficeBG
@onready var leftBtn = $LeftMove
@onready var rightBtn = $RightMove
@onready var desk = $MaskView/desk
@onready var maskAnim = $FreddyMask
@onready var monitorAnim = $Monitor
@onready var camera_system = $Cameras
@onready var ai_manager = $ai_manager
@onready var flashlight_fail_timer = $FlashlightFailTimer
@onready var slide_view_right = $SlideView_Right
@onready var slide_view_left = $SlideView_Left
@onready var office_darken_overlay = $OfficeDarkenOverlay
@onready var jumpscare_player = $JumpscarePlayer
@onready var jumpscare_sound = $JumpscareSound
@onready var office_animatronic_view = $MaskView/OfficeAnimatronicView
@onready var office_flicker_timer = $OfficeFlickerTimer
@onready var hall_flicker_lock_timer = $HallFlickerLockTimer
@onready var mangle_ceiling_view = $MaskView/MangeGotYou
@onready var mangle_office_sound = $MaskView/MangleStatic

@export var desk_offset_x: float = 0.0
@export var parralax_factor_desk: float = 1.2

@export var toy_bonnie_slide_texture: Texture2D
@export var toy_chica_slide_texture: Texture2D

@export_group("Mangle Settings")
@export var mangle_parallax_factor: float = 1.05

@export_group("Idle Mask Movement")
@export var idle_amplitude_x: float = 8.0
@export var idle_amplitude_y: float = 4.0
@export var idle_speed: float = 1.0

@export_group("Toy Freddy Parallax")
@export var toy_freddy_parallax_factor: float = 1.1

@export_group("Office Light Textures")
@export var office_dark_default: Texture2D
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

@export_group("Office Animatronic Textures")
@export var office_img_toyfreddy: Texture2D

@export var office_lit_left_empty: Texture2D
@export var office_lit_left_toychica: Texture2D
@export var office_lit_left_bb: Texture2D
@export var office_lit_right_empty: Texture2D
@export var office_lit_right_toybonnie: Texture2D
@export var office_lit_right_mangle: Texture2D



var is_hall_light_on = false

var hall_light_textures = {}
var left_vent_light_textures = {}
var right_vent_light_textures = {}
var office_textures = {}

var right_vent_occupant = "Empty"
var left_vent_occupant = "Empty"
var hall_occupant = "Empty"
var office_occupant = "Empty"

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
var initial_toy_freddy_pos: Vector2

var initial_mangle_pos: Vector2

var is_flash_lock_active = false 

var flicker_tween: Tween 
var slide_tween_right: Tween
var slide_tween_left: Tween
var active_cinematics = 0

func _ready():
	await ready
	
	initial_mangle_pos = mangle_ceiling_view.position
	
	ai_manager.animatronic_moved.connect(camera_system.on_animatronic_moved)
	ai_manager.jumpscare.connect(_on_ai_manager_jumpscare)
	jumpscare_player.animation_finished.connect(_on_jumpscare_animation_finished)
	
	hall_flicker_lock_timer.timeout.connect(_on_hall_flicker_lock_timer_timeout)
	
	widthScreen = get_viewport_rect().size.x
	movementLim = officeBG.get_rect().size.x - widthScreen
	if movementLim <= 0:
		movementLim = 0
	desk.play("default")
	
	hall_light_textures = {
		"Empty": office_lit_hall_empty,
		"Fail": office_lit_hall_fail,
		"ToyFreddy_Far": office_lit_hall_toyfreddy,
		"ToyFreddy_Close": office_lit_hall_toyfreddy2,
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
	office_textures = {
		"ToyFreddy": office_img_toyfreddy
	}
	
	if officeBG:
		officeBG.texture = office_dark_default
	
	initial_mask_pos = maskAnim.position
	initial_toy_freddy_pos = office_animatronic_view.position
	
	if not office_darken_overlay:
		office_darken_overlay = ColorRect.new()
		office_darken_overlay.name = "OfficeDarkenOverlay"
		add_child(office_darken_overlay)
		
	office_darken_overlay.color = Color(0, 0, 0, 0)
	office_darken_overlay.size = get_viewport_rect().size
	office_darken_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	office_darken_overlay.z_index = 10
	office_darken_overlay.hide()
	
	var vp_size = get_viewport_rect().size
	
	
	office_darken_overlay.size = vp_size * 1.2
	
	office_darken_overlay.position = -vp_size * 0.1
	
	flashlight_fail_timer.timeout.connect(_on_flashlight_fail_timer_timeout)
	office_flicker_timer.timeout.connect(_on_office_flicker_timer_timeout)
	
	var night_1_levels = {
		"ToyBonnie": 0,
		"ToyChica": 0,
		"ToyFreddy": 0,
		"Mangle": 0,
		"Foxy": 20
	}
	ai_manager.start_night(night_1_levels, camera_system, self)

func _process(delta):
	if not CAM_ON:
		if leftBtn.is_pressed():
			officeBG.position.x += panSpeed * delta
		if rightBtn.is_pressed():
			officeBG.position.x -= panSpeed * delta
		officeBG.position.x = clamp(officeBG.position.x, -movementLim + 5, -5)
		desk.position.x = (officeBG.position.x * parralax_factor_desk) + desk_offset_x
		$LeftLight.position.x = (officeBG.position.x) + 100
		$RightLight.position.x = (officeBG.position.x) + 1425
		
		if mangle_ceiling_view.visible:
			mangle_ceiling_view.position.y = 0
			mangle_ceiling_view.position.x = (officeBG.position.x * mangle_parallax_factor) + initial_mangle_pos.x + 220
			
		
		if office_occupant == "ToyFreddy":
			office_animatronic_view.position.y = -75
			office_animatronic_view.position.x = (officeBG.position.x * toy_freddy_parallax_factor) + initial_toy_freddy_pos.x + 850
	
	if mask_is_fully_on:
		idle_time_counter += delta * idle_speed
		var offset_x = sin(idle_time_counter) * idle_amplitude_x
		var offset_y = cos(idle_time_counter * 2.0) * idle_amplitude_y
		maskAnim.position = initial_mask_pos + Vector2(offset_x, offset_y)
	

func _on_mask_button_pressed() -> void:
	if CAM_ON or active_cinematics > 0:
		return
		
	if ai_manager.is_toy_freddy_doomed() and MASK_ON == false: 
		pass	
		
	MASK_ON = not MASK_ON
	maskAnim.show()
	
	if MASK_ON:
		mask_is_fully_on = false
		maskAnim.play("activate")
		var scale_tween = create_tween()
		scale_tween.tween_property(maskAnim, "scale:x", 1.2, 0.25)
		$CameraToggle.hide()
		$LeftLight.hide()
		$RightLight.hide()
		$HallLight.hide()
		
		await get_tree().create_timer(0.3).timeout
		
		print("Office: Máscara puesta, revisando...")
		
		var cinematic_started = false
		
		if right_vent_occupant == "ToyBonnie":
			print("Office: ¡Toy Bonnie detectado! Iniciando cinemática...")
			play_defense_cinematic("ToyBonnie", toy_bonnie_slide_texture, slide_view_right, slide_tween_right, "right")
			ai_manager.reset_animatronic("ToyBonnie")
			cinematic_started = true
		
		if left_vent_occupant == "ToyChica":
			print("Office: ¡Toy Chica detectada! Iniciando cinemática...")
			play_defense_cinematic("ToyChica", toy_chica_slide_texture, slide_view_left, slide_tween_left, "left")
			ai_manager.reset_animatronic("ToyChica")
			cinematic_started = true
			
		elif right_vent_occupant == "Mangle":
			print("Office: ¡Mangle detectada en RightVent! Ahuyentándola con la máscara...")
			# Mangle no tiene cinemática de deslizamiento, solo se va (audio stop)
			ai_manager.reset_animatronic("Mangle")
			# Opcional: Reproducir sonido de estática disminuyendo o pasos
			
		if cinematic_started:
			start_flicker_effect()
		
		elif left_vent_occupant == "BB":
			print("Office: BB detectado (no hace nada)")
			pass
		else:
			print("Office: No hay nadie en las ventilaciones")
	else:
		$CameraToggle.show()	
		$LeftLight.show()
		$RightLight.show()
		$HallLight.show()
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
		if ai_manager.is_toy_freddy_doomed():
			print("Office: Animación terminada. Ejecutando Jumpscare retardado de Toy Freddy.")
			ai_manager.emit_signal("jumpscare", "ToyFreddy")

func start_flicker_effect():
	if flicker_tween and flicker_tween.is_running():
		return
	
	office_darken_overlay.show()
	flicker_tween = create_tween().set_loops()
	flicker_tween.tween_property(office_darken_overlay, "color:a", 0.75, 0.1)
	flicker_tween.tween_property(office_darken_overlay, "color:a", 0.0, 0.15)

func stop_flicker_effect():
	if office_occupant == "ToyFreddy":
		return
	if active_cinematics > 0:
		return

	if flicker_tween and flicker_tween.is_running():
		flicker_tween.kill()
	
	office_darken_overlay.show()
	office_darken_overlay.color.a = 1 # Casi negro total
	
	flicker_tween = create_tween()
	
	flicker_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	flicker_tween.tween_property(office_darken_overlay, "color:a", 0.0, 5.0)
	
	flicker_tween.tween_callback(office_darken_overlay.hide)

func play_defense_cinematic(animatronic_name: String, slide_texture: Texture2D, slide_node: TextureRect, slide_tween: Tween, direction: String):
	active_cinematics += 1
	
	slide_node.texture = slide_texture
	
	if animatronic_name == "ToyBonnie":
		slide_node.position.y = -120
		slide_node.position.x = get_viewport_rect().size.x
	else:
		slide_node.position.y = 60
		slide_node.position.x = -get_viewport_rect().size.x
	
	slide_node.modulate.a = 1.0
	slide_node.visible = true
	print("Office: Iniciando deslizamiento de %s" % animatronic_name)

	if slide_tween and slide_tween.is_running():
		slide_tween.kill()
		
	slide_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	if animatronic_name == "ToyBonnie":
		slide_tween.tween_property(slide_node, "position:x", -slide_node.size.x, 8.0)
	else:
		slide_tween.tween_property(slide_node, "position:x", slide_node.size.x, 8.0)
	
	slide_tween.finished.connect(_on_slide_finished.bind(slide_node))

func _on_slide_finished(slide_node: TextureRect):
	slide_node.hide()
	active_cinematics -= 1
	
	if active_cinematics == 0:
		stop_flicker_effect()
		
		if not is_flashlight_failing:
			officeBG.texture = office_dark_default
			
	print("Office: ===== UNA CINEMÁTICA COMPLETADA =====")

func _on_left_light_button_down() -> void:
	if MASK_ON or is_flashlight_failing or active_cinematics > 0:
		return
	officeBG.texture = left_vent_light_textures.get(left_vent_occupant, office_lit_left_empty)

func _on_left_light_button_up() -> void:
	if active_cinematics == 0:
		officeBG.texture = office_dark_default
		
func _on_right_light_button_up() -> void:
	if active_cinematics == 0:
		officeBG.texture = office_dark_default

func _on_right_light_button_down() -> void:
	if MASK_ON or is_flashlight_failing or active_cinematics > 0:
		return
	officeBG.texture = right_vent_light_textures.get(right_vent_occupant, office_lit_right_empty)
	if right_vent_occupant == "Mangle":
		if not mangle_office_sound.playing:
			mangle_office_sound.play()

func _on_hall_light_button_up() -> void:
	if is_flashlight_failing or active_cinematics > 0 or is_flash_lock_active:
		is_hall_light_on = false
		return
		
	is_hall_light_on = false
	officeBG.texture = office_dark_default

func _on_hall_light_button_down() -> void:
	if MASK_ON or is_flashlight_failing or active_cinematics > 0:
			return
	is_hall_light_on = true 
	
	if hall_occupant in STROBE_ANIMATRONICS:
		is_flashlight_failing = true
		officeBG.texture = hall_light_textures["Fail"]
		flashlight_fail_timer.start()
		ai_manager.on_hall_flashlight_success(hall_occupant)
	else:
		officeBG.texture = hall_light_textures.get(hall_occupant, office_lit_hall_empty)


func _on_flashlight_fail_timer_timeout():
	is_flashlight_failing = false
	if active_cinematics == 0:
		officeBG.texture = office_dark_default

func _on_camera_toggle_pressed() -> void:
	if MASK_ON or active_cinematics > 0:
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
		if ai_manager.is_toy_freddy_doomed():
			print("Office: Monitor subido. Ejecutando Jumpscare retardado de Toy Freddy.")
			ai_manager.emit_signal("jumpscare", "ToyFreddy")
			return

func _on_office_flicker_timer_timeout():
	officeBG.visible = not officeBG.visible

func is_mask_on(animatronic_name: String) -> bool:
	if not mask_is_fully_on:
		return false
	
	if animatronic_name == "ToyBonnie":
		var chance = randi_range(1, 3)
		if chance == 1:
			print("Office: ¡La máscara funcionó contra Toy Bonnie!")
			play_defense_cinematic("ToyBonnie", toy_bonnie_slide_texture, slide_view_right, slide_tween_right, "right")
			return true
		else:
			print("Office: ¡La máscara falló contra Toy Bonnie!")
			return false
			
	elif animatronic_name == "ToyChica":
		print("Office: ¡La máscara funcionó contra Toy Chica! (llamado desde check_mask)")
		play_defense_cinematic("ToyChica", toy_chica_slide_texture, slide_view_left, slide_tween_left, "left")
		return true
	return true

func get_mask_state() -> bool:
	return mask_is_fully_on

func set_hall_occupant(occupant_name: String):
	var old_occupant = hall_occupant
	hall_occupant = occupant_name
	
	if is_hall_light_on and occupant_name == "Empty" and old_occupant != "Empty":
		officeBG.texture = hall_light_textures["Fail"]
		hall_flicker_lock_timer.start()

		is_flash_lock_active = true

	print("Office: ===== Pasillo ahora ocupado por: '%s' =====" % hall_occupant)

func set_vent_occupant(vent_name: String, occupant_name: String):
	if vent_name == "LeftVent":
		left_vent_occupant = occupant_name
		print("Office: ===== Ventilación Izquierda ahora ocupada por: '%s' =====" % left_vent_occupant)
	elif vent_name == "RightVent":
		right_vent_occupant = occupant_name
		print("Office: ===== Ventilación Derecha ahora ocupada por: '%s' =====" % right_vent_occupant)

func force_cameras_down():
	if CAM_ON:
		print("Office: ¡Forzado a bajar las cámaras!")
		_on_camera_toggle_pressed()

func set_office_occupant(name: String):
	office_occupant = name
	if name == "Empty":
		office_animatronic_view.hide()
		stop_flicker_effect()
		officeBG.visible = true
	else:
		if office_textures.has(name):
			office_animatronic_view.texture = office_textures[name]
			office_animatronic_view.visible = true
			office_animatronic_view.position = initial_toy_freddy_pos
			start_flicker_effect()
		else:
			print("Office: ¡ERROR! No se encontró textura para %s en la oficina" % name)

func _on_ai_manager_jumpscare(animatronic_name: String):
	print("¡¡¡JUMPSCARE RECIBIDO DE: %s!!!" % animatronic_name)
	
	if CAM_ON:
		await $Monitor.animation_finished
	elif MASK_ON:
		await maskAnim.animation_finished
	
	ai_manager.stop()
	set_process(false) 
	stop_flicker_effect()
	
	camera_system.hide() 
	monitorAnim.hide()
	
	# --- CORRECCIONES VISUALES ---
	officeBG.visible = true # Aseguramos que el fondo se vea
	officeBG.modulate = Color(1, 1, 1, 1) # Aseguramos que no esté oscuro
	
	
	# Ocultamos animatrónicos estáticos para que no estorben al jumpscare
	office_animatronic_view.hide() 
	$MaskView/MangeGotYou.visible = false # Ocultamos a Mangle del techo
	if has_node("MangleOfficeSound"): $MaskView/MangleStatic.stop()
	# -----------------------------

	jumpscare_sound.play()
	jumpscare_player.animation = animatronic_name
	jumpscare_player.visible = true
	jumpscare_player.z_index = 100 # Encima de todo
	jumpscare_player.play()
	
func _on_jumpscare_animation_finished():
	hide_all_game_activity()
	get_tree().change_scene_to_file("res://game_over.tscn")
	

func _on_hall_flicker_lock_timer_timeout():
	is_flash_lock_active = false 
	
	if is_hall_light_on:
		officeBG.texture = hall_light_textures.get(hall_occupant, office_lit_hall_empty)
	else:
	
		officeBG.texture = office_dark_default
		
func activate_mangle_inside():
	mangle_ceiling_view.visible = true
	
	
	mangle_office_sound.play()

func hide_all_game_activity():
	officeBG.hide()
	desk.hide()
	maskAnim.hide()
	monitorAnim.hide()
	camera_system.hide()
	$CanvasLayer.hide() 
	
	leftBtn.hide()
	rightBtn.hide()
	$LeftLight.hide()
	$RightLight.hide()
	$HallLight.hide()
	$MaskButton.hide()
	$CameraToggle.hide()
