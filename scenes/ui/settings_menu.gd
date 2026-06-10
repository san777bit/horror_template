extends Control
## Меню настроек. Работает и из главного меню, и из паузы (открывается поверх).
## Чувствительность мыши, инверсия Y, громкость, полный экран, переназначение клавиш.

var _waiting_action := ""      # действие, для которого ждём новую клавишу
var _bind_buttons := {}        # action -> Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _input(event: InputEvent) -> void:
	# Перехват клавиши при переназначении.
	if _waiting_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.physical_keycode != KEY_ESCAPE:  # Esc = отмена
			Settings.rebind_action(_waiting_action, event)
		_bind_buttons[_waiting_action].text = Settings.get_bind_text(_waiting_action)
		_waiting_action = ""


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 560)
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	vbox.add_child(_header("НАСТРОЙКИ", 28))

	# --- Мышь ---
	var sens := HSlider.new()
	sens.min_value = 0.05
	sens.max_value = 1.0
	sens.step = 0.01
	sens.value = Settings.mouse_sensitivity
	sens.value_changed.connect(func(v: float) -> void: Settings.mouse_sensitivity = v)
	vbox.add_child(_row("Чувствительность мыши", sens))

	var invert := CheckButton.new()
	invert.button_pressed = Settings.invert_y
	invert.toggled.connect(func(v: bool) -> void: Settings.invert_y = v)
	vbox.add_child(_row("Инверсия Y", invert))

	# --- Звук / видео ---
	var vol := HSlider.new()
	vol.min_value = 0.0
	vol.max_value = 1.0
	vol.step = 0.01
	vol.value = Settings.master_volume
	vol.value_changed.connect(func(v: float) -> void:
		Settings.master_volume = v
		Settings.apply_all()
	)
	vbox.add_child(_row("Громкость", vol))

	var fs := CheckButton.new()
	fs.button_pressed = Settings.fullscreen
	fs.toggled.connect(func(v: bool) -> void:
		Settings.fullscreen = v
		Settings.apply_all()
	)
	vbox.add_child(_row("Полный экран", fs))

	# --- Управление ---
	vbox.add_child(_header("УПРАВЛЕНИЕ", 20))
	for action in Settings.REBINDABLE_ACTIONS:
		var btn := Button.new()
		btn.text = Settings.get_bind_text(action)
		btn.custom_minimum_size = Vector2(140, 0)
		btn.pressed.connect(func() -> void: _start_rebind(action))
		_bind_buttons[action] = btn
		vbox.add_child(_row(Settings.REBINDABLE_ACTIONS[action], btn))

	# --- Назад ---
	var back := Button.new()
	back.text = "Назад"
	back.pressed.connect(func() -> void:
		Settings.save_settings()
		queue_free()
	)
	vbox.add_child(back)


func _start_rebind(action: String) -> void:
	# Сбросить предыдущую "ожидающую" кнопку, если была.
	if _waiting_action != "":
		_bind_buttons[_waiting_action].text = Settings.get_bind_text(_waiting_action)
	_waiting_action = action
	_bind_buttons[action].text = "Нажмите клавишу..."


func _row(label_text: String, control: Control) -> HBoxContainer:
	var hb := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(260, 0)
	hb.add_child(lbl)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(control)
	return hb


func _header(text: String, size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size)
	return lbl
