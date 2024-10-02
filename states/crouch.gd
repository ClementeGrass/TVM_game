extends State

@export var moving_state: State
@export var idle_state: State
@export var crouch_animation: AnimationPlayer


# Called when the node enters the scene tree for the first time.
func enter() -> void:
	parent.velocity.x = 0
	crouch_animation.play("crouch")
	parent.rpc("send_animation","crouch")
	parent.change_collision_shape(RectangleShape2D.new(),1.5,1,15)
	parent.rpc("send_collision_shape",0,1.5,1,15)
	
func update(event:InputEvent) -> State:
	if event != null:
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			return moving_state	
		if event.is_action_released("crouch"):
			return idle_state	
	return null
	
func Physics_update(delta:float) -> void:
	if not parent.is_on_floor():
		parent.velocity.y += gravity * delta	
