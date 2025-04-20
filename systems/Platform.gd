# Platform.gd
class_name Platform
extends Node2D

var p1: Vector2
var p2: Vector2
var is_drop_through: bool = true

func _init(p1: Vector2, p2: Vector2, drop_through := true) -> void:
	self.p1 = p1
	self.p2 = p2
	self.is_drop_through = drop_through

func get_y_at_x(x: float) -> float:
	var dx = p2.x - p1.x
	if is_equal_approx(dx, 0.0):
		push_error("🚨 Invalid platform segment with zero width: p1=%s p2=%s" % [str(p1), str(p2)])
		return p1.y  # Fallback to avoid returning INF or crashing

	var t = clamp((x - p1.x) / dx, 0.0, 1.0)
	var y = lerp(p1.y, p2.y, t)
	if is_inf(y) or is_nan(y):
		push_error("🚨 Lerp calculation invalid! x=%f t=%f y=%f | p1=%s p2=%s" % [x, t, y, str(p1), str(p2)])
		return p1.y  # Safe fallback again

	return y


func segment_intersects_vertical(x: float, y_start: float, y_end: float):
	var vertical_a := Vector2(x, y_start)
	var vertical_b := Vector2(x, y_end)

	if is_equal_approx(p1.x, p2.x) and is_equal_approx(p1.y, p2.y):
		push_error("🚨 Invalid platform segment (zero-length): %s to %s" % [str(p1), str(p2)])
		return null

	var result = Geometry2D.segment_intersects_segment(p1, p2, vertical_a, vertical_b)

	if result == null:
		return null
	if is_inf(result.x) or is_inf(result.y) or is_nan(result.x) or is_nan(result.y):
		push_error("🚨 Invalid intersection result: %s" % [str(result)])
		return null

	return result
