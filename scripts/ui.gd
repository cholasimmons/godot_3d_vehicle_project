# In your GUI script (e.g., attached to the Control node)
extends Control

@onready var vehicle_status_frame = $BoxContainer3/ColorRectL2
@onready var vehicle_status_label = $BoxContainer3/ColorRectL2/VehicleStatus
@onready var engine_status_label = $BoxContainer/HBoxContainer/VBoxValues/EngineValue
@onready var rpm_label = $BoxContainer/HBoxContainer/VBoxValues/RPMValue
@onready var gear_label = $BoxContainer/HBoxContainer/VBoxValues/GearValue
#@onready var accelerator_bar = $BoxContainer2/HBoxContainer/VBox2Values/AcceleratorValue
@onready var accelerator_label = $BoxContainer2/HBoxContainer/VBox2Values/AcceleratorValue
@onready var brake_label = $BoxContainer2/HBoxContainer/VBox2Values/BrakeValue
@onready var steering_label = $BoxContainer2/HBoxContainer/VBox2Values/SteeringValue

var engine_status = "..."
var vehicle_status: String

func _ready() -> void:
	if !vehicle_status:
		vehicle_status_frame.visible = false

func _on_rpm_updated(rpm: float):
	rpm_label.text = str(int(rpm))

func _on_accelerator_updated(input: float):
	accelerator_label.text = "%.3f" % input

func _on_brake_updated(input: float):
	brake_label.text = "%.3f" % input

func _on_steering_updated(input: float):
	# steering_bar.value = steering_input * 0.5 + 0.5  # Map -1 to 1 range to 0 to 1 for ProgressB
	steering_label.text = "%.2f" % input


# Engine
func _on_engine_starting():
	engine_status  = "Starting..."
	engine_status_label.text = engine_status

func _on_engine_started():
	engine_status = "On"
	engine_status_label.text = engine_status
	emit_signal("engine_toggled", true)  # Emit engine_toggled here

func _on_engine_failed_to_start(message: String):
	engine_status = "Off!!"
	print("Ignition fail: ",message)
	engine_status_label.text = engine_status

func _on_engine_toggled(is_on: bool):
	# Update the engine status label
	engine_status = "On" if is_on else "Off"
	engine_status_label.text = engine_status



# Gears
func _on_gear_updated(gear: int):
	# Update the engine status label
	var gear_msg = "N" if gear == 0 else "R" if gear < 0 else str(gear)
	gear_label.text = gear_msg



# General Vehicle status
func _on_vehicle_status_updated(message: String):
	if message.is_empty():
		vehicle_status_frame.visible = false
	else:
		vehicle_status_label.text = message
		vehicle_status_frame.visible = true
