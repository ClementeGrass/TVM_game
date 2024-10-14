extends Node2D

@export var player_scene: PackedScene
@onready var players: Node2D = $Players
@onready var markers: Node2D = $Markers
@onready var fondo: TextureRect = $TextureRect


var player
@export var papas = [false,false]
# Get the gravity from the project settings to be synced with RigidBody nodes.

var gravity = 1000

var maps = [
	"res://scenes/main.tscn",
	"res://scenes/maps/map1.tscn",
	"res://scenes/maps/map2.tscn",
	"res://scenes/maps/map3.tscn",
	"res://scenes/maps/map4.tscn",
	"res://scenes/maps/map5.tscn"
]

var curr_map = "res://scenes/main.tscn"

var fondos = [
	["res://assets/forest2.png",Vector2(1,1)],
	["res://assets/midnight.png",Vector2(5,5)],
	["res://assets/dark.png", Vector2(1.5,1.5)],
	["res://assets/mountains.png",Vector2(2,2.75)],
	["res://assets/sky.png",Vector2(0.75,1.5)],
	["res://assets/OldDungeon.png",Vector2(0.54,0.8)],
]

func _ready() -> void:
	var map_path = get_scene_file_path()
	var index_fondo = maps.find(map_path)
	var text = TextureRect.new()
	text.texture = load(fondos[index_fondo][0])
	text.scale = fondos[index_fondo][1]
	text.z_index = -2
	add_child(text)
	if Game.players.size()>0:
		for i in Game.players.size():
			var player_data = Game.players[i]
			var player_inst = player_scene.instantiate()
			player_data.scene = player_inst
			players.add_child(player_inst)
			player_inst.setup(player_data,i)
			player_inst.global_position = markers.get_child(i).global_position
		if multiplayer.is_server():
			await get_tree().create_timer(1).timeout
			var papa = randi() % Game.players.size()
			assign_potato.rpc(1)

@rpc("call_local", "reliable")
func assign_potato(papa: int) -> void:
	if papa < players.get_child_count():
		var player = players.get_child(papa)
		player.set_potato_state(true)


@rpc("any_peer","reliable")
func swap_potato(_pos: int,id_:int) -> void:
	rpc_id(id_,"set_potato_state",false)

