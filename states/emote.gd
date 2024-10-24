class_name Emote
extends State

@export var moving_state: State
@export var jump_state: State
@export var crouch_state: State
@export var emote_animation: AnimationPlayer

# Called when the node enters the scene tree for the first time.
func enter() -> void:
	parent.velocity.x = 0
	emote_animation.play("emote")
	parent.rpc("send_animation","emote")

func update(event: InputEvent) -> State:
	if event != null:
		if event.is_action_pressed("move_right"):
			return moving_state
		if event.is_action_pressed("move_left"):
			return moving_state
		if event.is_action_pressed("jump") and parent.jumps<2:
			return jump_state
		if event.is_action_pressed("crouch"):
			return crouch_state	
	return null


