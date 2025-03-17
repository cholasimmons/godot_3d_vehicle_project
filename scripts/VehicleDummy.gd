extends Node3D

class_name Dummy_Vehicle

@export var engine: NodePath
@export var transmission: NodePath
@export var pedal: NodePath
@export var steering: NodePath

# Onready variables to hold the nodes
@onready var engine_node = get_node(engine) if engine else null
@onready var transmission_node = get_node(transmission) if transmission else null
@onready var steering_node = get_node(steering) if steering else null
@onready var pedal_node = get_node(pedal) if pedal else null

# Reference to the GUI (CanvasLayer -> Control scene)
@onready var gui = get_parent().get_node("GUI/Control") if get_parent().has_node("GUI/Control") else null

# Signals
signal vehicle_status(message: String)

# Default Messages
var engine_missing_msg = "Engine is missing!"
var transmission_missing_msg = "Transmission is missing!"
var pedal_missing_msg = "Pedals are missing!"
var steering_missing_msg = "Steering rack missing!"

func _ready():
	self.vehicle_status.connect(gui._on_vehicle_status_updated)
	# Check for missing components
	if engine_node and gui:
		# Connect engine signals to update the GUI
		engine_node.engine_toggled.connect(gui._on_engine_toggled)
		engine_node.engine_starting.connect(gui._on_engine_starting)
		engine_node.engine_started.connect(gui._on_engine_started)
		engine_node.engine_failed_to_start.connect(gui._on_engine_failed_to_start)
		engine_node.rpm_updated.connect(gui._on_rpm_updated)
		engine_node.accelerator_updated.connect(gui._on_accelerator_updated)
		engine_node.brake_updated.connect(gui._on_brake_updated)
		engine_node.gear_updated.connect(gui._on_gear_updated)
	else:
		vehicle_status.emit(engine_missing_msg)
	
	if transmission_node and engine_node:
		transmission_node.gear_changed.connect(engine_node.set_gear)
	else:
		vehicle_status.emit(transmission_missing_msg)
	
	if pedal_node and engine_node:
		# Connect pedal signals to the engine
		pedal_node.accelerator_input_updated.connect(engine_node.set_accelerator_input)
		pedal_node.brake_input_updated.connect(engine_node.set_brake_input)
	else:
		vehicle_status.emit(pedal_missing_msg)

	if steering_node and gui:
		steering_node.steering_input_updated.connect(gui._on_steering_updated)
	else:
		vehicle_status.emit(steering_missing_msg)


func _input(event):
	# Handle input to toggle the engine and control the pedal
	if event.is_action_pressed("ignition_toggle"):
		if engine_node:
			engine_node.toggle_engine()
		else:
			vehicle_status.emit(engine_missing_msg)
			print(engine_missing_msg)

	if event.is_action("ui_up"):
		if pedal_node:
			pedal_node.set_accelerator_target_input(event.get_action_strength("ui_up"))
	elif event.is_action_released("ui_up"):
		if pedal_node:
			pedal_node.set_accelerator_target_input(0.0)
		
	if event.is_action("ui_down"):
		if pedal_node:
			pedal_node.set_brake_target_input(event.get_action_strength("ui_down"))
	elif event.is_action_released("ui_down"):
		if pedal_node:
			pedal_node.set_brake_target_input(0.0)
	
	# Handle steering input
	if event.is_action("ui_left"):
		if steering_node:
			steering_node.set_target_steering_input(-1.0)
	elif event.is_action("ui_right"):
		if steering_node:
			steering_node.set_target_steering_input(1.0)
	elif event.is_action_released("ui_left") or event.is_action_released("ui_right"):
		if steering_node:
			steering_node.set_target_steering_input(0.0)
	

	if event.is_action_pressed("gear_shift_up"):
		if transmission_node:
			transmission_node.shift_up()
		else:
			vehicle_status.emit(transmission_missing_msg)
			print(transmission_missing_msg)
	elif event.is_action_pressed("gear_shift_down"):
		if transmission_node:
			transmission_node.shift_down()
		else:
			vehicle_status.emit(transmission_missing_msg)
			print(transmission_missing_msg)

	if event.is_action_pressed("gear_shift_reverse"):
		if transmission_node:
			transmission_node.shift_to_reverse()
		else:
			vehicle_status.emit(transmission_missing_msg)
			print(transmission_missing_msg)

	if event.is_action_pressed("gear_shift_neutral"):
		if transmission_node:
			transmission_node.shift_to_neutral()
		else:
			vehicle_status.emit(transmission_missing_msg)
			print(transmission_missing_msg)
