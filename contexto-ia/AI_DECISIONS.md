# AI_DECISIONS — widget_nw_embalagens

Somente pedidos e decisões efetivas do usuário. Comportamentos encontrados no fonte, sem origem de aprovação confirmada, ficam em AI_REFERENCES.md.

| Data | Decisão | Origem |
|---|---|---|
| 2026-10-20 | Ao ativar/inativar, substituir visualmente o interruptor por um spinner no mesmo espaço e mantê-lo bloqueado durante a operação. Mostrar a situação confirmada pelo servidor; em falha, restaurar o estado anterior e informar o erro. | Usuário aprovou a ideia 1 e o exemplo apresentado: “Pode seguir”. |
| 2026-10-20 | Usar loading global e toast info também ao Buscar; retirar o toast quando os dados terminarem de carregar. Substitui a limitação anterior ao carregamento inicial. | Pedido do usuário: aplicar o loading global na busca com o toast info do padrão. |
| 2026-10-20 | Aplicar o loading global durante o carregamento inicial da widget, usando a referência de bags estudada na tarefa anterior. Substitui a restrição de apenas aprender quanto a esse fluxo inicial. | Pedido: “Quando a página estiver fazendo o carregamento inicial, deve aplicar o carregamento global”. |
| 2026-10-20 | Estudar na widget_nw_bags o loading global e o toast info para manter o conhecimento no contexto de embalagens; nenhuma aplicação na interface foi solicitada nesta tarefa. | Pedido do usuário nesta sessão, com caminho explícito da widget bags. |
| 2026-10-20 | SEMPRE fazer commit, push e compilar ao concluir tarefas desta widget. Substitui a exigência anterior de pedido pontual para commit/push e autoriza build; manter apresentação prévia e exclusão de referências e alterações alheias. Publicação no Fluig depende de autorização específica. | Pedido explícito nesta sessão: “SEMPRE: Commit, push e compilar”. |
| 2026-10-20 | Adotar o padrão documental de Documentos: AGENTS.md, README e quatro arquivos em contexto-ia/, sem CLAUDE.md local duplicado. | Pedido nesta sessão: “Em documentos, veja o arquivo PADRAO_CONTEXTO_IA_WIDGETS.md - Siga esse padrão na nossa widget embalagens”. |
| 2026-10-20 | Somente o escopo solicitado; commit/push só mediante pedido e apresentação prévia; referências somente leitura; nunca ler .r; respeitar regras Progress; não varrer fora do projeto sem autorização. | Instruções gerais do usuário nesta sessão. |
| 2026-10-07 (registro histórico) | Configuração de TESTE com DefaultGroup-1 liberando consultarTipos, incluirTipo e alterarTipo; escritas de inclusão/alteração habilitadas. | CLAUDE.md anterior atribuía expressamente a definição ao usuário nessa data. O fonte atual ampliou a configuração; este registro não autoriza produção. |

A origem de aprovação da sigla de 3 caracteres, do autocomplete e da exclusão presentes no fonte atual não foi confirmada nesta sessão; não atribuir essas mudanças ao usuário sem evidência.
