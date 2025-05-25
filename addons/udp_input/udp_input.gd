extends Node

signal data_received(data: Dictionary)

@export var port := 42424
@export var print_log: bool = false
@export var auto_connect_on_ready: bool = false

var udp := UDPServer.new()
var is_connected := false
var input_data = {}
var ip := "localhost"

func _ready():
	# Optional: auto-connect on start
	process_priority = -1000
	if auto_connect_on_ready:
		connect_server()


func _process(_delta):
	input_data = {}
	
	if not is_connected:
		return
		
	udp.poll()

	if udp.is_connection_available():
		var packet = udp.take_connection()
		if packet:
			var data = packet.get_packet().get_string_from_utf8()
			input_data = JSON.parse_string(data)
			data_received.emit(input_data)
	
	if print_log and input_data.keys().size() > 2:
		print("[%s.%s] input:\n%s" % [
			Time.get_time_string_from_system(),
			str(Time.get_unix_time_from_system()).split(".")[-1],
			JSON.stringify(input_data, ".  ")
		])


func connect_server(p_port = null):
	if is_connected:
		return
	
	if p_port is int:
		port = p_port
	
	# Get local IP address
	ip = Array(IP.get_local_addresses()).filter(
		func(addr): return addr.begins_with("192.") or addr.begins_with("10.") or addr.begins_with("172.")
	).front()

	if ip == null:
		ip = "localhost"  # fallback
	
	# Start UDP server
	var success = udp.listen(port)
	if success != OK:
		push_error("Failed to bind UDP to %s:%d\n" % [ip, port])
		return

	udp.set_block_signals(false)
	port = udp.get_local_port()
	is_connected = true
	
	if print_log:
		print("UDP server listening on %s:%d\n" % [ip, port])


func disconnect_server():
	if not is_connected:
		return

	udp.stop()
	is_connected = false

	if print_log:
		print("UDP server stopped\n")


func get_ip_address() -> String:
	return ip + ":" + str(port)
	


func is_action_just_pressed(action: StringName) -> bool:
	if not input_data.has("just_pressed"):
		return false
	
	return input_data["just_pressed"].has(action)


func is_action_just_released(action: StringName) -> bool:
	if not input_data.has("just_released"):
		return false
	
	return input_data["just_released"].has(action)


func is_action_pressed(action: StringName) -> bool:
	if not input_data.has("pressed"):
		return false
	
	return input_data["pressed"].has(action)


func get_action_strength(action: StringName) -> float:
	for input_type in ["just_pressed", "just_released", "pressed"]:
		if not input_data.has(input_type):
			continue
		
		if input_data[input_type].has(action):
			return input_data[input_type][action]
	
	return 0.0


func get_axis(negative_action: StringName, positive_action: StringName) -> float:
	return get_action_strength(positive_action) - get_action_strength(negative_action)


func get_vector(
	negative_x: StringName,
	positive_x: StringName,
	negative_y: StringName,
	positive_y: StringName,
	dead_zone: float = -1.0,
) -> Vector2:
	var raw_vector := Vector2(
		get_axis(negative_x, positive_x),
		get_axis(negative_y, positive_y)
	)

	# Apply dead zone
	if raw_vector.length() < dead_zone:
		return Vector2.ZERO

	# Normalize if above magnitude 1
	return raw_vector.normalized() if raw_vector.length() > 1.0 else raw_vector
	
