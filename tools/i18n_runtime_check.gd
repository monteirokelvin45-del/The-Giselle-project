## E2E das traduções em runtime: corre com o projeto carregado
## (não instancia cenas nem autoloads — testa o TranslationServer e o CSV).
## Uso: godot --headless --path . --script tools/i18n_runtime_check.gd
extends SceneTree

func _init() -> void:
	var ok := true
	var original := TranslationServer.get_locale()

	TranslationServer.set_locale("en")
	var en := tr("Jogo guardado.")
	print("[en] ", en)
	if en != "Game saved.":
		push_error("EN mismatch para 'Jogo guardado.'")
		ok = false

	TranslationServer.set_locale("es")
	var es := tr("Jogo guardado.")
	print("[es] ", es)
	if es != "Partida guardada.":
		push_error("ES mismatch para 'Jogo guardado.'")
		ok = false

	TranslationServer.set_locale("pt")
	var pt := tr("Jogo guardado.")
	print("[pt] ", pt)
	if pt != "Jogo guardado.":
		push_error("PT passthrough falhou")
		ok = false

	TranslationServer.set_locale("en")
	var fmt := tr("Estado: %s (lesão %d/%d) · Fadiga %d/%d") % ["Healthy", 0, 2, 0, 3]
	print("[en fmt] ", fmt)
	if not fmt.begins_with("State:"):
		push_error("EN format key não traduziu: " + fmt)
		ok = false

	TranslationServer.set_locale("es")
	var big := tr("AVALIAÇÃO Nº %d") % 7
	print("[es fmt] ", big)
	if not big.begins_with("EVALUACIÓN"):
		push_error("ES format key não traduziu: " + big)
		ok = false

	TranslationServer.set_locale(original)
	if not ok:
		push_error("i18n runtime check FAILED")
		quit(1)
	print("i18n runtime OK")
	quit(0)
