extends Node

class_name Vehicle_Steering

# Steering properties
@export var max_steering_angle: float = 45.0  # Maximum steering angle in degrees
@export var steering_speed: float = 1.1  # How fast the steering input changes

# Steering state
var current_steering_input: float = 0.0  # -1.0 (left) to 1.0 (right)
var target_steering_input: float = 0.0

# Signals
signal steering_input_updated(steering_input: float)

func set_target_steering_input(target: float):
	target_steering_input = clamp(target, -1.0, 1.0)

func _process(delta):
	# Smoothly interpolate the current steering input towards the target
	if current_steering_input < target_steering_input:
		current_steering_input = min(current_steering_input + steering_speed * delta, target_steering_input)
	elif current_steering_input > target_steering_input:
		current_steering_input = max(current_steering_input - steering_speed * delta, target_steering_input)

	current_steering_input = clamp(current_steering_input, -1.0, 1.0)
	steering_input_updated.emit(current_steering_input)
