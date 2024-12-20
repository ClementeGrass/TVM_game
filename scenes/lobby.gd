extends MarginContainer

@export var lobby_player_scene: PackedScene

# { id: true }
var status = { 1 : false }
var _menu_stack: Array[Control] = []

@onready var user = %User
@onready var host = %Host
@onready var join = %Join
@onready var tutorial = %Tutorial
@onready var credits = %Credits
@onready var ip = %IP
@onready var back_join: Button = %BackJoin
@onready var confirm_join: Button = %ConfirmJoin
@onready var role_a: Button = %RoleA
@onready var role_b: Button = %RoleB
@onready var role_c: Button = %RoleC
@onready var role_d: Button = %RoleD
@onready var back_ready: Button = %BackReady
@onready var volver_tutorial: Button = %Volver
@onready var volver_credits: Button = %VolverCredits
@onready var binds: Button = %Binds
@onready var volver_binds = %VolverBinds
@onready var ready_toggle: Button = %Ready
@onready var menus: MarginContainer = %Menus
@onready var start_menu = %StartMenu
@onready var join_menu = %JoinMenu
@onready var ready_menu = %ReadyMenu
@onready var tutorial_menu = %TutorialMenu
@onready var binds_menu = %BindsMenu
@onready var credits_menu = %CreditsMenu
@onready var players = %Players
@onready var start_timer: Timer = $StartTimer
@onready var time_container: HBoxContainer = %TimeContainer
@onready var time: Label = %Time
@onready var potato1: Sprite2D =$VegetablePotato
@onready var potato2: Sprite2D = $VegetablePotato2
@onready var fox: AnimatedSprite2D = $Fox
@onready var fox_blue: AnimatedSprite2D = $FoxBlue
@onready var fox_green: AnimatedSprite2D = $FoxGreen
@onready var fox_pink: AnimatedSprite2D = $FoxPink

var maps = [
	"res://scenes/main.tscn",
	"res://scenes/maps/map1.tscn",
	"res://scenes/maps/map2.tscn",
	"res://scenes/maps/map3.tscn",
	"res://scenes/maps/map4.tscn",
	"res://scenes/maps/map5.tscn"
]

func _ready():
	if Game.multiplayer_test:
		get_tree().change_scene_to_file.call_deferred("res://scenes/lobby_test.tscn")
		return
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	Game.player_updated.connect(func(_id) : _check_ready())
	Game.players_updated.connect(_check_ready)
	
	host.pressed.connect(_on_host_pressed)
	join.pressed.connect(_on_join_pressed)
	tutorial.pressed.connect(_on_tutorial_pressed)
	binds.pressed.connect(_on_binds_pressed)
	credits.pressed.connect(_on_credits_pressed)
	
	confirm_join.pressed.connect(_on_confirm_join_pressed)
	
	back_join.pressed.connect(_back_menu)
	volver_tutorial.pressed.connect(_back_menu)
	volver_binds.pressed.connect(_back_menu)
	back_ready.pressed.connect(_back_menu)
	volver_credits.pressed.connect(_back_menu)
	
	fox.play("default")
	fox_blue.play("default")
	fox_green.play("default")
	fox_pink.play("default")
	
	role_a.pressed.connect(func(): Game.set_current_player_role(Statics.Role.ROLE_A))
	role_b.pressed.connect(func(): Game.set_current_player_role(Statics.Role.ROLE_B))
	role_c.pressed.connect(func(): Game.set_current_player_role(Statics.Role.ROLE_C))
	role_d.pressed.connect(func(): Game.set_current_player_role(Statics.Role.ROLE_D))
	
	
	ready_toggle.pressed.connect(_on_ready_toggled)
	
	start_timer.timeout.connect(_on_start_timer_timeout)
	
	ready_toggle.disabled = true
	time_container.hide()

	_go_to_menu(start_menu)
	
	user.text = OS.get_environment("USERNAME") + (str(randi() % 1000) if Engine.is_editor_hint()
 else "")
	
	Game.upnp_completed.connect(_on_upnp_completed, 1)


func _process(_delta: float) -> void:
	potato1.rotation += _delta
	potato2.rotation += _delta
	if !start_timer.is_stopped():
		time.text = str(ceil(start_timer.time_left))


func _on_upnp_completed(error) -> void:
	print(error)
	if error == OK:
		Debug.log("Port Opened", 5)
	else:
		Debug.log("Port Error", 5)


func _on_host_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	
	var err = peer.create_server(Statics.PORT, Statics.MAX_CLIENTS)
	if err:
		Debug.log("Host Error: %d" %err)
		return
	
	multiplayer.multiplayer_peer = peer
	
	var player = Statics.PlayerData.new(multiplayer.get_unique_id(), user.text)
	_add_player(player)
	
	_go_to_menu(ready_menu)
	
	Debug.add_to_window_title("(Server)")
	Game.set_player_id("1")


func _on_join_pressed() -> void:
	_go_to_menu(join_menu)
	
func _on_tutorial_pressed() -> void:
	_go_to_menu(tutorial_menu)	

func _on_binds_pressed() -> void:
	_go_to_menu(binds_menu)
	
func _on_credits_pressed() -> void:
	_go_to_menu(credits_menu)	

func _on_confirm_join_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip.text, Statics.PORT)
	if err:
		Debug.log("Host Error: %d" %err)
		return
	
	multiplayer.multiplayer_peer = peer
	
	var player = Statics.PlayerData.new(multiplayer.get_unique_id(), user.text)
	_add_player(player)
	
	_go_to_menu(ready_menu)


func _on_connected_to_server() -> void:
	Debug.log("connected_to_server")


func _on_connection_failed() -> void:
	Debug.log("connection_failed")


func _on_peer_connected(id: int) -> void:
	Debug.log("peer_connected %d" % id)
	if not multiplayer.is_server() and not Game.get_current_player().index:
		await Game.player_index_received
	
	# A peer connected, send it my info
	send_info.rpc_id(id, Game.get_current_player().to_dict())
	if multiplayer.is_server():
		Game.set_player_index.rpc_id(id, status.size())
		for player_id in status:
			set_player_ready.rpc_id(id, player_id, status[player_id])
		status[id] = false


func _on_peer_disconnected(id: int) -> void:
	Debug.log("peer_disconnected %d" % id)
	_remove_player(id)
	if multiplayer.is_server():
		starting_game.rpc(false)
	
	# Server closed connection
	if id == 1:
		_back_menu()


func _on_server_disconnected() -> void:
	Debug.log("server_disconnected")


func _add_player(player: Statics.PlayerData) -> void:
	Game.add_player(player)
	
	var lobby_player = lobby_player_scene.instantiate() as UILobbyPlayer
	players.add_child(lobby_player)
	lobby_player.setup(player)
	
	for child in players.get_children():
		players.move_child(child, child.player.index)
	
	


func _remove_player(id: int):
	var lobby_player = players.find_child(str(id), true, false)
	players.remove_child(lobby_player)
	lobby_player.queue_free()
	status.erase(id)
	Game.remove_player(id)


@rpc("any_peer", "reliable")
func send_info(info_dict: Dictionary) -> void:
	var player = Statics.PlayerData.new(info_dict.id, info_dict.name, info_dict.index, info_dict.role)
	_add_player(player)


func _paint_ready(id: int) -> void:
	for child in players.get_children():
		if child.name == str(id):
			child.modulate = Color.GREEN_YELLOW


func _on_ready_toggled() -> void:
	player_ready.rpc_id(1, multiplayer.get_unique_id())


@rpc("reliable", "any_peer", "call_local")
func player_ready(id: int):
	if multiplayer.is_server():
		status[id] = !status[id]
		set_player_ready.rpc(id, status[id])
		var all_ok = true
		for ok in status.values():
			all_ok = all_ok and ok
		if all_ok:
			starting_game.rpc(true)
		else:
			starting_game.rpc(false)


@rpc("reliable", "any_peer", "call_local")
func set_player_ready(id: int, value: bool):
	for child in players.get_children():
		var player = child as UILobbyPlayer
		if player.player.id == id:
			player.set_ready(value)


@rpc("any_peer", "call_local", "reliable")
func starting_game(value: bool):
	role_a.disabled = value
	role_b.disabled = value
	role_c.disabled = value
	role_d.disabled = value
	back_ready.disabled = value
	time_container.visible = value
	if value:
		start_timer.start()
		var pos = 0
		if is_multiplayer_authority():
			Global.map_order.shuffle()
			var new_order = Global.map_order
			rpc("send_new_order",new_order)
		#Inicializo las variables globales con las que manejo la victoria y los revanchas
		for i in Game.players:
			Global.points_for_player.push_back(0)
			Global.points_old_for_player.push_back(0)
			Global.names_for_player.push_back("")
			Global.rematch_for_player.push_back(false)
			Global.winners.push_back(pos)
			pos += 1
	else:
		start_timer.stop()

@rpc("any_peer","reliable")	
func send_new_order(order) -> void:
	Global.map_order = order

@rpc("any_peer", "call_local", "reliable")
func start_game(first_map: int) -> void:
	Game.players.sort_custom(func(a, b): return a.index < b.index)
	#get_tree().change_scene_to_file("res://scenes/main.tscn")
	get_tree().change_scene_to_file(maps[first_map])



func _check_ready() -> void:
	var roles = []
	for player in Game.players:
		if not player.role in roles and player.role != Statics.Role.NONE:
			roles.push_back(player.role)
	ready_toggle.disabled = roles.size() != Game.players.size() or Game.players.size()<2


func _disconnect():
	multiplayer.multiplayer_peer.close()
	
	for player in players.get_children():
		players.remove_child(player)
		player.queue_free()
	
	ready_toggle.disabled = true
	status = { 1 : false }
	Game.players = []


func _on_start_timer_timeout() -> void:
	if multiplayer.is_server():
		print(Global.points_for_player.size())	
		start_game.rpc(Global.map_order[0])


func _hide_menus():
	for child in menus.get_children():
		child.hide()


func _go_to_menu(menu: Control) -> void:
	_hide_menus()
	_menu_stack.push_back(menu)
	menu.show()


func _back_menu() -> void:
	_hide_menus()
	_menu_stack.pop_back()
	var menu = _menu_stack.back()
	if menu:
		menu.show()
	_disconnect()


func _back_to_first_menu() -> void:
	var first = _menu_stack.front()
	_menu_stack.clear()
	if first:
		_menu_stack.push_back(first)
		first.show()
	if Game.is_online():
		_disconnect()
