extends Sprite 

export(Texture) var gear_texture : Texture setget set_gear_texture
export(float) var rotation_speed = 90.0
export(bool) var rotate_clockwise = true
export(float) var active_duration = 2.0
export(float) var pause_duration = 1.0
export(bool) var start_active = true
export(bool) var continuous = false
export(Vector2) var pivot_offset = Vector2.ZERO  

var current_time = 0.0
var is_active = true
var direction_multiplier = 1
var original_offset = Vector2.ZERO

func _ready():
	if gear_texture:
		self.texture = gear_texture
		self.centered = true
	
	original_offset = self.offset
	
	if pivot_offset != Vector2.ZERO:
		self.offset = pivot_offset
	
	direction_multiplier = 1 if rotate_clockwise else -1
	
	is_active = start_active
	if not start_active:
		current_time = active_duration
	
	if continuous:
		active_duration = 999999
		pause_duration = 0

func _process(delta):
	current_time += delta
	
	if not continuous:
		if is_active and current_time >= active_duration:
			is_active = false
			current_time = 0
		elif not is_active and current_time >= pause_duration:
			is_active = true
			current_time = 0
	
	if is_active or continuous:
		var rotation_amount = deg2rad(rotation_speed * direction_multiplier * delta)
		self.rotation += rotation_amount

func set_gear_texture(new_texture: Texture) -> void:
	gear_texture = new_texture
	self.texture = new_texture
	if new_texture:
		self.centered = true

func set_pivot_offset(offset: Vector2) -> void:
	pivot_offset = offset
	self.offset = offset
	
func reset_pivot() -> void:
	pivot_offset = Vector2.ZERO
	self.offset = original_offset
	self.centered = true
