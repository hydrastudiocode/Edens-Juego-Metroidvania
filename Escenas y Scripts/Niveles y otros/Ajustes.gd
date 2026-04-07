extends Node2D
#Nota Script para Establecer limites y que la camara tenga
#el efecto que lo deja de seguir al player
#El script esta adaptado para que puedas modificarlo desde el editor
#no usar variables fijas ni constantes asi se puede replicar en varios niveles
onready var Player = $Player
export var LimiteIzquierda = -185
export var LimiteArriba = -850
export var LimiteDerecha = 2855
export var LimiteAbajo = 590


func _ready():
	for child in get_children():
		if child is KinematicBody2D:
			var camera = child.get_node("Camera")
			camera.limit_left = LimiteIzquierda
			camera.limit_top = LimiteArriba
			camera.limit_right = LimiteDerecha
			camera.limit_bottom = LimiteAbajo
