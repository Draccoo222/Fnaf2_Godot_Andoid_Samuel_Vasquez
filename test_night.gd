extends Control

@onready var main_ambience = $MainAmbience
@onready var flashlight_click = $FlashlightClick
@onready var hallway_ambience = $HallwayAmbience
@onready var camera_up_sound = $CameraUp
@onready var camera_down_sound = $CameraDown
@onready var mask_on_sound = $MaskOn
@onready var mask_off_sound = $MaskOff
@onready var camera_ambience = $CameraAmbience
@onready var vent_crawl_far = $VentCrawlFar     
@onready var vent_crawl_close = $VentCrawlClose 
@onready var hour_display = $HourDisplay
@onready var night_display = $NightNumDisplay
@onready var puppet_escape_music = $PuppetEscapeMusic
@onready var battery_indicator = $BatteryIndicator
@onready var bb_view = $MaskView/BBGotYou
@onready var officeBG = $MaskView/OfficeBG
@onready var gf_view = $MaskView/GFView
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

@onready var bb_player = $MaskView/BBSoundPlayer
@export var sound_bb_hi: AudioStream
@export var sound_bb_hello: AudioStream
@export var sound_bb_laugh: AudioStream

var bb_laugh_timer: Timer

@export_group("Time System Images")
@export var img_12am: Texture2D
@export var img_1am: Texture2D
@export var img_2am: Texture2D
@export var img_3am: Texture2D
@export var img_4am: Texture2D
@export var img_5am: Texture2D
@export var img_6am: Texture2D

@export_group("Night Number Images")
@export var img_num_1: Texture2D
@export var img_num_2: Texture2D
@export var img_num_3: Texture2D
@export var img_num_4: Texture2D
@export var img_num_5: Texture2D
@export var img_num_6: Texture2D
@export var img_num_7: Texture2D

@export_group("Golden Freddy")
@export var office_lit_hall_golden_freddy: Texture2D 
@export var gf_texture: Texture2D
@export var gf_parallax_factor: float = 1.1 
@export var gf_fade_speed: float = 2.0

var initial_gf_pos: Vector2

@export_group("Battery Sprites")
@export var batt_4_bars: Texture2D
@export var batt_3_bars: Texture2D
@export var batt_2_bars: Texture2D
@export var batt_1_bar: Texture2D
@export var batt_empty: Texture2D

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
@export var office_img_bonnie: Texture2D
@export var office_img_chica: Texture2D
@export var office_img_freddy: Texture2D
@export var office_img_bb: Texture2D

@export var office_lit_left_empty: Texture2D
@export var office_lit_left_toychica: Texture2D
@export var office_lit_left_bb: Texture2D
@export var office_lit_right_empty: Texture2D
@export var office_lit_right_toybonnie: Texture2D
@export var office_lit_right_mangle: Texture2D


@export var battery_drain_rate: float = 2.0

@export_group("Balloon Boy Settings")
@export var bb_parallax_factor: float = 1.05 

@export_group("Phone Calls")
@export var call_night_1: AudioStream
@export var call_night_2: AudioStream
@export var call_night_3: AudioStream
@export var call_night_4: AudioStream
@export var call_night_5: AudioStream
@export var call_night_6: AudioStream


var puppet_jumpscare_timer: float = 0.0
var puppet_is_coming = false

var initial_bb_pos: Vector2

var battery_level: float = 100.0
var is_flashlight_blocked = false
var is_camera_flashlight_on = false
var dead_battery_flicker_timer: float = 0.0


var battery_frames_used: float = 0.0
var battery_max_frames: float = 36000.0  
var current_night: int = 1
const NIGHT_BATTERY_FRAMES = {
	1: 7000.0,  
	2: 6000.0,  
	3: 5000.0, 
	4: 4000.0,
	5: 3000.0, 
	6: 3000.0,
	7: 3000.0,
}

const NIGHT_MUSIC_BOX_SPEEDS = {
	1: 1.0,  
	2: 1.2,   
	3: 1.5,   
	4: 1.8,   
	5: 2.2,   
	6: 3.0,   
	7: 4.0,   
}

var is_hallway_movement_active = false 
var is_hall_light_on = false

var hall_light_textures = {}
var left_vent_light_textures = {}
var right_vent_light_textures = {}
var office_textures = {}

var right_vent_occupant = "Empty"
var left_vent_occupant = "Empty"
var hall_occupant = "Empty"
var office_occupant = "Empty"

var mangle_sound_playback_position: float = 0.0 
var mangle_vent_sound_position: float = 0.0
var mangle_camera_sound_position: float = 0.0


var is_flashlight_failing = false
const STROBE_ANIMATRONICS = [
	"Foxy", 
	"Foxy_Mangle", 
	"WitheredBonnie_Foxy", 
	"WitheredBonnie", 
	"WitheredChica", 
	"WitheredFreddy"
]

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

var is_game_over = false

var gf_hallway_reaction_timer: float = 0.0
var gf_hallway_limit: float = 0.8
var gf_is_dying_by_flashlight = false

var current_hour: int = 0 
var hour_timer: float = 0.0
var seconds_per_hour: float = 100.0 
var night_finished = false

@onready var footstep_sounds = [
	$FootStep1, 
	$FootStep2,
	$FootStep3,
	$FootStep4
]


func _ready():
	await ready
	is_game_over = false
	
	update_night_display()
	update_hour_display()
	
	current_hour = 0
	hour_timer = 0.0
	night_finished = false
	
	initial_bb_pos = bb_view.position
	
	initial_gf_pos = gf_view.position
	gf_view.visible = false
	gf_view.modulate.a = 1.0
	if gf_texture:
		gf_view.texture = gf_texture
	
	if camera_system.has_signal("flashlight_toggled"):
		camera_system.flashlight_toggled.connect(_on_camera_flashlight_toggled)
		
	if camera_system.has_signal("puppet_is_loose"):
		camera_system.puppet_is_loose.connect(_on_puppet_is_loose)
		
	if has_node("/root/Global"):
		current_night = Global.current_night
		print("Office: Cargando Noche ", current_night, " desde Global.")
	else:
		current_night = 1
		print("Office: Global no encontrado, usando Noche 1 por defecto.")
	if NIGHT_BATTERY_FRAMES.has(current_night):
		battery_max_frames = NIGHT_BATTERY_FRAMES[current_night]
	battery_frames_used = 0.0
	
	var ai_levels = get_night_ai_levels(current_night)
	
	var mb_speed = NIGHT_MUSIC_BOX_SPEEDS.get(current_night, 1.0)
	

	if "music_box_drain_rate" in camera_system:
		camera_system.music_box_drain_rate = mb_speed
		print("Office: Velocidad de Caja Musical ajustada a: ", mb_speed)
	
	ai_manager.start_night(ai_levels, camera_system, self)
	
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
		
		"GoldenFreddy": office_lit_hall_goldenFreddy,
		"Foxy_Mangle": office_lit_hall_foxy_mangle,
		"Mangle": office_lit_hall_mangle,
		"ToyChica": office_lit_hall_toyChica,
		"ToyFreddy_Far": office_lit_hall_toyfreddy,
		"WitheredBonnie_Foxy": office_lit_hall_witheredbonnie_foxy,
		"WitheredBonnie": office_lit_hall_witheredbonnie,
		"ToyFreddy_Close": office_lit_hall_toyfreddy2,
		"WitheredFreddy": office_lit_hall_witheredfreddy,
		"Foxy": office_lit_hall_foxy
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
		"ToyFreddy": office_img_toyfreddy,
		"WitheredBonnie": office_img_bonnie,
		"WitheredChica": office_img_chica,
		"WitheredFreddy": office_img_freddy
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
	
	
	current_hour = 0
	hour_timer = 0.0
	night_finished = false
	update_night_display()
	update_hour_display()
	start_phone_call()


func _process(delta):

	
	hour_timer += delta
	
	if hour_timer >= seconds_per_hour:
		hour_timer = 0.0
		current_hour += 1
		update_hour_display()
		
		
		if current_hour == 6:
			finish_night()
	
	if puppet_is_coming and not is_game_over:
		puppet_jumpscare_timer -= delta
	
		if puppet_jumpscare_timer <= 0:
			if CAM_ON:
				force_cameras_down()
				await get_tree().create_timer(0.3).timeout
			ai_manager.trigger_jumpscare("Puppet")
			puppet_is_coming = false
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
			
		if bb_view.visible:
			bb_view.position.x = (officeBG.position.x * bb_parallax_factor) + initial_bb_pos.x
			
		if gf_view.visible:
			gf_view.position.x = (officeBG.position.x * gf_parallax_factor) + initial_gf_pos.x
			
		if is_hall_light_on and hall_occupant == "GoldenFreddy":
			gf_hallway_reaction_timer += delta
			if gf_hallway_reaction_timer >= gf_hallway_limit:
				print("Office: ¡Te quedaste mirando a GF demasiado tiempo!")
				ai_manager.trigger_jumpscare("GoldenFreddy")
		else:
			gf_hallway_reaction_timer = 0.0
			
		if gf_is_dying_by_flashlight:
			fade_out_golden_freddy(delta, true)
			
		if gf_view.visible and MASK_ON:
			fade_out_golden_freddy(delta, false)
		
		if office_occupant == "ToyFreddy":
			office_animatronic_view.position.y = -75
			office_animatronic_view.position.x = (officeBG.position.x * toy_freddy_parallax_factor) + initial_toy_freddy_pos.x + 850
		else:
			office_animatronic_view.position.y = officeBG.position.y
			office_animatronic_view.position.x = officeBG.position.x
	
	if mask_is_fully_on:
		idle_time_counter += delta * idle_speed
		var offset_x = sin(idle_time_counter) * idle_amplitude_x
		var offset_y = cos(idle_time_counter * 2.0) * idle_amplitude_y
		maskAnim.position = initial_mask_pos + Vector2(offset_x, offset_y)
		
	var frames_this_tick = delta * 60.0
	if battery_frames_used < battery_max_frames:
		
		if (is_hall_light_on or is_camera_flashlight_on) and not is_flashlight_blocked:
			battery_frames_used += frames_this_tick
			battery_frames_used = min(battery_frames_used, battery_max_frames)
	else:
		force_flashlight_off()
	update_battery_display()
	

func _on_mask_button_pressed() -> void:
	if CAM_ON or active_cinematics > 0:
		return
		
	if ((ai_manager.is_toy_freddy_doomed() or 
	ai_manager.is_withered_bonnie_doomed() or 
	ai_manager.is_withered_chica_doomed() or 
	ai_manager.is_withered_freddy_doomed()) and 
	MASK_ON == false):
		return 
		
	
	if MASK_ON and gf_view.visible:
		return
		
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
		
		mask_on_sound.play()
		
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
			
			ai_manager.reset_animatronic("Mangle")
		
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
		mask_off_sound.play()
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
		elif ai_manager.is_withered_bonnie_doomed():
			print("Office: Animación terminada. Ejecutando Jumpscare retardado de Withered Bonnie.")
			ai_manager.emit_signal("jumpscare", "WitheredBonnie")
		elif ai_manager.is_withered_chica_doomed():
			print("Office: Máscara quitada. Jumpscare de Withered Chica.")
			ai_manager.emit_signal("jumpscare", "WitheredChica")

func start_flicker_effect():
	if flicker_tween and flicker_tween.is_running():
		return
	
	print("Office: Iniciando efecto de parpadeo de luces")
	
	office_darken_overlay.show()
	office_darken_overlay.color = Color(0, 0, 0, 0) 
	
	flicker_tween = create_tween().set_loops()
	

	flicker_tween.tween_property(office_darken_overlay, "color:a", 0.95, 0.08)
	flicker_tween.tween_property(office_darken_overlay, "color:a", 0.0, 0.08) 
	flicker_tween.tween_property(office_darken_overlay, "color:a", 0.90, 0.06)  
	flicker_tween.tween_property(office_darken_overlay, "color:a", 0.0, 0.06)   
	flicker_tween.tween_property(office_darken_overlay, "color:a", 0.85, 0.10)  
	flicker_tween.tween_property(office_darken_overlay, "color:a", 0.0, 0.10)  

func stop_flicker_effect():

	if office_occupant == "ToyFreddy" or office_occupant == "WitheredBonnie" or office_occupant == "WitheredChica" or office_occupant == "WitheredFreddy" or office_occupant == "GoldenFreddy":
		return
	if active_cinematics > 0:
		return
	
	if flicker_tween and flicker_tween.is_running():
		flicker_tween.kill()
	
	officeBG.texture = office_dark_default
	
	if not office_occupant == "GoldenFreddy":
		office_darken_overlay.show()
		office_darken_overlay.color.a = 1 
		
		flicker_tween = create_tween()
		
		flicker_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		
		flicker_tween.tween_property(office_darken_overlay, "color:a", 0.0, 5.0)
		
		flicker_tween.tween_callback(office_darken_overlay.hide)
	
	print("Office: Efecto de parpadeo detenido")

func play_defense_cinematic(animatronic_name: String, slide_texture: Texture2D, slide_node: TextureRect, slide_tween: Tween, direction: String):
	active_cinematics += 1
	slide_node.texture = slide_texture
	slide_node.modulate.a = 1.0
	
	if animatronic_name == "ToyBonnie":
		start_flicker_effect()
		slide_node.position.y = -120
		slide_node.position.x = get_viewport_rect().size.x
		slide_node.visible = true

		print("Office: Iniciando deslizamiento de Toy Bonnie")
		
		if slide_tween and slide_tween.is_running():
			slide_tween.kill()
		
		slide_tween = create_tween()
		
	
		var center_x = (get_viewport_rect().size.x - slide_node.size.x) / 2
		slide_tween.tween_property(slide_node, "position:x", center_x, 4.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
		
		slide_tween.tween_interval(1.5)

		
		slide_tween.tween_property(slide_node, "modulate:a", 0.0, 0.5)

		slide_tween.finished.connect(_on_slide_finished.bind(slide_node))
		
	elif animatronic_name == "ToyChica":
		start_flicker_effect()
		
		slide_node.position.y = 60
		slide_node.position.x = -slide_node.size.x
		slide_node.visible = true
		
		print("Office: Iniciando deslizamiento de Toy Chica con parpadeo")
		
		if slide_tween and slide_tween.is_running():
			slide_tween.kill()
		
		slide_tween = create_tween()
		
		var center_x = (get_viewport_rect().size.x - slide_node.size.x) / 2
		slide_tween.tween_property(slide_node, "position:x", center_x, 5.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		
		
		slide_tween.tween_interval(1.5)
		
		
		slide_tween.tween_property(slide_node, "modulate:a", 0.0, 0.5)
		
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

func _on_hall_light_button_up() -> void:
	if is_flashlight_failing or active_cinematics > 0 or is_flash_lock_active:
		is_hall_light_on = false
		return
		
	is_hall_light_on = false
	
	if not is_hallway_movement_active:
		officeBG.texture = office_dark_default

func _on_hall_light_button_down() -> void:
	if battery_frames_used >= battery_max_frames:
		print("Office: ¡Sin batería para la linterna!")
		return
		
	if MASK_ON or active_cinematics > 0 or is_flash_lock_active or battery_level <= 0 or is_flashlight_blocked:
		return
		
	flashlight_click.play()
		
	if gf_view.visible and not MASK_ON:
		print("Office: ¡Error! Alumbraste a GF en la oficina. Iniciando secuencia de muerte.")
		gf_is_dying_by_flashlight = true
		return	
		
	is_hall_light_on = true 
	
	
	if is_hallway_movement_active:
		print("Office: ¡Luz encendida durante movimiento! Mostrando FAIL.")
		officeBG.texture = hall_light_textures["Fail"]
		return
		
	officeBG.texture = hall_light_textures.get(hall_occupant, office_lit_hall_empty)
	
	var animatronics_in_hall = []
	
	if ai_manager.locations.get("Foxy") == "Hallway":
		animatronics_in_hall.append("Foxy")
	if ai_manager.locations.get("WitheredBonnie") == "Hallway":
		animatronics_in_hall.append("WitheredBonnie")
	if ai_manager.locations.get("WitheredFreddy") == "Hallway":
		animatronics_in_hall.append("WitheredFreddy")
	if ai_manager.locations.get("Mangle") == "Hallway":
		animatronics_in_hall.append("Mangle")
	if ai_manager.locations.get("ToyChica") == "Hallway":
		animatronics_in_hall.append("ToyChica")
	if ai_manager.locations.get("ToyFreddy") == "Hallway":
		animatronics_in_hall.append("ToyFreddy")
	
	for anim in animatronics_in_hall:
		if anim in STROBE_ANIMATRONICS:
			print("Office: ¡Flash aplicado a %s (en pasillo)!" % anim)
			ai_manager.on_hall_flashlight_success(anim)
	
	if animatronics_in_hall.size() > 0:
		for anim in animatronics_in_hall:
			if anim in STROBE_ANIMATRONICS:
				is_flashlight_failing = true
				flashlight_fail_timer.start()
				break



func _on_flashlight_fail_timer_timeout():
	is_flashlight_failing = false
	
	if active_cinematics > 0:
		return
		
	if is_hall_light_on:
		
		officeBG.texture = hall_light_textures.get(hall_occupant, office_lit_hall_empty)
		
		if hall_occupant in STROBE_ANIMATRONICS:
			is_flashlight_failing = true
			
			print("Office: Linterna mantenida -> Drenando ira de Foxy (Loop)...")
			ai_manager.on_hall_flashlight_success(hall_occupant)
			
			flashlight_fail_timer.start()
	else:
		officeBG.texture = office_dark_default

func _on_camera_toggle_pressed() -> void:
	if MASK_ON or active_cinematics > 0:
		return
		
	CAM_ON = not CAM_ON
	
	if CAM_ON:
		camera_ambience.play()
	else:
		camera_ambience.stop()
	
	monitorAnim.show()
	
	if CAM_ON:
		if right_vent_occupant == "Mangle" and mangle_office_sound.playing:
			print("Office: Cámaras subidas - pausando estática de Mangle")
			mangle_sound_playback_position = mangle_office_sound.get_playback_position()
			mangle_office_sound.stop()
		monitorAnim.play("monitorOn")
	else:
		if right_vent_occupant == "Mangle" and not mangle_office_sound.playing:
			print("Office: Cámaras bajadas - resumiendo estática de Mangle en ventila")
			if mangle_vent_sound_position > 0:
				mangle_office_sound.play(mangle_vent_sound_position)
			else:
				mangle_office_sound.play()
		ai_manager.on_cameras_lowered() 
		camera_system.on_monitor_lowered()
		camera_system.hide()
		monitorAnim.play("monitorOff")

func _on_monitor_animation_finished() -> void:
	if CAM_ON and monitorAnim.animation == "monitorOn":
		camera_system.show()
		camera_system.on_monitor_raised()
		ai_manager.on_cameras_raised() 
	elif not CAM_ON and monitorAnim.animation == "monitorOff":
		monitorAnim.hide()
		if ai_manager.is_toy_freddy_doomed():
			print("Office: Monitor subido. Ejecutando Jumpscare retardado de Toy Freddy.")
			ai_manager.emit_signal("jumpscare", "ToyFreddy")
			return
		elif ai_manager.is_withered_bonnie_doomed():
			print("Office: Monitor subido. Ejecutando Jumpscare retardado de Withered Bonnie.")
			ai_manager.emit_signal("jumpscare", "WitheredBonnie")
			return
		elif ai_manager.is_withered_chica_doomed(): 
			print("Office: Monitor bajado. Jumpscare de Withered Chica.")
			ai_manager.emit_signal("jumpscare", "WitheredChica")
			return
		elif ai_manager.is_withered_freddy_doomed():
			print("Office: Monitor bajado. Jumpscare de Withered Freddy.")
			ai_manager.emit_signal("jumpscare", "WitheredFreddy")
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
	
	print("Office: Pasillo cambiando de '%s' a '%s'" % [old_occupant, occupant_name])
	
	if old_occupant != occupant_name:
		print("Office: ¡MOVIMIENTO DETECTADO! Bloqueando flashlight...")
		is_hallway_movement_active = true
		
		
		if is_hall_light_on:
			officeBG.texture = hall_light_textures["Fail"]
		
	
		hall_flicker_lock_timer.start()
		is_flash_lock_active = true
		return
	
	
	if is_hall_light_on and not is_hallway_movement_active:
		officeBG.texture = hall_light_textures.get(hall_occupant, office_lit_hall_empty)

func set_vent_occupant(vent_name: String, occupant_name: String):
	if vent_name == "LeftVent":
		left_vent_occupant = occupant_name
		print("Office: ===== Ventilación Izquierda ahora ocupada por: '%s' =====" % left_vent_occupant)
	elif vent_name == "RightVent":
		var old_occupant = right_vent_occupant
		right_vent_occupant = occupant_name
		print("Office: ===== Ventilación Derecha ahora ocupada por: '%s' =====" % right_vent_occupant)
		
		if occupant_name == "Mangle" and old_occupant != "Mangle":
			# Mangle ENTERS vent - START sound
			print("Office: ¡Mangle en ventila! Iniciando estática automáticamente.")
			if mangle_vent_sound_position > 0:
				mangle_office_sound.play(mangle_vent_sound_position)
			else:
				mangle_office_sound.play()
		
		elif old_occupant == "Mangle" and occupant_name != "Mangle":
			# ✅ Mangle left the vent - STOP sound
			print("Office: Mangle salió de la ventila. Deteniendo estática.")
			mangle_sound_playback_position = mangle_office_sound.get_playback_position()
			mangle_office_sound.stop()

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
			if name == "toyFreddy":
				office_animatronic_view.position = initial_toy_freddy_pos
			else:
				office_animatronic_view.position = officeBG.position
			start_flicker_effect()
		else:
			print("Office: ¡ERROR! No se encontró textura para %s en la oficina" % name)

func _on_ai_manager_jumpscare(animatronic_name: String):
	if is_game_over:
		return
	
	is_game_over = true
	print("¡¡¡JUMPSCARE RECIBIDO DE: %s!!!" % animatronic_name)
	
	if CAM_ON:
		await $Monitor.animation_finished
	elif MASK_ON:
		await maskAnim.animation_finished
	
	ai_manager.stop()
	set_process(false) 

	if mangle_office_sound.playing:
		mangle_office_sound.stop()
	mangle_sound_playback_position = 0.0
	
	# Hide Mangle visuals
	office_animatronic_view.hide()
	mangle_ceiling_view.visible = false
	
	officeBG.texture = office_dark_default
	
	if flicker_tween and flicker_tween.is_running():
		flicker_tween.kill()
	office_darken_overlay.color = Color(0, 0, 0, 0) 
	office_darken_overlay.hide()
	office_darken_overlay.z_index = 0
	
	stop_flicker_effect()
	
	camera_system.hide() 
	monitorAnim.hide()
	

	officeBG.visible = true
	officeBG.modulate = Color(1, 1, 1, 1) 
	officeBG.texture = office_dark_default
	
	
	office_animatronic_view.hide() 
	$MaskView/MangeGotYou.visible = false 
	if has_node("MangleOfficeSound"): $MaskView/MangleStatic.stop()
	
	jumpscare_sound.play()
	jumpscare_player.animation = animatronic_name
	jumpscare_player.visible = true
	jumpscare_player.z_index = 100 
	jumpscare_player.play()
	
func _on_jumpscare_animation_finished():
	hide_all_game_activity()
	get_tree().change_scene_to_file("res://game_over.tscn")
	


func _on_hall_flicker_lock_timer_timeout():
	
	is_flash_lock_active = false
	is_hallway_movement_active = false 

	if is_hall_light_on:
		
		officeBG.texture = hall_light_textures.get(hall_occupant, office_lit_hall_empty)
		
		if hall_occupant in STROBE_ANIMATRONICS:
			print("Office: Foxy visible después del movimiento. Aplicando flash...")
			is_flashlight_failing = true
			flashlight_fail_timer.start()
			ai_manager.on_hall_flashlight_success(hall_occupant)
	else:
		
		officeBG.texture = office_dark_default
		
func activate_mangle_inside():
	mangle_ceiling_view.visible = true
	print("Office: Mangle en el techo - estática continúa")
	if not mangle_office_sound.playing:
		if mangle_sound_playback_position > 0:
			mangle_office_sound.play(mangle_sound_playback_position)
		else:
			mangle_office_sound.play()
	
func handle_withered_in_office(animatronic_name: String):
	print("Office: %s apareció en la oficina con parpadeo" % animatronic_name)
	office_animatronic_view.visible = true

func stop_mangle_sound():
	"""Called by AI manager when Mangle is reset/leaves"""
	print("Office: Deteniendo sonido de Mangle por reset")
	if mangle_office_sound.playing:
		mangle_office_sound.stop()
	mangle_sound_playback_position = 0.0
	mangle_ceiling_view.visible = false

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
	
func force_flashlight_off():
	if is_hall_light_on:
		is_hall_light_on = false
		officeBG.texture = office_dark_default
		
		if is_flash_lock_active:
			is_flash_lock_active = false
			hall_flicker_lock_timer.stop()
	
	if is_camera_flashlight_on:
		is_camera_flashlight_on = false
		
		camera_system.set_flashlight_blocked(true)
		camera_system.turn_off_flashlight()
		
func _on_camera_flashlight_toggled(state: bool):
	is_camera_flashlight_on = state
		
		
func block_flashlight():
	print("Office: ¡Balloon Boy ha robado las pilas!")
	is_flashlight_blocked = true
	force_flashlight_off()
	
func start_night_with_number(night_number: int):
	current_night = night_number
	battery_max_frames = NIGHT_BATTERY_FRAMES[current_night]
	battery_frames_used = 0.0

	print("Office: Noche %d iniciada - Batería: %d frames disponibles" % [night_number, battery_max_frames])

	var ai_levels = get_night_ai_levels(night_number)
	ai_manager.start_night(ai_levels, camera_system, self)
	
func update_battery_display():
	var battery_remaining = battery_max_frames - battery_frames_used
	var battery_percent = (battery_remaining / battery_max_frames) * 100.0
	battery_percent = clamp(battery_percent, 0.0, 100.0)

	if battery_percent > 80:
		battery_indicator.texture = batt_4_bars
		battery_indicator.visible = true
		battery_indicator.modulate.a = 1.0
	elif battery_percent > 60:
		battery_indicator.texture = batt_3_bars
		battery_indicator.visible = true
		battery_indicator.modulate.a = 1.0
	elif battery_percent > 40:
		battery_indicator.texture = batt_2_bars
		battery_indicator.visible = true
		battery_indicator.modulate.a = 1.0
	elif battery_percent > 20:
		battery_indicator.texture = batt_1_bar
		battery_indicator.visible = true
		battery_indicator.modulate.a = 1.0
	elif battery_percent > 0:
		battery_indicator.texture = batt_empty
		battery_indicator.visible = true
		battery_indicator.modulate.a = 1.0
	else:
		battery_indicator.texture = batt_empty
		dead_battery_flicker_timer += get_process_delta_time()
		if dead_battery_flicker_timer >= 0.5:
			battery_indicator.visible = not battery_indicator.visible
			dead_battery_flicker_timer = 0.0	
	
	
func get_night_ai_levels(night: int) -> Dictionary:
	match night:
		1:
			return {
				"ToyBonnie": 0, "ToyChica": 1, "ToyFreddy": 0,
				"Mangle": 1, "Foxy": 1,
				"WitheredBonnie": 0, "WitheredChica": 0, "WitheredFreddy": 0,
				"BB": 0, "GoldenFreddy": 0
			}
		2:
			return {
				"ToyBonnie": 3, "ToyChica": 1, "ToyFreddy": 2,
				"Mangle": 3, "Foxy": 3,
				"WitheredBonnie": 0, "WitheredChica": 0, "WitheredFreddy": 0,
				"BB": 3, "GoldenFreddy": 0
			}
		3:
			return {
				"ToyBonnie": 1, "ToyChica": 5, "ToyFreddy": 2,
				"Mangle": 2, "Foxy": 2,
				"WitheredBonnie": 3, "WitheredChica": 2, "WitheredFreddy": 1,
				"BB": 2, "GoldenFreddy": 0
			}
		4:
			return {
				"ToyBonnie": 2, "ToyChica": 4, "ToyFreddy": 6,
				"Mangle": 2, "Foxy": 7,
				"WitheredBonnie": 4, "WitheredChica": 4, "WitheredFreddy": 2,
				"BB": 3, "GoldenFreddy": 1 
			}
		5:
			return {
				"ToyBonnie": 5, "ToyChica": 7, "ToyFreddy": 5,
				"Mangle": 5, "Foxy": 7,
				"WitheredBonnie": 5, "WitheredChica": 5, "WitheredFreddy": 3,
				"BB": 5, "GoldenFreddy": 3
			}
		6:
			return {
				"ToyBonnie": 10, "ToyChica": 12, "ToyFreddy": 8,
				"Mangle": 10, "Foxy": 12,
				"WitheredBonnie": 10, "WitheredChica": 10, "WitheredFreddy": 8,
				"BB": 9, "GoldenFreddy": 10
			}
		7: 
			return {
				"ToyBonnie": 20, "ToyChica": 20, "ToyFreddy": 20,
				"Mangle": 20, "Foxy": 20,
				"WitheredBonnie": 20, "WitheredChica": 20, "WitheredFreddy": 20,
				"BB": 20, "GoldenFreddy": 20
			}
		_:
			# Por defecto (Noche 0 o pruebas)
			return {
				"ToyBonnie": 0, "ToyChica": 0, "ToyFreddy": 0,
				"Mangle": 0, "Foxy": 0,
				"WitheredBonnie": 0, "WitheredChica": 0, "WitheredFreddy": 0,
				"BB": 0, "GoldenFreddy": 0
			}
			
func play_bb_sound():
	if not ai_manager.bb_in_office:
		var sounds = [sound_bb_hi, sound_bb_hello, sound_bb_laugh]
		var pick = sounds.pick_random()
		bb_player.stream = pick
		bb_player.play()
	
func activate_bb_inside():
	print("Office: ¡Balloon Boy ha entrado! Activando visuales.")
	bb_view.visible = true
	
	block_flashlight()
	play_bb_laugh_loop()

func play_bb_laugh_loop():
	if not bb_laugh_timer:
		bb_laugh_timer = Timer.new()
		bb_laugh_timer.wait_time = 2.0
		bb_laugh_timer.one_shot = false
		bb_laugh_timer.timeout.connect(func(): 
			bb_player.stream = sound_bb_laugh
			bb_player.play()
		)
		add_child(bb_laugh_timer)
		bb_laugh_timer.start()
		
func spawn_golden_freddy_office():
	print("Office: Golden Freddy (Traje) aparece en la oficina.")
	gf_view.visible = true
	gf_view.modulate.a = 1.0
	gf_is_dying_by_flashlight = false
	
func _on_puppet_is_loose():
	print("Office: ¡PUPPET HA ESCAPADO! Iniciando secuencia final.")

	puppet_escape_music.play()
	
	puppet_jumpscare_timer = randf_range(5.0, 15.0) 
	puppet_is_coming = true

func fade_out_golden_freddy(delta, is_fatal: bool = false):
	if not gf_view.visible: return
	
	if gf_is_dying_by_flashlight:
		is_fatal = true
		
	var speed = gf_fade_speed * 1.5 if is_fatal else gf_fade_speed
	
	gf_view.modulate.a -= speed * delta
	
	if gf_view.modulate.a <= 0:
		gf_view.visible = false
		gf_view.modulate.a = 1.0
		
		if is_fatal:
			print("Office: GF terminó de desvanecerse -> JUMPSCARE.")
			ai_manager.trigger_jumpscare("GoldenFreddy")
		else:
			print("Office: GF se fue pacíficamente.")
			ai_manager.reset_animatronic("GoldenFreddy")
			
			
func update_hour_display():
	var texture = img_12am
	
	match current_hour:
		0: texture = img_12am
		1: texture = img_1am
		2: texture = img_2am
		3: texture = img_3am
		4: texture = img_4am
		5: texture = img_5am
		6: texture = img_6am
	
	if hour_display:
		hour_display.texture = texture			
		hour_display.reset_size()
			
			
func update_night_display():
	
	var texture = img_num_1 
	
	match current_night:
		1: texture = img_num_1
		2: texture = img_num_2
		3: texture = img_num_3
		4: texture = img_num_4
		5: texture = img_num_5
		6: texture = img_num_6
		7: texture = img_num_7
		_: texture = img_num_1 
		
	if night_display:
		night_display.texture = texture
		
func finish_night():
	print("Office: ¡SON LAS 6 AM! Noche completada.")
	night_finished = true
	
	ai_manager.stop()
	
	
	hide_all_game_activity()
	

	get_tree().change_scene_to_file("res://victory.tscn")


func play_hallway_ambience():
	if not hallway_ambience.playing:
		hallway_ambience.play()

func stop_hallway_ambience():
	if hallway_ambience.playing:
		hallway_ambience.stop()
		

func play_random_footstep():
	var footstep = footstep_sounds.pick_random()
	footstep.play()


func play_vent_sound(distance: String):
	if distance == "far":
		vent_crawl_far.play()
	else:
		vent_crawl_close.play()
		
func start_phone_call():
	var call_to_play: AudioStream = null
  
	match current_night:
		1: call_to_play = call_night_1
		2: call_to_play = call_night_2
		3: call_to_play = call_night_3
		4: call_to_play = call_night_4
		5: call_to_play = call_night_5
		6: call_to_play = call_night_6
		
	if call_to_play:
		$PhoneSystem.stream = call_to_play
		$PhoneSystem.play()
   
