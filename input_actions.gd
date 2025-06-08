class_name InputActions

const MOVE_FORWARD = "move_forward"
const MOVE_LEFT = "move_left"
const MOVE_BACK = "move_back"
const MOVE_RIGHT = "move_right"
const JUMP = "jump"
const BOUNCE_JUMP = "bounce_jump"
const SPRINT = "sprint"

const NAME_MOVE_FORWARD = "MOVE FORWARD"
const NAME_MOVE_LEFT = "MOVE LEFT"
const NAME_MOVE_BACK = "MOVE BACK"
const NAME_MOVE_RIGHT = "MOVE RIGHT"
const NAME_JUMP = "JUMP"
const NAME_BOUNCE_JUMP = "BOUNCE JUMP"
const NAME_SPRINT = "SPRINT"

const NAME_MAP = {
	MOVE_FORWARD: NAME_MOVE_FORWARD,
	MOVE_LEFT: NAME_MOVE_LEFT,
	MOVE_BACK: NAME_MOVE_BACK,
	MOVE_RIGHT: NAME_MOVE_RIGHT,
	JUMP: NAME_JUMP,
	BOUNCE_JUMP: NAME_BOUNCE_JUMP,
	SPRINT: NAME_SPRINT,
}


static func get_current_config() -> Dictionary:
	var conf = {}
	
	for action in NAME_MAP:
		conf.set(action, InputMap.action_get_events(action)[0])
	
	return conf


static func set_current_config(conf: Dictionary) -> void:
	print("setting input map...")
	for action in conf:
		if not (NAME_MAP.has(action) and conf[action] is InputEvent):
			print("skipping invalid action: {}".format([action], "{}"))
			continue

		print("setting action [{}] to event: {}".format([action, conf[action]], "{}"))
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, conf[action])
