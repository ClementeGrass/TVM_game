extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var potato_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var reach: Area2D = $Reach
@onready var reach_collision: CollisionShape2D = $Reach/CollisionShape2D
@onready var caught: Hurtbox = $Caught
@onready var caught_collision: CollisionShape2D = $Caught/CollisionShape2D
@onready var state_machine = $StateMachine
@export var potato_scene: PackedScene
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer


var JUMP_VELOCITY = 400.0
var ACCELERATION = 1000
var jumps = 0
var potatos = 0
var has_potato = false
var has_thrown_potato: bool = false
var ignore_potato: bool = false
var player
var pos
var id

# Get the gravity from the project settings to be synced with RigidBody nodes.

var gravity = 1000

#Function setup creates players with correct values
#Sets their multiplayer authority, as well as the ids to use for rpcs

func setup(player_data: Statics.PlayerData,pos_:int) -> void:
	name = str(player_data.id)
	set_multiplayer_authority(player_data.id)
	potato_spawner.set_multiplayer_authority(1)
	reach.id = get_multiplayer_authority()
	id = get_multiplayer_authority()

func _ready():
	reach_collision.disabled = true
	state_machine.init(self)
	
#Input funciton that is in charge fo receiving players input
#Divided into two, inputs where the state of the player can be changed (from idle to moving for example)
#And inputs for when a player has the potato, as they can be done in any state and while not stunned	
	
func _input(event:InputEvent) -> void:
	if is_multiplayer_authority():
		state_machine.handle_inputs(event)
		if has_potato && not state_machine.is_frozen:
			if event.is_action_pressed("lanzar"):
				throw_Potato.rpc_id(1)
			if event.is_action_pressed("pintar"):
				disable_reach.rpc_id(1, false)
		if event.is_action_released("pintar"):
			disable_reach.rpc_id(1, true)
			
#RPC function in charge of controling when a player´s reach is disabled or not

@rpc("call_local", "reliable")
func disable_reach(disabled: bool) -> void:
	reach_collision.set_deferred("disabled", disabled)
	
#Function in charge of changing the player´s collision shape, when they are moving
#Especially important for actions such as crouching	
	
func change_collision_shape(shape:Shape2D,scale_x: float, scale_y:float,position_y: float)-> void:
	caught_collision.shape = shape
	caught_collision.scale.x = scale_x
	caught_collision.scale.y= scale_y	
	caught_collision.position.y = position_y
	collision_shape.shape = shape
	collision_shape.scale.x = scale_x
	collision_shape.scale.y= scale_y	
	collision_shape.position.y = position_y
	
#RPC function that does the same thing as the one above	
	
@rpc()
func send_collision_shape(shape:int,scale_x: float, scale_y:float,position_y: float)-> void:
	change_actual_shape(shape)
	caught_collision.scale.x = scale_x
	caught_collision.scale.y= scale_y
	caught_collision.position.y = position_y
	collision_shape.scale.x = scale_x
	collision_shape.scale.y= scale_y	
	collision_shape.position.y = position_y
	
#Function in charge of actually changing the shape that is sent by the RPC funciton when changing the
#collision shape.
#This is used, as RPC does not allow for complez objects such as shapes to be sent by RPC	

func change_actual_shape(shape:int) -> void:
	if shape == 0:
		collision_shape.shape = RectangleShape2D.new()
		caught_collision.shape = RectangleShape2D.new()
	elif shape == 1:
		collision_shape.shape = CircleShape2D.new()		
		caught_collision.shape = RectangleShape2D.new()
		
		

func _process(delta) -> void:
	if is_multiplayer_authority():
		state_machine.handle_animations()	
					

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		state_machine.handle_physics(delta) 
		move_and_slide()
		send_position.rpc(position,velocity)
		
			
#RPC funciton that plays the animation according to what state the player is currently in
			
@rpc("reliable")		
func send_animation(animation: StringName)	-> void:
	animations.play(animation)
	
#RPC funciton that stops the animation the player is in once they leave a certain state		
	
@rpc("reliable")
func stop_animation() -> void:
	animations.stop()

#RPC function that is in charge of sending the players what side the other player is looking/heading to
@rpc()
func send_sprite(scale: float) -> void:
	sprite.scale.x = scale
	
#RPC function that sends my current position to the other players	
@rpc()
func send_position(pos:Vector2, vel: Vector2) -> void:
	position = lerp(position,pos,0.5)
	velocity = lerp(velocity,vel,0.5)
	
	
#Function in charge of creating and throwing the potato
#Takes into consideration if i have already thrown a potato and where i am looking at	
@rpc("call_local", "any_peer", "reliable")
func throw_Potato() -> void:
	if not potato_scene:
		Debug.log("Cant throw potato")
		return
	if has_thrown_potato:
		return
			
	var potato_inst = potato_scene.instantiate()
	var direction = sprite.scale.x
	potato_inst.velocity.x = 400 * direction
	potato_inst.add_to_group("potato")
	potato_inst.global_position = global_position
	potato_inst.global_rotation = global_rotation
	potato_inst.id = get_multiplayer_authority()	
	# Añadir lógica de colisiones: el jugador que lanza no colisiona con la papa
	potato_inst.collision_layer = 0
	potato_inst.collision_mask = ~(1 << self.collision_layer)  # Desactivar colisión con el jugador que la lanza
	
	potato_spawner.add_child(potato_inst, true)
	await _ignore_potato_temporarily(0.5) # ignore por 0.5 segundos la colisiones
	has_thrown_potato = true  # Marcar que se ha lanzado una papa
	
#Function that tells the player that they have picked up the potato they have thrown
#Also makes sure that when i tag someone without using the potato, sets back to false has_thrown_potato
func take_potato() -> void:
	has_thrown_potato = false
	
	
	
@rpc()
func update_sprite(frame: int) -> void:
	sprite.frame = frame


#Function that tells the players that the potato has been passed to someone else
#As well as changing my one potato_state, makes sure to change the other player´s potato_state
func potato_changed(id_: int) -> void:
	set_potato_state.rpc(true)
	var instigator = Game.get_player(id_)
	if instigator.scene:
		instigator.scene.set_potato_state.rpc(false)

#RPC function that changes the potato_state according to the variable state
		
@rpc("any_peer", "reliable", "call_local")
func set_potato_state(state:bool) -> void:
	Debug.log(get_multiplayer_authority())
	has_potato = state
	if has_potato:
		sprite.modulate = Color(1.0,0.5,0.5)
	else:
		sprite.modulate = Color(1.0,1.0,1.0)	
	
	
#Function called upon when i have been stunned (caught by the player woith the potato	
func stun() -> void:
	rpc_id(get_multiplayer_authority(),"notify_stun")
	
	
#RPC function that begins the process of being stunned
#Makes sure their state_machine is frozen, so they cannot move, changes the state to stunned and
#starts the timer for the amount if time they are stunned
@rpc("any_peer","call_local","reliable")	
func notify_stun() -> void:
	state_machine.is_frozen = true
	state_machine.change_state(state_machine.current_state,state_machine.states["stunned"])
	timer.start()
	
# Función para ignorar la papa temporalmente después de lanzarla
func _ignore_potato_temporarily(duration: float) -> void:
	ignore_potato = true
	await get_tree().create_timer(duration).timeout
	ignore_potato = false
	
