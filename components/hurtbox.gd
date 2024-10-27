class_name Hurtbox
extends Area2D


@export var reach: CollisionShape2D

func _ready() -> void:
	if is_multiplayer_authority():
		area_entered.connect(_on_area_entered)
	

#Function that checks when an object has entered the player´s hurtbox
func _on_area_entered(area: Area2D) -> void:
	var es_papa = true
	# Verifica si el area es un RigidBody2D que tiene un nodo hijo Hitbox
	var parent = area.get_parent() as RigidBody2D
	if parent == null:	
		#Si no era la papa, revisa si es el jugador quien lo pintó
		parent = area.get_parent() as CharacterBody2D
		if parent == null:
			return
	
	var hitbox = null
	#Obtengo el hitbox de la papa/jugador, si llega a ser este el area con el que chocó
	if parent.has_node("Hitbox"):
		hitbox = parent.get_node("Hitbox") as Hitbox 
	if hitbox == null:
		parent = area as Hitbox
		if parent == null:
			return
	
	#Revisa si la colisión es entre el dueño de la papa y la papa		
	if parent.id == owner.get_multiplayer_authority():
		#Si lo es, agarra la papa
		if owner.ignore_potato == false and es_papa:
			if owner.has_method("take_potato"):
				owner.take_potato()
				if parent.is_in_group("potato"):
					parent.queue_free()
	
	#Si la persona ha sido pintada por la papa	
	if parent.id != owner.get_multiplayer_authority():
		if owner.has_method("stun"):
			owner.stun()
			owner.take_potato()
			owner.potato_changed(parent.id)
		#revisa si fue pintado usando la papa o si hay papas en la cancha, para eliminarlas de la escena	
		if parent.is_in_group("potato"):
				parent.queue_free()
		else:
			var papas = get_tree().get_nodes_in_group("potato")
			if papas.size()>0:
				for papa in papas:
					papa.queue_free()		
				
