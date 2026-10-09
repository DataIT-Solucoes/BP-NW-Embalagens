# Matriz de APIs REST do Controle de Embalagens

**Atualizada em:** 22/09/2026
**Recurso atual:** `prg/esp/v1/controle-embalagens`  
**Ambiente de referência:** Datasul 12.1.2511.15, OpenEdge 12.2, Oracle e Fluig Silver Mist 1.8.1-230530 build 137.  
**Objetivo:** conferir, em um único lugar, se cada funcionalidade exposta possui contrato, procedure de negócio, autorização, compilação e evidência compatíveis. Esta matriz acompanha o estado; os contratos detalhados continuam no catálogo e nos documentos de entrega.

## Estados usados

- **Proposta:** necessidade identificada, sem rota aprovada.
- **Contratada:** método, recurso, entradas, saídas e erros definidos antes do código.
- **Implementada:** fonte existe, ainda sem prova suficiente no OpenEdge/PASOE atual.
- **Verificada em TESTE:** compilação/publicação e cenários registrados para o recorte indicado.
- **Homologada:** fluxo completo com Widget, Dataset, serviço autorizado, API e aceite funcional.

Uma rota pode estar verificada tecnicamente e continuar impedida para produção por autorização, dependência funcional ou ausência de homologação integrada.

**Dependência vigente DT-065:** conversor isolado compilado, com rollback aprovado nos três caminhos: 1→3 5/0, 4→3 6/0 e 3→1 6/0 (17/09, 10:02, após cadastro da despesa 645). DT-068 integra o conversor ao salvar/inativar no fonte, com migração explícita; compilação/transação conjunta ET-01F e REST pendentes. Não cria endpoint nem libera a revisão para publicação; ITEM_SEM_CONTROLE_LOTE é recusa histórica da revisão anterior. Apoios DT-064 inalterados. Evidência: validacao_et01h_3_1_2026-09-17.md.

## Rotas declaradas no adaptador atual

| Método e rota | Funcionalidade | Núcleo ABL | Contrato/fonte | Estado executável | Autorização e próximo fechamento |
|---|---|---|---|---|---|
| `GET /tipos` | Consultar tipos de embalagem | `contr-emb.p::consultarTipos` | Catálogo 17.1 e ET-01G | **Verificada em TESTE no recorte cadastral**: vazio, limite inválido, usuário ausente e faixa exata com massa; paginação e filtros ampliados ainda pendentes | Exige permissão global resolvida pelo Dataset. Homologar a cadeia Fluig e completar massa de consulta. |
| `POST /tipos` | Incluir tipo | `contr-emb.p::salvarTipo` | Catálogo 19 e ET-01G | **Verificada em TESTE**: inclusão, repetição, conflito de chave e duplicidade | Dataset deve obter a identidade e validar grupo; endpoint técnico ainda recebe contexto da requisição. |
| `PATCH /tipos` | Alterar, inativar ou reativar tipo | `contr-emb.p::salvarTipo` | Catálogo 19 e ET-01G | **Verificada em TESTE**: alteração, repetição, conflito de versão, inativação e reativação | Fechar grupos, visão global e teste integrado Fluig. |
| `GET /parametros` | Consultar parametrizações autorizadas | `contr-emb.p::consultarParametros` | Catálogo 17.2 e ET-01G | **Verificada em TESTE em 18/09** no ciclo inativo GET→POST→GET→PATCH→GET; filtros ampliados/paginação ainda requerem massa | Dataset envia `estabelecimentoPermitido` repetido, derivado da sessão/grupo. |
| `POST /parametros` | Parametrizar item e, quando necessário, convertê-lo para lote na mesma ação | `contr-emb.p::salvarParametro` → `contr-emb-conversao.p::converterControleItem` | Catálogo 16.1/16.2, DT-050/055/057/058/059 e ET-01G | **ABL ET-01F 32/0; REST inativo aprovado em 18/09; ativo retorna FALHA_PARAMETRIZACAO**. Payload de migração, adapter, `.r` e PROPATH já foram descartados como causa | Próximo teste é cadastrar a API REST na segurança Datasul e repetir o mesmo POST ativo; foco no contexto PASOE/CDAPIITEM. |
| `PATCH /parametros` | Alterar, inativar, reativar ou excluir parâmetro; ao retirar o último vínculo ativo, reverter item para Serial | `contr-emb.p::salvarParametro` | Catálogo 16.1, DT-050/055/057/058 e ET-01G | **ABL integrado aprovado no ET-01F 32/0**, incluindo segundo vínculo ativo, retirada do último ativo → Serial, conflitos/repetição, aborto e rollback; REST/Dataset pendentes | Publicar a mesma revisão e provar autorização/ciclo REST; guardas com massa, concorrência e falha técnica permanecem fora desse recorte. |
| `GET /etiquetas` | Consultar a projeção atual das embalagens/etiquetas | `contr-emb-rastreio.p::consultarEtiquetas` | Catálogo 10.1 e ET-02A | **ABL com massa 17/0 e REST funcionando em 18/09**, com vazio válido no ambiente atual | Completar tela/Dataset e cenário REST com massa persistida quando disponível. |

### Consultas DT-070 — ABL comprovado; publicação REST pendente

| Método e rota | Funcionalidade | Núcleo ABL | Contrato/fonte | Estado executável | Autorização e próximo fechamento |
|---|---|---|---|---|---|
| `GET /apoios/tipos` | Autocomplete por prefixo de código OU trecho da descrição | `contr-emb.p::consultarTiposApoio` | Catálogo 23.1 / DT-070 | **ABL e REST comprovados em TESTE**; ativos padrão, true/false/todos; teto 20 | Homologar Dataset/grupo e uso pela tela. |
| `GET /bags` | Listar/detalhar ocorrência autorizada, podendo apoiar lacre | `contr-emb.p::consultarBags` | Catálogo 22/23.2 / DT-070 | **ABL com massa e REST vazio válido comprovados**; filtros combinados com massa persistida ainda pendentes | Usuario + estabelecimentoPermitido confiáveis. Teto 20, cursor, inicio/fim ISO; não calcula totais nem elegibilidade. |
| `GET /conteudo-bag` | Consultar vínculos atuais autorizados da Bag | `contr-emb.p::consultarConteudoBag` | Catálogo 22/23.2 / DT-070 | **ABL comprovado em TESTE com massa DT-074**: conteúdo autorizado/vazio, repetição e cursor; REST/Dataset/autorização cruzada pendentes | idBag positivo em query, autorização da Bag e da posição atual da etiqueta; teto 20; sem totais globais. |
| `GET /apoios/familias` | Autocomplete global de famílias por código OU descrição | `contr-emb.p::consultarFamilias` | Catálogo 24.1 / DT-072 | **ABL 30/0 e REST comprovados em TESTE em 18/09** | Lista de estabelecimentos é contexto de autorização, não disponibilidade da família; teto 20. |
| `GET /dados-impressao` | Obter fotografia persistida de uma etiqueta individual para impressão/reimpressão | `contr-emb-rastreio.p::obterDadosImpressao` | Catálogo 24.2 / DT-072 | **ABL com massa aprovado e REST comprovado em TESTE em 18/09**; serviço/layout continuam pendentes | Uma etiqueta autorizada por chamada; não gera identidade, movimento ou impressão física. |
| `GET /operacoes/embalagens-origem` | Conferir a entrada escolhida e paginar suas embalagens, incluindo impedimentos | `contr-emb-operacao.p::consultarEmbalagensOrigem` | Catálogo 18.2 / DT-094 / E08 | **Implementada em fonte; sem SAVE/ensaio/PASOE** | Chave completa de entrada e estabelecimento autorizado; BOIN672 para compra, saldo-terc para retorno de empréstimo; limite compartilhado pela linha, não reserva a seleção. Listagem de documentos e demais terceiros pendentes. |
| `GET /operacoes/natureza` | Classificar a natureza exata selecionada e indicar necessidade de origem | `contr-emb-operacao.p::classificarNaturezaOperacao` | Catálogo 18.1 / DT-094 | **Implementada em fonte; sem SAVE/PASOE** | Usuario e codEstabel autorizado; não enumera nem autoriza naturezas amigáveis. Retorna ramo, origem e edição de quantidade/preço; publicação e consumo Dataset pendentes. |
| `GET /geracoes` | Consultar cabeçalho, itens/lotes e embalagens nascidas em um evento | `contr-emb-rastreio.p::consultarGeracao` | Catálogo 10.2 / DT-075 | Núcleo ABL **IMPLEMENTADO E VALIDADO 12/0**; adapter compilado, falta publicar/chamar REST | Evento autorizado pelo estabelecimento; pagina somente EMBALAGEM; não expõe estado atual, hashes, token ou payload técnico. |

### Apoios DT-064 — ABL concluído; publicação REST pendente

| Método e rota | Funcionalidade | Núcleo ABL | Contrato | Estado e dependência |
|---|---|---|---|---|
| `GET /apoios/estabelecimentos` | Autocomplete de estabelecimentos permitidos; código/nome | `contr-emb.p::consultarEstabelecimentos` | Catálogo 21 / ET-01I | **ABL 30/0 e REST comprovados em TESTE em 18/09.** Filtro mínimo 2, teto 20, cursor por código e lista autorizada antes da paginação. |
| `GET /apoios/itens` | Autocomplete do catálogo global de itens; código/descrição/unidade/tipo controle | `contr-emb.p::consultarItens` | Catálogo 21 / ET-01I | **ABL 30/0 e REST/cursor comprovados em TESTE em 18/09.** Estabelecimento selecionado autorizado; não afirma saldo/vínculo nesse estabelecimento. |

O detalhamento por **tela/campo/botão/procedure/método/arquivo** está em [Matriz de controles](MATRIZ_TELAS_CAMPOS_ACOES.md), derivada de `cobertura-telas.json`. Registro de apoios pendentes: depósito, localização, lote/validade, família/grupo, contraparte e motorista; consultas operacionais de natureza/documento/linha e Bag seguem os contratos propostos do catálogo. Filtros ampliados de etiqueta e tipo na consulta de parâmetro não existem no recorte atual; não enviar parâmetros extras supondo que o servidor os aplica. A consulta de CD não substitui esses apoios.

## Capacidades futuras sem rota aprovada

| Domínio | Funcionalidade prevista | Estado | Fonte para definição | Condição antes de acrescentar rota |
|---|---|---|---|---|
| Geração | Consultar resultado e impressão; geração permanece interna ao hook | GER-02/03 internos; GER-04 e GER-05 já implementados | Catálogo 10; ciclo 7; ET-03 | Não criar REST para atualizar RE1001 ou disparar hook. Fechar cálculo e ponto confirmado; manter apenas consultas necessárias à tela. |
| Movimentos | Consultar linha do tempo e conciliar controle individual | Proposta | Matriz de procedures, ET-02 | Fechar projeção histórica, visibilidade entre estabelecimentos e política de divergência. |
| Bags | Consultar/abrir/alterar Bag, conteúdo, eventos e histórico | Consultas BAG-04/BAG-08 no fonte conforme catálogo 22/23; mutações/eventos/histórico permanecem propostas | Catálogo 3 a 8; ET-05 | Fechar lacre, transições, permissões, limites, descarte e dependência do núcleo ET-02. |
| Saídas | Consultar naturezas/origens/itens, registrar seleção, processar e retomar operação | Proposta | Levantamento Fluig; matrizes de transações/eventos; ET-06/07 | Confirmar contratos instalados, natureza, FT4011/FT4012/BOs, persistência, concorrência e resultado durável. |
| Reversões | Consultar/solicitar operação quando houver caso Fluig; atualização/desatualização/cancelamento permanecem padrão | Proposta restrita | Ciclo 10; DT-077; ET-08 | Não criar REST substituta para RE0402, FT2100 ou FT2200. Hook interno chama compensação comum após fato confirmado. |
| GATEC | Saída/retorno de campo | Em levantamento | ET-10 e pendências | Obter processo real, contratos e responsável de homologação. |

## Contagem arquitetural DT-077

- **36 capacidades REST necessárias** para as telas e consumidores já definidos.
- **17 rotas declaradas** (inclui classificação exata de natureza; listagem amigável continua pendente) no adaptador atual.
- **21 capacidades pendentes:** seis apoios (depósito, localização, lote/validade, grupo de estoque, contraparte e motorista); histórico de movimentos; oito capacidades Bag (abrir, alterar, elegíveis, incluir, retirar, evento, histórico e impressão); seis capacidades de operação (consulta, resultado/detalhe, naturezas, origens, itens da origem e comando de criação/continuidade).
- As rotas futuras continuam **sem método/path aprovado** quando o catálogo ainda não os fechou. A contagem registra necessidade funcional e não inventa contrato.
- Não existem rotas REST próprias para `registrarEvento`, `aplicarMovimento`, recebimento atualizado, desatualização de entrada, atualização/desatualização de saída ou cancelamento padrão. UPCs chamam o serviço ABL interno; não fazem HTTP contra o próprio PASOE.

## Regra de manutenção

Ao declarar ou remover uma ação em `fontes/progress/esp/api/v1/controle-embalagens.p`, atualizar esta matriz no mesmo checkpoint. Uma linha só avança quando a evidência do estado estiver registrada no documento da entrega e em `docs/08_ACOMPANHAMENTO_ETAPAS.md`. O comando `Validar-Checkpoint-Projeto.bat` confere automaticamente se todas as ações REST declaradas no fonte aparecem aqui; ele não promove o estado por inferência.

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
| Naturezas da operacao | T02/E30 | consultarNaturezasOperacao (proposta) | A definir Nao contratada | fontes/progress/contr-emb-operacao.p (proposto) | DT-093: classificacao dinamica pelo cadastro/parametrizacoes da natureza; atributos suficientes e BO instalada pendentes; sem codigos fixos definitivos | Catalogo 18; ET-06/07 |
| Contrapartes | T02/E31 | A definir: apoio de contrapartes | A definir Nao contratada | A definir; modulo operacao proposto | Pendente: fonte nativa e contrato | Filtrar elegibilidade por natureza/empresa; nao inferir de cadastro livre |
| Documentos de origem | T02/E32 | consultarOrigensDevolucao (proposta) | A definir Nao contratada | fontes/progress/contr-emb-operacao.p (proposto) | Proposta; contratos FT4011/FT4012 pendentes | Catalogo 18; documentos elegiveis, contraparte e saldo disponivel |
| Motoristas | T03/B18 | A definir: apoio de motoristas | A definir Nao contratada | A definir; modulo cadastral proposto | Pendente: origem/cadastro e obrigatoriedade | ET-05; nao inventar tabela nativa |

Estabelecimento de destino operacional e destino de Bag precisam de elegibilidade/origem confirmadas; compartilhar campo visual nao autoriza reutilizar permissao de origem. O apoio de lote deve devolver validade na identidade selecionada quando aplicavel. Familia e grupo sao apoios distintos. Tipos possuem apoio incremental DT-070 no fonte, com OR codigo/descricao; ABL e paginacao foram comprovados, REST/Dataset ainda pendentes.

Etiquetas por codigo, notas por faixa/lista e lacre digitado sao filtros previstos na matriz de controles; nao foram convertidos em autocomplete por inferencia. Itens da origem e etiquetas elegiveis da Bag sao consultas acionadas por botao, com seus proprios contratos/limites, e nao se confundem com o catalogo global de itens.

Fonte unica: cobertura-telas.json; regenerar com scripts/gerar-entrega-telas.py. Atualizar estado somente com evidencias do recurso e da tela.
<!-- FIM_INVENTARIO_AUTOCOMPLETE -->

## ET-05A / DT-066 — ABL desenvolvido, REST proposto

consultarBags e consultarConteudoBag existem no núcleo, contrato catálogo 22 e roteiro ET-05A_CONSULTAS_BAGS.md. Checkpoint histórico DT-066 superado no transporte pela DT-070: GET /bags e GET /conteudo-bag declarados no fonte, ainda sem compilação/publicação; path /bags/{idBag}/conteudo continua proposta da API completa. Fonte ABL compilado em 16/09 às 17:13; execução funcional/homologação pendentes; serializers, Dataset autorizado, resumo global e totais não fazem parte deste lote. Consulta de Bags pode apoiar lacre/ID após integração, sem declarar autocomplete pronto por existir procedure.


## DT-072 — Progress: famílias e dados da ação de impressão

| Procedure | Arquivo | REST | Situação |
|---|---|---|---|
| consultarFamilias | fontes/progress/contr-emb.p | GET /apoios/familias | Desenvolvida em fonte; TT transitória; origem mgcad.familia comprovada; compilação, teste e REST pendentes. |
| obterDadosImpressao | fontes/progress/contr-emb-rastreio.p | GET /dados-impressao | Desenvolvida em fonte; uma etiqueta autorizada EMBALAGEM de evento CONCLUIDO; sem escrita; teste/REST/serviço/layout pendentes. |

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

## 06/10/2026 — Republicação da revisão corrente preparada
Conjunto inalterado de 17 combinações. CRC 1896 de contr_emb_oper_item confirmado no núcleo publicado. Roteiro de compilação/publicação integral dos cinco módulos: PUBLICACAO_REST_COMPLETA_TESTE_20261006.md. Nenhuma rota promovida de estado; SAVE cinco/zero e novos ensaios REST pendentes.


## DT114 — recebimentos das fazendas, demanda adicional
Três capacidades novas sem rota implementada: listagem de documentos, detalhe fiscal e embalagens vinculadas ao recebimento/ciclo. Definição funcional: CONSULTA_RECEBIMENTOS_FAZENDAS.md. Métodos GET; paths e contrato executável pendentes. Contagem atual do adaptador continua17. Consulta histórica não substituída por GET /geracoes nem condicionada ao aceite AED.


## DT115 — sete ações adicionais preparadas em 06/10/2026

| Método e rota | Funcionalidade | Núcleo ABL | Estado e próximo fechamento |
|---|---|---|---|
| POST /operacoes/transferencias | Preparar WT e seleção inteira entre estabelecimentos da mesma empresa | contr-emb-operacao.p::criarWtSaidaDireta → BODI317/registrarSelecaoAposWt | Fonte novo baseado em E04; SAVE e ensaio idempotência/lista variável/PASOE pendentes |
| POST /operacoes/remessas | Preparar WT de empréstimo/armazenagem, natureza de terceiros tipo3 | contr-emb-operacao.p::criarWtSaidaDireta → BODI317/registrarSelecaoRemessaAposWt | Fonte novo baseado E11/E14; contraparte externa ou destino interno; SAVE/PASOE pendentes |
| POST /operacoes/devolucoes | Preparar devolução de compra ou retorno de empréstimo com origem completa | contr-emb-devolucao.p::criarWtDevolucao | Serviço DT101 existente, transporte novo; SAVE/PASOE e sanitização de erro pendentes |
| GET /operacoes | Listar/detalhar cabeçalho por ID/WT original | contr-emb-operacao.p::consultarOperacoesRest | Fonte preparado; origem autorizada, paginação; SAVE/sonda/PASOE pendentes |
| GET /operacoes/resultado | Recuperar preparação pelo contexto da chave idempotente | contr-emb-operacao.p::consultarOperacoesRest | Fonte preparado; não promete ausência de chamada concorrente; mesma chave no retry; SAVE/PASOE pendentes |
| GET /operacoes/itens | Paginar seleções históricas de etiquetas da operação | contr-emb-operacao.p::consultarOperacoesRest | Fonte preparado; sem substituição por saldo corrente; SAVE/sonda/PASOE pendentes |
| GET /operacoes/eventos | Paginar metadados fiscais/ciclos autorizados da operação | contr-emb-operacao.p::consultarOperacoesRest | Fonte preparado; sem hashes/payload/diagnóstico interno; SAVE/sonda/PASOE pendentes |

Contagem corrente: **24 ações declaradas = 17 GET + 7 POST/PATCH**. As contagens DT077 acima são históricas. Contrato REST_FLUXOS_ABL_20261006.md; nenhum dos sete endpoints novos está compilado/publicado por inferência. Sem REST de atualização/cancelamento padrão, GATEC/anulação, mutações Bag ou T04. Compilador corrente: seis módulos de runtime e sonda de leitura (7/0 exigido).

## 06/10 — DT115 / GET operações aprovado pelo proxy
Responsável retornou sucesso=true/total1 para GET /operacoes?usuario=super&estabelecimentoPermitido=10904&codEstabel=10904&idOperacao=41&limite=20. Operação41 TRANSFERENCIA/CANCELADA, WT493024, versão3, IDs textuais, sem erro/temMaisfalse. Evidência: docs/entregas/evidencias/rest-operacoes-dt115-20261006.json. Após resposta anterior Method not found, rota passou a executar; causa/publicação/renovação exatas não comprovadas pelo retorno. Próximo GET /operacoes/itens e /operacoes/eventos com mesmo contexto. Não extrapolar aceite a POST/autorizações negativas REST/Dataset/Widget. Nenhum fonte ou binário alterado; não repetir cancelamento0019561.

## DT116 — mapeamento das24ações no Dataset central
Modelo fontes/fluig/datasets/dsNwEmbalagens.js e guia DATASET_UNICO_FLUIG_20261006.md. Nenhuma nova rota ABL. GET /operacoes/eventos confirmado pelo responsável: total3, eventos259/261/275, compensação275 ligada a261; não marca GET itens apenas pelo retorno de cabeçalho reenviado. Dataset de tipos recebido já comunica; modelo central exige configuração real/publicação/migração.21+7testes locais/FALHAS0, sem prova de Fluig instalado.
