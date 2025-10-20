extends Control

var rand = 0
func _ready():
	$Timer.start(5)
	$AnimatedSprite2D.play()

	
func _on_timer_timeout() -> void:
	rand = randi_range(1, 3)
	if(rand == 1):
		print("Freddy")
		$Animatronics.texture = $AnimatronicsFreddy.texture
	elif(rand == 2):
		print("Bonnie")
		$Animatronics.texture = $AnimatronicsBunny.texture
	elif(rand == 3):
		print("Chica")
		$Animatronics.texture = $AnimatronicsChica.texture
	$Timer2.start(0.15)

func _on_timer_2_timeout() -> void:
	print("Restart")
	$Animatronics.texture = $AnimsPlaceHolder.texture
	$Timer.start(randf_range(0.23, 1.01))
