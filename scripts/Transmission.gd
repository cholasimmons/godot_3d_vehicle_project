extends Node

# Transmission properties
@export var gears: Array[float] = [-2.4, 0.0, 3.5, 2.5, 1.8, 1.4, 1.0, 0.8]  # Gear ratios
@export var current_gear: int = 0  # Neutral by default
@export var shift_time: float = 0.6  # Time to shift gears (in seconds)

# Audio properties
@export var gear_shift_sound : AudioStream
var audio_player_shift : AudioStreamPlayer3D

# Transmission state
var is_shifting: bool = false
var shift_timer: float = 0.0

# Signals
signal gear_changed(gear: int)
signal shift_started()
signal shift_completed()

func _ready() -> void:
	# Set up the AudioStreamPlayer
	audio_player_shift = AudioStreamPlayer3D.new()
	add_child(audio_player_shift)
	audio_player_shift.stream = gear_shift_sound
	audio_player_shift.volume_db = -12.0

func shift_up():
	if current_gear < gears.size() - 1 and !is_shifting:
		start_shift(current_gear + 1)

func shift_down():
	if current_gear > 0 and !is_shifting:
		start_shift(current_gear - 1)

func shift_to_reverse():
	if !is_shifting:
		start_shift(0)  # Shift to reverse gear (index 0)

func shift_to_neutral():
	if !is_shifting:
		start_shift(1)  # Shift to neutral (index 1)

func start_shift(new_gear: int):
	is_shifting = true
	shift_timer = shift_time
	shift_started.emit()
	current_gear = new_gear
	gear_changed.emit(current_gear)
	if audio_player_shift and not audio_player_shift.playing:
		audio_player_shift.play()

func _process(delta):
	if is_shifting:
		shift_timer -= delta
		if shift_timer <= 0.0:
			is_shifting = false
			shift_completed.emit()

func get_current_gear_ratio() -> float:
	return gears[current_gear]

func is_in_reverse() -> bool:
	return current_gear == 0

func is_in_neutral() -> bool:
	return current_gear == 1
