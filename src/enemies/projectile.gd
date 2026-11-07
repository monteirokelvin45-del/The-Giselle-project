## Projétil arcano disparado pelos Magos de Cinza e pela Brasa de Ruína.
## Reutilizável (v1.7): timeout ou impacto devolvem-no á ProjectilePool em vez
## de o destruir — ver src/enemies/projectile_pool.gd.
extends Area3D

const ProjectilePool := preload("res://src/enemies/projectile_pool.gd")

var direction: Vector3 = Vector3.FORWARD
var speed: float = 17.0
var damage: float = 12.0
var life: float = 4.0

func setup(dir: Vector3) -> void:
	direction = dir.normalized()

func _ready() -> void:
	collision_layer = 8
	collision_mask = 3
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	rotate_y(6.0 * delta)
	life -= delta
	if life <= 0.0:
		ProjectilePool.release(self)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, self)
	ProjectilePool.release(self)
