class_name AshBat
extends Bat
## Morcego de cinza (P, bandos): vive na fumaça do Pântano de cinzas. Asas cinzentas com
## brasas nas pontas; o mergulho queima.


func _init() -> void:
	display_name = "Morcego de cinza"
	level = 5
	max_hp = 18.0
	body_color = Color(0.32, 0.3, 0.3)
	food_satiety = 18.0
	food_silk = 10.0
	food_xp = 22
	senses_text = "som (11 m): ouve quem se mexe; o mergulho queima"
	dive_damage = 9.0
	dive_burn = 3.0
