extends Control

@onready var blip_sound = $Blip
@onready var transition_image = $TransitionImage
@onready var newspaper_display = $Newspaper
@onready var fade_overlay = $FadeOverlay
@export_subgroup("Night Labels")
@export var img_night_1: Texture2D   
@export var img_night_2: Texture2D    
@export var img_night_3: Texture2D   
@export var img_night_4: Texture2D  
@export var img_night_5: Texture2D    
@export var img_night_6: Texture2D   
@export var img_night_7: Texture2D    

@export_group("Newspaper")
@export var img_newspaper: Texture2D

var night_number: int = 1 
var game_scene_path = "res://test_night.tscn"

func _ready():
	
	if has_node("/root/Global"):
		night_number = Global.current_night
	
	transition_image.visible = false
	newspaper_display.visible = false
	
	fade_overlay.color.a = 1.0 
	fade_overlay.visible = true
	
	setup_visuals()
	
	if night_number == 1:
		start_newspaper_sequence()
	else:
		await get_tree().create_timer(0.5).timeout
		start_transition_sequence()

func setup_visuals():
	
	if img_newspaper:
		newspaper_display.texture = img_newspaper
	
	
	var selected_texture = img_night_1
	match night_number:
		1: selected_texture = img_night_1
		2: selected_texture = img_night_2
		3: selected_texture = img_night_3
		4: selected_texture = img_night_4
		5: selected_texture = img_night_5
		6: selected_texture = img_night_6
		7: selected_texture = img_night_7
	
	if selected_texture:
		transition_image.texture = selected_texture

func start_newspaper_sequence():
	print("Mostrando periódico...")
	newspaper_display.visible = true
	
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 2.0) 
	await tween.finished
	
	await get_tree().create_timer(5.0).timeout
	
	
	var tween_out = create_tween()
	tween_out.tween_property(fade_overlay, "color:a", 1.0, 1.5)
	await tween_out.finished
	
	
	newspaper_display.visible = false
	
	start_transition_sequence()

func start_transition_sequence():
	
	fade_overlay.color.a = 1.0 
	
	await get_tree().create_timer(0.5).timeout
	
	
	if blip_sound.stream:
		blip_sound.play()
	
	fade_overlay.color.a = 0.0 
	transition_image.visible = true
	
	
	await get_tree().create_timer(2.5).timeout
	
	transition_image.visible = false
	
	await get_tree().create_timer(0.5).timeout
	
	load_game()

func load_game():
	get_tree().change_scene_to_file(game_scene_path)
