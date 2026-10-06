# ET-01I — Apoios limitados de estabelecimento e item

Contrato DT-064, 16/09/2026. Apoios de estabelecimento/item e ampliação de famílias foram compilados no lote vigente; **recorte ABL concluído em TESTE com 30/0 em 17/09 às 17:00; publicação REST/Dataset/homologação integrada pendentes**. Não altera tabelas físicas. Não confundir com a consulta pioneira de CD.

Base: `/dts/datasul-rest/resources/prg/esp/v1/controle-embalagens`.

| GET | Procedure em contr-emb.p | Dados comprovados |
|---|---|---|
| `/apoios/estabelecimentos` | `consultarEstabelecimentos` | mgcad.estabelec.cod-estabel/nome (baseline pi-listar-cds.p) |
| `/apoios/itens` | `consultarItens` | mgcad.item.it-codigo/desc-item/un/tipo-con-est (CE0111 recebido e conversor/cadastros existentes) |

Entradas comuns: `filtro` (2 a 100 caracteres depois de TRIM), `aposCodigo` (cursor exclusivo, até 100 caracteres), `limite` (ausente/0 = 20; 1 a 20; desconhecido/inválido, negativo ou >20 recusado). Código BEGINS ou nome/descrição contendo texto literal; não usar expressão MATCHES do usuário. Ordenar por código. Sem filtro curto não ler o cadastro. Paginação não promete fotografia sob concorrência; ao mudar filtro/permissão, reiniciar cursor.

Contexto: `usuario` obrigatório e `estabelecimentoPermitido` repetido na query, ambos reconstruídos pelo Dataset da sessão/grupos. Lista vazia recusa antes de ler. Para itens, `codEstabel` obrigatório e autorizado; entrega catálogo global de itens, **não saldo, elegibilidade fiscal ou vínculo item-estabelecimento**. Não há inferência de acesso produtivo a partir de parâmetros fornecidos por cliente direto. Grupos/serviço ainda aguardam homologação.

Saída comum: `sucesso`, `codigoErro`, `mensagem`, `total` (somente tamanho da página), `temMais`, `proximoCodigo`, `dados`. Cada opção tem `codigo`, `descricao`; item acrescenta `un`, `tipoControleEstoque`. Teto validado no servidor. Quando houver outra opção autorizada, `temMais=true`, cursor do último retornado; caso contrário cursor vazio. Nunca contar opções de outro estabelecimento como a próxima página. Em erro, descartar qualquer página anterior.

ABL: input TABLE ttEmbEstabelPermitido; itens acrescentam pcEstabel; pcFiltro, pcAposCodigo, piLimite; OUTPUT TABLE ttEmbEstabelecimento/ttEmbItem; plTemMais, pcProximoCodigo, plSucesso, pcErro, pcMensagem. Projeções apenas transitórias em contr-emb.i. O núcleo aplica autorização, validação e consulta; o adaptador apenas traduz JSON.

Erros: SEM_PERMISSAO, FILTRO_INVALIDO, FILTRO_CURTO, LIMITE_INVALIDO, BANCO_MGCAD_NAO_CONECTADO; falha técnica sanitizada no REST. Consulta repetida não grava nem cria evento.

Interface: mínimo 2, debounce 350 ms, limite 20, cancelar por campo, ignorar resposta antiga mesmo que o transporte não aceite cancelamento. Não chamar enquanto dependência/autorização faltar. Seleção guarda código, texto digitado invalida a seleção. Alteração de estabelecimento limpa item e filtros dependentes. Unidade preenchida pelo retorno de item e somente leitura. Estado vazio não é erro; erro conserva o texto e permite repetir. Não persistir cache de permissões.

## Validação e execução futura em TESTE

A fila vigente e os comandos completos estão em [FILA_VALIDACOES_TESTE.md](FILA_VALIDACOES_TESTE.md). O lote DT-072 de 13 fontes já foi compilado com SAVE em `13/0`. Para a seleção de massa ajustada das 15:49, somente `testar-consultar-apoios.p` precisou de nova compilação com SAVE antes de executar seu `.r`. O teste usa o núcleo .r compilado; ensaio em memória antigo não garante que esse r-code foi atualizado. Copiar a pasta ET-01_TESTE completa, sem ZIP ou .r históricos.

O ensaio é somente leitura. Após aprovação, compilar SAVE e publicar núcleo/adaptador da mesma revisão pelos procedimentos existentes, renovar somente PASOE TESTE e provar: 20/21 opções, cursor sem repetição, item e unidade, busca por código e descrição, filtro literal contendo `*`, ausência/forja de autorização, campo dependente, vazio, falha de serviço e resposta fora de ordem no Dataset/Widget. Novo TXT não é substituído por compilação antiga. Não reiniciar Fluig por esta entrega.

## Compilação recebida em 16/09, 17:13

Núcleo, adaptador REST e testar-consultar-apoios.p tiveram OK nominal em compilacao-et05a.txt. Dois erros 468 do total 11/2 eram exclusivos dos fontes ET-01H e passaram no SAVE posterior 5/0. Ainda não recebida execução funcional dos apoios ou validação REST incremental.


## 17/09, 15:26 — ET-01I parcial 25/0

25 casos executados passaram. Positivos de estabelecimento e de tipos/famílias (predicado/limite/repetição, descrição do tipo) e recusas aprovados. Pendentes: CODIGO_ITEM_CURTO (escolha do primeiro cadastro pelo teste; positivos item/unidade/cursor não executados), MASSA_TIPO_SEGUNDA_PAGINA_AUSENTE e MASSA_FAMILIA_SEGUNDA_PAGINA_AUSENTE. Aprovação parcial; não libera REST/Dataset nem cursor sem massa. Evidência docs/entregas/evidencias/validacao_et01i_parcial_2026-09-17.md. Próximo: testar-consultar-etiquetas.r ampliado com dados de impressão, somente leitura. Nenhum fonte alterado; não copiar/recompilar pacote agora.

## 17/09, 17:00 — ET-01I ABL concluído 30/0

O `resultado-apoios-pos-massa-dt074.txt` presente no pacote registra execução posterior ao checkpoint documental das 15:49: `TOTAL=30 FALHAS=0`. Foram aprovados `UNIDADE_DO_ITEM`, `ITEM_LIMITE_1`, `ITEM_REPETICAO`, `ITEM_CURSOR_EXCLUSIVO` e `FAMILIA_CURSOR`, além dos cenários de estabelecimento, tipos, famílias e recusas já cobertos. Evidência preservada em `docs/entregas/evidencias/validacao_et01i_concluido_2026-09-17.md` e no TXT correspondente.

A pendência `CODIGO_ITEM_CURTO` e a falta de cursor de família do ensaio 25/0 ficam resolvidas. A ausência de segunda página de tipos no teste readonly não reabre a paginação: duas páginas de tipos já foram aprovadas pela fixture DT-074. Não houve mudança de `contr-emb.p`, `contr-emb-rastreio.p` ou adaptador REST após o SAVE 13/0; somente o teste ET-01I havia recebido seleção melhor de massa e foi executado em seguida.

**Próximo:** publicar a revisão REST/ABL atual em TESTE, renovar somente o PASOE de TESTE e validar as rotas/JSON/autorização/paginação da revisão corrente. REST, Dataset, identidade/grupos e homologação integrada continuam pendentes. Não repetir ET-01I ou DT-074 sem mudança relevante de fonte.

