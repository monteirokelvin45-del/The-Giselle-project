# Elementos para o Giselle — «As Seis Disciplinas» como sistema de reação

**Estado: PROPOSTA — zero código até confirmação tua (F5/aprova).** Nada foi
implementado. Este documento existe para a decisão ser informada, não para
decidir por ti.

## 1. Contexto e princípio

O teu pedido recorrente: «elementos» como coração do combate — tabela de
reações (elemento aplicado + novo = resultado), status por inimigo com
temporizadores, tudo em **dados (JSON)**, não em código. Genshin é referência
de *direção* — aqui não se copia nada dele: nem nomes, nem 7 elementos, nem
a matemática exata. O Giselle tem algo melhor do que o pacote Genshin: **um
canon próprio escrito no GDD — as seis disciplinas mágicas de Arkanor**
(GDD §4):

| Disciplina | Natureza | Relevância no combate |
|---|---|---|
| **Cinética** | força, impacto, movimento | Fios de postura/choque — o candidato natural a "físico elemental" |
| **Ígnea** | fogo, calor, combustão | Queimaduras, pressão de área |
| **Hídrica** | água, pressão, adaptação | Saturação, apagar, cobertura |
| **Vital** | plantas, venenos, biologia | Envenenamento, raízes, cura inimiga |
| **Lúmina** | luz, perceção, revelação | Revelação, frágil a quem vê |
| **Umbral** | sombra, silêncio, selo | Véu, frágil a quem se esconde |

**E o par maior de sempre, também canónico:** Kael é um **Vazio** — sem
Núcleo Arcano (GDD §5). Ele **não lança disciplinas**; joga contra elas com
armas, ferramentas anti-magia e treino físico. Daí o design honesto:
**camadas**, nunca «Kael vira mago».

## 2. Camada 1 (v1.8) — reação sobre os inimigos; Kael nunca castra

Regra de ouro: **statuses vivem nos inimigos, como agora vive a postura/stun;
qualquer fonte aplica-os** (ataques de inimigos, ambiente, efeitos de cena).
Kael interage **através do oponente** — cancelar/interromper o caster antes de
a reação explodir vale mais do que «afinidade de arma».

### Os 6 statuses (GTD `elements.json`)

| Status | Fonte | Efeito base | Duração base |
|---|---|---|---|
| `cinza_carga` (Cinética) | golpes/choques de cinética | +30% dano à **postura** recebido | 6 s |
| `queimadura` (Ígnea) | fogo | dano ao longo do tempo 6/s | 8 s |
| `saturado` (Hídrica) | água | −25% velocidade; anula `queimadura` | 8 s |
| `toxina` (Vital) | venenos/plantas | dano ao longo do tempo 4/s + regen inimiga bloqueada | 10 s |
| `revelado` (Lúmina) | luz | próximo impacto crítico garantido flag; invisibilidade anulada | 6 s |
| `oculto` (Umbral) | sombra/seal | próximo elemento aplicado **não mostra FX** (evocação silenciosa) | 5 s |

Todos os números acima são **valores de partida por ajustar no F5 teu** —
vivem em JSON, não em código.

### Reações propostas (8 — não 36; começa-se pequeno)

| Status em cima | Novo elemento aplicado | Reação | Resultado |
|---|---|---|---|
| `saturado` | `queimadura` | **Vapor de Veyra** | explosão de área: dano em raio 2,5 m aos envolvidos |
| `saturado` | `cinza_carga` | **Cavitação** | dano de postura brutal — o choque viaja pela água |
| `queimadura` | `saturado` | **Apagão** | apaga o fogo e neutraliza os dois statuses (co-op tático) |
| `queimadura` | `cinza_carga` | **Onda de Choque** | pequeno impacto à volta do alvo (empurrar + postura) |
| `toxina` | `revelado` | **Fotoestase** | a toxina cristaliza: congela o inimigo 2 s |
| `revelado` | `oculto` | **Eclipse de um segundo** | a luz perde: silêncio absoluto — o alvo fica indetectável por 3 s (a favor do inimigo!) |
| `oculto` | `revelado` | **Despertar do Selado** | luz esmaga sombra: stun 1,5 s + grande dano + postura |
| `cinza_carga` | `toxina` | **Herda do Vazio** | a toxina torna-se volátil: detonas quando o trigger (parry/hit) acontece |

**Ordem antiga de reactividade (aditiva, legível):** primeiro aplica'se status,
depois a reação dispara pela aplicação seguinte — exatamente como a tua
referência pedia («elemento aplicado + novo = resultado»). Nada de calendários
mágicos escondidos; cada reação tem nome trilingue no CSV e uma frase curta.

## 3. Como isto entra no motor (toque mínimo e auditável)

- **Novo:** `src/balance/elements.json` — disciplines + statuses + reactions
  (nome, duração, efeitos, limiares, mensagens) e `src/core/elements.gd`
  (autoload `Elements` leve: leitura, aplicação, tick, consulta de reação).
- **Toques cirúrgicos:** `enemy.gd` ganha `_statuses: Dictionary` com timers
  (tickado no mesmo sítio onde `_stunned` é decrementado); `player.gd`/UI:
  faixa de statuses por alvo fixado (decisão UI tua na implementação); 
  `projectiles` carregam `discipline` quando o emissor o tem.
- **Sem dependências novas**, sem shaders, GLES3, offline, zero assets novos.
- **i18n:** ~60 chaves (6 disciplinas × 3 strings + 8 reações × 3 + HUD) —
  o validate.py gates do projeto tratam disso como sempre.
- **Gates:** gdparse/validate/i18n/headless_check/smoke/stress — e novos
  asserts: aplicação de status, timer expira, reação correta por prefixo,
  ausência de reações fora da tabela.

## 4. Escopo honesto e riscos

- **Risco de balança:** cada reação é uma multiplicadora de dano/postura
  escondida; se duplicadas empilharem, o medo é inevitável — mitigamos com
  budget no JSON (máx. 1 status reativo ativo por inimigo) e F5 contigo.
- **Risco de UI:** ícones = glifos de texto (ex.: Cinza `❖`, Ígnea `♨`...) —
  nunca novas texturas; se glifo não mapear, só texto.
- **Ortogonal ao combate**: nada disto muda parry/stamina/posture existentes;
  statuses são informação pura + gatilhos de reação.
- **Camada 2 (v1.9+) fica FORA:** «Kael imbuido» via ferramenta/arma a
  Arte Alta/runas — só depois da camada 1 estar no teu aparelho a funcionar.
- **O que não pede permissão e é decidido agora:** nomes técnicos das chaves
  JSON (`cinza_carga`, …) seguem o padrão do repo (`save_game` flags, l10n
  keys); texto visível ao jogador é tudo trilingue e revisto.

## 5. Estimativa de esforço (fatia v1.8)

~8–12 commits no teu branch: elements.json + elements.gd; enemy statuses +
timers; aplicação nos emisores existentes (cinza/brasa/wolves conforme
discipline); 3–4 reações primeiro (base testável) + restantes atrás de
F5; CSV trilingue; asserts e stress atualizado; AUDIT/GDD. Zero migração
de save (statuses são voláteis por defeito — desaparecem ao recarregar).

## 6. O que preciso de ti para arrancar

1. **Nomes visíveis** das 6 disciplinas — manter os do GDD
   (Cinética/Ígnea/Hídrica/Vital/Lúmina/Umbral) ou abreviar para UI?
2. Qual a **camada**: v1.8 na totalidade ou só as 3 reações núcleo para
   validar o caminho (recomendo as mesmas 3: **Cavitação**, **Despertar do
   Selado**, **Fotoestase**)?
3. GLIFOS de status no HUD (texto/símbolos Unicode) ou apenas nome escrito?
