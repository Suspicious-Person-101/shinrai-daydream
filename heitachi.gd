extends CharacterBody2D

# Constants
const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const GRAVITY = 900.0
const ATTACK_DAMAGE = 40

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var health_bar: ProgressBar = $HealthBarContainer/healthbar
@onready var hitbox: Area2D = $AttackArea  # This receives damage

# State
var is_attacking := false
var can_take_damage := true

# Health
var max_health := 100
var health := 100

# Input mappings (can be configured for different players)
var input_left := "p2left"
var input_right := "p2right"
var input_down := "p2down"
var input_jump := "p2up"
var input_attack := "p2attack"

# Attack cooldown
var attack_cooldown := 0.5
var attack_timer := 0.0

# Damage invulnerability
var damage_cooldown := 0.3
var damage_timer := 0.0


func _ready() -> void:
	# Initialize health bar
	health_bar.set_health_bar(health, max_health)
	
	# Connect hitbox to receive damage
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	
	# Make sure attack area is disabled initially
	attack_area.monitoring = false
	
	
func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Update timers
	if attack_timer > 0:
		attack_timer -= delta
	if damage_timer > 0:
		damage_timer -= delta
		can_take_damage = false
	else:
		can_take_damage = true
	
	# Get movement direction
	var direction := Input.get_axis(input_left, input_right)
	
	# Handle jump
	if Input.is_action_just_pressed(input_jump) and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY
	
	# Handle attack
	if Input.is_action_just_pressed(input_attack) and not is_attacking and attack_timer <= 0:
		start_attack()
	
	# Handle movement (disabled during attack)
	if not is_attacking:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0
	
	# Apply movement
	move_and_slide()
	
	# Update animations
	update_animation(direction)


func update_animation(direction: float) -> void:
	# Flip sprite based on direction
	if direction != 0 and not is_attacking:
		animated_sprite.flip_h = direction < 0
	
	# Play appropriate animation
	if is_attacking:
		return  # Attack animation is handled by start_attack()
	elif not is_on_floor():
		animated_sprite.play("jump")
	elif Input.is_action_pressed(input_down) and is_on_floor():
		animated_sprite.play("crouch")
	elif direction != 0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")


func start_attack() -> void:
	is_attacking = true
	attack_timer = attack_cooldown
	animated_sprite.play("attack")
	
	# Enable attack hitbox
	attack_area.monitoring = true
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	
	# Disable attack hitbox
	attack_area.monitoring = false
	is_attacking = false


func _on_hitbox_area_entered(area: Area2D) -> void:
	# Check if the area is an attack from another character
	if area.name == "AttackArea" and can_take_damage:
		var attacker = area.get_parent()
		if attacker != self:  # Don't damage yourself
			take_damage(ATTACK_DAMAGE)


func take_damage(damage: int) -> void:
	if not can_take_damage:
		return
	
	health -= damage
	health = clamp(health, 0, max_health)
	health_bar.value = health
	
	# Set invulnerability period
	damage_timer = damage_cooldown
	
	# Play damage animation
	if health > 0:
		animated_sprite.play("damaged")
		await animated_sprite.animation_finished
	else:
		die()


func die() -> void:
	# Play death animation or effect here
	queue_free()
