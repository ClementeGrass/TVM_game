extends Node2D

@onready var curr_round = $ronda
@onready var pj1 = $pj1
@onready var pj2 = $pj2
@onready var ganador = $ganador
@onready var mejorde = $mejorde
@onready var rematch = $CheckButton
var max_games = 1
var players_ready = 0

var maps = [
	"res://scenes/main.tscn",
	"res://scenes/maps/map1.tscn",
	"res://scenes/maps/map2.tscn",
	"res://scenes/maps/map3.tscn",
	"res://scenes/maps/map4.tscn",
	"res://scenes/maps/map5.tscn"
]

func _ready():
	update_labels()
	rematch.visible = false
	rematch.disabled = true
		
	Global.curr_round += 1
	await get_tree().create_timer(5).timeout
	
	if is_multiplayer_authority():
		var random_index = randi() % maps.size() 
		var random_map = maps[random_index]
		rpc("change_scene_for_all", random_map)


@rpc("call_local", "reliable")
func change_scene_for_all(map_path):
	pj1.text = ""
	pj2.text = ""
	curr_round.text = ""
	mejorde.text = ""
	#jugador 1 es server 
	if Global.point_j1 == (max_games / 2 + 1):
		ganador.text = "JUGADOR 1 GANASTE"
		Global.point_j1 = 0
		Global.point_j2 = 0
		rematch.visible = true
		rematch.disabled = false
	#ugador 2 es cleinte 
	elif Global.point_j2 == (max_games / 2 + 1):
		Global.point_j1 = 0
		Global.point_j2 = 0
		ganador.text = "JUGADOR 2 GANASTE"
		rematch.visible = true
		rematch.disabled = false
	else:
		get_tree().change_scene_to_file(map_path)
	
func update_labels():
	pj1.text = str(Global.point_j1)
	pj2.text = str(Global.point_j2)
	curr_round.text = "Ronda " + str(Global.curr_round) + "/" + str(max_games)
	mejorde.text = "Mejor de " + str(max_games / 2 + 1)



func _on_check_button_toggled(toggled_on):
	rpc_id(1,"notify_rematch",toggled_on)

@rpc("any_peer","reliable","call_local")
func notify_rematch(decision:bool) -> void:
	if decision:
		players_ready += 1
	else:
		players_ready -= 1
	Debug.log(players_ready)	
	if players_ready >= Game.players.size():
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		rpc("restart_for_all")		
		
@rpc("any_peer","call_local","reliable")
func restart_for_all() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")			
