extends Control

@onready var check_display = $CheckDisplay
@onready var music_player = $AudioStreamPlayer

@export var img_check_night_5: Texture2D
@export var img_check_night_6: Texture2D
@export var img_pink_slip: Texture2D   

var duration = 10.0

func _ready():
	
	if Global.current_night == 6:
		check_display.texture = img_check_night_5 	
	elif Global.current_night == 7:
		check_display.texture = img_check_night_6
	elif Global.current_night > 7:
		check_display.texture = img_pink_slip	
	else:
		check_display.texture = img_check_night_5
	
	
	music_player.play()
	
	
	await get_tree().create_timer(duration).timeout
	go_to_menu()

func go_to_menu():
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	get_tree().change_scene_to_file("res://menu_principal.tscn")
