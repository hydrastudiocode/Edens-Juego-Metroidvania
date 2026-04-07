extends KinematicBody2D

const FLOOR_DETECT_DISTANCE = 20.0
const FLOOR_NORMAL = Vector2.UP
const WALL_JUMP_FORCE_X = 300.0
const WALL_JUMP_FORCE_Y = -400.0
const AIR_ACCELERATION = 0.15
const AIR_DECELERATION = 0.1

export(String) var action_suffix = ""
export(float) var move_speed = 350.0
export(float) var jump_force = -500.0
export(float) var gravity = 800.0
export(float) var jump_cut_multiplier = 0.5
export(float) var wall_slide_speed = 200.0
export(float) var wall_stick_time = 0.15
export(int) var max_air_jumps = 10
export(float) var coyote_time = 0.1
export(float) var jump_buffer_time = 0.15
export(float) var ground_acceleration = 0.2
export(float) var ground_deceleration = 0.25

var velocity = Vector2()
var snap_vector = Vector2.ZERO
var is_on_platform = false

var is_wall_sliding = false
var wall_direction = 0
var wall_stick_timer = 0.0
var can_wall_jump = false
var wall_jump_cooldown = 0.0

var air_jumps_remaining = 0
var can_air_jump = true

var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var last_floor_time = 0.0
var is_jumping = false

onready var platform_detector = $PlatformDetector
onready var wall_detector_left = $Derecha
onready var wall_detector_right = $Izquierda

onready var sprite_caminar = $caminar
onready var sprite_fijo = $fijo
onready var sprite_caer = $caer
onready var sprite_wall_slide = $fijo

var current_animation_sprite = null
var last_direction = 1 
var is_facing_wall = false
var input_direction = 0
var target_velocity_x = 0.0

func _ready():
	setup_animated_sprites()
	switch_animation_sprite(sprite_fijo, "default")
	snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE
	air_jumps_remaining = max_air_jumps

	sprite_fijo.scale.x = last_direction

func setup_animated_sprites():
	sprite_caminar.visible = false
	sprite_fijo.visible = false
	sprite_caer.visible = false

func switch_animation_sprite(new_sprite, animation_name = ""):
	if current_animation_sprite and current_animation_sprite != new_sprite:
		current_animation_sprite.visible = false
		current_animation_sprite.playing = false
	
	new_sprite.visible = true
	if animation_name != "" and new_sprite.frames and new_sprite.frames.has_animation(animation_name):
		new_sprite.animation = animation_name
	
	new_sprite.playing = true
	current_animation_sprite = new_sprite

	if new_sprite:
		new_sprite.scale.x = last_direction

func _physics_process(delta):

	input_direction = Input.get_action_strength("move_right" + action_suffix) - Input.get_action_strength("move_left" + action_suffix)
	update_timers(delta)
	update_direction()
	detect_walls()
	apply_gravity(delta)
	handle_horizontal_movement(delta)
	handle_jumps()
	handle_wall_sliding(delta)
	move_character(delta)
	update_animation()

func update_direction():
	if input_direction != 0 and not (is_wall_sliding and is_facing_wall) and wall_jump_cooldown <= 0:
		last_direction = 1 if input_direction > 0 else -1

	if current_animation_sprite:
		if is_wall_sliding and is_facing_wall and current_animation_sprite == sprite_wall_slide:
			current_animation_sprite.scale.x = -wall_direction
		else:
			current_animation_sprite.scale.x = last_direction

func update_timers(delta):
	if is_on_floor():
		last_floor_time = 0.0
		is_jumping = false
	else:
		last_floor_time += delta
	
	if Input.is_action_just_pressed("jump" + action_suffix):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	
	if wall_jump_cooldown > 0:
		wall_jump_cooldown = max(0.0, wall_jump_cooldown - delta)

func detect_walls():
	var was_wall_sliding = is_wall_sliding
	is_wall_sliding = false
	wall_direction = 0
	
	if wall_detector_left and wall_detector_left.is_colliding():
		wall_direction = 1
		is_wall_sliding = true
		is_facing_wall = input_direction > 0
	elif wall_detector_right and wall_detector_right.is_colliding():
		wall_direction = -1
		is_wall_sliding = true
		is_facing_wall = input_direction < 0
	
	if is_wall_sliding and not was_wall_sliding:
		can_wall_jump = true
		wall_stick_timer = 0.0
	elif was_wall_sliding and not is_wall_sliding:
		wall_stick_timer = 0.0

func apply_gravity(delta):
	if not is_on_floor() and not is_wall_sliding:
		velocity.y += gravity * delta
	elif is_wall_sliding and velocity.y > 0:
		velocity.y += gravity * delta * 0.4

func handle_horizontal_movement(delta):
	if is_on_floor():
		if input_direction != 0:
			target_velocity_x = input_direction * move_speed
			velocity.x = lerp(velocity.x, target_velocity_x, ground_acceleration)
		else:
			velocity.x = lerp(velocity.x, 0, ground_deceleration)
	else:
		if input_direction != 0:
			target_velocity_x = input_direction * move_speed
			var acceleration = AIR_ACCELERATION if sign(velocity.x) == sign(input_direction) else AIR_DECELERATION
			velocity.x = lerp(velocity.x, target_velocity_x, acceleration)
		else:
			velocity.x = lerp(velocity.x, 0, AIR_DECELERATION)
	
	velocity.x = clamp(velocity.x, -move_speed * 1.5, move_speed * 1.5)

func handle_jumps():
	if is_on_floor():
		air_jumps_remaining = max_air_jumps
		can_air_jump = true
		is_jumping = false
	
	var can_jump_from_ground = is_on_floor() or last_floor_time < coyote_time
	
	if Input.is_action_just_pressed("jump" + action_suffix) and is_wall_sliding and can_wall_jump and wall_jump_cooldown <= 0:
		execute_wall_jump()
		return

	if (Input.is_action_just_pressed("jump" + action_suffix) or jump_buffer_timer > 0) and can_jump_from_ground and not is_jumping:
		execute_ground_jump()
		jump_buffer_timer = 0.0
	
	elif Input.is_action_just_pressed("jump" + action_suffix) and not is_on_floor() and not is_wall_sliding:
		if air_jumps_remaining > 0 and can_air_jump:
			execute_air_jump()

func execute_wall_jump():
	velocity.x = -wall_direction * WALL_JUMP_FORCE_X
	velocity.y = WALL_JUMP_FORCE_Y
	can_wall_jump = false
	is_wall_sliding = false
	air_jumps_remaining = max_air_jumps
	wall_jump_cooldown = 0.2
	is_jumping = true
	wall_stick_timer = 0.0
	last_direction = -wall_direction
	snap_vector = Vector2.ZERO

func execute_ground_jump():
	velocity.y = jump_force
	is_jumping = true
	air_jumps_remaining = max_air_jumps
	snap_vector = Vector2.ZERO

func execute_air_jump():
	var jump_strength = jump_force * (0.9 - (max_air_jumps - air_jumps_remaining) * 0.1)
	velocity.y = jump_strength
	air_jumps_remaining -= 1
	can_air_jump = false
	is_jumping = true
	snap_vector = Vector2.ZERO
	
	yield(get_tree().create_timer(0.1), "timeout")
	can_air_jump = true

func handle_wall_sliding(delta):
	if is_wall_sliding and not is_on_floor() and velocity.y >= 0 and is_facing_wall:
		if wall_stick_timer < wall_stick_time:
			wall_stick_timer += delta
			velocity.y = 0
		else:
			velocity.y = min(velocity.y, wall_slide_speed)
			if is_facing_wall:
				velocity.x = lerp(velocity.x, 0, 0.3)
	else:
		wall_stick_timer = 0.0

func move_character(delta):
	if Input.is_action_just_released("jump" + action_suffix) and velocity.y < 0:
		velocity.y *= jump_cut_multiplier
	
	if is_on_floor() and not is_jumping:
		snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE
	else:
		snap_vector = Vector2.ZERO
	
	velocity = move_and_slide_with_snap(
		velocity, 
		snap_vector, 
		FLOOR_NORMAL, 
		true,
		4,
		deg2rad(46),
		false
	)

func update_animation():
	if not sprite_caminar or not sprite_fijo or not sprite_caer:
		return
	
	if is_wall_sliding and is_facing_wall and not is_on_floor():
		if sprite_wall_slide:
			if current_animation_sprite != sprite_wall_slide:
				switch_animation_sprite(sprite_wall_slide)
			sprite_wall_slide.scale.x = -wall_direction
		return
	
	if is_on_floor():
		if abs(velocity.x) > 10.0:
			if current_animation_sprite != sprite_caminar:
				switch_animation_sprite(sprite_caminar)
		else:
			if current_animation_sprite != sprite_fijo:
				switch_animation_sprite(sprite_fijo)
	else:
		if velocity.y > 50.0:
			if current_animation_sprite != sprite_caer:
				switch_animation_sprite(sprite_caer)
		else:
			if current_animation_sprite != sprite_fijo:
				switch_animation_sprite(sprite_fijo)

func set_direction(direction):
	if direction != 0:
		last_direction = 1 if direction > 0 else -1
		if current_animation_sprite:
			current_animation_sprite.scale.x = last_direction
