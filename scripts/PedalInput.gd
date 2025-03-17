extends Node

class_name Vehicle_Pedal_Input

# Pedal properties
@export var foot_speed: float = 3.0  # How fast the pedal moves from 0 to 1


# Pedal state
var current_accelerator_input: float = 0.0
var current_brake_input: float = 0.0
var target_accelerator_input: float = 0.0
var target_brake_input: float = 0.0

# Signals
signal accelerator_input_updated(input: float)
signal brake_input_updated(input: float)

func set_accelerator_target_input(target: float):
	target_accelerator_input = clamp(target, 0.0, 1.0)
func set_brake_target_input(target: float):
	target_brake_input = clamp(target, 0.0, 1.0)

func _process(delta):
	if current_accelerator_input < target_accelerator_input:
		current_accelerator_input += (foot_speed / 3) * delta
	elif current_accelerator_input > target_accelerator_input:
		current_accelerator_input -= (foot_speed / 3) * delta
		
	if current_brake_input < target_brake_input:
		current_brake_input += foot_speed * delta
	elif current_brake_input > target_brake_input:
		current_brake_input -= foot_speed * delta

	current_accelerator_input = clamp(current_accelerator_input, 0.0, 1.0)
	current_brake_input = clamp(current_brake_input, 0.0, 1.0)
	
	accelerator_input_updated.emit(current_accelerator_input)
	brake_input_updated.emit(current_brake_input)
