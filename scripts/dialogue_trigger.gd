class_name DialogueTrigger
extends Interactable
## NPC или объект, запускающий диалог из JSON-файла по E.
## dialogue_file — JSON с диалогами, dialogue_key — ключ нужного диалога.

@export_file("*.json") var dialogue_file := "res://dialogues/sample_dialogue.json"
@export var dialogue_key := ""
## Сюжетный флаг, который выставится в SaveManager.flags после диалога (опционально).
@export var set_flag := ""


func _on_interact(_player: Node) -> void:
	DialogueManager.start_from_file(dialogue_file, dialogue_key)
	if set_flag != "" and DialogueManager.active:
		await DialogueManager.dialogue_finished
		SaveManager.flags[set_flag] = true
