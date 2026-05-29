extends RefCounted

var position := Vector2.ZERO
var velocity := Vector2.ZERO
var radius := Vector2(86.0, 62.0)
var mode := &"idle"
var drag_offset := Vector2.ZERO
var poke_point := Vector2.ZERO
var poke_strength := 0.0
var stretch := Vector2.ONE
var elapsed := 0.0
var window_delta := Vector2.ZERO
var press_duration := 0.0
var press_screen_position := Vector2.ZERO
var visual_effects: Array[Dictionary] = []
var contour_directions: Array[Vector2] = []
var contour_offsets: Array[float] = []
var contour_velocities: Array[float] = []
var spring_strength := 78.0
var damping := 14.0
var poke_depth := 34.0
var inertia_strength := 0.030
var tuning_preset := &"balanced"
var focus_mode := false


func initialize_contour(count: int = 40) -> void:
	contour_directions.clear()
	contour_offsets.clear()
	contour_velocities.clear()

	for index in count:
		var angle: float = TAU * float(index) / float(count)
		contour_directions.append(Vector2(cos(angle), sin(angle)))
		contour_offsets.append(0.0)
		contour_velocities.append(0.0)


func get_contour_points(expansion: float = 0.0) -> PackedVector2Array:
	if contour_directions.is_empty():
		initialize_contour()

	var points := PackedVector2Array()
	var pulse_speed := 1.4 if focus_mode else 2.6
	var pulse_amount := 0.006 if focus_mode else 0.018
	var pulse: float = sin(elapsed * pulse_speed) * pulse_amount
	var base_radius := Vector2(
		radius.x * stretch.x * (1.0 + pulse),
		radius.y * stretch.y * (1.0 - pulse * 0.5)
	)

	for index in contour_directions.size():
		var dir: Vector2 = contour_directions[index]
		var offset: float = contour_offsets[index] + expansion
		var point := Vector2(
			dir.x * (base_radius.x + offset),
			dir.y * (base_radius.y + offset)
		)
		points.append(point)

	return points


func get_local_anchor(normalized_position: Vector2, motion_follow: float = 0.12) -> Vector2:
	var lean := Vector2.ZERO
	if velocity.length() > 0.001:
		lean = velocity.normalized() * minf(velocity.length() * motion_follow, 14.0)

	return position + Vector2(
		normalized_position.x * radius.x * stretch.x,
		normalized_position.y * radius.y * stretch.y
	) + lean


func get_surface_anchor(direction: Vector2, expansion: float = 0.0) -> Vector2:
	if contour_directions.is_empty():
		initialize_contour()

	var normalized_direction := direction.normalized()
	var best_index := 0
	var best_dot := -2.0
	for index in contour_directions.size():
		var dot: float = contour_directions[index].dot(normalized_direction)
		if dot > best_dot:
			best_dot = dot
			best_index = index

	var dir: Vector2 = contour_directions[best_index]
	var offset: float = contour_offsets[best_index] + expansion
	return position + Vector2(
		dir.x * (radius.x * stretch.x + offset),
		dir.y * (radius.y * stretch.y + offset)
	)


func emit_ring(origin: Vector2, color: Color, radius_start: float, radius_end: float, duration: float) -> void:
	visual_effects.append({
		"type": &"ring",
		"origin": origin,
		"color": color,
		"radius_start": radius_start,
		"radius_end": radius_end,
		"duration": duration,
		"age": 0.0,
	})


func emit_spark(origin: Vector2, velocity_value: Vector2, color: Color, size: float, duration: float) -> void:
	visual_effects.append({
		"type": &"spark",
		"origin": origin,
		"velocity": velocity_value,
		"color": color,
		"size": size,
		"duration": duration,
		"age": 0.0,
	})


func apply_tuning_preset(preset: StringName) -> void:
	tuning_preset = preset
	if preset == &"soft":
		spring_strength = 58.0
		damping = 9.0
		poke_depth = 42.0
		inertia_strength = 0.040
	elif preset == &"snappy":
		spring_strength = 116.0
		damping = 21.0
		poke_depth = 28.0
		inertia_strength = 0.022
	else:
		tuning_preset = &"balanced"
		spring_strength = 78.0
		damping = 14.0
		poke_depth = 34.0
		inertia_strength = 0.030
