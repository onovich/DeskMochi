extends Node2D

const BODY_COLOR := Color(1.0, 0.73, 0.80, 0.94)
const BODY_EDGE := Color(0.96, 0.47, 0.62, 0.92)
const CHEEK_COLOR := Color(1.0, 0.50, 0.62, 0.30)
const FACE_COLOR := Color(0.22, 0.12, 0.16, 0.92)
const SHADOW_COLOR := Color(0.15, 0.11, 0.12, 0.20)
const PASSTHROUGH_DEBUG_COLOR := Color(0.2, 0.65, 1.0, 0.58)

var state
var slot_state
var show_debug_overlay := false
var _head_texture: Texture2D
var _face_texture: Texture2D
var _loaded_head_path := ""
var _loaded_face_path := ""


func _draw() -> void:
	if state == null:
		return

	var body_points: PackedVector2Array = state.get_contour_points()
	var draw_points := PackedVector2Array()
	for point in body_points:
		draw_points.append(state.position + point)

	draw_set_transform(Vector2.ZERO)
	_draw_flat_ellipse(state.position + Vector2(0.0, state.radius.y * 0.72), Vector2(state.radius.x * 0.72, 10.0), SHADOW_COLOR)
	_draw_effects(false)
	draw_colored_polygon(draw_points, BODY_COLOR)

	var outline := PackedVector2Array(draw_points)
	outline.append(draw_points[0])
	draw_polyline(outline, BODY_EDGE, 3.0, true)
	_draw_passthrough_debug()

	_draw_face()
	_draw_slots()
	_draw_effects(true)


func get_passthrough_polygon() -> PackedVector2Array:
	if state == null:
		return PackedVector2Array()

	var points := PackedVector2Array()
	for point in state.get_contour_points(8.0):
		points.append(state.position + point)
	return points


func _draw_face() -> void:
	var left_eye: Vector2 = state.get_local_anchor(Vector2(-0.30, -0.16))
	var right_eye: Vector2 = state.get_local_anchor(Vector2(0.30, -0.16))
	var mouth: Vector2 = state.get_local_anchor(Vector2(0.0, 0.12), 0.08)
	var left_cheek: Vector2 = state.get_local_anchor(Vector2(-0.48, 0.08), 0.08)
	var right_cheek: Vector2 = state.get_local_anchor(Vector2(0.48, 0.08), 0.08)
	var eye_radius: float = 6.0 * clampf((state.stretch.x + state.stretch.y) * 0.5, 0.86, 1.16)
	var cheek_radius: float = 13.0 * clampf(state.stretch.x, 0.88, 1.18)
	var mouth_radius: float = 14.0 * clampf(state.stretch.x, 0.86, 1.18)

	if state.focus_mode:
		draw_line(left_eye + Vector2(-8.0, 0.0), left_eye + Vector2(8.0, 0.0), FACE_COLOR, 3.0, true)
		draw_line(right_eye + Vector2(-8.0, 0.0), right_eye + Vector2(8.0, 0.0), FACE_COLOR, 3.0, true)
	else:
		draw_circle(left_eye, eye_radius, FACE_COLOR)
		draw_circle(right_eye, eye_radius, FACE_COLOR)
	draw_arc(mouth, mouth_radius, 0.18 * PI, 0.82 * PI, 20, FACE_COLOR, 3.0, true)
	draw_circle(left_cheek, cheek_radius, CHEEK_COLOR)
	draw_circle(right_cheek, cheek_radius, CHEEK_COLOR)

	if state.mode == &"dragged":
		var top_anchor: Vector2 = state.get_surface_anchor(Vector2.UP, 5.0)
		draw_line(top_anchor + Vector2(-12.0, -8.0), top_anchor + Vector2(12.0, -8.0), BODY_EDGE, 3.0, true)


func _draw_slots() -> void:
	if slot_state == null:
		return

	_refresh_slot_textures()
	if _face_texture != null:
		var face_center: Vector2 = state.get_local_anchor(Vector2(0.0, -0.02), 0.04)
		_draw_texture_fit(_face_texture, face_center, Vector2(90.0, 52.0), Color(1, 1, 1, 0.96))

	if _head_texture != null:
		var head_center: Vector2 = state.get_surface_anchor(Vector2.UP, 10.0) + Vector2(0.0, -30.0)
		_draw_texture_fit(_head_texture, head_center, Vector2(112.0, 72.0), Color(1, 1, 1, 0.98))


func _refresh_slot_textures() -> void:
	var head_path: String = slot_state.head_image_path
	if head_path != _loaded_head_path:
		_loaded_head_path = head_path
		_head_texture = _load_local_texture(head_path)

	var face_path: String = slot_state.face_image_path
	if face_path != _loaded_face_path:
		_loaded_face_path = face_path
		_face_texture = _load_local_texture(face_path)


func _load_local_texture(path: String) -> Texture2D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null

	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_warning("Could not load slot image: %s" % path)
		return null

	return ImageTexture.create_from_image(image)


func _draw_texture_fit(texture: Texture2D, center: Vector2, max_size: Vector2, modulate: Color) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var scale: float = minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
	var draw_size: Vector2 = texture_size * minf(scale, 1.0)
	draw_texture_rect(texture, Rect2(center - draw_size * 0.5, draw_size), false, modulate)


func _draw_passthrough_debug() -> void:
	if not show_debug_overlay:
		return

	var points := get_passthrough_polygon()
	if points.size() < 3:
		return

	points.append(points[0])
	draw_polyline(points, PASSTHROUGH_DEBUG_COLOR, 1.6, true)


func _draw_effects(foreground: bool) -> void:
	for effect in state.visual_effects:
		var type: StringName = effect["type"]
		if foreground and type != &"spark":
			continue
		if not foreground and type != &"ring":
			continue

		var age: float = float(effect["age"])
		var duration: float = maxf(float(effect["duration"]), 0.001)
		var t: float = clampf(age / duration, 0.0, 1.0)
		var color: Color = effect["color"]
		color.a *= 1.0 - t

		if type == &"ring":
			var radius: float = lerpf(float(effect["radius_start"]), float(effect["radius_end"]), t)
			draw_arc(effect["origin"], radius, 0.0, TAU, 48, color, 2.5, true)
		elif type == &"spark":
			var size: float = float(effect["size"]) * (1.0 - t * 0.45)
			_draw_star(effect["origin"], size, color)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 10:
		var angle: float = -PI * 0.5 + float(index) * TAU / 10.0
		var r: float = radius if index % 2 == 0 else radius * 0.42
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)


func _draw_flat_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 36:
		var angle: float = TAU * float(index) / 36.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
