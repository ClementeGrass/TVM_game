class_name UILobbyPlayer
extends MarginContainer

@onready var player_name: Label = %Name
@onready var player_role: Label = %Role
@onready var ready_texture: TextureRect = %Ready

var player: Statics.PlayerData


func _ready() -> void:
	player_role.hide()
	ready_texture.hide()


func setup(value: Statics.PlayerData) -> void:
	player = value
	name = str(player.id)
	_update()
	Game.player_updated.connect(_on_player_updated)


func _on_player_updated(id: int) -> void:
	if id == player.id:
		_update()


func _update():
	_set_player_name(player.name)
	_set_player_role(player.role)


func _set_player_name(value: String) -> void:
	player_name.text = value


func _set_player_role(value: Statics.Role) -> void:
	player_role.visible = value != Statics.Role.NONE
	match value:
		Statics.Role.ROLE_A:
			player_role.text = "Naranjo"
		Statics.Role.ROLE_B:
			player_role.text = "Azul"
		Statics.Role.ROLE_C:
			player_role.text = "Verde"	
		Statics.Role.ROLE_D:
			player_role.text = "Rosado"	


func set_ready(value: bool) -> void:
	ready_texture.visible = value
