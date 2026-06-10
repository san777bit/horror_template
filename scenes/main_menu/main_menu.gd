extends Control
## Главное меню: Продолжить / Новая игра / Загрузить / Настройки / Выход.

const SETTINGS_MENU := preload("res://scenes/ui/settings_menu.tscn")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var no_saves := SaveManager.latest_slot() == -1
	$VBox/ContinueBtn.disabled = no_saves
	$VBox/LoadBtn.disabled = no_saves
	$VBox/ContinueBtn.pressed.connect(_on_continue)
	$VBox/NewGameBtn.pressed.connect(_on_new_game)
	$VBox/LoadBtn.pressed.connect(_show_slots)
	$VBox/SettingsBtn.pressed.connect(_on_settings)
	$VBox/QuitBtn.pressed.connect(func() -> void: get_tree().quit())


func _on_continue() -> void:
	SaveManager.load_game(SaveManager.latest_slot())


func _on_new_game() -> void:
	SaveManager.new_game()


func _on_settings() -> void:
	add_child(SETTINGS_MENU.instantiate())


## Простое окно выбора слота загрузки.
func _show_slots() -> void:
	var popup := PopupPanel.new()
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(340, 0)
	vb.add_theme_constant_override("separation", 8)
	popup.add_child(vb)
	var title := Label.new()
	title.text = "Загрузить игру"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	for i in range(1, SaveManager.SLOTS + 1):
		var info := SaveManager.get_save_info(i)
		var b := Button.new()
		if info.is_empty():
			b.text = "Слот %d — пусто" % i
			b.disabled = true
		else:
			b.text = "Слот %d — %s" % [i, info.get("time", "?")]
			b.pressed.connect(func() -> void: SaveManager.load_game(i))
		vb.add_child(b)
	add_child(popup)
	popup.popup_centered()
