extends Node3D

@onready var menu = $gui/keybind_settings

var save_data: SaveData
var game_state: GameState


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_state = GameState.new()
	$character.game_state = game_state
	_create_or_load_save()


func _create_or_load_save():
	if SaveData.save_exists():
		save_data = SaveData.load_save()
		InputActions.set_current_config(save_data.input_map)
	else:
		save_data = SaveData.new()


func _unhandled_input(event: InputEvent) -> void:
	if menu.visible:
		_handle_menu_inputs(event)
	else:
		_handle_game_inputs(event)


func _handle_menu_inputs(_event):
	if Input.is_action_just_pressed("menu"):
		_hide_menu()


func _handle_game_inputs(event):
	if event is InputEventMouseButton and event.is_pressed():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if Input.is_action_just_pressed("menu"):
		_show_menu()


func _show_menu():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu.visible = true
	game_state.in_menu = true


func _hide_menu():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	save_data.input_map = InputActions.get_current_config()
	save_data.write_save()
	menu.visible = false
	game_state.in_menu = false
