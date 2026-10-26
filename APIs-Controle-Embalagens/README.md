# APIs Controle de Embalagens

Entrega de referência de 20/10/2026 para revisão do Humberto.

## Organização

- `fontes/progress/`: fontes `.p`, `.i` e o include `.i1` atual, mantendo a estrutura de caminhos do projeto.

Os fontes Progress são a cópia física local atual para investigar rotas, parâmetros, assinaturas e regras. Esta inclusão no Git não comprova que todos correspondam aos binários publicados e não indica nova compilação, carga de banco ou instalação automática. As rotinas em `database/` são fontes de manutenção já existentes, não etapas para publicar a tela.

## Tela Documentos de recebimento

Acompanha documentos desde sua criação no RE1001, inclusive sem estoque atualizado e sem embalagens. Somente consulta: filtros por fazenda autorizada/período, paginação e detalhe em abas Itens e Embalagens, com rateios/lotes/validades e participação histórica por ciclo. Não soma ciclos compensados nem substitui quantidade recebida por saldo atual. Estoque não atualizado não significa cancelamento ou erro.

O widget `widget_nw_recebimentos` foi retirado deste repositório em 26/10/2026 (fica só a tela de tipos); os fontes dele estão no histórico do git (commit `b26b5f5`).

O widget utiliza o `dsNwEmbalagens` aprovado, já existente na branch. Não altera o Dataset, grupos, serviço configurado ou arquivos atuais da raiz do repositório. Conferir estas ações:

| Ação Dataset | REST | Parâmetros principais |
|---|---|---|
| `apoiarEstabelecimentos` | GET `/apoios/estabelecimentos` | filtro, limite, aposCodigo |
| `consultarRecebimentos` | GET `/recebimentos` | codEstabel, dataIni, dataFim, tipoData, emitente, serie, numero, natureza, item, etiqueta, atualizado, somenteComEmbalagens, limite, aposDocumento |
| `consultarItensRecebimento` | GET `/recebimentos/itens` | codEstabel, emitente, serie, numero, natureza, idEvento, limite, aposSequencia |
| `consultarEmbalagensRecebimento` | GET `/recebimentos/embalagens` | codEstabel, emitente, serie, numero, natureza, idEvento, sequencia, limite, aposId |

Uma chamada por página, sem retry automático. Dataset recebe `acao` e `parametros` JSON e devolve uma linha com `resultadoJson`. A identidade/autorização é reconstruída pelo Dataset; não aceitar usuário ou fazendas permitidas enviados pelo widget. Os detalhes também exigem autorização.

## Onde investigar as chamadas

- Rotas e métodos: `fontes/progress/esp/api/v1/controle-embalagens.p`.
- Parser e campos das consultas de recebimento: handlers das rotas `/recebimentos`, `/recebimentos/itens` e `/recebimentos/embalagens` no adaptador.
- Implementação e validações dos documentos/itens/embalagens: `fontes/progress/contr-emb-recebimentos.p`.
- Filtros compartilhados da manutenção: `fontes/progress/includes/contr-emb-manutencao-consulta.i`.
- Demais ações: núcleos `.p` e includes `fontes/progress/includes/contr-emb-api-*.i`, conforme o include/handler declarado no adaptador.
- Includes padrão do Datasul/ut-api e demais dependências licenciadas continuam sendo fornecidos pela instalação do cliente. Não há runtimes `.r` nesta entrega.

## XML: fora do escopo atual

XMLs serão acompanhados no próprio ANFe. A tela de recebimentos não usa as rotas XML e não depende de diretórios ou da localização do ANFe. Os fontes atuais incluem `contr-emb-xml.p`, `contr-emb-api-xml.i` e duas rotas GET `/xmls` e `/xmls/detalhe` preparadas, agora suspensas e sem aceite integrado/publicação. Foram preservados nesta cópia fiel para referência, não como funcionalidade liberada. Não incluir o widget XML nem ampliar o Dataset por esta entrega.

## Validação

39 testes locais da tela aprovados em 19/10/2026, com respostas ERP simuladas e navegador isolado. Isso não equivale à homologação no Fluig. As três consultas DT119 já possuem evidências nativas/REST anteriores. Fontes da tela idênticos aos aprovados localmente; não foram alterados nesta entrega.

Após publicar no TESTE, conferir com dados existentes:

1. Fazenda autorizada e recusa de acesso direto aos detalhes de outra fazenda.
2. Documento com estoque não atualizado e documento sem embalagens.
3. Abas Itens/Embalagens, todos os rateios e quantidades históricas.
4. Ciclos compensados sem duplicar quantidades.
5. Paginação, troca de filtros, vazio e erro.

Publicação/homologação ficam com Humberto. Nenhuma alteração de `main`, merge, execução no ERP ou publicação no Fluig é realizada por este commit.
