class_name GiantBat
extends Bat
## Morcego gigante (M, bando): os mesmos da Cortina viva, mas acordados e caçando nas câmaras
## grandes do Abismo. Ouvem quem se mexe (14 m); parada, só bem perto. Mergulho pesado.
## Fio esticado no caminho derruba igual aos menores.


func _init() -> void:
	display_name = "Morcego gigante"
	size = Size.M
	level = 6
	max_hp = 40.0
	speed = 6.0
	body_radius = 0.42
	body_color = Color(0.2, 0.15, 0.2)
	food_satiety = 30.0
	food_silk = 14.0
	food_xp = 40
	senses_text = "som (14 m): ouve quem se mexe; parada, só a 2 m"
	model_size = 2.0
	dive_damage = 18.0
	hear_range = 14.0
