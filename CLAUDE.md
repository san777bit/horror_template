# КОНТЕКСТ ПРОЕКТА (вставлять в начало каждой сессии с ИИ-агентом)

Инди-хоррор на Godot 4.3 / GDScript. Вид от первого лица, low-poly PS1-стиль.
3D-мир + 2D-диалоги/катсцены поверх (CanvasLayer). Язык UI и комментариев — русский.

## Правила для агента
- НЕ перечитывай весь проект. Вся архитектура описана ниже — читай только файлы, которые реально меняешь.
- Не переписывай работающие системы, вноси точечные правки.
- Стиль: GDScript 4 (типизация, `:=`), табы, snake_case, комментарии на русском.
- Новые сцены — руками в .tscn по образцу существующих (format=3, без uid).
- UI строится либо в .tscn, либо кодом в `_build_ui()` — следуй стилю конкретного файла.

## Структура
```
project.godot                 — input map: move_forward/back/left/right, interact(E),
								sprint, crouch, flashlight(F), pause(Esc)
autoload/  (порядок загрузки)
  settings.gd        Settings        — сенса мыши, invert_y, громкость, fullscreen,
									   ребинды клавиш; user://settings.cfg
  save_manager.gd    SaveManager     — 3 слота JSON user://save_slot_N.json;
									   flags{} = сюжетные флаги, попадают в сейв
  scene_loader.gd    SceneLoader     — change_scene(path) с фейдом
  dialogue_manager.gd DialogueManager — 2D-диалоги поверх 3D, UI создаётся кодом
scenes/
  main_menu/main_menu.(gd|tscn)      — Продолжить/Новая/Загрузить/Настройки/Выход
  player/player.(gd|tscn)            — CharacterBody3D, FPS-контроллер, HUD-подсказка [E]
  ui/settings_menu.(gd|tscn)         — UI кодом; ребинды через _waiting_action
  ui/pause_menu.(gd|tscn)            — process_mode ALWAYS, get_tree().paused
  levels/test_level.tscn             — пример уровня (туман, записка, NPC)
scripts/
  interactable.gd   class Interactable (StaticBody3D): prompt_text, one_shot,
					signal interacted, виртуальный _on_interact(player)
  examine_item.gd   ExamineItem    — осмотр: item_name, description
  dialogue_trigger.gd DialogueTrigger — dialogue_file(json), dialogue_key, set_flag
  level_door.gd     LevelDoor      — target_scene → SceneLoader
  cutscene_3d.gd    Cutscene3D     — play(): блок игрока, камера, AnimationPlayer
dialogues/*.json   — { "ключ": [ {name, text, portrait?, image?} ] }
shaders/psx_lit.gdshader — vertex snap + аффинные UV
assets/{models,textures,portraits,art2d,audio} — контент художников
```

## Ключевые контракты (не ломать)
- Игрок: в группе "player"; блокируется, когда `DialogueManager.active or DialogueManager.block_player`.
- Интеракция: RayCast3D из камеры → у коллайдера есть `interact(player)` (+опц. `can_interact()`, `prompt_text`).
- Диалоги: `DialogueManager.start_from_file(path, key)` / `start_dialogue(массив)` / `show_examine(text, title)`; сигнал `dialogue_finished`. Поле `image` в реплике = полноэкранная 2D-иллюстрация (катсцены).
- Сейв: позиция применяется через `SaveManager.apply_pending_to_player(self)` в `player._ready()`.
- Подсказки клавиш: `Settings.get_bind_text("interact")` — не хардкодить "E".
- Смена сцен только через `SceneLoader.change_scene()`.

## Задача
<сюда вписать конкретную задачу>
