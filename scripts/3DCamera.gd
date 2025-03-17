extends Camera3D

# Camera properties
@export var target: NodePath  ## Path to the target node (e.g., the vehicle)
@export var distance: float = 4.0  ## Distance from the target
@export var min_zoom: float = 8.0  ## Closest zoom
@export var max_zoom: float = 14.0  ## Farthest zoom
@export var zoom_speed: float = 0.2  ## Zoom intensity
@export var height: float = 2.0  ## Height above the target
@export var rotation_speed: float = 5.0  ## Speed of rotation (degrees per second)
@export var pitch_limit: Vector2 = Vector2(-20, 20)  ## Pitch limits in degrees
@export var yaw_limit: Vector2 = Vector2(-20, 20)  ## Yaw limits in degrees

# Camera state
var current_pitch: float = 10.0  ## Initial pitch angle
var current_yaw: float = 0.0  ## Current yaw angle
var head_pitch: float = 0.0  ## Mouse-controlled vertical angle
var head_yaw: float = 0.0  ## Mouse-controlled horizontal angle
var target_head_pitch: float = 0.0  ## Smooth target for pitch
var target_head_yaw: float = 0.0  ## Smooth target for yaw
var mouse_sensitivity: float = 0.06  ## Sensitivity for mouse input
var mouse_captured: bool = true  ## Track if mouse is locked

# Zoom control
var target_distance: float = distance  ## The distance we are easing towards
var tween: Tween  ## Tween instance for smooth zooming

func _ready():
	# Ensure zoom starts at min_zoom instead of a random value
	target_distance = clamp(distance, min_zoom, max_zoom)
	distance = target_distance  # Immediately set distance to a valid zoom level
	look_at_target()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Capture mouse
	tween = create_tween()  # Initialize tween

func _input(event):
	# Mouse movement controls "head rotation" (not orbit)
	if event is InputEventMouseMotion and mouse_captured:
		target_head_yaw -= event.relative.x * mouse_sensitivity
		target_head_pitch -= -event.relative.y * mouse_sensitivity
		
		# ✅ Apply soft limits using ease-in-out clamping
		target_head_pitch = clamp(target_head_pitch, pitch_limit.x, pitch_limit.y)
		target_head_yaw = clamp(target_head_yaw, yaw_limit.x, yaw_limit.y)
	
	# Mouse Scroll (Zoom)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			update_zoom(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			update_zoom(zoom_speed)

	# Press ESC to toggle mouse capture
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_captured = not mouse_captured
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	var target_node = get_node_or_null(target)
	if target_node:
		rotate_camera(delta)

func rotate_camera(delta: float):
	var target_node = get_node_or_null(target)
	if not target_node:
		return
	
	# Gradually adjust actual distance using smooth interpolation
	distance = lerp(distance, target_distance, delta * 4.0)  # Smoothing factor
	
	# Orbit around the target
	current_yaw += rotation_speed * delta
	var yaw_rad = deg_to_rad(current_yaw)

	# Compute new camera position based on orbit
	var offset = Vector3(0, 0, -distance).rotated(Vector3.UP, yaw_rad)
	position = target_node.global_transform.origin + offset + Vector3(0, height, 0)

	# Calculate where the camera is looking
	var look_at_point = target_node.global_transform.origin
	
	# ✅ Smooth easing effect for head rotation
	head_pitch = lerp(head_pitch, target_head_pitch, ease(abs(target_head_pitch - head_pitch), 0.7) * delta * 10.0)
	head_yaw = lerp(head_yaw, target_head_yaw, ease(abs(target_head_yaw - head_yaw), 0.2) * delta * 10.0)

	# Apply "head movement" (head_pitch and head_yaw affect direction, not orbit)
	var final_look_vector = (look_at_point - position) \
		.rotated(Vector3.RIGHT, deg_to_rad(head_pitch)) \
		.rotated(Vector3.UP, deg_to_rad(head_yaw))

	look_at(position + final_look_vector, Vector3.UP)

func update_zoom(zoom_change: float):
	# Set new target zoom level and clamp it
	target_distance = clamp(target_distance + zoom_change, min_zoom, max_zoom)

	# Use tween for smooth zoom effect
	if tween.is_running():
		tween.kill()  # Cancel any ongoing tween
	tween = create_tween()  # Create a new tween
	tween.tween_property(self, "distance", target_distance, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
func look_at_target():
	var target_node = get_node_or_null(target)
	if target_node:
		# Place the camera initially at a fixed offset
		position = target_node.global_transform.origin + Vector3(0, height, -distance)
		look_at(target_node.global_transform.origin, Vector3.UP)
