extends Node
## Autoload "Settings" — настройки игры: мышь, звук, видео, переназначение клавиш.
## Файл настроек: user://settings.cfg (создаётся автоматически).

const FILE_PATH := "user://settings.cfg"

## Действия, доступные для переназначения в меню настроек.
## ключ = имя action в Input Map, значение = подпись в меню.
const REBINDABLE_ACTIONS := {
	"move_forward": "Вперёд",
	"move_back": "Назад",
	"move_left": "Влево",
	"move_right": "Вправо",
	"interact": "Взаимодействие",
	"sprint": "Бег",
	"crouch": "Присесть",
	"flashlight": "Фонарик",
}

var mouse_sensitivity: float = 0.25  # 0.05..1.0
var invert_y: bool = false
var master_volume: float = 1.0       # 0..1
var fullscreen: bool = false


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(FILE_PATH) != OK:
		apply_all()
		return
	mouse_sensitivity = cfg.get_value("input", "mouse_sensitivity", mouse_sensitivity)
	invert_y = cfg.get_value("input", "invert_y", invert_y)
	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	for action in REBINDABLE_ACTIONS:
		var keycode: int = cfg.get_value("binds", action, 0)
		if keycode != 0:
			_apply_bind(action, keycode)
	apply_all()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("input", "invert_y", invert_y)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	for action in REBINDABLE_ACTIONS:
		var events := InputMap.action_get_events(action)
		if events.size() > 0 and events[0] is InputEventKey:
			cfg.set_value("binds", action, (events[0] as InputEventKey).physical_keycode)
	cfg.save(FILE_PATH)


## Применить громкость и режим окна.
func apply_all() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(master_volume, 0.0001, 1.0)))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


## Переназначить действие на клавишу из события.
func rebind_action(action: String, event: InputEventKey) -> void:
	_apply_bind(action, event.physical_keycode)
	save_settings()


func _apply_bind(action: String, physical_keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = physical_keycode as Key
	InputMap.action_add_event(action, ev)


## Текст клавиши для подсказок на экране, например "E".
func get_bind_text(action: String) -> String:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			var k := e as InputEventKey
			var code := k.keycode
			if k.physical_keycode != KEY_NONE:
				code = DisplayServer.keyboard_get_keycode_from_physical(k.physical_keycode)
			return OS.get_keycode_string(code)
	return "—"
