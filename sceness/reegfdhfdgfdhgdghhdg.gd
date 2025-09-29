extends CharacterBody2D

# Exported variables for movement
@export var speed: float = 200.0
@export var gravity: float = 1000.0
@export var jump_force: float = -500.0

# References
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# State variables
var is_attacking: bool = false

func _physics_process(delta):
	handle_input(delta)
	move_and_slide()

func handle_input(delta):
	var move_input = Input.get_axis("ui_left", "ui_right")
	
	# Horizontal movement
	velocity.x = move_input * speed
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Play running animation
	if is_on_floor():
		if move_input != 0:
			play_animation("running")
		else:
			play_animation("idle")
	
	# Jumping
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_force
		play_animation("jump")
	
	# Crouching
	if Input.is_action_pressed("ui_down") and is_on_floor():
		play_animation("crouch")
		velocity.x = 0  # Stop moving while crouching
	
	# Attack
	if Input.is_action_just_pressed("attack"):  # Changed to action for better input handling
		play_animation("attack")
		is_attacking = true

func play_animation(anim_name: String):
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
