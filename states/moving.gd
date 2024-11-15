extends State
class_name Moving

@export var idle_state: State
@export var jump_state: State
@export var rolling_state: State
@export var falling_state: State
@export var wallride_state: State
@export var emote_state: State
@export var boost_state: State
@export var moving_animation: AnimationPlayer
@export var sprite: Sprite2D

func enter() -> void:
	moving_animation.play("walking")
	parent.rpc("send_animation","walking")
	parent.change_collision_shape(RectangleShape2D.new(),1.5,1.5,6)
	parent.rpc("send_collision_shape",0,1.5,1.5,6)
# Called when the node enters the scene tree for the first time.
func update(event: InputEvent) -> State:
	if event != null:
		if parent.is_on_wall_only() and event.is_action_pressed("wall_grab"):
			return wallride_state	
		if not parent.is_on_floor() and event.is_action_pressed("crouch"):
			return falling_state	
		if event.is_action_pressed("crouch"):
			return rolling_state
		if event.is_action_pressed("jump") and parent.jumps<2:
			return jump_state
		if event.is_action_pressed("boost"):
			return boost_state	
		if event.is_action_pressed("emote") and parent.is_on_floor():
			return emote_state		
	return null		
	
func autoUpdate() -> State:
	if parent.velocity.x == 0:
		return idle_state
	return null		
func Physics_update(delta:float) -> void:
	var move_input = Input.get_axis("move_left","move_right")
	
	#Sin momentum al ir de der a izq o der a izq pero si de der o izq y soltar boton 
	var target_velocity_x = parent.SPEED * move_input
	if (move_input > 0 and parent.velocity.x < 0) or (move_input < 0 and parent.velocity.x > 0):
		parent.velocity.x = target_velocity_x
	else:
		parent.velocity.x = move_toward(parent.velocity.x, target_velocity_x, parent.ACCELERATION * delta)
	
	#con momentum en todas situaciones der izq o izq der
	#parent.velocity.x = move_toward(parent.velocity.x, parent.SPEED* move_input, parent.ACCELERATION * delta)
	if move_input>0:
		sprite.scale.x = 1.5
		parent.rpc("send_sprite",1.5)
	if move_input<0:
		sprite.scale.x = -1.5	
		parent.rpc("send_sprite",-1.5)
	if not parent.is_on_floor():
		parent.velocity.y += gravity * delta
	else:
		parent.jumps = 0	
				
