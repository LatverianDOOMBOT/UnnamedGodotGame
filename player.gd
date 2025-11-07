extends CharacterBody3D

@onready var camera = $RotationPivot/PlayerCamera
@onready var rotation_pivot = $RotationPivot
@export var speed : int = 5

func _physics_process(delta):
	var direction = Vector3.ZERO
	

	if Input.is_action_pressed("Forward"):
		direction.z -= 1.0  
		
	if Input.is_action_pressed("Backward"):
		direction.z += 1.0
		
	if Input.is_action_pressed("Right"):
		direction.x += 1.0
		
	if Input.is_action_pressed("Left"):
		direction.x -= 1.0
	

	if Input.is_action_just_pressed("rotateL"):
		rotation_pivot.rotate_y(deg_to_rad(90.0))
		
	if Input.is_action_just_pressed("rotateR"):
		rotation_pivot.rotate_y(deg_to_rad(-90.0))
	

	direction = rotation_pivot.global_transform.basis * direction
	

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0

	
	move_and_slide()
