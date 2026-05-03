extends Node3D

@export var move_speed: float = 5.0
@export var mouse_sensitivity: float = 0.002

@onready var camera: Camera3D = $Camera3D

var pitch: float = 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -PI/2, PI/2)
		camera.rotation.x = pitch
	
	# Press Escape to release mouse (so you can click outside the window)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta):
	var input_dir := Vector3.ZERO
	
	# Horizontal movement (relative to where you're facing)
	if Input.is_key_pressed(KEY_W):
		input_dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_dir += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		input_dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_dir += transform.basis.x
	
	# Vertical movement (world-space up/down — like a drone)
	if Input.is_key_pressed(KEY_SPACE):
		input_dir += Vector3.UP
	if Input.is_key_pressed(KEY_SHIFT):
		input_dir -= Vector3.UP
	
	# Apply movement
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	position += input_dir * move_speed * delta
