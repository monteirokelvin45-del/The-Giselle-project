# Inspiração externa — o que foi estudado e o que entrou no jogo

**Regra deste documento:** nada de assets, dados ou código de terceiros entra
no produto. As referências informam **técnicas, arquitetura e
disciplina de dados**; o que é implementado aqui é original (ou nativo do
Godot). Estilos visuais (cel/toon) são um género — ninguém "possui" um ramp
diffuse; o Genshin Impact é referência de qualidade, não um recurso
extractável.

## O que foi estudado (links e papel de cada um)

### Gráficos — cel/toon shading
| Repo | Estado | O que ensina | O que usámos |
|---|---|---|---|
| [Gaolingx/GenshinCelShaderURP](https://github.com/Gaolingx/GenshinCelShaderURP) | ativo | unlit + Shadow Ramp por banda, ILM maps (Intensity/Light/Metallic por canal), SDF face shading, metal/transmissivo por capa, rim light | **Conceitos**: ramp por bandas e rim light. **Não usável** como está (Unity HLSL/URP; exige ILM/SDF por personagem — KayKit não tem esses mapas) |
| [Delt06/urp-toon-shader](https://github.com/Delt06/urp-toon-shader) | ativo (MIT) | half-lambert, ramp, sombra com bias, rim, outline por inverted hull | **Conceitos**: half-lambert→TOON nativo do Godot; inverted hull **não** adotado (risco de interseção/artefactos em GLES3; ver VISUALS.md) |
| [festivize/Genshin-Blender-Shader](https://github.com/festivize/Genshin-Blender-Shader) | **404 — repo morto** | — | nada |

**Resultado:** `StandardMaterial3D` com `DIFFUSE_TOON` + `SPECULAR_TOON` +
rim (ver `src/visuals/model_factory.gd::apply_cel_look` e `docs/VISUALS.md`).
Construído com recursos nativos do Godot — zero código de terceiros.

### Assets/Engine (estudo de formato — explicitamente "não para produto")
| Repo | Estado | Papel |
|---|---|---|
| [SilentNightSound/GI-Model-Importer](https://github.com/SilentNightSound/GI-Model-Importer) | ativo | estudo dos formatos/fluxos de extração (3dmigoto/XXMI). Confirma que inter-op de assets HoYoverse não é caminho para um produto original; nada importado |
| [zeroruka/GI-Asset](https://github.com/zeroruka/GI-Asset) | **404 — repo morto** | nada |

### Pipeline, dados e APIs
| Repo | Estado | Papel |
|---|---|---|
| [genshindev/api](https://github.com/genshindev/api) | ativo | referência de **disciplina de dados**: schemas JSON limpos, chaves consistentes, i18n por códigos. O nosso `balance.json` e o CSV l10n seguem a mesma disciplina |
| [Dimbreath/GenshinData](https://github.com/Dimbreath/GenshinData) | **404 — repo morto** (e dados de jogo da HoYoverse não são exportáveis) | nada importado, nada procurado em espelhos |
| [seriaati/genshin.py](https://github.com/seriaati/genshin.py) | ativo | referência de ergonomia de cliente de API (tipagem/validação). Não consome nada: o jogo não tem servidor |
| [torikushiii/hoyoverse-api](https://github.com/torikushiii/hoyoverse-api) | ativo | referência de "live-ops" (codes/calendars) — fora do escopo singleplayer |
| [UIGF-org/mihoyo-api-sdk](https://github.com/UIGF-org/mihoyo-api-sdk) | ativo | referência **schema-first** (TypeSpec): contratos moles gerados → adoptado o hábito de manter docs/l10n e docs/l10n/strings_pt.csv como inventários gerados |
| [UIGF-org/UIGF](https://github.com/UIGF-org/UIGF) | **404 — repo morto** | nada (o conceito UIGF = formato portátil de histórico inspirou a ideia de export portátil de métricas — não implementado, ver AUDIT §17) |

## Fronteira legal e criativa
- **Nenhum** asset, textura, modelo, voz, música ou texto de Genshin Impact
  entra no repositório — e nenhum é necessário: o KayKit (CC0) e o conteúdo
  original cobrem tudo.
- **Nenhuma** chamada de rede de/para serviços HoYoverse é feita pelo jogo.
- Homage é **estilo e qualidade-alvo**: mundo aberto com regiões
  distinguíveis, fações com reputação, finais por reputação, companheiros
  com epílogos persistidos — tudo isto já existia no projeto; o Genshin é o
  espelho, não a fonte de conteúdo.
- Os nomes, personagens e lugares de A Academia do Zero são originais.
