extends Node2D

@onready var curr_round = $ronda
@onready var ganador = $ganador
@onready var mejorde = $mejorde
@onready var rematch = $CheckButton
@onready var player_container = $PlayerContainer
var max_games = 5
var players_ready = 0

var maps = [
	"res://scenes/main.tscn",
	"res://scenes/maps/map1.tscn",
	"res://scenes/maps/map2.tscn",
	"res://scenes/maps/map3.tscn",
	"res://scenes/maps/map4.tscn",
	"res://scenes/maps/map5.tscn"
]

#Ready function that updates the labels and waits to change to the next round
func _ready():
	update_labels()
	rematch.visible = false
	rematch.disabled = true
		
	Global.curr_round += 1
	#Timer to allow players to see for 5 seconds the points reached after the round
	await get_tree().create_timer(5).timeout
	
	if is_multiplayer_authority():
		Global.map_turn+=1
		if(Global.map_turn>len(maps)-1):
			Global.map_turn = 0
		var random_index = Global.map_order[Global.map_turn]
		var random_map = maps[random_index]
		rpc("change_scene_for_all", random_map)


#RPC funciton that changes the scene if another round is needed
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
		
#Function in charge of updating the labels with the latest score			
func update_labels():
	if Game.players.size()>0:
		var i = 0
		var jugadores = player_container.get_children()
		for player in Game.players:
			jugadores[i].text = player.name + ":" + str(Global.points_for_player[i])
			i+=1
		curr_round.text = "Ronda " + str(Global.curr_round)
		mejorde.text = "Hasta " + str(max_games) + " victorias"


#Function that checks if the rematch button has been pressed
func _on_check_button_toggled(toggled_on):
	rpc_id(1,"notify_rematch",toggled_on)

#RPC function that notifies the server if someone has chosen to rematch
@rpc("any_peer","call_local","reliable")
func notify_rematch(decision:bool) -> void:
	#Aquí revisa si el jugador eligió apretar o no el botón
	if decision:
		players_ready += 1
	else:
		players_ready -= 1
	#Aquí revisa si todos quieren jugar otra partida	
	if players_ready >= Game.players.size():
		#Si todos quieren, se reinicia la partida
		rpc("restart_for_all")
		ganador.text = "Iniciando otra partida"
		await get_tree().create_timer(3).timeout
		get_tree().change_scene_to_file("res://scenes/main.tscn")		
	
#RPC funciton in charge of restarting the game for everyone		
@rpc("any_peer","reliable")
func restart_for_all() -> void:
	ganador.text = "Iniciando otra partida"
	await get_tree().create_timer(3).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")		
	
#RPC funciton that changes the scene to the final round	
@rpc("any_peer","reliable")
func change_final_scene(final_map: String) -> void:
	get_tree().change_scene_to_file(final_map)
			
