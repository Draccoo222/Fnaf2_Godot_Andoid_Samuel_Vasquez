extends Control

var rand = 0

@onready var animatronics_sprite = $Animatronics
@onready var timer_twitch = $Timer      
@onready var timer_reset = $Timer2     
@onready var static_anim = $AnimatedSprite2D

@onready var tex_freddy = $AnimatronicsFreddy.texture
@onready var tex_bonnie = $AnimatronicsBunny.texture
@onready var tex_chica = $AnimatronicsChica.texture
@onready var tex_placeholder = $AnimsPlaceHolder.texture
@onready var night_number_display = $Continue/NightLabel

@export_group("Menu Numbers")
@export var img_num_1: Texture2D
@export var img_num_2: Texture2D
@export var img_num_3: Texture2D
@export var img_num_4: Texture2D
@export var img_num_5: Texture2D 
@export var img_num_6: Texture2D 
@export var img_num_7: Texture2D

@onready var new_game_btn = $NewGame
@onready var continue_btn = $Continue
@onready var night_label = $Continue/NightLabel 

var transition_scene_path = "res://nigthTransition.tscn"

func _ready():
	$MainTheme.play()
	timer_twitch.start(5)
	if static_anim: static_anim.play()
	

	if has_node("/root/Global"):
		if Global.unlocked_night > 1:
			continue_btn.visible = true
			continue_btn.disabled = false
			
			var selected_texture = img_num_1
		
			match Global.unlocked_night:
				1: selected_texture = img_num_1
				2: selected_texture = img_num_2
				3: selected_texture = img_num_3
				4: selected_texture = img_num_4
				5: selected_texture = img_num_5
				6: selected_texture = img_num_6
				7: selected_texture = img_num_7
			
		
			if night_number_display and selected_texture:
				night_number_display.texture = selected_texture
			else:
				continue_btn.visible = false
	else:
		printerr("ERROR CRÍTICO: No se detectó el script Global.")

func ir_a_transicion():
	$MainTheme.stop()
	var transition_packed = load(transition_scene_path)
	if transition_packed:
		var transition_instance = transition_packed.instantiate()
		
		if "night_number" in transition_instance and has_node("/root/Global"):
			transition_instance.night_number = Global.current_night
		
		get_tree().root.add_child(transition_instance)
		get_tree().current_scene.queue_free()
		get_tree().current_scene = transition_instance
	else:
		printerr("ERROR: No se encuentra la escena en ", transition_scene_path)

func _on_timer_timeout() -> void:
	rand = randi_range(1, 3)
	if rand == 1: animatronics_sprite.texture = tex_freddy
	elif rand == 2: animatronics_sprite.texture = tex_bonnie
	elif rand == 3: animatronics_sprite.texture = tex_chica
	timer_reset.start(0.15)

func _on_timer_2_timeout() -> void:
	animatronics_sprite.texture = tex_placeholder
	timer_twitch.start(randf_range(0.23, 1.01))

func _on_quit_pressed():
	get_tree().quit()


func _on_new_game_button_down() -> void:
	print("Menu: Nueva Partida -> Noche 1")
	
	if has_node("/root/Global"):
		Global.current_night = 1
		Global.save_data()
	
	ir_a_transicion()


func _on_new_game_pressed() -> void:
	print("Menu: Nueva Partida iniciada.")
	Global.current_night = 1
	Global.save_data() 
	ir_a_transicion()


func _on_continue_pressed() -> void:
	print("¡CLICK DETECTADO! El botón funciona.")
	print("Menu: Continuando en Noche ", Global.unlocked_night)
	Global.current_night = Global.unlocked_night
	ir_a_transicion()
