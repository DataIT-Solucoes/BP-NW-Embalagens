# Registro de decisões técnicas

## DT-102 — chegada do retorno do emprestimo ao credor — 05/10/2026

Continuidade autorizada da E12 apos ciclo 227/229/231 aprovado e entrada manual 10904/112267/1/0004116/1949DO criada. Implementar dentro do modulo contr-emb-emprestimo-entrada.p, preservando assinaturas dos hooks e ramo tipo 3. Tipo 5 e definido pelo cadastro NFE/terceiros, sem naturezas chumbadas. Identificar DOCUMENTO_SAIDA_FLUIG do RETORNO_TERCEIROS por associacao persistida/historico, chave da NF-e recebida ou identidade exata do cabecalho. Confirmar nota/WT, ambas as contrapartes, REMESSA_TERCEIROS antecedente e vinculos das linhas/etiquetas. Referencia completa dos itens e validada contra a remessa original ou a propria saida do retorno, sem escolher por quantidade ou ultimo ID. A referencia do RE1001J a 0019559 nao transforma essa remessa na saida de retorno 0004116.

VINCULO_ENTRADA_SAIDA aponta ao documental do retorno; RECEBIMENTO_RETORNO_EMPRESTIMO aponta ao ciclo SAIDA_ESTOQUE ativo; ENTRADA_RETORNO_EMPRESTIMO aponta ao movimento de saida de cada etiqueta. Projecao TRANSITO/devolvedor para ESTAB/credor com rateio de entrada e posse cadastral do credor, mantendo ATIVA/quantidade/identidade. Reversao restaura snapshot, exige ausência de fatos posteriores e admite novo ciclo, sob bloqueio da operacao. Chegada ativa em outra entrada e origem incompleta/ambigua recusadas. Usar validacoes comuns sem mudar o ramo 5557/1557 ou lancar saldo padrao.

Preparacao nao e aceite nativo. Entregar leitura previa da entrada/origem/refs e SAVE com todas as dependencias .r necessarias. Depois uma atualizacao e consultas de estoque/terceiros/eventos; reversao/reatualizacao dirigidas apos primeiro aceite. ANFe real, campo Natureza Complementar (detalhe relatado, sem causa comprovada), cancelamento/anulacao, entradas substitutas/parcialidade/concorrencia continuam pendentes. Sem novo schema ou endpoint.

Este arquivo é append-only. Não apagar decisões antigas; quando uma decisão mudar, registrar uma nova entrada que substitua explicitamente a anterior.

## DT-001 — Controle por lote, sem referência

- **Data:** 24/08/2026
- **Status:** vigente
- **Decisão:** o novo controle usa item, estabelecimento, lote e validade. `cod-refer`, `ref-item`, `referencia` e `tipo-con-est = 4` são exclusivos do legado.
- **Motivo:** retirar a dependência do modelo antigo de referência e alinhar a rastreabilidade ao lote real do Datasul.

## DT-002 — Estrutura individual fora da saldo-estoq

- **Data:** 30/07/2026
- **Status:** vigente
- **Decisão:** `saldo-estoq` permanece responsável pelo saldo consolidado. Etiquetas individuais, situação, localização e histórico ficam em estrutura específica.
- **Motivo:** preservar o ERP padrão e eliminar movimentos auxiliares usados somente para individualização.

## DT-003 — Gatilho na atualização do RE1001

- **Data:** 30/07/2026
- **Status:** vigente
- **Decisão:** a atualização do documento no RE1001 substitui a criação pelo Fluig como evento oficial de geração das etiquetas.
- **Motivo:** o ANFE passou a centralizar a criação/importação do documento fiscal.

## DT-004 — Embalagens completas

- **Data:** 24/08/2026
- **Status:** vigente
- **Decisão:** a geração cria etiquetas somente para quantidades completas conforme a capacidade parametrizada; não haverá etiqueta parcial.

## DT-005 — Parametrização própria do projeto

- **Data:** 24/08/2026
- **Status:** vigente
- **Decisão:** item controlado é definido exclusivamente por parametrização específica por estabelecimento e item.

## DT-006 — Baseline REST Fluig-Datasul v1.0

- **Data:** 03/09/2026
- **Status:** vigente
- **Decisão:** novas integrações usam Widget -> Dataset -> Serviço autorizado -> ut-api -> ABL/PASOE.
- **Detalhes:** Dataset search utiliza `filterFields`; query parameters chegam como `JsonArray`; não registrar `oInput` completo; não manter filtros chumbados.

## DT-007 — Consistência dos agentes PASOE

- **Data:** 03/09/2026
- **Status:** vigente
- **Decisão:** toda publicação de API deve validar `.r`, PROPATH e atualizar os agentes da aplicação correta antes da homologação.
- **Motivo:** agentes com r-codes diferentes produziram respostas alternadas durante os testes.

## DT-008 — Nomenclatura das tabelas específicas

- **Data:** 03/09/2026
- **Status:** vigente
- **Decisão:** adotar o prefixo `contr_emb_` para as novas tabelas específicas e o nome `contr_emb_param` para a tabela de parametrização dos itens controlados.
- **Motivo:** diferenciar das tabelas padrão com prefixo `emb` informadas pelo responsável técnico e manter o nome conciso, pois não está prevista outra tabela de parametrização.
- **Substitui:** as propostas anteriores com prefixo `emb_` e o nome sugerido `contr_emb_param_item`.
- **Limite:** nomes das demais tabelas, campos, formatos, índices e relacionamentos continuam pendentes de definição.

## DT-009 — Tipos de embalagem e controle das Bags por lacre

- **Data:** 03/09/2026
- **Status:** vigente
- **Decisão:** utilizar o cadastro existente `bag_embalagens` como origem dos tipos de embalagem. Cada Bag está vinculada a um tipo e somente aceita embalagens desse mesmo tipo. O controle operacional das Bags é realizado por lacre.
- **Novo modelo:** relacionar e validar os tipos explicitamente pelo código de embalagem, sem depender de `cod-refer`, `ref-item` ou da tabela `referencia`, conforme DT-001.
- **Evidência:** confirmação do responsável técnico e consulta ao legado `pi-analisa-tipo-embalagem` em `referencias/fontes-legado/etiquetas_v2.p`; o legado extrai o tipo de `cod-refer`, comportamento que deverá ser substituído.
- **Limite:** esta definição não aprova os demais campos propostos para `contr_emb_param`, nem formato, unicidade, troca ou reutilização do lacre.

## DT-010 — Cadastro de tipos no padrão contr_emb_bag

- **Data:** 03/09/2026
- **Status:** vigente
- **Decisão:** adotar `contr_emb_bag` como nome do cadastro de tipos de embalagem no novo modelo, sucedendo o legado `bag_embalagens` e preservando os códigos e as informações existentes na migração.
- **Substitui parcialmente:** DT-009 quanto à utilização de `bag_embalagens` como cadastro de destino. Essa tabela permanece como origem legada; a parametrização e os vínculos do novo modelo deverão utilizar `contr_emb_bag`.
- **Mantém:** as regras de Bag vinculada a um único tipo, compatibilidade das embalagens pelo tipo, controle operacional por lacre e ausência de controle por referência.
- **Limite:** `contr_emb_bag` é o cadastro de tipos; não é a definição de destino da entidade operacional legada `bag`. Campos físicos, formatos, índices, dependências e procedimento de migração ainda precisam ser detalhados. Nenhuma migração foi executada nesta etapa.

## DT-011 — Modelo específico orientado às necessidades do projeto

- **Data:** 03/09/2026
- **Status:** vigente
- **Decisão:** redesenhar as tabelas específicas no padrão `contr_emb_` conforme as necessidades e regras aprovadas do projeto. O legado é fonte de levantamento dos processos e de eventual aproveitamento de dados; não determina a estrutura de destino.
- **Substitui parcialmente:** DT-010 quanto à obrigatoriedade de preservar códigos e informações do cadastro antigo e qualquer interpretação das DT-009/DT-010 que condicione o novo dicionário à reprodução das tabelas legadas. O aproveitamento de dados será avaliado e mapeado separadamente.
- **Mantém:** os nomes aprovados `contr_emb_param` e `contr_emb_bag`, a parametrização por estabelecimento e item, o vínculo explícito por tipo, a compatibilidade das Bags por tipo, o controle operacional por lacre e a ausência de controle por referência.
- **Integração:** preservar o estoque consolidado padrão do Datasul e conferir os campos e contratos externos efetivamente utilizados pela nova solução.
- **Limite:** esta orientação não aprova automaticamente os campos e índices ainda propostos e não autoriza exclusão de dados legados ou execução de migração. A implementação e a transição serão validadas por etapas.

## DT-012 — Separação entre produção, teste e novo modelo

- **Data:** 03/09/2026
- **Status:** vigente
- **Contexto informado:** somente uma pequena parte do projeto está em produção; o responsável técnico relata uma diferença significativa em relação a teste e enviará os fontes `.p` correspondentes à versão produtiva. A entrada do ANFE motivou a reformulação ampla do projeto.
- **Decisão:** identificar a origem e o ambiente de cada conjunto de fontes e comparar produção, teste e necessidades do novo modelo antes de decidir o reaproveitamento ou a substituição das funcionalidades em uso.
- **Limite:** os fontes já disponíveis não comprovam o conteúdo publicado em produção. O tamanho e os detalhes da diferença entre ambientes ainda não foram verificados. A origem em 2023 é aproximada e não confirmada. Esta definição não autoriza alterações ou desativação em produção.

## DT-013 — Finalidade contextual dos conjuntos legados recebidos

- **Data:** 03/09/2026
- **Status:** vigente
- **Contexto confirmado:** `referencias/fontes-prod-legado` contém os fontes fornecidos como versão de produção, com uso de `pre-faturamento_v2.p` não confirmado. `referencias/fontes-legado` corresponde à evolução que estava prestes a ser publicada; a implantação não ocorreu devido à centralização pelo ANFE.
- **Orientação:** utilizar esses conjuntos para compreender a trajetória do projeto e consultar comportamentos conforme a necessidade da nova modelagem. O envio não solicita auditoria exaustiva, correção ou publicação do legado.
- **Atualiza:** DT-012 quanto ao recebimento dos fontes e à finalidade imediata de sua comparação. Mantém a distinção entre versões e o foco na nova estrutura, sem vincular seu desenho às tabelas legadas.

## DT-014 — Modelo de dados inicial v1.0

- **Data:** 03/09/2026
- **Status:** vigente como definição inicial de arquitetura; não implantada
- **Solicitação:** o responsável técnico delegou a definição das tabelas específicas necessárias ao projeto completo, com prefixo `contr_emb_`, nomenclatura de campos próxima ao Datasul e evolução posterior controlada.
- **Definição:** modelo com 17 tabelas documentado integralmente em `docs/05_MODELO_DADOS.md`, com dicionário estruturado em `docs/modelo-dados/contr_emb_v1.json`. Campos, chaves, índices e relacionamentos específicos passam a ter uma definição inicial própria.
- **Núcleo:** tipos em `contr_emb_bag`; parametrização única por estabelecimento/item em `contr_emb_param`; documentos e identidades externas; cálculos de geração preservados; etiquetas e movimentos; vínculos mãe/filhas; ocorrências de Bags e conteúdo; operações e baixas; auditoria; eventos idempotentes e fila de saída.
- **Integridade:** etiquetas agrupadoras não possuem saldo próprio; capacidades e quantidades de geração são preservadas; exclusão de parametrização não apaga a história; baixas físicas e fiscais são distintas; numeração usa sequência autoritativa e unicidade; movimentos confirmados são imutáveis; projeções e efeitos locais são gravados atomicamente.
- **Atualiza:** DT-008, DT-010 e DT-011 quanto aos nomes e à definição inicial dos campos/índices das novas tabelas, mantendo a independência do legado e a ausência de referência.
- **Primeira entrega:** cadastro de tipos, parametrização e auditoria. O modelo completo não antecipa a implantação de todos os fluxos.
- **Limites:** compatibilidade OpenEdge e dicionário real dos campos padrão, identidades externas, confirmação transacional do evento ERP, contratos de integração, regras fiscais/operacionais e política de lacres continuam sujeitos às conferências registradas. Não foram criados `.df`, tabelas em banco ou migrações nesta etapa.

## DT-015 — Simplificação do modelo para 10 tabelas

- **Data:** 03/09/2026
- **Status:** vigente como modelo corrente; não implantado
- **Diretriz do gestor:** privilegiar uma solução simples e funcional, evitando complexidade com pontas ainda não fechadas e utilizando as tabelas padrão do Datasul onde elas já são autoridade.
- **Decisão:** substituir o modelo v1.0 de 17 tabelas pelo modelo v1.1 de 10 tabelas descrito em `docs/05_MODELO_DADOS.md` e `docs/modelo-dados/contr_emb_v1.json`. O dicionário anterior permanece em `contr_emb_v1_0.json` somente para histórico.
- **Concentrações:** documentos e itens fiscais permanecem nas estruturas padrão e têm fotografia mínima em evento/item; cálculo de geração fica no item do evento; agrupamentos e conteúdo de Bags são projeções da etiqueta com fatos no movimento; baixas ficam nas linhas da operação; fila externa só será criada diante de contrato assíncrono concreto.
- **Estoque específico:** `contr_emb_etiqueta` é a tabela específica do estoque individual das embalagens, reunindo identidade e estado/saldo atual. `saldo-estoq` conserva somente o saldo consolidado padrão por item/lote/validade/estabelecimento. `contr_emb_movto` permanece obrigatório como histórico imutável que explica cada alteração do estado atual.
- **Integridade:** movimento e atualização da etiqueta ocorrem na mesma transação; `id-movto-ult` e `id-movto-ant` encadeiam a projeção e o fato. Agrupadoras não possuem saldo e vínculos logísticos não duplicam quantidade.
- **Motivo:** separar etiqueta e saldo em tabelas 1:1 criaria sincronização e consultas adicionais sem ganho funcional comprovado. Manter o movimento separado é necessário para estorno, rastreabilidade, concorrência e reconstrução/auditoria do estado.
- **Limites:** as 10 tabelas ainda serão analisadas em conjunto antes da materialização. Campos podem ser simplificados ou acrescentados de modo coerente. Alterações de identidade, significado do saldo ou vínculo exigem análise de impacto.

## DT-016 — Saldo individual explícito e rastreio documental dos movimentos

- **Data:** 03/09/2026
- **Status:** vigente como modelo corrente; não implantado
- **Decisão:** evoluir o modelo corrente para a v1.2 com 11 tabelas, acrescentando `contr_emb_saldo` entre a identidade da embalagem e seu histórico. `contr_emb_etiqueta` guarda identidade, classe e origem permanentes; `contr_emb_saldo` guarda quantidade, situação, localização, vínculo de agrupamento e Bag atuais; `contr_emb_movto` registra os fatos imutáveis que explicam cada mudança.
- **Estoque:** `contr_emb_saldo` é a estrutura específica do estoque individual por etiqueta, item, lote, validade e estabelecimento. A tabela padrão `saldo-estoq` permanece como autoridade exclusiva do saldo consolidado do item/lote/validade/estabelecimento.
- **Documento e evento:** cada movimento confirmado referencia obrigatoriamente `contr_emb_evento` e, quando aplicável, `contr_emb_evento_item` e `contr_emb_oper_item`. Documento, série, tipo documental, espécie e natureza do evento ficam centralizados em `contr_emb_evento`; `contr_emb_movto` conserva apenas o tipo e o efeito físico da movimentação, evitando cópia e divergência dos dados documentais.
- **Motivo:** um evento pode originar vários movimentos, não originar movimento por erro ou repetição, ou ser reprocessado de forma idempotente. Separar o evento do movimento preserva esse processamento e mantém o histórico de estoque objetivo. A relação 1:1 entre etiqueta e saldo foi aceita deliberadamente para aproximar o desenho do padrão saldo/movimento utilizado no Datasul e tornar explícita a responsabilidade de cada estrutura.
- **Integridade:** etiquetas individuais e agrupadoras devem possuir exatamente um saldo correspondente; agrupadoras mantêm quantidade própria igual a zero. A gravação do movimento e a atualização de `contr_emb_saldo` ocorrem na mesma transação, sob validação do estado anterior. `id-movto-ant` e `id-movto-ult` formam a cadeia entre fato e projeção atual.
- **Substitui parcialmente:** DT-015 quanto à quantidade de tabelas e à concentração do estado atual em `contr_emb_etiqueta`. Mantém as demais concentrações e a diretriz de simplicidade.
- **Limite:** o modelo continua sujeito à revisão conjunta antes da criação do `.df` e das tabelas físicas. Nenhuma alteração foi executada no banco.

## DT-017 — Evento como raiz do agrupamento gerado e da consulta documental

- **Data:** 03/09/2026
- **Status:** vigente no modelo corrente; não implantado
- **Decisão:** tratar `contr_emb_evento` como raiz lógica das etiquetas originadas pelo documento. A relação física é `contr_emb_etiqueta.id-evento-geracao`; as etiquetas dessa origem com `classe-etiqueta = AGRUPADORA` são as etiquetas-mãe geradas pelo evento.
- **Cardinalidade:** um evento pode gerar zero, uma ou várias mães. Não adicionar um único `id-etiqueta-mae` ao cabeçalho nem repetir a lista em campo textual, pois isso limitaria a cardinalidade e duplicaria uma relação já íntegra.
- **Consulta:** os efeitos diretos do documento são obtidos por evento → movimentos → etiquetas → saldos. O ciclo completo das embalagens nascidas naquele documento é obtido por evento → etiquetas de geração → todos os movimentos dessas etiquetas → saldos atuais. As filhas atuais de uma mãe são obtidas por `contr_emb_saldo.id-etiqueta-mae`; vínculos anteriores permanecem nos movimentos.
- **API REST:** a API poderá expor uma projeção composta de rastreabilidade por documento/evento, reunindo evento, itens, mães, embalagens, movimentos e saldos atuais sem materializar cópias nas tabelas.
- **Atualiza:** DT-016 ao explicitar o agrupamento e os caminhos de consulta. Não acrescenta tabela nem campo ao modelo v1.2.

## DT-018 — Consolidação fiscal no item do evento e rateio individual

- **Data:** 03/09/2026
- **Status:** vigente no modelo corrente v1.3; não implantado
- **Regra esclarecida:** o documento fiscal movimenta uma quantidade consolidada por item, lote e validade. Uma única linha pode representar, por exemplo, 2.000 embalagens. Depois, essa quantidade é rateada nos saldos individuais na saída do estabelecimento emissor e novamente na entrada confirmada pelo estabelecimento recebedor.
- **Decisão:** usar `contr_emb_evento_item` como agrupamento lógico da linha/lote fiscal. Cada parcela do rateio é um `contr_emb_movto` ligado ao mesmo `id-item-evento` e à etiqueta afetada; o estado resultante fica em `contr_emb_saldo`.
- **Sem etiqueta-mãe:** retirar do modelo corrente a classe `AGRUPADORA`, `contr_emb_saldo.id-etiqueta-mae` e `contr_emb_movto.id-etiqueta-relac`. Uma etiqueta-mãe repetiria a função do item do evento e exigiria sincronização sem benefício operacional confirmado. Bags e lacres continuam com seus próprios vínculos.
- **Rastreabilidade:** documento → evento → item consolidado → movimentos rateados → etiquetas → saldos atuais. Para o ciclo completo de uma embalagem, consultar todos os movimentos pelo `id-etiqueta`.
- **Conciliação:** cada evento físico concluído deve reconciliar a soma do rateio aplicável com a quantidade normalizada do item do evento, considerando unidade, resíduos e a regra do tipo de evento. Saída e entrada são ocorrências distintas e não devem ser somadas como um único efeito.
- **Substitui:** DT-017 e as partes das DT-014, DT-015 e DT-016 que previam etiqueta-mãe, classe agrupadora ou vínculo mãe/filha. Mantém as 11 tabelas, a separação etiqueta/saldo/movimento e o estoque consolidado padrão em `saldo-estoq`.
- **Pendente:** definir o momento exato da mudança de responsabilidade durante o trânsito, critérios de seleção/rateio das embalagens e tratamento de recebimento parcial, divergente ou recusado antes da implementação física.

## DT-019 — Fronteira do controle por estabelecimento, item, lote e validade

- **Data:** 03/09/2026
- **Status:** vigente no modelo corrente v1.3; não implantado
- **Decisão:** toda consolidação, seleção de saldo, rateio, movimento e conciliação respeita a combinação `cod-estabel` + `it-codigo` + `lote` + `dt-vali-lote`.
- **Mesmo item em lotes distintos:** cada lote/validade forma outra ocorrência em `contr_emb_evento_item`, ainda que o código do item e o documento sejam os mesmos. Os movimentos de cada ocorrência usam seu próprio `id-item-evento`; uma etiqueta de outro lote ou validade não pode completar o rateio.
- **Estabelecimento:** o estabelecimento do evento identifica o contexto da saída ou da entrada. `contr_emb_saldo` possui índice por estabelecimento/item/lote/validade para localizar as etiquetas elegíveis. No item do evento, o índice iniciado por `id-evento` atende a navegação pelo cabeçalho sem duplicar `cod-estabel`.
- **Estrutura:** a v1.3 já possui os campos, vínculos e índices necessários; esta decisão acrescenta uma regra de integridade, sem criar tabela ou campo.

## DT-020 — Procedures novas sem dependência operacional das tabelas específicas legadas

- **Data:** 03/09/2026
- **Status:** vigente para o catálogo e para as futuras implementações
- **Decisão:** construir cada etapa diretamente sobre as tabelas `contr_emb_*` do modelo corrente e sobre as tabelas padrão autoritativas do Datasul. O desenvolvimento será incremental por domínio, sem criar procedures novas sobre as estruturas específicas legadas para substituí-las depois.
- **Mapeamento principal:** `etiquetas-CD` é sucedida funcionalmente por `contr_emb_etiqueta` e `contr_emb_saldo`; `bag_embalagens` por `contr_emb_bag`; `bag` por `contr_emb_bag_lacre`; `bag_etiquetas` pela projeção `contr_emb_saldo.id-bag` e pelos fatos de `contr_emb_movto`; `bag_log` por evento, movimento e auditoria.
- **Limite:** referências a essas tabelas na seção de inventário legado de `06_CATALOGO_PROCEDURES.md` servem somente para explicar o comportamento encontrado. Eventual migração poderá lê-las em rotina isolada e aprovada, sem torná-las dependência do fluxo REST novo.
- **Mantém:** `saldo-estoq` como tabela padrão do Datasul e autoridade do saldo consolidado; ela não se confunde com as tabelas específicas legadas.

## DT-021 — Tipo, sigla, capacidade e compatibilidade das Bags de descarte

- **Data:** 03/09/2026
- **Status:** vigente no modelo corrente v1.4; não implantado
- **Tipo:** `contr_emb_bag` classifica a natureza/material da embalagem. O exemplo definido é código `PLASTICO`, descrição `Plástico` e sigla `PL`.
- **Sigla:** obrigatória, única, normalizada em maiúsculas e com 2 a 10 caracteres. Representa somente o tipo e serve para apresentação; não participa de chave estrangeira nem é usada para inferir compatibilidade. Não incorporar capacidade na sigla: usar `PL`, não `PL20`.
- **Capacidade:** pertence a `contr_emb_param` por estabelecimento/item e é congelada em `contr_emb_saldo` na criação da etiqueta. Não pertence ao tipo da Bag.
- **Conteúdo da Bag:** toda etiqueta deve possuir o mesmo `cod-embalagem` de `contr_emb_bag_lacre`. Podem coexistir na mesma Bag itens, lotes, validades e capacidades diferentes, inclusive embalagens plásticas de 10 L e 20 L.
- **Descarte:** não restringir o conteúdo da Bag ao mesmo item. Se uma necessidade futura exigir segregação adicional, ela deverá ser tratada como nova regra com análise de impacto, sem ser presumida agora.
- **Estrutura:** a v1.4 mantém 11 tabelas e acrescenta obrigatoriedade e índice único para `contr_emb_bag.sigla`; a v1.3 permanece arquivada.

## DT-022 — Preenchimento e limite da sigla do tipo de embalagem

- **Data:** 03/09/2026
- **Status:** vigente no modelo corrente v1.5; não implantado
- **Decisão:** a sigla será informada manualmente no cadastro e validada pela API. Não será gerada automaticamente a partir da descrição, evitando mudanças inesperadas e colisões.
- **Formato:** depois de remover espaços externos e converter para maiúsculas, deve corresponder a `^[A-Z][A-Z0-9]{1,2}$`: mínimo de 2 e máximo de 3 caracteres, começando por letra e continuando com letras ou números, sem espaços, acentos ou sinais. `PL`, `PL1` e `PL2` são válidas; `1PL`, `P` e `PL20` são inválidas.
- **Unicidade:** a sigla normalizada é única. O Widget limita a entrada e orienta o usuário; a validação definitiva e a verificação de unicidade são executadas no servidor.
- **Capacidade separada:** números na sigla podem diferenciar variantes do tipo, mas não substituem `capacidade-emb`, que continua em `contr_emb_param` e `contr_emb_saldo`.
- **Estrutura:** reduzir `contr_emb_bag.sigla` de `CHARACTER(10)` para `CHARACTER(3)`, mantendo obrigatoriedade e índice único. A v1.4 permanece arquivada.
- **Substitui parcialmente:** DT-021 somente quanto ao limite anterior de 2 a 10 caracteres.

## DT-023 — Código único do tipo sem campo de sigla

- **Data:** 03/09/2026
- **Status:** vigente no modelo corrente v1.6; não implantado
- **Decisão:** eliminar a duplicidade entre `cod-embalagem` e `sigla`. `contr_emb_bag.cod-tipo` passa a ser a única chave curta do cadastro do tipo, usada também nos vínculos de parametrização, evento/item, saldo, ocorrência da Bag e operação/item.
- **Preenchimento:** manual, obrigatório, único e imutável. Depois de remover espaços externos e converter letras para maiúsculas, aceita `^[A-Z0-9]{2,3}$`: 2 ou 3 letras e/ou números. Exemplos válidos: `PL`, `PL1`, `PL2`, `001` e `002`.
- **Capacidade:** o código pode identificar a variante escolhida pelo cliente, mas não substitui `capacidade-emb`. A capacidade permanece na parametrização por estabelecimento/item e no saldo congelado da etiqueta.
- **Estrutura:** remover `contr_emb_bag.sigla`; renomear `cod-embalagem` para `cod-tipo` em `contr_emb_bag`, `contr_emb_param`, `contr_emb_evento_item`, `contr_emb_saldo`, `contr_emb_bag_lacre` e `contr_emb_oper_item`; usar `CHARACTER(3)` e atualizar chaves, relações e índices. O modelo mantém 11 tabelas.
- **Substitui:** DT-022 e as partes das DT-009, DT-010 e DT-021 que mantinham `cod-embalagem` e uma sigla separada. As referências aos nomes antigos continuam válidas somente ao descrever o legado e a futura migração.

## DT-024 — Início do detalhamento da geração de etiquetas

- **Data:** 03/09/2026
- **Status:** proposta de fluxo para revisão; não implementada
- **Etapa:** detalhar nascimento da embalagem, cálculo por item/lote/validade, saldo inicial, primeiro movimento, repetição e impressão, conforme seção 7 de `07_CICLO_VIDA_EMBALAGEM.md`.
- **Base preservada:** atualização confirmada do recebimento, parametrização por estabelecimento/item, embalagens completas, saldo específico e movimentos rastreáveis. Recebimento de transferência utiliza as identidades da origem; não é nova geração.
- **Proposta:** começar pela entrada de embalagens novas de fornecedor externo e classificar as demais entradas antes de aplicar o cálculo. Nenhuma natureza fiscal foi presumida.
- **Limites:** primeiro movimento sem estado anterior exige ajuste pontual de obrigatoriedade no dicionário antes da implementação; política de cancelamento, classificação das entradas e confirmação transacional permanecem pendentes. Não foram criadas tabelas, rotas ou procedures executáveis.

## DT-025 — Entrada do material como início do controle

- **Data:** 03/09/2026
- **Status:** regra de negócio confirmada; não implementada
- **Confirmação:** o responsável técnico esclareceu que o início do controle das embalagens ocorre no momento da entrada do material. Não indicou outro gatilho de início.
- **Decisão:** adotar a entrada inicial do material como nascimento do controle individual, com identidade, saldo e primeiro movimento. Permanece o gatilho técnico já definido na atualização confirmada do recebimento no RE1001.
- **Continuidade:** transferências de embalagens já controladas preservam as etiquetas da origem, conforme definição anterior; a entrada no destino não reinicia seu ciclo.
- **Atualiza:** DT-024 quanto ao marco funcional de início. A expressão proposta “fornecedor externo” não substitui a regra confirmada de entrada do material nem constitui classificação fiscal aprovada.
- **Limite:** não define códigos de natureza, espécies fiscais, tratamento de retornos, cancelamento, ponto pós-commit ou carga inicial da implantação. Nenhuma estrutura de tabela foi alterada.

## DT-026 — Início restrito à compra de fornecedores com natureza específica

- **Data:** 03/09/2026
- **Status:** regra funcional confirmada; código da natureza a confirmar; não implementada
- **Correção do responsável técnico:** “entrada” significa entrada de compra de fornecedores, com uma natureza específica. A geração não se aplica a toda entrada de material.
- **Decisão:** gerar identidades, saldos e primeiros movimentos na atualização confirmada desse recebimento de compra, para os itens ativos na parametrização. Transferências preservam as etiquetas da origem.
- **Evidência:** `referencias/fontes-legado/epc-re1005rp.p`, linha 118, contém `docum-est.nat-operacao <> '1101IS'` junto de um filtro de estabelecimentos, no bloco de realocação. Isso comprova a exclusão de `1101IS` desse bloco, mas não uma geração condicionada à igualdade com essa natureza. O trecho de pedido/ordem de compra adiante chama `pi-atualiza-follow-up`.
- **Substitui parcialmente:** DT-025 e a interpretação ampla da entrada inicial no detalhamento da DT-024. Mantém atualização confirmada, parametrização, embalagens completas e continuidade das identidades.
- **Pendente:** confirmar `1101IS` como código da natureza geradora e definir sua configuração no novo fluxo. Não copiar filtros fixos de estabelecimento ou controle por referência do legado. Nenhuma tabela ou procedure executável foi alterada.

## DT-027 — Natureza de compra 1101IS e contexto da exclusão na EPC

- **Data:** 03/09/2026
- **Status:** regra confirmada; não implementada
- **Confirmação do responsável técnico:** `1101IS` é a natureza de compra. Ela não participa do bloco de movimentações entre estabelecimentos e terceiros na EPC porque o fluxo de compra era realizado no Fluig.
- **Novo fluxo:** a atualização confirmada do recebimento de compra com natureza `1101IS`, para itens ativos na parametrização por estabelecimento/item, origina etiquetas, saldos individuais e primeiros movimentos. ANFE/Datasul assumem o recebimento fiscal conforme arquitetura já definida; a geração não depende da antiga criação da nota pelo Fluig.
- **Distinção:** transferências/realocações dão continuidade às identidades existentes. A condição legada `nat-operacao <> '1101IS'` não será interpretada como autorização para gerar etiquetas em todas as demais naturezas.
- **Atualiza:** DT-026 quanto à confirmação do código e ao motivo da separação no legado. A evidência do fonte permanece corretamente descrita como exclusão; sua finalidade funcional foi confirmada pelo responsável técnico.
- **Limites:** a forma de configurar a natureza e o ponto de confirmação/entrega do evento ainda serão definidos na implementação. Não altera tabelas nem implementa procedures nesta etapa.

## DT-028 — Abrangência do ciclo além das transferências legadas

- **Data:** 03/09/2026
- **Status:** abrangência funcional confirmada; regras por operação em detalhamento
- **Orientação:** usar os tipos de transferência encontrados no recebimento fiscal para entender os caminhos existentes, sem restringir o projeto a eles. Devoluções, empréstimos, cancelamento de notas e renovação de empréstimos também fazem parte do ciclo.
- **Evidência de produção:** `recebimento_fiscal.p`, procedure `pi-recebimento-fiscal` (linha 285), prepara o documento e seus itens. Na linha 415, espécie 23 ou indicador de terceiros encaminha a `pi-executa-reapi316a`; o outro ramo chama `rep/reapi190.p`. A classificação utiliza dados de `natur-oper`. A procedure consulta o documento criado e devolve mensagens; não chama diretamente uma rotina de geração das etiquetas específicas.
- **Evolução não implantada:** `recebimento_fiscal_v2.p`, linhas 574–602, distingue espécie 23, terceiros sem estabelecimento correspondente ao emitente e emitente vinculado a estabelecimento, chamando respectivamente `pi-executa-reapi316a`, `pi-recebe-terceiros` e `pi-recebe-empresas-diferentes`; o ramo restante usa `rep/reapi190.p`. Esses critérios descrevem o fonte, não um contrato novo aprovado.
- **Diretriz:** classificar cada evento pelo caso de negócio e vincular documento, operação, movimentos e saldos. Baixa física, efeito fiscal, cancelamento e renovação não são intercambiáveis. Definir seus efeitos por etapa preservando a rastreabilidade.
- **Mantém:** DT-027 para o nascimento na compra `1101IS`; não estende essa regra automaticamente às demais operações. Novos empréstimos e renovações terão regras próprias, ainda pendentes.

## DT-029 — Biblioteca ampla de contratos padrão e matriz de transações

- **Data:** 03/09/2026
- **Status:** organização do levantamento definida; coleta integral e análise de contratos pendentes
- **Solicitação:** ter acesso às APIs e BOs de Recebimento e Faturamento para planejar todas as transações, além dos caminhos já existentes no legado. O responsável técnico forneceu também referências de NF-e, Reforma Tributária e monitores.
- **Entrega de organização:** biblioteca em `referencias/padrao-datasul/`, com 124 links distintos: 26 BOs/11 APIs MRE, 62 BOs/9 APIs MFT e 16 referências complementares. A matriz relaciona operações e candidatos a leitura, sem seleção antecipada por nome.
- **Evidência de acesso:** índice de APIs MRE recuperado com 11 páginas; consultas posteriores automatizadas bloqueadas pelo TDN. Tentativas de abrir páginas individuais retornaram 403 ou falha de abertura. Conteúdos integrais ainda não obtidos.
- **Critério:** registrar origem, versão e situação de cada referência; conferir assinaturas, efeitos físicos/fiscais e transação antes da seleção. Toda documentação recebida será preservada, mesmo sem aplicação imediata no projeto.
- **Limite:** 124 links não significam 124 contratos analisados nem cobertura de todas as rotinas do produto. Fontes/includes da versão instalada, páginas filhas e anexos ainda precisam ser obtidos. Nenhuma nova tabela, API ou BO foi implementada nesta etapa.

## DT-030 — Mapeamento preliminar baseado na leitura individual do TDN

- **Data:** 04/09/2026
- **Status:** análise documental concluída para o recorte prioritário; seleção definitiva e homologação pendentes
- **Evidência:** 28 páginas abertas pelo navegador, sendo 26 documentações de API/BO, uma do monitor NF-e e REAPI436 em construção. As fichas preservadas em `referencias/padrao-datasul/MAPEAMENTO_APIS_BOS.md` são sínteses, não exportações integrais. Acesso regular funciona, atualizando o limite de acesso da DT-029.
- **Candidatos:** conjunto BODI317IN/SD/PR/IM1BR/VA e EF para saídas; métodos SD de devolução/terceiros; BODI135/135NA para consulta; BODI135CANCEL para cancelamento sujeito à conferência do programa físico e efeitos. EF2 é dependência interna. BOIN404TE foi identificada como dependência adicional de terceiros.
- **Delimitações documentadas:** REAPI190 exclui transferências/terceiros; RESTs doctoEntrada/doctoFisico tratam integração WMS; BOIN847 mantém o conversor; BOIN372 consulta recebimentos de pedidos; FTAPI402 parte de fatura do Contas a Receber; REAPI005 descreve RGA internacional. Esses nomes não serão usados para deduzir cobertura fiscal mais ampla.
- **Continuidade:** confirmar versão, includes, lotes resultantes do cálculo, ponto de atualização de estoque e tratamento de emissão com resultado incerto. A documentação de BODI317IN alerta sobre XML já enviado mesmo após rollback local. REAPI316A, BOIN090 e BOIN404RE seguem com evidência legada, sem contrato padrão obtido.
- **Mantém:** arquitetura REST da DT-006, ANFE e nascimento da compra conforme DT-027, modelo corrente e regras de saldo/movimento. Nenhuma nova regra fiscal, API executável ou estrutura física foi aprovada ou implantada por essa leitura.

## DT-031 — Saídas pelo Fluig e cobertura dos processos no Datasul

- **Data:** 04/09/2026
- **Status:** participação funcional confirmada; desenho técnico proposto, contratos e implementação pendentes
- **Confirmação do responsável técnico:** entre os processos fiscais do ciclo, somente a nota de saída será iniciada fora do Datasul, na manutenção de etiquetas do Fluig. Preservar ao máximo essa tela; seus fontes e os das demais telas envolvidas serão fornecidos para análise das diferenças entre produção e homologação.
- **Abrangência:** saídas feitas diretamente no padrão Datasul também precisam manter o controle individual, incluindo devoluções, empréstimos, renovações e os tratamentos de cancelamento/anulação aplicáveis. O vínculo entre etiquetas e documentos deve sobreviver a toda a cadeia. Recebimento permanece no Datasul/ANFE; o levantamento MRE não propõe recriar entrada no Fluig.
- **Correção de escopo:** a frase anterior “O Fluig deixa de criar o documento fiscal” referia-se à entrada centralizada no ANFE. Não elimina a solicitação da NF de saída pela manutenção de etiquetas. Cadastros e consultas operacionais Fluig permanecem previstos.
- **Entrega:** `referencias/padrao-datasul/MATRIZ_EVENTOS_EXECUCAO.md` cruza 14 operações com 14 marcos técnicos, locais de execução, APIs/BOs candidatas, extensões e lacunas. Os identificadores da matriz são de levantamento, não códigos de eventos aprovados para banco.
- **Evidência nova:** TDN FT2100 documenta atualização e desatualização de estoque; CD0606 documenta estoque automático durante o cálculo; FT2200 e RE0402 distinguem cancelamento e desatualização. A documentação da integração SIGAGFE localiza candidatos em BODI317EF, BODI135CANCEL, RE1005RP e RE0402RP, sem comprovar seus contratos para o projeto.
- **Proposta técnica:** processamento ABL compartilhado pelas extensões padrão e pela fronteira REST, seleção durável anterior à emissão, correlação com todas as notas geradas e idempotência comum entre observações da API e da EPC. Separar efeito fiscal, confirmação de estoque e compensação; não criar nova identidade em renovação ou transferência.
- **Pendências:** seleção/alocação de etiquetas no padrão, política de bloqueio versus pendência, concorrência, persistência da solicitação, identidade do ciclo ERP, entrega durável, pontos exatos de extensão, anulação por cenário e compensações com efeitos posteriores. Contratos, nomes físicos e release instalada ainda precisam ser conferidos.
- **Limites:** não aprova novo layout, naturezas, regras fiscais, tabela, payload ou procedure. Nenhuma alteração ABL, banco ou parametrização padrão foi executada. Modelo v1.6 preservado.

## DT-032 — Fontes Fluig recebidos e consolidação das interfaces

- **Data:** 04/09/2026
- **Status:** fontes recebidos e destinos funcionais registrados; integração e retirada operacional ainda não executadas
- **Recebimento:** clonados Monitor-Xml, Controle-Bags, manutencao-etiquetas-v2 e form-receb-material dos links fornecidos pelo responsável. Cópias preservadas em `referencias/fontes-fluig-github/2026-09-04/`, com branch, commit e hashes no manifesto. São 60 arquivos versionados; histórico raso da branch padrão, não cópia de todo o histórico remoto.
- **Classificação:** Monitor-Xml é esboço do novo monitor; Bags e manutenção v2 são homologação legada; formulário de recebimento é legado a substituir. Commit baixado não comprova versão publicada em produção/homologação.
- **ANFE:** o responsável esclareceu que o novo monitor se integra a uma situação adicional no fluxo de conferência usado pela usina para reconhecimento da nota e conferência de pedido, valores, quantidades e descontos. Substitui as telas legadas de recebimento fiscal; não duplica a criação de entrada. Situação, transições e contrato não definidos pelo mock.
- **Interfaces:** Item por Etiqueta será substituído pela parametrização aprovada. Consolidar consulta/impressão da tela Etiquetas Item — Centro de Distribuição na manutenção, conforme encaminhamento do responsável e recomendação técnica. Fontes da manutenção já demonstram consulta, filtros e impressão individual/em lote; conferir as funções necessárias antes da retirada operacional. Preservar ao máximo sua interface.
- **Evidência/limite:** inspeção inicial, não revisão integral nem teste operacional. Datasets, serviço de impressão, utilitários externos e correspondência com ABL publicado ainda exigem levantamento. Não houve build, deploy, alteração dos fontes recebidos, desativação de tela ou alteração do modelo de dados.

## DT-033 — Devolução por documento de origem e cobertura das reversões

- **Data:** 04/09/2026
- **Status:** seleção de origem e parcialidade confirmadas; detalhamento técnico proposto e contratos pendentes
- **Confirmação do responsável:** no fluxo utilizado, a natureza de devolução no FT4003 leva à seleção do documento original do empréstimo, itens e quantidades; a devolução pode ser integral ou parcial. A rastreabilidade deve abranger todos os eventos que movimentam ou revertem o controle individual, sem repetir levantamentos já feitos.
- **Evidência padrão:** FT4003 documenta FT4011 para devolução e FT4012 para terceiros. O suporte TOTVS confirma abertura automática do FT4012 na natureza de retorno de beneficiamento, com remessa de origem, itens e disponibilidade/alocação. O enquadramento exato de cada empréstimo do cliente continua sujeito à natureza instalada; não foi deduzido CFOP ou tipo de terceiros.
- **Detalhamento:** criado `referencias/padrao-datasul/DEVOLUCOES_E_REVERSOES.md`, complementando a matriz. Relaciona seleção de origem, rateio por etiqueta, saldo disponível, concorrência, documentos definitivos e reversão da baixa específica. Usa os vínculos e compensações já previstos em `contr_emb_oper_item` e os movimentos por etiqueta, sem nova tabela.
- **Cobertura:** classificados também posição/depósito, requisição/devolução, ajuste quantitativo, inventário, recebimento físico/fiscal, Bag/descarte, documentos simbólicos e fatos sem efeito físico. Os caminhos MCE/recebimento físico são condicionais ao uso real no cliente; não autorizam novo escopo de implantação ou correção de saldo legado.
- **Reversão:** cancelar/desatualizar uma devolução parcial não desfaz as outras devoluções da origem. Compensar apenas a dimensão e a parcela efetivamente revertidas, com dependências posteriores avaliadas. Renovação, impressão, conferência ou ajuste apenas de valor não movimentam conteúdo por si sós.
- **Limites:** pesquisa/documentação concluída para os grupos identificados; cobertura exaustiva da instalação exige inventário dos produtores reais, contratos, versão e homologação. Nenhum hook foi presumido pelo nome da tela; nenhuma regra fiscal, código executável ou estrutura física foi implantada.

## DT-034 — Renovação e transações fiscais acompanham o estoque padrão

- **Data:** 04/09/2026
- **Status:** regra confirmada pelo responsável técnico; não implementada
- **Correção:** não tratar renovação de empréstimo como operação isenta de movimentos individuais por ser fiscal/simbólica ou não envolver deslocamento material. O responsável esclareceu que a renovação praticada pelo fiscal da BP deve permanecer visível no controle, conforme as transações realizadas pelo padrão.
- **Regra:** se a transação fiscal movimentar o saldo consolidado do item em `saldo-estoq` e houver etiquetas/embalagens vinculadas, registrar e refletir os movimentos correspondentes no controle específico dessas identidades. O efeito real no ERP governa a aplicação; o nome da operação não determina ausência de movimento.
- **Etapas:** entrada e saída distintas devem continuar rastreáveis, mesmo quando o resultado líquido é zero. Não suprimir etapas nem confundir compensação/renovação com repetição técnica. Idempotência impede reaplicar a mesma ocorrência, sem eliminar ocorrências diferentes.
- **Identidade:** utilizar as mesmas etiquetas vinculadas e conservar a cadeia documental. Renovação não gera identidades novas. A conciliação relaciona cada etapa padrão com o rateio específico, sem produzir lançamento adicional no ERP.
- **Ausência de efeito:** somente quando o padrão não movimentar estoque não haverá reflexo quantitativo por esse motivo. Mesmo nesse caso, manter documentos, vínculos e efeitos da operação que existirem. Ausência de movimento material não equivale a ausência de movimento de estoque.
- **Atualiza:** as formulações das DT-031/DT-033 e das matrizes que poderiam excluir renovação do controle quantitativo apenas por qualificá-la como fiscal. Decisões anteriores permanecem como histórico; esta regra prevalece.
- **Limites:** contratos, naturezas, sequência documental e representação de cada efeito ainda exigem detalhamento na versão instalada. Nenhuma tabela, campo, código ou parametrização foi alterado nesta etapa.

## DT-035 — Contexto geral curto e leitura por assunto

- **Data:** 04/09/2026
- **Status:** organização documental autorizada pelo responsável técnico
- **Motivo:** evitar o crescimento da leitura obrigatória de cada sessão sem dificultar a localização das regras e das dependências.
- **Organização:** `docs/contextos/GERAL.md` orienta a retomada; seis guias apontam para as seções existentes de parametrização/dados, Bags, recebimento, saídas, estoque e integrações. São mapas de leitura, não cópias das definições.
- **Fontes:** escopo, modelo, catálogo, ciclo, matrizes e pendências continuam nos arquivos atuais. Decisões anteriores e fontes legados permanecem preservados. Não criar resumos por sessão nem reproduzir o histórico nos guias.
- **Leitura:** `AGENTS.md` exige o geral e os guias pertinentes, as seções completas aplicáveis, decisões relevantes e dependências. Mudanças estruturais exigem o modelo integral e seu JSON; revisões gerais exigem ampliar a leitura. Regras de segurança, evidência, atualização documental e validação permanecem.
- **Comando:** o mesmo `.bat` gera um contexto inicial curto e um inventário separado. A consolidação não interpreta conversas nem atualiza semanticamente os documentos.
- **Manutenção:** atualizar a definição em sua fonte; revisar o geral se mudar uma regra transversal ou a etapa atual; revisar guias se mudarem localização ou dependências. A organização não muda o escopo funcional nem o modelo v1.6.

## DT-036 — Acompanhamento de evolução e prontidão por etapa

- **Data:** 04/09/2026
- **Status:** acompanhamento solicitado pelo responsável; critérios operacionais documentados para uso na evolução
- **Solicitação:** conhecer a situação real, as definições ainda abertas e a consistência de cada etapa, iniciando seu desenvolvimento após concretizar as definições correspondentes.
- **Organização:** `docs/08_ACOMPANHAMENTO_ETAPAS.md` reúne status, evidências, dependências, impedimentos e próximo passo por entrega `ET-xx`. Não substitui as fontes técnicas nem cria novos códigos de eventos.
- **Critério:** distinguir levantamento, definição parcial, definição fechada/pronta para desenvolver, desenvolvimento, homologação e implantação. Conferir regra, dados, contrato, dependências, cenários e coerência antes de liberar o recorte; não exigir o fechamento de áreas sem dependência efetiva.
- **Correção de sequência:** a seção 2 do catálogo era uma proposta centrada em Bags. Cadastros podem iniciar antes; operações com conteúdo e transições que alteram etiquetas exigem o mecanismo comum de evento/saldo/movimento. Essa dependência já aparece no próprio catálogo e no modelo. A ordem geral de implantação segue as dependências do modelo, e não a ordem de listagem das procedures.
- **Diagnóstico inicial:** baseline de consulta validado em teste, documentação e levantamento existentes; cadastros próximos do fechamento, geração e núcleo com pendências impeditivas, contratos fiscais/ANFE/GATEC ainda não fechados. Nenhuma nova etapa funcional é declarada pronta apenas por esta revisão.
- **Manutenção:** atualizar a linha da etapa com evidência e data quando o estado mudar; manter questões em aberto no documento `03` e decisões/histórico nos documentos `02`/`04`. Reavaliar etapas afetadas por mudança de contrato ou regra.
- **Limites:** não aprova contratos propostos, não cria tabelas, não executa desenvolvimento funcional nem confirma versão publicada. A organização das entregas é uma recomendação técnica inicial e não uma nova estimativa de horas ou data de entrega.

## DT-037 — Início incremental ET-01A e revisão por entrega

- **Data:** 07/09/2026
- **Responsável pela orientação:** Wallison Cheli, nesta sessão.
- **Status:** preparação incremental de fontes autorizada; recorte técnico definido no escopo 6.1; compilação remota e homologação pendentes.
- **Solicitação:** começar a desenvolver, apresentar material concreto e usar agente de revisão a cada evolução, mantendo ajustes por etapa.
- **Recorte:** validação pura dos campos do tipo, com componente ABL, apoio JavaScript, testes e demonstração sem persistência. Reutilizar no futuro cadastro; não implementar um cadastro provisório sobre tabelas legadas.
- **Contrato técnico:** catálogo 15. Normalização ASCII explícita evita aceitar caracteres proibidos por conversão linguística. Validação de campos não verifica unicidade, autorização nem idempotência durável de comandos.
- **Revisão:** agente independente confere contrato, código, casos de sucesso/vazio/erro/repetição e evidências antes do fechamento de cada entrega. Registrar achados e correções no acompanhamento; revisão documental/estática não é compilação.
- **Ambiente:** responsável informou que o desenvolvimento está em ambiente remoto e autorizou testes somente em teste. Acesso, pasta, versão e execução ainda serão disponibilizados; não foi executada publicação ou alteração em produção.
- **Mantém:** DT-036 para prontidão do recorte e separação entre desenvolvimento, homologação e implantação; CONS-03 e demais dependências de gravação continuam abertas. Modelo v1.6 sem mudança estrutural.

## DT-038 — Entregável Progress e consultas internas ET-01B

- **Data:** 07/09/2026
- **Orientação confirmada por Wallison:** priorizar tabelas específicas, `.p`, `.i` e fluxo Progress; Fluig fica com outro dev. Telas atuais são contexto. Eventual preparação de telas fica para depois do backend.
- **Recorte técnico:** preparar consultas internas de tipos e parametrização sobre os campos definidos em v1.6. Catálogo 17 fecha filtros, limites, cursores, retorno ABL, vazio/erro/repetição e fronteira de autorização. Não cria endpoint ou gravação.
- **Dados:** projeções `.i` herdam tipos das tabelas específicas por LIKE. Sem novo campo, índice, tabela física ou nome de banco presumido. Compatibilidade física e compilação permanecem pendentes.
- **Permissões:** tipos exigem permissão global informada por adaptador confiável; parâmetros recebem conjunto explícito de estabelecimentos já autorizados. Lista vazia nega acesso. O resolvedor de identidade/permissão é dependência da futura exposição pública; não aceitar permissão fornecida pelo cliente.
- **Entrega:** ET-01B, consultas ABL; não representa liberação do CRUD integrado ou solução de CONS-03. Preparação de fontes autorizada pela orientação de iniciar Progress sobre o modelo predefinido; execução exclusivamente no ambiente de teste quando disponibilizado.

## DT-039 — Fusão da identidade e projeção atual da etiqueta

- **Data:** 08/09/2026
- **Orientação confirmada por Wallison:** reduzir tabelas específicas quando houver ganho real, mantendo as estruturas necessárias ao saldo individual, aos movimentos, documentos, Bags e operações.
- **Decisão:** evoluir o modelo corrente para a v1.7 com 10 tabelas, 217 campos e 46 índices. Incorporar todos os campos de `contr_emb_saldo` em `contr_emb_etiqueta`, preservando uma única cópia dos campos de identidade e auditoria comuns.
- **Justificativa:** identidade e projeção atual tinham cardinalidade obrigatória 1:1, o mesmo ciclo de existência e atualização conjunta. A fusão elimina seis campos duplicados, uma tabela e sincronização entre duas projeções. `contr_emb_movto` continua separado e imutável, portanto a rastreabilidade não é reduzida.
- **Operações e eventos:** remover `contr_emb_oper.id-evento-inclusao` e seu índice. `contr_emb_evento.id-operacao` passa a ser a única direção desse vínculo, evitando dependência circular entre uma solicitação e os fatos que a executam.
- **Mantidas:** evento e item do evento continuam separados por granularidade documental; movimentos continuam como fatos; Bag/lacre, operação/itens e auditoria permanecem com responsabilidades próprias. Novas fusões nesses pontos misturariam ciclos de vida e aumentariam repetição ou campos sem aplicação.
- **Estoque:** `saldo-estoq` continua sendo a autoridade do saldo consolidado do Datasul. `contr_emb_etiqueta` mantém somente a projeção individual específica, explicada pelos movimentos.
- **Histórico:** `contr_emb_v1_6.json` preserva a definição anterior. Esta decisão substitui a separação física etiqueta/saldo das DT-016, DT-018, DT-020 e DT-023; mantém suas regras funcionais que não dependem dessa separação.
- **Implantação:** alteração somente de desenho. Nenhuma tabela específica foi criada ou alterada em banco e a materialização no OpenEdge de teste continua pendente.

## DT-040 — Embalagem como entidade controlada e primeiro movimento

- **Data:** 08/09/2026
- **Definição do responsável:** o objeto controlado é a embalagem. A etiqueta é consequência desse controle e identifica uma única embalagem. Depois de vinculadas, ambas representam a mesma identidade durante todo o ciclo.
- **Reimpressão:** uma etiqueta pode ser reimpressa quantas vezes forem necessárias usando o mesmo `cod-etiqueta`. Reimpressão não cria embalagem, identidade, movimento ou novo saldo individual. O layout e a quantidade de cópias continuam como contrato próprio de impressão.
- **Primeiro movimento:** o nascimento cria a embalagem e sua identificação. Como ainda não existe estado individual anterior, `id-movto-ant`, `situacao-ant`, `cod-estabel-orig` e `tipo-local-orig` ficam ausentes, e `qtidade-ant` é zero. O destino e o estado atual são obrigatórios.
- **Movimentos seguintes:** exigem movimento, situação e posição anteriores válidos e coincidentes com a projeção corrente, sob bloqueio. A exceção é exclusiva do nascimento e não permite origem fictícia.
- **Modelo:** manter o nome físico `contr_emb_etiqueta`, agora explicitamente entendido como registro da embalagem individual identificada pela etiqueta. O ajuste resolve CONS-01 sem criar campo ou tabela.
- **Implantação:** definição lógica no modelo v1.7; nenhuma alteração executada no banco.

## DT-041 — Convivência entre saldo anterior e embalagens individualizadas

- **Data:** 08/09/2026
- **Definição do responsável:** manter disponíveis os dois caminhos de implantação por item: consumir o saldo anterior sem inventário ou inventariá-lo e rateá-lo em embalagens, sem alterar o fluxo definitivo segundo a escolha do cliente.
- **Estrutura:** manter 10 tabelas. `contr_emb_etiqueta.tipo-controle` distingue `EMBALAGEM` de `PRE_SALDO`; `id-pre-origem` liga cada embalagem criada por inventário ao PRE agregado que lhe deu origem.
- **PRE:** uma carga de corte cria um registro por estabelecimento, depósito/localização, item, lote e validade, com código técnico único iniciado por `PRE-`. Ele não representa embalagem física, não é impresso e não participa de Bags.
- **Sem inventário:** movimentos do saldo anterior reduzem sua quantidade até zero. Embalagens oriundas de novos recebimentos coexistem como registros `EMBALAGEM` e seguem o fluxo normal.
- **Com inventário:** o rateio reduz o PRE exatamente pela soma das quantidades atribuídas às embalagens reais. Rateio total encerra o PRE em zero; rateio parcial preserva o restante. Cada embalagem conserva `id-pre-origem`, permitindo recuperar o código PRE e a carga de corte.
- **Integridade:** não duplicar quantidade entre PRE e embalagens. A operação de rateio, os primeiros movimentos das embalagens e a atualização do PRE pertencem à mesma transação e ao mesmo evento idempotente.
- **Carga:** planilha e script de importação ficam como GAP de implantação a detalhar. A decisão por item pode ocorrer antes da produção sem exigir mudança posterior no modelo.
- **Modelo:** v1.7 passa a ter 10 tabelas, 219 campos e 47 índices. Nenhuma estrutura foi implantada no banco.

## DT-042 — PRE fora do fluxo e assinatura permanente após inventário

- **Data:** 08/09/2026
- **Esclarecimento do responsável:** ao ativar o controle do item, todo saldo já existente nas combinações de estabelecimento, depósito/localização, lote e validade é identificado como PRE. O PRE agregado não entra no fluxo específico.
- **Sem inventário:** PRE não recebe `contr_emb_movto`, não entra em Bag e não é impresso. Continua sendo movimentado apenas pelo estoque consolidado padrão; a interface o apresenta como saldo anterior sem rateio de embalagens. A parcela operacional anterior é o consolidado ainda não coberto pelas embalagens controladas da mesma combinação.
- **Com inventário:** o rateio zera total ou parcialmente o PRE e cria embalagens individualizadas. Somente essas embalagens passam a entrar no fluxo normal. Cada uma conserva `id-pre-origem` durante todo o ciclo, permitindo recuperar o código `PRE-...` e demonstrar que existia antes da implantação.
- **Novas entradas:** depois da ativação do item, todo novo recebimento gera embalagens controladas, independentemente da existência de PRE em outros lotes/validades ou na mesma combinação.
- **Correção:** substitui a frase da DT-041 que atribuía movimentos específicos ao saldo anterior sem inventário. Mantém a estrutura com 10 tabelas, 219 campos e 47 índices e preserva o rateio transacional definido naquela decisão.
- **Implantação:** nenhuma alteração executada no banco.

## DT-043 — PRE como indicação de existência anterior, sem reconstrução

- **Data:** 08/09/2026
- **Esclarecimento do responsável:** PRE informa somente que aquela combinação de item, lote, validade, estabelecimento e posição já existia quando o item passou a ter controle de embalagens.
- **Limite:** não se conhece quantas embalagens existiam, quais eram, nem o histórico anterior. O projeto não tentará deduzir ou reconstruir essas informações.
- **Movimentação:** o item PRE pode continuar sendo movimentado no estoque consolidado padrão, sem etiqueta e sem rateio individual. Isso não cria `contr_emb_movto` e não o coloca no fluxo de embalagens.
- **Regularização:** para sanar um PRE, o cliente precisa inventariar as embalagens. O rateio reduz ou zera o PRE, cria as embalagens individualizadas e mantém nelas `id-pre-origem` permanentemente. A partir desse ponto, essas embalagens entram no mesmo fluxo das novas entradas.
- **Correção:** substitui qualquer interpretação das DT-041/042 que derive saldo PRE por cálculo, reconcilie histórico anterior ou trate seu consumo consolidado como movimento específico. Mantém 10 tabelas, 219 campos e 47 índices.

## DT-044 — Tipos simples na estrutura específica

- **Data:** 08/09/2026
- **Definição do responsável:** identificadores e versões usam `INTEGER`; não usar `INT64`, `CLOB` ou `LONGCHAR` nas tabelas específicas.
- **Conteúdos técnicos:** `dados-evento` e `resultado` usam `CHARACTER(4000)` e guardam somente o conteúdo sanitizado necessário à repetição e ao diagnóstico.
- **Auditoria:** `dados-ant` e `dados-atu` usam `CHARACTER(4000)` e registram somente os campos auditados que mudaram, antes e depois, sem copiar obrigatoriamente o registro completo.
- **Motivo:** seguir tipos simples já praticados no ambiente, evitar tratamento de LOB e manter limites físicos explícitos para o DDL Oracle e o schema holder.
- **Modelo:** permanecem 10 tabelas, 219 campos e 47 índices. Nenhuma estrutura foi implantada no banco.

## DT-045 — Estrutura física Oracle de teste

- **Data:** 09/09/2026
- **Ambiente comprovado:** banco/serviço `BPTESTE`, usuário e schema `EMS2ESP`, tablespace padrão `TS_EMS2`.
- **Mapeamento:** `DATETIME-TZ` será `TIMESTAMP(6) WITH TIME ZONE`; o tipo já existe no owner. Os demais campos seguem os tipos físicos observados: `VARCHAR2`, `NUMBER` e `DATE`.
- **Padrão DataServer:** uma sequência por tabela, `PROGRESS_RECID NUMBER`, índice único `##REC`, índices lógicos `##I<n>` e colunas `U##` para textos indexados sem diferenciação de maiúsculas/minúsculas.
- **Execução:** o DDL interrompe quando o banco/schema estiver incorreto ou quando já existir objeto `CONTR_EMB_*`; não contém `DROP`. Em 09/09/2026 foi executado com sucesso no teste, criando 10 tabelas, 10 sequências e 57 índices. As dez tabelas, 219 campos e 47 índices lógicos foram carregados e verificados no `shmgesp`; em 10/09/2026, as dez sequências e seus vínculos físicos com `EMS2ESP` também foram confirmados em nova sessão ABL.
- **Operação:** a repetição do processo em TESTE segue `docs/entregas/ROTEIRO_SCHEMAHOLDER_TESTE.md`. A carga das sequências compreende o `.df` e a configuração imediata de nome físico/owner antes da primeira validação. Publicação de API ou núcleo ABL exige renovação somente do PASOE; o Fluig permanece ativo como consumidor.

## DT-046 — Três módulos Progress por responsabilidade

- **Data:** 10/09/2026
- **Definição do responsável:** evitar um `.p` ou `.i` para cada operação CRUD e manter poucos arquivos com tamanho administrável.
- **Decisão:** organizar o núcleo em `contr-emb.p`, `contr-emb-rastreio.p` e `contr-emb-operacao.p`, com procedures internas por operação e um único `contr-emb.i` para contratos compartilhados.
- **Distribuição:** `contr-emb.p` concentra regras transversais, tipos, parâmetros, Bags/lacres e auditoria; rastreio concentra eventos, itens, embalagem/etiqueta e movimentos; operação concentra solicitações e seus itens, transferências, baixas, devoluções, descarte e compensações.
- **Materialização incremental:** criar somente o módulo necessário à entrega corrente. Os demais nomes representam a arquitetura aprovada, não arquivos vazios.
- **GATEC:** permanece em levantamento. Se a integração tiver responsabilidade e volume próprios, poderá ser criado `contr-emb-gatec.p`; caso contrário, as chamadas serão incorporadas ao módulo de negócio correspondente.

## DT-047 — Continuidade das saídas e devoluções pela tela Fluig

- **Data:** 10/09/2026
- **Definição do responsável:** a tela Fluig atual continua iniciando transferências entre estabelecimentos, armazenagem em terceiros e operações entre estabelecimentos de outra empresa. O processo não deve exigir que o usuário abandone o Fluig no meio da operação para concluir manualmente no Datasul.
- **Decisão:** as procedures de operação devem integrar as rotinas padrão necessárias, preservar a seleção das etiquetas e origens, vincular todos os documentos gerados e devolver à tela Fluig o resultado e as pendências do processo. A tela poderá receber ajustes para coletar e apresentar os dados que hoje existem apenas nas janelas padrão.
- **GAP prioritário:** a devolução de empréstimo não possui hoje no fluxo Fluig o equivalente à seleção da origem e ao vínculo documental realizados no FT4012. Devoluções integrais e parciais devem entrar no mesmo levantamento, incluindo FT4011 para devoluções e FT4012 para terceiros.
- **Limite da decisão:** FT4011/FT4012 são referências funcionais confirmadas pela documentação, mas a correspondência exata por natureza, assinatura de API/BO, versão instalada e possibilidade de execução sem abrir a interface ainda precisam de validação. A observação de que a devolução de compra abre FT4011 permanece como hipótese operacional até teste no ambiente.

## DT-048 — Paridade funcional com melhoria de fluxo e automação

- **Data:** 10/09/2026
- **Definição do responsável:** sem as melhorias adicionais da revitalização, a alteração funcional seria substituir a criação da entrada pelo Fluig/REAPI pela criação no ANFE/Datasul. Todas as demais funcionalidades anteriormente existentes devem ser mantidas.
- **Decisão:** usar o fluxo vigente como baseline obrigatório. Cada função deve ter destino equivalente no sistema novo, com adaptação ao modelo `contr_emb_*`, melhoria de fluxo e automação onde houver trabalho manual ou quebra de continuidade.
- **Complementação:** finalizar pelo Fluig os pontos que hoje exigem atuação manual no Datasul, especialmente devoluções, pagamento/retorno e renovação de empréstimos, cancelamentos e anulações, conforme DT-047.
- **Controle de paridade:** antes de retirar ou substituir uma função, registrar funcionalidade anterior, destino novo, melhoria e teste de aceite. Ausência dessa correspondência é GAP de escopo.
- **Reaproveitamento técnico:** a paridade exigida é funcional. Devido à fronteira REST e à mudança dos cadastros/modelo, praticamente todas as procedures precisam de novo contrato e adequação ou reimplementação. O legado é base sólida de análise, não fonte a copiar integralmente.
- **Limite:** preservar funcionalidade não significa portar `cod-refer`, `tipo-con-est = 4`, tabelas antigas ou contratos inseguros. O comportamento necessário é preservado sobre a arquitetura nova.

## Nota de planejamento — gap técnico acumulado

A redefinição do controle de saldo para a estrutura específica `contr_emb_*`, a criação e conferência das tabelas/schema holder e a aprendizagem prática de ABL, REST, Dataset, Fluig e integração Datasul formam esforço técnico adicional do projeto. Esse esforço deve aparecer na reestimativa das etapas e não deve ser lançado como pendência de regra de negócio. A nota é de planejamento; não altera contratos nem libera implementação.
## DT-049 — Comando cadastral idempotente usando `contr_emb_evento`

- **Data:** 10/09/2026
- **Recorte:** o primeiro comando de gravação será `salvarTipo`, dentro de `contr-emb.p`, para incluir, alterar ou inativar tipos. Código não muda e não haverá exclusão física por esse contrato.
- **Repetição durável:** utilizar `contr_emb_evento` como registro comum do comando. Mesma origem/chave/conteúdo devolve o resultado concluído; mesma chave com conteúdo diferente gera conflito. O evento cadastral não cria movimentos nem itens de evento.
- **Atomicidade:** tipo, auditoria e resultado concluído confirmam na mesma transação local. A auditoria referencia `id-evento`; versão esperada protege concorrência.
- **Segurança:** identidade e autorização são resolvidas antes da rotina por adaptador confiável. Hashes são produzidos sobre envelope canônico pelo backend e não aceitos como autoridade da tela.
- **Estrutura:** nenhuma tabela ou campo novo. Em 10/09/2026, as dez sequências Oracle foram registradas na imagem `mgesp` por um `.df` exclusivo e ficaram visíveis no schema holder de TESTE (`TOTAL=10` em nova sessão). A carga não alterou valores correntes.
- **Efeito:** encaminha CONS-03 para os comandos cadastrais; recuperação concorrente e estados do mecanismo comum continuam obrigatórios nos comandos operacionais longos.

## DT-050 — Comando integrado da parametrização

- **Data:** 10/09/2026
- **Recorte:** `salvarParametro`, dentro de `contr-emb.p`, atende inclusão, alteração, inativação e exclusão física da parametrização. O identificador é gerado por `CONTR_EMB_PARAM_SEQ`; alteração, inativação e exclusão exigem identificador e versão esperada.
- **Integridade cadastral:** o servidor valida `estabelec.cod-estabel`, `mgcad.item.it-codigo`, igualdade entre a unidade informada e `mgcad.item.un`, existência do tipo e tipo ativo ao incluir ou deixar o parâmetro ativo. O par estabelecimento/item permanece único. A autorização do estabelecimento chega resolvida por adaptador confiável e nunca é aceita diretamente da tela. A exigência anterior de conversão manual prévia para lote foi substituída pela DT-055.
- **Histórico:** inclusão, mudança, inativação e exclusão geram `contr_emb_evento` e `contr_emb_audit` na mesma transação. A exclusão conserva a fotografia anterior na auditoria e no resultado idempotente; não remove eventos, itens de evento ou demais fatos históricos.
- **Repetição e concorrência:** aplica o mesmo mecanismo comprovado em DT-049: origem, chave e hashes canônicos, recuperação de resultado concluído, conflito de reutilização da chave e versão esperada.
- **Limite:** este contrato é o núcleo ABL. Identidade, autorização e hashes continuam sendo responsabilidade do futuro adaptador REST confiável; a homologação REST permanece separada.

## DT-051 — Conversão controlada de referência para lote

- **Data:** 11/09/2026
- **Definição do responsável:** os itens participantes atualmente configurados com `mgcad.item.tipo-con-est = 4` deverão ser convertidos para `3`, mesmo que a operação exija intervenção ampla, desde que executada com cautela e evidências.
- **Execução posterior:** a conversão será objeto de plano de ação próprio. Antes de executar, levantar item e estabelecimento, `ref-item`, referências, saldos por referência/lote/validade/posição, documentos e alocações em aberto, além da correspondência para os lotes de destino.
- **Controles mínimos:** backup recuperável, ensaio em TESTE, relatório antes/depois, reconciliação quantitativa, validação funcional dos fluxos afetados, janela controlada, responsáveis e plano de retorno.
- **Limite:** esta decisão confirma a necessidade e o método de governança; não aprova agora uma rotina, atualização direta de `saldo-estoq`, alteração em produção ou reaproveitamento automático do conversor legado.

## DT-052 — AED como caminho preferencial para a pré-aprovação das fazendas

- **Data:** 11/09/2026
- **Origem:** reunião `[ANFe] Integração BP - Monitor XML` com a equipe ANFe, consolidada em [`docs/entregas/ANFE_AED_REUNIAO_2026-09-11.md`](entregas/ANFE_AED_REUNIAO_2026-09-11.md); demonstração com Ítalo/BP e o responsável técnico do AED ainda será agendada.
- **Necessidade:** usuários das fazendas devem visualizar XMLs emitidos contra seu estabelecimento e reconhecer o documento correto ou rejeitar uma emissão indevida. A função atende todos os XMLs aplicáveis ao estabelecimento, sem depender da parametrização do Controle de Embalagens.
- **Caminho preferencial:** validar o módulo padrão AED (Aprovação Eletrônica de Documentos) antes de desenvolver integração própria. Segundo a equipe ANFe, o documento entra em bloqueio físico, o usuário não fiscal acessa uma lista de pendências por perfil específico e a aprovação libera o documento para o fluxo fiscal já utilizado na usina.
- **Continuidade:** depois do reconhecimento da fazenda, o fiscal assume o documento no ANFe, executa as verificações do tipo de entrada e o importa para o Datasul/RE1001. A consulta de itens parametrizados e a geração do Controle de Embalagens continuam vinculadas à atualização confirmada no RE1001; não pertencem ao AED.
- **Aceite pendente:** a demonstração deve confirmar visão restrita por estabelecimento/fazenda, comportamento de reconhecimento e rejeição, tipos de documento abrangidos, perfis e permissões, auditoria, situações, retorno ao usuário e aderência ao processo atual da BP.
- **Contingência:** se o AED não atender ao aceite, levantar com a equipe ANFe o contrato ou chamada oficialmente suportada utilizada pela função e então avaliar sua exposição no `Monitor-Xml` via baseline REST. Não iniciar cópia de chamada, Dataset ou integração personalizada antes dessa conclusão.
- **Efeito:** a hipótese anterior de desenvolver diretamente uma situação própria no `Monitor-Xml` deixa de ser o caminho principal. O fonte mockado permanece como referência visual e alternativa condicionada, sem integração aprovada.

## DT-053 — Custódia individual acompanha o saldo padrão de terceiros

- **Data:** 11/09/2026
- **Definição do responsável:** nas remessas de armazenagem em terceiros, o Datasul retira o saldo da disponibilidade interna do estabelecimento remetente e passa a controlá-lo como saldo de terceiro; o retorno baixa esse controle. As embalagens individualizadas devem acompanhar o mesmo ciclo.
- **Representação:** a remessa preserva identidade e conteúdo e altera a posição/posse das etiquetas selecionadas para `TERCEIRO`. O retorno total ou parcial usa documento/linha de origem, etiquetas e quantidades efetivamente devolvidas, baixa a pendência correspondente e atualiza a posição interna real.
- **Autoridade:** o estoque e o saldo de terceiros consolidados continuam no padrão Datasul. `contr_emb_*` registra operação, vínculo documental, custódia corrente e movimentos individuais após a confirmação padrão, sem atualizar diretamente `saldo-estoq` nem duplicar o lançamento ERP.
- **Estrutura:** o modelo v1.7 já suporta a regra por `contr_emb_etiqueta`, `contr_emb_movto`, `contr_emb_oper` e `contr_emb_oper_item`; não será criada outra tabela de saldo sem lacuna comprovada.
- **Limite:** a aplicação a empréstimos entre empresas é condicional à natureza e ao efeito padrão confirmados no ambiente. Permanecem pendentes os contratos, produtores, chaves de movimento, disponibilidade/alocação e reversões por operação.

## DT-054 — Autorização Fluig por grupo e recorte explícito de estabelecimentos

- **Data:** 11/09/2026
- **Definição do responsável:** o controle de usuários, telas e ações do projeto é realizado no Fluig por grupo; o desenvolvedor Fluig fará o controle de exibição da interface.
- **Fronteira confiável:** o Widget não informa livremente usuário, grupo ou permissão. O Dataset obtém o usuário da sessão, valida o grupo aplicável e chama o serviço autorizado. A API Datasul fica disponível somente por esse serviço e usa a identidade recebida para auditoria.
- **Estabelecimentos:** quando um grupo limitar estabelecimentos, o Dataset envia uma lista explícita já resolvida. Consultas de parâmetros aplicam primeiro essa lista e comandos recusam estabelecimento fora dela. O ABL não interpreta nomes de grupos e não usa filtro visual como autorização.
- **Organização:** um adaptador REST fino em `fontes/progress/esp/api/v1/controle-embalagens.p` expõe tipos e parâmetros e delega as regras a `contr-emb.p`; isso não acrescenta outro módulo de negócio nem cria um `.p` por CRUD.
- **Pendente:** definir com o desenvolvedor Fluig os códigos dos grupos e sua correspondência com estabelecimentos, inclusive grupos de visão global, antes da publicação do Dataset e da homologação integrada.

## DT-055 — Parametrização ativa converte o item para lote na mesma ação

- **Data:** 11/09/2026
- **Definição do responsável:** a parametrização é uma única operação da tela Fluig. O usuário busca um item existente no Datasul, informa estabelecimento, tipo de embalagem e capacidade e salva; não deve abrir outra tela nem executar previamente a conversão do item.
- **Efeito:** ao incluir ou reativar uma parametrização, se `mgcad.item.tipo-con-est` ainda não for `3`, o backend deve usar a API padrão de manutenção do item da versão instalada, confirmar o controle por lote e somente então concluir `contr_emb_param`, evento e auditoria. Tipo de embalagem precisa existir e estar ativo, pois é uma opção reutilizável selecionada nessa mesma tela.
- **Desativação:** esta regra foi refinada pela DT-058. Inativação ou exclusão do último parâmetro ativo do item também deve executar a reversão controlada Lote → Serial; enquanto houver outro parâmetro ativo do mesmo item, o controle padrão permanece Lote.
- **Conversão com histórico:** itens em referência continuam sujeitos aos controles de transição da DT-051. A experiência é uma ação única, mas a operação deve recusar com erro controlado quando o inventário ou a conversão segura não puderem ser concluídos.
- **Implementação:** o legado comprova o uso de `cdp/cdapiitem.p`, `setTTItem` e `validateSaveImplantacao`; a TOTVS também relaciona CDAPIITEM entre as APIs suportadas para alteração de item. O produto instalado foi identificado como Datasul 12.1.2511.15, com OpenEdge 12.2; antes de alterar o fonte, conferir nessa instalação a include/estrutura oficial e a fronteira transacional entre o cadastro padrão e `mgesp`. Não copiar a temp-table legada de 476 linhas nem atualizar `mgcad.item` diretamente.
- **Substitui parcialmente:** DT-050 quanto à conversão prévia; DT-051 continua válida para governança e tratamento do histórico existente.

## DT-056 — Checkpoint documental e técnico verificável

- **Data:** 12/09/2026
- **Definição do responsável:** cada fechamento de raciocínio, funcionalidade ou etapa deve permanecer recuperável depois de uma interrupção, com matriz de APIs e cronograma coerentes com a implementação e as evidências.
- **Fonte da verdade:** a definição continua no documento de origem. Decisões, pendências, changelog, matrizes e acompanhamento registram somente seus papéis próprios; os guias continuam como mapas de leitura, sem copiar os contratos.
- **Matriz REST:** toda ação declarada no adaptador deve possuir uma linha em `docs/entregas/MATRIZ_APIS_REST.md`, com funcionalidade, núcleo, estado executável, autorização, evidência e próximo fechamento. Funcionalidades futuras permanecem como propostas sem inventar rotas.
- **Validação automática:** `Validar-Checkpoint-Projeto.bat` verifica documentos e guias obrigatórios, modelo JSON, executor, sincronismo do pacote, cobertura da evidência de compilação, inventário executável, matriz REST, massa de teste chumbada e atualidade do contexto. Erro bloqueia o fechamento; aviso preserva a pendência sem declarar falha inexistente.
- **Planner:** a cada checkpoint relevante que alterar a situação de execução, atualizar a fotografia vigente. Atividades individuais usam somente `0%`, `15%`, `30%`, `45%`, `60%`, `75%`, `90%` ou `100%`; percentuais intermediários ficam restritos às fases e aos agrupamentos, calculados pela média das atividades filhas.
- **Limite:** o comando não consulta ambientes externos e não transforma arquivo em compilação, rota em publicação ou teste técnico em homologação. Esses estados só avançam com evidência identificada no `08_ACOMPANHAMENTO_ETAPAS.md`.

## DT-057 — Conversão do controle de estoque exige o tratamento padrão do histórico

- **Data:** 14/09/2026
- **Constatação:** o `CE0111 — Alteração Tipo Controle Estoque` solicita lote e validade ao converter um item existente para lote porque precisa ajustar saldos, movimentos, documentos e outras tabelas relacionadas. O lote informado na conversão não limita os lotes futuros do item.
- **Serial → Lote:** o `v80in172.w` confirma `ce0111.i` com lote/validade obrigatórios e referência vazia. A rotina concentra o histórico por posição remanescente e atribui os valores informados. O código definitivo do lote inicial permanece pendente.
- **Referência → Lote:** o SmartViewer confirma `ce0111.i2` com referência vazia. Lote/validade são preservados em `saldo-estoq` e na maior parte do histórico, mas `ce0111.i4` limpa `ped-saldo.lote`. A limpeza alcança somente os vínculos `cod-refer` dos registros do item convertido; o cadastro mestre da referência permanece intacto para os demais itens. A consolidação de mesmo lote com referências diferentes está comentada; qualquer colisão da chave remanescente deve impedir a conversão automática.
- **Integração:** `CDAPIITEM` isolado não é suficiente para itens que já possuam registros relacionados. O backend deve usar uma interface suportada que realize o tratamento equivalente ao CE0111 ou devolver impedimento controlado de migração; não deve reproduzir as atualizações diretas observadas no legado.
- **Limite da evidência:** o chamador foi recebido e mapeado, mas o `ce0111.w` declara `2.00.00.012`, enquanto a tela de TESTE exibiu `2.00.00.018`; o Viewer possui revisão própria `.048`. Não há API independente nem transação explícita. Automação e produção continuam dependendo da correspondência com o `.r` ativo, interface suportada e ensaio físico.
- **Refina:** DT-051 e DT-055. A parametrização continua sendo uma única ação para o usuário, mas pode ser recusada quando o histórico exigir uma migração ainda não preparada.

## DT-058 — Desativação do último parâmetro reverte Lote para Serial

- **Data:** 14/09/2026
- **Definição do responsável:** desabilitar o controle específico deve transformar novamente o item de Lote (`tipo-con-est = 3`) para Serial (`1`), preservando a coerência do estoque e do histórico.
- **Abrangência por item:** a parametrização é por estabelecimento/item, mas `tipo-con-est` pertence ao item. A reversão só ocorre quando a inativação ou exclusão retirar o último parâmetro ativo do item em todos os estabelecimentos; desativar apenas um vínculo não pode quebrar os demais.
- **Ação única:** ao retirar o último parâmetro, o backend valida a elegibilidade, converte pelo mecanismo padrão, confirma `tipo-con-est = 1` e conclui parâmetro, evento e auditoria. Falha ou incerteza impede a conclusão e não pode deixar estados divergentes.
- **Proteções:** não reverter enquanto existirem embalagens ou quantidades individuais ativas, operações abertas ou vínculos específicos que dependam do lote. O tratamento deve reconciliar saldos, terceiros, movimentos, documentos, reservas e inventário; a política exata de encerramento será provada em TESTE.
- **Evidência CE0111:** o `v80in172.w` confirma que qualquer tipo maior que 1 → Serial chama `ce0111.i` com lote/referência vazios e validade desconhecida. A rotina limpa essas dimensões no histórico alcançado e consolida saldo/inventário.
- **Refina:** DT-050, DT-055 e DT-057 quanto à desativação e à conversão inversa.

## DT-059 — Procedure backend própria para conversão do controle de estoque

- **Data:** 14/09/2026
- **Definição do responsável:** a conversão será implementada em uma procedure backend própria. O cadastro do item será alterado pela `CDAPIITEM`; o restante do tratamento seguirá as rotas e tabelas comprovadas nos fontes do CE0111.
- **Organização:** `contr-emb-conversao.p` será um serviço técnico chamado pelo núcleo `contr-emb.p`, não um CRUD adicional nem uma tela Progress. Ele expõe análise prévia sem gravação e execução controlada para Serial → Lote, Referência → Lote e Lote → Serial. Seu código interno fica consolidado no `.p`; existe somente `contr-emb-conversao.i`, limitado à temp-table compartilhada com os chamadores e testes.
- **Adaptação:** as regras dos includes do CE0111 serão reescritas para contexto backend, substituindo dependências de frame, SmartViewer e acompanhamento visual por parâmetros, retornos estruturados e erros controlados. Os fontes de referência não serão executados diretamente no PASOE.
- **Transação:** alteração do item, tratamento das tabelas padrão e mudança de `contr_emb_param` devem participar da mesma unidade de trabalho ou possuir recuperação comprovada. A implementação permanece isolada do `salvarParametro` até o ensaio em TESTE demonstrar rollback integral; o legado separava essas fases e podia deixar estado parcial.
- **Pré-validação:** antes de gravar, a procedure confirma item, transição suportada, lote/validade para Serial → Lote, colisões para Referência → Lote e impedimentos do controle específico para Lote → Serial. O diagnóstico identifica a abrangência encontrada sem alterar registros.
- **Evidência e liberação:** compilação confirma somente compatibilidade sintática. A integração no REST depende dos ensaios ET-01F de sucesso, repetição, recusa, reconciliação e falha forçada. Nenhuma execução em produção é autorizada por esta decisão.
- **Substitui:** a proibição de implementar as atualizações equivalentes registrada na DT-057. Permanece proibido alterar apenas `mgcad.item`/`saldo-estoq`, instanciar o Viewer no PASOE ou usar os includes originais como API.

## DT-060 — Registros consultados no banco lógico proprietário

- **Data:** 15/09/2026
- **Definição do responsável:** qualquer conferência ou alteração de registro funcional deve usar o banco lógico proprietário: `mgcad` para item e cadastros mestres, `mgmov` para saldos, terceiros, movimentos e documentos de estoque e `mgesp` para as estruturas específicas `contr_emb_*`.
- **Schema holder:** suas conexões existem para compilação e leitura/manutenção dos metadados DataServer; não são fonte de registros funcionais. A consulta de `_File/_Field` pode usar a conexão do holder exclusivamente para inspecionar o schema image.
- **Aplicação no ET-01H — atualização de 16/09/2026:** cod-refer aponta para COD_REFER e cd-referencia para CD_REFERENCIA. Propriedade do dado não obriga prefixar toda tabela: o acesso aprovado a saldo-estoq usa a resolução configurada na sessão Datasul, sem mgmov. e sem FIELDS. Não forçar qualificação não validada. A leitura passou em 6.325 linhas; falta recompilar a revisão do conversor e repetir o diagnóstico 4→3, sem Verify ou alteração estrutural.

## DT-061 — Consolidar referências equivalentes na conversão para lote

- **Data:** 16/09/2026.
- **Autorização:** após o diagnóstico de 361378 com 6.218 linhas colidentes, o responsável confirmou referências diferentes para o mesmo lote/validade e solicitou preparar a consolidação.
- **Agrupamento:** estabelecimento, depósito, localização, item, lote e validade. Somar os cinco campos de quantidade usados pelo bloco comentado de `ce0111.i2`; conservar as maiores datas conhecidas de última entrada e contagem. Não recriar saldo, modificar lote/validade ou excluir cadastro mestre de referência.
- **Proteção:** diferenças de validade na mesma posição/lote e diferenças nos demais campos não agregáveis impedem a conversão. A chave física sem referência ainda não foi demonstrada para validades distintas. A comparação dos demais campos usa o buffer funcional, sem consultar registros no holder.
- **Terceiros:** preservar cada registro e seus vínculos; somente retirar cod-refer conforme o fluxo já adaptado. Não consolidar contrapartes/documentos nem misturar custódias.
- **Transação e ensaio:** consolidação e limpeza da referência ocorrem na transação do conversor. O executor existente confere soma dos cinco campos por grupo, datas, posições e quantidade de grupos; depois comprova restauração de todas as linhas fotografadas por ROWID. Manter análise somente leitura antes da execução autenticada com rollback.
- **Substitui:** bloqueio indiscriminado de qualquer colisão 4→3 da DT-057. Colisões equivalentes passam a ser consolidáveis; incompatibilidades continuam impedidas. Não muda a organização DT-059, nem libera salvarParametro, REST ou produção. Compilação e ensaio da nova revisão permanecem pendentes.


## DT-062 — Agrupadoras F zeradas fora do saldo operacional

- **Data:** 16/09/2026.
- **Definição do responsável:** referências iniciadas com F agrupam etiquetas do faturamento legado e têm saldo transitório. Ficam fora das somas do saldo operacional; a clarificação seguinte admite absorver sua linha zerada no único registro consolidado, retirando a referência.
- **Aplicação:** somente 4→3. Priorizar sobrevivente não F; somar apenas linhas operacionais compatíveis. Absorver F zeradas do mesmo grupo antes de limpar cod-refer, sem acrescentar valores/datas nem exigir igualdade de fabricação/log-reg-zero com a linha operacional. O cadastro mestre permanece intacto. Se o grupo contiver apenas F, manter uma linha zerada original com referência vazia.
- **Zero comprovado:** validar qtidade-atu/ini/fin, qt-alocada, qt-aloc-prod e qt-aloc-ped. Qualquer valor não zero ou desconhecido retorna FATURAMENTO_COM_VALOR_PENDENTE antes de gravar. Não descartar quantidade/alocação por quantidade atual zero, prefixo ou marcador. A amostra F000050 já apresentou quantidade atual 1 e exige conferir a massa/fluxo de TESTE.
- **Compatibilidade:** posição, lote e validade são preservados. Validades divergentes na mesma posição/lote permanecem impedidas conforme DT-061; entre linhas operacionais, conservar as verificações dos campos não agregáveis. Linhas que convergem ao mesmo grupo não são impedimento por si só: absorver duplicadas antes da limpeza. Não foi comprovado um índice físico específico.
- **Lógico:** preservar log-reg-zero da sobrevivente. Não adotar a proposta anterior de AND, nem transformar essa regra funcional em definição do campo padrão TOTVS.
- **Ensaio:** fotografar todas as linhas por ROWID, incluindo F, fabricação, lógico, alocação de pedido e campos já conferidos. Verificar uma linha por grupo, sobrevivente operacional quando existir e grupo apenas F integralmente zerado. Informar quantidades de F absorvidas/conservadas e grupos operacionais. Rollback deve restaurar todas as linhas e valores fotografados.
- **Refina:** DT-061 quanto ao tratamento das agrupadoras. Não muda 1→3 ou 3→1 nem libera integração ao cadastro/REST ou produção. Nova compilação e diagnóstico em TESTE são obrigatórios antes de ensaiar rollback.


## DT-063 — Todas as referências contribuem à consolidação

- **Data:** 16/09/2026. Correção expressa do responsável após interpretar o par F000050/PL-100: duas referências, quantidade 1/0, resultado consolidado 1. Todas as referências entram na soma; F não exige quantidade zero.
- **Substitui:** DT-062 quanto a exclusão das somas, restrição a F zeradas e FATURAMENTO_COM_VALOR_PENDENTE. Esse bloqueio foi preparado por interpretação errada do assistente e retirado antes de ensaio em TESTE.
- **Quantidade:** soma por estabelecimento/depósito/localização/item/lote/validade de qtidade-atu/ini/fin, qt-alocada, qt-aloc-prod e qt-aloc-ped, inclusive F. Somar também a alocação de pedido evita perder compromisso ao absorver linhas; campo comprovado em stockBalanceMonitor.p. É política do backend próprio, sem afirmar que o bloco CE0111 recebido soma esse sexto campo.
- **Dados restantes:** priorizar sobrevivente não F. dt-fabric e log-reg-zero divergentes em F não substituem os valores da sobrevivente operacional. Quantidade zero não é erro. Diferenças entre linhas operacionais e demais campos sem regra continuam reportadas especificamente; não inventar valor de fabricação nem significado TOTVS do lógico. Grupo apenas F conserva uma linha original e todas as somas. Datas de entrada/contagem conservam máximas conhecidas de todas as linhas.
- **Integridade:** preservar posições/lote/validade; quantidades desconhecidas não são zero. Não misturar terceiros ou excluir referência mestre. Consolidar antes de limpar cod-refer. O diagnóstico verifica todos os pares para que uma F não esconda divergência entre operacionais.
- **Prova:** executor soma todas as referências e as seis quantidades/alocações por grupo, confere dados da sobrevivente e rollback por ROWID. Nova compilação SAVE 5/0 e análise somente leitura precedem mutação autenticada. 4→3, 3→1 e integração ao parâmetro ainda pendentes; planner 51%, nenhuma mudança REST ou produção.

## DT-064 — Campos, ações e apoios limitados das telas Fluig

- **Data:** 16/09/2026. Solicitado pelo responsável: mockups e mapeamento por tela/campo/ação/procedure, incluindo autocomplete e busca, para orientar o Dev e a manutenção.
- **Direção:** três telas do mapa vigente, modais internos, identificadores estáveis e distinção entre operação local, rota implementada e proposta. Fonte da cobertura: `docs/entregas/cobertura-telas.json`; apresentação: `MATRIZ_TELAS_CAMPOS_ACOES.md`. Não inventar endpoints executáveis para nomes propostos.
- **Manutenção contínua — confirmação posterior do responsável:** toda necessidade nova de autocomplete identificada ao avançar entra no registro e nas duas matrizes no mesmo checkpoint, mesmo ainda pendente. Informar tela/campo, dependências e estado; atualizar procedure/rota/arquivo conforme comprovação, sem esperar concluir a implementação.
- **Abrangência confirmada:** novas procedures também são registradas ao identificar a necessidade: catálogo e matriz Progress, matriz REST para exposição aplicável e mapa de controles para interação de tela/campo/ação. Incluir finalidade, arquivo, dependências e estado; avanço do acompanhamento/Planner somente quando o checkpoint aceito justificar.
- **Primeiros apoios:** `consultarEstabelecimentos` e `consultarItens` no núcleo existente, sem tabela física nova. REST `GET /apoios/estabelecimentos` e `GET /apoios/itens`. Contrato no catálogo, seção 21. Itens são cadastro global, sem prometer disponibilidade por estabelecimento. CD de ressuprimento continua referência independente.
- **Interface:** dois caracteres, 350 ms, teto 20, identidade selecionada, cancelamento, resposta antiga ignorada, limpeza dos campos dependentes. Autorização antes da leitura e antes da paginação; contexto reconstruído pelo Dataset. Grupos instalados ainda pendentes.
- **Planner:** manter o arquivo apresentado à gestão e seus avanços. Não rebaselinear por estimativa do assistente. O XLSX auditado não contém datas de início/término; manter compromisso informado de validação fim de outubro/início de novembro e registrar a necessidade de trazer as datas para o controle local. Preparação de fontes/mockups não comprova teste integrado.
- **Aceite:** revisão local e teste do protótipo/componentes; compilação OpenEdge, publicação, Dataset autorizado e testes reais dos apoios permanecem pendentes até evidência de TESTE.

## DT-065 — Retirar comparação genérica dos atributos do saldo

- **Data/autorização:** 16/09/2026; responsável solicitou revisar e corrigir conferências desnecessárias após CE0111 `.018` concluir 4→3 de 357867 sem erro visível. O relato não homologa consolidação nem o conversor próprio.
- **Achado:** `campoSaldoIncompativel` percorria `NUM-FIELDS`, exigindo igualdade de todos os atributos não somados. O CE0111 recebido não contém essa exigência. Revisar uma diferença técnica não equivale a comprovar impedimento funcional.
- **Correção:** remover comparação genérica, inclusive a recusa por `dt-fabric`/`log-reg-zero` entre referências operacionais. Conservar os atributos da sobrevivente original, com prioridade não F; não recalcular lógico ou escolher uma nova fabricação. Preservar seis somas e máximas datas de todas as linhas. Zero e referências diferentes não são impedimentos.
- **Repetição sem alteração:** ao encontrar item já no tipo solicitado, devolver sucesso antes das pré-condições de mutação e da leitura de histórico. Não chamar CDAPIITEM nem atualizar registros; diagnóstico vazio nessa repetição. Item inexistente continua recusado.
- **Mantido:** quantidades/alocações desconhecidas; recusa por validade diferente na mesma posição/item/lote enquanto a chave física de coexistência não for comprovada; política configurada e custo específico com evidência no Viewer; erros CDAPIITEM e rollback. Validar somente esses campos na compatibilidade, sem varrer o dicionário inteiro. Validade é uma limitação do backend, não exigência atribuída à TOTVS.
- **Substitui:** DT-061/063 somente quanto à igualdade dos demais atributos. Não muda assinaturas, terceiros, mestre de referência, 1→3/3→1 ou integração à parametrização. SAVE 5/0, diagnóstico de 361378 e execução autenticada com rollback permanecem pendentes; Planner oficial 50%, sem nova rota REST.

## DT-066 — Adiantamento das consultas ABL de Bags

- **Autorização:** responsável pediu adiantar procedures possíveis enquanto testes estão indisponíveis, preservando saldo de tokens e ponto de retomada.
- **Recorte:** `consultarBags` e `consultarConteudoBag` no `contr-emb.p`, com projeção transitória `ttEmbBag` no include existente; sem alteração física do modelo. Definição técnica no catálogo 22 antes do código.
- **Segurança/leitura:** lista explícita autorizada, estabelecimento responsável da Bag e estabelecimento atual da etiqueta; teto 20 e cursor exclusivo por ID; erro indistinto para Bag inexistente/sem acesso; filtros estáticos e NO-LOCK. Situações são lidas, não transicionadas. Totais globais e dados de impressão ficam fora deste recorte.
- **Limite:** implementação em fonte não comprova compilação, publicação ou homologação. Criar um ensaio readonly para o recorte no módulo de testes ET-05. Não antecipar cadastro/transição/conteúdo mutável com regras abertas. Atualizar matrizes/mapa/pacote/retomada. Planner oficial permanece 50%.

## Validação posterior — 16/09, 17:13–17:21

Em 16/09/2026, SAVE 5/0 às 17:14, análise de 361378 com SUCESSO=SIM às 17:15 e conversão Referência→Lote com rollback às 17:21: TOTAL=6 FALHAS=0. Dentro da transação, 6.325 saldos consolidaram em 139 grupos, 33 referências F absorvidas, 17 estabelecimentos; após rollback, tipo 4 e 6.325 saldos restaurados, quantidade 39.252,73. Terceiros: 454 registros e quantidade 21.118 preservados/restaurados. Sem conversão persistida; 3→1, integração a salvarParametro e ensaio de atualização definitiva continuam pendentes.

ET-05A: núcleo e teste compilados; relatório geral 11/2 teve apenas os dois erros 468 ET-01H, resolvidos pelo SAVE 5/0 posterior. Execução funcional Bags ausente. Evidência consolidada: docs/entregas/evidencias/validacao_et01h_et05a_2026-09-16.md. Não constitui nova regra ou autorização de mutação definitiva.

## Checkpoint posterior — ET-05A às 17:35

ET-05A executado em TESTE em 16/09 às 17:35: cinco recusas passaram, TOTAL=5 FALHAS=0. MASSA_BAG_AUSENTE: consultas positivas, conteúdo, repetição e paginação não executados; homologação parcial. Núcleo/teste seguem compilados. Relatório geral das 17:34 teve três erros 468 apenas nos fontes ET-01H (conversor, análise e executor), já cobertos no SAVE 5/0 anterior; conversão 4→3 aprovada não precisa ser repetida.

compilar-consultas.p foi ajustado: somente quando o compilador retornar 468, refaz com SAVE em _validacao_compilacao sob a pasta do fonte. Não sobrescreve .r ativo nem executa procedure. Demais erros continuam falhas. Essa revisão do auxiliar ainda precisa ser compilada/executada no Studio; o alvo é FONTES=11 FALHAS=0. A pasta isolada não deve entrar no PROPATH da aplicação e não representa publicação.

Evidência: docs/entregas/evidencias/et05a_recusas_e_compilador_468_2026-09-16.md. Calendário e avanço oficial preservados; recusa aprovada sem massa não encerra a atividade.

## DT-067 — Entrega pela pasta aberta ET-01_TESTE, 17/09/2026

- Responsável definiu a pasta aberta como entrega corrente; compacta quando desejar. Não gerar ZIP automaticamente.
- Caminho oficial: docs/entregas/pacotes/ET-01_TESTE, sincronizado com os fontes do projeto em cada checkpoint. Informar arquivos relativos alterados para cópia ao servidor.
- ZIP é snapshot histórico e não identifica versão corrente. Conferência realizada antes desta definição: todos os arquivos da pasta coincidiam com o ZIP, incluindo testes/et01/compilar-consultas.p; horário diferente não correspondia a diferença de conteúdo. Isso não comprova o arquivo executado no servidor nem diagnostica o novo erro de compilação.
- Removida compactação automática da rotina existente; validador agora confere também sincronismo do próprio auxiliar compilar-consultas.p. Nenhuma alteração funcional ABL, execução no servidor ou promoção de homologação.
- Preservar r-code ativo/evidências e distinguir fonte atualizado de compilação. Orientações anteriores que tratam ZIP e pasta como referências paralelas ficam superadas por esta decisão.

## DT-068 — Integrar conversão à parametrização, 17/09/2026

- **Base:** DT-055/058/059 e ensaios ET-01H aprovados em 1→3, 4→3 e 3→1; escopo 6.5 atualizado antes do código.
- **Contrato:** dois novos inputs ABL após situação: lote e validade de migração. REST aceita os campos transitórios homônimos; inclusão/reativação Serial exige valores explícitos. Nome definitivo de lote inicial continua pendente, sem chumbamento.
- **Atomicidade:** item bloqueado por comando; recuperar repetição antes de converter e revalidar dentro do bloqueio. Conversão e CRUD específico na mesma transação, com retorno controlado e liberação do módulo técnico.
- **Reversão:** somente retirada efetiva do último parâmetro ativo; preservar outros estabelecimentos. Impedimentos conforme escopo 6.5. Operações EXECUTADAS sem conciliação comprovada permanecem impedimento técnico, não são consideradas encerradas.
- **Limite:** fonte integrado não é compilação nem aceite. Novo SAVE, ET-01F/REST, concorrência, corte/reconciliação e identidade confiável Fluig continuam necessários. Nenhuma mudança física, novo endpoint ou execução produtiva.

## DT-069 — Cópia integral como padrão, 17/09/2026

- **Autorização explícita:** responsável copiará toda a pasta ET-01_TESTE e sobreporá arquivos correspondentes; agente avisa previamente quando uma exceção exigir só arquivos específicos.
- **Entrega:** listas de mudanças não são listas limitadoras da cópia. Manter a pasta aberta completa/sincronizada; ZIP não é referência corrente. Sobreposição não autoriza apagar/espelhar o destino.
- **R-code:** quatro snapshots .r locais foram preservados fora do transporte, em evidencias/r-codes_snapshot_antes_dt069_2026-09-17. Sem .r históricos no pacote, cópia integral não os recoloca no servidor. Compilação SAVE indicada continua obrigatória para atualizar os .r ativos; executar só após zero falhas.
- **Evidências:** usuário devolve os TXT novos antes da próxima cópia. Agente consulta/preserva os resultados antes de atualizar a entrega. Nenhum fonte ABL, servidor, percentual ou contrato funcional alterado nesta decisão.
- **Refina:** DT-067 e orientações de cópia seletiva anteriores; escopo 1.4 e AGENTS atualizados.


## DT-070 — Adiantar consultas sem acesso ao compilador, 17/09/2026

- **Pedido:** responsável liberou desenvolvimento local de outras frentes enquanto o 103 está em uso por outro profissional. Sem acesso remoto, reinício ou execução de banco.
- **Recorte:** transporte REST das duas consultas Bag existentes e autocomplete global de tipos com filtro OR real, em arquivos já aprovados. Escopo 13.5 atualizado antes dos fontes.
- **Rotas técnicas:** GET /bags, GET /conteudo-bag? idBag e GET /apoios/tipos. Conteúdo por path da API completa permanece proposta; este recorte usa query conforme baseline existente, sem inventar parser de path.
- **Qualidade:** parâmetros fornecidos inválidos não viram defaults; teto 20, cursor, dados autorizados e falha sanitizada. Matriz de tela e inventário de autocomplete devem refletir chamadas reais no fonte.
- **Limite:** fonte desenvolvido/revisado, compilação e testes futuros. Manter DT-068 na fila: não misturar aprovação isolada do conversor com esta revisão. Sem promover Planner, liberar produção ou iniciar mutações com contratos abertos.


## DT-071 — Frente visual adiada por orientação do responsável

17/09/2026: responsável explicitou foco em procedures Progress de consulta, autocomplete e ações. Limpeza/seleção de campos e UX pertencem ao Dev Fluig e serão tratadas depois, se houver tempo. Experimento local foi arquivado em docs/entregas/evidencias/frente_fluig_dt071_adiada; fonte/teste/template ativos revertidos à versão anterior. Teste experimental 17/0 não representa código ativo ou avanço do Planner. DT-064 mantém requisitos gerais, sem nova implementação visual neste checkpoint.


## DT-072 — Famílias e dados da ação de impressão no backend

17/09/2026: responsável pediu procedures Progress de consulta/autocomplete/ações, sem tratativas de frontend. Escopo 13.6 precede fontes. Desenvolver consultarFamilias no núcleo e obterDadosImpressao no rastreio, transporte no adaptador único, tests nos arquivos existentes. Campos família comprovados em referencias/fontes-prod-legado/etiquetasCD.p (192/203) e etiquetas.i (409); tipo textual evidenciado no filtro fm-codigo <> vazio (etiquetasCD.p 212). Dados específicos no modelo v1.7 implantado. Exposição respeita seleção por ID textual, lista explícita de estabelecimentos, limite/cursor e falha sanitizada. Impressão precisa de identidade EMBALAGEM e evento origem CONCLUIDO; recorte obtém dados, sem afirmar emissão física ou cobrir impressão de Bag. Mesma identidade em repetição; nenhuma escrita. Nova revisão exige SAVE/ensaios próprios; Planner não elevado por fontes preparados.


## DT-073 — aviso 214 no SAVE das 15:18, 17/09

Relatório informado pelo responsável: 13 fontes/1 falha contabilizada; 12 OK nominais. Única mensagem do testar-salvar-parametro.p é WARNING 214 (TRANSACTION dentro de transação existente). Retirado TRANSACTION redundante do bloco interno aborto; preservados DO ON ERROR UNDO, THROW e UNDO aborto, LEAVE aborto, dentro da transação externa ensaio. Auxiliar agora decide erro real com COMPILER:ERROR e imprime diagnósticos de compilação bem-sucedida como AVISO, sem contá-los como falha. Dois fontes sincronizados com pasta oficial; nova compilação/SAVE necessária antes de ET-01F. Não houve execução/mudança de contrato funcional, REST ou avanço do Planner.

## DT-074 — Massa controlada de consultas e acesso remoto, 17/09/2026

Responsável autorizou criar registros na base de TESTE para cenários positivos, após ET-05A 5/0 com MASSA_BAG_AUSENTE às 15:38. Escopo 13.7 precede implementação. Preparar um único executor de fixtures de consulta em transação com rollback e conferência por ID/código, usando sequências instaladas e tipos sem colisão. Reaproveitar os executores existentes de Bags/etiquetas e complementar paginação de tipos. Fixtures não homologam produtores de geração/vínculo/histórico, documentos fiscais ou mutações operacionais. Não alterar estoque padrão ou cadastros mestres.

Acesso informado: RDP dentro de outro RDP. Sondagem local do endereço documentado 192.168.1.103 não alcançou 445/5985/3389; não equivale a indisponibilidade na rede interna. Ferramenta de controle do computador falhou ao inicializar o kernel (caminho não encontrado), inclusive após reset. Nenhum acesso, compilação ou execução remota efetuado pelo agente. Não afirmar autonomia no 103 até observar sessão de TESTE e ferramenta funcionando.


Complemento DT-074: acesso exato confirmado pelo responsável é RDP externo 200.206.113.85 → RDP interno 192.168.1.103:1074, Administrator autenticado manualmente pelo responsável. Roteiro de infraestrutura atualizado; limitação atual é inicialização da ferramenta de controle local, sem acesso remoto realizado.

## DT-075 — GER-04 e inventário de fechamento, 21/09/2026

- Fechar o backend por lotes completos, com inventário e checkpoint persistentes; fonte sem compilação permanece “implementada, falta testar”.
- `consultarGeracao` recebe evento positivo, cursor e limite; devolve cabeçalho funcional, itens/lotes e somente embalagens geradas. Autoriza pelo estabelecimento do evento e separa nascimento de estado atual.
- Expor `GET /geracoes` com adapter fino. Não devolver hashes, token ou payload técnico e não criar fatos pela consulta.
- Compilar somente rastreio, teste GER-04 e adapter no OpenEdge TESTE. Não tentar compilação local.
- GER-01/02/03, hook RE1001/AED e inverso permanecem nos contratos próprios.

## DT-076 — Núcleo único de eventos e movimentos, 21/09/2026

- `registrarEvento` e `aplicarMovimento` ficam no módulo existente `contr-emb-rastreio.p`, com contratos compartilhados em `contr-emb.i`; não criar um `.p` por procedure.
- Evento novo é apenas registrado como `RECEBIDO`. A procedure não presume documento fiscal, natureza, produtor, pós-commit nem conclusão. A idempotência usa o índice `hash-chave` e compara origem, chave, conteúdo e tipo antes de aceitar repetição.
- Aplicação de movimento serializa pelo evento e pela etiqueta, exige versão e último movimento esperados, recusa `PRE_SALDO`, preserva o encadeamento e atualiza fato/projeção na mesma transação. O nascimento é a única ocorrência sem estado e posição anteriores.
- A procedure comum persiste um comando já validado pelo produtor do fluxo; não inventa efeitos de transferência, devolução, terceiros, Bag ou compensação. Relações opcionais são conferidas quando informadas.
- Não há rota REST nova neste lote. BO fiscal, RE1001, geração e operações permanecem desacoplados até seus contratos próprios.

## DT-077 — Gatilhos finos e padrão Datasul como autoridade documental, 22/09/2026

- **Entrada:** criação/importação, atualização, desatualização e cancelamento pertencem ao ANFE e ao processo padrão Datasul. O Controle de Embalagens não cria API/procedure substituta para RE1001/RE0402 nem duplica o movimento consolidado.
- **Captura:** pontos de extensão identificam fatos confirmados e delegam a serviços customizados reutilizáveis. Os nomes, assinaturas, momento transacional e dados disponíveis em cada extensão precisam ser comprovados na release; ausência dessa prova recebe `PONTO_DATASUL_A_CONFIRMAR`.
- **Compra:** atualização confirmada de compra parametrizada pode gerar identidades; a compensação de desatualização/cancelamento preserva histórico e considera efeitos posteriores.
- **Transferência/retorno:** recebimento não gera nem seleciona novamente etiquetas. Uma rotina comum correlaciona entrada, saída/operação, documentos, itens/lotes e as mesmas identidades enviadas, inclusive em parcialidade e múltiplos documentos.
- **Saída pelo Fluig:** a camada customizada prepara/valida a operação e seleção e chama BO/API padrão para criar o documento. A referência de todos os documentos gerados é persistida; somente o fato padrão posterior de estoque confirma o movimento individual.
- **Reversão:** cancelamento fiscal, desatualização de estoque e pedido de cancelamento são fatos distintos. O núcleo compensa uma vez somente o efeito realmente revertido pelo padrão.
- **Reuso:** UPCs/produtores não implementam persistência própria de evento ou movimento; reutilizam `registrarEvento` e `aplicarMovimento`, aprovadas no ET-02.
- **Medição:** cobertura de backend usa apenas capacidades `CUSTOM_BACKEND`. `DATASUL_STANDARD`, `UPC_HOOK`, `STANDARD_BO_CALL`, `REST_API`, `UI_DATASET`, `LOCAL_UI` e `EXTERNAL` são acompanhadas separadamente. O inventário anterior de 51 capacidades deixa de ser denominador de procedures customizadas.
- **Limite:** esta decisão não escolhe nomes de UPC/EPC, BOs instaladas, naturezas, tabelas ou campos. BODI317, REAPI316A, BOIN090/176/404RE/404TE, FT4011/FT4012 e localizadores documentados permanecem evidências/candidatos até validação no ambiente.

## DT-078 — GER-02/GER-03 internos e transacionais, 22/09/2026

- `validarGeracao` é cálculo sem persistência. A ocorrência é identificada por `sequencia + seq-lote`; repetição dentro da mesma fotografia é recusada, e item sem parametrização ativa é registrado como `IGNORADO`.
- Item participante exige controle por lote, tipo ativo, capacidade positiva com quatro casas, unidade parametrizada igual à unidade de estoque, lote e validade. Enquanto não houver fonte comprovada da conversão instalada, unidade de origem diferente é recusada; não aceitar fator livre do consumidor.
- `gerarEtiquetas` recebe apenas `ttEmbGeracaoValidada`, reutiliza `registrarEvento` e `aplicarMovimento`, cria somente `EMBALAGEM`, persiste a memória em `contr_emb_evento_item` e conclui o evento atomicamente.
- Repetição de evento já concluído compara as ocorrências persistidas e não cria nova identidade ou movimento. Evento existente ainda aberto não é retomado por inferência.
- Nenhuma rota REST, hook RE1001/RE1005, chamada fiscal, `PRE_SALDO` ou movimento no estoque padrão faz parte deste lote. Em 22/09/2026 às 11:51, a revisão corrigida pelo responsável compilou `2/0` e o executor concluiu `25/0`; GER-02/GER-03 estão **IMPLEMENTADAS E VALIDADAS** e não devem ser repetidas sem mudança relevante.

## DT-079 — GER-01 interno e prova controlada do EPC RE1005RP, 22/09/2026

- `processarRecebimento` fica no módulo `contr-emb-rastreio.p`; recebe o `ROWID` somente como transporte interno do EPC, relê `mgmov.docum-est`/`item-doc-est` e nunca persiste o `ROWID` como identidade.
- O recorte inicial classifica somente compra de fornecedor `1101IS` com `ce-atual = sim`. Natureza diferente é `NAO_APLICAVEL`; transferência, terceiros e empréstimo não entram por aproximação.
- Somente linhas com parametrização ativa são montadas para GER-02. GER-01 não atualiza RE1001, não movimenta estoque padrão, não duplica persistência e não possui rota REST.
- A chave inicial usa a identidade fiscal disponível do documento e ciclo 1; a fotografia canônica inclui as linhas participantes. O mesmo conteúdo recupera o resultado; conteúdo divergente conflita. Novo ciclo após desatualização permanece dependente do inverso.
- TDN e fonte legado comprovam `re1005rp`, `fim-atualizacao`; o legado comprova ainda a assinatura e `docum-est rowid`. A sonda executada em TESTE em 22/09 às 16:13 comprovou transação ativa, documento atualizado e dez ocorrências legíveis. Ela não comprova, por si, propagação de erro ou rollback da atualização padrão.
- GER-01 está **IMPLEMENTADA E VALIDADA** em TESTE (`3/0`, `17/0`). Preparar sua chamada na UPC instalada preservando o processamento existente; ativação depende de ensaio controlado da propagação de falha e rollback.

## DT-080 — Compensação inicial da compra desatualizada, 23/09/2026

- **Status:** implementação preparada, validação TESTE pendente.
- No recorte de compra `1101IS`, RE0402 não exclui etiquetas, evento gerador ou movimentos. Para embalagens ainda no nascimento e sem Bag, registrar um evento de desatualização relacionado à origem e um movimento compensatório por etiqueta pelo núcleo ET-02.
- O movimento identifica “Documento desatualizado no RE0402”, série, número e emitente; atualiza atomicamente a projeção individual para `CANCELADA` e quantidade zero. Estoque consolidado permanece sob controle do Datasul.
- Movimentos posteriores, estado alterado ou mais de um ciclo gerador para a nota bloqueiam esta primeira versão. A reatualização futura requer ciclo próprio e não está liberada.
- `Fim-Atualizacao` foi observado no backend com `docum-est-rowid`, mas a UPC de reversão só será ativada após comprovar transação e `ce-atual = no` nesse ponto e após compilar/testar os fontes novos.

## DT-081 — Limpeza dirigida da UPC RE1005RP, 24/09/2026

- **Decisão do responsável:** retirar da candidata de TESTE o bloco legado de etiquetas por referência, etiqueta-mãe/filhas, movimentação via CEAPI001K, atualização direta de `saldo-estoq` e registro no serviço legado de etiquetas. O novo fluxo de compra usa GER-01 e o núcleo de fatos; não executar os dois tratamentos em paralelo.
- **Preservação obrigatória:** manter o bloco que altera o cabeçalho e os itens de `cd_solicitacao`/`cd_solic_item`, projeto já operante em produção, e manter `pi-atualiza-follow-up` e suas dependências, pertencentes à outra consultoria. Não mudar sua regra funcional nesta limpeza.
- **Extensão operacional:** retirar a chamada de sonda de diagnóstico da candidata. Em `fim-atualizacao`, a chamada de GER-01 para `1101IS` só ocorre com documento localizado e `ce-atual=YES`; GER-01 conserva a segunda barreira. A versão com rollback forçado e os fontes de referência legados não são alterados.
- **Status:** fonte de TESTE ainda requer compilação SAVE e validação dirigida antes de substituir a UPC instalada; esta decisão não autoriza implantação automática em produção.

## DT-082 — E04 em FT2100 e FT4003, 24/09/2026

- **Direção do responsável:** cobrir a atualização e a desatualização da saída no estoque tanto no FT2100 quanto no caminho automático do FT4003. Uma NF criada pelo Fluig não participa do primeiro ensaio; usar documentos padrão preparados em TESTE.
- **Contrato interno:** ambos os pontos físicos chamarão o mesmo serviço de reflexão das embalagens, reutilizando ET-02. A repetição entre programas não cria segundo movimento para o mesmo fato padrão. Não escolher uma chave de deduplicação nem uma assinatura de EPC antes de comprová-las no fonte/execução da release instalada.
- **Separação:** cancelamento fiscal da saída será observado e tratado como marco próprio; não presumir que seu evento já reverteu o estoque. Nenhum adaptador ou movimento E04 está implementado por esta decisão.

## DT-083 — Cancelamento de entrada e saída; anulação ainda distinta, 24/09/2026

- **Abrangência confirmada pelo responsável:** cobrir cancelamento tanto dos documentos recebidos quanto das notas de saída. O sinal fiscal, a desatualização do documento e o eventual estorno de estoque não são tratados como um único fato.
- **Referência oficial:** a TDN descreve FT2200 como cancelamento da NF de saída e RE0708 como monitor que pode encaminhar ao RE0402 para desatualização fiscal de entrada. Há casos oficiais de “anulação da operação” por documento simbólico, portanto não classificar toda anulação como cancelamento direto da nota original. Fontes: https://tdn.totvs.com/display/LDT/Cancelamento+de+Nota+Fiscal+-+FT2200 ; https://tdn.totvs.com/pages/releaseview.action?pageId=243640731 ; https://tdn.totvs.com/pages/releaseview.action?pageId=863927127 .
- **Implementação:** manter cancelamento/indicação externa de entrada, cancelamento de saída, desatualização de estoque e anulação por documento relacionado como categorias separadas até comprovar, no fluxo do cliente, programa, evento, vínculo e efeito. Nenhum movimento individual nasce apenas do nome da operação; compensar uma vez o efeito padrão efetivamente revertido. E04 pode avançar sem resolver a nomenclatura de anulação.

## DT-084 — Seleção de embalagens exclusivamente no Fluig para saídas, 24/09/2026

- **Decisão do responsável:** somente documentos de saída criados pelo fluxo Fluig terão embalagens/etiquetas vinculadas. Saídas criadas diretamente no Datasul não receberão seleção automática nem movimento individual do E04. Seleção por específico durante a criação no FT4003 é possibilidade futura, fora do escopo atual.
- **Gatilho comprovado:** a mesma UPC do FT2100RP observará `end-ft2100` nos dois sentidos: `i-tipo-atual=1` para atualização e `2` para desatualização; `l-desfaz=no` e ROWID da `nota-fiscal` foram observados em transação. Em `ft2100rp.p`, `l-desfaz=yes` executa `UNDO bloco, NEXT bloco`. O caminho automático FT4003 passou pelo FT2100RP no ensaio. O EPC não seleciona etiquetas pela quantidade do estoque.
- **Vínculo necessário:** cada execução de criação pelo Fluig produz um documento. O Fluig seleciona identidades antes de criá-lo; o backend deve persistir a seleção da operação, associar o documento retornado e revalidar item/lote/validade/quantidade ao confirmar o estoque. Sem operação e seleção vinculadas, a UPC retorna sem efeito específico. A desatualização compensa somente movimentos anteriormente registrados para aquele documento, preservando o histórico.
- **Persistência da seleção, ainda não implantada:** as linhas agregadas de `contr_emb_oper_item` não comprovam, por si, quais etiquetas e parcelas de quantidade foram selecionadas. O contrato da seleção individual operação/item/etiqueta/quantidade e sua persistência serão fechados no lote próprio, verificando primeiro se as estruturas existentes bastam. Não presumir uma relação entre vários documentos gerados numa única execução do Fluig; a v1.7 implantada ainda não deve ser tratada como se já possuísse esse vínculo individual.
- **Fluxo de manutenção:** selecionar embalagens e natureza; a natureza determina o ramo. Se for devolução, obter documento de origem, emitente e itens/quantidades elegíveis antes da criação padrão. A origem pode aparecer antes na experiência da tela, mas sua elegibilidade precisa ser revalidada após a natureza. A família BODI317SD é candidata documental, não contrato instalado já comprovado.

## DT-085 — E04 por nota no FT2100 e seleção individual candidata, 24/09/2026

- Complemento de 25/09/2026: uma transferência pode selecionar milhares de etiquetas. A v1.8 candidata terá índice não único `etiqueta` em `contr_emb_oper_item` por `id-etiqueta` + `id-operacao`, para a verificação de reserva consultar diretamente a identidade. Isso não elimina a necessidade de bloqueio da operação/etiqueta e recusa de duplicidade; tampouco altera a v1.7 implantada até a migração ser aplicada.

- A criação de saída pelo Fluig produz um documento por comando; uma execução em faixa do FT2100 pode processar vários documentos. O EPC `end-ft2100` fornece o ROWID de cada nota e `i-tipo-atual=1/2`; cada chamada específica atua apenas sobre aquela nota.
- A v1.7 de `contr_emb_oper_item` não guarda `id-etiqueta`. A proposta mínima v1.8 adiciona o campo opcional, obrigatório para linhas `SOLICITACAO` originadas no Fluig: uma linha por embalagem/parcela de quantidade. O evento `DOCUMENTO_SAIDA_FLUIG` associa a operação à identidade da nota antes do efeito padrão; nota sem esse evento permanece fora da movimentação individual.
- A UPC candidata de TESTE e o serviço `processarNotaFt2100` estão preparados para atualização e compensação da **transferência entre estabelecimentos** com seleção persistida, via `registrarEvento`/`aplicarMovimento`. Outros tipos dependem de classificação/natureza e não podem herdar a regra de trânsito da transferência. Uma operação Fluig não suportada é recusada explicitamente; nota direta do Datasul retorna sem efeito específico.
- Nada disso está aprovado em execução: migrar Oracle/schema holder, compilar e validar com uma nota Fluig controlada antes de instalar a UPC. A criação da nota via BO e o instante em que o vínculo documental deve ser gravado para cobrir estoque automático do FT4003 ainda precisam de prova na instalação.

## DT-086 — Seleção ligada ao documento de trabalho da transferência, 24/09/2026

- **Direção funcional informada pelo responsável:** no Fluig, selecionar as identidades das embalagens antes de criar um `wt-docto` no FT4003. A seleção pertence à operação/documento de trabalho; quando atualizado, acompanha a nota fiscal resultante. A desatualização da nota registra movimentos compensatórios e devolve a disponibilidade das embalagens, preservando seleção e histórico para o documento de trabalho. Em um caso observado, a atualização posterior atribuiu outro número de nota; esse comportamento ainda não foi generalizado.
- **Evidência de fonte legado:** `referencias/fontes-legado/pre-faturamento_v2.p` chama `criaWtDocto` e recebe `i-seq-wt-docto`, depois cria itens/lote via BODI317SD. Esse fonte comprova a criação do documento de trabalho no fluxo legado, mas não comprova a chave persistente da passagem para `nota-fiscal` nem o retorno após a desatualização na release instalada.
- **Regra de integração:** o FT2100 pode processar faixa, mas o EPC fornece uma nota por chamada. Cada atualização/desatualização registrada no específico deve ser ligada à nota corrente e à seleção original por uma correlação `wt-docto`/operação/nota demonstrada, sem inferir etiquetas do estoque consolidado nem apagar movimentos anteriores. A UPC candidata E04, que hoje procura apenas `DOCUMENTO_SAIDA_FLUIG` pela nota, **não cobre ainda essa correlação completa e não está liberada para instalação**.
- **Recebimento da transferência:** ANFE conduz XML/entrada ao RE1001. Após confirmação da entrada, localizar a saída correspondente e mover as mesmas identidades ao estabelecimento destinatário; não gerar etiquetas novas. Identificadores e ponto de correlação da nota de entrada permanecem a comprovar no ambiente instalado.
- **Esclarecimento do responsável em 25/09:** a PI de criação chamada pelo Fluig obtém `i-seq-wt-docto` pela BODI317 e termina sem atualizar/calcular a nota via API. A nota e seu número aparecem depois, no processamento FT4003; só nesse segundo momento se deve ligar a identidade fiscal às embalagens já selecionadas para o `wt-docto`. `contr_emb_movto` registra apenas efeitos confirmados por etiqueta e não pode ser a única fonte dessa ligação, pois nenhum movimento existe antes da primeira atualização. Priorizar a seleção em `contr_emb_oper_item` e a correlação documental em `contr_emb_evento`/estrutura específica comprovada; movimentos apontam para o evento e a linha da operação. Ainda falta provar qual ponto do FT4003 expõe conjuntamente o `wt-docto` e a nota para persistir essa passagem antes do efeito FT2100, inclusive no estoque automático. Revisão dirigida posterior encontrou a PI `pi-gerar-faturamento` em `referencias/cd-ressuprimento.p`: ela chama `criaWtDocto`, recebe `i-seq-wt-docto`, calcula/efetiva a nota pela BODI317 e recupera a nota via `buscaTTNotasGeradas`/ROWID. Esse fluxo do CD comprova as chamadas nessa cópia, mas difere deste projeto, que encerra a PI após criar o documento de trabalho; não comprova a relação acessível ao FT2100 depois do FT4003.
- **Correção posterior do ponto de captura:** a sonda já comprovou que tanto o FT2100 executado diretamente quanto o estoque automático disparado pelo FT4003 passam pelo EPC `end-ft2100` por nota. Uma única UPC nesse ponto basta para os movimentos específicos nos dois caminhos. Não exigir outro hook do FT4003 apenas para movimentar etiquetas. A pendência é localizar, a partir da nota corrente desse EPC, o `wt-docto` da operação Fluig e suas etiquetas, por chave padrão comprovada ou relação específica previamente persistida. A exigência anterior de necessariamente capturar os dois identificadores em um hook separado do FT4003 fica superada; somente se o EPC/nota não oferecer correlação segura será preciso buscar outro ponto de associação.
- **Momento do primeiro vínculo, confirmado pelo responsável:** a PI acionada pelo Fluig já conhece a operação e as etiquetas selecionadas e recebe o identificador do `wt-docto` ao chamar a BODI317. Nessa própria PI, após a criação bem-sucedida, deve persistir em estrutura específica a relação **operação/seleção ↔ `wt-docto`**; não esperar o FT2100 para montar essa seleção nem usar `contr_emb_movto` como cadastro dela. O FT2100 só precisa resolver o segundo elo, **nota corrente ↔ `wt-docto` já registrado**, antes de aplicar ou compensar movimentos. O formato da chave e a forma como a nota expõe esse elo continuam sujeitos à prova no Datasul instalado.
- **Correção funcional do responsável em 25/09:** o Fluig tem timeout informado de **200 segundos** na chamada síncrona ao Datasul e uma seleção pode alcançar cerca de 3.000 etiquetas, mas não deve haver reserva/registro específico persistido antes de o `wt-docto` ser criado com sucesso. A tela envia a seleção à PI; o backend valida antes da BODI317 e, só após retorno confirmado de `i-seq-wt-docto`, grava operação, linhas individuais e vínculo documental. Falha efetiva da BO não deixa seleção específica e o usuário seleciona novamente. A transação precisa garantir que falha na gravação específica não deixe um documento padrão sem seleção; isso ainda exige prova na instalação. Medir latência com 3.000 etiquetas em TESTE. Timeout do cliente, por si, não significa que a BO falhou; consultar/reconciliar o resultado antes de nova tentativa. O contorno recursivo legado não é requisito do novo fluxo.
- **Direção adicional do responsável:** não contar com relação padrão persistente entre a nota e o `wt-docto` que a gerou; o identificador pode se perder após a efetivação. O responsável informou `nota-fiscal.char-1` e `char-2` com 2.000 posições, além de `dec-1/2` e `int-1/2`; dispensou a sonda de campos, que foi retirada. A busca nos fontes locais não encontrou acesso a `nota-fiscal.char-2`, mas encontrou `nota-fiscal.int-2` usado pelo FT2100, portanto `int-2` não é candidato. Consulta `FOR EACH mgmov.nota-fiscal NO-LOCK` executada pelo responsável em TESTE em 25/09: **232.060 notas**, `char-2` preenchido em **165.657**, faixa **1500–1519** preenchida em **zero**. Avaliar essa faixa somente como hipótese: gravar um marcador/versionamento com o inteiro `i-seq-wt-docto`, preservando as demais posições e recusando qualquer conteúdo preexistente diferente. A faixa vazia na massa atual não comprova reserva futura nem persistência após processamento padrão. Confirmar ponto de gravação quando FT4003 cria a nota e persistência em atualização/desatualização antes de ativar E04. Se a faixa não for segura ou não persistir, a alternativa aprovada para avaliação é uma relação em tabela específica na migração v1.8, sem ocupar campo padrão arbitrário.
- **Decisão posterior do responsável em 25/09:** utilizar diretamente `nota-fiscal.char-2` nas posições 1500–1519 para o vínculo `seq-wt-docto`, sem criar tabela de correlação agora. Em TESTE foram lidas 232.060 notas: 165.657 com `char-2` preenchido e nenhuma com essa faixa ocupada; `char-1` tinha 213.924 preenchidas e a mesma faixa vazia. O slot usa marcador `CEWT1:`, preserva as demais posições, recusa conflito e aceita repetição idêntica. `gravarWtDoctoNaNota` foi preparado em `contr-emb-operacao.p`, mas ainda não possui chamada instalada nem compilação; o exemplo CD-Ressuprimento comprova que após `efetivaNota` e `buscaTTNotasGeradas` a PI dispõe de `i-seq-wt-docto` e ROWID da nota. O fluxo deste projeto efetiva a nota posteriormente no FT4003, portanto a chamada real ainda precisa ser localizada nessa efetivação, sem antecipar a geração fiscal para a PI Fluig. Confirmar em TESTE a permanência do slot após atualização/desatualização antes de ativar E04.
- **Materialização E04 da mesma decisão:** a migração v1.8 candidata passa a incluir `contr_emb_oper.seq-wt-docto` (índice único) além de `contr_emb_oper_item.id-etiqueta`. No módulo `contr-emb-operacao.p`, `vincularWtDoctoOperacao` grava o WT retornado pela BO, `vincularNotaPorWt` localiza a operação pelo WT e `vincularNotaSaidaFluig` carimba `char-2` e registra a origem documental; `processarNotaFt2100` confere o carimbo com o WT da operação antes de movimentar. Tudo permanece **não compilado/não instalado**: seleção pós-BO, ponto de chamada na efetivação FT4003 e teste integrado são pendentes. O carimbo deve existir antes do FT2100, inclusive quando o estoque é atualizado posteriormente por acesso direto ao programa.
- **Seleção não é movimento:** considerada e descartada a alternativa de inserir movimento de quantidade zero para cada etiqueta escolhida, a fim de evitar o campo `contr_emb_oper_item.id-etiqueta`. No núcleo ET-02 vigente, `aplicarMovimento` aceita zero, porém grava `contr_emb_movto` e altera `contr_emb_etiqueta.id-movto-ult` e `versao`; isso colocaria uma intenção ainda não efetivada na cadeia de fatos confirmados. A seleção individual deve ficar na operação/linha (extensão v1.8 candidata); cada atualização e desatualização confirmada cria movimentos próprios com `id-item-oper`, preservando rastreio da etiqueta até a seleção original. A migração v1.8 ainda não foi aplicada.
- **28/09/2026 — primeiro ensaio da seleção pós-WT:** autorizada a implantação incremental das duas colunas v1.8 **somente em TESTE** para compilar e ensaiar, com rollback, `registrarSelecaoAposWt`. A procedure candidata valida uma ou mais identidades, recusa duplicidade e indisponibilidade, grava operação/linhas e liga o WT já criado; repetição idêntica retorna a mesma operação. O ensaio isolado não equivale à prova de atomicidade da BODI317 com as tabelas específicas, à conferência dos itens do WT, nem à ligação da nota ao WT. Não instalar UPC E04 por esse resultado.
- **28/09/2026 — origem da saída e papel das UPCs, esclarecidos pelo responsável:** transferência, devolução e devolução de empréstimo nascem da seleção explícita das embalagens. A seleção determina os grupos fiscais por item/lote/validade e demais dimensões pertinentes, com confronto ao `saldo-estoq`; grupos compatíveis somam quantidade numa linha do WT, mas cada etiqueta permanece identificada em `contr_emb_oper_item`. A seleção é persistida somente depois da criação confirmada do WT. Na atualização/desatualização, a UPC observa o efeito efetivo do estoque consolidado e registra o reflexo das embalagens já vinculadas, sem selecioná-las novamente nem movimentar o estoque padrão. Este esclarecimento não aprova a chamada fiscal de devolução/empréstimo nem a aplicação da regra de transferência simples às demais naturezas.

## DT-087 — Localização interna vazia na projeção da etiqueta, 28/09/2026

- **Decisão do responsável:** quando não existe localização, gravar `contr_emb_etiqueta.cod-localiz = ""`, acompanhando a representação do `saldo-estoq`; não persistir `?` nesse campo das próximas embalagens criadas ou movimentadas sem localização.
- **Implementação dirigida:** ajustar apenas a atribuição da projeção da etiqueta no nascimento e em `aplicarMovimento`. A representação histórica de `contr_emb_movto.cod-localiz-*` e a semântica dos demais campos opcionais permanecem como estão. O executor E04 mantém equivalência entre `?` e vazio para ler etiquetas já existentes; não corrigir registros antigos automaticamente.
- **Validação:** compilar o núcleo modificado com SAVE em TESTE e verificar a localização de uma embalagem gerada futuramente. Não repetir os lotes GER-02/03 ou ET-02 aprovados integralmente por essa mudança de representação.

## DT-088 — Re-efetivação da transferência após desatualização, 29/09/2026

- **Evidência:** no WT `492960`, a nota `0019557` gerou saída individual `183` e a desatualização padrão FT2100 gerou compensação específica `185`, ambas concluídas, preservando dois movimentos por etiqueta e restaurando 101/103 em `10904/INS` com 10 LT.
- **Risco de repetição:** o serviço E04 ainda trata uma segunda atualização da **mesma identidade fiscal** como repetição da saída anterior. Depois da compensação isso seria incorreto, pois o estoque padrão sairia novamente enquanto as etiquetas permaneceriam na origem. O responsável observou nova numeração em ensaios anteriores, mas não a garantiu para todos os fluxos.
- **Proteção intermediária, superada pela DT-089:** a recusa explícita impedia repetição falsa, mas não atendia a reatualização legítima da mesma nota. Não manter a recusa como regra definitiva.
- **Validação:** compilar `contr-emb-operacao.p` com SAVE e comprovar em TESTE que o caminho de nota nova permanece funcional. Não testar re-efetivação do WT `492960` com r-code anterior a esta proteção.

## DT-089 — Ciclos sucessivos da mesma nota no FT2100, 29/09/2026

- **Evidência:** após desatualizar a nota `0019557`, o WT `492960` não reapareceu no FT4003 e a leitura de `mgcad.wt-docto` retornou `AVAILABLE=NO`. A nota conservou no fluxo já testado a marca `CEWT1:492960`, ligada à operação `6` e às etiquetas 101/103. A ausência do WT operacional não apaga esses vínculos históricos específicos.
- **Regra:** se o padrão aceitar atualizar novamente a **mesma nota** no FT2100, o serviço recupera as etiquetas selecionadas pela cadeia nota→WT gravado→operação. Uma saída concluída e ainda não compensada é repetição; se todas as saídas anteriores foram compensadas, a atualização cria a próxima ocorrência ímpar de `seq-ciclo`, novo evento `SAIDA_ESTOQUE` e novos movimentos individuais. A desatualização seguinte cria o ciclo par e compensa exclusivamente a saída ativa mais recente. Histórico anterior e identidade das etiquetas permanecem.
- **Identidade:** manter as chaves existentes do primeiro par de ciclos (`ATUALIZA`/`DESATUALIZA`) e acrescentar o número do ciclo às ocorrências posteriores; `id-evento-origem` da nova saída aponta ao evento documental e o da reversão à saída que ela compensa. Histórico inconsistente, saída/reversão pendente ou mais de uma saída ativa bloqueiam a operação.
- **Limite e prova:** esta regra não recria WT nem liga automaticamente outra nota ao WT extinto. Exige SAVE da nova revisão e ensaio dirigido da reatualização da nota `0019557`, conferindo confirmação/estoque padrão, ciclos 1–4, quatro movimentos novos no par atualização/desatualização e projeções das etiquetas. Não executar com o r-code anterior de recusa.
- **Evidência posterior em TESTE:** SAVE `4/0`; reatualização padrão inicial retornou `4070`. Consulta específica mostrou o par `187/3`→`189/4` e nova saída `191/5`, todos concluídos, dois movimentos por ocorrência e etiquetas 101/103 ativas em trânsito após o ciclo 5. Os IDs internos ímpares observados não mudam a chave de ciclo nem o código público das etiquetas; a revisão de numeração fica separada para o fechamento geral. Faltam os relatórios padrão das duas últimas passagens e prova de repetição técnica/rollback.

## DT-090 — Primeiro recebimento integral da transferência 5557/1557, 29/09/2026

- **Direção funcional:** a entrada é criada pelo ANFE e atualizada no RE1001; no ensaio inicial de TESTE, sua criação será simulada no padrão RE1001. A customização não cria a entrada nem altera o estoque consolidado.
- **Correlação exigida:** conferir `nro-comp/serie-comp` da linha de entrada contra a nota de saída 5557, o emitente contra o estabelecimento de origem, o destinatário contra o estabelecimento de entrada, e a cadeia nota → marcador WT → operação Fluig → etiquetas. Exigir uma única correspondência; não inferir etiquetas pela quantidade agregada. O preenchimento efetivo desses campos pelo ANFE continua sujeito à prova na entrada controlada.
- **Recorte inicial:** uma linha/lote integral, correspondente a todas as etiquetas selecionadas e ainda no último movimento de uma saída ativa. No `fim-atualizacao` do RE1005RP, apenas após `ce-atual=YES`, criar evento `RECEBIMENTO_TRANSFERENCIA` e movimentos `ENTRADA_TRANSFERENCIA` para as mesmas identidades, de `TRANSITO` para `ESTAB` no destino, mantendo quantidade/situação e o histórico. Repetição idêntica não cria novo movimento; divergência ou origem ambígua é erro. Parcialidade, múltiplos documentos e desatualização dessa entrada serão lotes seguintes, sem interpretação automática a partir deste caso.
- **Estado:** fontes candidatos preparados e ainda sem SAVE, instalação ou execução. Antes de ativar a UPC, uma leitura da entrada ainda não atualizada deve comprovar os campos de origem e a correlação; depois, uma única atualização controlada validará padrão e específico.

## DT-091 — Distribuição física da entrada de transferência, 30/09/2026

- A leitura da entrada manual `10913/1/0019557` confirmou `item-doc-est.serie-comp=1` e `nro-comp=0019557`, uma saída 5557, WT `492960`, operação `6` e etiquetas 101/103 somando 20 LT. A mesma leitura mostrou lote, validade e depósito vazios em `item-doc-est`, enquanto a aba Estoque do RE1001 exibiu `INS`, lote `28092026`, validade `31/12/2050` e 20 LT. O fonte legado comprova a relação `rat-lote OF item-doc-est`.
- Para o primeiro recorte, a customização lê a origem documental e quantidade de `item-doc-est`, e a distribuição física de um único `rat-lote` integral associado ao item. Compara lote/validade do rateio às etiquetas e usa depósito/localização do rateio no movimento de chegada. Mais de um rateio, rateio ausente ou quantidade divergente impedem a movimentação específica. Esta decisão corrige a origem dos dados físicos presumida na candidata DT-090; a relação ainda precisa de SAVE e leitura em TESTE.
- A criação real via ANFE e a atualização/chegada específica seguem pendentes; a prova manual de origem não homologa o ANFE end-to-end.

## DT-092 — Histórico reversível da entrada de transferência, 30/09/2026

- O positivo manual 1557 em TESTE concluiu o evento `193 RECEBIMENTO_TRANSFERENCIA`, dois movimentos de entrada e as etiquetas 101/103 em `10913/INS`. A desatualização dessa entrada pelo RE0402 deve produzir fato novo, nunca apagar ou reutilizar o evento/movimento da chegada.
- A UPC RE0402 existente mantém a reversão da compra `1101IS` e despacha a natureza `1557` ao mesmo serviço de transferência. Somente em `Fim-Atualizacao`, com transação ativa e `docum-est.ce-atual=NO`, o serviço identifica um recebimento específico ativo, verifica ausência de efeitos posteriores nas etiquetas e registra `DESATUALIZACAO_ENTRADA` e um movimento homônimo por identidade. O destino individual volta ao `TRANSITO` no estabelecimento da saída, recuperado do próprio movimento de chegada. A quantidade e a situação não mudam.
- Em atualização posterior confirmada pelo RE1001, um novo `RECEBIMENTO_TRANSFERENCIA` usa ciclo ímpar seguinte e novos movimentos `ENTRADA_TRANSFERENCIA`. A reversão usa o ciclo par intermediário e aponta ao recebimento compensado; a nova entrada preserva a referência ao evento de saída original. Repetição do mesmo estado não duplica fatos; cadeia ambígua, rateio não integral ou movimentação posterior bloqueiam.
- Implementação candidata preparada, sem SAVE ou ensaio integrado dos ciclos nesta data. Consulta somente leitura da vida de uma etiqueta acompanhará nascimento, saída, chegada, reversão e reentrada. ANFE real e cancelamento fiscal continuam pendentes.

## DT-093 — Modal único de saída orientado pela natureza, 30/09/2026

- **Complemento confirmado pelo responsável em 01/10:** as opções do usuário vêm das naturezas amigáveis já cadastradas; a classificação técnica escolhe o ramo padrão, sem tentar deduzir se uma remessa é armazenagem ou empréstimo apenas pelos atributos. No escopo atual, NFD atende devolução de compra/FT4011; retorno de empréstimo atende terceiros/FT4012. A origem permite localizar a operação e movimentação original. Leitura executada em TESTE confirmou as nove naturezas mapeadas e 83 naturezas NFD; o conjunto NFD inclui usos externos ao recorte, logo a permissão da natureza continua na seleção amigável e na BO. Implementar primeiro a classificação somente leitura no módulo de operações, com necessidade de origem e edição de quantidade/preço. Esse resultado não habilita sozinho novos comandos de gravação nem altera UPCs.

- **Decisão funcional corrigida pelo responsável:** a manutenção de etiquetas conserva uma ação comum para preparar o documento, com rótulo final ainda a definir; não usar “Criar saída” como nome da ação. Um único modal adapta seu fluxo após a escolha da natureza de operação; não criar uma interface por tipo/natureza. Atalhos podem pré-filtrar opções, sem substituir a classificação da natureza validada no backend.
- **Naturezas sem chumbamento definitivo:** a consulta e o comando devem derivar o ramo dos atributos e parametrizações atuais da natureza no cadastro Datasul. Os fontes legados mostram `natur-oper.transf` e `natur-oper.terceiros`, mas isso ainda não comprova classificação suficiente para todos os ramos; conferir a definição física e o comportamento instalado antes de fechar o contrato. Se os dados não permitirem classificar uma natureza sem ambiguidade, recusar o ramo ainda não suportado e registrar a lacuna, em vez de inferir pelo código ou descrição. Códigos específicos podem ficar apenas em executores isolados de TESTE, para validar cada cenário; não entram no Widget, Dataset, API ou ABL definitivo.
- **Sequência:** selecionar natureza no início do modal. Saída comum pode aproveitar as etiquetas já selecionadas na manutenção, após revalidação. Natureza de devolução exige selecionar documento de origem e contraparte, carregar itens e embalagens vinculadas ainda elegíveis, apresentar quantidades disponíveis e permitir seleção parcial. O backend revalida natureza, origem, disponibilidade, etiquetas e quantidades no comando de criação; não confiar no estado do Widget.
- **Limites:** devolução de compra e retorno de empréstimo compartilham a experiência visual, mas mantêm consultas, vínculos e chamadas padrão próprios, sujeitos a contrato instalado FT4011/FT4012/BODI317SD. A regra de fracionar conteúdo de uma embalagem ainda não está aprovada. Armazenagem e empréstimo não herdam automaticamente a posição `TRANSITO` da transferência 5557. Nenhuma API, BO, tela ou código foi implementado por esta decisão.
- **Evidência de fonte FT4003/FT4011/FT4012 recebida depois da decisão:** `referencias/ft4003-4011-4012/ft4003.w` consulta `getEnableFieldButtons` da BODI317SD para habilitar `Ger It`; quando esse botão é acionado, `tt-wt-docto.esp-docto = 20` abre `ftp/ft4011.w`, e outro `esp-docto` com botão habilitado abre `ftp/ft4012.w`. `ft4011.w` usa `geraItensDevolucaoTtItensDevol` e `geraWtItDoctoPartindoDoTtItensDevol`; `ft4012.w` usa `buscaNaturOperTpOperTerc`, `geraItensTerceirosTtItTercNf`, `setaHandleBoin404te` e `geraWtItDoctoPartindoDoTtItTercNf`. Isso comprova a delegação da tela ao WT/BO, sem identificar ainda quais campos do cadastro da natureza produzem `esp-docto=20` ou o retorno `l-gera-itens`. Para fechar a classificação, inspecionar `ft4003b.w` e os fontes BODI317 correspondentes da mesma instalação; não inferir pela condição visual isolada.
- **Observação visual FT4012 informada pelo responsável:** a tela de exemplo usou origem `série 1 / documento 0019499 / natureza 1949OE` e item `357867`. O campo de quantidade veio vazio na busca; o responsável digitou `10 LT` manualmente apenas para observar a reação do padrão. Em `ft4012.w`, série, número e natureza de origem são enviados a `geraItensTerceirosTtItTercNf`; o código da natureza do WT é passado separadamente a `buscaNaturOperTpOperTerc`, que devolve se a quantidade pode ser editada. Portanto `1949OE` na captura é a natureza da origem selecionada, não prova da natureza do novo WT nem da regra geral de classificação.
- **Resultado desse exemplo, sem massa válida de devolução:** após a digitação manual de `10 LT`, o FT4012 exibiu erro `57.066 Saldo Insuficiente para a sequência 10` e detalhe de quantidade insuficiente em saldo de terceiros. Não usar este documento aleatório como ensaio positivo nem investigar sua falta de saldo como pendência do projeto. A frase genérica sobre quantidade fracionada não comprova problema de parametrização. Não houve criação/efetivação comprovada da nova nota nem movimento específico de etiquetas nessa tentativa.
- **Evidência complementar de 01/10:** `ft4003b.w` chama `atualizaDadosGeraisNota` e `alteraNaturezaItens` ao salvar o cabeçalho; `bodi317sd.p` confirma as assinaturas dos dois ramos, porém remete a implementação a `bodi317sd.m27`–`.m30` e as temp-tables a `bodi317sd.i1`/`boin404te.i1`, ausentes dos fontes recebidos. A espécie `20` seleciona FT4011 somente depois de atribuída ao WT; ainda não há prova da regra que deriva essa espécie e a habilitação `Ger It` da natureza instalada. O mapeamento dirigido está em `docs/entregas/evidencias/mapeamento_ft4003_bodi317sd_2026-10-01.md`; nenhuma regra nova foi aprovada nem código executável criado por esta leitura.
- **Fonte complementar recebido depois:** os includes mencionados acima foram disponibilizados. `m21` deriva `esp-docto` de `natur-oper.especie-doc`/`transf`; `m3` define quando o ramo brasileiro habilita **Ger It**. `m27` usa BOIN672 para calcular o saldo devolvível da compra e `m29` calcula a disponibilidade de terceiros a partir de `saldo-terc`; `m28`/`m30` geram itens, vínculo de origem e distribuição do WT com as BOs padrão. A natureza específica de retorno de empréstimo ainda precisa ser lida no cadastro de TESTE; não foi aprovada regra nova nem criada a devolução executável. O mapa dirigido registra campos e limites.

## DT-094 — Ações Transferência e Devolução na manutenção de etiquetas, 01/10/2026

- Aprovado pelo responsável após alinhamento com o Dev Fluig: duas ações, Transferência e Devolução. Substitui somente a ação comum da DT-093; preserva natureza dinâmica e execução integral por APIs/BOs.
- Devolução atende compra e empréstimo em um modal, direcionado pela natureza para FT4011/FT4012. Não criar uma ação por tipo sem diferença de interação comprovada.
- Embalagens podem ser selecionadas antes da ação. Após natureza e origem, backend verifica pertinência e elegibilidade, informa incompatibilidades e calcula os totais das selecionadas válidas. Agrupar por item/lote/validade/depósito/localização/unidade sem misturar linhas documentais de origem distintas. Quantidade documental e rateio individual devem ser coerentes.
- Naturezas amigáveis fornecem as opções; classificação backend identifica o ramo e não substitui autorização, validação da origem/quantidades e regras BO. Revalidar antes de gravar.
- A próxima revisão dos mockups deve incorporar esse fluxo. Nenhuma tela ou mockup alterado nesta decisão. Fracionamento do conteúdo e comandos dos novos ramos ainda pendentes.
## DT-095 — Criação de WT de devolução e seleção de origem, 01/10/2026

- Dois cenários dirigidos autorizados: comprar/devolver e comprar/emprestar/receber/devolver o empréstimo, com compras novas criadas pelo responsável no RE1001 de TESTE. Não reutilizar as etiquetas 101/103 hoje no 10913.
- Preparação ABL separada da efetivação: seleção explícita com versão, entrada por chave completa, natureza reclassificada, limites por linha e posição revalidados sob bloqueio; BODI317SD m27/m28 para compra, m29/m30 com BOIN404TE para retorno de terceiros. Sem criação customizada de entradas.
- Os contratos nativos de TT vêm de dibo/bodi317sd.i1 da instalação. Não copiar layouts incompletos nem identificar origem por número isolado. WT gerado deve conservar origem/linha e distribuição selecionada; rateio diferente é recusado com rollback, sem escolha silenciosa de outro lote. Validade desconhecida do rateio gerado pode ser preenchida pela própria BO a partir da seleção já conferida.
- Cabeçalho e SOLICITACAO individuais persistem após sucesso padrão, na mesma transação. Contexto mínimo da origem fica em observacao/justificativa versionadas, com IDs dos eventos/movimentos; não criar BAIXA ou movimento de estoque na preparação. Idempotência da preparação usa chave e hash de conteúdo, serializada pelo documento de origem; repetição não gera outro WT.
- Fracionamento, efeitos confirmados dos novos ramos, recebimento de empréstimo, reversões e publicação REST continuam exigindo seus recortes próprios. Este lote não reclassifica empréstimo como transferência 5557 para contornar as guardas atuais.

## DT-096 — Ciclos de saída da devolução de compra, 02/10/2026

- Responsável determinou seguir o padrão de atualização/desatualização dos demais tipos de saída e consultar saldo-terc durante os ensaios, sem movimentá-lo pela customização.
- Recorte E10: DEVOLUCAO_COMPRA com natureza classificada como NFD, vínculo documental pelo BODI317EF existente e efeito no end-ft2100. Saída mantém quantidade e situação ATIVA, muda posição ESTAB para TRANSITO e registra fornecedor; não zera/encerra automaticamente a etiqueta. Desatualização restaura o snapshot do movimento compensado e reatualização cria novo ciclo. Fato posterior bloqueia reversão automática.
- Preservar identidade, origem documental/operacional e histórico imutável. Sem novo lançamento no estoque padrão, sem mudança de schema e sem implantação em produção. Consulta readonly registra saldo-terc por estabelecimento/emitente/item, discriminando documento/linha quando houver; ausência não é tratada como erro nem reconstruída.
- Embalagens inteiras, sem fracionamento, apenas devolução de compra nesta entrega. Remessa/retorno de empréstimo, cancelamento e recebimento físico pelo fornecedor não estão liberados por esse lote.

## DT-097 — Remessa do empréstimo e observação do saldo-terc, 02/10/2026

- Próximo cenário autorizado é compra/emprestar/receber/devolver. Primeira etapa E11 cobre saída e compensação da remessa classificada pelo cadastro como NFS/NFT de terceiros tipo 3, sem código de natureza fixo.
- Mesmo vínculo BODI317EF/WT/nota e ciclos FT2100; SAIDA_REMESSA_TERCEIROS muda ESTAB para TERCEIRO com contraparte, sem zerar conteúdo/situação. Inverso restaura snapshot, vincula movimento original e exige ausência de fatos posteriores. Reatualização cria ciclo novo.
- Operação de remessa passa a EXECUTADA após saída confirmada e a SOLICITADA após desatualização. Isso descreve execução da ação, não liquidação da dívida/pendência de terceiro (modelo 5.8), e evita reserva de preparação bloquear o retorno depois de recebido.
- Consultar saldo-terc padrão por estabelecimento/emitente/item e documento/linha antes/depois; ausência, quantidade, dec-1 e disponível são evidências, não pressupor criação/baixa nem gravar no padrão. Consulta não cruza fornecedores por prefixo de estabelecimento.
- Ensaio inicial: 10904→11301, 5949IM, etiquetas 151/161 da compra 9999802, 10 LT de cada lote. Emitente vem de estabelec.cod-emitente. Valor unitário 1 é apenas fixture do executor isolado de remessa; não define preço definitivo. Entrada 1949OE e retorno 5949EM vinculados à origem serão implementados/aprovados nas etapas seguintes; não atualizar entrada com os hooks 1557 atuais.
# DT-098 — E12: chegada do empréstimo e saída do retorno — 02/10/2026

Continuação autorizada após E11 confirmado: receber no 11301 a saída 10904/1/0019559 e depois devolver pela entrada rastreada, com as mesmas etiquetas 151/161. Classificação por cadastro, sem códigos fixos no serviço. Entrada NFE/terceiros tipo 3 exige remessa REMESSA_TERCEIROS, saída ativa única, WT/documento/contrapartes exatos e reconciliação integral de todas as linhas/rateios. Recebimento registra RECEBIMENTO_EMPRESTIMO/ENTRADA_EMPRESTIMO, TERCEIRO→ESTAB destino, mantendo conteúdo e identidade; posse passa ao emitente do estabelecimento recebedor. Reversão copia posição, estabelecimento, depósito/localização, posse, quantidade e situação anteriores; fatos posteriores bloqueiam. Ciclos/repetição preservados. Serviço próprio mantém o recorte 5557/1557 inalterado.

Retorno já preparado pela BO FT4012 conserva origem completa e seleção; BODI317EF/FT2100 passam a aceitar RETORNO_TERCEIROS de NFS/NFT, terceiros YES, tipo 2/5. Saída muda ESTAB→TRANSITO com contraparte, movimento SAIDA_RETORNO_TERCEIROS; reversão restaura snapshot e reatualização gera novo ciclo. Chegada do retorno ao credor ainda não liberada. Sem mudança estrutural, REST ou lançamento de saldo padrão. Cenário isolado: 1949OE de entrada, 5949EM de retorno; natureza definitiva vem do cadastro. Primeiro usuário cria entrada sem atualizar; instalar revisão compilada antes de executar.

## DT-099 — origem pelo cabeçalho fiscal na chegada do empréstimo — 04/10/2026

Responsável aprovou alternativa após prova nativa: 11301/9321/1/0019559/1949OE atualizado, estoque e saldo-terc de entrada presentes, mas série-comp/nro-comp vazios em ambas as linhas e ausência de RECEBIMENTO_EMPRESTIMO. Substitui somente a exigência desses campos do E12/DT-098. Ambos vazios usam identidade fiscal do cabeçalho; ambos preenchidos são validados contra ela, parcialmente preenchidos/divergentes recusados. Emitente identifica emissores candidatos; nota única com destinatário correto, vínculo WT/operação/destino, saída ativa e composição integral confirma a relação. Ausência/ambiguidade nunca gera etiquetas nem escolhe por quantidade. Não alterar documentos/saldo padrão; dívida de terceiros permanece no 10904 até retorno.

Executor dirigido de conciliação para TESTE recebe chave completa da entrada, exige ce-atual YES, trava cabeçalho sem espera e chama o mesmo serviço em transação. Novo evento/movimentos/projeções atômicos ou rollback integral; repetição devolve evento existente. Corrige lacuna específica após fato nativo já confirmado; não recria documento nem atualiza estoque outra vez. Revisão do serviço e executor ainda dependem de SAVE zero falhas e resultado nativo.

## DT-100 — vínculo persistente e continuidade dos recebimentos — 04/10/2026

Implementação autorizada e preparada em ABL nesta continuação: resolvedor comum incluído nos serviços E05/E12, evento documental persistente, conferência global de chegadas ativas e cadeia de compensação por movimento, bloqueio da operação e associação explícita atômica para origem conhecida. Mantidas assinaturas dos hooks, estoque padrão e recortes integrais. Sem novo schema, REST ou BO não comprovada. Compilador dirigido 6 fontes e completo 14; nenhum SAVE ou ensaio novo realizado localmente. Roteiro `docs/entregas/E12_VINCULO_RECEBIMENTOS_DT100.md`. A revisão inicial abaixo é histórica e pode estar desatualizada quanto à implementação.

**Complemento autorizado em 04/10:** responsável solicitou implementar a busca segura e impedir nova perda do vínculo. Implementar resolvedor e registro comum aos recebimentos, com consulta por campos padrão comprovados e guardas dos movimentos. Não chamar métodos BO sem assinatura instalada nem presumir presença de rat-docum/nota-fisc-adc. A busca automática atual usa referências dos itens, chave NF-e e identidade fiscal; entrada substituta sem referência exige associação explícita, não seleção por proximidade. SAVE e comprovação em TESTE obrigatórios antes de declarar o recorte validado.

Revisão solicitada pelo responsável, sem autorização inferida para declarar a proposta implementada. Recomenda associação documental em `contr_emb_evento` e validação do antecedente físico pelos movimentos, separando documento de saída, ciclo ativo e identidade da entrada. Origem conhecida pelo padrão/ANFe tem preferência sobre inferência; referências contraditórias bloqueiam. Último movimento permite conferir saída pendente ou reversão da chegada, não escolher documento apenas por data ou quantidade.

Identificadas limitações da DT-099/E12 para entrada substituta: igualdade obrigatória entre origem e cabeçalho, retorno não aplicável quando outra numeração não traz referência, histórico restrito à mesma entrada e primeiro ciclo exigindo saída como predecessor. Solução detalhada e evidência em `docs/entregas/REVISAO_VINCULO_RECEBIMENTOS_20261004.md`. Utiliza campos existentes; não foi alterado modelo físico, fonte ABL ou contrato REST. Não comprova novo cenário, BO instalada ou cancelamento fiscal. Próximo: implementar o resolvedor/vínculo e guardas globais, com um ensaio dirigido de substituição após reversão, preservando compras e ciclos aprovados.


## DT-101 — compatibilidade da tabela nativa do retorno FT4012 — 04/10/2026

Execução de 04/10 às 19:09:20 confirmou ABL 5363: tt-it-terc-nf do chamador incompatível com a da BO instalada. Não é erro de saldo nem perda do vínculo das etiquetas. A comparação dos includes locais comprova apenas que a cópia mantida qualifica bancos em relação à referência recebida; não identifica qual campo diverge no r-code instalado. Não adicionar/remover campos por hipótese.

Implementar recepção da estrutura real via OUTPUT TABLE-HANDLE com HANDLE inicialmente ?, editar somente selecionado/qt-disponivel-inf nas linhas validadas e enviar a mesma tabela por INPUT TABLE-HANDLE à BODI317SD. O mecanismo ABL é documentado em https://documentation.progress.com/output/ua/OpenEdge_latest/dvref/parameter-passing-syntax.html e https://docs.progress.com/bundle/abl-reference/page/DEFINE-PARAMETER-statement.html; tabela/definição são retornadas e objeto criado deve ser destruído. Aplicar validação de campos/tipos usados e chave completa da origem; rejeitar ausência/incompatibilidade, linhas ambíguas ou quantidade insuficiente. Conservar demais campos e índices desconhecidos, sem inferir seu significado.

Mantidos contratos de negócio e métodos FT4012/BOIN404TE comprovados nos fontes nativos; FT4011, schema, hooks e REST intactos. Falha/mensagens anteriores preservadas; revisão exige SAVE dirigido 2/0 e somente a criação do retorno ainda pendente. SAVE não equivale a aceite funcional; não repetir recebimento/remessa/compra.

### DT-103 — armazenagem e retorno emitido pelo terceiro (05/10/2026)
Definicao autorizada pelo responsavel: fazenda envia remessa para armazenador (emitente), sem exigir estabelecimento desse terceiro em nossa estrutura. O terceiro emite retorno; ANFe cria a entrada na fazenda referenciando a remessa original. RE1001 manual simula somente essa criacao no ensaio. Nao gerar WT, operacao de saida ou recebimento interno do armazenador.
Saida NFS/NFT, terceiros, tipo3 preserva etiquetas em TERCEIRO/estabelecimento remetente, posse emitente armazenador. Entrada NFE, terceiros, tipo5: priorizar retorno interno rastreado existente; sem tal origem, resolver referencia completa serie-comp/nro-comp para remessa REMESSA_TERCEIROS da propria fazenda ao mesmo emitente. Sem deducao por numero do retorno, quantidade ou ultimo movimento isolado. Vínculo documental persistido aponta remessa original; chegada aponta sua SAIDA_ESTOQUE ativa e movimentos daquelas etiquetas.
Retorno integral do conjunto selecionado: identidade, lote, validade, unidade e quantidade conferidos com rateios; custodia TERCEIRO e continuidade comprovadas, sem chegada ativa em outro documento. Nova chegada RECEBIMENTO_RETORNO_TERCEIROS/ENTRADA_RETORNO_TERCEIROS. Compensacao restaura snapshot em TERCEIRO, reatualizacao conserva ciclos. Estado posterior bloqueia. Parcialidade permanece pendente. Datasul controla estoque e terceiros; especifico nao grava saldos nativos.
Destino de REMESSA_TERCEIROS pode ser vazio para armazenador externo, com cod-emitente valido e cadastrado; transferencia continua exigindo estabelecimento. Se destino informado, conferir emitente do estabelecimento. Nenhum campo/tabela/indice novo; hooks existentes preservados. Atributos cadastrais e contexto documental direcionam o ramo, sem natureza chumbada definitiva. Naturezas5934/1907CI apenas fixtures ja comprovados. Desenvolvimento/compilacao/ensaios E14 pendentes; nao equivale a aceite.

## DT-104 — SAVE completo nas entregas de TESTE, 05/10/2026
Responsavel determinou recompilar todos os fontes do pacote, evitando dependencias runtime .r ausentes. Transporte continua sem .r historicos conformeDT067/069; nao apagar nem espelhar destino. Toda nova copia do pacote deve acompanhar comando testes/compilar-todos-save.p, que descobre recursivamente todos os .p/.w presentes e gera SAVE no caminho de cada fonte, registrando falhas por unidade. Includes.i participam da compilacao dos consumidores. Exigir FALHAS0 antes de executar a revisao. Compiladores dirigidos nao substituem esse lote completo quando o pacote for sobreposto. SAVE nativo ainda pendente deste compilador; nao declarar compilacao realizada localmente. Nenhuma mudanca de regra funcional, schema ou estoque.

## DT-105 — preservar r-code vigente no pacote, 05/10/2026
Determinacao explicita do responsavel apos SAVE completo95fontes/0falhas: ele copiara os .r compilados no Datasul TESTE de volta para a pasta ET-01_TESTE do projeto. A partir deste marco, preservar esses .r no pacote e transportar os binarios vigentes junto dos fontes. Nao excluir .r em limpeza/sincronizacao/geracao da entrega. Substituir apenas os .r recompilados de fontes novos ou alterados, mantendo os demais. Esta determinacao substitui a exclusao de .r do transporte em DT067/069 e a exigencia de recompilar todos a cada copia em DT104; o compilador completo continua disponivel para verificacao geral, quando necessaria. Para alteracao de .p/.w ou include consumidor, indicar exatamente as unidades que precisam de SAVE e exigir zero falhas antes de executar a revisao. Ate recuperar os .r novos do servidor, tratar o binario anterior como desatualizado para o fonte modificado e avisar explicitamente; nao assumir que gravar o fonte atualiza r-code. Registrar hashes de fonte/include e .r nas entregas quando disponiveis, sem usar horarios como prova de equivalencia. Nao apagar nem espelhar destino. Compilacao nativa permanece responsabilidade da sessao Datasul TESTE; o agente nao gera .r localmente. Recebimento dos binarios pelo projeto ainda depende da copia que o responsavel informou que realizara.

### Complemento DT-105 — autorizacao da sobreposicao local
Antes de o responsavel trazer a versao testada do servidor e sobrepor a pasta do projeto, o agente deve sinalizar explicitamente se pode sobrescrever, quais arquivos podem ser incorporados e quais alteracoes locais precisam ser preservadas. Comparar hashes dos arquivos disponiveis; nao presumir equivalencia por horario ou apenas pelo SAVE. Se a versao do servidor ainda nao estiver disponivel para comparacao, nao declarar equivalencia integral. Para o SAVE95/0 informado neste marco, orientar copia somente dos .r mantendo caminhos relativos, pois documentos locais foram atualizados depois da copia ao servidor. A copia integral depende de conferir e preservar documentos/fontes locais mais novos. Preservar evidencias antes de sobreposicao. Essa verificacao nao exige recompilacao de arquivos inalterados.

## DT-106 — encerramento automatico da operacao por cancelamento confirmado, 05/10/2026
Aprovado pelo responsavel: cancelamento deve encerrar automaticamente a operacao vinculada no fluxo padrao, sem intervencao manual recorrente. Hook AFTERINVOICECANCELLATION de BODI135CANCEL chama servico documental interno na mesma transacao; erro impede confirmacao especifica e rollback padrao desfaz encerramento. Validar nota cancelada e estoque desconfirmado, identidade completa, carimboWT e documento especifico concluido; toda saida especifica dessa nota deve possuir uma unica compensacao concluida. Nao compensar novamente, alterar etiquetas ou lancar estoque. Sob lock da operacao, conferir todos os DOCUMENTO_SAIDA_FLUIG associados: encerrar CANCELADA somente quando todas as notas estiverem canceladas e reconciliadas; se outra nota ainda nao estiver cancelada, manter situacao da operacao e devolver pendencia documental com sucesso. Repeticao em CANCELADA nao incrementa versao nem modifica fatos; primeira conclusao incrementa versao/autor/data. Ausencia de vinculo especifico significa nao aplicavel com sucesso; divergencia, ambiguidade ou efeito ainda ativo bloqueiam fechamento. Servico nao cria evento de estoque nem altera eventos historicos. Conciliação excepcional da operacao23 usa o mesmo servico sobre a nota ja cancelada, com repeticao e rollback de ensaio antes da persistencia. Hooks nao sao pos-commit. Sem schema/endpoint novo; estado CANCELADA ja existe no modelo implantado. Preparado nao equivale a SAVE/aceite; exige compilacao dos fontes alterados/novos e recuperacao dos .r atualizados para pacote (DT105).

## DT-107 — vinculo BODI317EF dentro da UPC instalada, 05/10/2026
Por determinacao do responsavel, incorporar o adaptador de vinculo como procedure interna piVincularEmbalagensPorWt em testes/e04/ebodi317ef.p. Remover RUN externo para UPC-BODI317EF-VINCULO-TESTE.r. Preservar parametros EPC, evento EndEffectiveNote, contrato e validacoes do vinculo, transacao e rotinas legadas da UPC. Sem operacao de embalagens para WT, retornar OK antes de carregar nucleos; ressuprimento segue fluxo existente. Nucleos contr-emb-rastreio.r e contr-emb-operacao.r permanecem dependencias apenas para operacao especifica. Arquivo do adaptador antigo preservado para historico/testes, nao e dependencia runtime de ebodi317ef. Sem novo schema ou regra de estoque. SAVE de ebodi317ef e instalacao no destino EMS2/Upc exigidos; .r anterior preservado ate substituicao pelo recompilado. Nao assumir resolucao do acesso aos outros nucleos ou homologacao SOAP antes de novo teste.

## DT-108 — restaurar adaptador separado e chamadas logicas no SOAP, 05/10/2026
Responsavel determinou retornar ao adaptador separado apos erro293 tambem no caminho absoluto do nucleo rastreio. Exemplo real da integracao SOAP: PROGRAM=_bp/api/cd-ressuprimento.p. Usar caminhos logicos a partir desse mesmo PROPATH: _bp/EMS2/Upc/UPC-BODI317EF-VINCULO-TESTE.r e _bp/api/ET-01_TESTE/fontes/progress/contr-emb-{rastreio,operacao}.r. DT107 incorporacao interna fica superada. Contratos/transacao/validacoes e rotinas legadas preservados; resolver log a partir do caminho do nucleo encontrado por SEARCH, sem drive absoluto. Nao alterar PROPATH da sessao por inferencia. Resolucao depende dessas pastas presentes sob raiz configurada no SOAP; SAVE e teste nativo pendentes. Nao suprimir falha de dependencia de operacao especifica. Preservar .r existentes e substituir somente compilados novos.

### Complemento DT108 — dependencia remanescente FT2100
Revisao da cadeia apontou outra UPC instalada com RUN absoluto para rastreio/operacao: UPC-FT2100RP-EMBALAGENS-TESTE. Esse hook carrega nucleos antes da determinacao de aplicabilidade por processarNotaFt2100, podendo atingir notas de outros projetos mesmo quando o adaptador BODI317EF retorna sem operacao especifica. Trocar tambem essas chamadas para _bp/api/ET-01_TESTE/... e derivar caminho do log por SEARCH. Preservar ordem/contrato/processamento/compensacao, sem bypass por carimbo ou supressao de erros. Fonte e pacote alterados; binario anterior preservado e exige SAVE/instalacao. Origem concreta da falha SOAP ainda depende de execucao/log novo; nao afirmar comprovacao por leitura estatica. Demais produtores RE1005/RE0402 continuam com chamadas fisicas, revisao futura fora deste recorte imediato.

## DT-109 — resolucao compartilhada de caminhos e sonda local, 05/10/2026
Responsavel confirmou sucesso SOAP apos correcao do FT2100/DT108 e autorizou revisar dependencias restantes, preservando testes no Procedure Editor sem exigir telas Fluig. Include contr-emb-caminhos.i resolve primeiro _bp/api/ET-01_TESTE/<relativo> (raiz ERP no PROPATH) e depois <relativo> (raiz pacote no PROPATH); nao altera PROPATH nem usa drive/host fixo. Resolucao de diagnosticos deriva da localizacao desse include, sem mudar nomes/contratos. Aplicar aos seis hooks mantidos e aos diagnosticos dos servicos de entrada; APIs ja usam SEARCH/caminhos logicos de sua publicacao, nao mudar contrato REST. Compiladores/testes administrativos com caminhos fisicos nao sao chamadas runtime SOAP e permanecem ferramentas dirigidas ao TESTE.
Sonda isolada verifica resolucao e carga persistente de sete modulos, chama seis adaptadores do pacote com evento sem efeito/tt-epc vazia, confirma PROPATH inalterado, encerra handles e nao cria/atualiza/cancela documentos. Complementa, nao substitui, teste funcional de estoque/vinculo/repeticao. Compilador dirigido cobre14 fontes/dependencias e exige zero falhas antes da sonda. Nenhuma nova tabela/regra de estoque. Preservar .r existentes, sobrescrever apenas compilados novos; homologacao local desta revisao e propagacao de falhas ainda pendentes.

### Complemento DT109 — diagnosticos em UNC sem acesso de escrita
Erro nativo98/Errno13 comprovou que o caminho resolvido da sessao local usa compartilhamento UNC sem escrita. Para evitar que diagnostico bloqueie fluxo local, ceArquivoPacote usa SESSION:TEMP-DIRECTORY quando a raiz resolvida comeca por //; nomes dos TXT preservados. Em raiz local gravacao continua no pacote. Sonda sempre grava em TEMP. Nao alterar permissoes, PROPATH, chamadas de negocio, estoque ou banco. Isto muda o include e exige SAVE dos oito consumidores, cobertos pelo lote E16 de14 fontes. Supera orientacao provisoria de recompilar somente a sonda. Logs em TEMP devem ser recolhidos pelo responsavel para evidencias; sonda informa pasta. Teste nativo ainda pendente.

### E16 — diretorio temporario do Windows
Responsavel informa repeticao de erro ao abrir/criar relatorio. OUTPUT TO cria arquivo ausente; existencia previa nao e requisito. SESSION:TEMP-DIRECTORY pode compartilhar a inicializacao sem escrita, portanto resolver diagnostico temporario por OS-GETENV(TEMP), depois TMP, por fim SESSION:TEMP-DIRECTORY. Normalizar separador final. Sonda informa versao/diretorio antes de abrir relatorio para distinguir caminho e fonte executado; compilador registra resultado no TEMP Windows tambem. Sem modificar permissoes/PROPATH ou dados. Novo SAVE E16/14 necessario para include consumidores. Caminho real do erro repetido ainda nao recebido; nao atribuir cache/servidor como causa comprovada.
