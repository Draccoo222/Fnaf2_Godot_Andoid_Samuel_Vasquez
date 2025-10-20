extends Control

@onready var officeBG = $MaskView/OfficeBG
@onready var leftBtn = $LeftMove
@onready var rightBtn = $RightMove
@onready var desk = $MaskView/desk
@onready var maskAnim = $FreddyMask
@onready var monitorAnim = $Monitor


@export var desk_offset_x: float = 0.0
@export var parralax_factor_desk: float = 1.2

@export_group("Idle Mask Movement")
@export var idle_amplitude_x: float = 8.0
@export var idle_amplitude_y: float = 4.0
@export var idle_speed: float = 1.0

@export_group("Office Textures")
@export var default_ofc = Texture2D
@export var leftON = Texture2D
@export var rightON = Texture2D
@export var hallON = Texture2D


var widthScreen: float
var movementLim: float
var panSpeed = 400.0

var CAM_ON = false
var cam_is_fully_on = false

var MASK_ON = false
var mask_is_fully_on = false
var idle_time_counter: float = 0.0
var initial_mask_pos: Vector2

func _ready():
	await ready
	widthScreen = get_viewport_rect().size.x
	movementLim = officeBG.get_rect().size.x - widthScreen
	if movementLim <= 0:
		movementLim = 0
	desk.play("default")
	
	initial_mask_pos = maskAnim.position

func _process(delta):
	if leftBtn.is_pressed():
		officeBG.position.x += panSpeed * delta
	if rightBtn.is_pressed():
		officeBG.position.x -= panSpeed * delta
	officeBG.position.x = clamp(officeBG.position.x, -movementLim + 5, -5)
	desk.position.x = (officeBG.position.x * parralax_factor_desk) + desk_offset_x
	$LeftLight.position.x = (officeBG.position.x ) + 100
	$RightLight.position.x = (officeBG.position.x ) + 1425
	#$HallLight.position.x = (officeBG.position.x) + 500
		
	if mask_is_fully_on:
		idle_time_counter += delta * idle_speed
		var offset_x = sin(idle_time_counter) * idle_amplitude_x
		var offset_y = cos(idle_time_counter * 2.0) * idle_amplitude_y
		maskAnim.position = initial_mask_pos + Vector2(offset_x, offset_y)

func _on_mask_button_pressed() -> void:
	MASK_ON = not MASK_ON
	maskAnim.show()
	if not CAM_ON:
		if MASK_ON:
			mask_is_fully_on = false
			maskAnim.play("activate")
			var scale_tween = create_tween()
			scale_tween.tween_property(maskAnim, "scale:x", 1.2, 0.25)
		else:
			mask_is_fully_on = false 
			maskAnim.position = initial_mask_pos 
			maskAnim.play("deactivate")
			var scale_tween = create_tween()
			scale_tween.tween_property(maskAnim, "scale:x", 1.0, 0.2)

func _on_freddy_mask_animation_finished() -> void:
	if MASK_ON:
	
		mask_is_fully_on = true
		idle_time_counter = 0.0 
	else:
	
		maskAnim.hide()
		
func _on_left_light_button_down() -> void:
	officeBG.texture = leftON
	
func _on_left_light_button_up() -> void:
	officeBG.texture = default_ofc

func _on_right_light_button_up() -> void:
	officeBG.texture = default_ofc
	
func _on_right_light_button_down() -> void:
	officeBG.texture =  rightON


func _on_hall_light_button_down() -> void:
	if  MASK_ON:
		return
	officeBG.texture = hallON


func _on_hall_light_button_up() -> void:
	officeBG.texture = default_ofc


func _on_camera_toggle_pressed() -> void:
	CAM_ON = not CAM_ON
	monitorAnim.show()
	if not MASK_ON:
		if CAM_ON:
			monitorAnim.play("monitorOn")
			var scale_tween = create_tween()
			scale_tween.tween_property(monitorAnim, "scale:x", 1.2, 0.25)
		else:
			monitorAnim.play("monitorOff")
			var scale_tween = create_tween()
			scale_tween.tween_property(monitorAnim, "scale:x", 1, 0.2)
