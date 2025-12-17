extends Control

@onready var clock_anim = $ClockAnim
@onready var confetti_anim = $ConfettiAnim
@onready var chime_sound = $ClockChime
@onready var kids_sound = $CheerSound

@export var confetti_frames: SpriteFrames 

@export var confetti_amount: int = 200
@export var spawn_interval: float = 0.05

var next_scene_path = "res://menu_principal.tscn"
var confetti_timer: Timer

func _ready() -> void:
	confetti_timer = Timer.new()
	confetti_timer.wait_time = spawn_interval
	confetti_timer.one_shot = false
	confetti_timer.timeout.connect(_spawn_single_confetti)
	add_child(confetti_timer)
	chime_sound.play()
	await get_tree().create_timer(2.0).timeout
	
	start_sequence()
	


func start_sequence():
	clock_anim.play("default")
	await clock_anim.animation_finished
	trigger_celebration()

func trigger_celebration():
	print("Victory: ¡6 AM!")
	

	if confetti_timer:
		confetti_timer.start()
	
		for i in range(20):
			_spawn_single_confetti()
			
	
	kids_sound.play()
	
	if kids_sound.stream:
		await kids_sound.finished
	else:
		
		await get_tree().create_timer(3.0).timeout
	
	go_to_menu()

func _spawn_single_confetti():
	var conf = AnimatedSprite2D.new()
	
	conf.sprite_frames = confetti_frames
	conf.play("default")
	
	var screen_width = get_viewport_rect().size.x
	var random_x = randf_range(0, screen_width)
	
	conf.position = Vector2(random_x, -50)
	
	conf.speed_scale = randf_range(0.5, 2.0)
	
	var scale_factor = randf_range(0.5, 1.2)
	conf.scale = Vector2(scale_factor, scale_factor)
	
	conf.z_index = 10 if randf() > 0.5 else 0

	add_child(conf)
	
	var fall_duration = randf_range(2.0, 5.0)
	var screen_height = get_viewport_rect().size.y
	var end_y = screen_height + 100 
	var tween = create_tween()
	
	tween.tween_property(conf, "position:y", end_y, fall_duration).set_trans(Tween.TRANS_LINEAR)
	

	var drift = randf_range(-100, 100)
	tween.parallel().tween_property(conf, "position:x", random_x + drift, fall_duration)
	
	tween.tween_callback(conf.queue_free)

func go_to_menu():
	confetti_timer.stop()
	
	var tweens = get_tree().get_processed_tweens()
	for t in tweens:
		t.kill()
	
	Global.current_night += 1
	
	

	if Global.current_night > Global.unlocked_night:
		Global.unlocked_night = Global.current_night
	
	Global.save_data()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 3.0)
	await tween.finished
	
	if Global.current_night == 6: 
		get_tree().change_scene_to_file("res://paycheck.tscn")
	elif Global.current_night == 7:
		get_tree().change_scene_to_file("res://paycheck.tscn")
	else:
		print("Victory: Volviendo continuando con la siguente noche.")
		get_tree().change_scene_to_file("res://nigthTransition.tscn")
