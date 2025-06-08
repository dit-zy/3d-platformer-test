extends Resource
class_name SaveData


const SAVE_PATH = "user://save.tres"


@export var input_map: Dictionary


static func save_exists() -> bool:
	return ResourceLoader.exists(SAVE_PATH)


static func load_save() -> SaveData:
	print("loading save...")
#	return ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	return load(SAVE_PATH)


func write_save() -> void:
	print("writing save...")
	ResourceSaver.save(self, SAVE_PATH)
