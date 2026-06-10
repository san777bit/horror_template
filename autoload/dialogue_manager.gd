extends CanvasLayer
## Autoload "DialogueManager" — 2D-диалоги и осмотр предметов ПОВЕРХ 3D-мира.
##
## Формат одной реплики (Dictionary / строка JSON):
##   "name"     - имя говорящего (опционально)
##   "text"     - текст реплики
##   "portrait" - путь к PNG-портрету, напр. "res://assets/portraits/stranger.png" (опционально)
##   "image"    - путь к полноэкранной 2D-иллюстрации для катсцен (опционально;
##                картинка остаётся на экране до следующей "image" или конца диалога)
##
## Запуск:
##   DialogueManager.start_from_file("res://dialogues/sample_dialogue.json", "stranger_intro")
##   DialogueManager.start_dialogue([{"name": "Я", "text": "Что это было?.."}])
##   DialogueManager.show_examine("Старая ржавая табличка.", "Табличка")
##
## Пока active == true, игрок не двигается (см. player.gd).

signal dialogue_finished

const CHARS_PER_SECOND := 40.0

var active := false
## Внешняя блокировка игрока (для 3D-катсцен): DialogueManager.block_player = true
var block_player := false

var _lines: Array = []
var _index := 0
var _typing := false

var _root: Control
var _fullscreen_art: TextureRect
var _panel: PanelContainer
var _name_label: Label
var _text_label: RichTextLabel
var _portrait: TextureRect
var _hint: Label
var _tween: Tween


func _ready() -> void:
	layer = 50
	_build_ui()
	_root.visible = false


## Запустить диалог из массива реплик.
func start_dialogue(lines: Array) -> void:
	if lines.is_empty() or active:
		return
	_lines = lines
	_index = 0
	active = true
	_fullscreen_art.visible = false
	_root.visible = true
	_show_line()


## Запустить диалог из JSON-файла по ключу.
func start_from_file(path: String, key: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("DialogueManager: файл не найден: " + path)
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary and data.has(key):
		start_dialogue(data[key])
	else:
		push_warning("DialogueManager: ключ '%s' не найден в %s" % [key, path])


## Короткое окно осмотра предмета (одна реплика).
func show_examine(text: String, title := "") -> void:
	start_dialogue([{"name": title, "text": text}])


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	var advance := event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	if advance:
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	if _typing:
		# первый клик — показать весь текст сразу
		if _tween:
			_tween.kill()
		_text_label.visible_characters = -1
		_typing = false
		_hint.visible = true
		return
	_index += 1
	if _index >= _lines.size():
		_end()
	else:
		_show_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	# полноэкранная иллюстрация (2D-катсцены)
	if line.has("image"):
		var img_path: String = str(line["image"])
		if img_path != "" and ResourceLoader.exists(img_path):
			_fullscreen_art.texture = load(img_path)
			_fullscreen_art.visible = true
		else:
			_fullscreen_art.visible = false
	# портрет говорящего
	var portrait_path: String = str(line.get("portrait", ""))
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		_portrait.texture = load(portrait_path)
		_portrait.visible = true
	else:
		_portrait.visible = false
	# имя и текст
	var speaker: String = str(line.get("name", ""))
	_name_label.text = speaker
	_name_label.visible = speaker != ""
	_text_label.text = str(line.get("text", ""))
	_text_label.visible_characters = 0
	_hint.visible = false
	_typing = true
	var total := _text_label.get_total_character_count()
	_tween = create_tween()
	_tween.tween_property(_text_label, "visible_characters", total, float(total) / CHARS_PER_SECOND)
	_tween.finished.connect(func() -> void:
		_typing = false
		_hint.visible = true
	)


func _end() -> void:
	active = false
	_root.visible = false
	_fullscreen_art.visible = false
	_fullscreen_art.texture = null
	dialogue_finished.emit()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_fullscreen_art = TextureRect.new()
	_fullscreen_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fullscreen_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fullscreen_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fullscreen_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fullscreen_art.visible = false
	_root.add_child(_fullscreen_art)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.03, 0.88)
	style.border_color = Color(0.5, 0.45, 0.4, 1.0)
	style.set_border_width_all(1)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.anchor_left = 0.12
	_panel.anchor_right = 0.88
	_panel.anchor_top = 0.72
	_panel.anchor_bottom = 0.95
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	_panel.add_child(hbox)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(110, 110)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.visible = false
	hbox.add_child(_portrait)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	_name_label = Label.new()
	_name_label.modulate = Color(1.0, 0.88, 0.6)
	_name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_name_label)

	_text_label = RichTextLabel.new()
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.scroll_active = false
	_text_label.add_theme_font_size_override("normal_font_size", 20)
	vbox.add_child(_text_label)

	_hint = Label.new()
	_hint.text = "▸"
	_hint.modulate = Color(1, 1, 1, 0.5)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_hint)
