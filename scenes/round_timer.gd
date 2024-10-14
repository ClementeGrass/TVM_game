extends Timer

@onready var round_timer = $"."
@onready var timer_label = $TimerLabel
<<<<<<< HEAD
var round_duration = 5
=======
var round_duration = 7
>>>>>>> problemas_papas2
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
	var players = get_tree().current_scene.get_node("Players").get_children()
	#PARA SISTEMA DE DOS JUGADORES SOLAMENTE
	var i = 1
	for player in players:
		print(player.has_potato)
		#Server tiene potato
		if i == 1 and player.has_potato:
			Global.point_j2 += 1
		#Cliente tiene potato
		if i == 2 and player.has_potato:
			Global.point_j1 += 1
		i += 1
	get_tree().change_scene_to_file("res://scenes/maps/points.tscn")


