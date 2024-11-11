extends AnimationPlayer

@onready var player_container = $".."



# Called when the node enters the scene tree for the first time.
func _ready():
	speed_scale = 0.5
	#play("nubes")
	#play("fade_in")

func begin() -> void:
	var players_ = player_container.get_children()
	var fade_in_animation = get_animation("fade_in")
	Debug.log(fade_in_animation)
	# Configura la animación "fade_in"
	fade_in_animation.length = 3.0  # Duración de la animación (en segundos)
	
	# Asigna la animación al AnimationPlayer
	for player in players_:
		if player is Label:
			var track_index = fade_in_animation.add_track(Animation.TYPE_VALUE)
			fade_in_animation.track_set_path(track_index, player.get_path())
			fade_in_animation.track_insert_key(track_index, 0.0, 1.0)  # Valor inicial (opacidad 1)
			fade_in_animation.track_insert_key(track_index, 1.0, 1.0)  # Valor final (opacidad 0)		
	play("fade_in")
