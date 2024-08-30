extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var potato_spawner: MultiplayerSpawner = $MultiplayerSpawner

@export var potato_scene: PackedScene


var SPEED = 300.0
var JUMP_VELOCITY = 400.0
var ACCELERATION = 1000
var jumps = 0

var player
# Get the gravity from the project settings to be synced with RigidBody nodes.

var gravity = 1000

func setup(player_data: Statics.PlayerData) -> void:
	name = str(player_data.id)
	set_multiplayer_authority(player_data.id)


func _input(event:InputEvent) -> void:
	if is_multiplayer_authority():
		if event.is_action_pressed("crouch"):
			rpc("update_sprite",20)
			update_sprite(20)
		if event.is_action_released("crouch"):
			rpc("update_sprite",0)
			update_sprite(0)
		if event.is_action_pressed("lanzar"):
			throw_Potato()
		if event.is_action_pressed("move_left"):
			sprite.frame=0
					
			
		

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var move_input = Input.get_axis("move_left","move_right")
		velocity.x = move_toward(velocity.x, SPEED* move_input, ACCELERATION * delta)
		if Input.is_action_just_pressed("jump") and jumps <2:
			velocity.y= -JUMP_VELOCITY
			jumps+=1
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			jumps = 0	 
		move_and_slide()
		send_position.rpc(position,velocity)

@rpc()
func send_position(pos:Vector2, vel: Vector2) -> void:
	position = lerp(position,pos,0.5)
	velocity = lerp(velocity,vel,0.5)
	
	
@rpc()
func throw_Potato() -> void:
	if not potato_scene:
		Debug.log("Cant throw potato")
		return
	var potato_inst = potato_scene.instantiate()
	potato_inst.global_position = global_position	
	potato_inst.global_rotation = global_rotation
	potato_spawner.add_child(potato_inst, true)
	potato_inst.setup.rpc(get_tree().get_multiplayer().get_unique_id())

@rpc()
func update_sprite(frame: int) -> void:
	sprite.frame = frame
	
