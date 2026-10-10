# Cities Manager Game — Escopo Técnico e de Design

> Documento de referência para construir um city-builder **original**, inspirado nas mecânicas clássicas do gênero popularizado por *SimCity 2000* (Maxis/EA, 1993), rodando em Windows 10/11 e mobile (Android/iOS).

## 0. Nota legal importante

*SimCity 2000* é propriedade da Electronic Arts. Não vamos copiar código, assets gráficos/sonoros, textos, nome ou identidade visual do jogo — isso seria infração de direitos autorais e de marca. O que **pode** ser reaproveitado livremente são as **mecânicas de jogo** (zoneamento, oferta/demanda, orçamento municipal, infraestrutura, desastres), que tribunais (ex.: *Tetris Holding v. Xio*, *Incredible Technologies v. Virtual Tech*) tratam como ideias/regras não protegíveis — a proteção recai sobre a expressão específica (arte, código, nomes, sprites).

Precedente útil: em 2008 a própria EA liberou o código do *SimCity* original (1989) como software livre (GPLv3), rebatizado **Micropolis**, hoje referência acadêmica de simulação urbana. Outros projetos 100% open-source no mesmo espírito (sem usar assets da Maxis): **LinCity-NG** (GPLv2, C++/SDL) e **OpenTTD** (clone de Transport Tycoon). Seguiremos esse mesmo caminho: motor de simulação e arte 100% próprios, mecânicas "inspiradas em", nome e identidade visual originais.

**Ação recomendada:** definir já um nome/marca próprios para o projeto (ex.: o nome do repositório "Cities Manager") e não usar "SimCity" em nenhum material de marketing, ícone ou texto do app.

## 1. Mecânicas de referência extraídas (o que vamos reconstruir, com nossa própria implementação)

| Sistema | Como funciona no clássico | Decisão para o nosso jogo |
|---|---|---|
| **Zoneamento RCI** | Jogador não constrói prédios diretamente; zona terrenos como Residencial/Comercial/Industrial. O que nasce ali depende de utilidades (água/energia), serviços e valor do terreno | Mesma lógica: zonas + simulação de crescimento procedural dos lotes |
| **Demanda RCI** | Medidor de oferta/demanda guia o equilíbrio entre R/C/I; proporção ideal muda com a população | Simulação de demanda com fórmula própria balanceável por config (não copiar números do jogo original) |
| **Valor do terreno** | Água, árvores e ausência de poluição aumentam; poluição, crime e falta de serviços reduzem | Grid de "land value" recalculado periodicamente a partir de camadas (poluição, serviços, crime, estética) |
| **Orçamento municipal** | Receita via impostos/aluguel; gasto com construção/manutenção; déficit contínuo = fim de jogo | Sistema de tesouro + taxas ajustáveis por categoria (serviços, infraestrutura) |
| **Utilidades** | Energia (usinas), água, lixo — zonas sem elas não crescem | Rede de grafos (energia/água) com propagação por adjacência de tiles |
| **Transporte** | Ruas, rodovias, trilhos, metrô, aeroportos e portos (zoneados) | Malha viária em grid + pathfinding para tráfego simulado |
| **Serviços públicos** | Polícia, bombeiros, saúde, educação — reduzem crime/incêndio, educam a população | Cobertura por raio de influência sobre o grid |
| **Terraformação** | Ferramentas para elevar/baixar terreno, criar água | Editor de terreno com heightmap editável (pré-jogo e/ou in-game limitado) |
| **Desastres** | Incêndio, enchente, terremoto, tornado, etc.; podem ser ligados/desligados | Sistema de eventos configurável, com toggle de dificuldade |
| **Ordenanças/leis municipais** | Leis que trocam custo por efeito (ex.: imposto turístico, reciclagem) | Lista de políticas ativáveis com custo e efeito nos sistemas acima |
| **Cidades vizinhas** | Conexões comerciais/de recursos entre cidades | Fase futura (pós-MVP): comércio entre save-games/cidades |
| **Evolução dos lotes** | Prédios crescem em estágios conforme densidade/valor | Sprites/variantes por estágio de crescimento (asset próprio) |
| **Overlays de dados** | Mapas de poluição, criminalidade, tráfego, valor do solo | Modos de visualização alternando o shader/coloração do grid |
| **Jornal/eventos** | Feed narrando o que acontece na cidade | Painel de notificações com título original (não copiar marca do "Sim Herald"/"Chronicle") |

## 2. Arquitetura técnica recomendada

**Motor:** Godot 4.x (GDScript/C#)
- MIT license, sem royalties, exporta nativamente para Windows, Android e iOS a partir de um único projeto.
- 2D performático o suficiente para grid isométrico/top-down com milhares de tiles; se a escala exigir mais, dá para usar `MultiMeshInstance2D`/tilemaps otimizados em vez de 1 nó por tile.
- Alternativa avaliada e descartada para MVP: Unity (mais pesado para exportar iOS/Android com menos atrito de licenciamento open-source) — manter como plano B se precisar de recursos 3D avançados depois.

**Estrutura em camadas (separação essencial para rodar bem em mobile):**
1. **Simulation core** (puro, sem engine) — grid de tiles, RCI, utilidades, orçamento, tráfego. Roda em "ticks" discretos, desacoplado de FPS/renderização, para permitir testes automatizados e futura reescrita de performance.
2. **Render/View layer** — TileMap/sprites, overlays de dados, câmera (pan/zoom).
3. **UI layer** — HUD, painéis de orçamento, ferramentas de construção, menus — adaptada por *input method* (mouse+teclado vs. touch).
4. **Persistência** — save/load em formato próprio (JSON ou binário versionado), independente de qualquer formato `.sc2` do jogo original.

## 3. Adaptações específicas para mobile (Android/iOS)

- Controles touch: pan com um dedo, zoom com pinça, toolbar colapsável/radial em vez de barra lateral fixa de desktop.
- UI responsiva por breakpoint de tela (phone vs tablet vs desktop), não apenas escalada.
- Orçamento de performance mais apertado: limitar tiles simulados simultaneamente, usar LOD de simulação (áreas fora da tela atualizam com menor frequência).
- Save autosave em nuvem opcional (mobile tende a ter sessões mais curtas/interrompidas).
- Monetização/distribuição ficam fora de escopo técnico aqui — decidir separadamente (gratuito, pago, ou freemium) antes de publicar nas lojas.

## 4. Estrutura de repositório proposta

```
/
├── docs/                  # este documento e specs futuras
├── game/                  # projeto Godot (project.godot na raiz desta pasta)
│   ├── core/              # simulation core: classes RefCounted puras
│   │   └── grid/          # (sem extends Node, sem scene tree), testável
│   │       ├── tile.gd    # isoladamente — mas PRECISA estar dentro de
│   │       └── city_grid.gd  # res://, pois o Godot só carrega scripts do
│   │                          # próprio diretório do projeto
│   ├── scenes/
│   ├── scripts/           # camada de render/input (usa core/ internamente)
│   ├── assets/            # arte 100% original
│   ├── tests/             # testes do core (GUT), também dentro de res://
│   └── export_presets.cfg # gerado localmente, não versionado (.gitignore)
└── tools/                 # scripts de build/export (Windows/Android/iOS)
```

> **Correção em relação à primeira versão deste documento:** aqui descrevíamos
> `core/` como pasta-irmã de `game/`, fora do projeto Godot. Na prática o
> Godot só carrega scripts dentro do diretório do projeto (`res://`), então
> `core/` foi movido para `game/core/`. "Sem dependência de engine" continua
> valendo no sentido que importa: são classes `RefCounted`, sem `extends Node`
> nem acesso à scene tree, então são testáveis isoladamente (via GUT) mesmo
> morando dentro da pasta do projeto.

## 5. Roadmap faseado

**Fase 0 — Fundação (1–2 semanas)**
- Setup do projeto Godot + export presets para as 3 plataformas.
- Core do grid de tiles + câmera pan/zoom (desktop e touch).
- Pipeline de build automatizado (Windows .exe, Android .apk/.aab; iOS requer macOS/Xcode — avaliar CI com runner macOS).

**Fase 1 — MVP de simulação (4–6 semanas)**
- [x] Zoneamento R/C/I, crescimento básico de lotes.
- [x] Energia e água como pré-requisito de crescimento (flood-fill simplificado; linhas/canos reais ficam para a Fase 2).
- [x] Orçamento simples (impostos + manutenção) com condição de derrota por déficit.
- [x] Malha viária básica (ruas) conectando zonas a serviços (checagem de adjacência; pathfinding/tráfego real também fica para a Fase 2).
- [x] Save/load (JSON próprio em `user://saves/`).
- [ ] **Pendente:** validar tudo isso abrindo o projeto no Godot Editor (não há binário do Godot no ambiente de nuvem usado para escrever o código) — ver `game/README.md`.
- [ ] **Pendente:** UI de ferramentas de construção (hoje é só clique + hotkeys de demonstração).

**Fase 2 — Profundidade de simulação (6–8 semanas)**
- Serviços (polícia/bombeiros/saúde/educação) com raio de cobertura.
- Valor do terreno + overlays de dados (poluição, criminalidade, tráfego).
- Transporte avançado (rodovias, trilhos, metrô) com simulação de tráfego.
- Terraformação.

**Fase 3 — Conteúdo e eventos (4–6 semanas)**
- Desastres configuráveis.
- Ordenanças municipais.
- Edifícios especiais (aeroporto, porto, marcos de população).
- Jornal/painel de eventos narrando a cidade.

**Fase 4 — Polimento multiplataforma (contínuo)**
- UI touch dedicada para mobile, testes em dispositivos reais.
- Otimização de performance (LOD de simulação, pooling de nós).
- Acessibilidade, localização (pt-BR/en), tutorial.

## 6. Riscos e mitigação

- **Performance em mobile com grids grandes** → simular em "chunks" e atualizar fora-de-tela com frequência reduzida.
- **Scope creep comparando feature a feature com o jogo original** → cada mecânica entra no roadmap só quando o MVP da fase anterior estiver jogável; manter números/fórmulas próprios em vez de tentar replicar exatamente o balanceamento do clássico.
- **Exportação iOS** → exige macOS/Xcode para assinatura e build; planejar acesso a um Mac (físico, cloud CI como GitHub Actions `macos-latest`, ou serviço de build Godot) desde a Fase 0.
- **Risco de IP** → manter checklist: nenhum asset, texto, música ou nome extraído do jogo original entra no repositório; toda arte e nomenclatura são criadas do zero.

## 7. Próximos passos imediatos

1. Confirmar motor (Godot 4) e criar o esqueleto do projeto em `game/`.
2. Implementar o `core/grid` com testes unitários (estrutura de tile, adjacência).
3. Prototipar zoneamento + crescimento R/C/I mínimo (Fase 1) antes de qualquer arte definitiva.
