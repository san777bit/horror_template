extends Node
## Autoload "SaveManager" — система сохранений: 3 слота, JSON в user://.
## Сохраняет: текущую сцену, позицию игрока, сюжетные флаги (flags).

const SLOTS := 3
const SLOT_PATH := "user://save_slot_%d.json"
const FIRST_LEVEL := "res://scenes/levels/test_level.tscn"  # стартовый уровень новой игры

var current_slot: int = 1
## Сюжетные флаги: SaveManager.flags["got_key"] = true
var flags: Dictionary = {}
## Данные сейва, ожидающие применения после загрузки сцены.
var pending_load: Dictionary = {}


func slot_path(slot: int) -> String:
	return SLOT_PATH % slot


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func get_save_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


func save_game(slot: int = -1) -> void:
	if slot <= 0:
		slot = current_slot
	current_slot = slot
	var data := {
		"scene": get_tree().current_scene.scene_file_path,
		"flags": flags,
		"time": Time.get_datetime_string_from_system().replace("T", " "),
		"unix": Time.get_unix_time_from_system(),
	}
	var player := get_tree().get_first_node_in_group("player")
	if player is Node3D:
		data["player_pos"] = var_to_str(player.global_position)
		data["player_rot_y"] = player.rotation.y
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))


func load_game(slot: int) -> void:
	var data := get_save_info(slot)
	if data.is_empty():
		return
	current_slot = slot
	flags = data.get("flags", {})
	pending_load = data
	SceneLoader.change_scene(data.get("scene", FIRST_LEVEL))


func new_game() -> void:
	flags = {}
	pending_load = {}
	current_slot = _first_free_slot()
	SceneLoader.change_scene(FIRST_LEVEL)


## Слот с самым свежим сохранением, либо -1, если сейвов нет.
func latest_slot() -> int:
	var best := -1
	var best_time := -1.0
	for i in range(1, SLOTS + 1):
		var info := get_save_info(i)
		if not info.is_empty() and float(info.get("unix", 0)) > best_time:
			best_time = float(info.get("unix", 0))
			best = i
	return best


func _first_free_slot() -> int:
	for i in range(1, SLOTS + 1):
		if not has_save(i):
			return i
	return 1


## Игрок вызывает это в _ready(), чтобы встать на сохранённую позицию.
func apply_pending_to_player(player: Node3D) -> void:
	if pending_load.is_empty():
		return
	if pending_load.has("player_pos"):
		player.global_position = str_to_var(pending_load["player_pos"])
		player.rotation.y = float(pending_load.get("player_rot_y", 0.0))
	pending_load = {}
