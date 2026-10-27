# Decisões do usuário — widget_nw_embalagens

> Decisões e correções do usuário. Acrescentar no topo (mais recente primeiro), com data e origem.
> Só registrar o que o usuário decidiu ou pediu. Proposta não aprovada vai para `pendencias.md`.
> Comportamento encontrado no fonte, sem aprovação confirmada, fica em `referencias-backend.md` ou `tela-e-codigo.md`.

## Dados e regras
| Data | Decisão | Origem |
|---|---|---|
| 19/10 | O `dsNwEmbalagens` publicado no Fluig é sempre o do GitHub `BP-NW-DATASET` (registrado no `widget_nw_bags`) | Usuário |
| 07/10 (histórico) | Configuração de TESTE com `DefaultGroup-1` liberando `consultarTipos`, `incluirTipo` e `alterarTipo`; escritas de inclusão/alteração habilitadas. O fonte atual ampliou a configuração; não autoriza produção | `CLAUDE.md` anterior atribuía ao usuário |

A origem de aprovação da sigla de 3 caracteres, do autocomplete e da exclusão presentes no fonte não foi confirmada: não atribuir essas mudanças ao usuário sem evidência.

## Tela e comportamento
| Data | Decisão | Origem |
|---|---|---|
| 27/10 | A tabela não consulta ao abrir a tela: fica vazia até o usuário clicar em Buscar. O overlay inicial cobre só a espera do Tabulator | "Retire esse carregamento inicial da tabela, o usuário vai ter que buscar" |
| 27/10 | A tabela vazia ao abrir mantém o texto "Nenhum tipo de embalagem encontrado." (proposta de trocar por "Clique em Buscar..." recusada) | "Não, deixe do jeito que está" |
| 20/10 | Ao ativar/inativar, o interruptor vira um spinner no mesmo espaço e fica bloqueado durante a operação. Mostra a situação confirmada pelo servidor; em falha, restaura o estado anterior e informa o erro | Usuário aprovou a ideia 1 e o exemplo: "Pode seguir"; `077378f` |
| 20/10 | Loading global e toast info também ao Buscar; o toast sai quando os dados terminam de carregar (substitui a limitação ao carregamento inicial) | Pedido do usuário; `1f0ec9c` |
| 20/10 | Loading global no carregamento inicial da widget, no padrão do `widget_nw_bags` | "Quando a página estiver fazendo o carregamento inicial, deve aplicar o carregamento global"; `3bf6ce3` |

## Forma de trabalho
| Data | Decisão | Origem |
|---|---|---|
| 21/10 | Skill `fluig-branco-peres` local em `.claude/skills/` de cada um dos 4 widgets (sem cópia global); `.claude/` inteira no git; mesma organização (`AGENTS.md`, `docs/`, `scripts/entregar.ps1`) nos 4 widgets | Usuário |
| 21/10 | Regras do widget no `AGENTS.md`; o `CLAUDE.md` só importa (`@AGENTS.md`). `contexto-ia/` vira `docs/` (decisoes, pendencias, referencias-backend, tela-e-codigo); `AI_HANDOFF` removido; atualizar só o arquivo afetado. Substitui o padrão de 20/10 (`contexto-ia/`, sem `CLAUDE.md` local) | Usuário |
| 20/10 | **Mensagem de commit sempre com prefixo:** `DOCS: Texto`, `FIX: Texto`, `CHORE: Texto` (decisão registrada no `widget_nw_bags`, aplicada aos 4) | Usuário |
| 20/10 | **SEMPRE commit + push + compilar** ao concluir tarefas; commit só do escopo da entrega, preservando alterações alheias. Publicação no Fluig depende de autorização específica | "SEMPRE: Commit, push e compilar" |
| 20/10 | Somente o escopo solicitado; referências somente leitura; nunca ler `.r`; respeitar regras Progress; não varrer fora do projeto sem autorização | Instruções gerais do usuário |
