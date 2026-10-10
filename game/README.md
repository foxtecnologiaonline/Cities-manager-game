# game/ — projeto Godot

Projeto Godot 4.x (testado como 4.3+; a engine faz upgrade automático do
`project.godot` ao abrir com uma versão mais nova).

## Como abrir

1. Instale o Godot 4 (https://godotengine.org/download) — Windows/Linux/macOS.
2. Abra este diretório (`game/`) como projeto no Godot Editor.
3. Rode a cena principal (`scenes/Main.tscn`) com F5/F6.

> **Nota:** este esqueleto foi criado em um ambiente de nuvem sem o binário
> do Godot instalado, então ainda **não foi aberto/executado** pelo Claude.
> A primeira verificação (abrir no editor, rodar a cena, confirmar que o
> grid renderiza e responde a clique/drag/zoom) precisa ser feita
> localmente antes de seguir para a Fase 1.

## O que já funciona (Fase 0)

- `core/grid/` — `Tile` e `CityGrid`: grid puro, sem dependência de `Node`,
  testável isoladamente.
- `scenes/Main.tscn` + `scripts/main.gd` — desenha o grid e permite zonear
  células como Residencial com clique esquerdo (botão direito desfaz).
- `scripts/camera.gd` — pan (arrastar com o botão do meio ou toque) e zoom
  (scroll, pinça/gesto de magnificação em trackpad/touch).

## Testes

Os testes em `tests/core/test_city_grid.gd` usam a convenção do addon
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
