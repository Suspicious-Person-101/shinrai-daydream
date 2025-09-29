extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0

# Animation variables
var is_attacking: bool = false
var is_crouching: bool = false
var is_damaged: bool = false
var is_special_attacking: bool = false

@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D  # Assuming you have a Sprite2D node

func _ready():
	# Make sure you have an AnimationPlayer node in your scene
	if not animation_player:
		push_error("AnimationPlayer node not found!")

func _physics_process(delta: float) -> void:
	# Skip movement if performing certain actions
	if is_attacking or is_damaged or is_special_attacking:
		move_and_slide()
		return
	
	# Add gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY
		play_animation("jump")

	# Handle crouch
	if Input.is_action_pressed("ui_down") and is_on_floor():
		is_crouching = true
		play_animation("crouch")
	elif is_crouching:
		is_crouching = false
	
	# Handle attack
	if Input.is_action_just_pressed("attack"):  # You'll need to set up this input action
		is_attacking = true
		play_animation("attack")
	
	# Handle special attack
	if Input.is_action_just_pressed("special_attack"):  # You'll need to set up this input action
		is_special_attacking = true
		play_animation("special")
	
	# Get the input direction and handle movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction and not is_crouching:
		velocity.x = direction * SPEED
		if is_on_floor() and not is_attacking and not is_special_attacking and not is_damaged:
			play_animation("running")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor() and not is_attacking and not is_special_attacking and not is_crouching and not is_damaged:
			play_animation("idle")
	
	# Flip sprite based on direction
	if direction != 0 and not is_attacking and not is_special_attacking:
		sprite.flip_h = direction < 0

	move_and_slide()
	
	# Handle landing from jump and animation transitions
	handle_animation_transitions()

func handle_animation_transitions():
	if is_damaged:
		play_animation("damaged")
		return
	
	if is_attacking:
		play_animation("attack")
		return
	
	if is_special_attacking:
		play_animation("special")
		return
	
	if is_crouching and is_on_floor():
		play_animation("crouch")
		return
	
	if not is_on_floor():
		if velocity.y < 0:
			play_animation("jump")
		else:
			play_animation("fall")  # You might want to add a fall animation
	elif velocity.x != 0:
		play_animation("running")
	else:
		play_animation("idle")

func play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		# Don't interrupt certain animations unless necessary
		if animation_player.current_animation == "damaged" and anim_name != "damaged":
			return
		if animation_player.current_animation == "attack" and anim_name != "attack":
			return
		if animation_player.current_animation == "special" and anim_name != "special":
			return
		
		animation_player.play(anim_name)
	else:
		print("Animation not found: ", anim_name)

# Animation finished signal handler
func _on_animation_player_animation_finished(anim_name: String):
	match anim_name:
		"attack":
			is_attacking = false
		"special":
			is_special_attacking = false
		"damaged":
			is_damaged = false

# External function to trigger damaged state
func take_damage():
	is_damaged = true
	# You might want to add knockback or other effects here

# Connect the animation finished signal automatically
func _enter_tree():
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_player_animation_finished)
