class_name VisionOverlay
extends CanvasLayer
## Visão curta: escurece a tela fora de um círculo em volta da aranha. Não apaga o que
## brilha (fungos, olhos, avisos de golpe continuam aparecendo atrás da névoa escura).

var player: Player
var _rect: ColorRect
var _mat: ShaderMaterial
var _r := 0.0   ## raio suavizado (acender/apagar a runa abre e fecha a visão devagar)

const SHADER := """
shader_type canvas_item;
uniform vec2 center = vec2(0.5);
uniform float radius = 200.0;
uniform float soft = 160.0;
uniform float strength = 0.72;
uniform vec2 screen = vec2(1600.0, 900.0);
void fragment() {
	vec2 px = UV * screen;
	float d = distance(px, center);
	float a = smoothstep(radius, radius + soft, d) * strength;
	COLOR = vec4(0.0, 0.0, 0.01, a);
}
"""


func _ready() -> void:
	layer = 5
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_rect.material = _mat
	add_child(_rect)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player) or player.camera == null:
		_rect.visible = false
		return
	_rect.visible = true
	var cam := player.camera
	var vp := _rect.get_viewport_rect().size
	var c := cam.unproject_position(player.global_position + Vector3.UP * 0.4)
	# runa acesa clareia bem mais em volta (a luz azul dela); apagada, só a visão no escuro
	var r := player.sight_radius() * ((1.35 + 0.35 * player.energy / maxf(player.max_energy, 1.0)) if player.rune_on else 1.0)
	_r = r if _r <= 0.0 else lerpf(_r, r, clampf(delta * 5.0, 0.0, 1.0))
	var edge := cam.unproject_position(player.global_position + cam.global_transform.basis.x * _r)
	_mat.set_shader_parameter("center", c)
	_mat.set_shader_parameter("radius", maxf(40.0, c.distance_to(edge)))
	_mat.set_shader_parameter("soft", maxf(60.0, c.distance_to(edge) * 0.8))
	_mat.set_shader_parameter("screen", vp)
