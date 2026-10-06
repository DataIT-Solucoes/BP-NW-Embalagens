# Catálogo de procedures — Controle de Embalagens

## 1. Situação e objetivo

A visão prática consolidada por módulo, incluindo o que já foi desenvolvido e os bloqueios atuais, está em [`docs/entregas/MATRIZ_PROCEDURES_PROGRESS.md`](entregas/MATRIZ_PROCEDURES_PROGRESS.md). Ela não substitui os contratos deste catálogo nem cria um arquivo por operação.

A biblioteca ampla de contratos padrão está em `referencias/padrao-datasul/README.md`, com catálogos de MRE/MFT, NF-e e complementos e `MATRIZ_TRANSACOES.md` (DT-029). Dos 124 links catalogados, 28 páginas foram consultadas em 04/09/2026: 26 com documentação de API/BO analisada preliminarmente, uma do monitor NF-e e REAPI436 em construção (DT-030). As 96 restantes, os contratos integrais, a compatibilidade com a versão instalada e a seleção para implementação permanecem pendentes. Não confundir esse inventário padrão com as procedures específicas propostas neste documento.

- **Situação:** o módulo central `contr-emb.p` possui oito procedures de negócio e um auxiliar; os dois apoios DT-064 ainda aguardam compilação; `contr-emb-rastreio.p` possui `consultarEtiquetas`; e o adaptador REST único expõe tipos, parâmetros e a consulta de etiquetas. O ciclo REST de tipos foi comprovado em TESTE. Parametrização com conversão do item, ET-02A e os demais fluxos ainda seguem seus bloqueios e critérios próprios. As rotinas legadas inventariadas são identificadas separadamente.
- **Primeiro domínio:** tipos de Bag, ocorrência/lacre, conteúdo, movimentos e consultas de Bag.
- **Objetivo:** enumerar os casos de uso antes da implementação REST/ABL e ampliar o catálogo por etapa até fechar o ciclo do projeto.

O legado é fonte de entendimento. Os nomes, parâmetros, tabelas e comportamentos antigos não definem o contrato novo.

### 1.1 Como ler este catálogo

- As seções 3 e 4 descrevem o **modelo novo proposto**. Essas procedures utilizam tabelas `contr_emb_*` e, quando necessário, tabelas padrão autoritativas do Datasul.
- A seção 6 é apenas o **inventário das procedures legadas encontradas**. Citações a `etiquetas-CD`, `bag`, `bag_embalagens`, `bag_etiquetas` e `bag_log` nessa seção não autorizam seu uso no código novo.
- A implementação será feita por domínio, mas cada etapa será definitiva no novo modelo. Não será criada uma etapa intermediária escrevendo nas tabelas específicas legadas para depois refazê-la.

| Estrutura específica legada | Destino funcional no modelo novo |
|---|---|
| `etiquetas-CD` | `contr_emb_etiqueta` guarda identidade, origem, item, lote, validade, estabelecimento, quantidade, situação e localização atuais. |
| `bag_embalagens` | `contr_emb_bag`. |
| `bag` | `contr_emb_bag_lacre`. |
| `bag_etiquetas` | Vínculo atual em `contr_emb_etiqueta.id-bag`; inclusões e retiradas no histórico de `contr_emb_movto`. |
| `bag_log` | Eventos, movimentos e `contr_emb_audit`, conforme o tipo de alteração. |

`saldo-estoq` não é uma tabela específica legada do projeto: permanece como tabela padrão do Datasul e autoridade do saldo consolidado.

## 2. Organização recomendada

A listagem a seguir organiza o domínio Bag; não define a ordem geral de implementação. Conforme DT-036 e o [acompanhamento das etapas](08_ACOMPANHAMENTO_ETAPAS.md), tipos e parametrização constituem o primeiro recorte candidato a desenvolvimento. A infraestrutura comum de evento, saldo e movimento deve existir antes das operações de conteúdo e das transições de Bag que afetam etiquetas, conforme seção 4 deste catálogo e seção 7 do modelo.

No domínio Bag, a sequência lógica é cadastro do tipo, abertura/consulta da ocorrência, conteúdo, transições e histórico. Isso não adia a infraestrutura de etiquetas e movimentos para depois de seu uso. Cada recorte só inicia desenvolvimento quando suas definições, contratos e dependências estiverem fechados; abertura isolada pode ser avaliada sem antecipar todo o ciclo da Bag.

As rotas abaixo são relativas ao recurso REST v1 do projeto. Cada procedure pública recebe `JsonObject` e devolve `JsonObject`, seguindo o baseline REST Fluig–Datasul. Nomes de rotas e contratos permanecem propostos até a revisão conjunta.

## 3. Procedures públicas propostas para Bag

### 3.1 Tipo de Bag — `contr_emb_bag`

| ID | Procedure ABL | Método e recurso | Responsabilidade | Persistência |
|---|---|---|---|---|
| BAG-01 | `pi-consultar-tipos-bag` | `GET /tipos-bag` e `GET /tipos-bag/{codTipo}` | Listar ou detalhar tipos, com filtro por código, descrição e ativo; paginação obrigatória na lista. | Lê `contr_emb_bag`. |
| BAG-02 | `pi-incluir-tipo-bag` | `POST /tipos-bag` | Criar `cod-tipo` manual, estável e único. Não derivar tipo de referência nem de prefixo da etiqueta. | Inclui `contr_emb_bag` e `contr_emb_audit`. |
| BAG-03 | `pi-alterar-tipo-bag` | `PATCH /tipos-bag/{codTipo}` | Alterar descrição ou situação ativa usando `versao` para concorrência. `cod-tipo` não é alterado; inativação substitui exclusão física quando houver uso. | Altera `contr_emb_bag` e inclui `contr_emb_audit`. |

Não haverá procedure pública para obter “próximo código” nem para excluir fisicamente tipo referenciado.

### 3.2 Ocorrência de Bag e lacre — `contr_emb_bag_lacre`

| ID | Procedure ABL | Método e recurso | Responsabilidade | Persistência |
|---|---|---|---|---|
| BAG-04 | `pi-consultar-bags` | `GET /bags` e `GET /bags/{idBag}` | Listar ou detalhar ocorrências, com filtros por id, lacre, tipo, estabelecimento, situação, destino e período. O detalhe traz resumo do conteúdo; listas extensas usam o recurso de conteúdo. | Lê `contr_emb_bag_lacre`, `contr_emb_bag` e agregados de `contr_emb_etiqueta`. |
| BAG-05 | `pi-abrir-bag` | `POST /bags` | Criar uma ocorrência em situação `ABERTA`, com `id-bag` gerado por sequência autoritativa e tipo ativo. | Inclui `contr_emb_bag_lacre` e `contr_emb_audit`. |
| BAG-06 | `pi-alterar-bag-aberta` | `PATCH /bags/{idBag}` | Alterar os dados permitidos enquanto aberta, como destino e motorista, validando `versao`. Tipo não muda depois de receber conteúdo. | Altera `contr_emb_bag_lacre` e inclui `contr_emb_audit`. |
| BAG-07 | `pi-executar-evento-bag` | `POST /bags/{idBag}/eventos` | Executar uma transição idempotente do ciclo. Tipos candidatos: `LACRAR`, `ENVIAR`, `DEVOLVER`, `ENCERRAR` e `CANCELAR`. | Inclui `contr_emb_evento`, altera `contr_emb_bag_lacre` e inclui `contr_emb_audit`; inclui `contr_emb_movto` somente quando houver efeito nas embalagens. |

As regras exatas das transições, obrigatoriedade e reutilização do lacre ainda precisam ser fechadas. `TROCAR_LACRE` não entra no primeiro contrato enquanto essa regra estiver pendente.

### 3.3 Conteúdo e embalagens da Bag

| ID | Procedure ABL | Método e recurso | Responsabilidade | Persistência |
|---|---|---|---|---|
| BAG-08 | `pi-consultar-conteudo-bag` | `GET /bags/{idBag}/conteudo` | Listar as etiquetas atualmente vinculadas, com item, lote, validade, quantidade, localização e totais, usando paginação. | Lê `contr_emb_bag_lacre` e `contr_emb_etiqueta`. |
| BAG-09 | `pi-consultar-saldos-elegiveis-bag` | `GET /bags/{idBag}/saldos-elegiveis` | Localizar somente registros `tipo-controle = EMBALAGEM` disponíveis, respeitando estabelecimento, situação e o mesmo `cod-tipo` da Bag. `PRE_SALDO` nunca é elegível. | Lê `contr_emb_bag_lacre`, `contr_emb_bag` e `contr_emb_etiqueta`. |
| BAG-10 | `pi-incluir-etiquetas-bag` | `POST /bags/{idBag}/conteudo` | Incluir uma ou várias etiquetas em lote. Toda a requisição confirma ou falha em conjunto. Exigir `tipo-controle = EMBALAGEM` e validar Bag aberta, tipo compatível, saldo atual, vínculo existente e concorrência. | Inclui `contr_emb_evento` e um `contr_emb_movto` por etiqueta; atualiza `contr_emb_etiqueta.id-bag` e a versão de `contr_emb_bag_lacre` na mesma transação. |
| BAG-11 | `pi-retirar-etiquetas-bag` | `POST /bags/{idBag}/conteudo/retiradas` | Retirar uma ou várias etiquetas com motivo. É uma ação histórica, por isso não usa exclusão física REST. Toda a requisição confirma ou falha em conjunto. | Inclui `contr_emb_evento` e um `contr_emb_movto` por etiqueta; limpa `contr_emb_etiqueta.id-bag` e atualiza a versão de `contr_emb_bag_lacre` na mesma transação. |

Incluir ou retirar conteúdo nunca altera diretamente `contr_emb_etiqueta` sem criar `contr_emb_movto`. A quantidade física da embalagem permanece igual quando somente o vínculo com a Bag muda.

### 3.4 Histórico

| ID | Procedure ABL | Método e recurso | Responsabilidade | Persistência |
|---|---|---|---|---|
| BAG-12 | `pi-consultar-historico-bag` | `GET /bags/{idBag}/historico` | Entregar uma linha do tempo paginada com abertura, alterações, lacre, envio, devolução, encerramento, cancelamento e inclusão/retirada de etiquetas. | Lê Bag, eventos, movimentos e auditoria; não materializa outra tabela de log. |

## 4. Rotinas internas necessárias

Estas rotinas não são endpoints e não aceitam decisões vindas diretamente da interface:

| Rotina | Responsabilidade |
|---|---|
| `pi-validar-transicao-bag` | Conferir situação atual, evento solicitado, conteúdo, lacre, destino e campos obrigatórios antes da transição. |
| `pi-validar-conteudo-bag` | Conferir existência, situação, estabelecimento, tipo explícito, vínculo atual e versão de todas as etiquetas do lote. |
| `pi-aplicar-vinculo-bag` | Sob bloqueio, criar os movimentos e atualizar os saldos individuais e a versão da Bag atomicamente. |
| `pi-registrar-auditoria` | Rotina compartilhada do projeto para registrar alterações permitidas, sem dados sensíveis. |

`pi-aplicar-vinculo-bag` deverá usar a infraestrutura comum de eventos e movimentos que será detalhada na etapa de `contr_emb_movto`; não deve criar uma segunda implementação concorrente do mesmo mecanismo.

## 5. Regras transversais do contrato

- Comandos recebem chave idempotente; repetição com o mesmo conteúdo devolve o resultado anterior e conteúdo diferente gera conflito.
- IDs `INTEGER` atravessam JSON como texto.
- Alterações usam `versao` e retornam conflito quando o estado foi modificado por outro processo.
- Consultas volumosas são paginadas, possuem limite máximo e ordenação estável.
- A Bag aceita somente etiquetas cujo `cod-tipo` coincida explicitamente com seu tipo.
- A compatibilidade não compara item, lote, validade ou capacidade. Uma Bag de `cod-tipo = PL` pode conter embalagens plásticas de 10 L e 20 L e itens distintos.
- A API normaliza `cod-tipo` com remoção de espaços externos e maiúsculas, valida `^[A-Z0-9]{2,3}$` e confere sua unicidade; a interface não é a autoridade da regra.
- Nenhuma validação utiliza `cod-refer`, prefixo de referência ou sigla legada para inferir o tipo.
- Eventos, movimentos, projeções de saldo, versão da Bag e auditoria confirmam na mesma transação local.
- Movimentos de armazenagem em terceiro conservam identidade e conteúdo e alteram posição/custódia somente após confirmação do efeito padrão. O retorno total ou parcial exige documento/linha de origem, etiquetas, quantidade e disponibilidade válidos; o serviço específico não lança novamente estoque nem presume que todo empréstimo produza saldo de terceiros (DT-053).
- Histórico confirmado não é apagado; correção cria evento compensatório conforme a regra do fluxo.
- A API retorna mensagens funcionais sanitizadas e nunca devolve credenciais, sessão, cookies ou requisição integral.

## 6. Procedures encontradas no legado

As mesmas doze procedures centrais aparecem na versão informada como produção, em `referencias/fontes-prod-legado/etiquetas.p`, e na evolução não implantada, em `referencias/fontes-legado/etiquetas_v2.p`.

| Procedure | Produção | Evolução não implantada |
|---|---:|---:|
| `pi-cadastra-embalagens` | linha 1577 | linha 2034 |
| `pi-retorna-embalagens` | linha 1590 | linha 2063 |
| `pi-proximo-codigo-bag` | linha 1602 | linha 2075 |
| `pi-bag` | linha 1613 | linha 2086 |
| `pi-excluir-bag` | linha 1646 | linha 2119 |
| `pi-registra-bag-log` | linha 1667 | linha 2140 |
| `pi-retorna-bag-log` | linha 1676 | linha 2149 |
| `pi-insere-bag-etiquetas` | linha 1688 | linha 2161 |
| `pi-exclui-bag-etiquetas` | linha 1700 | linha 2173 |
| `pi-busca-bag-etiquetas` | linha 1712 | linha 2185 |
| `pi-analisa-tipo-embalagem` | linha 1867 | linha 2364 |
| `pi-retorna-bags` | linha 1890 | linha 2387 |

| Procedure legada | Papel observado | Destino no novo desenho |
|---|---|---|
| `pi-cadastra-embalagens` | Inclui registros em `bag_embalagens`; a versão evoluída tenta impedir siglas com o mesmo prefixo. | BAG-02/BAG-03, usando `contr_emb_bag` e tipo explícito. |
| `pi-retorna-embalagens` | Lista `bag_embalagens`. | BAG-01. |
| `pi-proximo-codigo-bag` | Calcula maior código + 1. | Eliminada; `id-bag` usa sequência autoritativa. |
| `pi-bag` | Inclui ou atualiza Bag e cria log. | BAG-05, BAG-06 e BAG-07, separados por caso de uso. |
| `pi-excluir-bag` | Exclui fisicamente quando não encontra etiquetas associadas. | Sem equivalente direto; usar cancelamento/encerramento conforme regra aprovada. |
| `pi-registra-bag-log` | Insere `bag_log`. | Evento, movimento e auditoria automáticos. |
| `pi-retorna-bag-log` | Consulta `bag_log`. | BAG-12. |
| `pi-insere-bag-etiquetas` | Cria vínculos em `bag_etiquetas`. | BAG-10, com evento, movimento e saldo atômicos. |
| `pi-exclui-bag-etiquetas` | Exclui vínculos em `bag_etiquetas`. | BAG-11, preservando o histórico. |
| `pi-busca-bag-etiquetas` | Lista vínculos da Bag. | BAG-08. |
| `pi-analisa-tipo-embalagem` | Compara sigla da Bag com prefixo de `saldo-estoq.cod-refer`. | Validação interna por `cod-tipo`; a lógica por referência é descartada. |
| `pi-retorna-bags` | Lista Bags e monta filtro ABL como texto. | BAG-04, com filtros validados e consulta estática/paginada. |

Também foram encontradas referências indiretas em `pi-processa-ref-item` e `pi-situacao-etiqueta`. A primeira depende do modelo antigo por referência e não será portada. A segunda apenas traduz situações de etiqueta e será substituída pelos domínios e projeções do novo controle.

## 7. Riscos observados no legado que não devem ser reproduzidos

- numeração por maior código + 1, sujeita a concorrência;
- criação, alteração e exclusão física sem contrato idempotente;
- inferência do tipo pelo prefixo de referência;
- montagem de consulta dinâmica por concatenação de valores;
- vínculo de conteúdo apagado sem fato histórico imutável;
- log separado sem garantir a mesma transação do efeito completo;
- ausência de paginação, controle de versão e resposta REST estável.

## 8. Pontos a fechar antes de implementar BAG-07, BAG-10 e BAG-11

1. Formato, abrangência da unicidade, troca e reutilização do lacre.
2. Conteúdo mínimo para lacrar e possibilidade de retirar etiquetas após o lacre.
3. Transições permitidas entre `ABERTA`, `LACRADA`, `ENVIADA`, `DEVOLVIDA`, `ENCERRADA` e `CANCELADA`.
4. Momento em que destino e motorista se tornam obrigatórios.
5. Tratamento de lote parcialmente válido em uma inclusão/retirada em massa; a proposta atual é atomicidade de todo o lote.
6. Perfis autorizados para cadastro, conteúdo, lacre, envio, devolução, encerramento e cancelamento.
7. Volume máximo de etiquetas por comando e paginação das consultas.

## 9. Próximas etapas do catálogo

Após a revisão do domínio Bag, acrescentar neste documento, na ordem sugerida:

1. geração no recebimento e consulta das etiquetas — proposta inicial na seção 10;
2. eventos e movimentos comuns — usados pela geração e por Bag, sem duplicar implementação;
3. demais consultas de saldo individual;
4. transferência entre estabelecimentos e rateio de saída/entrada;
5. empréstimos, renovações de empréstimos, devoluções, retornos, cancelamento/anulação/desatualização de notas, descarte e baixas;
6. conciliação, auditoria e consultas gerenciais.

## 10. Geração no recebimento — fase em definição

**Situação:** contratos internos GER-01 a GER-04 materializados nos recortes indicados; GER-05 já existia. Regras detalhadas em `07_CICLO_VIDA_EMBALAGEM.md`, seção 7. Os nomes abaixo não obrigam criar um arquivo `.p` para cada rotina.

| ID | Rotina proposta | Papel | Dados envolvidos |
|---|---|---|---|
| GER-01 | `pi-processar-recebimento` | Orquestrar o recebimento confirmado, reconhecer repetição e classificar a operação. Encaminhar geração nova ou recebimento das etiquetas existentes; classificação incerta gera pendência. | Evento e identidade fiscal real validada pelo adaptador. |
| GER-02 | `pi-validar-geracao` | Validar entrada de compra de fornecedor com natureza `1101IS` (DT-027), linhas/lotes, posição, parametrização ativa, unidade e conversão; calcular embalagens completas/resíduo e preparar a memória do cálculo. | Parâmetro, tipo e itens do evento; dados padrão conferidos. |
| GER-03 | `pi-gerar-etiquetas` | Criar identidades, saldos e primeiros movimentos e concluir o evento na transação local. Usa o mecanismo comum de movimentos, sem produzir entrada adicional no ERP. | Evento, item, etiqueta, saldo e movimento. |
| GER-04 | `pi-consultar-geracao` | Consultar resultado por evento e seus itens, quantidades, resíduos, diagnósticos e somente registros `tipo-controle = EMBALAGEM` gerados, com paginação. Separar dados de nascimento da projeção atual. | Evento/item e embalagem; PRE aparece apenas nas consultas próprias da transição. |
| GER-05 | `pi-obter-dados-impressao` | Recuperar somente registros `tipo-controle = EMBALAGEM` confirmados para impressão ou reimpressão, conservando os mesmos códigos. Rejeitar `PRE_SALDO`; não confirma que o papel foi fisicamente impresso. | Identidade e dados congelados da embalagem; sem movimentar saldo. |

GER-01, GER-02 e GER-03 são rotinas internas de negócio. A interface não fornece livremente quantidade para criar etiquetas: GER-01 relê o documento confirmado do `mgmov`. GER-04 e GER-05 seguem seus contratos de consulta. O transporte do gatilho fiscal até GER-01 depende da prova transacional do EPC e não usa REST.

### 10.2 Contrato executável GER-04 — DT-075

`consultarGeracao` em `contr-emb-rastreio.p`: INPUT TABLE `ttEmbEstabelPermitido`, `piIdEvento`, `piAposId`, `piLimite`; OUTPUT TABLE `ttEmbGeracao`, `ttEmbGeracaoItem`, `ttEmbEtiquetaGerada`, `plTemMais`, `piProximoId`, `plSucesso`, `pcErro`, `pcMensagem`.

O evento precisa existir, possuir estabelecimento e pertencer à lista explícita. Inexistente e sem acesso retornam `GERACAO_NAO_DISPONIVEL`. Cursor não negativo; limite zero usa 20, faixa 1–100. O cabeçalho omite hashes, token e payload técnico. Itens devolvem a memória de cálculo. Etiquetas são paginadas por `id-etiqueta` e limitadas a `tipo-controle = EMBALAGEM`; a projeção contém dados de nascimento, sem posição/situação/quantidade atual. Vazio autorizado é sucesso. Erro técnico limpa todas as projeções.

`GET /geracoes`: parâmetros `idEvento`, `aposId`, `limite`, `usuario` e `estabelecimentoPermitido` repetido. Resposta: `geracao`, `itens`, `etiquetas`, `total`, `temMais`, `proximoId` e controles comuns. O adapter não calcula nem persiste.

### 10.3 Contrato executável GER-02/GER-03 — DT-078

`validarGeracao` em `contr-emb-rastreio.p`: INPUT TABLE `ttEmbGeracaoLinha`, `plAutorizado`; OUTPUT TABLE `ttEmbGeracaoValidada`, `piQtdEtiquetas`, `plSucesso`, `pcErro`, `pcMensagem`. Não persiste. Valida estabelecimento e item padrão, parametrização ativa, tipo ativo, controle por lote, capacidade/unidade, lote/validade, quantidade positiva com até quatro casas e ocorrência única por `sequencia + seq-lote`. A unidade igual à parametrizada usa fator 1; diferença retorna `CONVERSAO_UNIDADE_NAO_COMPROVADA`. Item sem parâmetro é `IGNORADO`. O cálculo preserva `quantidade = qtd-etiquetas × capacidade + resíduo`, com `0 <= resíduo < capacidade`.

`gerarEtiquetas`: INPUT TABLE `ttEmbEventoComando`, INPUT TABLE `ttEmbGeracaoValidada`, `plAutorizado`; outputs `plSucesso`, `plRepeticao`, `piIdEvento`, `piQtdEtiquetas`, `pcErro`, `pcMensagem`. Registra o evento pelo ET-02, grava cada memória em `contr_emb_evento_item`, cria somente identidades `EMBALAGEM`, chama `aplicarMovimento` para `NASCIMENTO_RECEBIMENTO` e conclui o evento. Tudo ocorre na mesma transação. Evento concluído repetido devolve sucesso sem duplicar; cálculo divergente é conflito. Não existe rota REST para essas rotinas internas.

### 10.4 Contrato executável GER-01 — DT-079

`processarRecebimento` em `contr-emb-rastreio.p`: recebe `prDocumEst` e `plAutorizado`; devolve aplicabilidade, sucesso, repetição, evento, quantidade de etiquetas, classificação, erro e mensagem. O `ROWID` é transporte interno do EPC, usado somente para reler `mgmov.docum-est`; a identidade persistida usa campos fiscais estáveis.

O dispatcher aceita neste recorte apenas `1101IS` com `ce-atual = sim`, monta ocorrências de `item-doc-est` somente para itens com parâmetro ativo e chama `validarGeracao`/`gerarEtiquetas`. Natureza diferente retorna sucesso `NAO_APLICAVEL`. Documento inexistente, não confirmado, usuário ausente ou fotografia inválida falha antes de persistir. Não há REST, atualização do RE1001, transferência, terceiros ou empréstimo.

O TDN oficial localiza `fim-atualizacao` em `re1005rp`; o EPC legado confirma assinatura e `docum-est rowid`. GER-01 está **IMPLEMENTADA E VALIDADA** em TESTE (`3/0`, `17/0`). `testes/et03/sonda-re1005rp.p` ainda precisa comprovar na instalação a fronteira da transação e os dados disponíveis antes da chamada automática.

### 10.5 Reversão inicial da compra pelo RE0402 — DT-080

`reverterRecebimentoCompra` em `contr-emb-rastreio.p` recebe `prDocumEst` e `plAutorizado`; devolve aplicabilidade, sucesso, repetição, ID do evento compensatório, quantidade de etiquetas, erro e mensagem. O documento deve ser `1101IS` com `ce-atual = no`; o evento de geração concluído deve ser único. Apenas etiquetas ainda no movimento `NASCIMENTO_RECEBIMENTO`, ativas, com quantidade inicial e sem Bag são elegíveis. Cada uma recebe um movimento `CANCELAMENTO_RECEBIMENTO` ligado ao nascimento, com motivo que identifica a nota desatualizada; `aplicarMovimento` zera a projeção e marca `CANCELADA`. O evento compensatório aponta para a origem e é concluído na mesma transação. Repetição concluída não duplica movimentos; movimento posterior ou ciclo ambíguo bloqueia. Não altera o estoque padrão.

A candidata de EPC `testes/et03/UPC-RE0402RP-REVERSAO-TESTE.p` chama esse serviço apenas em `Fim-Atualizacao` e exige transação ativa. Está **PREPARADA, NÃO COMPILADA/NÃO ATIVADA**. Sua instalação depende da sonda de transação e `ce-atual` nesse evento, seguida de ensaio isolado com rollback. Não há REST para o gatilho; reatualização da mesma nota ainda não está coberta.

### 10.3 ET-02 — núcleo executável de fatos, DT-076

`registrarEvento` em `contr-emb-rastreio.p`: INPUT TABLE `ttEmbEventoComando`, `plAutorizado`; OUTPUT `plSucesso`, `plRepeticao`, `piIdEvento`, `pcSituacao`, `piVersao`, `pcErro`, `pcMensagem`. Exige exatamente um comando, contexto confiável e hashes SHA-256 já calculados. Evento novo recebe sequência autoritativa, situação `RECEBIDO`, zero tentativas e versão 1. Repetição exata devolve o registro existente em qualquer situação; mesma chave hash com origem, chave, conteúdo ou tipo divergente retorna `CONFLITO_IDEMPOTENCIA`.

`aplicarMovimento`: INPUT TABLE `ttEmbMovimentoComando`, `plAutorizado`; OUTPUT `plSucesso`, `plRepeticao`, `piIdMovto`, `piVersaoEtiqueta`, `pcErro`, `pcMensagem`. Exige evento existente ainda aberto para fatos novos, sequência positiva, embalagem individual, versão e `id-movto-ult` esperados, quantidades não negativas, destino completo e relações existentes quando informadas. A chave única evento+sequência torna a repetição determinística; divergência retorna `CONFLITO_SEQUENCIA`.

No primeiro fato, o movimento anterior, situação e posição de origem ficam desconhecidos e a quantidade anterior é zero; a quantidade final precisa coincidir com a quantidade inicial da embalagem. Nos seguintes, a origem é fotografada da projeção bloqueada. Movimento e atualização de quantidade, situação, posição, posse, Bag, último movimento, versão e autoria confirmam ou desfazem juntos. O núcleo não chama ERP e não define o efeito de uma operação específica.

### 10.1 Consulta da projeção atual de etiquetas — primeiro recorte de rastreio

O contrato `consultarEtiquetas` / `GET /etiquetas` é o primeiro recorte implementado em `contr-emb-rastreio.p`. Ele consulta a projeção atual de `contr_emb_etiqueta`; não gera identidade, movimento ou efeito no estoque padrão.

Filtros opcionais: `codEstabel`, `codEtiqueta`, `item`, `lote`, `codTipo`, `tipoControle`, `tipoLocal`, `situacao` e `idBag`. A paginação usa `aposId`, ordenação crescente por `id-etiqueta`, limite padrão 20 e máximo 100. `idBag = 0` significa ausência de filtro por Bag; valor negativo é inválido.

O Dataset fornece `usuario` e repete `estabelecimentoPermitido` para cada estabelecimento autorizado. Lista vazia nega a consulta. Quando `codEstabel` é informado, ele também precisa pertencer à lista. Sem filtro explícito, o núcleo ainda elimina qualquer registro cujo estabelecimento atual não pertença à lista confiável.

A resposta contém identidade e origem, item/tipo/lote/validade, capacidade e quantidades, estabelecimento/depósito/localização atuais, custódia, Bag, situação, último movimento e versão. Os IDs são serializados como texto no REST. `tipo-controle` distingue `EMBALAGEM` de `PRE_SALDO`; a consulta não transforma PRE em etiqueta nem atribui a ele movimento ou Bag.

Este contrato resolve a visibilidade da projeção atual pelo estabelecimento corrente. A consulta histórica de movimentos permanece sem implementação até definir a visibilidade de fatos que cruzam estabelecimentos de origem e destino.

Evento idempotente e aplicação de movimento são capacidades compartilhadas com Bag e demais fluxos; sua implementação deve ser única. Recebimento de transferência terá sua própria regra de rateio e utilizará essas mesmas capacidades, sem passar pelo cálculo de novas etiquetas.

Antes de implementar: classificação fiscal; ponto confirmado do recebimento; chaves de documento/ciclo/item/lote; cancelamento; volume transacional; parâmetros alterados antes do primeiro processamento; impressão e perfis. Não portar do legado dependências de `etiquetas-CD`, etiquetas-mãe, referência ou movimentos ERP auxiliares.

## 11. Recebimento fiscal legado — referência dos caminhos existentes

Levantamento contextual (DT-028), sem aprovação de porte dessas rotinas para o novo fluxo:

| Fonte e trecho | Comportamento observado |
|---|---|
| `referencias/fontes-prod-legado/recebimento_fiscal.p:285`, `pi-recebimento-fiscal` | Recebe cabeçalho/itens, consulta a natureza, prepara dados fiscais, depósito/localização e integra o documento. |
| Mesmo fonte, linha 415 | Espécie 23 ou terceiros encaminha a `pi-executa-reapi316a`; demais casos chamam `rep/reapi190.p`. |
| Mesmo fonte, linha 434 | Consulta o documento resultante. Não há chamada direta de geração de etiquetas específicas nessa procedure. |
| `referencias/fontes-legado/recebimento_fiscal_v2.p:574` | Evolução distingue transferência, terceiros sem estabelecimento correspondente ao emitente, emitente vinculado a estabelecimento e o ramo restante. |
| Evolução, linhas 1127 e 1249 | `pi-recebe-terceiros` e `pi-recebe-empresas-diferentes` especializam o recebimento dos respectivos ramos. |

A geração encontrada em `referencias/fontes-prod-legado/etiquetasCD.p:242`, `pi-gera-etiquetas`, é outra rotina, dependente do saldo e da referência legados. Sua existência não comprova uma chamada direta pelo recebimento fiscal; o encadeamento completo do Fluig não está demonstrado por esses dois fontes isoladamente.

O responsável técnico destacou a distinção funcional entre terceiros e transferência entre estabelecimentos da mesma empresa. No fonte evoluído, o ramo de transferência (espécie 23) usa `pi-executa-reapi316a`, que chama `rep/reapi316a.p` na linha 1078. O ramo `pi-recebe-terceiros` usa diretamente as BOs `inbo/boin090.p`, `inbo/boin176.p` e `inbo/boin404re.p` (linhas 1130–1132). `pi-recebe-empresas-diferentes` também chama `rep/reapi316a.p` na linha 1409, com preparação própria. Portanto, os dois tratamentos funcionais não equivalem a uma correspondência exclusiva entre uma REAPI e cada tipo de operação; o ramo restante de `pi-recebimento-fiscal` chama `rep/reapi190.p`.

No novo projeto, os caminhos de transferência acima não limitam o catálogo: devoluções, empréstimos, cancelamento de notas e renovação de empréstimos também serão detalhados. Reutilizar evento, operação, saldo e movimento sem tratar eventos fiscais distintos como se tivessem o mesmo efeito físico.

## 12. Contratos padrão consultados — 04/09/2026

O levantamento individual do TDN está em `referencias/padrao-datasul/MAPEAMENTO_APIS_BOS.md`, com matriz de transações e estados no catálogo estruturado da biblioteca (DT-030). Foram analisadas preliminarmente 26 documentações de APIs/BOs; nenhuma nova procedure específica foi implementada ou teve contrato JSON aprovado nesta etapa.

Para faturamento, a documentação sustenta candidatos da família BODI317, métodos específicos de devolução/terceiros na SD, efetivação na EF e consultas BODI135/135NA. A EF2 é interna. Na entrada, REAPI190 não cobre transferência/terceiros; REAPI316A, BOIN090 e BOIN404RE continuam exigindo fontes/includes. A BOIN404TE também deve ser obtida, como dependência documentada da SD na saída com terceiros. Preservar a distinção entre candidato documental, chamada legada e implementação homologada.

## 13. Cruzamento dos eventos com os canais de execução — DT-031

A [matriz de execução](../referencias/padrao-datasul/MATRIZ_EVENTOS_EXECUCAO.md) detalha as operações fiscais iniciadas no Fluig ou no Datasul e os pontos de captura de recebimento, efetivação, estoque, cancelamento e desatualização. Nenhuma linha da matriz representa nova procedure aprovada ou implementada.

Capacidades propostas para reaproveitamento no domínio ABL: validar/persistir seleção; correlacionar solicitação e documentos gerados; reconhecer ocorrência ERP e ciclo; aplicar rateio e movimento confirmado; reconciliar resultado incerto; avaliar e executar compensação autorizada pela regra. Expor ao Fluig pela fronteira REST e reutilizar internamente nas extensões do padrão, sem duplicar regra por canal. Nomes, assinaturas e agrupamento em arquivos serão fechados com os fontes e contratos.

O evento fim-atualizacao está observado no legado. Os demais localizadores documentados para integração GFE são pistas para inspeção dos fontes, não hooks implementados do Controle de Embalagens. Estoque automático e desatualização FT2100 também exigem cobertura; a regra não pode ficar somente no botão de emissão da tela Fluig.

## 14. Fontes das interfaces Fluig recebidos — DT-032

Complemento posterior DT-033: [Devoluções e reversões](../referencias/padrao-datasul/DEVOLUCOES_E_REVERSOES.md) relaciona as consultas de origem do pré-faturamento legado, BOs candidatas e capacidades de seleção/rateio/compensação. Nenhuma nova procedure foi aprovada por esse mapeamento.

Os quatro repositórios e a primeira relação entre ações, Datasets e procedures estão em [fontes Fluig recebidos](../referencias/fontes-fluig-github/README.md). Manutenção v2 e Bags são referências de homologação legada; o formulário é legado a substituir; `Monitor-Xml` é um esboço com dados simulados. Conforme DT-052, a pré-aprovação das fazendas deve validar primeiro o AED padrão do ANFE; portanto, nenhuma procedure ou Dataset do Monitor será contratada antes da demonstração. Os nomes `pi-*` encontrados nesses widgets são chamadas legadas, não novos contratos aprovados. Próximo detalhamento: cruzar cada ação necessária com o ABL correspondente e com os eventos da matriz, preservando a interface e substituindo as dependências incompatíveis com o modelo atual.

## 15. ET-01A — Validação pura de campos do tipo

**Contrato fechado em 07/09/2026 — DT-037; ABL executado no OpenEdge 12.2 de TESTE em 10/09/2026.** Componente interno, sem endpoint e sem acesso ao banco. Não libera BAG-02/03 nem o CRUD completo. As procedures públicas anteriores continuam propostas.

`validarTipo` é uma procedure interna de `fontes/progress/contr-emb.p`, com os parâmetros posicionais abaixo. A futura fronteira JSON fará a validação de tipos JSON e chamará este componente; ele não recebe `oInput`, credenciais ou identidade de usuário.

| Direção | Parâmetro ABL | Tipo | Contrato |
|---|---|---|---|
| Entrada | pcCodTipo | CHARACTER | Código manual, obrigatório, 2–3 caracteres após retirar espaços ASCII externos; letras ASCII convertidas para maiúsculas; somente A–Z e 0–9. |
| Entrada | pcDescricao | CHARACTER | Descrição obrigatória, até 100 caracteres depois de retirar espaços ASCII externos; rejeitar texto composto apenas de espaços/tabulações/quebras. |
| Entrada | plAtivo | LOGICAL | YES ou NO; desconhecido rejeitado. |
| Saída | pcCodNormalizado | CHARACTER | Código normalizado somente no sucesso; vazio na falha. |
| Saída | pcDescricaoNormalizada | CHARACTER | Descrição normalizada somente no sucesso; vazia na falha. |
| Saída | plValido | LOGICAL | YES somente se os três campos forem válidos. |
| Saída | pcErro | CHARACTER | Vazio no sucesso; CODIGO_INVALIDO, DESCRICAO_INVALIDA ou SITUACAO_INVALIDA. |
| Saída | pcMensagem | CHARACTER | Mensagem controlada; não reproduz entrada ou exceção. |

A validação falha na primeira inconsistência, na ordem código, descrição, situação. Códigos são texto: preservar zeros à esquerda e aceitar `1PL` conforme DT-023. Descrição é contada em caracteres; JavaScript conta pontos de código, sem confundir pares UTF-16 com dois caracteres. Compatibilidade de caracteres no codepage OpenEdge deve ser conferida no teste remoto. O componente não acrescenta capacidade ao tipo, não recebe versão e não modifica dados.

Apoio Fluig: `fontes/fluig/componentes/validar-tipo.js`, função `validarTipo({codTipo, descEmbalagem, ativo})`, devolve `{sucesso, codigoErro, mensagem, dados}`; `dados` é null na falha e contém apenas os três campos normalizados no sucesso. Exige strings e booleano reais, sem coerção de número ou texto em identificador/situação. Esta checagem melhora o preenchimento; o serviço ABL continuará como autoridade na gravação futura.

Critérios: formatos válidos DT-023, zeros preservados, minúsculas normalizadas, código com 1/4 caracteres ou sinais rejeitado, desconhecidos/vazios rejeitados, descrição com 100 aceita e 101 rejeitada, ativo false aceito, execução repetida sem efeito lateral. Testes de banco, concorrência cadastral, repetição durável e contrato Widget/Dataset/API ficam para o CRUD, não são simulados como aprovados.

## 16. ET-01C — Validação pura de campos da parametrização

`validarParametro` é uma procedure interna de `fontes/progress/contr-emb.p`, sem endpoint, consulta ou gravação. Entradas posicionais: `pcEstabelecimento`, `pcItem`, `pcCodTipo` CHARACTER, `pdCapacidade` DECIMAL, `pcUnidade` CHARACTER e `plAtivo` LOGICAL. Saídas: estabelecimento, item, tipo e unidade normalizados, `plValido`, `pcErro` e `pcMensagem`.

Estabelecimento, item e unidade são obrigatórios e perdem somente espaços ASCII externos; seus códigos não são convertidos nem validados contra cadastros nesta rotina. Tipo segue a regra ET-01A: 2–3 caracteres ASCII alfanuméricos e letras em maiúsculas. Capacidade deve ser conhecida e maior que zero; a escala física de quatro casas pertence ao campo implantado. Situação precisa ser YES ou NO. A validação falha na primeira inconsistência, na ordem estabelecimento, item, tipo, capacidade, unidade e situação. Na falha, todas as saídas normalizadas permanecem vazias; no sucesso, a mensagem e o código de erro ficam vazios.

Códigos funcionais: `ESTABELECIMENTO_INVALIDO`, `ITEM_INVALIDO`, `TIPO_INVALIDO`, `CAPACIDADE_INVALIDA`, `UNIDADE_INVALIDA` e `SITUACAO_INVALIDA`. O aceite puro cobre sucesso, normalização, inativo, ausente/vazio, tipo inválido, capacidade desconhecida/zero/negativa, capacidade fracionária positiva e repetição. Existência do estabelecimento/item/tipo, tipo ativo, unidade de estoque compatível com o item, autorização e unicidade do par estabelecimento/item pertencem a `salvarParametro` e continuam dependentes do contrato integrado.

### 16.1 ET-01F — Gravação integrada da parametrização

**Contrato fechado em 10/09/2026 — DT-050.** `salvarParametro`, procedure interna de `contr-emb.p`, executa `INCLUIR`, `ALTERAR`, `INATIVAR` e `EXCLUIR`. A inclusão exige `id-param = 0` e versão esperada zero; as demais ações exigem identificador positivo e versão atual. Código do estabelecimento e item são imutáveis após a inclusão; para trocar o par, excluir e cadastrar novamente.

A entrada contém ação, identificador, estabelecimento, item, tipo, capacidade, unidade, situação, **lote de migração e validade de migração (DT-068, antes da versão)**, versão esperada e o contexto confiável já usado por `salvarTipo`: origem, chave idempotente, hash da chave, hash do conteúdo, usuário e autorização resolvida. A saída informa sucesso, repetição, identidade e fotografia normalizadas, versão resultante, exclusão, evento e erro funcional. O resultado concluído fica recuperável em `contr_emb_evento`.

Além de `validarParametro`, o comando confirma a existência de `estabelec.cod-estabel` e `mgcad.item.it-codigo`, exige unidade igual a `mgcad.item.un` e tipo existente e ativo ao incluir ou deixar o parâmetro ativo. Conforme DT-055/057/058, ativação converte para Lote quando necessário e a retirada do último parâmetro ativo do item converte Lote → Serial; ambas confirmam o tipo padrão antes de concluir parâmetro, evento e auditoria. A DT-059 definiu `contr-emb-conversao.p` para combinar `CDAPIITEM` com o tratamento backend das tabelas relacionadas. O `v80in172.w` confirmou as rotas: Serial → Lote usa a lógica de `ce0111.i`; Referência → Lote usa `.i2`, preserva o lote na maior parte das tabelas, mas limpa `ped-saldo.lote`; Lote → Serial usa `.i` com valores vazios e consolida o histórico. Referência → Lote consolida linhas operacionais equivalentes conforme DT-061, com tratamento de todas as referências, inclusive F, conforme DT-063. Lote → Serial deve recusar enquanto houver outro parâmetro ativo, embalagem/saldo individual ativo, operação aberta ou dependência não conciliada. O par estabelecimento/item é único. ET-01H comprovou execução e rollback integral de Serial → Lote; DT-068 liga o conversor ao comando: a recusa prévia ITEM_SEM_CONTROLE_LOTE foi substituída pela conversão condicionada e seus erros; a nova revisão exige SAVE/ET-01F antes do uso REST. Ensaios isolados dos três caminhos passaram, sem homologar a integração. Os códigos atuais do CRUD continuam sendo `SEM_PERMISSAO`, `CONTEXTO_INVALIDO`, `VERSAO_INVALIDA`, `ESTABELECIMENTO_NAO_ENCONTRADO`, `ITEM_NAO_ENCONTRADO`, `UNIDADE_DIVERGENTE`, `ITEM_SEM_CONTROLE_LOTE`, `TIPO_NAO_ENCONTRADO`, `TIPO_INATIVO`, `PARAMETRO_JA_EXISTE`, `PARAMETRO_NAO_ENCONTRADO`, `CHAVE_IMUTAVEL`, `CONFLITO_VERSAO`, `SEM_ALTERACAO`, `CONFLITO_IDEMPOTENCIA`, `COMANDO_EM_PROCESSAMENTO` e `RESULTADO_INVALIDO`.

Inclusão usa `CONTR_EMB_PARAM_SEQ`. Toda mudança efetiva grava evento e auditoria atomicamente; exclusão física registra a fotografia anterior e não apaga fatos históricos. O aceite ABL deve cobrir validações cadastrais, inclusão, repetição, conflito, alteração, inativação, exclusão e rollback sem massa residual. REST, Dataset e tela permanecem em recorte posterior.

### 16.2 ET-01H — Conversão backend do controle do item

`contr-emb-conversao.p` é um serviço técnico do núcleo, definido pela DT-059. Não é endpoint nem CRUD adicional. `analisarConversao` recebe item, tipo de destino, lote e validade de migração e devolve o tipo de origem, quantidade de colisões de saldo, diagnóstico por tabela, sucesso e erro. Essa operação não grava dados.

DT-065: quando o item já tem o tipo solicitado, a análise devolve sucesso, zero colisões e diagnóstico vazio sem verificar pré-condições de mutação nem carregar histórico. `converterControleItem` confirma o tipo final e `plAlterou=NO`, sem chamar CDAPIITEM. Item inexistente permanece erro.

`converterControleItem` recebe os mesmos dados e devolve tipo de origem/final, indicação de alteração, diagnóstico, sucesso e erro. São aceitos Serial `1` → Lote `3`, Referência `4` → Lote `3`, Lote `3` → Serial `1` e repetição com tipo já igual. Serial → Lote exige lote e validade atual ou futura; Referência → Lote ignora lote/validade de migração, preserva os existentes e consolida todas as referências equivalentes em saldo-estoq conforme DT-061/063/065, inclusive F com quantidade não zero. Soma qtidade-atu/ini/fin, qt-alocada, qt-aloc-prod e qt-aloc-ped; conserva máximas datas de entrada/contagem. Prioriza sobrevivente não F e conserva seus demais atributos originais, inclusive fabricação/lógico. Não exigir igualdade desses atributos entre referências F ou operacionais. Grupo apenas F conserva uma linha original e todas as somas. COLISOES_SALDO conta linhas colidentes, não grupos únicos, e pode ser positivo com SUCESSO=SIM. COLISAO_CAMPOS_SALDO fica restrito a quantidade/alocação desconhecida. COLISAO_VALIDADE_LOTE permanece uma limitação própria: não fundir validades diferentes na mesma posição/item/lote até comprovar a chave física de coexistência. Nenhuma comparação genérica de todos os campos é executada.

Na execução, `alterarTipoPelaCdApiItem` monta a estrutura comprovada no legado, chama `cdp/cdapiitem.p`, `setTTItem` e `validateSaveImplantacao`; depois `atualizarHistorico` aplica as rotas backend adaptadas de `ce0111.i`/`.i2`, `.i3` e `.i4`. O contrato da CDAPI e esses tratamentos internos ficam consolidados em `contr-emb-conversao.p`; seu único `.i` contém a temp-table compartilhada com os chamadores. O conjunto não usa frame, Viewer ou acompanhamento visual. ET-01H comprovou no caminho Serial → Lote que a procedure participa da transação externa: o tipo chegou a `3`, e o `UNDO` restaurou os 27 saldos, a quantidade `2963,2` e o estado de `ped-saldo`. O executor generalizado foi recompilado com `FONTES=3 FALHAS=0` e encerrou a regressão 1→3 com as cinco verificações aprovadas, `TOTAL=5 FALHAS=0`. A DT-061 preparou a consolidação 4→3 no mesmo núcleo e executor: somas por posição/lote/validade dos cinco campos de quantidade, maiores datas e restauração dos campos fotografados após rollback. Preparação histórica DT-061 superada pela DT-065 e pelos ensaios isolados aprovados: 4→3 em 16/09 (6/0) e 3→1 em 17/09 às 10:02 (6/0), após cadastro da despesa 645. Integração à parametrização e reconciliação persistida continuam pendentes. Códigos iniciais: `ITEM_NAO_ENCONTRADO`, `ITEM_POLITICA_CONFIGURADA`, `TRANSICAO_NAO_SUPORTADA`, `LOTE_MIGRACAO_NAO_INFORMADO`, `VALIDADE_MIGRACAO_INVALIDA`, `CUSTO_ESPECIFICO_INCOMPATIVEL`, `PARAM_GLOBAL_NAO_ENCONTRADO`, `COLISAO_VALIDADE_LOTE`, `COLISAO_CAMPOS_SALDO`, `CDAPIITEM_RECUSOU`, `FALHA_CDAPIITEM`, `FALHA_ATUALIZACAO_HISTORICO`, `TIPO_NAO_CONFIRMADO` e `FALHA_CONVERSAO`.

## 17. ET-01B — Consultas internas Progress

Contrato definido antes dos fontes em 07/09/2026 (DT-038). São componentes ABL internos de leitura. Campos retornados herdam as tabelas específicas do modelo v1.7, já implantado e conferido em TESTE. As duas consultas compilaram e passaram nos cenários sobre a base vazia; filtros e paginação com massa continuam pendentes. O adaptador REST cadastral já as expõe, sem alterar seu papel interno. Não consultam tabelas específicas legadas nem executam gravações. Os includes são projeções transitórias, não novas tabelas físicas.

### 17.1 Tipos

`consultarTipos`, procedure interna de `contr-emb.p`: entradas posicionais `plAutorizado` LOGICAL, `pcCodigoDe`, `pcCodigoAte`, `pcDescricao`, `pcAposCodigo` CHARACTER, `plAtivo` LOGICAL, `piLimite` INTEGER. Saídas: TABLE `ttEmbTipo`, `plTemMais` LOGICAL, `pcProximoCodigo` CHARACTER, `plSucesso` LOGICAL, `pcErro`, `pcMensagem` CHARACTER.

Permissão deve ser YES, resolvida na camada confiável anterior; NO/desconhecido nega sem leitura. Códigos de filtro/cursor são normalizados para maiúsculas e sem espaços externos; limites são inclusivos, cursor exclusivo, ordenação `cod-tipo`. Código de/até iguais permite buscar um tipo; ausente retorna coleção vazia com sucesso. Texto de descrição é busca literal, sem wildcard; case/acento seguem a collation do banco. Situação desconhecida significa todas; YES/NO filtra ativos/inativos.

### 17.2 Parâmetros

`consultarParametros`, procedure interna de `contr-emb.p`: entradas posicionais TABLE `ttEmbEstabelPermitido`, `pcEstabelDe`, `pcEstabelAte`, `pcItemDe`, `pcItemAte` CHARACTER, `plAtivo` LOGICAL, `piAposId` INTEGER, `piLimite` INTEGER. Saídas: TABLE `ttEmbParametro`, `plTemMais` LOGICAL, `piProximoId` INTEGER, `plSucesso` LOGICAL, `pcErro`, `pcMensagem` CHARACTER.

Lista de estabelecimentos é fornecida exclusivamente pelo adaptador de autorização confiável, nunca pela requisição do usuário. Lista vazia ou com código vazio/desconhecido nega acesso. Os filtros de estabelecimento e item são faixas inclusivas, vazias significam sem aquela restrição adicional; a autorização permanece obrigatória. Estabelecimento/item não são convertidos para número ou normalizados para outro código. Cursor por `id-param` ascendente, exclusivo; 0 inicia a primeira página. Negativo/desconhecido é inválido. Campos retornados correspondem ao cadastro; nenhuma descrição de item/estabelecimento é inventada ou buscada por banco lógico presumido.

### 17.3 Comum e cenários

Limite 0 ou desconhecido usa 20; de 1 a 100 é aceito; negativo ou acima de 100 falha. Teto é limite técnico do contrato, não filtro de teste. Texto de filtro desconhecido e faixa invertida falham. Na consulta de tipos, filtros/cursor de código limitados a 3 caracteres e descrição a 100. Em retorno funcional normal de falha, coleção vazia, temMais NO e cursor vazio/0. Em exceção ABL propagada, parâmetros OUTPUT não têm retorno garantido: o chamador deve limpar as saídas antes e descartá-las integralmente se a chamada falhar, nunca reaproveitando a página anterior. `total` é a quantidade da página obtida pelo chamador, não uma contagem global. Quando houver mais um registro autorizado correspondente, temMais YES e cursor aponta para o último retornado; caso contrário cursor vazio/0. A próxima chamada conserva filtros/permissões; NO-LOCK não promete fotografia consistente entre páginas sob alteração concorrente. Após alteração de filtros, iniciar outra paginação.

INTEGER permanece INTEGER em ABL. No adaptador JSON vigente, identidades técnicas e cursores de ID são texto decimal; versões e contagens são números inteiros. Não há idempotência de comando nesta consulta; repetição, sem alteração de dados, reproduz a página. Dados desconhecidos/corrompidos não devem ser inventados; erros ABL de infraestrutura seguem ao chamador, que deve sanitizar a resposta pública. Nenhum catch deve transformar falha de banco em coleção vazia com sucesso.

Aceite remoto: base vazia; tipo por faixa exata; ativo/inativo/todos; descrição literal contendo `*`; 20 e 21 registros; cursor da página seguinte; intervalo invertido; limites inválidos; consulta repetida; lista de estabelecimentos vazia; dados de outro estabelecimento excluídos antes da paginação; IDs acima de 2^53 preservados no ABL; tabela/compilação ausente deve falhar. Permissão de endpoint e testes Widget/Dataset ficam fora deste componente e continuam obrigatórios antes de exposição pública.

## 18. ET-06/ET-07 — consultas para continuidade no Fluig

**Situação em 10/09/2026 — DT-047:** nomes e responsabilidades em levantamento; nenhum contrato ABL aprovado ou fonte implementado. As rotinas ficarão dentro de `contr-emb-operacao.p`, sem arquivo por consulta.

| Rotina candidata | Papel | Evidência existente | Fechar antes do código |
|---|---|---|---|
| `consultarNaturezasOperacao` | Retornar as naturezas permitidas e o ramo de negócio que cada uma habilita. | A manutenção já consulta natureza; o padrão abre a sequência conforme a natureza. | Fonte padrão, estabelecimento, usuário/perfil e mapa natureza → transferência/devolução/terceiros → BO. |
| `consultarOrigensDevolucao` | Listar documentos/remessas que podem ser usados como origem da operação. | `form-receb-material` chama `pi-retorna-doc-origem`; ABL legado consulta `saldo-terc`. | Chave canônica completa, situação, saldo, período, autorização, filtros e paginação. |
| `consultarItensOrigem` | Detalhar itens e quantidades da origem para seleção total ou parcial. | `form-receb-material` chama `pi-retorna-itens-origem`; legado usa `saldo-terc`, `it-nota-fisc` e `fat-ser-lote`. | Quantidade original, já devolvida, alocada e disponível; unidade, lote, posição, sequência e contrato FT4011/FT4012 instalado. |
| `validarRateioOperacao` | Conferir documento/linha de origem, itens, quantidades e etiquetas antes da emissão. | A tela atual já seleciona etiquetas e o legado associa itens/etiquetas. | Parcialidade, arredondamento, múltiplas origens, concorrência e tratamento de itens sem controle específico. |
| `consultarResultadoOperacao` | Retomar uma solicitação e informar processamento, documentos, erros e efeitos confirmados. | O legado possui pré-faturamento, arquivo de acompanhamento e reprocessamento. | CONS-03, estados persistidos, chave idempotente, documentos gerados, falha incerta e prazo de retenção. |

Pela DT-093, `consultarNaturezasOperacao` alimentará o modal único da operação documental. O ramo apresentado pelo Widget precisa vir da leitura/classificação dos atributos e parametrizações atuais da natureza no Datasul e ser revalidado no comando de criação; atalhos de interface somente restringem opções. `natur-oper.transf` e `natur-oper.terceiros` constam dos fontes legados, mas ainda não formam contrato completo para todos os ramos. Códigos fixos são aceitos só em executores isolados de TESTE. Devolução de compra e retorno de empréstimo reutilizam a experiência visual, sem unificar seus contratos padrão. Complemento de 01/10: contrato ABL interno `classificarNaturezaOperacao` implementado em `contr-emb-operacao.p`, com SAVE 2/0 e conferência E07 15/0 aprovados em 01/10 14:23; nenhum endpoint REST foi acrescentado. INPUT `pcNatureza`; OUTPUT `pcFluxo`, `pcRamoPadrao`, `plExigeOrigem`, `plEditaQuantidade`, `plEditaPreco`, `plSucesso`, `pcErro`. Consulta `mgcad.natur-oper` NO-LOCK, sem escrita. NFD → DEVOLUCAO_COMPRA/FT4011; NFS ou NFT de terceiros tipo 3 → REMESSA_TERCEIROS/DIRETO; tipos 2/5 → RETORNO_TERCEIROS/FT4012; 4 → FATURAMENTO_CONSIGNACAO/FT4012; 6 → REAJUSTE_TERCEIROS/FT4012, preço editável e quantidade não editável. FT4012 exige origem. NFT de transferência sem terceiros → TRANSFERENCIA/DIRETO. Outros ramos retornam NATUREZA_FORA_DOS_RAMOS_SUPORTADOS; vazio/desconhecido retorna PARAMETRO_INVALIDO e cadastro ausente NATUREZA_NAO_ENCONTRADA. Todos os outputs são reiniciados a cada chamada. Sucesso é classificação, não liberação fiscal: naturezas amigáveis e validadores BO permanecem necessários. A chamada não cria WT, não abre tela e não altera o tratamento FT2100. Origem/seleção e comando deverão chamar novamente a classificação; integração ainda pendente.

As procedures legadas não serão portadas porque dependem de `tipo-con-est = 4`, `cod-refer` e `etiquetas-CD`. Os campos úteis serão recontratados sobre o padrão Datasul e o modelo `contr_emb_*`. A análise detalhada está em [`docs/entregas/LEVANTAMENTO_FLUIG_SAIDAS_DEVOLUCOES.md`](entregas/LEVANTAMENTO_FLUIG_SAIDAS_DEVOLUCOES.md).

## 19. ET-01D — Primeiro comando cadastral de tipo

`salvarTipo`, procedure interna de `contr-emb.p`, recebe ação (`INCLUIR`, `ALTERAR` ou `INATIVAR`), código, descrição, situação, versão esperada, origem, chave idempotente, hashes canônicos, usuário validado e autorização resolvida. Retorna sucesso, repetição, código/descrição/situação normalizados, versão resultante, `id-evento`, código de erro e mensagem sanitizada. O adaptador REST vigente converte JSON para esse contrato e calcula os hashes; permissão e usuário deverão ser injetados pelo Dataset/serviço autorizado, sem confiança em valores livres do Widget.

Na inclusão, versão esperada é zero, o código precisa estar livre e a versão resultante é 1. Alteração e inativação exigem registro existente e versão esperada positiva coincidente; código é imutável e versão incrementa uma vez. Inativar mantém descrição e define `ativo = NO`. Alteração pode mudar descrição e situação, mas requisição sem mudança devolve sucesso sem nova versão somente quando for repetição do mesmo evento concluído; uma nova chave sem alteração é rejeitada como `SEM_ALTERACAO`.

O comando valida os campos antes de iniciar efeitos. Sem autorização retorna `SEM_PERMISSAO`; identidade/origem/chave/hash inválidos retornam `CONTEXTO_INVALIDO`; chave existente com conteúdo diferente retorna `CONFLITO_IDEMPOTENCIA`; ausência ou existência incompatível retorna `TIPO_NAO_ENCONTRADO`/`TIPO_JA_EXISTE`; versão divergente retorna `CONFLITO_VERSAO`. Falha de infraestrutura é propagada e sanitizada na fronteira pública.

Para chave nova, cria `contr_emb_evento` de tipo `CADASTRO_TIPO`, aplica a mudança em `contr_emb_bag`, grava uma linha de `contr_emb_audit` e conclui o evento com resultado recuperável na mesma transação. A auditoria usa `INCLUSAO` ou `ALTERACAO`; inativação é alteração de `ativo`. Repetição concluída não cria outra auditoria. Não há `contr_emb_evento_item`, movimento, documento fiscal ou efeito em estoque.

Aceite mínimo em TESTE: sem permissão; entrada inválida; inclusão; repetição idêntica; conflito de conteúdo; código existente; alteração; conflito de versão; inativação; nova chave sem mudança; auditoria única; rollback integral sob erro. Os testes devem usar códigos reservados para teste e limpar/compensar a massa de forma controlada, sem tocar registros funcionais.

## 20. ET-01G — Adaptador REST e autorização Fluig

**Recorte cadastral publicado e em validação em 11/09/2026 — DT-054.** O fonte `fontes/progress/esp/api/v1/controle-embalagens.p` concentra as rotas REST de tipos, parametrização e consulta de etiquetas. Para os cadastros, delega às seis procedures internas de `contr-emb.p`. Não há um arquivo `.p` por CRUD ou por tela. A revisão cadastral foi compilada/publicada; a revisão atual acrescida de ET-02A compilou em TESTE, mas ainda aguarda publicação e validação REST.

As rotas cadastrais são `GET /tipos`, `POST/PATCH /tipos`, `GET /parametros` e `POST/PATCH /parametros`, relativas ao recurso `prg/esp/v1/controle-embalagens`. Exclusão de parâmetro é a ação `EXCLUIR` de um `PATCH`, para não depender de corpo em `DELETE`. O adaptador também declara `GET /etiquetas`, cuja implementação e teste pertencem à ET-02A. O contrato JSON, exemplos e critérios de aceite cadastral estão em [`ET-01G_API_REST_CADASTROS.md`](entregas/ET-01G_API_REST_CADASTROS.md).

O estado comparável de todas as rotas declaradas e das capacidades futuras está em [`MATRIZ_APIS_REST.md`](entregas/MATRIZ_APIS_REST.md). O catálogo permanece como fonte do contrato; a matriz acompanha implementação, autorização, evidência e próximo fechamento.

O grupo do usuário, a exibição da tela e a autorização funcional pertencem ao Fluig. O Dataset deverá obter `WKUser`, validar o grupo e reconstruir a requisição para o serviço autorizado. Para parâmetros, a lista `estabelecimentoPermitido` (consulta) ou `estabelecimentosPermitidos` (comando) deve ser produzida pelo Dataset, nunca copiada de campos livres do Widget. O ABL exige essa lista e confere o estabelecimento do comando; não interpreta códigos de grupo nem usa `usuar-depos` como substituto da regra Fluig. Códigos de grupos, visão global e relação grupo → estabelecimento continuam pendentes. Como o adaptador atualmente recebe esse contexto na própria requisição, o endpoint de TESTE não deve ser considerado uma fronteira produtiva segura até a cadeia autorizada ser homologada.

O adaptador e o núcleo foram compilados e publicados no OpenEdge/PASOE de TESTE. O ciclo REST de tipos passou, incluindo inclusão, repetição, conflitos, alteração, inativação, reativação e leitura final. As recusas de parâmetro por permissão, unidade divergente e item sem lote também passaram. A homologação do recorte permanece pendente pela ação única de parametrizar/converter o item, pelo ciclo positivo de parâmetros e pelo teste integrado Widget → Dataset → serviço autorizado → API.



DT-063 — checkpoint vigente de 16/09: todas as referências, inclusive F, entram nas seis somas de quantidade/alocação por estabelecimento/depósito/localização/item/lote/validade. F000050/PL-100 com 1/0 resulta em saldo 1; F não exige saldo zero. Consolidar antes de retirar cod-refer, preservando uma sobrevivente não F quando existir. Diferenças de dt-fabric/log-reg-zero em F não substituem os dados operacionais; demais incompatibilidades continuam identificadas por campo, sem escolher valores arbitrários. Grupo apenas F também conserva todas as quantidades. Executor verifica seis somas, maiores datas de todas as linhas, metadata da sobrevivente e restauração por ROWID. DT-063 substitui exclusão das somas/restrição de F zeradas/FATURAMENTO_COM_VALOR_PENDENTE da DT-062, que foram interpretação errada do assistente e retiradas antes de ensaio. Revisão estática; nova compilação SAVE 5/0 e diagnóstico somente leitura em TESTE precedem mutação autenticada com rollback. 4→3, 3→1 e integração ao parâmetro pendentes; planner 51%, REST inalterado. Evidência: docs/entregas/evidencias/preparacao_agrupadoras_f_et01h_2026-09-16.md.

## 21. ET-01I — Apoios limitados das telas Fluig (DT-064)

Contrato aprovado para estabelecimento/item e implementado em fonte no mesmo núcleo/adaptador existente. **Compilado no OpenEdge e recorte ABL concluído em TESTE no ET-01I com 30/0 em 17/09 às 17:00; publicação REST/Dataset/homologação incremental pendentes.** Contrato completo, assinatura, autorização, paginação, erros e execução: [ET-01I_APOIOS_AUTOCOMPLETE.md](entregas/ET-01I_APOIOS_AUTOCOMPLETE.md). Procedures públicas `consultarEstabelecimentos` e `consultarItens`; `validarFiltroApoio` é auxiliar interno. GET `/apoios/estabelecimentos` e `/apoios/itens`, filtro 2–100 caracteres, limite padrão/teto 20, cursor exclusivo por código, autorização antes da leitura/paginação. Cadastro funcional em mgcad; nenhuma tabela física nova. Item é catálogo global, sem afirmar disponibilidade no estabelecimento selecionado.

Widget reutiliza `autocomplete-limitado.js` com transporte injetado. Não implementa autoridade de identidade/grupos; Dataset autorizado continua dependência. O exemplo pioneiro de CD permanece independente. Os demais apoios e cada campo/ação por tela estão na [matriz de controles](entregas/MATRIZ_TELAS_CAMPOS_ACOES.md), como proposta/pendência quando sem fonte/contrato. Não transformar nomes dessa lista em procedure executável.

### 21.1 Cobertura completa dos autocompletes

O registro atual tem **25 campos autocomplete em 13 apoios**: estabelecimentos/destino, itens, tipos de embalagem, depósitos, localizações, lotes/validades, famílias, grupos de estoque, Bags/lacres, naturezas, contrapartes, documentos de origem e motoristas. Família e grupo têm entradas independentes; grupo de estoque não é grupo de autorização Fluig. Os destinos ainda exigem comprovação de origem/elegibilidade, sem presumir que permissão de origem serve para destino.

Os apoios ET-01I de estabelecimento/item estão implementados e aprovados no recorte ABL 30/0; o apoio específico de tipos com OR código/descrição da DT-070 também possui prova ABL e paginação DT-074. REST/Dataset e integração Fluig permanecem pendentes. O recorte de consulta de Bags está contratado na seção 22; os demais não possuem contrato executável fechado. O inventário completo, com IDs de tela/campo, procedure, método/rota, arquivo, estado e dependência, é gerado do mesmo `cobertura-telas.json` nas matrizes REST e Progress. Não declarar endpoints ou tabelas nativas para preencher lacunas. Busca de itens do documento e de etiquetas elegíveis continua consulta de botão; etiquetas por código, faixas/listas de notas e lacre digitado continuam filtros textuais até decisão diferente.

## 22. ET-05A — Consultas ABL de Bags (DT-066)

Contrato do recorte somente leitura, implementável sem fechar transições. Módulo `contr-emb.p`, mesmo include. Não substitui contrato completo das propostas BAG-04/BAG-08: resumo global, totais e REST permanecem pendentes.

- `consultarBags`: entrada TT `ttEmbEstabelPermitido`, `pcEstabel`, `piIdBag` (0 sem filtro), `pcFiltroLacre` (vazio ou prefixo de 2–40 caracteres), `pcCodTipo` (vazio ou código normalizado), `pcSituacao` (vazia ou domínio do modelo), `pdtInicio`/`pdtFim` (DATE opcionais inclusivas sobre DATE(dt-inclusao)), `piAposId` e `piLimite`. Saída `ttEmbBag`, `plTemMais`, `piProximoId`, `plSucesso`, `pcErro`, `pcMensagem`. Estabelecimento vazio lista somente autorizados. id positivo sem acesso/inexistente retorna `BAG_NAO_DISPONIVEL`, independentemente dos filtros de negócio; detalhe autorizado que não atende filtros resulta vazio. Projeção dos campos da ocorrência, sem resumo ou soma de conteúdo. Tipo não ativo permanece consultável historicamente.
- `consultarConteudoBag`: entrada TT permitidos, `piIdBag` positivo, `piAposId`, `piLimite`. Saída `ttEmbEtiqueta` e mesmos cinco controles. Autorizar Bag pelo responsável; devolver somente vínculos atuais cuja etiqueta esteja em estabelecimento autorizado. Não presumir que todos os vínculos continuam no estabelecimento da Bag; não excluir silenciosamente PRE/inconsistências por situação/tipo (a consulta não prova elegibilidade). Vazio autorizado é sucesso. Não revelar quantidade/conteúdo de estabelecimentos não autorizados.

Comum: IDs/cursor não desconhecidos e não negativos; limite zero usa 20, válido 1–20; lista de permissões vazia ou com identificador desconhecido/vazio nega antes da consulta funcional. Consulta estática em `mgesp`, NO-LOCK, ordenação por ID, buscar uma linha autorizada extra para temMais, cursor final zero. Sem snapshot transacional entre chamadas; conteúdo pode mudar. Falha técnica limpa projeções e controles e retorna `FALHA_CONSULTA` sanitizada. Erros: SEM_PERMISSAO, FILTRO_INVALIDO, LIMITE_INVALIDO, BANCO_MGESP_NAO_CONECTADO, BAG_NAO_DISPONIVEL, FALHA_CONSULTA. Autorização de grupos/tela no Dataset continua dependência.

## Validação posterior — 16/09, 17:13–17:21

Em 16/09/2026, SAVE 5/0 às 17:14, análise de 361378 com SUCESSO=SIM às 17:15 e conversão Referência→Lote com rollback às 17:21: TOTAL=6 FALHAS=0. Dentro da transação, 6.325 saldos consolidaram em 139 grupos, 33 referências F absorvidas, 17 estabelecimentos; após rollback, tipo 4 e 6.325 saldos restaurados, quantidade 39.252,73. Terceiros: 454 registros e quantidade 21.118 preservados/restaurados. Sem conversão persistida; 3→1, integração a salvarParametro e ensaio de atualização definitiva continuam pendentes.

ET-05A: núcleo e teste compilados; relatório geral 11/2 teve apenas os dois erros 468 ET-01H, resolvidos pelo SAVE 5/0 posterior. Execução funcional Bags ausente. Evidência consolidada: docs/entregas/evidencias/validacao_et01h_et05a_2026-09-16.md. Não constitui nova regra ou autorização de mutação definitiva.

## Checkpoint posterior — ET-05A às 17:35

ET-05A executado em TESTE em 16/09 às 17:35: cinco recusas passaram, TOTAL=5 FALHAS=0. MASSA_BAG_AUSENTE: consultas positivas, conteúdo, repetição e paginação não executados; homologação parcial. Núcleo/teste seguem compilados. Relatório geral das 17:34 teve três erros 468 apenas nos fontes ET-01H (conversor, análise e executor), já cobertos no SAVE 5/0 anterior; conversão 4→3 aprovada não precisa ser repetida.

compilar-consultas.p foi ajustado: somente quando o compilador retornar 468, refaz com SAVE em _validacao_compilacao sob a pasta do fonte. Não sobrescreve .r ativo nem executa procedure. Demais erros continuam falhas. Essa revisão do auxiliar ainda precisa ser compilada/executada no Studio; o alvo é FONTES=11 FALHAS=0. A pasta isolada não deve entrar no PROPATH da aplicação e não representa publicação.

Evidência: docs/entregas/evidencias/et05a_recusas_e_compilador_468_2026-09-16.md. Calendário e avanço oficial preservados; recusa aprovada sem massa não encerra a atividade.

## 17/09 — Diagnóstico 3→1 aprovado e geral 11/0

TXT recebidos em 17/09: compilacao-geral-20260917.txt às 09:47 confirma FONTES=11 FALHAS=0 e quatro recompilações 468 com SAVE isolado (núcleo, conversor, análise e executor). resultado-analise-conversao-et01h-3-1.txt às 09:50 confirma 357867, origem 3, destino 1, zero colisões e SUCESSO=SIM. Percorreu inventário 91, itens de notas 156, documentos 843, movimentos 4.478, saldos 1.191 e terceiros 133; it-dep-fat/ped-saldo sem massa. Análise somente leitura, ainda sem execução/rollback 3→1.

Próximo: executor existente com parâmetros 357867, 3, 1, lote vazio, validade desconhecida, em sessão Datasul TESTE autenticada. Não mudar fonte/lançador nem repetir 4→3. Integração à parametrização e homologação completa ainda pendentes. Evidência: docs/entregas/evidencias/diagnostico_et01h_3_1_2026-09-17.md.

## 17/09, 09:57 — 3→1 recusado por cadastro 645

Ensaio 3→1 de 357867 em TESTE, 17/09 às 09:57: CDAPIITEM_RECUSOU por Tipo Despesa 645 não cadastrado. TOTAL=6 FALHAS=2; EXECUTOU/TRATAMENTO=NAO. Item permaneceu 3, 1.191 saldos e quantidade 4.448,6 preservados; 133 terceiros e quantidade 33.148 preservados; 17 estabelecimentos. A análise prévia aprovada não cobria essa validação cadastral completa da CDAPIITEM.

ROLLBACK_INTEGRAL=NAO porque o executor exige execução e tratamento bem-sucedidos para aprovação integral; os quatro indicadores de restauração individual foram SIM. As duas falhas correspondem à execução/tratamento não realizados, não a divergência das fotografias. TIPO_DENTRO_TRANSACAO=0 é valor não preenchido após recusa, não prova que o item virou tipo 0.

Próximo: conferir/regularizar corretamente o Tipo Receita/Despesa 645 no CD0920 da homologação conforme cadastro de origem aprovado. Não substituir por código próximo, não criar valor arbitrário ou contornar validação no fonte. Conversor copia o cadastro e altera somente tipo-con-est. Após ajuste cadastral, repetir a mesma chamada autenticada do executor .r 357867, 3→1 com rollback, sem nova cópia ou compilação ABL; salvar execução em nome novo de TXT para preservar a recusa. Integração/persistência seguem pendentes.

Evidência: docs/entregas/evidencias/recusa_et01h_3_1_despesa645_2026-09-17.md.

## Checkpoint vigente — 17/09, 10:02: três caminhos com rollback aprovados

ET-01H 3→1 aprovado em TESTE em 17/09 às 10:02 após cadastro da despesa 645: item 357867, tipo 3→1 dentro da transação→3 após rollback, 1.191 saldos/quantidade 4.448,6 e 133 terceiros/quantidade 33.148 restaurados, 17 estabelecimentos, TOTAL=6 FALHAS=0. Ped-saldo sem massa. Os três caminhos isolados passaram: 1→3 5/0, 4→3 6/0 e 3→1 6/0. A recusa das 09:57 foi resolvida por cadastro, sem mudança no fonte. Evidência: docs/entregas/evidencias/validacao_et01h_3_1_2026-09-17.md.

**Próximo:** integrar conversor ao salvar/inativar parametrização e provar a transação conjunta, último parâmetro ativo, impedimentos, repetição e fluxo REST (ET-01F). Não repetir ensaios aprovados sem mudança relevante; não houve conversão persistida. Geral 11/0 já comprovado. Bags positivos seguem sem massa. Entrega corrente: pasta aberta ET-01_TESTE, sem ZIP automático.

## DT-068 — integração preparada, aguardando SAVE/ET-01F (17/09)

Conversor agora chamado por salvarParametro na mesma unidade de trabalho; contrato transitório de migração e proteções descritos no escopo 6.5/catálogo 16.1. Ensaios isolados 1→3, 4→3 e 3→1 seguem como evidências anteriores, sem aprovar a nova revisão. Fonte novo exige SAVE de nove fontes e executor ET-01F autenticado com rollback. Roteiro: docs/entregas/ET-01F_PARAMETRIZACAO_CONVERSAO.md. Evidência estática: docs/entregas/evidencias/integracao_parametro_conversao_dt068_2026-09-17.md. Impedimentos com massa, falha interna, concorrência e REST pendentes. Nenhum servidor reiniciado; entrega somente na pasta aberta, sem ZIP.

Entradas de migração são transitórias; Serial→Lote exige lote/validade explícitos. Inclusão inativa não converte. Retirada efetiva do último ativo inclui ALTERAR para inativo, INATIVAR e EXCLUIR. Bloqueio por item serializa CRUD específico; operações futuras precisam da mesma coordenação. Erros adicionais: ITEM_CONTROLE_DIVERGENTE (outro parâmetro ativo com item fora de Lote), CONTROLE_ESPECIFICO_ATIVO, OPERACAO_CONCILIACAO_PENDENTE e FALHA_PARAMETRIZACAO, além dos erros propagados pelo conversor. Migração no REST: loteMigracao/validadeMigracao ISO; campos fornecidos inválidos são recusados. Sem migração, hash anterior preservado; com valores novos, hash inclui a migração.

## 23. DT-070 — Consultas REST Bag e apoio de tipos

### 23.1 Autocomplete global de tipos

`consultarTiposApoio`: INPUT plAutorizado LOGICAL, pcFiltro CHARACTER, pcAposCodigo CHARACTER, plAtivo LOGICAL (YES/NO/? para ambos), piLimite INTEGER. OUTPUT TABLE ttEmbTipo, plTemMais, pcProximoCodigo, plSucesso, pcErro, pcMensagem. Nega autorização desconhecida/falsa antes de ler; filtro 2–100; cursor vazio ou código ASCII alfanumérico 2–3 normalizado; limite zero usa 20, teto 20, desconhecido inválido. Prefixo de código OR trecho de descrição; situação aplicada antes da paginação. Tipos globais em mgesp, NO-LOCK. Cursor final vazio. Erros SEM_PERMISSAO, FILTRO_CURTO, FILTRO_INVALIDO, LIMITE_INVALIDO, BANCO_MGESP_NAO_CONECTADO, FALHA_CONSULTA.

Handler `pi-apoios-tipos`, GET /apoios/tipos: filtro, aposCodigo, limite, ativo (true/false/todos; padrão true), usuario reconstruído pelo Dataset. Saída dados[{codigo,descricao,ativo,versao}], controles comuns e proximoCodigo. Permissão global e serviço autorizado permanecem dependência da cadeia Fluig atual; usuário declarado sozinho não homologa autorização. Endpoint tem as mesmas restrições de acesso do GET /tipos já existente.

### 23.2 Transporte dos recortes BAG-04/BAG-08

Handlers `pi-consultar-bags` e `pi-consultar-conteudo-bag`, delegam a helper `piConsultarBagRest` e às procedures do catálogo 22. GET /bags: codEstabel, idBag (zero opcional), filtroLacre, codTipo, situacao, inicio/fim ISO inclusivas em dt-inclusao, aposId, limite. GET /conteudo-bag: idBag positivo obrigatório, aposId, limite. Ambos recebem usuario e estabelecimentoPermitido repetido da cadeia confiável; usuário ausente recusa, permissões resolvidas no núcleo. Dados da ocorrência ou vínculos atuais, controles comuns, proximoId em texto. Conteúdo não calcula totais nem altera quantidade; projeção de etiqueta mantém campos já expostos no GET /etiquetas. Não confundir consulta com elegibilidade para ação.

Textos/query usados pelo recorte vêm de arrays com um elemento, salvo lista repetida de permissões. ID/cursor/limite aceitam somente texto decimal de inteiro não negativo, máximo INTEGER ABL; presente vazio/malformado/desconhecido recusa. Datas inválidas recusam. Erros de falha JSON/execução retornam FALHA_CONSULTA sanitizada, dados vazios e controles reiniciados. Módulos carregados são liberados em FINALLY.

### 23.3 Estado

Revisão compilada em TESTE; ET-01F integrado passou 32/0, ET-01I passou 30/0 e as consultas Bag/tipos com massa DT-074 passaram nos recortes documentados. Endpoints novos ainda não foram publicados/testados via REST. Próximo: publicar a mesma revisão ABL/REST, renovar somente PASOE TESTE e validar autorização/JSON/paginação. Sem alteração do modelo físico.


## 24. DT-072 — Apoio de famílias e dados para impressão

### 24.1 consultarFamilias

Núcleo existente contr-emb.p. INPUT TABLE ttEmbEstabelPermitido, pcFiltro CHAR, pcAposCodigo CHAR, piLimite INTEGER; OUTPUT TABLE ttEmbFamilia (codigo LIKE mgcad.familia.fm-codigo, descricao LIKE mgcad.familia.descricao), plTemMais, pcProximoCodigo, plSucesso, pcErro, pcMensagem. 10 parâmetros posicionais. Lista vazia/inválida nega antes de ler. Filtro 2–100, prefixo código OR descrição literal; limite 0/ausente=20, 1..20; cursor exclusivo por código textual, final vazio; NO-LOCK em mgcad. Catálogo global, não disponibilidade/eligibilidade. Erros SEM_PERMISSAO, FILTRO_CURTO, FILTRO_INVALIDO, LIMITE_INVALIDO, BANCO_MGCAD_NAO_CONECTADO e FALHA_CONSULTA. GET /apoios/familias: usuario/contexto reconstruídos pelo Dataset, filtro/aposCodigo/limite; resposta padrão total/temMais/proximoCodigo/dados.

### 24.2 obterDadosImpressao — GER-05, etiqueta individual

Rastreio existente contr-emb-rastreio.p. INPUT TABLE ttEmbEstabelPermitido, piIdEtiqueta INTEGER; OUTPUT TABLE ttEmbEtiqueta existente, plSucesso, pcErro, pcMensagem. 6 parâmetros. Sem permissão antes de consulta; ID positivo. Posição atual autorizada; inexistente e negada indistinguíveis ETIQUETA_NAO_DISPONIVEL. PRE_SALDO/controle diferente rejeitado ETIQUETA_NAO_IMPRIMIVEL; geração precisa de evento específico ligado por id-evento-geracao em CONCLUIDO, senão GERACAO_NAO_CONFIRMADA. Falha técnica FALHA_CONSULTA; banco ausente BANCO_MGESP_NAO_CONECTADO; ID inválido FILTRO_INVALIDO. Retorna uma identidade persistida, conserva código e campos congelados, sem cadastro/movimento/contador. Não bloqueia reimpressão pela quantidade zero/situação operacional; devolve situação atual para conferência, sem presumir validade de movimentação. GET /dados-impressao: idEtiqueta textual positivo, usuário/permissões do Dataset; resposta padrão sucesso/codigoErro/mensagem/total/dados com até uma linha. Lista de IDs/cópias/layout/serviço/impressão de Bag ainda não contratados.

### 24.3 Estado e dependências

Fonte compilado no lote SAVE 13/0. `consultarFamilias` foi comprovada no ET-01I 30/0, incluindo cursor; `obterDadosImpressao` foi comprovada no recorte ET-02A/DT-074 com massa. Serviço/Dataset/WKUser/grupos, publicação e prova REST permanecem pendentes. Contexto fornecido diretamente não homologa autorização produtiva. Nenhuma procedure do frontend nem alteração do modelo físico.

## 25. DT-077 — Adaptadores de fatos padrão e criação de saídas

O recebimento padrão não ganha uma procedure customizada de criação, atualização ou desatualização. O adaptador instalado deve ser fino: fotografar a ocorrência confirmada, classificar compra versus continuidade, montar identidade canônica e chamar o dispatcher do rastreio. Compra usa GER-02/GER-03; transferência/retorno usa uma capacidade comum de correlação com a saída e recupera as mesmas etiquetas. Ambas reutilizam `registrarEvento` e `aplicarMovimento`.

**ET-06/DT-090/091, candidato executável em TESTE:** `processarEntradaTransferencia` em `fontes/progress/contr-emb-transferencia-entrada.p` recebe ROWID de `docum-est`, HANDLE do núcleo ET-02 e devolve aplicabilidade, sucesso, repetição, evento, total de etiquetas, erro e mensagem. A UPC existente RE1005RP o chama somente para natureza `1557` e `ce-atual=YES`; a compra `1101IS` continua em GER-01. A rotina não cria entrada ou etiqueta. O recorte de uma linha e um `rat-lote` integral correlaciona saída 5557, WT, operação e seleção; lê série/número de origem em `item-doc-est` e lote/validade/depósito/localização em `rat-lote` antes de registrar `RECEBIMENTO_TRANSFERENCIA` e `ENTRADA_TRANSFERENCIA`. A revisão anterior compilou em TESTE com zero falhas; a correção DT-091 ainda exige novo SAVE e leitura do rateio antes de instalação. Contrato ANFE, parcialidade/múltiplos documentos e reversão da chegada seguem pendentes.

**Validação posterior em TESTE, 30/09:** SAVE `3/0`, entrada manual `10913/1/0019557` atualizada pelo RE1001, evento `193` concluído e dois movimentos de chegada; etiquetas 101/103 ativas em `10913/INS`. A cobertura é do recebimento integral manual, sem ANFE real e sem reversão dessa entrada. Evidência em `docs/entregas/evidencias/resultado-entrada-transferencia-e05-20260930-1101.txt`.

**DT-092, candidata ainda sem SAVE:** o mesmo serviço oferece `reverterEntradaTransferencia`, com ROWID do documento e HANDLE do núcleo ET-02, e os mesmos retornos de aplicabilidade/sucesso/repetição/evento/quantidade/erro. A UPC RE0402RP chama essa rotina somente para natureza `1557` em `Fim-Atualizacao`, após o padrão deixar `ce-atual=NO`; `1101IS` continua na reversão de compra. Ela localiza a chegada ativa sem efeitos posteriores, cria evento `DESATUALIZACAO_ENTRADA` ligado a essa chegada e um movimento compensatório por etiqueta para o `TRANSITO` de origem, preservando quantidade, situação e todos os fatos anteriores. Uma nova atualização confirmada no RE1001 permite novo ciclo de `RECEBIMENTO_TRANSFERENCIA` para as mesmas identidades. Primeiro ciclo mantém a chave anterior; novos ciclos recebem sufixo `|CICLO=n`. A consulta `testes/e05/consultar-vida-etiqueta-transferencia.p` lê uma identidade e todos os seus movimentos/eventos, sem escrita.

**Validação posterior DT-092 em TESTE:** o RE0402 desatualizou a entrada integral `10913/1/0019557`; evento 195/ciclo 2 e movimentos 125/127 concluídos, etiquetas 101/103 em `TRANSITO/10904` com 10 LT e situação ativa. O compilador corrigido inclui o núcleo ET-02 entre cinco fontes. A reatualização no RE1001 e a consulta de vida final seguem pendentes; a expressão “candidata ainda sem SAVE” acima descreve o estado anterior.

Na saída iniciada pelo Fluig, `contr-emb-operacao.p` concentra consulta, seleção, rateio, persistência da solicitação, controle da chamada padrão e correlação do documento único devolvido por cada execução. Na manutenção de etiquetas, a natureza selecionada define o ramo; devolução requer documento de origem, emitente e itens/quantidades elegíveis antes da chamada padrão. A família BODI317, seus caminhos de devolução/terceiros e BOIN404TE permanecem `STANDARD_BO_CALL` candidatas até conferência instalada. Atualização/desatualização de estoque e cancelamento não pertencem a esse módulo: são fatos padrão observados por hooks e refletidos pelo núcleo.

DT-085/086, **contrato corrigido, ainda sem implementação**: a seleção das etiquetas é enviada pela tela à PI de criação de documento. O backend valida a lista e a disponibilidade, chama BODI317 e somente após confirmação de `i-seq-wt-docto` persiste operação, linhas individuais `SOLICITACAO` e vínculo documental na mesma unidade transacional comprovada. Não há reserva persistida anterior ao documento nem movimento nessa etapa. A v1.8 candidata ainda precisa ser implantada e o tempo de 3.000 linhas medido em TESTE. O candidato anterior `registrarSelecaoTransferencia`, que gravava linhas antes da BO, foi retirado; não declarar seleção ou associação ao `wt-docto` implementadas. Timeout do Fluig exige consulta/reconciliação do resultado antes de repetir a criação.
DT-085/086, **contrato corrigido, ainda sem implementação completa**: a seleção das etiquetas é enviada pela tela à PI de criação de documento. O backend valida a lista e a disponibilidade, chama BODI317 e somente após confirmação de `i-seq-wt-docto` persiste operação, linhas individuais `SOLICITACAO` e vínculo documental na mesma unidade transacional comprovada. Não há reserva persistida anterior ao documento nem movimento nessa etapa. A v1.8 candidata ainda precisa ser implantada e o tempo de 3.000 linhas medido em TESTE. O candidato anterior `registrarSelecaoTransferencia`, que gravava linhas antes da BO, foi retirado. Timeout do Fluig exige consulta/reconciliação do resultado antes de repetir a criação. No mesmo módulo E04 foram preparados `vincularWtDoctoOperacao` (WT retornado pela BO), `vincularNotaPorWt` (encontra a operação pelo WT) e `gravarWtDoctoNaNota` (carimbo versionado em `nota-fiscal.char-2[1500..1519]`). `vincularNotaSaidaFluig` grava o carimbo e a origem documental na mesma transação; `processarNotaFt2100` exige concordância entre WT da nota e da operação. A persistência das linhas selecionadas, a chamada na efetivação FT4003, a migração v1.8 e a compilação/teste seguem pendentes.

28/09/2026: `registrarSelecaoAposWt` foi preparado no mesmo `contr-emb-operacao.p`, com entrada `ttEmbSelecaoSaida` (`id-etiqueta`, `quantidade`) em `contr-emb.i`. Recebe WT positivo já criado, origem/destino, emitente e usuário; registra operação `TRANSFERENCIA` e uma linha `SOLICITACAO` por embalagem inteira, sem evento/movimento, e devolve repetição idêntica. Fonte e teste de rollback **ainda não compilados/executados**; dependem da migração v1.8 em TESTE. Falta ligá-lo à PI real após BODI317 na mesma transação, confrontar os itens/quantidades do WT e medir volume/tempo. O roteiro isolado é `docs/entregas/E04_SELECAO_POS_WT_TESTE.md`.

28/09/2026: o executor integrado de TESTE `criar-wt-transferencia-com-etiquetas.p` parte dos IDs escolhidos, lê as dimensões das etiquetas, agrupa as compatíveis e confere a quantidade de cada grupo contra `saldo-estoq` antes de chamar a cadeia BODI317 observada no legado. Um grupo vira uma linha WT; cada etiqueta permanece uma linha `SOLICITACAO` no específico após WT positivo. Esse executor não substitui a PI definitiva, ainda não foi compilado/validado e não autoriza a UPC FT2100. O mesmo princípio de seleção primeiro vale para devolução e devolução de empréstimo, cujas BOs e regras de efetivação continuam próprias.

29/09/2026, DT-089: `processarNotaFt2100` comprovou no WT `492960` a saída da nota `0019557` e sua desatualização, com fatos e movimentos individuais persistidos. O WT não retornou ao FT4003 neste caso. Para a **mesma nota**, o serviço localiza a operação pelo carimbo WT persistido na nota e sua origem documental. Saída ainda ativa significa repetição; saída anterior compensada permite novo ciclo ímpar de `SAIDA_ESTOQUE`, com novos movimentos nas mesmas etiquetas. A desatualização compensa apenas a saída ativa no ciclo par seguinte. O primeiro par preserva as chaves existentes; ciclos posteriores acrescentam `|CICLO=n`. Histórico pendente/ambíguo é recusado. Essa revisão exige SAVE e teste integrado em TESTE; não autoriza reutilizar seleção em outro WT ou outra nota sem vínculo próprio.

Não criar `registrarEvento*` ou `aplicarMovimento*` por operação, UPC ou programa Datasul. Serviços específicos preparam/classificam o comando; o núcleo ET-02 persiste. Também não expor REST para uma extensão chamar serviço interno ou para substituir RE1001, RE0402, FT2100 e FT2200.

A matriz de processos, seis hooks lógicos, três famílias de BO e pontos ainda não comprovados está em `docs/entregas/MATRIZ_GATILHOS_DATASUL.md`. Nomes físicos de extensões, assinaturas, campos e relacionamento entrada↔saída permanecem `PONTO_DATASUL_A_CONFIRMAR`.


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

### 18.1 GET /operacoes/natureza — classificação da natureza escolhida, DT-094

Contrato somente leitura no adaptador existente. Query `natureza` e `codEstabel` obrigatórios; `usuario` e `estabelecimentoPermitido` repetido vêm do Dataset autorizado. Exige usuário não vazio e estabelecimento selecionado presente na lista permitida. Não é autocomplete nem enumera naturezas amigáveis: recebe um código exato já escolhido e devolve a classificação atual.

Retorno padrão `sucesso`, `codigoErro`, `mensagem`, `total`, `temMais=false`, `proximoCodigo=""`, `dados` com zero ou uma linha. Linha: `natureza`, `codEstabel`, `fluxo`, `ramoPadrao`, `exigeOrigem`, `editaQuantidade`, `editaPreco`. Sucesso significa classificação; não autoriza emissão nem afirma disponibilidade. Cadastro amigável, autorização do contexto confiável e validadores BO permanecem necessários no comando.

Chama `classificarNaturezaOperacao` do `contr-emb-operacao.r` publicado no caminho lógico `esp/api/v1/contr-emb-operacao.r`. Erros funcionais: USUARIO_NAO_INFORMADO, PARAMETRO_INVALIDO, SEM_PERMISSAO, NATUREZA_NAO_ENCONTRADA e NATUREZA_FORA_DOS_RAMOS_SUPORTADOS; falhas de carga/consulta retornam mensagem sanitizada. Sem escrita, movimentos, UPCs ou abertura de tela. Estado: contrato e fonte nesta entrega; compilação, PASOE e integração Dataset/Widget ainda pendentes.
### 18.2 GET /operacoes/embalagens-origem — origem de entrada escolhida e suas embalagens

Recorte inicial somente leitura para devolução de compra e retorno de empréstimo a partir de entrada recebida. Recebe natureza do novo documento, codEstabel, emitenteOrigem, serieOrigem, numeroOrigem, naturezaOrigem, aposIdEtiqueta (texto canônico inteiro, padrão 0) e limite (padrão 20, teto 100); usuário e estabelecimentos permitidos vêm do Dataset confiável. Identidade completa da entrada e natureza de saída são distintas. Não lista documentos por texto livre e não cria WT para consultar.

Backend reclassifica a natureza, exige ramo FT4011 ou retorno FT4012, verifica documento de entrada atualizado e último ciclo específico concluído, recupera movimentos daquele ciclo e etiquetas. Linha de origem vem de id-item-evento quando disponível; caso contrário, distribuição rat-lote OF item-doc-est ou campos da linha sem rateio permitem correlação somente se houver uma única sequência compatível. Ambiguidade aparece por embalagem e impede seleção; não fundir linhas por quantidade ou descrição.

Disponibilidade documental FT4011 vem de BOIN672.calculaSaldoDevolver (mesma assinatura chamada pela BODI317SD.m27); FT4012 vem de saldo-terc.quantidade menos dec-1 por chave completa/linha/estabelecimento, na mesma unidade. Não repetir quantidade documental por lote como se fossem limites independentes. Disponibilidade corrente também exige embalagem ativa, sem Bag, em ESTAB do solicitante, quantidade positiva não superior à participação na origem, ausência de reserva em operação pendente e saldo-estoq suficiente na posição atual. Cada embalagem retorna quantidade da origem, quantidade atual, limite documental compartilhado pela linha, podeSelecionar e motivo. Limites de cada linha e saldo devem ser reapurados sobre a soma da seleção no comando; o booleano de leitura não representa reserva nem valida a combinação inteira. Fracionamento não é liberado por esta consulta.

Paginação crescente por idEtiqueta, cursor exclusivo; dados inclui todas as embalagens vinculadas da página, inclusive incompatíveis. Estado corrente de etiqueta fora do estabelecimento não é exposto, somente motivo de indisponibilidade e participação histórica na origem autorizada. Não altera estoque, eventos ou projeções. Origem sem rastreio/entrada atualizada é recusada. Consulta de remessa de saída para outros tipos FT4012, faturamento de consignação e reajuste ficam fora deste recorte. Múltiplos ciclos não multiplicam embalagens; vínculos ambíguos são recusados. Estado: contrato nesta entrega; SAVE, ensaio e REST pendentes.
### 18.3 criarWtDevolucao — DT-095 / E09, preparação ABL

**04/10, 19:37 — FT4012 aprovado no cenário:** SAVE 2/0, WT 493002/operação 27, origem entrada 11301/9321/1/0019559/1949OE, etiquetas 151/161. Duas linhas de 10 LT/INS com lotes/validades preservados; repetição, conflito e persistência FALHAS=0. Correção TABLE-HANDLE ultrapassou o erro 5363 no ensaio nativo. Criação não comprova atualização/reversão da nota nem chegada no credor. Evidências em docs/entregas/evidencias/e12-retorno-falha-20261004/resultado-retorno-20261004-193753.txt e compilacao-retorno-20261004-193737.txt. Nenhum fonte alterado após esse SAVE.

DT-101 / 04/10 19:09: ABL 5363 confirmou incompatibilidade do parâmetro nativo FT4012. contr-emb-devolucao.p recebe tt-it-terc-nf da BO instalada por OUTPUT TABLE-HANDLE inicialmente ?, valida sequencia/rw-saldo-terc/selecionado/qt-disponivel/qt-disponivel-inf escalares (tipos esperados) e devolve por INPUT TABLE-HANDLE, preservando campos e índices restantes. Só edita seleção e quantidade das linhas cuja chave completa de saldo-terc corresponde à origem. Objetos temporários liberados no FINALLY. FT4011 inalterado; código preparado, novo SAVE 2/0 e criação positiva ainda pendentes. Escopo 5.2, DT-101 e roteiro E12_DIAGNOSTICO_RETORNO_FT4012.md prevalecem sobre dependência histórica do include para FT4012.

04/10 — diagnóstico do retorno FT4012 preparado após CONSULTAR_TERCEIROS_BO_FALHOU: captura ABL/RETURN-VALUE e RowErrors antes do UNDO, sem substituir validações/origem padrão; executor observa novos WT presentes após falha dentro do recorte estabelecimento/natureza/usuário, sem atribuir causalidade sob concorrência. Sem alteração de contrato ou hook. Novo SAVE dirigido 2/0 necessário; causa e retorno ainda sem aceite. Roteiro docs/entregas/E12_DIAGNOSTICO_RETORNO_FT4012.md.

Módulo fontes/progress/contr-emb-devolucao.p. Entrada: HANDLE do módulo de operações, TABLE ttEmbEstabelPermitido, codEstabel, natureza de saída, série de saída, emitenteOrigem, série/número/natureza de entrada, usuário confiável, chaveIdempotencia e TABLE ttEmbDevolucaoSelecao (id-etiqueta, versao, quantidade). Saída: TABLE ttEmbDevolucaoLinha, WT, operação, sucesso, repetição, erro e mensagem. Sem endpoint mutante nesta revisão; adaptador REST após prova ABL do contrato BO.

Seleciona somente embalagens inteiras disponíveis da entrada; quantidade deve coincidir com projeção corrente e versão. Chave 1..64 ASCII alfanumérico/hífen/underscore; contexto mínimo versionado em observacao/justificativa. A chave idempotente é escopada pela entrada completa e usuário autorizado. Repete WT/operação pelo hash de chave/conteúdo antes de revalidar posição alterada, sob coordenação pelo documento de origem; projeção de linhas é devolvida somente na primeira criação. Mesma chave com outro conteúdo conflita; WT abandonado não é recriado por repetição. Lista não vazia, no máximo 100 embalagens neste recorte, sem IDs repetidos; origem e seleção são rechecadas no comando. Fonte não usa códigos fixos de naturezas.

BODI317IN inicializa SD/PR/IM/VA; SD.criaWtDocto sugere a espécie conforme natureza. Compra usa geraItensDevolucaoTtItensDevol e geraWtItDoctoPartindoDoTtItensDevol. Terceiros usa geraItensTerceirosTtItTercNf e geraWtItDoctoPartindoDoTtItTercNf com BOIN404TE, como FT4012. Desmarca todas as linhas nativas e seleciona somente as sequências validadas, com soma das embalagens. Preço fica com o padrão. Origem e quantidade do WT gerado são conferidas; lotes/deposito/localização gerados precisam coincidir com seleção. Multilote incompatível com rateio sugerido é recusado, sem apagar ou trocar lotes padrão. Validade preenchida por criaAlteraWtFatSerLote quando desconhecida; discrepância conhecida recusa. Item validado pela VA depois do rateio.

WT e SOLICITACAO por etiqueta são atômicos; nenhum evento físico, nota ou BAIXA é gerado aqui. Tipos internos DEVOLUCAO_COMPRA ou RETORNO_TERCEIROS. Último evento da origem e linha/movimento selecionados são conservados em contexto mínimo; efeito posterior não pode depender apenas de observacao textual. Hook FT2100 atual ainda recusa esses tipos até a implementação do seu efeito. Retorno de empréstimo precisa de entrada rastreada própria; compra nova não substitui essa entrada. Estado: preparação em desenvolvimento; compilação e ensaios positivos pendentes.

### 18.4 E10 — efeito da devolução de compra (DT-096)

Criação de compra/devolução foi aprovada em E09, WT 492998/operação 23. Revisão E10 de vincularNotaSaidaFluig/processarNotaFt2100 admite apenas DEVOLUCAO_COMPRA adicionalmente à transferência já validada. Natureza NFD e contraparte são revalidadas na nota; evento documental conserva natureza. EndEffectiveNote reutiliza WT/seleção, end-ft2100 atualiza embalagens inteiras na mesma transação do ERP: SAIDA_ESTOQUE/SAIDA_DEVOLUCAO_COMPRA, quantidade/situação conservadas, ESTAB→TRANSITO, fornecedor identificado. Inverso DESATUALIZACAO_SAIDA restaura snapshot e aponta ao movimento compensado; novo ciclo por reatualização. Dependência posterior impede reversão. Sem alteração de assinatura, REST ou schema. Logs persistentes e consulta readonly incluem saldo-terc/saldo-estoq, sem escrita consolidada. Preparado; SAVE E10 7/0 e ensaio único do ciclo pendentes. Roteiro E10_CICLO_DEVOLUCAO_COMPRA.md; efeitos de remessa/retorno de empréstimo permanecem recusados.

### 18.5 E11 — remessa de terceiros tipo 3 (DT-097)

E10 aprovado no recorte manual, eventos 203/205/207/209. E11 amplia os mesmos vínculos/ciclos apenas para REMESSA_TERCEIROS de NFS/NFT, terceiros=YES/tp-oper-terc=3. registrarSelecaoRemessaAposWt revalida emitente do estabelecimento destino e reserva somente seleção preparatória. FT2100 cria SAIDA_REMESSA_TERCEIROS, TERCEIRO com contraparte, conteúdo/situação mantidos; operação EXECUTADA após saída, SOLICITADA após reversão, dentro da transação do ERP. Guarda de fato posterior e ciclos/idempotência existentes conservados; transferência/NFD preservadas. Sem mudança de assinatura/schema/REST, sem escrever saldo-terc/estoque padrão. Consulta E11 registra snapshots por documento/linha. Preparado; SAVE E11 8/0 e ensaio remessa pendentes. Entrada 1949OE e retorno FT4012 não são liberados por este lote.
### 18.6 E12 — chegada e retorno do empréstimo (DT-098)

**DT-102/E13, 05/10 — recebimento do retorno preparado, sem SAVE/aceite nativo:** processarEntradaEmprestimo/reverterEntradaEmprestimo agora classificam NFE/terceiros tipo 3 ou 5, com assinaturas existentes ROWID/HANDLE e outputs preservados. Tipo 5 exige RETORNO_TERCEIROS com id-oper-origem REMESSA_TERCEIROS; conferir credor/devolvedor, notas/WT, selecao e id-item-origem de cada etiqueta. Cabecalho/chave/persistencia identificam a nota de retorno; serie-comp/nro-comp completos sao validados contra remessa original ou essa saida, sem usa-los para escolher retorno por saldo/quantidade. Helper validarDocumentoRetorno no include contr-emb-retorno-origem.i. Chegada RECEBIMENTO_RETORNO_EMPRESTIMO/ENTRADA_RETORNO_EMPRESTIMO aponta saida ativa/movimento, recebe TRANSITO -> ESTAB/credor e conserva identidade/conteudo. Reversao DESATUALIZACAO_ENTRADA usa snapshot e novos ciclos. Guardas comuns contemplam chegada de retorno e continuidade compensada. Sem novo schema, BO, endpoint ou escrita em estoque padrao. Roteiro E13_RECEBIMENTO_RETORNO_CREDOR.md: SAVE cinco fontes, leitura previa somente leitura, depois ensaio nativo dirigido. Hooks atuais continuam chamando as mesmas assinaturas e nao precisam ser substituidos neste lote.

**04/10, 20:12 — aceite E12 da saida do retorno:** WT 493002/op.27/nota 0004116/1 comprovou eventos 227/229/231 e movimentos 245/247 -> 249/251 -> 253/255, com quantidade/situacao/identidade preservadas, compensacao por snapshot e novo ciclo. Estoque e terceiros recebidos 11301 acompanharam saida/reversao/nova saida; saldo de terceiros do credor 10904 permanece pendente ate recebimento. Criacao FT4012/DT-101 ja passou SAVE 2/0 e executor sem falhas. Recebimento do retorno no credor, ANFe real e REST mutante continuam pendentes; nao ampliar o aceite alem desse recorte. Evidencia docs/entregas/evidencias/e12-retorno-falha-20261004/aceite-ciclo-completo-retorno-20261004-201200.md. Historicos de preparacao abaixo podem estar desatualizados.


**04/10, 17:51 — chegada corrente comprovada:** entrada 11301/9321/1/0019559/1949OE, vínculo 221 -> documental 211, chegada 223 -> saída ativa 217, movimentos 241/243 -> 233/235. Etiquetas 151/161 ATIVA, 10 LT cada, ESTAB/11301/INS, mesmas identidades/lotes/validades/posse. Repetição conservou evento e dois movimentos. Estoque padrão e saldo-terc iguais à leitura anterior à conciliação; 20 LT da remessa continuam pendentes no 10904. Evidência `docs/entregas/evidencias/e12-dt100-preparacao-20261004/resultado-ciclo-emprestimo-e12-20261004-175139.txt`. Próximo: criar WT de retorno pelo FT4012 usando a entrada rastreada; criação/efeito/reversão do retorno ainda não comprovados. Entrada substituta, recusas, concorrência e ANFe real permanecem pendentes. Registros anteriores abaixo podem estar desatualizados.

**DT-100, 04/10 — revisão ABL implementada, SAVE/aceite pendentes:** os dois serviços de entrada incluem `fontes/progress/includes/contr-emb-recebimento-origem.i`. O resolvedor usa vínculo persistido/histórico, referência completa dos itens, chave da mesma NF-e e identidade exata do cabeçalho; confere remetente/destinatário, nota/WT/operação e unicidade. Referência parcial, contraditória ou ambígua recusa; composição e saída ativa são conferidas pelo serviço antes da chegada. Existindo remessa rastreada entre as partes mas faltando identidade suficiente, retorna pendência de correlação; não escolhe por quantidade/data nem gera etiquetas. Naturezas e abrangência dos serviços existentes permanecem as do recorte E05/E12.

`VINCULO_ENTRADA_SAIDA` usa a chave completa da entrada e aponta ao evento documental de saída. Chegada aponta ao ciclo físico ativo e seu movimento aponta à saída individual; predecessor permanece o cursor real. Vínculo e efeito específico são atômicos/idempotentes, com releitura sob bloqueio da operação e versão/predecessor no núcleo. Guarda global recusa chegada ativa da mesma origem em outra entrada. Continuidade aceita somente a própria saída ou a compensação concluída de uma chegada dessa origem, restaurando o snapshot; não atravessa fatos posteriores incompatíveis. A reversão usa o mesmo bloqueio e mantém histórico/vínculo.

`conciliarEntradaComOrigem` está exposta em ambos os módulos para chamada interna confiável: entrada ROWID, ID do evento documental de saída, HANDLE do núcleo; outputs aplicável/sucesso/repetição/evento/quantidade/erro/mensagem. Associa e chama o mesmo processamento integral numa transação; qualquer recusa desfaz também o vínculo. Permite numeração diferente quando a origem foi identificada, sem alterar campos padrão. Não é rota REST nem descoberta automática do ANFe. Cancelamento/anulação e contratos adicionais BO/ANFe permanecem pendentes. Compilador dirigido E12 agora 6 fontes; completo 14. Roteiro corrente: `docs/entregas/E12_VINCULO_RECEBIMENTOS_DT100.md`. Textos históricos abaixo podem estar desatualizados.

A consulta de origem de devolução em `contr-emb-operacao.p` exclui o evento VINCULO_ENTRADA_SAIDA ao escolher o ciclo físico da entrada; associação documental não substitui recebimento/compensação. Correção incluída no mesmo SAVE dirigido, agora 6 fontes. Contrato REST existente preservado.

Novo módulo contr-emb-emprestimo-entrada.p expõe processarEntradaEmprestimo/reverterEntradaEmprestimo com a mesma assinatura de ROWID/HANDLE e outputs aplicável/sucesso/repetição/evento/quantidade/erro/mensagem dos serviços E05. Serviço separado preserva o recorte já aprovado. Chegada classifica NFE/terceiros tipo 3, exige remessa rastreada única e reconcilia todas as linhas/rateios com as etiquetas selecionadas; grupo físico repetido em linhas/rateios distintos é recusado. Sem remessa específica, retorna não aplicável e não interfere no recebimento padrão. Recebimento/compensação geram fatos novos, conservam identidade/conteúdo e guardam último movimento. Retorno preparado por criarWtDevolucao mantém FT4012/origem/quantidades; vincularNotaSaidaFluig e processarNotaFt2100 revalidam NFS/NFT de terceiros tipo 2/5 e registram SAIDA_RETORNO_TERCEIROS/compensação/ciclos. Nenhum saldo padrão escrito. Consulta E12 inclui estoque/terceiros nos dois lados. Preparado, sem SAVE ou execução desta revisão; chegada do retorno no credor e ANFe end-to-end pendentes.


04/10 — DT-099 preparado: SAVE E12 anterior 12/0 confirmado pelo TXT. Entrada 11301/9321/1/0019559/1949OE atualizada em 02/10 14:29 com 10 LT por lote e duas linhas de terceiros; nenhum evento especifico de chegada. Consulta nativa OF docum-est confirmou serie-comp/nro-comp vazios em ambas as linhas (10/20). Corrigida correlacao por cabecalho com emissor/destinatario/WT/operacao/ciclo/grupos unicos; campos parciais/divergentes bloqueiam. Executor dirigido concilia apenas embalagens, sem novo movimento padrao. Sem SAVE/execucao da correcao; compilador de revisao 2 fontes, compilador completo futuro 13 fontes. Proximo: SAVE 2/0, conciliar entrada existente e consulta E12 operacao 25; retorno FT4012 somente apos chegada comprovada. Evidencias preservadas: docs/entregas/evidencias/e12-correlacao-cabecalho-20261004.


## DT-103/E14 — retorno de armazenagem preparado (05/10/2026)
Reutiliza as assinaturas processarEntradaEmprestimo/reverterEntradaEmprestimo e hooks instalados. NFE/terceiros tipo5 sem retorno interno rastreado resolve RETORNO_ARMAZENAGEM -> REMESSA_TERCEIROS da propria fazenda para o emitente da entrada, por referencia completa de todos os itens. VINCULO_ENTRADA_SAIDA aponta remessa, RECEBIMENTO_RETORNO_TERCEIROS aponta saida ativa, ENTRADA_RETORNO_TERCEIROS aponta movimentos; TERCEIRO -> ESTAB e inverso por snapshot. Guardas comuns incorporam esse tipo de chegada. registrarSelecaoRemessaAposWt aceita destino vazio para emitente externo cadastrado; FT2100 permite esse caso somente no ramo REMESSA_TERCEIROS. Transferencia continua exigindo destino; demais fluxos preservados. Sem tabelas/campos/REST novos. Preparado sem SAVE/ensaio; compiladorE14 sete fontes, roteiro docs/entregas/E14_ARMAZENAGEM_TERCEIRO.md. Cenários: sucesso integral/repeticao/compensacao previstos; sem origem/ambiguo/quantidade ou estado divergente bloqueados. Integracao real/parcelas ainda pendentes.

## E15/DT-106 — encerramento automatico preparado, 05/10/2026
Implementado fontes/progress/contr-emb-cancelamento.p, procedure concluirCancelamentoNota(ROWID nota, usuario; aplicavel, sucesso, repeticao, id-operacao, erro, mensagem). Confere identidade/documento/carimbo CEWT1, cancelamento nativo, estoque desconfirmado e compensacao unica de cada saida. Sob lock da operacao, encerra CANCELADA apenas quando todas as notas associadas estiverem canceladas e reconciliadas. Primeira conclusao atualiza autor/data/versao; repeticao nao altera versao. Nota sem vinculo especifico devolve nao aplicavel/sucesso. Nenhuma escrita em estoque, etiquetas, eventos ou movimentos; preserva historico. Divergencia, lock ou efeito ativo impedem conclusao.
UPC-BODI135CANCEL-DIAGNOSTICO-TESTE agora tambem e funcional: AFTERINVOICECANCELLATION exige transacao e chama o servico; FIM_CANCELANOTAFISCAL permanece observacao. Erro funcional propagado, nunca suprimido pelo log. Nome instalado mantido para evitar mudar cadastro. Nao e pos-commit. Sem nova API/schema. Compensacao continua exclusivamente no FT2100.
Executor parametrizado testes/e15/concluir-operacao-cancelada.p realiza fechamento, repeticao, estabilidade de versao/quantidade de movimentos e rollback quando PERSISTIR=no. Uso excepcional para op23 ja cancelada; fluxo futuro pelo hook. SAVE/rollback/propagacao de erro e aceite nativo ainda pendentes. Cenários sem baixa, varias notas, dependencias posteriores e anulacao continuam sem homologacao; nao afirmar garantia geral.

## 05/10 — DT107: adaptador de vinculo incorporado em ebodi317ef
Removida chamada externa UPC-BODI317EF-VINCULO-TESTE.r; mesma logica em piVincularEmbalagensPorWt, mesma transacao/validacoes e rotinas existentes. WT sem operacao especifica retorna OK antes de carregar nucleos. Rastreio/operacao continuam necessarios para embalagens. Arquivo legado preservado byte a byte fora do bloco alterado e qualificadas referencias a mgcad.item; r-code anterior preservado, exige novo SAVE e instalacao de ebodi317ef.r. Fonte sincronizado por hash no pacote. Sem compilador local; teste SOAP/ressuprimento e vinculo de embalagens pendentes. E15 fechamento continua preparado e ainda depende de SAVE7/0, sem nova validacao nesta interrupcao. Nao repetir cancelamento0019558.

## 05/10 — DT108: SOAP por caminho logico, adaptador separado restaurado
DT107 superada por solicitacao do responsavel. ebodi317ef chama _bp/EMS2/Upc/UPC-BODI317EF-VINCULO-TESTE.r; adaptador carrega _bp/api/ET-01_TESTE/fontes/progress/contr-emb-rastreio.r e contr-emb-operacao.r pelo PROPATH. Log deriva do nucleo encontrado por SEARCH. Exemplo real PROGRAM=_bp/api/cd-ressuprimento.p fornecido pelo responsavel fundamenta raiz logica. Fonte/pacote sincronizados; .r preservados. Exigir SAVE dos dois fontes e instalacao em EMS2/Upc, depois teste SOAP/ressuprimento e vinculo especifico. Sem SAVE/aceite nativo local. Outros hooks nao alterados; E15 continua pendente da compilacao/ensaio registrados.

## 05/10 — DT109/E16 preparado: caminhos compartilhados e sonda local
SOAP/ressuprimento aprovado pelo responsavel apos DT108/FT2100; evidência na conversa, sem TXT nativo novo. Include contr-emb-caminhos.i em seis hooks e dois servicos de entrada; resolve raiz ERP (_bp/api/ET-01_TESTE/...) ou raiz pacote no PROPATH. Nao muda PROPATH runtime, nao usa drive fixo; logs derivam do include localizado. APIs publicadas ja resolvem modulos por SEARCH/esp/api/v1; contratos REST inalterados. Ferramentas administrativas dirigidas ao TESTE conservam caminhos fisicos de compilacao/instalacao.
E16/compilar-caminhos-save.p cobre14 fontes com SAVE e restaura PROPATH anterior. Sonda conferir-caminhos-local.p carga sete modulos, seis adaptadores com evento sem efeito e tt-epc vazia, vazio/arquivo ausente e PROPATH preservado; sem chamada de negocio/mutacao. Prepara compatibilidade local sem telas Fluig; nao homologa efeitos/rollback funcional. Pacote sincronizado por SHA256;95 .r recebidos preservados. Proximo copiar pacote, SAVE14/0, executar sonda na sessao local; apos FALHAS0 instalar seis adaptadores nos destinos atuais e retomar E15 ensaio com rollback de op23. Nenhuma nova execucao nativa feita localmente; aceite E16/DT106 pendentes.
