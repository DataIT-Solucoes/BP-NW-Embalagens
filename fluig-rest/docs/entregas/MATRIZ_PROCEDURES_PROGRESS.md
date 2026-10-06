**04/10, 19:37 — DT-101/FT4012: criação do retorno aprovada.** SAVE 2/0 confirmado no TXT às 19:37:37; criação às 19:37:53 retornou WT 493002/operação 27, origem 11301/9321/1/0019559/1949OE, natureza 5949EM, etiquetas 151/161. Duas linhas de 10 LT, lotes 01102025-2/31-12-2032 e 01102026-3/31-12-2033, INS, local vazio, preservados. Repetição manteve WT/operação; divergência recusada com CHAVE_IDEMPOTENTE_DIVERGENTE; persistência aprovada/FALHAS=0. Tela FT4003 confirma WT/data/natureza/itens. Sem nota/efeito/reversão do retorno ainda comprovados. Próximo: leitura de operação 27 antes/depois de efetivar somente WT 493002; complementar operação 25 para estoque/terceiros em ambos os estabelecimentos (retorno guarda contraparte e id-oper-origem, mas cod-estabel-dest não é preenchido neste contrato). Não repetir criação/recebimento/compra/remessa, copiar ou recompilar. Evidências docs/entregas/evidencias/e12-retorno-falha-20261004/resultado-retorno-20261004-193753.txt e compilacao-retorno-20261004-193737.txt. Históricos abaixo podem estar desatualizados.

**04/10, 19:09 — DT-101: causa do retorno identificada, correção preparada.** Erro ABL 5363 comprovou incompatibilidade de tt-it-terc-nf com a BO instalada; não identifica o campo divergente nem é prova de saldo insuficiente. FT4012 agora recebe o schema completo da BO por OUTPUT TABLE-HANDLE inicialmente ?, valida os campos utilizados, seleciona por chave completa/linha e devolve a mesma tabela por INPUT TABLE-HANDLE. Objetos liberados no FINALLY; FT4011 preservado. Novo SAVE/execução pendentes: copiar pacote completo, compilar-retorno-save.p 2/0 e repetir somente a criação do retorno 11301/9321/1/0019559/1949OE, etiquetas 151/161. Chegada 221/223 permanece aprovada; retorno ainda sem WT/efeito aprovado. Roteiro docs/entregas/E12_DIAGNOSTICO_RETORNO_FT4012.md. Histórico abaixo pode estar desatualizado.

**04/10 — retorno FT4012 bloqueado na consulta da BO; diagnóstico preparado.** Entrada 11301/9321/1/0019559/1949OE e etiquetas 151/161 continuam com chegada aprovada (221/223, movimentos 241/243). SAVE anterior 14/0 confirmado pelo TXT. Tentativa de retorno às 18:26 falhou em geraItensTerceirosTtItTercNf sem mensagem interna útil; isso não comprova saldo insuficiente. Preparada captura ABL/RowErrors antes do UNDO e observação de WT residual no executor, sem remover validação nativa. Copiar pacote completo e executar testes/e12/compilar-retorno-save.p, exigir 2/0; depois somente a criação do retorno, sem repetir recebimento/compra/remessa. UPCs inalteradas. Causa nativa e efeito do retorno ainda pendentes. Roteiro docs/entregas/E12_DIAGNOSTICO_RETORNO_FT4012.md. Históricos abaixo podem estar desatualizados.

# Matriz prática de procedures Progress

**02/10, E11/DT-097:** registrarSelecaoRemessaAposWt/vincularNotaSaidaFluig/processarNotaFt2100 preparados para remessa de terceiros tipo 3, incluindo validação da contraparte, TERCEIRO e execução/reversão do cabeçalho. SAVE 8/0 e efeitos ainda pendentes; leitura de saldo-terc inclui doc/linha. Não significa entrada/retorno de empréstimo implementados. E09/E10 mantêm evidências anteriores, sem repetição.

**02/10 12:08 — E10 validado no cenário:** vínculo de nota e processarNotaFt2100 com DEVOLUCAO_COMPRA passaram saída/reversão/reatualização na mesma nota 0019558, eventos 203/205/207/209, duas etiquetas e estoque consolidado coerente. Preparação E09 e ciclo E10 não devem ser repetidos sem mudança relevante. Remessa/retorno de empréstimo e REST mutante permanecem pendentes. Evidência resultado-ciclo-devolucao-compra-e10-20261002-120853.txt.

**02/10, E10/DT-096:** E09 criarWtDevolucao aprovado (WT 492998/operação 23, FALHAS=0). vincularNotaSaidaFluig/processarNotaFt2100 ampliados para DEVOLUCAO_COMPRA NFD, sem mudança de assinatura ou REST; log e consulta readonly de ciclos/saldos preparados. Novo SAVE 7/0 e efeitos nativos pendentes; não marcar ciclo como validado antes das evidências. registrarSelecaoRemessaAposWt segue sem ensaio positivo/efeito de empréstimo.

**Atualizada em:** 22/09/2026  
**Objetivo:** mostrar o que existe, o que pode ser desenvolvido com as definições atuais e o que ainda depende de regra. Esta matriz organiza procedures internas dentro dos três módulos de negócio aprovados pela DT-046. A DT-059 acrescenta `contr-emb-conversao.p` como serviço técnico isolado devido ao risco e à abrangência da conversão padrão; ele não cria outro CRUD ou módulo funcional.

## Como ler

- **Concluída:** fonte existente, compilada no OpenEdge 12.2 de TESTE e coberta pelo recorte de testes indicado.
- **Sim, próximo lote:** não depende de nova regra de negócio; falta fechar apenas o contrato técnico de entrada/saída e criar os testes com massa controlada.
- **Parcial:** uma parte pura ou somente leitura pode avançar, mas a operação completa ainda está bloqueada.
- **Não ainda:** a gravação ou o efeito operacional depende de decisão de negócio, integração ou mecanismo transversal ainda aberto.
- Nomes sem implementação são **nomes de trabalho**. O contrato deve ser registrado no catálogo antes do código.
- Pela DT-048, cada procedure posterior à entrada deve preservar uma funcionalidade vigente ou automatizar uma lacuna comprovada. A criação da entrada por Fluig/REAPI não será portada, pois foi substituída pelo ANFE/Datasul.
- O legado é uma base de comportamento e integração. A mudança para REST e para os novos cadastros exige contrato novo ou adequação substancial de praticamente todas as procedures; paridade funcional não significa copiar o ABL anterior.
- O estado por método/recurso REST é acompanhado em [`MATRIZ_APIS_REST.md`](MATRIZ_APIS_REST.md). Ao acrescentar uma ação no adaptador, atualizar as duas matrizes no mesmo checkpoint.
- Pela DT-077/078/079, esta matriz conta **54 capacidades `CUSTOM_BACKEND`**: 20 implementadas e validadas, 34 ainda sem fonte concluído. `DATASUL_STANDARD`, 6 `UPC_HOOK`, 3 `STANDARD_BO_CALL`, 36 capacidades `REST_API`, UI/Dataset e externos são acompanhados separadamente em [`MATRIZ_GATILHOS_DATASUL.md`](MATRIZ_GATILHOS_DATASUL.md).
- Procedures de recebimento e operação abaixo significam classificar, correlacionar, selecionar/ratear, chamar/controlar BO e refletir fatos confirmados. Elas não recriam atualização, desatualização, cancelamento nem estoque consolidado.

## `contr-emb.p` — cadastros, Bags e regras comuns

| `.p` | Conteúdo | Procedure | Já desenvolvida? | É possível desenvolver? | Pendência para desenvolver ou concluir |
|---|---|---|---|---|---|
| `contr-emb-operacao.p` | Origem de entrada e suas embalagens por linha, com disponibilidade e impedimentos | `consultarEmbalagensOrigem` | Desenvolvida em 01/10; sem SAVE | Sim, contrato catálogo 18.2 / E08 | Consulta exata de compra ou entrada de empréstimo; BOIN672/saldo-terc e estoque corrente, paginação 20/100, sem criação de WT. SAVE 3/0 e leitura dirigida 5/0 pendentes; loan sem massa/rastreio de entrada comprovados. |
| `contr-emb-operacao.p` | Direcionamento pelo cadastro da natureza, sem escrita | `classificarNaturezaOperacao` | Compilada SAVE 2/0 e conferência E07 15/0 em 01/10 14:23 | Sim, contrato catálogo 18 / DT-093 | NFD/FT4011, terceiros/FT4012 com origem, remessa/transferência direta; uma conferência E07 somente leitura. Adaptador GET /operacoes/natureza desenvolvido em 01/10, sem SAVE/publicação. Seleção de origem e criação dos novos ramos pendentes. Classificar não autoriza emissão. |
| `contr-emb-operacao.p` | FT2100 por nota: transferência, desatualização e ciclos seguintes | `processarNotaFt2100` | Primeiro par validado em TESTE; ciclos seguintes preparados, sem SAVE | Sim, mediante SAVE e ensaio DT-089 | A nota `0019557` preserva vínculo WT `492960`/operação `6`/etiquetas 101/103; saída `183` e reversão `185` concluídas. Novo ciclo da mesma nota deve criar fatos e movimentos distintos; conferir padrão e específico. Outros ramos não herdam a regra de trânsito. |
| `contr-emb-operacao.p` | Seleção de etiquetas da transferência após BODI317 confirmar WT | `registrarSelecaoAposWt` | Implementada, compilada em TESTE; falta execução integrada | Sim, SAVE E04 `2/0`; executor BODI317 novo ainda não compilado | Recebe `ttEmbSelecaoSaida`, grava uma operação e linhas `SOLICITACAO`, vincula WT e aceita repetição idêntica. O ensaio isolado com WT preexistente não prova a criação a partir das etiquetas. O novo executor de TESTE parte da seleção, agrupa as linhas e confere `saldo-estoq` antes da BODI317; faltam compilação, rollback conjunto, persistência real e volume de 3.000 linhas. Não envolve devolução. |
| `contr-emb.p` | Validar tipo | `validarTipo` | Sim | Concluída | Nenhuma no recorte puro; CRUD continua separado. |
| `contr-emb.p` | Consultar tipos | `consultarTipos` | Sim | Concluída | Completar testes com massa: faixa, ativo/inativo, descrição e paginação. |
| `contr-emb.p` | Autocomplete global de tipos por código OU descrição | `consultarTiposApoio` | Sim | Concluída no ABL | ET-01I 30/0 e paginação com fixture DT-074 aprovadas; REST/Dataset continuam validação de transporte. |
| `contr-emb.p` | Validar parâmetro | `validarParametro` | Sim | Concluída | Contrato puro formalizado e 19 casos aprovados em TESTE. Validações padrão de estabelecimento, item e unidade continuam no CRUD integrado. |
| `contr-emb.p` | Consultar parâmetros | `consultarParametros` | Sim | Concluída | Completar testes com massa, paginação e estabelecimentos autorizados. |
| `contr-emb.p` | Incluir/alterar/inativar tipo | `salvarTipo` | Sim | Concluída no recorte ABL | Contrato DT-049 implementado; compilação 2/0 e mutação controlada ET-01E aprovada em 13/0, com idempotência, versão, auditoria e rollback sem registros persistidos. REST e homologação operacional permanecem fora deste recorte. |
| `contr-emb.p` | Incluir/alterar/inativar/excluir parâmetro, adequar item para lote e reverter o último vínculo para Serial | `salvarParametro` | Sim | **IMPLEMENTADA E VALIDADA no ABL** | ET-01F integrado 32/0 aprovou ciclo, conversão conjunta, reversão, idempotência, conflitos e rollback. POST ativo via REST permanece bloqueio separado de segurança/contexto PASOE. Não repetir ET-01F. |
| `contr-emb-conversao.p` | Analisar e converter tipo usando CDAPIITEM e histórico CE0111 | `analisarConversao`; `converterControleItem` | Sim | **IMPLEMENTADA E VALIDADA** | 1→3 5/0, 4→3 6/0 e 3→1 6/0, além do ET-01F integrado 32/0. REST/PASOE permanece separado. Não repetir esses ensaios. |
| `esp/api/v1/controle-embalagens.p` | Transporte REST de tipos, parâmetros e etiquetas | Ações REST `GET/POST/PATCH` | Sim, em validação | Parcialmente comprovada | A revisão atual compilou em TESTE; a revisão cadastral anterior foi publicada e comprovou o ciclo de tipos e recusas iniciais de parâmetro. Faltam publicar ET-02A, compilar/provar a integração DT-068 e consultas DT-070, provar o ciclo positivo de parâmetros e homologar Widget → Dataset → serviço → API. O endpoint ainda recebe o contexto declarado pelo chamador e não está liberado para produção. |
| `contr-emb.p` | Consultar Bags | `consultarBags` (recorte BAG-04) | Sim | **IMPLEMENTADA E VALIDADA no ABL** | DT-074 aprovou massa positiva, duas páginas, autorização e rollback. Publicação REST permanece separada. |
| `contr-emb.p` | Abrir Bag | `abrirBag` (BAG-05) | Não | Não ainda | CONS-03; sequência autoritativa; formato/unicidade do lacre; campos obrigatórios; perfil e auditoria. |
| `contr-emb.p` | Alterar Bag aberta | `alterarBagAberta` (BAG-06) | Não | Não ainda | CONS-03; campos alteráveis; momento de exigir destino/motorista; concorrência e auditoria. |
| `contr-emb.p` | Transição da Bag | `executarEventoBag` (BAG-07) | Não | Não ainda | Estados e transições; conteúdo mínimo; lacre/troca; retirada após lacre; perfis; efeito nas embalagens. |
| `contr-emb.p` | Consultar conteúdo da Bag | `consultarConteudoBag` (recorte BAG-08) | Sim | **IMPLEMENTADA E VALIDADA no ABL** | DT-074 aprovou conteúdo, cursor, autorização e rollback. Publicação REST permanece separada. |
| `contr-emb.p` | Consultar etiquetas elegíveis | `consultarSaldosElegiveisBag` (BAG-09) | Não | Parcial | Definir situação/disponibilidade elegível no núcleo ET-02; contrato de filtros, paginação e autorização. |
| `contr-emb.p` | Incluir etiquetas na Bag | `incluirEtiquetasBag` (BAG-10) | Não | Não ainda | ET-02; atomicidade e limite do lote; concorrência; estados elegíveis; regra após lacre; CONS-03. |
| `contr-emb.p` | Retirar etiquetas da Bag | `retirarEtiquetasBag` (BAG-11) | Não | Não ainda | Mesmas regras de BAG-10, mais motivo obrigatório e situações que permitem retirada. |
| `contr-emb.p` | Histórico da Bag | `consultarHistoricoBag` (BAG-12) | Não | Parcial | Pode fechar consulta, mas o resultado completo depende dos eventos, movimentos e auditorias ainda não implementados. |
| `contr-emb.p` | Validar transição | `validarTransicaoBag` | Não | Não ainda | Depende da máquina de estados e das obrigatoriedades ainda abertas. |
| `contr-emb.p` | Validar conteúdo em lote | `validarConteudoBag` | Não | Parcial | Validações estruturais podem avançar; disponibilidade, concorrência e estados dependem de ET-02 e das regras Bag. |
| `contr-emb.p` | Auditoria compartilhada | `registrarAuditoria` | Não | Não ainda | Definir ator confiável, campos auditáveis e vínculo com idempotência/resultado do comando na mesma transação. |

## `contr-emb-rastreio.p` — nascimento, etiquetas, eventos e movimentos

| `.p` | Conteúdo | Procedure | Já desenvolvida? | É possível desenvolver? | Pendência para desenvolver ou concluir |
|---|---|---|---|---|---|
| `contr-emb-rastreio.p` | Classificar fato confirmado de recebimento | `processarRecebimento` (GER-01) | Sim, DT-079; SAVE `3/0`, executor `17/0`, integração positiva da nota `9999779` | **IMPLEMENTADA E VALIDADA** no recorte positivo; revisão de 24/09 aguarda SAVE | Relê `mgmov`, exige `ce-atual=YES` e recusa explicitamente `?`; a UPC de TESTE também exige `YES` antes de chamar GER-01. Pela DT-081, a candidata da UPC foi limpa dos efeitos de etiquetas legadas, preservando solicitação CD e follow-up. Compilação/ensaio da revisão são necessários; não repetir o positivo histórico. |
| `contr-emb-rastreio.p` | Compensar compra `1101IS` desatualizada | `reverterRecebimentoCompra` (DT-080) | Ensaio isolado com rollback aprovado; integração RE0402 na nota `9999779`: evento `143` concluído, dez cancelamentos, dez movimentos e quantidade final zero | **IMPLEMENTADA E VALIDADA INTEGRADAMENTE NO RECORTE** | Preserva identidades e nascimento; registra evento relacionado e um movimento compensatório por etiqueta sem movimento posterior. Novo ciclo de reatualização, falha após escrita específica, Bag, movimentos posteriores e outras naturezas seguem fora do recorte. |
| `contr-emb-rastreio.p` | Validar e calcular geração | `validarGeracao` (GER-02) | Sim, DT-078; SAVE 2/0 | **IMPLEMENTADA E VALIDADA** | Executor 25/0 em 22/09 às 11:51. Unidade diferente continua recusada até comprovar conversão Datasul. Não repetir sem mudança relevante. |
| `contr-emb-rastreio.p` | Gerar embalagens e primeiro movimento | `gerarEtiquetas` (GER-03) | Sim, DT-078; SAVE 2/0 | **IMPLEMENTADA E VALIDADA** | Executor 25/0; reutiliza ET-02, cria somente EMBALAGEM, conclui e não duplica. Hook e inverso permanecem fora do recorte. |
| `contr-emb-rastreio.p` | Consultar resultado da geração | `consultarGeracao` (GER-04) | Sim, DT-075; SAVE 3/0 | **IMPLEMENTADA E VALIDADA** | TESTE aprovado em 21/09 às 16:58: cabeçalho, item, exclusão de PRE, duas páginas e rollback, `TOTAL=12 FALHAS=0`. Não repetir. Publicação/chamada REST permanece validação separada do transporte. |
| `contr-emb-rastreio.p` | Dados para impressão/reimpressão | `obterDadosImpressao` (GER-05) | Sim | **IMPLEMENTADA E VALIDADA no ABL** | DT-074 aprovou EMBALAGEM, recusas PRE/geração não confirmada e reimpressão sem nova identidade. Serviço/layout/cópias/Bag permanecem externos. |
| `contr-emb-rastreio.p` | Registrar evento idempotente | `registrarEvento` | Sim, DT-076; SAVE 2/0 | **IMPLEMENTADA E VALIDADA** | TESTE aprovado em 22/09: evento novo `RECEBIDO`, repetição determinística e conflito de idempotência dentro do ensaio ET-02 `23/0`. Não repetir o lote. |
| `contr-emb-rastreio.p` | Aplicar movimento, projeção atual e custódia | `aplicarMovimento` | Sim, DT-076; SAVE 2/0 | **IMPLEMENTADA E VALIDADA** | TESTE aprovado em 22/09: nascimento, repetição, conflitos de sequência/versão, cadeia, projeção, recusas de PRE/quantidade negativa e rollback no ensaio ET-02 `23/0`. Efeitos próprios continuam nos contratos de cada operação. |
| `contr-emb-rastreio.p` | Consultar embalagem/etiqueta | `consultarEtiquetas` | Sim | **IMPLEMENTADA E VALIDADA no ABL** | DT-074 aprovou código exato, massa positiva, autorização, PRE/EMBALAGEM e rollback. Publicação REST permanece separada. |
| `contr-emb-rastreio.p` | Consultar linha do tempo | `consultarMovimentos` | Não | Sim, próximo lote | Fechar filtros, projeção, paginação e autorização; resultado estará vazio até existirem movimentos. |
| `contr-emb-rastreio.p` | Conciliar específico com estoque padrão | `conciliarEtiquetas` | Não | Não ainda | Política de divergência, tolerância, origem dos saldos, ações corretivas e tratamento de `PRE_SALDO`. |

## `contr-emb-operacao.p` — solicitações, transferências, devoluções e baixas

| `.p` | Conteúdo | Procedure | Já desenvolvida? | É possível desenvolver? | Pendência para desenvolver ou concluir |
|---|---|---|---|---|---|
| `contr-emb-operacao.p` | Consultar operações e itens | `consultarOperacoes` | Não | Sim, próximo lote | Fechar filtros, estados, projeção, paginação e autorização. |
| `contr-emb-operacao.p` | Consultar naturezas e ramo padrão | `consultarNaturezasOperacao` | Não | Parcial | A consulta pode avançar; falta mapear por natureza o caso de negócio, FT4011/FT4012/BO aplicável e permissões. |
| `contr-emb-operacao.p` | Consultar documentos de origem | `consultarOrigensDevolucao` | Não | Parcial | Chaves, situações elegíveis, contraparte, saldo disponível/alocado, paginação e contrato instalado. |
| `contr-emb-operacao.p` | Consultar itens da origem | `consultarItensOrigem` | Não | Parcial | Assinaturas FT4011/FT4012/BOIN404TE, quantidades original/devolvida/alocada/disponível e unidades. |
| `contr-emb-operacao.p` | Validar rateio da operação | `validarRateioOperacao` | Não | Parcial | Relação entre linha de origem, etiquetas e quantidade; parcialidade, arredondamento, múltiplas origens e concorrência. |
| `contr-emb-operacao.p` | Persistir seleção após criação confirmada do `wt-docto` | A definir na PI de criação | Não | Definida, falta implementar | DT-085/086: uma linha `SOLICITACAO` por etiqueta/quantidade apenas depois do sucesso da BODI317, junto ao vínculo com `i-seq-wt-docto`. Depende da v1.8 não implantada, prova transacional, medição de ~3.000 etiquetas e correlação posterior nota↔`wt-docto`. O candidato que gravava antes do documento foi retirado. |
| `contr-emb-operacao.p` | Preparar saída de transferência e terceiros | `processarTransferenciaSaida` | Não | Parcial | Validar/persistir seleção, controlar `STANDARD_BO_CALL` e guardar a nota criada por comando Fluig. Custódia/trânsito só muda no hook do estoque confirmado. Natureza, BO e rateio pendentes. |
| `contr-emb-operacao.p` | Correlacionar recebimento de transferência | `processarTransferenciaEntrada` (responsabilidade a recontratar) | Não | Não ainda | Serviço interno reutilizável chamado pelo hook; localiza saída/operação e reaplica as mesmas identidades, inclusive parcialidade/múltiplos documentos. Não cria entrada nem seleciona novamente. |
| `contr-emb-operacao.p` | Preparar empréstimo | `processarEmprestimo` | Não | Não ainda | Seleção, prazo e controladoria da BO padrão; custódia `TERCEIRO` somente no fato confirmado e quando o efeito da natureza for comprovado. |
| `contr-emb-operacao.p` | Preparar devoluções | `processarDevolucao` | Não | Não ainda | Oferecer seleção/vínculo equivalentes a FT4011/FT4012, validar parcialidade e chamar BO padrão comprovada. Atualização/desatualização permanece padrão + hook. |
| `contr-emb-operacao.p` | Preparar renovação | `processarRenovacao` | Não | Não ainda | Sequência documental, prazo e `STANDARD_BO_CALL`; cada fato confirmado posterior reutiliza ET-02, inclusive entrada/saída com efeito líquido zero. |
| `contr-emb-operacao.p` | Baixar embalagens | `processarBaixa` | Não | Não ainda | Motivos, autorização, vínculo de origem, efeito no estoque padrão e possibilidade de reversão. |
| `contr-emb-operacao.p` | Descartar conteúdo/Bag | `processarDescarte` | Não | Não ainda | Momento comprovado do descarte; estados permitidos; efeito quantitativo/fiscal; perfis e dependências da Bag. |
| `contr-emb-operacao.p` | Refletir reversão padrão confirmada | `processarReversao` | Não | Não ainda | Não chama RE0402/FT2100/FT2200 para substituir o padrão. Classifica o fato capturado, localiza evento/parcela e prepara compensação considerando efeitos posteriores. |
| `contr-emb-operacao.p` | Aplicar compensação individual | `aplicarCompensacao` | Não | Não ainda | Usa ET-02, idempotência e cadeia existente; uma compensação por efeito realmente revertido, sem duplicar cancelamento fiscal e desatualização de estoque. |
| `contr-emb-operacao.p` | Consultar resultado e retomar | `consultarResultadoOperacao` | Não | Parcial | Estados duráveis, chave idempotente, documentos/erros vinculados e distinção entre aceitação, emissão e estoque confirmado. |

## Ordem prática sugerida

1. ET-01H 1→3, 4→3 e 3→1 e ET-01F integrado já foram aprovados; não repetir sem alteração relevante. O bloqueio remanescente desse domínio é o POST ativo via REST/PASOE.
2. Fechar os códigos de grupos e a regra grupo → estabelecimento no Dataset, garantindo que usuário e estabelecimentos venham da sessão/regra do Fluig. Homologar a cadeia Widget → Dataset → serviço autorizado → API antes de qualquer liberação produtiva.
3. Publicar/validar o transporte REST das consultas quando o lote de PASOE for autorizado; o ABL com massa já foi aprovado.
4. ET-02 (`registrarEvento` e `aplicarMovimento`) está fechado em TESTE com SAVE `2/0` e ensaio `23/0`; não repetir sem mudança relevante.
5. Acoplar a sonda somente leitura ao EPC já instalado e validar um recebimento real antes de ativar o dispatcher; não repetir GER-01/GER-02/GER-03.
6. Fechar cada operação fiscal com seu inverso e só então implementar transferências, armazenagem em terceiros, empréstimos, devoluções, renovação, baixa e descarte.
7. Fechar as regras Bag e implementar BAG-05 a BAG-12 quando o núcleo já estiver comprovado.
8. Manter GATEC fora destes três módulos até concluir o levantamento. Depois decidir entre encaixe no módulo responsável pelo efeito ou `contr-emb-gatec.p`.

Para ET-06/ET-07, o fechamento inclui a **tela Fluig**: mapear primeiro o comportamento existente e os dados hoje coletados em FT4011/FT4012. A procedure só estará pronta quando permitir concluir e retomar o processo pelo Fluig, inclusive em falha ou resultado incerto, sem etapa manual intermediária no Datasul.

## Leitura executiva

- **10 procedures de negócio e um auxiliar já existem** no módulo central. As duas consultas ET-05A foram desenvolvidas sem compilação/homologação.
- **5 consultas somente leitura** são candidatas ao próximo lote, após contrato técnico curto.
- As **gravações cadastrais ABL** já estão implementadas no recorte anterior. `salvarTipo` e seu ciclo REST foram comprovados; `salvarParametro` aguarda as conversões padrão para Lote e de volta para Serial e a prova positiva ET-01F/REST.
- A **fronteira REST cadastral** está publicada em TESTE, mas só estará apta à produção depois que Dataset e serviço autorizado garantirem a identidade e os estabelecimentos sem aceitar contexto livre do cliente.
- As **gravações de rastreio e operação** dependem do núcleo ET-02 e das regras específicas de cada fluxo.
- Esta matriz é de planejamento; não transforma nomes propostos do catálogo em contrato aprovado.

## Apoios DT-064 — 16/09/2026

| Módulo | Procedure | Estado | Dependência/contrato |
|---|---|---|---|
| contr-emb.p | consultarEstabelecimentos | Compilada; ET-01I ABL 30/0; REST/Dataset pendentes | Catálogo 21 / ET-01I; autorizados, código/nome, limite 20 e cursor. |
| contr-emb.p | consultarItens | Compilada; ET-01I ABL 30/0 com unidade/repetição/cursor; REST/Dataset pendentes | Catálogo 21 / ET-01I; contexto autorizado, catálogo global e unidade, limite 20. |
| contr-emb.p | validarFiltroApoio | Auxiliar interno implementado | Não é endpoint; valida termo/limite compartilhados. |
| esp/api/v1/controle-embalagens.p | pi-apoios-estabelecimentos / pi-apoios-itens | Compiladas; núcleos ABL comprovados; publicação/REST/Dataset pendentes | Adaptam JSON, delegam ao núcleo; Dataset/grupos ainda pendentes. |

A matriz detalhada por tela/campo/ação é MATRIZ_TELAS_CAMPOS_ACOES.md. Continuam pendentes apoios de depósito/localização/lote/família/grupo/contraparte/motorista, operações e transições de Bags. Existem agora dez procedures de negócio e um auxiliar no núcleo; as seis anteriores mantêm suas evidências históricas. Nenhuma evidência anterior homologa os apoios DT-064 ou as consultas DT-066.

<!-- INICIO_INVENTARIO_AUTOCOMPLETE -->
## Inventario completo de autocomplete por tela

**13 recursos de consulta para 25 campos autocomplete.** Inclui apoios implementados no fonte e pendencias com seus estados reais. Necessidade mapeada nao significa API implementada ou rota aprovada.

| Recurso | Tela/campo | Procedure | Metodo/rota | Arquivo .p | Estado | Dependencia/contrato |
|---|---|---|---|---|---|---|
| Estabelecimentos / destino | T01/P01; T01/P11; T02/E01; T02/E29; T03/B01; T03/B14; T03/B17 | consultarEstabelecimentos | GET /apoios/estabelecimentos | fontes/progress/contr-emb.p | Compilado; ET-01I ABL 30/0: autorizacao, filtro e codigo aprovados; REST/Dataset pendentes | Catalogo 21 / ET-01I |
| Itens | T01/P02; T01/P12; T02/E02 | consultarItens | GET /apoios/itens | fontes/progress/contr-emb.p | Compilado; ET-01I ABL 30/0: permissao, unidade, limite, repeticao e cursor aprovados; REST/Dataset pendentes | Catalogo 21 / ET-01I; catalogo global, nao saldo por estabelecimento |
| Tipos de embalagem | T01/P03; T01/P14; T02/E39; T03/B02; T03/B15 | consultarTiposApoio | GET /apoios/tipos | fontes/progress/contr-emb.p | Compilado; ET-01I positivos/recusas e DT-074 duas paginas aprovados; REST/Dataset pendentes | Catalogo 23.1; filtro OR codigo/descricao, minimo 2, teto 20, cursor; ativo=true/false/todos |
| Depositos | T02/E04 | A definir: apoio de depositos | A definir Nao contratada | A definir; modulo cadastral proposto | Pendente: fonte nativa, visibilidade e assinatura | Dependente de estabelecimento; nao usar tabela/coluna presumida |
| Localizacoes | T02/E05 | A definir: apoio de localizacoes | A definir Nao contratada | A definir; modulo cadastral proposto | Pendente: fonte nativa e assinatura | Dependente de estabelecimento/deposito |
| Lotes / validades | T02/E06 | A definir: apoio de lotes/validades | A definir Nao contratada | A definir; modulo rastreio proposto | Pendente: contrato, origem e deduplicacao | Dependente de estabelecimento/item; nao apresentar referencias como lotes |
| Familias | T02/E09 | consultarFamilias | GET /apoios/familias | fontes/progress/contr-emb.p | Compilado; ET-01I ABL 30/0: predicado, limite, repeticao e cursor aprovados; REST/Dataset pendentes | Catalogo 24.1; mgcad.familia comprovada; busca OR, teto 20, cursor e permissoes; filtro ampliado de etiquetas continua pendente |
| Grupos de estoque | T02/E10 | A definir: apoio de grupos de estoque | A definir Nao contratada | A definir; modulo cadastral proposto | Pendente: fonte nativa e contrato | Grupo do item, distinto de familia e dos grupos de autorizacao Fluig; filtro ampliado pendente |
| Bags / lacres | T02/E13 | consultarBags | GET /bags | fontes/progress/contr-emb.p | Compilado; DT-074 positivo/exato/vazio/autorizacao e duas paginas de Bags aprovados; filtros combinados/REST/Dataset pendentes | Catalogo 22/23.2; somente leitura, teto 20, cursor; idBag em query; sem totais globais |
| Naturezas da operacao | T02/E30 | consultarNaturezasOperacao (proposta) | A definir Nao contratada | fontes/progress/contr-emb-operacao.p (proposto) | Proposta; natureza/BO instalada pendente | Catalogo 18; ET-06/07 |
| Contrapartes | T02/E31 | A definir: apoio de contrapartes | A definir Nao contratada | A definir; modulo operacao proposto | Pendente: fonte nativa e contrato | Filtrar elegibilidade por natureza/empresa; nao inferir de cadastro livre |
| Documentos de origem | T02/E32 | consultarOrigensDevolucao (proposta) | A definir Nao contratada | fontes/progress/contr-emb-operacao.p (proposto) | Proposta; contratos FT4011/FT4012 pendentes | Catalogo 18; documentos elegiveis, contraparte e saldo disponivel |
| Motoristas | T03/B18 | A definir: apoio de motoristas | A definir Nao contratada | A definir; modulo cadastral proposto | Pendente: origem/cadastro e obrigatoriedade | ET-05; nao inventar tabela nativa |

Estabelecimento de destino operacional e destino de Bag precisam de elegibilidade/origem confirmadas; compartilhar campo visual nao autoriza reutilizar permissao de origem. O apoio de lote deve devolver validade na identidade selecionada quando aplicavel. Familia e grupo sao apoios distintos. Tipos possuem apoio incremental DT-070 no fonte, com OR codigo/descricao; ABL e paginacao foram comprovados, REST/Dataset ainda pendentes.

Etiquetas por codigo, notas por faixa/lista e lacre digitado sao filtros previstos na matriz de controles; nao foram convertidos em autocomplete por inferencia. Itens da origem e etiquetas elegiveis da Bag sao consultas acionadas por botao, com seus proprios contratos/limites, e nao se confundem com o catalogo global de itens.

Fonte unica: cobertura-telas.json; regenerar com scripts/gerar-entrega-telas.py. Atualizar estado somente com evidencias do recurso e da tela.
<!-- FIM_INVENTARIO_AUTOCOMPLETE -->

## DT-068 — integração preparada, aguardando SAVE/ET-01F (17/09)

Conversor agora chamado por salvarParametro na mesma unidade de trabalho; contrato transitório de migração e proteções descritos no escopo 6.5/catálogo 16.1. Ensaios isolados 1→3, 4→3 e 3→1 seguem como evidências anteriores, sem aprovar a nova revisão. Fonte novo exige SAVE de nove fontes e executor ET-01F autenticado com rollback. Roteiro: docs/entregas/ET-01F_PARAMETRIZACAO_CONVERSAO.md. Evidência estática: docs/entregas/evidencias/integracao_parametro_conversao_dt068_2026-09-17.md. Impedimentos com massa, falha interna, concorrência e REST pendentes. Nenhum servidor reiniciado; entrega somente na pasta aberta, sem ZIP.


## DT-072 — Progress: famílias e dados da ação de impressão

| Procedure | Arquivo | REST | Situação |
|---|---|---|---|
| consultarFamilias | fontes/progress/contr-emb.p | GET /apoios/familias | Compilada; ET-01I ABL 30/0 com cursor aprovado; REST/Dataset pendentes. |
| obterDadosImpressao | fontes/progress/contr-emb-rastreio.p | GET /dados-impressao | Compilada; ET-02A/DT-074 com massa aprovado no recorte de impressão; REST/serviço/layout pendentes. |

Recorte da ação imprimir/reimprimir entrega somente dados da identidade. Não cobre lote de IDs nem impressão do conteúdo da Bag, cuja necessidade está separada no registro. Não há desenvolvimento de UX/limpeza de campos neste checkpoint.


**SAVE DT-073, 17/09:** lote 13 fontes aprovado com zero falhas conforme relato do responsável. TXT novo pendente de localização; desenvolvimento em fonte não permanece sem compilação conforme esse relato, mas execução funcional/publicação/REST não foram aprovadas. Próximo: ET-01F autenticado.


## 17/09, 15:23 — ET-01F integrado aprovado 32/0

Item 365131/10901: 32 casos aprovados, FALHAS=0 PENDENCIAS=0 nesse executor; inclusão inativa, ativação/conversão conjunta, segundo ativo, último inativo→Serial, conflitos/repetição, aborto interno e rollback externo aprovados. 27 saldos/2963,2 e 106 terceiros conservados; zero registros persistidos. Evidência preservada fora do pacote em docs/entregas/evidencias/validacao_et01f_integrado_2026-09-17.md. Pendências do domínio permanecem: guardas com massa, concorrência/falha técnica e novo REST/Dataset. Próximo: testar-consultar-apoios.r (ET-01I), somente leitura, sem copiar/recompilar fontes novamente.


## 17/09, 15:26 — ET-01I parcial 25/0

25 casos executados passaram. Positivos de estabelecimento e de tipos/famílias (predicado/limite/repetição, descrição do tipo) e recusas aprovados. Pendentes: CODIGO_ITEM_CURTO (escolha do primeiro cadastro pelo teste; positivos item/unidade/cursor não executados), MASSA_TIPO_SEGUNDA_PAGINA_AUSENTE e MASSA_FAMILIA_SEGUNDA_PAGINA_AUSENTE. Aprovação parcial; não libera REST/Dataset nem cursor sem massa. Evidência docs/entregas/evidencias/validacao_et01i_parcial_2026-09-17.md. Próximo: testar-consultar-etiquetas.r ampliado com dados de impressão, somente leitura. Nenhum fonte alterado; não copiar/recompilar pacote agora.


## 17/09, 15:28 — ET-02A parcial 9/0

9 casos executados passaram, zero falhas, REGISTROS_ETIQUETAS=0. Comprovados recusas de autorização/filtros/cursor/limite, consulta vazia/repetição e recusas de impressão sem permissão/ID inválido. Pendentes consulta por código exato e impressão positiva: a base consultada não apresentou etiquetas; o executor procura até 20 registros para impressão. Não comprova geração, impressão física, filtros ampliados nem REST/Dataset. Evidência transcrita do resultado informado pelo responsável: docs/entregas/evidencias/resultado_et02a_2026-09-17_152850.txt.

Nenhum fonte alterado; manter r-codes do SAVE aprovado. Próximo: testar-consultar-bags.r, somente leitura, INPUT 0 para selecionar Bag existente. Sem nova cópia/compilação ou reinício de serviço. Avanço técnico local de consultas permanece 60%; resultado sem massa positiva não fecha essa frente.


## 17/09, 15:38 — ET-05A parcial e massa autorizada (DT-074)

ET-05A repetiu cinco recusas aprovadas, TOTAL=5 FALHAS=0, MASSA_BAG_AUSENTE; nenhuma consulta positiva executada. TXT preservado fora do transporte em docs/entregas/evidencias/resultado_et05a_2026-09-17_153840.txt. Responsável autorizou registros sintéticos em TESTE; executor testes/executar-consultas-com-massa-teste.p preparado/sincronizado, ainda sem compilação. Reaproveita executores readonly .r do lote aprovado: Bag com duas etiquetas, Bag vazia, etiquetas/PRE/geração não confirmada; complementa listagem de Bags e cursor de tipos. Dois tipos novos sem colisão, dois eventos, duas Bags, quatro etiquetas temporários; rollback explícito, conferência dos IDs/códigos e nenhuma alteração do estoque/cadastros padrão. Fixtures são projeções para consulta, não homologação da geração RE1001/vínculo/movimentos.

Compilar somente o executor novo no Studio de TESTE (SAVE) e rodar seu .r; não repetir os 13 fontes inalterados. Comandos no final do ET-05A_CONSULTAS_BAGS.md. Guardas: confirmação TESTE, conexão shmgesp no caminho documentado DBs/TESTE/shems2esp e fora de transação prévia. Holder diferente bloqueia; não remover guarda sem conferir ambiente. Sequências podem avançar; histórico e registros existentes não são alterados. Sem novo percentual: consultas permanecem 60% técnico local, REST e positivos ainda pendentes.

Acesso confirmado pelo responsável: RDP 200.206.113.85 já autenticado na máquina local; dentro dele RDP 192.168.1.103:1074, com autenticação de Administrator feita pelo responsável. Ferramenta local de controle do computador falhou na inicialização do kernel (caminho não encontrado), mesmo após reset; não houve acesso/compilação/execução remota pelo agente. Sondagem direta anterior de 3389 não cobre a porta interna 1074 nem prova indisponibilidade da sessão em cadeia. Não registrar senha no projeto/conversa.


## 17/09, 15:49 — consultas com massa aprovadas (DT-074)

Quatro TXT conferidos: principal 19/0, Bag com conteúdo 16/0, Bag vazia 13/0 e etiquetas/impressão 17/0. Comprovados consulta exata, conteúdo autorizado/recusado, repetição, cursor de conteúdo, duas páginas de Bags e tipos, código exato de etiqueta, recusa PRE/geração ERRO e dados/reimpressão preservando identidade. Dez conferências de rollback aprovaram ausência dos dois tipos, dois eventos, duas Bags e quatro etiquetas. Fonte do executor da raiz coincide com o transportado. Evidências preservadas fora do pacote em docs/entregas/evidencias/consultas_massa_dt074_2026-09-17_154934/.

PENDENTE=MASSA_SEGUNDA_PAGINA_CONTEUDO apenas no relatório da Bag vazia é esperado: não existe segunda linha nesse caso. A Bag com conteúdo aprovou CURSOR_EXCLUSIVO/SEGUNDA_PAGINA. Pendências anteriores de massa Bag/etiqueta/impressão e segunda página de tipos ficam resolvidas para os cenários ABL exercitados. Não prova geração RE1001, produtor de vínculo/movimento, impressão física, REST/Dataset, autorização cruzada entre estabelecimentos, concorrência ou filtros combinados/período.

Próximo: ET-01I positivos de item/unidade e cursor de famílias. Ajustado somente testes/et01/testar-consultar-apoios.p: escolher item existente com código >=2 caracteres e preferir prefixo presente em duas famílias nativas; sem criar/alterar cadastro padrão. Fonte sincronizado com a pasta completa oficial; recompilar somente esse teste com SAVE antes do RUN .r. API/core/rastreio e o lote de 13 fontes não mudaram. Nova seleção de massa ainda aguarda compilação/execução. Tipos podem continuar registrando falta de segunda página no filtro do teste readonly; paginação desse recurso já foi aprovada com fixture DT-074.

## 17/09, 17:00 — ET-01I ABL concluído 30/0

O `resultado-apoios-pos-massa-dt074.txt` presente no pacote registra execução posterior ao checkpoint documental das 15:49: `TOTAL=30 FALHAS=0`. Foram aprovados `UNIDADE_DO_ITEM`, `ITEM_LIMITE_1`, `ITEM_REPETICAO`, `ITEM_CURSOR_EXCLUSIVO` e `FAMILIA_CURSOR`, além dos cenários de estabelecimento, tipos, famílias e recusas já cobertos. Evidência preservada em `docs/entregas/evidencias/validacao_et01i_concluido_2026-09-17.md` e no TXT correspondente.

A pendência `CODIGO_ITEM_CURTO` e a falta de cursor de família do ensaio 25/0 ficam resolvidas. A ausência de segunda página de tipos no teste readonly não reabre a paginação: duas páginas de tipos já foram aprovadas pela fixture DT-074. Não houve mudança de `contr-emb.p`, `contr-emb-rastreio.p` ou adaptador REST após o SAVE 13/0; somente o teste ET-01I havia recebido seleção melhor de massa e foi executado em seguida.

**Próximo:** publicar a revisão REST/ABL atual em TESTE, renovar somente o PASOE de TESTE e validar as rotas/JSON/autorização/paginação da revisão corrente. REST, Dataset, identidade/grupos e homologação integrada continuam pendentes. Não repetir ET-01I ou DT-074 sem mudança relevante de fonte.

## E09 / DT-095 — preparação WT (01/10)

| Procedure | Fonte | Estado | Limite |
|---|---|---|---|
| criarWtDevolucao | fontes/progress/contr-emb-devolucao.p | Desenvolvida, sem SAVE/ensaio | FT4011/FT4012, entrada rastreada, seleção inteira; sem nota/estoque/REST mutante. |
| registrarSelecaoRemessaAposWt | fontes/progress/contr-emb-operacao.p | Desenvolvida, sem SAVE/ensaio | Remessa classificada, seleção pós-BO; não herda efeito 5557. |

O novo .p é auxiliar técnico da criação de operações, não um CRUD ou quarto domínio funcional. Massa nova: compras 9999801/1 e 9999802/1, duas linhas com lotes/validades diferentes; roteiro E09_CENARIOS_DEVOLUCAO.md. Compilador cinco fontes, depois leitura única das compras/etiquetas. Não repetir E07/E08 aprovados.

E12 / DT-098 — PREPARADO, SEM SAVE: contr-emb-emprestimo-entrada.p::processarEntradaEmprestimo/reverterEntradaEmprestimo; hooks RE1005RP/RE0402RP; retorno FT4012 integrado em vincularNotaSaidaFluig/processarNotaFt2100. Classificacao por cadastro e correlacao integral multigrupo. Nenhum REST/schema alterado. Ensaio E11 da remessa aprovado (213/215/217), entrada/retorno E12 pendentes. Dependencias completas no compilador E12 12 fontes. Roteiro docs/entregas/E12_RECEBIMENTO_RETORNO_EMPRESTIMO.md.


04/10 — DT-099 preparado: SAVE E12 anterior 12/0 confirmado pelo TXT. Entrada 11301/9321/1/0019559/1949OE atualizada em 02/10 14:29 com 10 LT por lote e duas linhas de terceiros; nenhum evento especifico de chegada. Consulta nativa OF docum-est confirmou serie-comp/nro-comp vazios em ambas as linhas (10/20). Corrigida correlacao por cabecalho com emissor/destinatario/WT/operacao/ciclo/grupos unicos; campos parciais/divergentes bloqueiam. Executor dirigido concilia apenas embalagens, sem novo movimento padrao. Sem SAVE/execucao da correcao; compilador de revisao 2 fontes, compilador completo futuro 13 fontes. Proximo: SAVE 2/0, conciliar entrada existente e consulta E12 operacao 25; retorno FT4012 somente apos chegada comprovada. Evidencias preservadas: docs/entregas/evidencias/e12-correlacao-cabecalho-20261004.



DT-100 / 04-10 — IMPLEMENTADO, SEM SAVE/ACEITE: servicos E05/E12 compartilham includes/contr-emb-recebimento-origem.i (resolverOrigemRecebimento, validarRecebimentosOrigem, validarContinuidadeRecebimento, registrarVinculoRecebimento). conciliarEntradaComOrigem e chamada interna para origem explicitamente identificada, atomica a chegada; nao e endpoint REST. Assinaturas dos hooks inalteradas. SAVE dirigido 6 fontes/completo 14; conciliacao corrente e substituicao apos reversao ainda pendentes. Roteiro docs/entregas/E12_VINCULO_RECEBIMENTOS_DT100.md. Passagens anteriores podem estar desatualizadas.

## DT-103/E14 — retorno de armazenagem preparado (05/10/2026)
Reutiliza as assinaturas processarEntradaEmprestimo/reverterEntradaEmprestimo e hooks instalados. NFE/terceiros tipo5 sem retorno interno rastreado resolve RETORNO_ARMAZENAGEM -> REMESSA_TERCEIROS da propria fazenda para o emitente da entrada, por referencia completa de todos os itens. VINCULO_ENTRADA_SAIDA aponta remessa, RECEBIMENTO_RETORNO_TERCEIROS aponta saida ativa, ENTRADA_RETORNO_TERCEIROS aponta movimentos; TERCEIRO -> ESTAB e inverso por snapshot. Guardas comuns incorporam esse tipo de chegada. registrarSelecaoRemessaAposWt aceita destino vazio para emitente externo cadastrado; FT2100 permite esse caso somente no ramo REMESSA_TERCEIROS. Transferencia continua exigindo destino; demais fluxos preservados. Sem tabelas/campos/REST novos. Preparado sem SAVE/ensaio; compiladorE14 sete fontes, roteiro docs/entregas/E14_ARMAZENAGEM_TERCEIRO.md. Cenários: sucesso integral/repeticao/compensacao previstos; sem origem/ambiguo/quantidade ou estado divergente bloqueados. Integracao real/parcelas ainda pendentes.

## E15/DT-106 — encerramento automatico preparado, 05/10/2026
Implementado fontes/progress/contr-emb-cancelamento.p, procedure concluirCancelamentoNota(ROWID nota, usuario; aplicavel, sucesso, repeticao, id-operacao, erro, mensagem). Confere identidade/documento/carimbo CEWT1, cancelamento nativo, estoque desconfirmado e compensacao unica de cada saida. Sob lock da operacao, encerra CANCELADA apenas quando todas as notas associadas estiverem canceladas e reconciliadas. Primeira conclusao atualiza autor/data/versao; repeticao nao altera versao. Nota sem vinculo especifico devolve nao aplicavel/sucesso. Nenhuma escrita em estoque, etiquetas, eventos ou movimentos; preserva historico. Divergencia, lock ou efeito ativo impedem conclusao.
UPC-BODI135CANCEL-DIAGNOSTICO-TESTE agora tambem e funcional: AFTERINVOICECANCELLATION exige transacao e chama o servico; FIM_CANCELANOTAFISCAL permanece observacao. Erro funcional propagado, nunca suprimido pelo log. Nome instalado mantido para evitar mudar cadastro. Nao e pos-commit. Sem nova API/schema. Compensacao continua exclusivamente no FT2100.
Executor parametrizado testes/e15/concluir-operacao-cancelada.p realiza fechamento, repeticao, estabilidade de versao/quantidade de movimentos e rollback quando PERSISTIR=no. Uso excepcional para op23 ja cancelada; fluxo futuro pelo hook. SAVE/rollback/propagacao de erro e aceite nativo ainda pendentes. Cenários sem baixa, varias notas, dependencias posteriores e anulacao continuam sem homologacao; nao afirmar garantia geral.

## 05/10 — DT109/E16 preparado: caminhos compartilhados e sonda local
SOAP/ressuprimento aprovado pelo responsavel apos DT108/FT2100; evidência na conversa, sem TXT nativo novo. Include contr-emb-caminhos.i em seis hooks e dois servicos de entrada; resolve raiz ERP (_bp/api/ET-01_TESTE/...) ou raiz pacote no PROPATH. Nao muda PROPATH runtime, nao usa drive fixo; logs derivam do include localizado. APIs publicadas ja resolvem modulos por SEARCH/esp/api/v1; contratos REST inalterados. Ferramentas administrativas dirigidas ao TESTE conservam caminhos fisicos de compilacao/instalacao.
E16/compilar-caminhos-save.p cobre14 fontes com SAVE e restaura PROPATH anterior. Sonda conferir-caminhos-local.p carga sete modulos, seis adaptadores com evento sem efeito e tt-epc vazia, vazio/arquivo ausente e PROPATH preservado; sem chamada de negocio/mutacao. Prepara compatibilidade local sem telas Fluig; nao homologa efeitos/rollback funcional. Pacote sincronizado por SHA256;95 .r recebidos preservados. Proximo copiar pacote, SAVE14/0, executar sonda na sessao local; apos FALHAS0 instalar seis adaptadores nos destinos atuais e retomar E15 ensaio com rollback de op23. Nenhuma nova execucao nativa feita localmente; aceite E16/DT106 pendentes.
