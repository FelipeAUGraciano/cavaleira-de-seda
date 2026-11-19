extends Node
## Gera os retratos do bestiário (assets/ui/bestiario/<id>.png, 512x512, fundo transparente).
## Cada bicho é montado de verdade (a mesma classe do jogo, parado) num estúdio com luz de
## três pontos e fotografado em 3/4 de frente.
## Rodar (precisa de tela; no Linux sem monitor use xvfb-run):
##   godot --path . res://tools/bestiario/retratos.tscn            (todos)
##   godot --path . res://tools/bestiario/retratos.tscn -- sapo     (só um)

const OUT := "res://assets/ui/bestiario/"
const SIZE := 512

## [id, construtor, guinada extra (graus), ajuste]  (ajuste chamado depois do _ready)
var specs := [
	["irma_menor", func(): return Sister.new(false), 0.0, null],
	["irma_faminta", func(): return Sister.new(true), 0.0, null],
	["mae", func():
		var m := MotherChase.new()
		m.route = PackedVector2Array([Vector2(-20, 0), Vector2(20, 0)])
		return m, 90.0, func(n): n.visible = true],
	["larva", func(): return Larva.new(), 0.0, null],
	["sapo", func(): return Frog.new(), 0.0, null],
	["morcego", func(): return Bat.new(), 0.0, null],
	["lagarto", func(): return Lizard.new(), 0.0, null],
	["formiga", func(): return Ant.new(), 0.0, null],
	["cobra", func(): return Snake.new(), 0.0, _snake_out],
	["centopeia", func(): return Centipede.new(), 0.0, null],
	["besouro", func(): return Beetle.new(), 0.0, null],
	["aranha_lobo", func(): return WolfSpider.new(), 0.0, null],
	["mimico", func(): return Mimic.new(), 0.0, null],
	["morcego_gigante", func(): return GiantBat.new(), 0.0, null],
	["escorpiao", func(): return Scorpion.new(), 0.0, null],
	["lesma", func(): return AcidSlug.new(), 0.0, null],
	["colosso", func(): return Colossus.new().setup(PackedVector2Array([Vector2(-30, 0), Vector2(30, 0)])), 0.0, null],
	["cortina", func(): return BatCurtain.new().setup(Vector3(0, 0, -4), Vector3(0, 0, 4)), 0.0, null],
	["serpente", func(): return Serpent.new(), 0.0, null],
	["besouro_brasa", func(): return EmberBeetle.new(), 0.0, null],
	["morcego_cinza", func(): return AshBat.new(), 0.0, null],
	["aranha_cinza", func(): return AshSpider.new(), 0.0, null],
	["salamandra", func(): return FireSalamander.new(), 0.0, null],
	["golem", func(): return BasaltGolem.new(), 0.0, null],
	["peixe_magma", func(): return MagmaFish.new(), 0.0, null],
	["verme_lava", func(): return LavaWorm.new(), 0.0, null],
	["rainha", func(): return QueenSalamander.new(), 0.0, null],
	["espadachim", func(): return Hunter.new("espadachim"), 0.0, null],
	["arqueira", func(): return Hunter.new("arqueira"), 0.0, null],
	["batedor", func(): return Hunter.new("batedor"), 0.0, null],
	["capita", func(): return Captain.new(), 0.0, null],
]

func _snake_out(n) -> void:
	## A cobra fora da fresta, de cabeça erguida (como logo antes do bote).
	n.player_memory = 5.0
	for i in 20:
		n._animate(0.1, 0.0)


var vp: SubViewport
var stage: Node3D
var cam: Camera3D


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var only := OS.get_cmdline_user_args()
	vp = SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	_studio()
	for s in specs:
		if not only.is_empty() and not only.has(s[0]):
			continue
		await _shoot(s)
	print("retratos prontos")
	get_tree().quit()


func _studio() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.5, 0.75)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.9, 0.8)
	key.light_energy = 1.5
	key.rotation_degrees = Vector3(-40, -35, 0)
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color(0.45, 0.8, 1.0)
	rim.light_energy = 1.6
	rim.rotation_degrees = Vector3(-20, 160, 0)
	vp.add_child(rim)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.7, 0.6, 1.0)
	fill.light_energy = 0.4
	fill.rotation_degrees = Vector3(-10, 60, 0)
	vp.add_child(fill)
	cam = Camera3D.new()
	cam.fov = 30.0
	cam.far = 400.0
	vp.add_child(cam)
	cam.current = true


func _shoot(s: Array) -> void:
	stage = Node3D.new()
	vp.add_child(stage)
	var n: Node3D = (s[1] as Callable).call()
	n.set_meta("vitrine", true)
	n.process_mode = Node.PROCESS_MODE_DISABLED
	stage.add_child(n)
	await _frames(2)
	if s[3] != null:
		(s[3] as Callable).call(n)
	await _frames(1)
	if n is Creature:
		World.unregister(n)
		var cr := n as Creature
		if cr._visual != null:
			cr._visual.scale = cr._vis_base if cr._vis_base != Vector3.ZERO else cr._visual.scale
	n.rotation_degrees.y += float(s[2])
	await _frames(1)
	var box := _bounds(n)
	if box.size == Vector3.ZERO:
		print("SEM VISUAL: ", s[0])
		stage.queue_free()
		return
	var c := box.get_center()
	var rad := box.size.length() * 0.5
	var dir := Vector3(0.75, 0.5, -1.0).normalized()
	var dist := rad / tan(deg_to_rad(cam.fov * 0.5)) * 0.92
	cam.position = c + dir * dist
	cam.look_at(c, Vector3.UP)
	cam.near = maxf(0.01, dist - rad * 2.0)
	await _frames(4)
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "%s.png" % s[0]))
	print("retrato: ", s[0], "  ", box.size)
	stage.queue_free()
	await _frames(2)


func _bounds(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for v in n.find_children("*", "VisualInstance3D", true, false):
		var vi := v as VisualInstance3D
		if not vi.is_visible_in_tree() or vi is Light3D or vi is GPUParticles3D or vi is CPUParticles3D or vi is Decal:
			continue
		if vi is Label3D or vi is Sprite3D:
			continue
		var b := vi.global_transform * vi.get_aabb()
		if b.size.length() > 200.0:
			continue
		if first:
			out = b
			first = false
		else:
			out = out.merge(b)
	return out


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
