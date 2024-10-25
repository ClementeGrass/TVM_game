extends Timer

@onready var round_timer = $"."
@onready var timer_label = $TimerLabel
var round_duration = 20
var round_over = true

func _ready():
	if is_multiplayer_authority():
		randomize()
		start_round()
		rpc("start_round")
		
	
func _process(delta):
	if is_multiplayer_authority() and round_timer.is_stopped() == false:
		update_timer_label(round_timer.time_left)
		rpc("update_timer_label", round_timer.time_left)
	if is_multiplayer_authority() and round_timer.is_stopped() == true and round_over:
		round_over = false
		end_round()
		rpc("round_over")

@rpc("authority", "call_remote", "reliable")
func start_round():
	round_timer.start(round_duration)
	update_timer_label(round_timer.time_left)

@rpc("authority", "call_remote", "reliable")
func update_timer_label(time_left):
	timer_label.text = str(round(time_left)) + "s"

@rpc("authority", "call_remote", "reliable")
func end_round():
	timer_label.text = "Round Over!" 
	print("Round over!")
	rpc("change_scene_for_all")

@rpc("call_local", "reliable")
func change_scene_for_all():
	#PARA SISTEMA DE DOS JUGADORES SOLAMENTE
	var players = get_tree().current_scene.get_node("Players").get_children()
	var i = 0
	for player in players:
		#Le sumo los puntos a los jugadores que no tienen la papa y no están de spectators
		if not player.has_potato and not player.spectator:
			Global.points_for_player[i] += 1
		i += 1		
	get_tree().change_scene_to_file("res://scenes/maps/points.tscn")
