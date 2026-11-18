extends CharacterBody3D

# Mouse sensitivity for looking around
@export var mouse_sensitivity := 0.5

# Player movement speed
@export var speed := 5.0
const JUMP_VELOCITY = 4.5

# Stores the object currently detected by the raycast
var raycast_target: CollisionObject3D = null


func _ready() -> void:
	# Capture the mouse for first-person camera controls
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Prevent the raycast from detecting the player itself
	%RayCast3D.add_exception(self)

func _unhandled_input(event: InputEvent) -> void:
	# Handle mouse movement to rotate the player and camera
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		%Camera3D.rotation_degrees.x -= event.relative.y * mouse_sensitivity

		# Limit vertical camera rotation
		%Camera3D.rotation_degrees.x = clamp(%Camera3D.rotation_degrees.x, -80.0, 80.0)

	# Handle mouse clicks
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Capture the mouse again if it is currently visible
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				# Delete the object the raycast is pointing at, except the ground
				if is_instance_valid(raycast_target) and raycast_target.name != "Ground":
					raycast_target.queue_free()

	# Release the mouse when Escape is pressed
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	# Apply gravity while the player is in the air
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump when the jump action is pressed and the player is on the floor
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get movement input and convert it into a direction relative to the player
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply movement or gradually slow the player down when there is no input
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Move the player and handle collisions
	move_and_slide()

	# Reset the raycast target before checking for a new collision
	raycast_target = null

	# Check whether the raycast is detecting an object
	if %RayCast3D.is_colliding():
		raycast_target = %RayCast3D.get_collider() as CollisionObject3D

		if is_instance_valid(raycast_target):
			print("Raycast hit:", raycast_target.name)
			
	# Handle collisions with other physics bodies
	handle_collisions()
			

# Checks for collisions with other physics bodies and pushes any RigidBody3D objects the player touches.
func handle_collisions() -> void:
	# get_slide_collision_count() returns the number of collisions detected during the current movement.
	for i in get_slide_collision_count():
		# Get collision information
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		# Check if the collided object is a RigidBody3D
		if collider is RigidBody3D:
			print("Player Collider hit:",collider.name)
			
			# Get the direction to push the object
			var push_direction = -collision.get_normal()
			
			# Apply an impulse to push the object
			collider.apply_central_impulse(push_direction * 2.0)
