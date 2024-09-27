extends Timer

@onready var round_timer = $"."
@onready var timer_label = $TimerLabel
var round_duration = 60
var round_over = true

var maps = [
	"res://scenes/maps/map1.tscn",
	"res://scenes/maps/map2.tscn",
	"res://scenes/maps/map3.tscn",
	"res://scenes/maps/map4.tscn",
	"res://scenes/maps/map5.tscn"
]

func _ready():
	randomize()
	start_round()
	
func _process(delta):
	if round_timer.is_stopped() == false:
		update_timer_label(round_timer.time_left)
	if round_timer.is_stopped() == true and round_over:
		round_over = false
		end_round()

func start_round():
	round_timer.start(round_duration)
	update_timer_label(round_timer.time_left)

func update_timer_label(time_left):
	timer_label.text = str(round(time_left)) + "s"

func end_round():
	timer_label.text = "Round Over!" 
	print("Round over!")
	change_to_random_map()
	

#Este cambio tiene que se rpc 
func change_to_random_map():
	var random_index = randi() % maps.size() 
	var random_map = maps[random_index]
	get_tree().change_scene_to_file(random_map) 



