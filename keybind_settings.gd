extends Control


@onready var input_button_scene = preload("res://keybind_button.tscn")
var bind_list: Node


var is_remapping = false
var remapping_button: Button
var action_to_remap: String


func _ready() -> void:
	bind_list = find_child("keybind_list")


func _reset_keybind_list() -> void:
	InputMap.load_from_project_settings()
	_create_keybind_list()


func _create_keybind_list() -> void:
	for bind in bind_list.get_children():
		bind.queue_free()
	
	for action in InputActions.NAME_MAP:
		var button = input_button_scene.instantiate() as Button
		var action_label = button.find_child("l_action") as Label
		var input_label = button.find_child("l_input") as Label
		
		action_label.text = InputActions.NAME_MAP[action]
		
		var events = InputMap.action_get_events(action)
		if 0 < events.size():
			input_label.text = events[0].as_text().to_upper().trim_suffix(" (PHYSICAL)")
		else:
			input_label.text = ""
		
		bind_list.add_child(button)
		button.pressed.connect(_on_input_button_pressed.bind(button, action))


func _on_input_button_pressed(button: Button, action: String) -> void:
	if not is_remapping:
		is_remapping = true
		remapping_button = button
		action_to_remap = action
		(button.find_child("l_input") as Label).text = "press key to bind..."


func _input(event) -> void:
	if not is_remapping: return
	
	var is_key_event = event is InputEventKey
	var is_mouse_event = event is InputEventMouseButton
	var apply_remapping = event.is_pressed() and (is_key_event or is_mouse_event)
	if not apply_remapping: return
	
	if is_mouse_event: (event as InputEventMouseButton).double_click = false
	
	InputMap.action_erase_events(action_to_remap)
	InputMap.action_add_event(action_to_remap, event)
	
	_update_binding(remapping_button, event)
	
	is_remapping = false
	remapping_button = null
	action_to_remap = ""
	
	accept_event()


func _update_binding(button: Button, event: InputEvent) -> void:
	var label = button.find_child("l_input") as Label
	label.text = event.as_text().to_upper().trim_suffix(" (PHYSICAL)")


func _on_reset_pressed() -> void:
	_reset_keybind_list()


func _on_visibility_changed() -> void:
	if not visible: return
	_create_keybind_list()
