extends Node2D

# === Constants ===
const GRAVITY = 1800.0
const JUMP_FORCE = -550.0
const SPEED = 150.0
const AIR_ACCEL = 100.0
const AIR_DEACCEL = 100.0
const ACCEL = 2000.0
const DEACCEL = 2000.0
const GROUND_CHECK_DIST = 300.0

# === State ===
var velocity: Vector2 = Vector2.ZERO
var is_grounded: bool = false
var is_prone: bool = false
var ignored_platform: Platform = null
var jump_held := Input.is_action_pressed("jump")

# === Nodes ===
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var platform_manager = $"../PlatformManager"

func _ready():
	print("Scene loaded")
	print("Player position:", global_position)

func _physics_process(delta: float) -> void:
	
	# === Input
	var input_dir := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var jump_held := Input.is_action_pressed("jump")
	var prone_input := Input.is_action_pressed("prone")
	var wants_down_jump = prone_input and Input.is_action_just_pressed("jump")
	

	# === Horizontal movement
	var accel: float
	var deaccel: float

	if is_grounded:
		accel = ACCEL
		deaccel = DEACCEL
	else:
		accel = AIR_ACCEL
		deaccel = AIR_DEACCEL

	if input_dir != 0:
		velocity.x = move_toward(velocity.x, input_dir * SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deaccel * delta)

	# === Handle Down-jump
	var down_jump_attempted := false
	var down_jump_successful := false

	if wants_down_jump and is_grounded:
		down_jump_attempted = true
		if platform_manager.can_down_jump_at(global_position):
			var current_platform = platform_manager.get_platform_below(global_position.x, global_position.y - 4.0, 4.0)
			if current_platform:
				ignored_platform = current_platform
				velocity.y = -200  # hop
				down_jump_successful = true
		else:
			print("down jump request rejected!")


	# === Platform detection
	# === Apply gravity BEFORE checking snap
	velocity.y += GRAVITY * delta
	var projected_y = global_position.y + velocity.y * delta

	# === Platform detection
	var platform = platform_manager.get_platform_below(
		global_position.x,
		global_position.y,
		GROUND_CHECK_DIST + 32.0,
		ignored_platform 
	)
	is_grounded = false

	if platform:
		var intersection = platform.segment_intersects_vertical(
			global_position.x,
			global_position.y,
			projected_y
		)

		if velocity.y >= 0 and intersection:
			global_position.y = intersection.y
			print("✅ Snapped to | global Y:", global_position.y, "projected_y:", projected_y, "| platform_y:", intersection.y)
			velocity.y = 0
			is_grounded = true
		else:
			global_position.y += velocity.y * delta
	else:
		global_position.y += velocity.y * delta



	# === Final horizontal position update
	global_position.x += velocity.x * delta
	
	# If still grounded and on a platform, re-align Y to slope
	if is_grounded and platform:
		global_position.y = platform.get_y_at_x(global_position.x)

	# === Restore ignored platform after falling below
	if ignored_platform:
		var ignored_y = ignored_platform.get_y_at_x(global_position.x)

		# ✅ You must be *falling*, and *well below* the ignored platform
		if velocity.y > 0 and global_position.y > ignored_y + 1.0:
			print("✅ Cleared ignored platform — below:", ignored_y)
			ignored_platform = null

	# === Jumping
	if is_grounded and jump_held and not is_prone:
		velocity.y = JUMP_FORCE
		is_grounded = false


	# === Prone Logic (after is_grounded is set!)
	if down_jump_attempted and not down_jump_successful:
		is_prone = true  # force staying prone after a failed down-jump
	else:
		is_prone = prone_input and is_grounded and input_dir == 0 and not Input.is_action_just_pressed("jump")



	# === Animations
	if is_prone:
		play_anim("prone")
	elif not is_grounded:
		play_anim("jump")
	elif input_dir != 0:
		play_anim("walk")
	else:
		play_anim("idle")

	# === Flip
	if input_dir != 0:
		anim.flip_h = input_dir > 0

func play_anim(name: String) -> void:
	if anim.animation != name:
		anim.play(name)
		
