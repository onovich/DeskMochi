extends RefCounted

const DRAG_SMOOTHING := 24.0
const VELOCITY_DAMPING := 7.5
const POKE_DECAY := 8.0
const MIN_SPEED := 8.0
const CENTERING_SMOOTHING := 12.0
const EDGE_MARGIN := 100.0
const GRAVITY := 1850.0
const FLOOR_BOUNCE := 0.36
const FLOOR_FRICTION := 0.82
const SETTLE_CENTERING_SMOOTHING := 22.0
const POKE_RING_COLOR := Color(1.0, 0.42, 0.58, 0.62)
const DRAG_RING_COLOR := Color(0.38, 0.72, 1.0, 0.55)
const BOUNCE_RING_COLOR := Color(1.0, 0.62, 0.72, 0.45)
const SPARK_COLOR := Color(1.0, 0.94, 0.56, 0.82)


func step(state, input_frame, delta: float, viewport_rect: Rect2) -> void:
	if delta <= 0.0:
		return

	state.elapsed += delta
	state.window_delta = Vector2.ZERO
	var pointer_inside := _is_pointer_inside(state, input_frame.mouse_position)

	if input_frame.left_pressed and pointer_inside:
		state.mode = &"dragged"
		state.drag_offset = state.position - input_frame.mouse_position
		state.press_duration = 0.0
		state.press_screen_position = input_frame.screen_mouse_position
		state.poke_point = input_frame.mouse_position
		state.poke_strength = 1.0
		_emit_poke_feedback(state, input_frame.mouse_position)
		state.emit_ring(input_frame.mouse_position, DRAG_RING_COLOR, 14.0, 48.0, 0.32)

	if state.mode == &"dragged" and input_frame.left_down:
		state.press_duration += delta
		state.window_delta = input_frame.screen_mouse_delta
		var target: Vector2 = viewport_rect.size * 0.5 + state.drag_offset * 0.12
		var previous_position: Vector2 = state.position
		var t: float = 1.0 - exp(-DRAG_SMOOTHING * delta)
		state.position = previous_position.lerp(target, t)
		state.velocity = input_frame.screen_mouse_delta / delta
	elif input_frame.left_released and state.mode == &"dragged":
		state.mode = &"idle"
		state.velocity = Vector2.ZERO
	elif input_frame.left_released and state.mode == &"poked":
		state.mode = &"settled"
		state.velocity = Vector2.ZERO
	else:
		_integrate_free_motion(state, delta, viewport_rect)

	state.poke_strength = maxf(0.0, state.poke_strength - POKE_DECAY * delta)
	_keep_inside_viewport(state, viewport_rect, delta)
	_update_stretch(state)
	_update_contour(state, delta)
	_update_visual_effects(state, delta)


func _is_pointer_inside(state, point: Vector2) -> bool:
	var local: Vector2 = point - state.position
	var normalized: Vector2 = Vector2(
		local.x / maxf(state.radius.x, 1.0),
		local.y / maxf(state.radius.y, 1.0)
	)
	return normalized.length_squared() <= 1.1


func _keep_inside_viewport(state, viewport_rect: Rect2, delta: float) -> void:
	var min_position: Vector2 = Vector2(EDGE_MARGIN, state.radius.y + 20.0)
	var max_position: Vector2 = Vector2(viewport_rect.size.x - EDGE_MARGIN, _floor_y(state, viewport_rect))
	state.position = state.position.clamp(min_position, max_position)

	if state.mode == &"idle" or state.mode == &"settled":
		var center: Vector2 = viewport_rect.size * 0.5
		center.y = minf(center.y, _floor_y(state, viewport_rect))
		var smoothing := SETTLE_CENTERING_SMOOTHING if state.mode == &"settled" else CENTERING_SMOOTHING
		var t: float = 1.0 - exp(-smoothing * delta)
		state.position = state.position.lerp(center, t)
		if state.mode == &"settled" and state.position.distance_to(center) < 8.0:
			state.mode = &"idle"


func _integrate_free_motion(state, delta: float, viewport_rect: Rect2) -> void:
	if state.mode == &"falling":
		state.velocity.y += GRAVITY * delta

	state.position += state.velocity * delta
	var damping: float = 1.0 - exp(-VELOCITY_DAMPING * delta)
	state.velocity.x = lerpf(state.velocity.x, 0.0, damping)

	var floor_y: float = _floor_y(state, viewport_rect)
	if state.position.y >= floor_y:
		state.position.y = floor_y
		if state.velocity.y > 72.0:
			state.velocity.y = -state.velocity.y * FLOOR_BOUNCE
			state.velocity.x *= FLOOR_FRICTION
			state.poke_strength = maxf(state.poke_strength, 0.55)
			state.poke_point = state.position + Vector2(0.0, state.radius.y)
			_emit_bounce_feedback(state)
		else:
			state.velocity.y = 0.0
			if state.mode == &"falling":
				state.mode = &"settled"
	else:
		state.velocity.y = lerpf(state.velocity.y, 0.0, damping * 0.18)

	if state.mode != &"dragged" and state.mode != &"falling" and state.velocity.length() < MIN_SPEED:
		state.mode = &"idle"


func _floor_y(state, viewport_rect: Rect2) -> float:
	return viewport_rect.size.y - state.radius.y - 18.0


func _update_stretch(state) -> void:
	var speed: float = clampf(state.velocity.length() / 1200.0, 0.0, 1.0)
	var direction: Vector2 = state.velocity.normalized() if state.velocity.length() > 0.001 else Vector2.RIGHT
	var x_bias: float = absf(direction.x)
	var y_bias: float = absf(direction.y)
	state.stretch = Vector2(
		1.0 + speed * 0.20 * x_bias - speed * 0.08 * y_bias,
		1.0 + speed * 0.20 * y_bias - speed * 0.08 * x_bias
	)


func _update_contour(state, delta: float) -> void:
	if state.contour_directions.is_empty():
		state.initialize_contour()

	var speed: float = minf(state.velocity.length(), 1600.0)
	var velocity_dir: Vector2 = state.velocity.normalized() if speed > 0.001 else Vector2.ZERO
	var poke_dir: Vector2 = (state.poke_point - state.position).normalized() if state.poke_strength > 0.0 else Vector2.ZERO

	for index in state.contour_directions.size():
		var dir: Vector2 = state.contour_directions[index]
		var target_offset := 0.0

		if velocity_dir != Vector2.ZERO:
			var leading: float = maxf(dir.dot(velocity_dir), 0.0)
			var trailing: float = maxf(dir.dot(-velocity_dir), 0.0)
			target_offset += trailing * speed * state.inertia_strength
			target_offset -= leading * speed * state.inertia_strength * 0.55

		if poke_dir != Vector2.ZERO:
			var poke_influence: float = pow(maxf(dir.dot(poke_dir), 0.0), 8.0)
			target_offset -= poke_influence * state.poke_strength * state.poke_depth

		var displacement: float = state.contour_offsets[index] - target_offset
		var acceleration: float = -displacement * state.spring_strength - state.contour_velocities[index] * state.damping
		state.contour_velocities[index] += acceleration * delta
		state.contour_offsets[index] += state.contour_velocities[index] * delta


func _emit_poke_feedback(state, origin: Vector2) -> void:
	if state.focus_mode:
		state.emit_ring(origin, POKE_RING_COLOR.darkened(0.08), 8.0, 24.0, 0.22)
		return

	state.emit_ring(origin, POKE_RING_COLOR, 10.0, 38.0, 0.28)
	for index in 5:
		var angle: float = -PI * 0.72 + float(index) * PI * 0.36
		var speed: float = 80.0 + float(index % 2) * 36.0
		state.emit_spark(origin, Vector2(cos(angle), sin(angle)) * speed, SPARK_COLOR, 4.5, 0.42)


func _emit_bounce_feedback(state) -> void:
	var origin: Vector2 = state.position + Vector2(0.0, state.radius.y * 0.78)
	if state.focus_mode:
		state.emit_ring(origin, BOUNCE_RING_COLOR.darkened(0.08), 14.0, 36.0, 0.28)
		return

	state.emit_ring(origin, BOUNCE_RING_COLOR, 18.0, 58.0, 0.34)
	for index in 7:
		var angle: float = -PI + float(index) * PI / 6.0
		var speed: float = 44.0 + absf(3.0 - float(index)) * 11.0
		state.emit_spark(origin, Vector2(cos(angle), -absf(sin(angle))) * speed, SPARK_COLOR, 3.8, 0.36)


func _update_visual_effects(state, delta: float) -> void:
	for index in range(state.visual_effects.size() - 1, -1, -1):
		var effect: Dictionary = state.visual_effects[index]
		effect["age"] = float(effect["age"]) + delta
		if effect["type"] == &"spark":
			effect["origin"] = effect["origin"] + effect["velocity"] * delta
			effect["velocity"] = effect["velocity"] + Vector2(0.0, 220.0) * delta
		state.visual_effects[index] = effect
		if float(effect["age"]) >= float(effect["duration"]):
			state.visual_effects.remove_at(index)
