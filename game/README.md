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
> localmente antes de seguir para a Fase 2.

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

### Controles da cena de demonstração

| Ação | Controle |
|---|---|
| Zonear Residencial | clique esquerdo |
| Demolir (zona + edifício especial) | clique direito |
| Zonear Residencial/Comercial/Industrial/Rua | teclas `1` `2` `3` `4` (no tile sob o mouse) |
| Colocar usina de energia | tecla `P` |
| Colocar estação de água | tecla `U` |
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
