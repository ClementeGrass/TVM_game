extends Timer

@onready var round_timer = $"."
@onready var timer_label = $TimerLabel
var round_duration = 7
var round_over = true

var maps = [
	"res://scenes/main.tscn",
	"res://scenes/maps/map1.tscn",
	"res://scenes/maps/map2.tscn",
	"res://scenes/maps/map3.tscn",
	"res://scenes/maps/map4.tscn",
	"res://scenes/maps/map5.tscn"
]

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
	var random_index = randi() % maps.size() 
	var random_map = maps[random_index]
	rpc("change_scene_for_all", random_map)

@rpc("call_local", "reliable")
func change_scene_for_all(map_path):
	get_tree().change_scene_to_file(map_path)


