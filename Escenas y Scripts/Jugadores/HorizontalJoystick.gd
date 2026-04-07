extends Control

# Señales
signal moved(direction)
signal released

# Variables
var touch_index = -1
var is_active = false
var dead_zone = 50.0
var center_x = 0.0
var current_direction = 0

# Exportar para ajustar fácilmente
export var is_left_side = true  # True para lado izquierdo, False para derecho

func _ready():
	# Configurar tamaño y posición
	rect_min_size = Vector2(300, 150)
	rect_size = rect_min_size
	
	# Posicionar en el lado correspondiente de la pantalla
	if is_left_side:
		rect_position = Vector2(50, get_viewport_rect().size.y - 200)
	else:
		rect_position = Vector2(get_viewport_rect().size.x - 350, get_viewport_rect().size.y - 200)
	
	center_x = rect_size.x / 2
	
	# Hacer que el joystick sea transparente pero clickeable
	modulate = Color(1, 1, 1, 0.7)

func _input(event):
	# Solo procesar eventos táctiles
	if event is InputEventScreenTouch:
		var local_pos = get_local_mouse_position()
		
		if event.pressed:
			# Verificar si el toque está dentro del área del joystick
			if Rect2(Vector2.ZERO, rect_size).has_point(local_pos):
				touch_index = event.index
				is_active = true
				update_joystick(local_pos.x)
				get_tree().set_input_as_handled()  # Marcar como procesado
		
		elif event.index == touch_index and not event.pressed:
			release_joystick()
			get_tree().set_input_as_handled()
	
	elif event is InputEventScreenDrag and event.index == touch_index and is_active:
		update_joystick(get_local_mouse_position().x)
		get_tree().set_input_as_handled()

func update_joystick(x_pos):
	var relative_x = x_pos - center_x
	
	# Determinar dirección con zona muerta
	var new_direction = 0
	if abs(relative_x) > dead_zone:
		new_direction = 1 if relative_x > 0 else -1
	
	# Solo emitir si cambia la dirección
	if new_direction != current_direction:
		current_direction = new_direction
		emit_signal("moved", current_direction)
	
	# Mover el handle visualmente
	if has_node("Handle"):
		var handle = $Handle
		var max_move = (rect_size.x - handle.rect_size.x) / 2
		
		if new_direction != 0:
			handle.rect_position.x = center_x - handle.rect_size.x/2 + (relative_x * 0.3)
			handle.rect_position.x = clamp(handle.rect_position.x, 0, rect_size.x - handle.rect_size.x)

func release_joystick():
	touch_index = -1
	is_active = false
	
	# Resetear handle visual
	if has_node("Handle"):
		$Handle.rect_position = Vector2(
			center_x - $Handle.rect_size.x/2,
			rect_size.y/2 - $Handle.rect_size.y/2
		)
	
	if current_direction != 0:
		current_direction = 0
		emit_signal("released")
		emit_signal("moved", 0)

# Para debug en editor
func _process(delta):
	if OS.has_feature("editor"):
		if Input.is_action_pressed("move_left"):
			emit_signal("moved", -1)
		elif Input.is_action_pressed("move_right"):
			emit_signal("moved", 1)
		elif Input.is_action_just_released("move_left") or Input.is_action_just_released("move_right"):
			emit_signal("released")
