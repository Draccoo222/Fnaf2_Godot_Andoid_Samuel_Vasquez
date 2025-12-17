extends Control

@onready var game_over_image = $GameOverImage
@onready var static_overlay = $StaticOverlay
@onready var sequence_timer = $SequenceTimer
@onready var audio_player = $AudioPlayerS

func _ready():
	
	game_over_image.show()
	static_overlay.hide()
	
	# (Opcional: reproduce un sonido inicial si quieres)
	
	$StaticBefore.play()
	$AudioPlayerS.play()
	
	# 2. Conecta la señal del timer
	sequence_timer.timeout.connect(_on_sequence_timer_timeout)
	$SequenceTimer.start()

# 3. Se llama después de 4 segundos
func _on_sequence_timer_timeout():
	# Oculta la imagen de Game Over
	game_over_image.show()
	
	$StaticBefore.stop()
	$AudioPlayerS.stop()
	$StaticBefore.hide()
	
	static_overlay.show()
	static_overlay.play()
	
	await get_tree().create_timer(4.0).timeout
	
	get_tree().change_scene_to_file("res://menu_principal.tscn")


	
	
