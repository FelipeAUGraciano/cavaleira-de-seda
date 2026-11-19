class_name KitBook
extends RefCounted
## Qual kit de ataques cada forma usa. Ramos: um kit. Formas finais e raras: estilo A ou B.

const L = preload("res://actors/player/kits/kits_lamina.gd")
const T = preload("res://actors/player/kits/kits_teia.gd")
const R = preload("res://actors/player/kits/kits_runa.gd")
const X = preload("res://actors/player/kits/kits_raras.gd")


static func styles(form: int) -> int:
	## Quantos estilos a forma tem (0 = ataques padrão).
	if form <= Player.Form.CAVALEIRA:
		return 0
	if Player.BRANCHES.has(form):
		return 1
	return 2


static func make(form: int, style: int) -> AttackKit:
	var table := {
		Player.Form.LAMINA: [L.Ceifadora], Player.Form.TEIA: [T.Tecela], Player.Form.RUNA: [R.Arauta],
		Player.Form.EXECUTORA: [L.Frenesi, L.Foices], Player.Form.BASTIA: [L.Martelo, L.Muralha],
		Player.Form.SENHORA: [T.Guerra, T.Rede], Player.Form.SALTADORA: [T.Pendulo, T.Ricochete],
		Player.Form.VIDENTE: [R.PontoFraco, R.Antecipacao], Player.Form.TEMPESTADE: [R.Raio, R.Campo],
		Player.Form.ARDENTE: [X.LancaChamas, X.Fornalha], Player.Form.BREU: [X.Assassina, X.SombraViva],
		Player.Form.VIUVA: [X.Presas, X.FiosVenenosos], Player.Form.CORROSIVA: [X.Cuspe, X.Banho],
		Player.Form.LUA: [X.Lanca, X.Espelho],
	}
	if not table.has(form):
		return null
	var opts: Array = table[form]
	var cls = opts[clampi(style, 0, opts.size() - 1)]
	return cls.new() as AttackKit


static func info(form: int, style: int) -> Dictionary:
	## Nomes e descrições, para o menu do casulo (sem pôr o kit na cena).
	var k := make(form, style)
	if k == null:
		return {}
	var d := {"names": k.names.duplicate(), "descs": k.descs.duplicate()}
	k.free()
	return d
