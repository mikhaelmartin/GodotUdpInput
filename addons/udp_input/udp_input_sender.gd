class_name UdpInputSender
extends Node

@export var id := "player_1"
@export var target_ip := "127.0.0.1"  # Or LAN IP of receiver
@export var port := 42424
@export var print_log := false
## set which actions to send. leave empty to send all actions
@export var actions: Array[StringName] = [] # leave empty to send all actions

var udp := PacketPeerUDP.new()
var ip: String

func _ready():
	udp.set_dest_address(target_ip, port)
	
	ip = Array(IP.get_local_addresses()).filter(
		func(addr): return addr.begins_with("192.") or addr.begins_with("10.") or addr.begins_with("172.")
	).front()

func _process(_delta):
	var input_data: Dictionary = {
		"id": id,
		"ip": ip,
		"just_pressed" : {},
		"just_released" : {},
		"pressed" : {},
	}
	
	var send_actions := InputMap.get_actions() if actions.is_empty() else actions
	
	for action in send_actions:
		if Input.is_action_just_pressed(action):
			input_data["just_pressed"][action] = Input.get_action_strength(action)
		
		if Input.is_action_just_released(action):
			input_data["just_released"][action] = Input.get_action_strength(action)
		
		if Input.is_action_pressed(action):
			input_data["pressed"][action] = Input.get_action_strength(action)
	
	for input_type in ["just_pressed", "just_released", "pressed"]:
		if input_data[input_type].is_empty():
			input_data.erase(input_type)
	
	udp.put_packet(JSON.stringify(input_data).to_utf8_buffer())
	
	if print_log and input_data.keys().size() > 2:
		print("[%s.%s] input:\n%s" % [
			Time.get_time_string_from_system(),
			str(Time.get_unix_time_from_system()).split(".")[-1],
			JSON.stringify(input_data, ".  ")
		])
