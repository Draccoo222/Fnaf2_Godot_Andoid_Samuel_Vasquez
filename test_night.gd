extends Control

# --- Referencias a Nodos ---
@onready var officeBG = $MaskView/OfficeBG
@onready var leftBtn = $LeftMove
@onready var rightBtn = $RightMove
@onready var desk = $MaskView/desk
@onready var maskAnim = $FreddyMask
@onready var monitorAnim = $Monitor
@onready var camera_system = $Cameras
@onready var ai_manager = $ai_manager
@onready var flashlight_fail_timer = $FlashlightFailTimer # Timer para el "strobe"
@onready var animatronic_slide_view = $Animatronic_Slide_View # TextureRect para la animación de deslizamiento

# --- Exports de Texturas ---
@export var desk_offset_x: float = 0.0
@export var parralax_factor_desk: float = 1.2

@export var toy_bonnie_slide_texture: Texture2D
# (Añade aquí las texturas de deslizamiento de ToyChica, Mangle, etc.)
# @export var toy_chica_slide_texture: Texture2D 

@export_group("Idle Mask Movement")
@export var idle_amplitude_x: float = 8.0
@export var idle_amplitude_y: float = 4.0
@export var idle_speed: float = 1.0

@export_group("Office Light Textures")
@export var office_dark_default: Texture2D
# Pasillo
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
# Ventilación Izquierda
@export var office_lit_left_empty: Texture2D
@export var office_lit_left_toychica: Texture2D
@export var office_lit_left_bb: Texture2D
# Ventilación Derecha
@export var office_lit_right_empty: Texture2D
@export var office_lit_right_toybonnie: Texture2D
@export var office_lit_right_mangle: Texture2D

# --- Variables de Estado ---
var hall_light_textures = {}
var left_vent_light_textures = {}
var right_vent_light_textures = {}

# Quién está en las zonas de ataque (controlado por el AIManager)
var right_vent_occupant = "Empty"
var left_vent_occupant = "Empty"
var hall_occupant = "Empty"

# Estado de la linterna del pasillo
var is_flashlight_failing = false
const STROBE_ANIMATRONICS = ["Foxy", "WitheredBonnie", "WitheredChica", "WitheredFreddy"]

# Variables de paneo
var widthScreen: float
var movementLim: float
var panSpeed = 400.0

# Variables de estado del jugador
var CAM_ON = false
var MASK_ON = false
var mask_is_fully_on = false # True solo cuando la máscara está 100% bajada
var idle_time_counter: float = 0.0
var initial_mask_pos: Vector2

var slide_tween: Tween


func _ready():
	await ready
	
	# Configuración del Paneo
	widthScreen = get_viewport_rect().size.x
	movementLim = officeBG.get_rect().size.x - widthScreen
	if movementLim <= 0:
		movementLim = 0
	desk.play("default")
	
	# --- Construcción de Diccionarios de Luces ---
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
	
	# Conectar señales
	flashlight_fail_timer.timeout.connect(_on_flashlight_fail_timer_timeout)
	
	
	
	# --- ¡INICIAR LA IA! ---
	var night_1_levels = {
		"ToyBonnie": 20,  # Nivel bajo para Noche 1
		"ToyChica": 1,
		"ToyFreddy": 0
	}
	ai_manager.start_night(night_1_levels, camera_system, self)


func _process(delta):
	# Lógica de paneo de la oficina
	if not MASK_ON and not CAM_ON: # Solo se puede mover si no se hace nada
		if leftBtn.is_pressed():
			officeBG.position.x += panSpeed * delta
		if rightBtn.is_pressed():
			officeBG.position.x -= panSpeed * delta
		officeBG.position.x = clamp(officeBG.position.x, -movementLim + 5, -5)
		desk.position.x = (officeBG.position.x * parralax_factor_desk) + desk_offset_x
		$LeftLight.position.x = (officeBG.position.x ) + 100
		$RightLight.position.x = (officeBG.position.x ) + 1425
	
	# Lógica de movimiento 'idle' de la máscara
	if mask_is_fully_on:
		idle_time_counter += delta * idle_speed
		var offset_x = sin(idle_time_counter) * idle_amplitude_x
		var offset_y = cos(idle_time_counter * 2.0) * idle_amplitude_y
		maskAnim.position = initial_mask_pos + Vector2(offset_x, offset_y)

# --- Lógica de la Máscara (con bloqueo de IA) ---
func _on_mask_button_pressed() -> void:
	if CAM_ON: # No puedes ponerte la máscara si las cámaras están subidas
		return
		
	MASK_ON = not MASK_ON
	maskAnim.show()
	
	if MASK_ON:
		mask_is_fully_on = false
		maskAnim.play("activate")
		var scale_tween = create_tween()
		scale_tween.tween_property(maskAnim, "scale:x", 1.2, 0.25)
		
		# --- ¡LÓGICA DE DEFENSA! ---
		# Comprueba si hay alguien en las ventilaciones CUANDO te pones la máscara
		if right_vent_occupant == "ToyBonnie":
			play_animatronic_slide(toy_bonnie_slide_texture)
			ai_manager.reset_animatronic("ToyBonnie") # ¡Le decimos a la IA que lo resetee!
		
		elif left_vent_occupant == "ToyChica":
			# play_animatronic_slide(toy_chica_slide_texture) # (Cuando la tengas)
			ai_manager.reset_animatronic("ToyChica")
			pass
		
		elif left_vent_occupant == "BB":
			# BB es especial, no se va, solo se ríe y desactiva la luz
			pass

	else:
		# Lógica para quitarse la máscara
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

# --- Lógica de Luces (usando diccionarios) ---
func _on_left_light_button_down() -> void:
	if MASK_ON or is_flashlight_failing:
		return
	officeBG.texture = left_vent_light_textures.get(left_vent_occupant, office_lit_left_empty)

func _on_left_light_button_up() -> void:
	officeBG.texture = office_dark_default

func _on_right_light_button_down() -> void:
	if MASK_ON or is_flashlight_failing:
		return
	officeBG.texture = right_vent_light_textures.get(right_vent_occupant, office_lit_right_empty)

func _on_right_light_button_up() -> void:
	officeBG.texture = office_dark_default

func _on_hall_light_button_down() -> void:
	if MASK_ON or is_flashlight_failing:
		return
	
	if hall_occupant in STROBE_ANIMATRONICS:
		is_flashlight_failing = true
		officeBG.texture = hall_light_textures["Fail"]
		flashlight_fail_timer.start()
		ai_manager.on_hall_flashlight_success(hall_occupant)
	else:
		officeBG.texture = hall_light_textures.get(hall_occupant, office_lit_hall_empty)

func _on_hall_light_button_up() -> void:
	if is_flashlight_failing:
		return
	officeBG.texture = office_dark_default

func _on_flashlight_fail_timer_timeout():
	is_flashlight_failing = false
	officeBG.texture = office_dark_default

# --- Lógica de Cámara (con parada de drenaje) ---
func _on_camera_toggle_pressed() -> void:
	if MASK_ON: # No puedes subir las cámaras si la máscara está puesta
		return
		
	CAM_ON = not CAM_ON
	monitorAnim.show()
	
	if CAM_ON:
		monitorAnim.play("monitorOn")
		# (Aquí puedes añadir tu lógica de scale_tween si la necesitas)
	else:
		# --- Avisa a la IA que bajaste las cámaras ---
		ai_manager.on_cameras_lowered() 
		
		camera_system.hide()
		monitorAnim.play("monitorOff")

func _on_monitor_animation_finished() -> void:
	if CAM_ON and monitorAnim.animation == "monitorOn":
		camera_system.show()
		# --- Avisa a la IA que subiste las cámaras ---
		ai_manager.on_cameras_raised() 
		
	elif not CAM_ON and monitorAnim.animation == "monitorOff":
		monitorAnim.hide()

# --- Animación de Deslizamiento ---
func play_animatronic_slide(texture: Texture2D):
	if slide_tween and slide_tween.is_running():
		slide_tween.kill()

	animatronic_slide_view.texture = texture
	animatronic_slide_view.position.x = 1200 # Ajusta esta posición inicial
	animatronic_slide_view.visible = true

	slide_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	slide_tween.tween_property(animatronic_slide_view, "position:x", -1200, 1.5) # Ajusta la pos final y duración
	slide_tween.tween_callback(animatronic_slide_view.hide)

# --- FUNCIONES PÚBLICAS (Para que el AIManager te llame) ---

func is_mask_on(animatronic_name: String) -> bool:
	if not mask_is_fully_on:
		return false # El jugador no tiene la máscara puesta
	
	if animatronic_name == "ToyBonnie":
		var chance = randi_range(1, 3) # Genera un número del 1 al 3
		if chance == 1: # 1/3 de probabilidad de ÉXITO (o 2/3, ajusta esto)
			print("Oficina: ¡La máscara funcionó contra Toy Bonnie!")
			play_animatronic_slide(toy_bonnie_slide_texture)
			return true # ¡Salvado!
		else:
			print("Oficina: ¡La máscara falló contra Toy Bonnie!")
			return false # ¡Jumpscare!
			
	elif animatronic_name == "ToyChica":
		print("Oficina: ¡La máscara funcionó contra Toy Chica!")
		# play_animatronic_slide(toy_chica_slide_texture)
		return true # Toy Chica siempre es engañada
	
	return true # Por defecto, la máscara funciona

func set_hall_occupant(occupant_name: String):
	hall_occupant = occupant_name
	print("Oficina: Pasillo ocupado por ", hall_occupant)

func set_vent_occupant(vent_name: String, occupant_name: String):
	if vent_name == "LeftVent":
		left_vent_occupant = occupant_name
		print("Oficina: Ventilación Izquierda ocupada por ", left_vent_occupant)
	elif vent_name == "RightVent":
		right_vent_occupant = occupant_name
		print("Oficina: Ventilación Derecha ocupada por ", right_vent_occupant)
