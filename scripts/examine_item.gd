class_name ExamineItem
extends Interactable
## Предмет для осмотра: по E показывает текст в 2D-окне поверх 3D.
## Повесить на StaticBody3D с CollisionShape3D, заполнить поля в инспекторе.

@export var item_name := ""
@export_multiline var description := "Ничего интересного."


func _on_interact(_player: Node) -> void:
	DialogueManager.show_examine(description, item_name)
