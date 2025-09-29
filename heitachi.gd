extends CharacterBody2D

# === Constants ===
const SPEED = 200
const JUMP_VELOCITY = -350
const GRAVITY = 900
const ATTACK_DAMAGE = 40

# === Nodes ===
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var health_bar: ProgressBar = $HealthBarContainer/healthbar
@onready var HealthBarContainer: Node2D = $HealthBarContainer

# === States ===
var is_crouching = false
var is_attacking = false

# === Health ===
var max_health = 100
var health = 99

# === Input config per player ===
var input_left = "p2left"
var input_right = "p2right"
var input_down = "p2down"
var input_jump = "p2up"
var input_attack = "p2attack"
var input_special = "p2special"

# === Attack cooldown ===
var attack_cooldown = 0.5
var attack_timer = 0.0

func _ready() -> void:
	health_bar.set_health_bar(health, max_health)
	attack_area.monitoring = false

	attack_area.body_entered.connect(Callable(self, "_on_attack_area_body_entered"))
func _physics_process(delta: float) -> void: 
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta

	# Movement input
	var direction = Vector2.ZERO
	if Input.is_action_pressed(input_right):
		direction.x += 1
	if Input.is_action_pressed(input_left):
		direction.x -= 1

	# Jump
	if Input.is_action_just_pressed(input_jump) and is_on_floor() and not is_crouching and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# Crouch
	is_crouching = Input.is_action_pressed(input_down) and is_on_floor()

	# Attack
	if Input.is_action_just_pressed(input_attack) and not is_attacking and attack_timer <= 0:
		attack_timer = attack_cooldown
		await _perform_attack()  # <-- new one-shot mechanic
		return  # skip movement during attack start

	# Movement lock while attacking
	if not is_crouching and not is_attacking:
		velocity.x = direction.x * SPEED
	else:
		velocity.x = 0

	move_and_slide()
	_update_animation(direction)

func _update_animation(direction: Vector2) -> void:
	if is_attacking:
		animated_sprite.play("attack")
	elif not is_on_floor():
		animated_sprite.play("jump")
	elif is_crouching:
		animated_sprite.play("crouch")
	elif direction.x != 0:
		animated_sprite.play("walk")
		animated_sprite.flip_h = direction.x < 0
	else:
		animated_sprite.play("idle")

# === NEW attack mechanic using await ===
func _perform_attack() -> void:
	is_attacking = true
	animated_sprite.play("attack")
	attack_area.monitoring = true

	# Wait until the attack animation finishes (one-shot)
	await animated_sprite.animation_finished
	_end_attack()

func _end_attack() -> void:
	is_attacking = false
	attack_area.monitoring = false

# === Damage / Health ===
func take_damage(damage: int) -> void:
	health -= damage
	if health < 0: health = 0
	health_bar.change_health(-damage)
	animated_sprite.play("damaged")

func _on_death() -> void:
	queue_free()
