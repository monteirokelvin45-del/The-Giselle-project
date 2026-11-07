# PLAYTEST — checklist de QA humano (obrigatório antes de chamar v1.0 «pronta»)

Nada aqui pode ser substituído por CI: o sandbox não tem GPU, voz humana,
Android nem olho humano. Duração: 30–45 min. Regista tudo com capturas.

## A. Setup (5 min)
- [ ] PC com Godot 4.7+: F5 → ecrã de título → **Novo Jogo** (do zero).
- [ ] Android: export/instalar (ver `docs/BUILD.md` e `README.md` — seção Android).
- [ ] Dificuldade Normal; idioma PT, depois repetir troca para EN/ES/ES.

## B. Percurso crítico (10 min)
- [ ] Vale: falar com Elen (objetivo muda) · Garr · aceitar as duas missões
      (Lobos / Luz para as Lâmpadas) · verificar contadores no HUD.
- [ ] Viajar para a Academia (mapa) · voss_meet · 4 provas: verificar NPCs
      companheiros: bram → bram_pre → exame de duelo vs Guardião.
- [ ] Morrer 1× numa prova (Bram deve zerar tu hp vs tu nível): confirmar
      respawn na arena sem punição permanente.

## C. Meta-quests — OS NOVOS SISTEMAS (15 min)
**A Ferida:**
- [ ] Com estágio ≥ 5 e prova/prova social feita, falar com Voss → rumor.
- [ ] Reabrir Voss → `voss_ferida` com 3 escolhas → escolher 1 →
      objetivo lateral ✓ → falar de novo → créditos listam «A Ferida — …».
- [ ] Fechar o jogo, carregar, confirmar que `world_flags` persistiu
      (HUD mostra «concluída ✓»).
- [ ] Continuar até A Decisão → final escolhido aparece normalmente.

**O Golpe da Custódia:**
- [ ] Estágio ≥ 5 + ≥ 2 exames → Bram chama (`bram_golpe`).
- [ ] Escolher **Ficar calado** → `A DECISÃO` → «O Reformado» bloqueado
      com aviso (cadeado + razão). Um save novo deve re-desbloquear.
- [ ] Repetir run → **Denunciar** → Guardas prendidos → créditos «denunciado».

**Epílogos com memória:**
- [ ] Romancear Bram (pós-prova) + prova dele feita ⇒ lealdade ≥ 60 ⇒
      epílogo varia; sem prova, epílogo padrão.

## D. Performance real (10 min, no hardware-alvo)
- [ ] `godot --path . -s res://tools/perf_probe.tscn` (ou rodar apontando
      para addon) e registar: ms proc/fis média, pico, MB, nós, órfãos.
- [ ] FPS no Android (Galaxy A13+/Snapdragon 6xx): ≥ 30 fps no pátio com
      arena vazia; cenas com 200+ inimigos (arena waves): anotar min fps.
- [ ] Temperatura/bateria após 15 min: sem throttling perceptível.

## E. QA linguístico nativo (5 min cada idioma)
- [ ] EN: menu pausa → idioma English → confirmar 10 strings chave (pausa,
      objetivos, créditos, A DECISÃO) — pedir opinião de falante nativo.
- [ ] ES: idem. Registar erros na issue `i18n-QA` (antes de marcar
      «EN/ES prontos para release» no ROADMAP).

## F. Sanidade visual (F5)
- [ ] Cel-shading ON (default): rosto/cabelo com degraus, rim visível em
      contraluz; mudar para OFF no pausa → requer reload da cena (o aviso
      deve aparecer).
- [ ] Crimson/silhueta: personagens legíveis contra o céu em Khar.

## G. Reportar
- Criar issue com: dispositivo, janela (px), dificuldade, idioma, passos,
  esperado vs observado, captura. Tag: `playtest-YYYY-MM-DD`.
