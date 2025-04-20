# PlatformManager.gd
class_name PlatformManager
extends Node2D

var platforms: Array = []
var down_jump_zones: = []
var down_jump_max_dist = 300.0 # valid maximum down jump distance

func _ready():
	
	print("Scene loaded")
	
	# Add test platforms
	add_platform(Vector2(-300, 300), Vector2(0, 300))   # Flat
	add_platform(Vector2(-300, 100), Vector2(500, 100))   # Flat
	add_platform(Vector2(100, 290), Vector2(500, 290))   # Flat
	add_platform(Vector2(150, 300), Vector2(5000, 300))   # Flat
	add_platform(Vector2(550, 300), Vector2(750, 250))   # Slope up
	add_platform(Vector2(800, 250), Vector2(1000, 300))  # Slope down
	
	for platform in platforms:
		print("Platform: p1 =", platform.p1, "| p2 =", platform.p2)
		if is_equal_approx(platform.p1.x, platform.p2.x):
			print("🚨 BAD VERTICAL PLATFORM FOUND")

	
	# Add down jump zones
	compute_down_jump_zones(down_jump_max_dist)

func add_platform(p1: Vector2, p2: Vector2, drop_through := true):
	var platform = Platform.new(p1, p2, drop_through)
	platforms.append(platform)
	queue_redraw()

func get_platform_below(x: float, y: float, max_dist: float, ignored: Platform = null) -> Platform:
	var vertical_start = Vector2(x, y)
	var vertical_end = Vector2(x, y + max_dist)
	var closest: Platform = null
	var closest_y := INF

	for platform in platforms:
		if platform == ignored:
			continue

		var hit_point = platform.segment_intersects_vertical(x, y, y + max_dist)
		if hit_point and hit_point.y < closest_y:
			closest = platform
			closest_y = hit_point.y

	return closest

func compute_down_jump_zones(max_dist: float):
	down_jump_zones.clear()

	# Sort platforms by min y-value once
	var sorted_platforms = platforms.duplicate()
	sorted_platforms.sort_custom(func(a, b):
		return min(a.p1.y, a.p2.y) < min(b.p1.y, b.p2.y)
	)

	for i in range(sorted_platforms.size()):
		var upper = sorted_platforms[i]
		var upper_min_y = min(upper.p1.y, upper.p2.y)
		var upper_max_y = max(upper.p1.y, upper.p2.y)

		for j in range(i + 1, sorted_platforms.size()):
			var lower = sorted_platforms[j]

			var lower_min_y = min(lower.p1.y, lower.p2.y)
			if lower_min_y > upper_max_y + max_dist:
				break  # Optimization: no need to check further

			# Check horizontal overlap
			var overlap_start_x = max(min(upper.p1.x, upper.p2.x), min(lower.p1.x, lower.p2.x))
			var overlap_end_x = min(max(upper.p1.x, upper.p2.x), max(lower.p1.x, lower.p2.x))

			if overlap_start_x >= overlap_end_x:
				continue

			# Step through the overlap range to detect valid down-jump zones
			var step_size = 4.0
			var valid_start: Vector2 = Vector2.ZERO
			var in_valid_zone = false

			var x = overlap_start_x
			while x < overlap_end_x:
				var upper_y = upper.get_y_at_x(x)
				var lower_y = lower.get_y_at_x(x)

				if lower_y - upper_y <= max_dist:
					if not in_valid_zone:
						valid_start = Vector2(x, upper_y)
						in_valid_zone = true
				else:
					if in_valid_zone:
						down_jump_zones.append([
							valid_start,
							Vector2(x, valid_start.y)
						])
						in_valid_zone = false
				x += step_size

			# If still in valid zone at the end
			if in_valid_zone:
				down_jump_zones.append([
					valid_start,
					Vector2(overlap_end_x, valid_start.y)
				])
			
func can_down_jump_at(pos: Vector2, tolerance := 6.0) -> bool:
	for segment in down_jump_zones:
		var start_x = min(segment[0].x, segment[1].x)
		var end_x = max(segment[0].x, segment[1].x)
		var y = segment[0].y  # All segments are horizontal

		if abs(pos.y - y) <= tolerance and pos.x >= start_x and pos.x <= end_x:
			return true
	return false
	
func _draw() -> void:
	for platform in platforms:
		draw_line(platform.p1, platform.p2, Color.YELLOW, 2)

	# Draw all down-jump zones as lines between Vector2 pairs
	for segment in down_jump_zones:
		var p1 = segment[0]
		var p2 = segment[1]
		draw_line(p1, p2, Color.CYAN, 2)

func _process(_delta):
	queue_redraw()
