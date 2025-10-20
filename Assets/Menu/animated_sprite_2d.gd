extends AnimatedSprite2D

@export var speed = 1.0
var screen_size

func _ready():
	screen_size = get_viewport_rect()
	
func _process(delta):
	$AnimatedSprite2D.animation = "default"
	$AnimationSprite2D.play()
	
	
	
	
