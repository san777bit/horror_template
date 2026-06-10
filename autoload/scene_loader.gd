extends CanvasLayer
## Autoload "SceneLoader" — смена сцен с плавным затемнением.
## Использование: SceneLoader.change_scene("res://scenes/levels/имя_уровня.tscn")

var _rect: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func change_scene(path: String, fade_time: float = 0.4) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	await _fade(1.0, fade_time)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await _fade(0.0, fade_time)
	_busy = false


func _fade(target_alpha: float, time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", target_alpha, time)
	await tw.finished
