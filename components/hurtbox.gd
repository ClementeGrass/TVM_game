class_name Hurtbox
extends Area2D


@export var reach: CollisionShape2D

func _ready() -> void:
	if is_multiplayer_authority():
		area_entered.connect(_on_area_entered)
	

func _on_area_entered(area: Area2D) -> void:
	var es_papa = true
	# Verifica si el area es un RigidBody2D que tiene un nodo hijo Hitbox
	var parent = area.get_parent() as RigidBody2D
	if parent == null:	
		parent = area.get_parent() as CharacterBody2D
		if parent == null:
			return
	
	var hitbox = parent.get_node("Hitbox") as Hitbox 
	if hitbox == null:
		parent = area as Hitbox
		if parent == null:
			return
			
	if parent.id == owner.get_multiplayer_authority():
		if owner.ignore_potato == false and es_papa:
			if owner.has_method("take_potato"):
				owner.take_potato()
				if parent.is_in_group("potato"):
					parent.queue_free()
		
	if parent.id != owner.get_multiplayer_authority():
		if owner.has_method("stun"):
			owner.stun()
			owner.take_potato()
			owner.potato_changed(parent.id)
		if parent.is_in_group("potato"):
				parent.queue_free()
		else:
			var papas = get_tree().get_nodes_in_group("potato")
<<<<<<< HEAD
			if papas.size()!=0:
=======
			if papas.size()>0:
>>>>>>> problemas_papas2
				for papa in papas:
					papa.queue_free()		
				
