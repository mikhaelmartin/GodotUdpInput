extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UdpInput.connect_server()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	var dir = UdpInput.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var accept = UdpInput.is_action_pressed("ui_accept")
	prints(dir, "accept" if accept else "")


func _exit_tree() -> void:
	UdpInput.disconnect_server()
