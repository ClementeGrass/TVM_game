class_name UpBoost
extends State

@export var jump_state: State
@export var fall_state: State
@export var boost_animation: AnimationPlayer

func enter() -> void:
	parent.velocity.x = 0
	parent.velocity.y = -650
	parent.jumps += 2
	boost_animation.play("boost")
	parent.rpc("send_animation","boost")
	
	
func update(event: InputEvent):
	if event.is_action_pressed("jump") and parent.velocity.y >-100:
		if parent.jumps<2:
			return jump_state
	if event.is_action_pressed("move_right") and parent.velocity.y >-100:
		return fall_state
	if event.is_action_pressed("move_left") and parent.velocity.y >-100:
		return fall_state
	return null				

func autoUpdate() -> State:
	if abs(parent.velocity.y)<0.1:
		return fall_state
	return null
	
func Physics_update(delta: float) -> void:
	if not parent.is_on_floor():
			parent.velocity.y += gravity * delta
		 
