class_name AshSpider
extends WolfSpider
## Aranha de cinza (P, matilhas de 3): rival que tece fios de cinza que não queimam. Caça
## em grupo como as aranhas-lobo, mas prende de longe com um fio grudento (fica lenta).


func _init() -> void:
	display_name = "Aranha de cinza"
	level = 8
	max_hp = 40.0
	speed = 5.0
	body_color = Color(0.36, 0.34, 0.33)
	food_satiety = 32.0
	food_silk = 30.0
	food_xp = 45
	fire_immune = true
	food_fire = 0
	senses_text = "visão no escuro (8 m) e vibração; atira fio de cinza que deixa lenta"
	add_attack(Attack.make("fio_cinza", "Fio de cinza", {"min_range": 3.0, "max_range": 8.0, "windup": 0.6, "active": 0.2,
		"recover": 0.6, "cooldown": 5.0, "damage": 4.0, "shape": Attack.Shape.LINE, "reach": 8.0, "width": 0.6,
		"knockback": false, "effect": "slow", "effect_power": 2.5, "weight": 2.0}))


func _build_visual() -> void:
	super._build_visual()
	var glow := Fx.mat(Color(1.0, 0.5, 0.2), 1.6, true)
	var stripe := Fx.box(Vector3(0.05, 0.03, 0.5), glow)
	stripe.position = Vector3(0, 0.9, 0.42)
	_visual.add_child(stripe)
