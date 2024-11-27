extends Timer

@onready var round_timer = $"."
@onready var second_label = $Panel/Seconds
@onready var msecond_label = $Panel/Milliseconds
var round_duration = 60
var round_over = true


var time: float = 0.0
var seconds: int = 0
var mseconds: int = 0 

#Ready function thats is in charge of telling every player (and server) that the round has started

func _ready():
	if is_multiplayer_authority():
		randomize()
		start_round()
		rpc("start_round")
		
#Process funtion in charge of checking the round timer to see if the round is over	
func _process(delta):
	if is_multiplayer_authority() and round_timer.is_stopped() == false:
		update_timer_label(round_timer.time_left)
		rpc("update_timer_label", round_timer.time_left)
	if is_multiplayer_authority() and round_timer.is_stopped() == true and round_over:
		round_over = false
		end_round()
		rpc("round_over")

#Rpc function in charge of staring the round
@rpc("authority", "call_remote", "reliable")
func start_round():
	round_timer.start(round_duration)
	update_timer_label(round_timer.time_left)

#Rpc function that updates the timer label
@rpc("authority", "call_remote", "reliable")
func update_timer_label(time_left):
	seconds = time_left
	mseconds = fmod(time_left, 1) * 100
	second_label.text = "%02d" % seconds
	msecond_label.text = "%02d" % mseconds

#Rpc funciton that ends the round
@rpc("authority", "call_remote", "reliable")
func end_round():
	print("Round over!")
	rpc("change_scene_for_all")

#Rpc funciton that passes the screen to the points screen
@rpc("call_local", "reliable")
func change_scene_for_all():
	var players = get_tree().current_scene.get_node("Players").get_children()
	var i = 0
	if not Global.last_loser.is_empty():
		Global.last_loser.clear()
	for player in players:
		#Le sumo los puntos a los jugadores que no tienen la papa y no están de spectators
		if not player.has_potato and not player.spectator:
			Global.points_for_player[i] += 1
			Global.last_loser.append(false)
		if player.has_potato:
			Global.last_loser.append(true)
		i += 1		
	print(Global.last_loser)
	get_tree().change_scene_to_file("res://scenes/maps/points.tscn")
