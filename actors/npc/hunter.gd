class_name Hunter
extends Creature
## Caçador humano da expedição (Ato 4). Grandes, com fogo, e caçam a "aranha da runa".
##   espadachim  corpo a corpo: corte que emenda, estocada e empurrão de escudo
##   arqueira    flechas de fogo de longe: queimam seus fios no caminho e te deixam queimando
##   batedor     tocha na mão: segue rastros de seda (vai até os seus fios e queima), avisa o grupo
##   capita      a Capitã da expedição (minichefe da Subida antiga), ver Captain
## Enxergam com a luz das tochas: com a runa acesa você aparece de longe; apagada, só de perto.
## Ver você, achar teia ou perder um companheiro sobe o ALERTA DA CAÇADA (HuntDirector).
## Vencidos, viram comida como os bichos (embrulhar e comer).

var role := "espadachim"
var squad := false                 ## do acampamento: é o esquadrão que sai quando o alerta chega a 3
var director: Node = null
var torch: Fire
var _seen_cd := 0.0
var _seek_cd := 4.0
var _seek: WebStrand = null
var _seek_goal := Vector3.ZERO
var _seek_best := INF
var _seek_stuck := 0.0
var _ignored := {}
const LOOKS := {"espadachim": ["aventureiro_a", Color(0.55, 0.4, 0.3)], "arqueira": ["aventureiro_b", Color(0.35, 0.4, 0.55)],
	"batedor": ["aventureiro_c", Color(0.5, 0.5, 0.45)], "capita": ["aventureiro_a", Color(0.6, 0.18, 0.15)]}


func _init(role_: String = "espadachim") -> void:
	role = role_
	size = Size.G
	body_radius = 0.42
	nav_kind = NavGrid.Kind.LARGE
	aggression = 1.0
	memory_time = 8.0
	track_range = 24.0
	leash_range = 45.0
	sight_fov = 120.0
	food_satiety = 80.0
	food_silk = 35.0
	food_xp = 120
	model_name = String(LOOKS[role][0])
	model_fit = "height"
	model_size = 1.85
	body_color = LOOKS[role][1]
	uses_interest = false
	match role:
		"espadachim":
			display_name = "Caçador espadachim"
			level = 12
			max_hp = 120.0
			speed = 3.4
			sight_range = 9.0
			senses_text = "visão com a tocha do grupo (9 m; runa acesa te entrega de longe) e barulho"
			add_attack(Attack.make("corte", "Corte", {"max_range": 2.4, "windup": 0.5, "active": 0.16, "recover": 0.5,
				"cooldown": 1.4, "damage": 22.0, "reach": 2.3, "arc": 100.0, "lunge": 3.0, "combo_next": "corte2", "weight": 3.0}))
			add_attack(Attack.make("corte2", "Corte de volta", {"max_range": 2.6, "windup": 0.3, "active": 0.14, "recover": 0.6,
				"cooldown": 3.0, "damage": 18.0, "reach": 2.4, "arc": 120.0, "lunge": 2.0, "weight": 0.0}))
			add_attack(Attack.make("estocada", "Estocada", {"min_range": 2.0, "max_range": 4.0, "windup": 0.65, "active": 0.2,
				"recover": 0.7, "cooldown": 3.5, "damage": 26.0, "shape": Attack.Shape.LINE, "reach": 3.6, "width": 0.8, "lunge": 5.0, "weight": 2.0}))
			add_attack(Attack.make("escudo", "Empurrão de escudo", {"max_range": 1.8, "windup": 0.35, "active": 0.14, "recover": 0.5,
				"cooldown": 4.0, "damage": 12.0, "reach": 1.8, "arc": 90.0, "lunge": 2.5, "weight": 1.5}))
		"arqueira":
			display_name = "Caçadora arqueira"
			level = 12
			max_hp = 80.0
			speed = 3.6
			sight_range = 12.0
			retreat_frac = 0.2
			senses_text = "visão de longe (12 m); flechas de fogo queimam seus fios"
			add_attack(Attack.make("flecha", "Flecha de fogo", {"min_range": 3.0, "max_range": 12.0, "windup": 0.9, "active": 0.15,
				"recover": 0.6, "cooldown": 2.4, "damage": 18.0, "shape": Attack.Shape.LINE, "reach": 12.0, "width": 0.5,
				"knockback": false, "effect": "burn", "effect_power": 2.0, "weight": 3.0}))
			add_attack(Attack.make("chute", "Chute", {"max_range": 1.8, "windup": 0.3, "active": 0.12, "recover": 0.5,
				"cooldown": 2.0, "damage": 10.0, "reach": 1.7, "arc": 90.0, "lunge": 1.5, "weight": 1.0}))
		"batedor":
			display_name = "Caçador batedor"
			level = 11
			max_hp = 90.0
			speed = 3.9
			sight_range = 11.0
			senses_text = "segue rastros de seda e queima os fios com a tocha (11 m)"
			add_attack(Attack.make("tocha", "Golpe de tocha", {"max_range": 2.2, "windup": 0.45, "active": 0.16, "recover": 0.5,
				"cooldown": 1.6, "damage": 14.0, "reach": 2.1, "arc": 110.0, "lunge": 2.5, "effect": "burn", "effect_power": 3.0, "weight": 3.0}))


func _ready() -> void:
	super._ready()
	add_to_group("hunter")
	add_to_group("predator")
	if role == "batedor" or role == "capita":
		torch = Fire.new(0.55)
		torch.position = Vector3(0.45, 0.6, -0.1)
		add_child(torch)
	elif role == "espadachim":
		var lantern := OmniLight3D.new()   # lanterna no cinto: dá para ver os espadachins chegando
		lantern.light_color = Color(1.0, 0.75, 0.4)
		lantern.omni_range = 5.0
		lantern.light_energy = 1.0
		lantern.position = Vector3(0, 1.2, 0)
		add_child(lantern)


func notices_player(p: Player) -> bool:
	var d := flat_dist_to(p)
	if d < body_radius + 1.2 or d < p.noise_radius() * 1.2:
		return true
	var vis := p.visibility_mult() * (1.6 if p.rune_on else 1.0)
	return can_see(p, sight_range * vis, sight_fov)


func sees_player_as_prey(_p: Player) -> bool:
	return true


func is_prey(_o: Creature) -> bool:
	return false


func _think(delta: float) -> Vector3:
	_seen_cd -= delta
	var p := GameState.player as Player
	if p != null and not p.dead and player_memory >= memory_time - 0.3 and _seen_cd <= 0.0:
		_seen_cd = 5.0
		if director != null:
			director.raise(0.8, p.global_position, self)
	# o batedor segue o rastro de seda: vai até o fio mais perto (que ele alcança) e queima
	if role == "batedor" and player_memory <= 0.0:
		_seek_cd -= delta
		if _seek != null and (not is_instance_valid(_seek) or not WebNetwork.strands.has(_seek)):
			if director != null:
				director.raise(0.4, global_position, self)
			_seek = null
		if _seek == null and _seek_cd <= 0.0:
			_seek_cd = 3.0
			var best_d := 26.0
			for s in WebNetwork.strands:
				if not is_instance_valid(s) or _ignored.has(s):
					continue
				var ws := s as WebStrand
				var d := ws.distance_to(global_position)
				if d >= best_d:
					continue
				var goal = _goal_near(ws)
				if goal == null:
					continue
				var path := World.nav.path(global_position, goal, nav_kind)
				if path.size() > 0 and Fx.flat_dist(path[path.size() - 1], goal) < 1.5:
					best_d = d
					_seek = ws
					_seek_goal = goal
					_seek_best = INF
					_seek_stuck = 0.0
		if _seek != null:
			activity = "Seguindo o rastro de seda"
			if _seek.distance_to(global_position) < 2.6:
				Fx.beam(get_parent(), global_position + Vector3(0, 1.2, 0), (_seek.a_pos + _seek.b_pos) * 0.5 + Vector3(0, 0.2, 0), Color(1.0, 0.5, 0.15), 0.4, 0.12)
				WebNetwork.remove_strand(_seek)
				if near_player:
					EventBus.message.emit("Um batedor queimou o seu fio!")
				return Vector3.ZERO
			var dd := Fx.flat_dist(global_position, _seek_goal)
			if dd < _seek_best - 0.3:
				_seek_best = dd
				_seek_stuck = 0.0
			else:
				_seek_stuck += delta
				if _seek_stuck > 4.0:   # empacou: desiste deste fio por um tempo
					_ignored[_seek] = true
					_seek = null
					return Vector3.ZERO
			return nav_to(_seek_goal, 0.8)
	return super._think(delta)


func _goal_near(ws: WebStrand) -> Variant:
	## Um ponto andável (para o tamanho dele) a até 2 m do fio.
	for k in 7:
		var t := k / 6.0
		var q := ws.a_pos.lerp(ws.b_pos, t)
		for r in [0.0, 1.2, 1.9]:
			for a in 8:
				var c: Vector3 = q + Vector3(cos(a * TAU / 8.0), 0, sin(a * TAU / 8.0)) * float(r)
				if World.nav.walkable(c, nav_kind):
					return c
	return null


func on_attack_active(a: Attack) -> void:
	if a.id == "flecha":
		_burn_line(global_position, facing, a.reach, 0.6)


func _burn_line(from: Vector3, dir: Vector3, reach: float, half_w: float) -> void:
	var to := from + dir * reach
	for s in WebNetwork.strands.duplicate():
		if is_instance_valid(s):
			var ws := s as WebStrand
			for k in 6:
				if Fx.seg_dist_flat(ws.a_pos.lerp(ws.b_pos, k / 5.0), from, to) < half_w:
					WebNetwork.remove_strand(s)
					break
	for t in WebNetwork.traps.duplicate():
		if is_instance_valid(t) and Fx.seg_dist_flat(t.global_position, from, to) < half_w + 0.8:
			WebNetwork.remove_trap(t)
	if near_player:
		Fx.beam(get_parent(), from + Vector3(0, 1.2, 0), to + Vector3(0, 0.6, 0), Color(1.0, 0.55, 0.15), 0.3, 0.06)


func die(fell: bool = false) -> void:
	if director != null and not fell:
		director.comrade_down(self)
	super.die(fell)


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Caçando a aranha")) \
		.add(Behaviors.Retreat.new()) \
		.add(Behaviors.Stalk.new()) \
		.add(Behaviors.Roam.new()) \
		.add(Behaviors.Wander.new(4.0, 0.4))


func _build_visual() -> void:
	## Formas simples (o modelo do aventureiro entra por cima quando existe).
	var mat := _mat
	var body := Fx.cylinder(0.32, 1.3, mat)
	body.position.y = 0.95
	_visual.add_child(body)
	var head := Fx.sphere(0.24, Fx.mat(Color(0.85, 0.7, 0.58)))
	head.position.y = 1.85
	_visual.add_child(head)
	var pack := Fx.box(Vector3(0.45, 0.6, 0.3), Fx.mat(body_color.darkened(0.4)))
	pack.position = Vector3(0.0, 1.15, 0.3)
	_visual.add_child(pack)
	_body_parts = [body, head, pack]
