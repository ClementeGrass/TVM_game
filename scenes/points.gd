extends Node2D

@onready var curr_round = $ronda
@onready var ganador = $ganador
@onready var mejorde = $mejorde
@onready var rematch = $CheckButton
@onready var player_container = $PlayerContainer
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
	curr_round.text = ""
	mejorde.text = ""
	var continue_ = true
	Global.winners = []
	#Aquí reviso cuantos jugadores ya han igualado o superado la cantidad de victorias necesarias
	for i in range(Global.points_for_player.size()):
		if Global.points_for_player[i] >=(max_games):
			continue_ = false
			Global.winners.push_back(i)
			var cur_max = Global.points_for_player[Global.winners[0]]
			#Si el que agregue, tiene menos rondas ganadas que algiuen aquí, lo saco
			if cur_max > Global.points_for_player[i]:
				Global.winners.pop_back()
			#Si el que recien agregue es el que más rondas ganó, saco todo el resto y dejo al que agregue	
			elif cur_max< Global.points_for_player[i]:
				Global.winners = [i]	
	#Si nadie ha ganado aún			
	if continue_:
		#Agrego todos a la lista de ganadores, para que todos jueguen la próxima ronda
		for i in range(Global.points_for_player.size()):
			Global.winners.push_back(i)
		get_tree().change_scene_to_file(map_path)
	else:
		#Si hay más de un ganador, se envía a una última partida que decide todo
		if Global.winners.size() != 1:
			get_tree().change_scene_to_file(map_path)
		#Si hay solo un ganador, muestra pantalla final	
		else:		
			ganador.text = str(Game.players[Global.winners[0]].name) + " GANASTE"
			Global.curr_round = 1
			Global.winners = []
			for i in range(Game.players.size()):
				Global.points_for_player[i] = 0
				Global.winners.push_back(i)
				var label_player = player_container.get_child(i)
				label_player.text = ""
			rematch.visible = true
			rematch.disabled = false
			
func update_labels():
	if Game.players.size()>0:
		var i = 0
		for player in Game.players:
			var new_label = Label.new()
			new_label.text = player.name + ":" + str(Global.points_for_player[i])
			player_container.add_child(new_label)
			i+=1
		curr_round.text = "Ronda " + str(Global.curr_round)
		mejorde.text = "Hasta " + str(max_games) + " victorias"



func _on_check_button_toggled(toggled_on):
	rpc_id(1,"notify_rematch",toggled_on)

@rpc("any_peer","call_local","reliable")
func notify_rematch(decision:bool) -> void:
	if decision:
		players_ready += 1
	else:
		players_ready -= 1
	Debug.log(players_ready)	
	if players_ready >= Game.players.size():
		rpc("restart_for_all")
		ganador.text = "Iniciando otra partida"
		await get_tree().create_timer(3).timeout
		get_tree().change_scene_to_file("res://scenes/main.tscn")		
		
@rpc("any_peer","reliable")
func restart_for_all() -> void:
	ganador.text = "Iniciando otra partida"
	await get_tree().create_timer(3).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")		
	
@rpc("any_peer","reliable")
func change_final_scene(final_map: String) -> void:
	get_tree().change_scene_to_file(final_map)
			
