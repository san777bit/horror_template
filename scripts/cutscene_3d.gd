class_name Cutscene3D
extends Node
## Помощник 3D-катсцен. Добавить в сцену уровня, назначить в инспекторе
## AnimationPlayer и Camera3D катсцены, затем вызвать play() (из кода,
## сигнала interacted или Area3D.body_entered).
## На время катсцены игрок блокируется, после — управление возвращается.

@export var animation_player: AnimationPlayer
@export var cutscene_camera: Camera3D
@export var animation_name := "cutscene"
## Запускать автоматически при входе игрока в зону (если родитель — Area3D).
@export var auto_play_on_area := false

signal finished

var _played := false


func _ready() -> void:
	if auto_play_on_area and get_parent() is Area3D:
		get_parent().body_entered.connect(func(body: Node3D) -> void:
			if body.is_in_group("player") and not _played:
				play()
		)


func play() -> void:
	if _played:
		return
	_played = true
	DialogueManager.block_player = true
	var prev_camera := get_viewport().get_camera_3d()
	if cutscene_camera:
		cutscene_camera.current = true
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		await animation_player.animation_finished
	# если внутри анимации запускался диалог — дождаться его конца
	if DialogueManager.active:
		await DialogueManager.dialogue_finished
	if prev_camera:
		prev_camera.current = true
	DialogueManager.block_player = false
	finished.emit()
