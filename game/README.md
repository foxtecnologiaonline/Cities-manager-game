# game/ — projeto Godot

Projeto Godot 4.x (testado como 4.3+; a engine faz upgrade automático do
`project.godot` ao abrir com uma versão mais nova).

## Como abrir

1. Instale o Godot 4 (https://godotengine.org/download) — Windows/Linux/macOS.
2. Abra este diretório (`game/`) como projeto no Godot Editor.
3. Rode a cena principal (`scenes/Main.tscn`) com F5/F6.

> **Nota:** este esqueleto foi criado em um ambiente de nuvem sem o binário
> do Godot instalado, então ainda **não foi aberto/executado** pelo Claude —
> todo o GDScript abaixo foi escrito e revisado manualmente, sem rodar no
> editor. A primeira verificação (abrir no editor, rodar a cena, confirmar
> que o grid renderiza, cresce e responde aos controles) precisa ser feita
> localmente antes de seguir para a Fase 4.

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

### Controles da cena de demonstração

| Ação | Controle |
|---|---|
| Zonear Residencial | clique esquerdo |
| Demolir (zona + edifício especial) | clique direito |
| Zonear Residencial/Comercial/Industrial/Rua/Rodovia/Trilho/Metrô | teclas `1`–`7` (no tile sob o mouse) |
| Colocar usina de energia / estação de água | `P` / `U` |
| Colocar polícia / bombeiros / hospital / escola | `K` / `F` / `H` / `O` |
| Colocar aeroporto / porto (exige marco de população) | `A` / `E` |
| Criar ou remover água (terraformação) | `8` |
| Subir / descer elevação | `9` / `0` |
| Ligar/desligar ordenança (Patrulha/Reciclagem/Turismo/Educação) | `Ctrl` + `1`–`4` |
| Ligar/desligar desastres aleatórios | `N` |
| Disparar um desastre aleatório agora | `M` |
| Alternar overlay de dados | `TAB` |
| Salvar / Carregar | `F5` / `F9` |
| Pan / Zoom da câmera | arrastar botão do meio ou toque / scroll ou pinça |

> Isso é uma cena de prova de conceito, não a UI final — ferramentas de
> construção com toolbar/touch dedicados entram na Fase 1 avançada /
> Fase 4 (polimento mobile) do roadmap em `docs/GAME_SCOPE.md`.

## Testes

Os testes em `tests/core/` usam a convenção do addon
[GUT](https://github.com/bitwes/Gut) (não incluído no repositório). Para
rodá-los:

1. No Editor, abra o AssetLib e instale "Gut" (ou adicione como submódulo
   git em `addons/gut`).
2. Ative o plugin em Project Settings → Plugins.
3. Rode via painel do GUT no editor, ou via linha de comando:
   ```
   godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs
   ```

## Build/export

`export_presets.cfg` é gerado localmente (Project → Export) e está no
`.gitignore` — não deve ser versionado porque normalmente referencia
caminhos de keystore/certificados de assinatura específicos da máquina.
Exportação para iOS exige macOS + Xcode instalados (ou um runner macOS em
CI); isso ainda não está configurado (ver `docs/GAME_SCOPE.md`, risco de
exportação iOS).
