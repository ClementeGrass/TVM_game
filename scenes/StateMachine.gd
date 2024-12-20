extends Node
@export var initial_state: State
var states: Dictionary = {}
var current_state: State
var is_frozen: bool = false
# Called when the node enters the scene tree for the first time.
func init(parent: CharacterBody2D):
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_transition.connect(change_state)
			child.parent = parent
	if initial_state:
		initial_state.enter()
		current_state = initial_state

# Called every frame. 'delta' is the elapsed time since the previous frame.
		
func handle_physics(delta):
	if current_state:
		current_state.Physics_update(delta)			
		
#Function where the state machine handles player inputs		
func handle_inputs(event):
	var new_state = null
	new_state = current_state.update(event)	
	if is_frozen:
		return
	if new_state != current_state && new_state:
		change_state(current_state, new_state)

#Fucntion where the state mahcine handles changes not necesarrily donde by inputs
func handle_animations():
	var new_state = current_state.autoUpdate()
	if is_frozen:
		return
	if new_state != current_state && new_state:
		change_state(current_state, new_state)	
		
#Function in charge of changing the current state of the player		
func change_state(state, new_state):
	if state != current_state:
		return
	#var new_state_name = states.get(new_state.name.to_lower())
	if current_state:
		current_state.exit()
	#if is_multiplayer_authority():
		#Debug.log(new_state)	
	current_state = new_state	
	new_state.enter() 
