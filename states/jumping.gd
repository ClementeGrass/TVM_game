extends State
class_name Jumping

@export var idle_state: State
@export var moving_state: State
@export var falling_state: State
@export var fallJump_state :State
@export var wallride_state: State
@export var boost_state: State
@export var jumping_animation: AnimationPlayer
@export var sprite: Sprite2D
@export var state_machine: Node
# Called when the node enters the scene tree for the first time.
var JUMP_VELOCITY = -400.0
var jump_time = 0.0
var MIN_JUMP_DURATION = 0.5

func enter() -> void:
	parent.velocity.y = JUMP_VELOCITY
	parent.jumps+=1
	jumping_animation.play("jumping")
	parent.rpc("send_animation","jumping")
	jump_time = 0.0
	

func update(event: InputEvent) -> State:
	if event != null:	
		if event.is_action_pressed("jump"):
			if parent.jumps<2:
				parent.jumps+=1
				parent.velocity.y = JUMP_VELOCITY
		if not parent.is_on_floor() and event.is_action_pressed("crouch"):
			return falling_state
		if event.is_action_pressed("boost"):
			return boost_state				
		if parent.is_on_wall_only() and event.is_action_pressed("wall_grab"):
			return wallride_state		
	return null	

func autoUpdate() -> State:	
	if not parent.is_on_floor() and parent.velocity.y>0:
		return fallJump_state
	if parent.is_on_floor() and (jump_time > MIN_JUMP_DURATION):
		parent.jumps= 0
		if parent.velocity.x != 0:
			return moving_state
		else:
			return idle_state	
	return null		


func Physics_update(delta:float) -> void:
	var move_input = Input.get_axis("move_left","move_right")
	parent.velocity.x = move_toward(parent.velocity.x, parent.SPEED* move_input, parent.ACCELERATION * delta)
	if parent.velocity.x>0:
		sprite.scale.x = 1.5
		parent.rpc("send_sprite",1.5)
	if parent.velocity.x<0:
		sprite.scale.x = -1.5	
		parent.rpc("send_sprite",-1.5)
	if not parent.is_on_floor():
			parent.velocity.y += gravity * delta
			
	jump_time += delta 
				
