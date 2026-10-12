# game/ — projeto Godot

Projeto Godot 4.x. **Validado headless com Godot 4.6.0** (binário baixado
e executado nesta própria sessão de nuvem — não é mais só revisão manual
de código): projeto importa sem erro, todos os 70 testes GUT passam, e a
cena principal roda vários ticks de simulação (incluindo desastres) sem
erro em runtime. Detalhes e o que ainda falta validar na seção "Testes"
abaixo e em `docs/GAME_SCOPE.md`.

## Como abrir

1. Instale o Godot 4.6+ (https://godotengine.org/download) — Windows/Linux/macOS.
2. Abra este diretório (`game/`) como projeto no Godot Editor.
3. Rode a cena principal (`scenes/Main.tscn`) com F5/F6.

> **Nota sobre a primeira vez que abrir:** se aparecerem erros tipo "Could
> not find type X in the current scope" na primeira importação, é um
> comportamento conhecido do Godot ao escanear muitos scripts com
> `class_name` de uma vez só (o cache global de classes às vezes precisa
> de duas passadas). Feche e abra o projeto de novo (ou rode
> `godot --headless --editor --path . --quit` duas vezes) — na segunda
> passagem os erros desaparecem. Isso aconteceu e se resolveu exatamente
> assim durante a validação desta sessão.

> **O que ainda não foi testado:** interação real de mouse/touch na janela
> (a validação aqui foi 100% headless, sem display) e dispositivos móveis
> de verdade. Abra e clique/toque na toolbar para confirmar visualmente —
> a lógica por trás já está validada, falta o "sentir" da interação.

## O que já funciona

**Fase 0 — fundação**
- `core/grid/` — `Tile` e `CityGrid`: grid puro, sem dependência de `Node`,
  testável isoladamente.
- `scripts/camera.gd` — pan (arrastar com o botão do meio ou toque) e zoom
  (scroll, pinça/gesto de magnificação em trackpad/touch).

**Fase 1 — MVP de simulação**
- `core/utilities/utility_network.gd` — energia e água se propagam por
  flood-fill a partir de usinas/estações, sem atravessar água (ainda sem
  linhas/canos — isso é simplificação deliberada da Fase 1).
- `core/simulation/rci_demand.gd` — fórmula própria (não é a do jogo
  original) de demanda Residencial/Comercial/Industrial a partir de
  população e empregos.
- `core/simulation/city_simulation.gd` — orquestra um "tick" (1 mês):
  atualiza utilidades, calcula demanda, cresce/encolhe zonas servidas e
  conectadas a uma rua, roda o orçamento.
- `core/economy/budget.gd` — receita de impostos por população/empregos
  menos manutenção de ruas e edifícios especiais; derrota por déficit
  (`BANKRUPTCY_THRESHOLD`).
- `core/save/save_game.gd` — save/load em JSON próprio, gravado em
  `user://saves/` (caminho correto e gravável em Windows/Android/iOS).
- `scenes/Main.tscn` + `scripts/main.gd` — cena de demonstração: desenha o
  grid, roda a simulação a cada 2s (1 "mês"), e mostra HUD com mês, caixa e
  demanda.

**Fase 2 — profundidade de simulação**
- `core/services/service_coverage.gd` — polícia/bombeiros/saúde/educação
  projetam um raio de cobertura (mecânica clássica do gênero, com nossos
  próprios números) sobre `police_coverage`/`fire_coverage`/
  `health_coverage`/`education_coverage` em cada tile.
- `core/simulation/pollution_calculator.gd` — industrial com crescimento
  emite poluição com queda por distância, acumulando entre poluidores.
- `core/simulation/crime_calculator.gd` — criminalidade cresce com
  densidade populacional e poluição, e é suprimida pela cobertura policial.
- `core/simulation/land_value_calculator.gd` — valor do terreno real:
  bônus por água/polícia/saúde, penalidade por poluição/criminalidade.
  **Já realimenta o crescimento:** zonas com valor do terreno baixo
  encolhem mesmo com demanda positiva (`CitySimulation.MIN_DESIRABLE_LAND_VALUE`).
- `core/simulation/traffic_estimator.gd` — **heurística**, não é
  simulação de tráfego real: estima carga de cada tile de transporte pela
  soma de população+empregos dos vizinhos diretos. Pathfinding/roteamento
  de verdade fica para uma passada futura.
- Novos tipos de zona `HIGHWAY`/`RAIL`/`SUBWAY` (todos contam como acesso a
  transporte para crescimento) e terraformação básica
  (`CityGrid.terraform_set_water`, `raise_elevation`, `lower_elevation`).
- Overlays de dados na cena de demonstração (tecla `TAB`): Zonas → Valor do
  terreno → Poluição → Criminalidade → Tráfego.

**Fase 3 — conteúdo e eventos**
- `core/events/disaster_manager.gd` — incêndio, enchente, tornado e
  terremoto (conjunto genérico do gênero, textos/números próprios).
  Dispara aleatoriamente por mês (configurável/desligável) ou manualmente.
  A **enchente usa a elevação do terreno** da Fase 2 como defesa real: só
  destrói tiles baixos perto de água — primeiro uso de `elevation` no
  jogo.
- `core/economy/ordinance_manager.gd` — 4 ordenanças municipais (Patrulha
  Extra, Reciclagem, Imposto Turístico, Educação Gratuita), cada uma com
  custo mensal e efeito próprio sobre cobertura policial, poluição ou
  receita.
- `core/milestones/population_milestones.gd` — aeroporto e porto como
  edifícios especiais liberados por marco de população (porto também
  exige adjacência a água).
- `core/news/news_feed.gd` — jornal/log de eventos (desastres, marcos
  atingidos), mostrado no HUD da cena de demonstração.
- `education_coverage` (calculado desde a Fase 2 mas não usado até aqui)
  passou a reduzir criminalidade em `crime_calculator.gd`.
- `core/save/save_game.gd` — formato v2: agora inclui ordenanças, estado
  de desastres e jornal; saves v1 continuam carregando (campos novos
  usam valores padrão).

**Fase 4 — polimento multiplataforma**
- `scripts/toolbar.gd` — toolbar inferior com rolagem horizontal, um
  botão por ferramenta (estilo rádio via `ButtonGroup`), construída em
  runtime a partir de uma tabela de dados. Alvos de toque de 96×56px
  (acima do mínimo recomendado de 44×44pt/48×48dp).
- **Correção de um gap real:** antes, a cena só reagia a
  `InputEventMouseButton`/`InputEventKey` — um toque real em touchscreen
  gera `InputEventScreenTouch`/`InputEventScreenDrag`, então **construir
  por toque não funcionava de fato em mobile**. Agora `scripts/main.gd`
  trata os dois (mouse e toque) de forma unificada, distinguindo
  toque/clique de arrasto pela distância percorrida
  (`TAP_MOVE_THRESHOLD`), e converte posição de tela para tile via
  `Viewport.canvas_transform` em vez de `get_global_mouse_position()`
  (que não existe para toque puro).
- Acessibilidade: paleta dos overlays de dados trocada de verde/vermelho
  para azul/âmbar — verde/vermelho é a pior combinação possível para
  daltonismo vermelho-verde (a forma mais comum).
- `localization/strings.csv` — esqueleto de localização: a primeira
  coluna (`keys`) é o próprio texto em pt-BR usado como chave de
  tradução, e a coluna `en` traz a versão em inglês. Os botões da
  toolbar já chamam `tr(label)`, então **funcionam em pt-BR imediatamente
  sem nenhuma importação** (é o texto padrão quando não há tradução
  carregada). Para habilitar o inglês: abra o projeto no Godot, selecione
  `localization/strings.csv` no FileSystem (o importador de CSV gera os
  `.translation` por idioma), depois adicione-os em Project Settings →
  Localization → Translations. **Isso não pode ser feito sem o editor**,
  por isso não foi feito aqui.
- `scripts/tutorial_hint.gd` — painel de onboarding mínimo (uma
  mensagem, um botão "Entendi"), não um tutorial multi-etapas.
- **Decisão deliberada:** nenhuma otimização de performance (LOD de
  simulação, pooling de nós) foi feita nesta fase. Otimizar sem medir é
  especulação, e não há como medir sem abrir o projeto. Primeiro valide
  e colete métricas reais; otimize depois, com dados.

### Controles da cena de demonstração

A maior parte das ações agora passa pela toolbar inferior (clique ou
toque num botão para selecionar a ferramenta, depois toque/clique no
mapa para aplicá-la). O que não tem botão na toolbar continua em
teclado, só para debug/demonstração:

| Ação | Controle |
|---|---|
| Selecionar ferramenta (zonear, demolir, serviços, aeroporto/porto, terraformação) | toolbar inferior |
| Aplicar a ferramenta selecionada no tile sob o cursor/dedo | toque ou clique esquerdo (sem arrastar) |
| Demolir rápido (atalho de desktop) | clique direito |
| Ligar/desligar ordenança (Patrulha/Reciclagem/Turismo/Educação) | `Ctrl` + `1`–`4` |
| Ligar/desligar desastres aleatórios | `N` |
| Disparar um desastre aleatório agora | `M` |
| Alternar overlay de dados | `TAB` |
| Salvar / Carregar | `F5` / `F9` |
| Pan / Zoom da câmera | arrastar botão do meio ou toque / scroll ou pinça |

> Isso ainda é uma cena de prova de conceito, não a UI final de produção
> (sem ícones, sem tema visual) — mas a interação (toolbar + tap, mouse e
> touch tratados da mesma forma) já é a real, não um placeholder.

## Testes

O addon [GUT](https://github.com/bitwes/Gut) (MIT, v9.6.1) está incluído
em `addons/gut/` — não precisa instalar nada. Rode:

```
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

(a partir de dentro de `game/`, ou adicione `--path game` se rodar de
outro diretório). `-gexit` fecha o processo automaticamente ao terminar —
sem ele, o runner headless pode ficar parado depois do último teste.

**Resultado da última validação (Godot 4.6.0 + GUT 9.6.1, headless,
nesta sessão):**

```
Scripts              16
Tests                70
Passing Tests        70
Asserts             134
---- All tests passed! ----
```

Um bug real foi encontrado e corrigido durante essa validação:
`scripts/camera.gd` fazia `var delta := (event.position - ...)` dentro de
um `elif event is InputEventMouseMotion and _dragging:` — o Godot não
restringe (narrows) o tipo de `event` quando o `is` vem combinado com
`and`, então `event.position` ficava sem tipo inferível e o script
simplesmente não carregava ("Cannot infer the type of 'delta' variable").
Corrigido com um cast explícito (`event as InputEventMouseMotion`). Esse
era exatamente o tipo de erro que só aparece ao rodar o projeto — nenhuma
revisão manual de código o teria pego.

Também foi confirmado que a cena principal roda de verdade: vários ticks
de simulação (orçamento, desastres com a chance aleatória de 5% ativa,
etc.) ao longo de ~12s headless, sem nenhum erro ou warning no log.

## Build/export

`export_presets.cfg` é gerado localmente (Project → Export) e está no
`.gitignore` — não deve ser versionado porque normalmente referencia
caminhos de keystore/certificados de assinatura específicos da máquina.
Exportação para iOS exige macOS + Xcode instalados (ou um runner macOS em
CI); isso ainda não está configurado (ver `docs/GAME_SCOPE.md`, risco de
exportação iOS).
