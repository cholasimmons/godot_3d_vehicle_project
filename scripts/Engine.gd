extends Node

class_name Vehicle_Engine

# Engine properties
@export var max_rpm: float = 6000.0
@export var idle_rpm: float = 800.0
@export var torque_curve: Curve  ## Torque curve based on RPM (optional)
@export var inertia: float = 1.0  ## How resistant the engine is to RPM changes
@export var engine_health: float = 1.0  ## Engine's health from 0.0 to 1.0
@export var ignition_speed: float = 900.0  ## RPM increase per second during ignition
@export var shutdown_speed: float = 1600.0  ## RPM decrease per second during shutdown

# Audio properties
@export var idle_sound : AudioStream
@export var ignition_sound : AudioStream
@export var stop_sound : AudioStream
var audio_player_idle : AudioStreamPlayer3D
var audio_player_ignition : AudioStreamPlayer3D

# Engine state
var current_rpm: float = 0.0
var current_gear: int = 0
var is_engine_on: bool = false
var is_engine_starting: bool = false
var is_engine_shutting_down: bool = false
var ignition_timer: float = 0.0  ## Timer for ignition delay
var is_ignition_complete: bool = false  ## Track if ignition delay is complete
var accelerator_input: float = 0.0  # 0 to 1
var brake_input: float = 0.0  # 0 to 1
var steering_input: float = 0.0  # 0 to 1

# Signals
signal engine_toggled(is_on: bool)
signal engine_starting()
signal engine_started()
signal engine_failed_to_start(message: String)
signal engine_shutting_down()
signal engine_shut_off()
signal rpm_updated(rpm: float)
signal accelerator_updated(input: float)
signal brake_updated(input: float)
signal gear_updated(gear: int)

func _ready():
	# Set up the AudioStreamPlayer
	audio_player_idle = AudioStreamPlayer3D.new()
	audio_player_ignition = AudioStreamPlayer3D.new()
	add_child(audio_player_idle)
	add_child(audio_player_ignition)
	
	# Check if the audio files are assigned and if the audio player exists
	if idle_sound == null or ignition_sound == null:
		# vehicle_status.emit("Missing audio files: idle or rev sound not assigned.")
		print("Missing audio - idle or rev sound not assigned.")
		return

	if !audio_player_idle and !audio_player_ignition:
		# vehicle_status.emit("AudioStreamPlayer node is missing.")
		print("AudioStreamPlayers missing.")
		return
	
	audio_player_ignition.stream = ignition_sound  # Set the initial ignition sound
	audio_player_idle.stream = idle_sound  # Set the initial idle sound
	
	if is_engine_on:
		start_engine()

func toggle_engine():
	if is_engine_on or is_engine_starting:
		stop_engine()
	else:
		start_engine()

func start_engine():
	if engine_health <= 0.1:
		engine_failed_to_start.emit("Requires repair.")
		print("Engine failed to start: Requires repair.")
		return

	#audio_player.loop = true  # Loop the engine sound
	if audio_player_ignition and !audio_player_ignition.playing:
		audio_player_ignition.play()  # Start playing the ignition sound if the engine is starting
	is_engine_starting = true
	is_ignition_complete = false
	engine_starting.emit()

	# Calculate ignition delay based on engine health
	ignition_timer = randf_range(1.0, 6.0) * (1.0 - engine_health)

func stop_engine():
	engine_shutting_down.emit()
	is_engine_on = false
	is_engine_starting = false
	current_rpm = 0.0
	# Emit Signals
	engine_toggled.emit(false)
	rpm_updated.emit(current_rpm)
	
	# Stop crossfade from ignition to idle sound
	if audio_player_ignition.playing:
		fade_out_audio(audio_player_ignition)

	if audio_player_idle.playing:
		fade_out_audio(audio_player_idle)

func fade_in_audio(player: AudioStreamPlayer3D, target_volume: float, duration: float):
	player.play()
	var fade_in_time = 0.0
	while fade_in_time < duration:
		player.volume_db = lerp(-80, int(target_volume), fade_in_time / duration)  # Fade in
		fade_in_time += get_process_delta_time()
		await get_tree().create_timer(0.05)
	player.volume_db = target_volume  # Ensure the final volume level

func fade_out_audio(player: AudioStreamPlayer3D, duration: float = 1.0):
	var fade_out_time = 0.0
	while fade_out_time < duration:
		player.volume_db = lerp(0, -80, fade_out_time / duration)  # Fade out
		fade_out_time += get_process_delta_time()
		await get_tree().create_timer(0.05)
	player.stop()  # Stop the audio after fading out

func set_accelerator_input(input: float):
	accelerator_input = clamp(input, 0.0, 1.0)
	accelerator_updated.emit(accelerator_input)

func set_brake_input(input: float):
	brake_input = clamp(input, 0.0, 1.0)
	brake_updated.emit(brake_input)

func set_gear(gear: int):
	current_gear = gear
	gear_updated.emit(current_gear)

#func set_steering_input(input: float):
	#steering_input = clamp(input, -1.0, 1.0)
	#emit_signal("steering_updated", steering_input)

func _process(delta):
	if is_engine_starting:
		# Handle engine ignition delay
		ignition_timer -= delta
		
		# Wait for ignition delay to complete before increasing RPM
		if ignition_timer <= 0.0:
			is_engine_starting = false
			is_engine_on = true
			is_ignition_complete = true

			engine_started.emit()
			engine_toggled.emit(true)
			
			# Crossfade from ignition sound to idle sound
			fade_out_audio(audio_player_ignition, 1.0)  # Fade out ignition sound
			fade_in_audio(audio_player_idle, 0.0, 2.0)  # Fade in idle sound over 2 seconds
		
		# Gradually increase RPM to idle after ignition delay is complete
		if is_ignition_complete:
			var rpm_difference = idle_rpm - current_rpm
			var rpm_change = min(ignition_speed * delta, rpm_difference)
			current_rpm += rpm_change
			rpm_updated.emit(current_rpm)
			if audio_player_ignition and audio_player_ignition.playing:
				audio_player_ignition.stop()
		return
	
	if is_engine_shutting_down:
		# Gradually decrease RPM to 0 during shutdown
		var rpm_change1 = shutdown_speed * delta
		current_rpm = max(current_rpm - rpm_change1, 0.0)
		rpm_updated.emit(current_rpm)

		if current_rpm <= 0.0:
			is_engine_shutting_down = false
			is_engine_on = false
			engine_shut_off.emit()
			engine_toggled.emit(false)
			# Stop audio when engine is off
			if audio_player_idle and audio_player_idle.playing:
				audio_player_idle.stop()
		return
	
	if !is_engine_on:
		return
	
	# **New Part**: Gradually ramp up RPM from idle to the target RPM instead of suddenly jumping to it
	if current_rpm < idle_rpm:
		# Smooth ramp-up from 0 RPM to idle RPM
		current_rpm = min(current_rpm + (ignition_speed * delta), idle_rpm)
	elif current_rpm >= idle_rpm and current_rpm < max_rpm:
		# Calculate target RPM based on accelerator input
		var target_rpm = idle_rpm + (max_rpm - idle_rpm) * accelerator_input

		# Calculate torque based on RPM (using torque curve if available)
		var torque = 1.0
		if torque_curve:
			torque = torque_curve.sample_baked(current_rpm / max_rpm)

		# Simulate RPM changes based on torque and inertia
		var rpm_difference = target_rpm - current_rpm
		var rpm_change2 = (rpm_difference * torque) / inertia * delta

		current_rpm += rpm_change2
		current_rpm = clamp(current_rpm, idle_rpm, max_rpm)

	# Emit RPM updates
	rpm_updated.emit(current_rpm)
	
	# Adjust audio pitch based on RPM (idle sound to rev sound)
	var pitch_scale = lerp(0.64, 1.8, (current_rpm - idle_rpm) / (max_rpm - idle_rpm))
	if audio_player_idle:
		audio_player_idle.pitch_scale = pitch_scale
	
	accelerator_updated.emit(accelerator_input)
	brake_updated.emit(brake_input)
