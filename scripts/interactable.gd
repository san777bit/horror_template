class_name Interactable
extends StaticBody3D
## Базовый класс всего, с чем игрок взаимодействует на E.
## Варианты использования:
##  1) Готовые наследники: ExamineItem (осмотр), DialogueTrigger (диалог), LevelDoor (переход).
##  2) Свой класс: унаследоваться и переопределить _on_interact().
##  3) Без кода: подключить сигнал interacted в редакторе.

## Текст подсказки на экране: "[E] <prompt_text>"
@export var prompt_text := "Осмотреть"
## true = сработает только один раз.
@export var one_shot := false

signal interacted(player: Node)

var _used := false


func can_interact() -> bool:
	return not (one_shot and _used)


func interact(player: Node) -> void:
	if not can_interact():
		return
	_used = true
	interacted.emit(player)
	_on_interact(player)


## Переопределить в наследниках.
func _on_interact(_player: Node) -> void:
	pass
