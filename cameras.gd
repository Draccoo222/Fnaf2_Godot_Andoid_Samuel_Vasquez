extends Control

@onready var camViews = $CamViews
var curCam: TextureRect

@export_group("Camera Panning")
@export var panning_cams: Array[StringName];

var camTween: Tween;

func _ready():
	$Static.play()
	var group: ButtonGroup = ButtonGroup.new()
	group.pressed.connect(buttongroup_pressed)
	for cams in $CamButtons.get_children():
		cams.button_group = group

	for cam_view in camViews.get_children():
		cam_view.hide()
	
	cambiar_vista_a("CAM_09")

func buttongroup_pressed(button : TextureButton):
		cambiar_vista_a(button.name)



func cambiar_vista_a(nombre_camara: String):
	if curCam:
		curCam.hide()
		
	curCam = camViews.get_node(nombre_camara)
	curCam.show()
	
