class_name Attack
extends RefCounted
## Um golpe de criatura, no estilo Monster Hunter: aviso → golpe → recuperação.
##
## - Aviso (windup): a criatura gira atrás de você (track, rad/s) e mira onde você VAI estar
##   (lead, segundos de previsão). Uma marca no chão mostra a área e enche até o golpe.
## - Golpe (active): a área machuca enquanto durar. O golpe vai até o fim mesmo que você
##   saia do alcance: sair andando não cancela, só esquivar (i-frames) ou estar fora da área.
## - Recuperação (recover): a criatura fica parada — é a sua janela de punir.
## Bichos furiosos (metade da vida) avisam menos e esperam menos entre golpes.

enum Shape { CONE, CIRCLE, LINE, RING }

var id := ""
var label := ""                ## nome mostrado na Leitura ("Bote", "Salto")
var min_range := 0.0           ## só começa com a jogadora entre min_range e max_range
var max_range := 2.0
var windup := 0.5
var active := 0.15
var recover := 0.6
var cooldown := 2.0
var weight := 1.0
var damage := 20.0
var shape: Shape = Shape.CONE
var reach := 2.0               ## raio (cone, círculo, anel) ou comprimento (linha)
var arc := 90.0                ## abertura do cone (graus)
var width := 1.2               ## largura da linha
var lunge := 0.0               ## m/s para a frente durante o golpe (bote, investida)
var leap := false              ## pula até o ponto mirado; a área é um círculo no pouso
var at_point := false          ## a área é um círculo no ponto mirado, sem sair do lugar (cuspe)
var track := 6.0               ## quanto gira atrás de você durante o aviso (rad/s)
var lead := 0.0                ## previsão: mira onde você estará daqui a `lead` segundos
var knockback := true
var needs_sight := false       ## só começa vendo a jogadora (cuspe, língua)
var only_enraged := false
var flank := false             ## golpe contra quem fica rodando: preferido quando você está do lado/atrás
var effect := ""               ## "pull", "slow", "acid", "web", "stun" — tratado pela espécie
var effect_power := 0.0
var combo_next := ""           ## se acertar, emenda este golpe na hora
var cd_left := 0.0


static func make(id_: String, label_: String, props: Dictionary) -> Attack:
	var a := Attack.new()
	a.id = id_
	a.label = label_
	for k in props:
		a.set(k, props[k])
	return a


func in_range(d: float) -> bool:
	return d >= min_range and d <= max_range


func hits(origin: Vector3, facing: Vector3, point: Vector3, target: Vector3, target_radius: float) -> bool:
	## A jogadora (target) está dentro da área do golpe?
	var to := target - origin
	to.y = 0.0
	match shape:
		Shape.CIRCLE:
			var c := point if (leap or at_point) else origin
			return Fx.flat_dist(c, target) <= reach + target_radius
		Shape.RING:
			return to.length() <= reach + target_radius
		Shape.LINE:
			var f := Vector3(facing.x, 0.0, facing.z).normalized()
			var along := to.dot(f)
			if along < -0.3 or along > reach + target_radius:
				return false
			var side := (to - f * along).length()
			return side <= width * 0.5 + target_radius
		_:
			var dist := to.length()
			if dist > reach + target_radius:
				return false
			if dist < 0.6:
				return true
			var f2 := Vector3(facing.x, 0.0, facing.z).normalized()
			return rad_to_deg(f2.angle_to(to.normalized())) <= arc * 0.5 + rad_to_deg(atan2(target_radius, dist))
