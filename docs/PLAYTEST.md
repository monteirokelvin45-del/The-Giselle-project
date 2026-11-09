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

---

## v1.3 + v1.4 — checklist de jogabilidade (2026-11-07)

1. **Salto no último passo** — corre e salta na beira: sem coyote prendeste ou "comiste" saltos? (esperado: 0,12s de tolerância)
2. **Esquiva perfeita** (FANTASMA) — deixa-te atingir durante a arrancada: recebeste Ruptura/fôlego e o flash?
3. **Sprint attack** — ataca em corrida: sentiste a arrancada estendida?
4. **Arremesso do Lobo** — vês o lobo abaixar-se antes? Consegues esquivar ou atordoar no meio do salto?
5. **Mago de Cinza** — vês o clarão turquesa antes do disparo? Tens tempo para a Corrente?
6. **Flinch** — o Salteador verga quando o acertas com o pesado? E o Guardião NÃO verga?
7. **HP do alvo fixado** — a barra carmesim desce plausivelmente?
8. **GOLPEIA AGORA** — aparece quando a postura quebra? Some depois?
9. **Banner do Guardião** — aparece na primeira ferida e não reaparece?
10. **Vinheta** — flash vermelho ao apanhares um golpe; pulso abaixo de 30% de vida?
11. **Marcador ✕ e combo ×N** — piscam a cada acerto; somem sozinhos?
12. **Fúria do Guardião (50% HP)** — rugido, sacode, +dano, emissão rubra?

Regista aqui o que sentiste fora do sítio:

## v1.6 — arsenal e noite (2026-11-07)

1. **Anoitecer** — fica parado ao fim da tarde na mata (ou espera o
   ciclo): a luz esfria? O aviso «A NOITE CAI» aparece? O relógio ☾ NOITE
   fica índigo?
2. **Ecos chegam devagar** — à noite, na floresta: os inimigos aparecem
   das sombras (≥ 12 m)? São umbra/espectro/alfa na maioria? (máx. 4
   vivos)
3. **Brush-pass do jogador** — à noite fora da floresta: nenhum Eco
   nasce? (zona delimitada)
4. **Aurora banha a floresta** — deixa um Eco a meio de combate e espera
   o amanhecer: o aviso «AURORA» aparece? O Eco dissolve-se sem fila nem
   recompensa?
5. **Brasa de Ruína** — vês o clarão ember antes do projétil? O
   projétil ember é visivelmente diferente do turquesa do Mago?
6. **Lobo Alfa** — vês-o descendente (1.35×) antes da emboscada? O
   arremesso telegrafado existe (windup) como no lobo normal?
7. **Expedições** — Ruun/Sahr/Khar: os pools de 6 inimigos trazem
   veterano/brasa? Sentes a ameaça elevar de nível?
8. **HUD relógio** — ☀/☾ alterna com a luz? (o ciclo completo ~4 min:
   decidirá no F5 se é demasiado rápido)

Regista aqui o que sentiste fora do sítio:
