extends Control

@onready var camViews = $CamViews
@onready var cam_ui_root = $CamUI
@onready var camera_name_display = $CamUI/CameraNameLabel
@onready var rec_dot = $CamUI/RecDot
@onready var music_box_bar = $CamUI/MusicBoxBar
@onready var music_box_circle = $CamUI/MusicBoxCircle
@onready var music_box_button = $CamUI/MusicBoxButton
@onready var static_overlay = $Static
@onready var static_transition = $Static2
@onready var cam_buttons_root = $CamButtons
@onready var grace_period_timer = $CamUI/GracePeriodTimer
var curCam: TextureRect

@export_group("Camera Panning")
@export var pan_value: float
@export var pan_amount: float = 100.0
@export var pan_duration: float = 5.0

var camera_content = {
	"CAM_01": "Empty",
	"CAM_02": "Empty",
	"CAM_03": "Empty",
	"CAM_04": "Empty",
	"CAM_05": "Empty",
	"CAM_06": "Empty",
	"CAM_07": "Empty",
	"CAM_08": "Empty",
	"CAM_09": "Empty",
	"CAM_10": "Empty",
	"CAM_11": "Empty",
	"CAM_12": "Empty"
}

#Texturas de camaras individuales
@export_group("CAM_01 Textures")
@export var cam01_dark_empty: Texture2D
@export var cam01_lit_empty: Texture2D
@export var cam01_lit_bonnie: Texture2D
@export var cam01_lit_toychica: Texture2D

@export_group("CAM_02 Textures")
@export var cam02_dark_empty: Texture2D
@export var cam02_lit_empty: Texture2D
@export var cam02_dark_chica: Texture2D
@export var cam02_lit_chica: Texture2D
@export var cam02_lit_toybonnie: Texture2D

@export_group("CAM_03 Textures")
@export var cam03_dark_empty: Texture2D
@export var cam03_lit_empty: Texture2D
@export var cam03_dark_freddy: Texture2D
@export var cam03_lit_freddy: Texture2D
@export var cam03_lit_toybonnie: Texture2D

@export_group("CAM_04 Textures")
@export var cam04_dark_empty: Texture2D
@export var cam04_lit_empty: Texture2D
@export var cam04_lit_toychica: Texture2D
@export var cam04_lit_chica: Texture2D
@export var cam04_dark_toybonnie: Texture2D
@export var cam04_lit_toybonnie: Texture2D

@export_group("CAM_05 Textures")
@export var cam05_dark_empty: Texture2D
@export var cam05_lit_empty: Texture2D
@export var cam05_lit_toychica: Texture2D
@export var cam05_lit_bonnie: Texture2D
@export var cam05_lit_bb: Texture2D
@export var cam05_lit_endo: Texture2D

@export_group("CAM_06 Textures")
@export var cam06_dark_empty: Texture2D
@export var cam06_lit_empty: Texture2D
@export var cam06_lit_toybonnie: Texture2D
@export var cam06_lit_mangle: Texture2D
@export var cam06_lit_chica: Texture2D

@export_group("CAM_07 Textures")
@export var cam07_dark_empty: Texture2D
@export var cam07_lit_empty: Texture2D
@export var cam07_dark_toychica: Texture2D
@export var cam07_lit_toychica: Texture2D
@export var cam07_lit_bonnie: Texture2D
@export var cam07_lit_freddy: Texture2D

@export_group("CAM_08 Textures")
@export var cam08_dark_empty: Texture2D
@export var cam08_lit_empty: Texture2D
@export var cam08_dark_chica: Texture2D
@export var cam08_lit_chica: Texture2D
@export var cam08_lit_bonnie: Texture2D
@export var cam08_lit_freddy: Texture2D
@export var cam08_lit_foxy: Texture2D
@export var cam08_lit_shadowfreddy: Texture2D


@export_group("CAM_09 Textures")
@export var cam09_dark_empty: Texture2D
@export var cam09_lit_empty: Texture2D
@export var cam09_dark_toybonnie: Texture2D
@export var cam09_lit_toybonnie: Texture2D
@export var cam09_dark_toychica: Texture2D
@export var cam09_lit_toychica: Texture2D
@export var cam09_dark_toyfreddy: Texture2D


@export_group("CAM_10 Textures")
@export var cam10_dark_empty: Texture2D
@export var cam10_lit_empty: Texture2D
@export var cam10_dark_bb: Texture2D
@export var cam10_lit_bb: Texture2D
@export var cam10_lit_toyfreddybb: Texture2D
@export var cam10_lit_toyfreddy: Texture2D

@export_group("CAM_11 Textures")
@export var cam11_dark_empty: Texture2D
@export var cam11_lit_empty: Texture2D
@export var cam11_lit_puppet1: Texture2D
@export var cam11_lit_puppet2: Texture2D
@export var cam11_lit_puppetFinal: Texture2D
@export var cam11_lit_endo: Texture2D

@export_group("CAM_12 Textures")
@export var cam12_dark_empty: Texture2D
@export var cam12_lit_empty: Texture2D
@export var cam12_lit_mangle: Texture2D

@export_group("Camera Name Textures")
@export var name_img_cam01: Texture2D
@export var name_img_cam02: Texture2D
@export var name_img_cam03: Texture2D
@export var name_img_cam04: Texture2D
@export var name_img_cam05: Texture2D
@export var name_img_cam06: Texture2D
@export var name_img_cam07: Texture2D
@export var name_img_cam08: Texture2D
@export var name_img_cam09: Texture2D
@export var name_img_cam10: Texture2D
@export var name_img_cam11: Texture2D
@export var name_img_cam12: Texture2D

@export_group("Music Box")
@export var drain_rate: float = 0.2
@export var wind_rate: float = 5.0

@onready var warning_sign_1 = $CamUI/WarningSign1
@onready var warning_sign_2 = $CamUI/WarningSign2
@onready var warning_timer_1 = $CamUI/WarningTimer1
@onready var warning_timer_2 = $CamUI/WarningTimer2

@onready var warning_delay_timer_1 = $CamUI/WarningDelayTimer1
@onready var warning_delay_timer_2 = $CamUI/WarningDelayTimer2

var music_box_locked = false
var is_warning_1_pending = false
var is_warning_2_pending = false
var is_in_grace_period = false
signal puppet_is_loose


var camera_name_textures = {}
var camera_textures ={}
var camTween: Tween;

var is_flashlight_on = false;

func _ready():
	static_overlay.play()
	static_transition.hide() 
	
	var group: ButtonGroup = ButtonGroup.new()
	group.pressed.connect(buttongroup_pressed)
	
	warning_timer_1.timeout.connect(_on_warning_timer_1_timeout)
	warning_timer_2.timeout.connect(_on_warning_timer_2_timeout)
	warning_delay_timer_1.timeout.connect(_on_warning_delay_timer_1_timeout)
	warning_delay_timer_2.timeout.connect(_on_warning_delay_timer_2_timeout)
	grace_period_timer.timeout.connect(_on_grace_period_timer_timeout)
	
	static_transition.animation_finished.connect(_on_static_2_animation_finished)
	
	camera_name_textures = {
		"CAM_01": name_img_cam01,
		"CAM_02": name_img_cam02,
		"CAM_03": name_img_cam03,
		"CAM_04": name_img_cam04,
		"CAM_05": name_img_cam05,
		"CAM_06": name_img_cam06,
		"CAM_07": name_img_cam07,
		"CAM_08": name_img_cam08,
		"CAM_09": name_img_cam09,
		"CAM_10": name_img_cam10,
		"CAM_11": name_img_cam11,
		"CAM_12": name_img_cam12
	}
	
	camera_content = {
		"CAM_01": "Empty",
		"CAM_02": "Empty",
		"CAM_03": "Empty",
		"CAM_04": "Empty",
		"CAM_05": "Empty",
		"CAM_06": "Empty",
		"CAM_07": "Empty",
		"CAM_08": "Empty",
		"CAM_09": "Empty",
		"CAM_10": "Empty",
		"CAM_11": "Empty",
		"CAM_12": "Empty"
	}
	
	camera_textures = {
		"CAM_01": {
			"Dark_Empty": cam01_dark_empty,
			"Lit_Empty": cam01_lit_empty,
			"Lit_Bonnie": cam01_lit_bonnie,
			"Lit_ToyChica": cam01_lit_toychica
		},
		"CAM_02": {
			"Dark_Empty": cam02_dark_empty,
			"Lit_Empty": cam02_lit_empty,
			"Dark_Chica": cam02_dark_chica,
			"Lit_Chica": cam02_lit_chica,
			"Lit_ToyBonnie": cam02_lit_toybonnie
		},
		"CAM_03": {
			"Dark_Empty": cam03_dark_empty,
			"Lit_Empty": cam03_lit_empty,
			"Dark_Freddy": cam03_dark_freddy,
			"Lit_Freddy": cam03_lit_freddy,
			"Lit_ToyBonnie": cam03_lit_toybonnie
		},
		"CAM_04": {
			"Dark_Empty": cam04_dark_empty,
			"Lit_Empty": cam04_lit_empty,
			"Lit_ToyChica": cam04_lit_toychica,
			"Lit_Chica": cam04_lit_chica,
			"Dark_ToyBonnie": cam04_dark_toybonnie,
			"Lit_ToyBonnie": cam04_lit_toybonnie
		},
		"CAM_05": {
			"Dark_Empty": cam05_dark_empty,
			"Lit_Empty": cam05_lit_empty,
			"Lit_ToyChica": cam05_lit_toychica,
			"Lit_Bonnie": cam05_lit_bonnie,
			"Lit_BB": cam05_lit_bb,
			"Lit_Endo": cam05_lit_endo
		},
		"CAM_06": {
			"Dark_Empty": cam06_dark_empty,
			"Lit_Empty": cam06_lit_empty,
			"Lit_ToyBonnie": cam06_lit_toybonnie,
			"Lit_Mangle": cam06_lit_mangle,
			"Lit_Chica": cam06_lit_chica
		},
		"CAM_07": {
			"Dark_Empty": cam07_dark_empty,
			"Lit_Empty": cam07_lit_empty,
			"Dark_ToyChica": cam07_dark_toychica,
			"Lit_ToyChica": cam07_lit_toychica,
			"Lit_Bonnie": cam07_lit_bonnie,
			"Lit_Freddy": cam07_lit_freddy
		},
		"CAM_08": {
			"Dark_Empty": cam08_dark_empty,
			"Lit_Empty": cam08_lit_empty,
			"Dark_Chica": cam08_dark_chica,
			"Lit_Chica": cam08_lit_chica,
			"Lit_Bonnie": cam08_lit_bonnie,
			"Lit_Freddy": cam08_lit_freddy,
			"Lit_Foxy": cam08_lit_foxy,
			"Lit_ShadowFreddy": cam08_lit_shadowfreddy
		},
		"CAM_09": {
			"Dark_Empty": cam09_dark_empty,
			"Lit_Empty": cam09_lit_empty,
			"Dark_ToyBonnie": cam09_dark_toybonnie,
			"Lit_ToyBonnie": cam09_lit_toybonnie,
			"Dark_ToyChica": cam09_dark_toychica,
			"Lit_ToyChica": cam09_lit_toychica,
			"Dark_ToyFreddy": cam09_dark_toyfreddy
		},
		"CAM_10": {
			"Dark_Empty": cam10_dark_empty,
			"Lit_Empty": cam10_lit_empty,
			"Dark_BB": cam10_dark_bb,
			"Lit_BB": cam10_lit_bb,
			"Lit_ToyFreddyBB": cam10_lit_toyfreddybb,
			"Lit_ToyFreddy": cam10_lit_toyfreddy
		},
		"CAM_11": {
			"Dark_Empty": cam11_dark_empty,
			"Lit_Empty": cam11_lit_empty,
			"Lit_Puppet1": cam11_lit_puppet1,
			"Lit_Puppet2": cam11_lit_puppet2,
			"Lit_PuppetFinal": cam11_lit_puppetFinal,
			"Lit_Endo": cam11_lit_endo
		},
		"CAM_12": {
			"Dark_Empty": cam12_dark_empty,
			"Lit_Empty": cam12_lit_empty,
			"Lit_Mangle": cam12_lit_mangle
		}
	}
	
	for cams in cam_buttons_root.get_children():
		cams.button_group = group

	for cam_view in camViews.get_children():
		cam_view.hide()
		
	camTween = create_tween().set_loops()
	camTween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	camTween.tween_property(self, "pan_value", -pan_amount, pan_duration)
	camTween.tween_property(self, "pan_value", 0.0, pan_duration)
	
	cambiar_vista_a("CAM_09")
	
	music_box_bar.value = 100.0
	
	music_box_circle.play("reload") 
	update_circle_animation()
	

func buttongroup_pressed(button : TextureButton):
		cambiar_vista_a(button.name)

func _process(delta):
	if music_box_locked:
		return

	if music_box_button.is_pressed():

		if is_in_grace_period:
			grace_period_timer.stop()
			is_in_grace_period = false
		
		music_box_bar.value += wind_rate * delta 
		music_box_bar.value = clamp(music_box_bar.value, 0, 100)
		
	else:
		music_box_bar.value -= drain_rate * delta
	
	music_box_bar.value = clamp(music_box_bar.value, 0, 100)

	update_circle_animation()

	if music_box_bar.value <= 0:
		if not is_in_grace_period:
			is_in_grace_period = true
			grace_period_timer.start()
			print("¡PERIODO DE GRACIA INICIADO!")
	else:
		if is_in_grace_period:
			grace_period_timer.stop()
			is_in_grace_period = false

	if curCam and curCam.is_in_group("panning_cameras"):
		curCam.position.x = pan_value

func cambiar_vista_a(nombre_camara: String):
	static_transition.show()
	static_transition.play()
	
	if curCam:
		curCam.hide()
		curCam.position.x = 0
		
	curCam = camViews.get_node(nombre_camara)
	curCam.show()
	
	update_camera_view()
	
	if curCam.is_in_group("panning_cameras"):
		curCam.position.x = pan_value
	else:
		curCam.position.x = 0
	
	if camera_name_textures.has(nombre_camara):
		camera_name_display.texture = camera_name_textures[nombre_camara]
	else:
		camera_name_display.texture = null
		
	if nombre_camara == "CAM_11":
		music_box_bar.visible = true
		music_box_circle.visible = true
		music_box_button.visible = true
		music_box_button.disabled = false
	else:
		music_box_bar.visible = false
		music_box_circle.visible = false
		music_box_button.visible = false
		music_box_button.disabled = true
	
func _on_static_2_animation_finished():
	static_transition.hide()


func update_camera_view():
	if not curCam:
		return

	var cam_name = curCam.name
	var content = camera_content.get(cam_name, "Empty") 
	var texture_to_show = null

	if not camera_textures.has(cam_name):
		print("¡ERROR GRAVE! La cámara '", cam_name, "' no existe en camera_textures.")
		return
	
	if is_flashlight_on:
		if camera_textures[cam_name].has("Lit_" + content):
			texture_to_show = camera_textures[cam_name]["Lit_" + content]
		else: 
			texture_to_show = camera_textures[cam_name]["Lit_Empty"]
	else:
		if camera_textures[cam_name].has("Dark_" + content):
			texture_to_show = camera_textures[cam_name]["Dark_" + content]
		else: 
			texture_to_show = camera_textures[cam_name]["Dark_Empty"]
	
	if texture_to_show:
		curCam.texture = texture_to_show
	else:
		print("¡ERROR! No se encontró textura para: ", cam_name, " con estado ", content)
		curCam.texture = camera_textures[cam_name]["Dark_Empty"]


func _on_flash_light_button_down() -> void:
	is_flashlight_on = true
	update_camera_view()

func _on_flash_light_button_up() -> void:
	is_flashlight_on = false
	update_camera_view()
	
func set_camera_content(camera_name: String, content: String):
	camera_content[camera_name] = content
	if curCam and curCam.name == camera_name:
		update_camera_view()

func update_circle_animation():
	var current_value = music_box_bar.value
	var total_frames = 20.0
	var new_frame = int(round((current_value / 100.0) * total_frames))
	
	music_box_circle.frame = new_frame

	if new_frame <= 2:
		
		if warning_delay_timer_2.is_stopped() and not is_warning_2_pending:
			warning_delay_timer_2.start() 
			is_warning_2_pending = true
	else:
		
		warning_sign_2.hide()
		warning_timer_2.stop()
		warning_delay_timer_2.stop()
		is_warning_2_pending = false

	
	if new_frame <= 8:
		
		if warning_delay_timer_1.is_stopped() and not is_warning_1_pending:
			warning_delay_timer_1.start()
			is_warning_1_pending = true
	else:
		
		warning_sign_1.hide()
		warning_timer_1.stop()
		warning_delay_timer_1.stop()
		is_warning_1_pending = false

func _on_rec_timer_timeout() -> void:
	rec_dot.visible = not rec_dot.visible

func _on_warning_timer_1_timeout():
	
	warning_sign_1.visible = not warning_sign_1.visible

func _on_warning_timer_2_timeout():
	
	warning_sign_2.visible = not warning_sign_2.visible
func _on_warning_delay_timer_1_timeout():
	is_warning_1_pending = false 

	if music_box_bar.value <= (8.0 / 20.0) * 100.0 and not music_box_locked:
		warning_timer_1.start() 

func _on_warning_delay_timer_2_timeout():
	is_warning_2_pending = false
	if music_box_bar.value <= (2.0 / 20.0) * 100.0 and not music_box_locked:
		warning_timer_2.start()

func stop_all_warnings():
	warning_sign_1.hide()
	warning_timer_1.stop()
	warning_delay_timer_1.stop()
	is_warning_1_pending = false
	
	warning_sign_2.hide()
	warning_timer_2.stop()
	warning_delay_timer_2.stop()
	is_warning_2_pending = false
	
func _on_grace_period_timer_timeout():
	is_in_grace_period = false
	
	
	if music_box_bar.value <= 0:
		print("¡PERIODO DE GRACIA TERMINADO! Caja bloqueada.")
		
		
		music_box_locked = true
		emit_signal("puppet_is_loose")
		stop_all_warnings()
		
func on_animatronic_moved():
	if not self.visible:
		return 
	$StaticTransition.show()
	$StaticTransition.play()
	$SignalInterrupted.show()
	
	if $StaticTransition.animation_finished:
		$StaticTransition.hide()
		$SignalInterrupted.hide()
	
