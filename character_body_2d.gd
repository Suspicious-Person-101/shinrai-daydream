extends CharacterBody2D

# --- EXPORTS ---
@export var move_speed: float = 200.0
@export var attack_damage: int = 10
@export var max_hp: int = 100

# --- NODES ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

# --- VARIABLES ---
var hp: int
var is_attacking: bool = false
var is_crouching: bool = false
var is_special: bool = false

func _ready():
	hp = max_hp
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)

func _physics_process(delta):
	handle_input(delta)
	move_and_slide()
	update_animation()

func handle_input(delta):
	velocity.x = 0

	if Input.is_action_pressed("move_right"):
		velocity.x += move_speed
		anim.flip_h = false
	elif Input.is_action_pressed("move_left"):
		velocity.x -= move_speed
		anim.flip_h = true

	is_crouching = Input.is_action_pressed("crouch")

	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	if Input.is_action_just_pressed("special") and not is_special:
		special()

	if not is_on_floor():
		velocity.y += 1000 * delta
	else:
		velocity.y = 0

func update_animation():
	if is_attacking:
		anim.play("attack")
	elif is_special:
		anim.play("special")
	elif is_crouching:
		anim.play("crouch")
	elif velocity.x != 0:
		anim.play("walk")
	else:
		anim.play("idle")

func attack() -> void:
	is_attacking = true
	anim.play("attack")
	attack_area.position.x = 30 if not anim.flip_h else -30
	attack_area.monitoring = true
	await anim.animation_finished
	attack_area.monitoring = false
	is_attacking = false

func special() -> void:
	is_special = true
	anim.play("special")
	await anim.animation_finished
	is_special = false

func take_damage(amount: int):
	hp -= amount
	hp = clamp(hp, 0, max_hp)
	print("%s HP: %d" % [name, hp])
	if hp <= 0:
		die()

func die():
	print("%s died!" % name)
	anim.play("idle")
	set_physics_process(false)

func _on_attack_area_body_entered(body):
	if body != self and body.has_method("take_damage"):
		body.take_damage(attack_damage)
