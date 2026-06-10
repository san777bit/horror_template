extends CharacterBody3D
## Контроллер игрока от первого лица.
## WASD — движение, мышь — обзор, Shift — бег, Ctrl — присед,
## E — взаимодействие, F — фонарик, Esc — пауза.
## Чувствительность мыши и клавиши настраиваются в меню (autoload Settings).

@export_group("Движение")
@export var walk_speed := 3.0
@export var sprint_speed := 5.5
@export var crouch_speed := 1.5
@export var acceleration := 10.0

@export_group("Камера")
@export var pitch_limit_deg := 85.0
@export var bob_enabled := true        # лёгкое покачивание камеры при ходьбе
@export var bob_frequency := 2.2
@export var bob_amplitude := 0.05

@export_group("Взаимодействие")
@export var interact_distance := 2.2

const PAUSE_MENU := preload("res://scenes/ui/pause_menu.tscn")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var prompt_label: Label = $HUD/InteractPrompt

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _bob_time := 0.0
var _crouching := false
var _current_target: Node = null


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ray.target_position = Vector3(0, 0, -interact_distance)
	# если загрузились из сейва — встать на сохранённую позицию
	SaveManager.apply_pending_to_player(self)


func _is_blocked() -> bool:
	return DialogueManager.active or DialogueManager.block_player


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not _is_blocked():
		_open_pause_menu()
		return
	if _is_blocked():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = Settings.mouse_sensitivity * 0.003
		rotate_y(-event.relative.x * sens)
		var dy: float = event.relative.y * sens * (-1.0 if Settings.invert_y else 1.0)
		head.rotate_x(-dy)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-pitch_limit_deg), deg_to_rad(pitch_limit_deg))
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("flashlight"):
		flashlight.visible = not flashlight.visible


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var blocked := _is_blocked()
	var input_dir := Vector2.ZERO
	if not blocked:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_crouching = (not blocked) and Input.is_action_pressed("crouch")

	var speed := walk_speed
	if _crouching:
		speed = crouch_speed
	elif not blocked and Input.is_action_pressed("sprint"):
		speed = sprint_speed

	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = lerpf(velocity.x, dir.x * speed, acceleration * delta)
	velocity.z = lerpf(velocity.z, dir.z * speed, acceleration * delta)
	move_and_slide()

	_update_head(delta)
	_update_prompt()


func _update_head(delta: float) -> void:
	# присед — опускаем "голову"
	var target_y := 1.1 if _crouching else 1.6
	head.position.y = lerpf(head.position.y, target_y, 8.0 * delta)
	# покачивание камеры
	if bob_enabled and is_on_floor():
		var hvel := Vector2(velocity.x, velocity.z).length()
		_bob_time += delta * hvel
		camera.position.y = sin(_bob_time * bob_frequency) * bob_amplitude * clampf(hvel / walk_speed, 0.0, 1.0)
	else:
		camera.position.y = lerpf(camera.position.y, 0.0, 5.0 * delta)


## Подсказка "[E] Осмотреть" над интерактивными объектами.
func _update_prompt() -> void:
	_current_target = null
	if _is_blocked():
		prompt_label.visible = false
		return
	if ray.is_colliding():
		var collider := ray.get_collider()
		if collider and collider.has_method("interact"):
			var ok: bool = true
			if collider.has_method("can_interact"):
				ok = collider.can_interact()
			if ok:
				_current_target = collider
				var text := "Осмотреть"
				if "prompt_text" in collider:
					text = collider.prompt_text
				prompt_label.text = "[%s] %s" % [Settings.get_bind_text("interact"), text]
				prompt_label.visible = true
				return
	prompt_label.visible = false


func _try_interact() -> void:
	if _current_target:
		_current_target.interact(self)
		get_viewport().set_input_as_handled()


func _open_pause_menu() -> void:
	get_tree().root.add_child(PAUSE_MENU.instantiate())
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
