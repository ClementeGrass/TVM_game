class_name WallRide
extends State


@export var idle_state: State
@export var jump_state: State
@export var fallingjump_state: State
@export var wall_animation: AnimationPlayer
@export var sprite: Sprite2D

# Called when the node enters the scene tree for the first time.
func enter():
	wall_animation.play("wall_ride")
	parent.rpc("send_animation","wall_ride")
	parent.jumps = 0
	parent.velocity.y = 0


func update(event: InputEvent) -> State:
	if event != null:
		if event.is_action_pressed("jump") and parent.jumps<2:
			return jump_state
		if (event.is_action_pressed("move_left") and sprite.scale.x >1) or (event.is_action_pressed("move_right") and sprite.scale.x<1):
			return fallingjump_state	
	return null	
	
func autoUpdate() -> State:
	return null	
func Physics_update(delta:float) -> void:
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
