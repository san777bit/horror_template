extends Control
## Меню паузы: открывается игроком по Esc (см. player.gd).
## process_mode = ALWAYS, поэтому работает при get_tree().paused == true.

const SETTINGS_MENU := preload("res://scenes/ui/settings_menu.tscn")


func _ready() -> void:
	$Panel/VBox/ResumeBtn.pressed.connect(_resume)
	$Panel/VBox/SaveBtn.pressed.connect(_save)
	$Panel/VBox/SettingsBtn.pressed.connect(func() -> void: add_child(SETTINGS_MENU.instantiate()))
	$Panel/VBox/MenuBtn.pressed.connect(_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_resume()
		get_viewport().set_input_as_handled()


func _resume() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()


func _save() -> void:
	SaveManager.save_game()
	$Panel/VBox/SaveBtn.text = "Сохранено ✓"


func _to_menu() -> void:
	get_tree().paused = false
	SceneLoader.change_scene("res://scenes/main_menu/main_menu.tscn")
