class_name LevelDoor
extends Interactable
## Дверь/переход: по E загружает другую сцену-уровень с затемнением.

@export_file("*.tscn") var target_scene := ""


func _on_interact(_player: Node) -> void:
	if target_scene != "":
		SceneLoader.change_scene(target_scene)
