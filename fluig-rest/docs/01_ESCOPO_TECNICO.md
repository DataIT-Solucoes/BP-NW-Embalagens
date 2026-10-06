# Escopo técnico vivo — Controle e Rastreabilidade de Embalagens

**Cliente:** Branco Peres  
**Responsável técnico Data IT:** Wallison Cheli  
**Produto principal:** TOTVS Datasul integrado ao Fluig  
**Situação do documento:** fonte técnica viva do projeto  
**Última consolidação:** 12/09/2026

## 1. Finalidade deste arquivo

Este documento concentra as definições técnicas confirmadas do projeto. A entrada de cada sessão segue `AGENTS.md` e `docs/contextos/GERAL.md`; antes de analisar ou alterar um assunto, ler integralmente as seções deste escopo e as dependências indicadas no guia correspondente. Revisões gerais de arquitetura ou escopo exigem leitura integral deste documento.

Não substitui a proposta comercial. A proposta define o compromisso macro; este arquivo registra como a solução será tecnicamente construída e quais decisões já estão válidas.

### 1.1 Contexto por assunto — DT-035

Manter um contexto geral curto e sete guias em `docs/contextos`, para localizar as definições de parametrização/dados, Bags, recebimento, saídas, estoque, integrações e infraestrutura de TESTE. Os guias indicam documentos, seções, decisões e dependências; não duplicam contratos, dicionários ou listas de pendências. Os documentos atuais continuam como fontes das definições e o histórico permanece preservado.

`Atualizar-Contexto-Projeto.bat` gera `_CONTEXTO_SESSAO.md` com o contexto geral e separa a relação de arquivos em `_INVENTARIO_FONTES.md`. Não concatena os documentos técnicos nem altera automaticamente suas regras. Após cada definição, atualizar a fonte correspondente e, somente se necessário, o resumo geral ou o guia afetado; então executar o `.bat`. Ler outros assuntos quando houver dependência, impacto transversal ou dúvida. A divisão documental não altera regras de negócio, modelo de dados ou critérios de validação.

### 1.2 Acompanhamento e fechamento por etapa — DT-036

`docs/08_ACOMPANHAMENTO_ETAPAS.md` concentra a situação das etapas, consistência entre documentos, dependências, próximo passo e liberação para desenvolvimento. É um acompanhamento das definições e evidências existentes, não outro escopo nem uma cópia das pendências. IDs `ET-xx` identificam entregas de acompanhamento, sem alterar códigos de eventos, tabelas ou procedures.

Uma etapa somente fica pronta para desenvolvimento quando seu recorte funcional, dados, contratos, dependências e cenários de aceite estiverem fechados, sem divergência impeditiva. Homologação e implantação são verificações posteriores e distintas. Definições de outras etapas podem avançar sem liberar código incompleto; pendências sem impacto no recorte não devem bloquear a entrega. O cadastro de tipos e parâmetros pode fechar antes das regras de lacre ou dos contratos fiscais; operações de conteúdo de Bag dependem do núcleo comum de eventos/saldo/movimentos.

Atualizar o acompanhamento ao fechar uma definição, descobrir um impedimento, iniciar/concluir desenvolvimento ou obter evidência de homologação/implantação. Regras detalhadas continuam nas fontes originais, pendências no documento `03` e histórico no `02`/`04`. Percentual e prazo só serão informados com critério e base de esforço atualizados; a macro de 240 horas não representa trabalho medido nem data de entrega confirmada.

### 1.3 Checkpoint verificável — DT-056

Ao concluir uma alteração ou bloco de análise, atualizar primeiro o documento de origem e depois os controles derivados aplicáveis: decisões, pendências, changelog, matriz de APIs, matriz de procedures e acompanhamento. Uma funcionalidade REST nova deve aparecer em `docs/entregas/MATRIZ_APIS_REST.md` no mesmo checkpoint; mudança de implementação ou prontidão deve aparecer também na matriz de procedures e no cronograma por etapas.

`Validar-Checkpoint-Projeto.bat` confere automaticamente presença dos mapas, modelo JSON, lista de compilação, sincronismo do pacote ET-01, evidência de compilação e cobertura das ações REST na matriz. O resultado não promove estados sozinho: compilação, publicação, teste e homologação continuam exigindo evidência do ambiente correspondente. Após ajustar o contexto geral ou um guia, executar `Atualizar-Contexto-Projeto.bat` para regenerar os arquivos de retomada.

### 1.4 Pasta oficial de entrega — DT-067/069

A entrega corrente para o servidor de TESTE é a pasta aberta `docs/entregas/pacotes/ET-01_TESTE`. Editar os fontes na árvore do projeto e sincronizar nela os arquivos alterados no mesmo checkpoint, preservando caminhos relativos, antes de anunciar atualização.

**Padrão definido pelo responsável em 17/09: copiar a pasta ET-01_TESTE completa e sobrepor os arquivos correspondentes no destino.** A lista de arquivos alterados é um registro de mudanças, não restrição de cópia. Somente orientar cópia seletiva quando houver necessidade concreta de preservar os demais arquivos, avisando explicitamente antes da cópia. Sobrepor/mesclar não significa apagar o destino nem usar espelhamento com exclusão (`/MIR`).

A pasta de transporte não mantém `.r` históricos; snapshots ficam fora dela como evidência. A cópia integral de fontes não atualiza r-code já existente no servidor: executar a compilação indicada e exigir zero falhas antes de rodar o teste/revisão novos. Recompilar também o auxiliar quando ele tiver sido alterado. Não publicar/reiniciar ambiente por efeito implícito da cópia.

Não gerar ZIP automaticamente; responsável compacta quando desejar. ZIP existente é histórico. Conferir conteúdo/hash, sem inferir versão por horários. Preservar resultados: copiar os TXT recém-gerados de volta ao projeto antes da próxima sobreposição, como já definido para checkpoints. Não copiar a raiz inteira do projeto no lugar da pasta de entrega.

## 2. Marco de arquitetura

O acompanhamento de execução não deve ser inferido da existência deste desenho. Consulte a seção 1.2 e `docs/08_ACOMPANHAMENTO_ETAPAS.md` para a prontidão de cada entrega.

O Controle de Embalagens é o primeiro projeto da Data IT definido para operar integralmente por APIs REST na integração entre Fluig e Datasul.

A consulta de Centros de Distribuição validou o encadeamento:

`Widget Fluig -> Dataset Fluig -> Serviço autorizado -> API Datasul/ut-api -> Progress ABL -> PASOE`

O padrão técnico detalhado está em `00_BASELINE_REST_FLUIG_DATASUL_v1.0.docx`.

## 3. Objetivo da evolução

- Adequar o projeto ao recebimento fiscal centralizado pelo ANFE.
- Usar a atualização do documento no RE1001 como evento oficial para geração das etiquetas.
- Manter o saldo consolidado dos itens sob controle padrão do Datasul.
- Retirar da `saldo-estoq` a responsabilidade de representar individualmente cada embalagem.
- Manter identificação, saldo individual, situação, localização e histórico em estrutura específica de rastreabilidade.
- Reduzir movimentações auxiliares criadas apenas para representar embalagens individualmente.
- Preservar e adaptar as funcionalidades válidas do projeto existente.

### 3.1 Situação do projeto e versões existentes

O ambiente informado pelo responsável utiliza **TOTVS Datasul 12.1.2511.15**, banco **Oracle** e runtime **OpenEdge 12.2**, este último também confirmado nas evidências de compilação de TESTE. O Fluig informado é **TOTVS Fluig Plataforma Silver Mist 1.8.1-230530, build 137**. A estação usada no acesso informado executa Windows 11 e Chrome 151.0.0.0; `WebSpeed` aparece como `N/A`. As versões orientam a conferência das APIs, BOs, includes, Datasets, bibliotecas de Widget e pontos de extensão, mas não comprovam por si só que cada contrato candidato esteja instalado ou possua a assinatura esperada.

A interface informa que a versão do Fluig está desatualizada. Atualização de versão não integra o escopo deste projeto e não será executada. Widget, Dataset, serviço e autenticação devem ser implementados e homologados na versão atual; qualquer limitação comprovada deve ser registrada antes de adotar recurso incompatível.

Conforme informado pelo responsável técnico, apenas uma pequena parte do projeto está em produção. Os seis arquivos disponibilizados em `referencias/fontes-prod-legado` representam o conjunto informado como legado de produção; o uso de `pre-faturamento_v2.p` nesse ambiente não está confirmado. O conjunto em `referencias/fontes-legado` representa a evolução que estava prestes a ser publicada, mas cuja implantação não se concretizou devido à centralização do recebimento pelo ANFE.

Esses conjuntos foram fornecidos para contextualizar a trajetória do projeto: versão inicial em produção, evolução não implantada e reformulação atual. Não constituem uma solicitação de auditoria exaustiva, correção ou publicação do legado. O foco permanece na nova estrutura e nas necessidades atuais.

A entrada do ANFE motivou uma reformulação ampla, com nova estrutura e revisão das necessidades acumuladas durante o projeto. A origem do projeto foi estimada pelo responsável técnico em 2023, ainda sem confirmação documental.

O contexto distingue a versão informada como produção, a evolução não implantada e o novo modelo. Detalhes dos fontes serão consultados conforme necessários a cada etapa. As funções e os dados em uso deverão ser considerados no planejamento da transição; nenhuma desativação ou alteração em produção está autorizada por essa contextualização.


### 3.2 Contexto legado — referência agrupadora do faturamento

Conforme relato do responsável em 16/09/2026, as referências dos exemplos F000050 e F000032 pertencem à etiqueta agrupadora usada no documento físico de faturamento do legado. Seu saldo é temporário no fluxo de transferência: ao criar o documento de saída, a referência agrupadora recebe o saldo consolidado do item/lote/validade envolvido; na atualização do documento de saída esse saldo é zerado. No recebimento em outra fazenda, o saldo da referência agrupadora também é zerado no tratamento da entrada e desmembrado nas etiquetas que mantinham vínculo com ela.

Depois desse tratamento, saldo zero nessas referências é esperado no legado; durante o fluxo elas podem possuir saldo. O relato contextualiza os exemplos da massa, sem comprovar o estado de todas as linhas ou as condições técnicas de atribuição de log-reg-zero. Não equiparar a referência agrupadora a uma embalagem individual do novo modelo, nem excluir cadastro mestre ou registros somente pelo saldo atual zero. A nova solução mantém as identidades individuais em contr_emb_* e não reintroduz cod-refer. Nenhuma execução/manutenção do legado ou de produção é autorizada por esse registro.

## 4. Limites conceituais confirmados

### 4.1 Estoque consolidado

O Datasul continua responsável pelo saldo consolidado do item. O projeto deve acompanhar os movimentos reais do ERP e não criar movimentos fictícios para mascarar procedimentos operacionais.

### 4.2 Rastreabilidade individual

A nova estrutura controla cada embalagem e seu ciclo de vida. Ela não substitui o saldo padrão do item e deve permanecer conciliável com os movimentos efetivos do Datasul.

### 4.3 Controle por lote

O novo modelo utiliza item, estabelecimento, lote e validade. Não haverá controle por referência.

Na migração de um item legado de Referência (`tipo-con-est = 4`) para Lote
(`3`), são removidos somente os vínculos `cod-refer` dos registros desse
item. O cadastro mestre da referência não é excluído nem alterado, pois pode
continuar atendendo outros itens legados.

Os componentes abaixo pertencem somente ao legado e não devem ser usados como fundamento do novo modelo:

- `cod-refer`;
- `ref-item`;
- tabela `referencia` como chave do controle;
- `tipo-con-est = 4` como critério de participação.

### 4.4 Participação no projeto

A participação de um item no Controle de Embalagens será definida exclusivamente por parametrização própria do projeto.

### 4.5 Revitalização e independência do legado

A estrutura específica será redesenhada conforme as necessidades e regras aprovadas do projeto, utilizando o padrão `contr_emb_`. Os fontes e tabelas legados servem ao levantamento dos processos e à identificação de dados que possam ser aproveitados; não determinam os campos, tipos, formatos, índices ou relacionamentos das novas tabelas.

Não existe obrigação de copiar tabelas nem de preservar códigos legados. O aproveitamento de dados, quando necessário, terá mapeamento e validação próprios, definidos após o modelo de destino. A criação do novo dicionário não depende da reprodução do dicionário legado.

Essa independência mantém o estoque consolidado padrão do Datasul e exige conferir os campos e contratos do ERP e das integrações com os quais a nova solução efetivamente se relacionar. Funcionalidades válidas serão adaptadas à nova estrutura. A orientação não autoriza excluir dados legados ou alterar ambientes sem definição da transição.

## 5. Fluxo operacional definido

1. O fornecedor emite o documento fiscal.
2. O ANFE captura e valida o XML.
3. O monitor operacional permite o acompanhamento e o reconhecimento pela Fazenda.
4. O documento é importado para o Datasul.
5. O documento é atualizado no RE1001.
6. A customização identifica o evento de atualização.
7. Os itens parametrizados são identificados.
8. A quantidade de embalagens é calculada conforme a capacidade parametrizada.
9. Nos recebimentos normais, as etiquetas são geradas somente para embalagens completas; carga inicial inventariada pode registrar a quantidade física parcial encontrada.
10. A rastreabilidade é inicializada e passa a acompanhar os eventos posteriores.

O Fluig deixa de criar o documento fiscal de entrada deste fluxo. O recebimento permanece no ANFE/Datasul. A nota de saída continua podendo ser solicitada pela manutenção de etiquetas no Fluig, com execução fiscal pelas rotinas padrão do Datasul.

### 5.1 Fronteira e paridade da revitalização — DT-048

A adequação obrigatória ao ANFE altera a criação do documento de entrada: o Fluig deixa de chamar as REAPIs de criação do documento, que passa a ser criado pelo fluxo ANFE/Datasul. Depois desse marco, o sistema novo deve manter todas as funcionalidades válidas anteriormente existentes, adaptadas ao modelo `contr_emb_*`, ao contrato REST e à rastreabilidade individual.

A revitalização deve melhorar o fluxo e ampliar a automação sem perder capacidade operacional. Processos que já funcionam permanecem como baseline; processos incompletos serão finalizados dentro da mesma experiência. Entram nessa complementação devoluções, pagamento/retorno e renovação de empréstimos, cancelamentos, anulações e outros casos que hoje obrigam conclusão manual no Datasul. A manutenção de etiquetas continuará como frente quando já exercer esse papel, incorporando os passos padrão ausentes conforme DT-047.

Antes de substituir ou retirar qualquer tela, Dataset, procedure ou ação, registrar a paridade: funcionalidade anterior, destino no novo fluxo, melhoria aplicada e cenário de aceite. Uma função somente poderá ser retirada quando seu equivalente novo estiver identificado e validado.

A paridade é funcional, não uma exigência de reaproveitamento técnico. A mudança para APIs REST, os novos cadastros e o modelo `contr_emb_*` exigem recontratar e adequar praticamente todas as procedures. Fontes legados fornecem comportamento, campos, chamadas e exceções para levantamento; cada rotina nova deve usar contratos versionados, autorização, paginação, idempotência e as estruturas atuais.

### 5.2 Local de execução e cobertura dos eventos — DT-031

**Compatibilidade FT4012 / DT-101, 04/10:** a criação do retorno recebe a tabela de itens de terceiros com a estrutura devolvida pela BO instalada, por OUTPUT TABLE-HANDLE inicialmente desconhecido, e a devolve por INPUT TABLE-HANDLE na geração dos itens. Não reconstrói nem adivinha campos faltantes de tt-it-terc-nf a partir de include histórico. Valida presença/tipo dos campos utilizados, mantém todos os demais campos/índices retornados e limita a edição à seleção e quantidade de retorno das linhas de origem exatas. Origem, disponibilidade, lote/validade, estoque padrão, atomicidade e validações da BO conservam os contratos vigentes. Objetos temporários são liberados ao concluir/falhar. Devolução de compra FT4011 permanece no contrato já comprovado. Não altera schema específico, assinatura pública, REST ou hooks.
**Recorte E09 / DT-095 — preparação da devolução pela BO:** a criação recebe uma entrada atualizada por chave completa e uma seleção explícita de embalagens inteiras, com versões. Revalida a origem, a disponibilidade e a soma por linha e posição; usa os métodos padrão FT4011/FT4012 da BODI317SD, sem abrir telas nem efetivar nota. WT e seleção específica confirmam juntos. A distribuição gerada pela BO precisa coincidir com a seleção; divergência provoca rollback, sem substituir silenciosamente lotes. O aceite dirigido terá duas compras novas: uma para devolução ao fornecedor e outra para remessa de empréstimo, recebimento na outra empresa e devolução vinculada à entrada do empréstimo. Preparação do WT não comprova os efeitos posteriores nas embalagens nem libera as UPCs para os novos ramos.

**Direcionamento confirmado em 01/10 — complemento DT-093:** o usuário escolhe uma natureza previamente cadastrada nas naturezas amigáveis. O backend lê `natur-oper.especie-doc`, `transf`, `terceiros` e `tp-oper-terc`: NFD encaminha a devolução de compra por FT4011; terceiros dos tipos 2/4/5/6 encaminham ao ramo FT4012 com documento de origem; terceiros do tipo 3 encaminham a remessa com seleção direta; NFT com transferência encaminha à transferência entre estabelecimentos. Armazenagem e empréstimo não precisam ser distinguidos apenas pelos atributos: a natureza e o documento de origem permitem recuperar o contexto e as movimentações envolvidas. A classificação identifica o ramo e a necessidade de origem; não substitui a autorização por naturezas amigáveis, os validadores da BO ou a validação das embalagens. Espécie NFE não constitui seleção de natureza para criar saída neste recorte. Outros ramos ainda sem contrato são recusados. Os tipos 2/4/6 são reconhecidos como ramo padrão de terceiros, sem declarar implementados seus efeitos nas embalagens.

O responsável técnico confirmou que, entre os processos fiscais deste ciclo, somente a emissão da nota de saída será iniciada fora do Datasul, pela manutenção de etiquetas no Fluig. Isso abrange saídas de transferência, devolução, empréstimo e renovação conforme as regras de cada operação. Preservar ao máximo a tela existente. Os fontes dos quatro repositórios Fluig foram recebidos e preservados em referências (DT-032); a obtenção das dependências ausentes e a confirmação das versões efetivamente instaladas em produção e homologação permanecem pendentes. Essa delimitação fiscal não elimina os cadastros e consultas operacionais já previstos no Fluig.

**Continuidade da operação na tela Fluig — DT-047:** a tela atual do Fluig permanece como frente para as saídas de transferência entre estabelecimentos, armazenagem em terceiros e estabelecimentos de outra empresa. O usuário não deverá iniciar uma dessas operações no Fluig e ser obrigado a migrar para uma tela Datasul no meio do procedimento para selecionar origem, vincular documento ou concluir a emissão. As procedures do backend devem encapsular as chamadas padrão necessárias e devolver à tela o estado e o resultado da operação.

O principal GAP conhecido é a devolução de empréstimo: o fluxo atual não oferece no Fluig o equivalente à seleção/vinculação realizada pelo FT4012. Devoluções em geral devem ser avaliadas pelo mesmo princípio. O levantamento documental associa FT4011 à geração de itens de devolução e FT4012 às operações com terceiros; deve-se conferir na instalação quais rotinas, APIs/BOs e dados atendem cada natureza antes de implementar. A indicação operacional de que a devolução de compra abre FT4011 é uma pista a validar, não contrato confirmado. Ajustes na tela Fluig fazem parte do recorte quando forem necessários para preservar o fluxo contínuo.

**Experiência documental — DT-094, 01/10, substitui a ação única da DT-093:** a manutenção de etiquetas oferece as ações Transferência e Devolução. Transferência reaproveita a seleção das embalagens. Devolução atende compra e empréstimo no mesmo modal adaptável pela natureza, acrescentando documento de origem e contraparte. A seleção prévia das embalagens é conferida contra a origem; incompatibilidades são informadas, sem exclusão silenciosa. Quantidades são preenchidas pela soma das embalagens elegíveis selecionadas e agrupadas por item, lote, validade, depósito, localização e unidade, preservando a linha documental de origem. Edição do total deve manter coerência com o rateio individual e a disponibilidade padrão. A política de fracionamento permanece pendente. Mockups serão ajustados na próxima revisão da manutenção de etiquetas, não nesta entrega. A natureza de operação é escolhida no início do modal e determina, por classificação devolvida pelo backend e validada novamente no comando de criação, qual sequência e quais campos são aplicáveis. A classificação definitiva deve derivar do cadastro e das parametrizações vigentes da natureza no Datasul, não de uma lista fixa de códigos no Widget, Dataset, API ou ABL. Campos como `natur-oper.transf` e `natur-oper.terceiros` aparecem nos fontes legados; o complemento de 01/10 acima fecha os atributos do direcionamento do ramo padrão, sem exigir distinguir armazenagem de empréstimo por esses atributos; disponibilidade de origem e efeitos específicos permanecem sujeitos às BOs e ao histórico. Não haverá uma interface independente por natureza nem escolha de ramo baseada apenas no texto digitado no Widget. Para transferência/remessa comum, a seleção de etiquetas feita na manutenção pode ser aproveitada após a natureza ser validada. Para devolução de compra ou retorno de empréstimo, o modal exige documento de origem e contraparte, consulta itens e embalagens elegíveis daquela origem, apresenta as quantidades disponíveis e permite ao usuário escolher o subconjunto e informar as quantidades admitidas. A origem e a disponibilidade são revalidadas no servidor antes de criar o documento. A tela pode oferecer atalhos que pré-filtram naturezas, mas a natureza validada continua sendo a autoridade do ramo. Códigos fixos são admitidos somente em executores isolados de TESTE para fechar cada fluxo; não migram para o código definitivo. Fracionamento do conteúdo de uma embalagem e contratos BO específicos permanecem pendentes de comprovação; a interface não presume que qualquer quantidade parcial seja permitida.

Saídas iniciadas diretamente no padrão Datasul também devem participar do controle individual. Recebimento, atualização/desatualização de estoque, cancelamento e demais tratamentos fiscais serão mapeados no Datasul, sem exigir passagem pela tela Fluig. A identidade da etiqueta e seu vínculo com todos os documentos do ciclo devem ser preservados em ambos os caminhos.

O cruzamento entre operação, canal de início, programa padrão, API/BO candidata, confirmação e efeito específico está em [MATRIZ_EVENTOS_EXECUCAO.md](../referencias/padrao-datasul/MATRIZ_EVENTOS_EXECUCAO.md). O desenho técnico propõe processamento ABL compartilhado entre a integração REST e as extensões do ERP. Os pontos exatos de UPC/EPC, confirmação transacional, seleção das etiquetas no padrão e tratamento de divergência continuam pendentes; não são contratos implementados.

## 6. Parametrização de itens

A parametrização é por estabelecimento e item e deverá permitir:

- informar capacidade da embalagem;
- informar tipo de embalagem;
- ativar e inativar o controle;
- incluir novos itens;
- editar a capacidade;
- excluir efetivamente um cadastro quando essa ação for solicitada;
- filtrar no Fluig por faixa de estabelecimento, item e situação ativa/inativa.

Definição vigente: existe uma parametrização por item. Mudança de capacidade que represente outro produto ou outra unidade operacional deve ser tratada com novo item no Datasul, não com coexistência de capacidades para o mesmo item.

O cadastro de tipos de embalagem do novo modelo será `contr_emb_bag`, com estrutura própria definida pelas necessidades do projeto. `bag_embalagens` é fonte de levantamento e de eventual aproveitamento de dados, sem obrigatoriedade de preservar sua estrutura ou seus códigos. O tipo utilizado na parametrização deve ser vinculado explicitamente ao novo cadastro, sem extração de `cod-refer` ou de qualquer referência.

### 6.1 Entrega incremental do cadastro — ET-01A, 07/09/2026

A pedido do responsável técnico, iniciar desenvolvimento por componentes verificáveis, com revisão independente a cada evolução. O primeiro recorte é a validação pura dos campos de tipo: código manual conforme DT-023, descrição obrigatória de até 100 caracteres e situação lógica obrigatória. Implementar componente ABL reutilizável e apoio de preenchimento no Fluig, com cenários executáveis e demonstração local explicitamente sem gravação. Código vazio/desconhecido, formato inválido, descrição vazia/excedente e situação desconhecida devem falhar com mensagem controlada. Remover espaços ASCII externos de código e descrição; o código aceita apenas letras ASCII e números, normalizando minúsculas. Não transformar caracteres Unicode em códigos ASCII válidos por equivalência linguística.

Este recorte não cria tabela, rota REST, registro cadastral ou dependência de campos padrão Datasul. Unicidade, autorização, versão, auditoria e recuperação durável de comandos pertencem à gravação integrada e continuam exigidas em ET-01. Repetição da validação comprova determinismo, não idempotência de uma gravação. A validação pura foi executada no OpenEdge 12.2 de TESTE em 11/09/2026 com 22 cenários e zero falha; isso comprova somente o componente puro. Pasta, execução e evidência estão no pacote `docs/entregas/pacotes/ET-01_TESTE`. A revisão de código e esse resultado não substituem a homologação do CRUD integrado.

### 6.2 Prioridade Progress e consultas cadastrais — DT-038

O entregável de Wallison nesta fase é Progress: tabelas específicas, índices/sequências necessários, fontes `.p`/`.i` e estrutura dos fluxos. As telas recebidas contextualizam operações; desenvolvimento Fluig pertence ao outro desenvolvedor. Preparação de telas só será retomada posteriormente, se houver tempo e nova priorização. Preservar o contrato entre camadas, sem implementar telas agora.

Preparar as consultas internas de tipos e parâmetros diretamente sobre `contr_emb_bag` e `contr_emb_param`, conforme campos do modelo v1.7. Retorno ABL por temp-tables de projeção, filtros no servidor e paginação por chave, sem gravação. Parâmetros são restritos aos estabelecimentos autorizados pelo adaptador confiável; a consulta de tipos exige autorização global explícita. Nenhuma permissão recebida livremente do JSON/Widget será aceita como autoridade. O vínculo do adaptador à identidade real continua pendente para exposição REST.

O contrato do componente interno está na seção 17 do catálogo. As consultas foram compiladas e executadas no OpenEdge 12.2 de TESTE sobre a base vazia; os cenários com massa continuam pendentes. A preparação inicial do fonte, por si só, não comprovava a tabela instalada, mas a estrutura v1.7 já foi implantada e conferida no schema holder. Não emitir `.df` com formatos LIKE presumidos. CONS-03 continua sendo requisito dos comandos operacionais longos, sem bloquear estas consultas sem efeitos.

### 6.3 Primeiro comando cadastral — ET-01D

O primeiro comando de gravação será `salvarTipo`, cobrindo inclusão, alteração e inativação. O código do tipo permanece imutável; não haverá exclusão física por esse comando. A autorização e a identidade do usuário chegam de um adaptador confiável, nunca de campos livres enviados pela tela.

Para recuperar respostas perdidas sem duplicar gravações, o comando reutiliza `contr_emb_evento`: origem e chave estável identificam a solicitação, os hashes canônicos distinguem repetição de conflito e o resultado concluído é persistido. A alteração de `contr_emb_bag`, a inclusão de `contr_emb_audit` e a conclusão do evento pertencem à mesma transação. `versao` protege alterações concorrentes. Essa aplicação cadastral não cria item de evento, movimento ou efeito de estoque.

As dez sequências Oracle foram confirmadas em TESTE no schema holder, com nome físico e owner `EMS2ESP`, antes da compilação dos comandos de gravação. Essa comprovação não autoriza gerar identificadores por máximo + 1 nem acrescentar outra tabela. Toda reconstrução do holder deve repetir a instalação e a validação descritas em `docs/entregas/ROTEIRO_SCHEMAHOLDER_TESTE.md` antes de publicar fontes que usem `NEXT-VALUE`.

### 6.4 Comando da parametrização — ET-01F

`salvarParametro` cobre inclusão, alteração, inativação e exclusão da parametrização por estabelecimento/item. Inclusão usa a sequência autoritativa; as demais ações exigem identidade e versão esperada. Estabelecimento e item são a chave funcional imutável, e continua existindo no máximo uma parametrização para o par.

O servidor confirma estabelecimento e item nos cadastros padrão, compara a unidade informada com a unidade de estoque do item e exige tipo existente e ativo quando o parâmetro resultante estiver ativo. O adaptador REST calcula os hashes; a identidade e a autorização só serão confiáveis quando o Dataset/serviço Fluig reconstruir o contexto conforme a DT-054. Evento idempotente, cadastro e auditoria são gravados na mesma transação; a exclusão preserva a fotografia anterior no histórico. O contrato detalhado está na seção 16.1 do catálogo e na DT-050.

A tela executa uma única ação de negócio: o usuário seleciona o estabelecimento e um item já cadastrado no Datasul, informa tipo de embalagem e capacidade e salva a parametrização. Quando o resultado ficar ativo e o item ainda não usar lote, o backend deve convertê-lo para `mgcad.item.tipo-con-est = 3` pelo mecanismo padrão suportado na versão instalada, confirmar o resultado e somente então concluir `contr_emb_param`. Não haverá uma etapa manual intermediária nem retorno a outra tela para converter o item.

Para item sem movimentos, saldos, documentos ou preços relacionados, a manutenção padrão do cadastro pode ser suficiente depois de comprovada na instalação. Para item com histórico, a conversão precisa reproduzir o tratamento do `CE0111 — Alteração Tipo Controle Estoque`, que ajusta as tabelas relacionadas; alterar somente `mgcad.item.tipo-con-est` por `CDAPIITEM` não converte o estoque existente.

Pela DT-059, essa conversão será executada por `contr-emb-conversao.p`, uma procedure backend técnica. Ela usa `CDAPIITEM` para alterar o cadastro do item e rotinas próprias, sem dependência da tela, para tratar as tabelas relacionadas nos mesmos três caminhos comprovados do CE0111. A procedure possui análise prévia sem gravação e execução controlada; sua compilação foi comprovada em TESTE e ela permanece separada de `salvarParametro` até a execução diagnóstica e o rollback integrado serem comprovados.

No caminho **Serial → Lote**, o saldo anterior não possui lote/validade. O `v80in172.w` confirma a chamada de `ce0111.i` com lote e validade obrigatórios. A rotina consolida os registros por posição remanescente e atribui os valores informados. O nome definitivo do lote inicial permanece pendente; entradas posteriores podem usar outros lotes e validades.

No caminho **Referência → Lote**, o `v80in172.w` confirma a chamada de `ce0111.i2` com referência vazia. A rotina preserva lote e validade em `saldo-estoq` e na maior parte do histórico ao retirar `cod-refer`; o tratamento complementar preserva o lote do Faturamento, mas `ce0111.i4` limpa `ped-saldo.lote`. O bloco de consolidação está comentado no padrão recebido; a consolidação abaixo é uma adaptação própria aprovada em 16/09/2026 (DT-061), não comportamento ativo comprovado da TOTVS. O conjunto ainda precisa ser confrontado com o `.r` ativo, pois o shell recebido é `.012` e TESTE exibiu `.018`.

Correção DT-063: todas as referências, inclusive F do faturamento legado, contribuem com suas quantidades para a consolidação 4→3. No exemplo F000050/PL-100, quantidades 1/0 resultam em saldo 1. Prefixo F ou log-reg-zero não elimina quantidade nem exige saldo zero para agrupar. Priorizar uma sobrevivente operacional não F quando existir; diferenças de dt-fabric e log-reg-zero de F não substituem esses dados da sobrevivente. Entre linhas operacionais, diferenças nesses dados continuam pendentes de política explícita, sem escolher fabricação arbitrariamente. Grupos apenas F também preservam quantidades e uma linha original. Não excluir o cadastro mestre da referência. Esta regra substitui o tratamento DT-062 de F exclusivamente zeradas e sua recusa por quantidade não zero.
A conversão consolida `saldo-estoq` por estabelecimento, depósito, localização, item, lote e validade, retirando somente a referência. Soma `qtidade-atu`, `qtidade-ini`, `qtidade-fin`, `qt-alocada`, `qt-aloc-prod` e `qt-aloc-ped`; conserva a maior data conhecida de `data-ult-ent` e `dt-ul-contag`. Campos restantes precisam ser iguais entre linhas agrupadas, exceto dt-fabric e log-reg-zero quando uma delas é F (DT-063), ou a conversão é recusada para não perder informação. Mesmo estabelecimento/depósito/localização/item/lote com validades diferentes continua bloqueado até comprovar uma chave física que permita separá-las após retirar a referência. O saldo de terceiros mantém seus registros, origens e quantidades; não é incorporado ao saldo interno nem agrupado entre contrapartes. O cadastro mestre de referências permanece intacto. Preparar e provar a consolidação e o rollback em TESTE antes de integrar ao cadastro de parâmetros.

A inativação ou exclusão interrompe novas gerações no estabelecimento. Como o controle padrão pertence ao item, a desativação só converte Lote → Serial (`tipo-con-est = 1`) quando não restar outro parâmetro ativo para o mesmo item em qualquer estabelecimento. Essa reversão faz parte da mesma ação, exige ausência de embalagens/saldos individuais e operações específicas ainda ativos, tratamento padrão comprovado do histórico e reconciliação quantitativa; se qualquer condição falhar, a operação inteira deve ser recusada ou recuperada sem deixar o item e a parametrização divergentes. Para itens com histórico em referência (`tipo-con-est = 4`), a ativação permanece uma única ação, mas só pode concluir depois das verificações aprovadas. A necessidade de intervenção não autoriza alteração direta e isolada de `mgcad.item` ou de `saldo-estoq`. Os três caminhos estão em `docs/entregas/PLANO_CONVERSAO_CONTROLE_ESTOQUE.md`.

### 6.5 Integração transacional do conversor — DT-068, 17/09/2026

Após aprovação isolada dos três caminhos ET-01H, integrar o conversor existente à ação salvar/inativar parametrização. O comando recebe lote e validade de migração explicitamente, obrigatórios somente quando uma ativação efetiva converter Serial→Lote; não há nome/data fixos definitivos. REST usa `loteMigracao` e `validadeMigracao` (ISO `YYYY-MM-DD`), incorporados ao hash do conteúdo quando informados. Campos são transitórios, não novas colunas.

Serializar comandos de parametrização pelo bloqueio do item padrão e conferir novamente idempotência, unidade, tipo, versão e vínculos ativos dentro da transação. Converter antes da alteração do parâmetro; falha desfaz item/histórico, parâmetro, evento e auditoria. Inclusão inativa não converte. Alteração para inativo e exclusão também são desativação quando retiram vínculo ativo. Com outro parâmetro ativo do item, conservar Lote; último vínculo só reverte se elegível. Registro já inativo não provoca conversão nova.

Impedir reversão se houver etiqueta ativa, quantidade específica não zero/desconhecida, situação desconhecida ou vínculo com Bag. Operações não canceladas vinculadas ao item exigem conciliação; `EXECUTADA` não prova ausência de pendência. Neste recorte, devolvê-las como impedimento de conciliação, sem inventar fechamento ou apuração de baixas ainda não implementados. Escritores futuros de geração/operação deverão compartilhar o bloqueio por item ou outra coordenação comprovada. Concorrência com lançamentos nativos do ERP permanece sujeita à janela de manutenção/corte aprovada; bloqueio do cadastro não bloqueia todos os movimentos padrão.

Integração preparada exige nova compilação e ET-01F com rollback, falha, repetição, múltiplos estabelecimentos e revisão REST antes da liberação. Ensaios isolados anteriores permanecem evidências, sem homologar esta revisão.

## 7. Geração de etiquetas

- O início do controle ocorre na entrada de compra de fornecedores com natureza `1101IS`, confirmada pelo responsável técnico (DT-027), para os itens ativos na parametrização. Essa entrada origina identidade, saldo individual e primeiro movimento. No legado, o fluxo de compra era realizado no Fluig, por isso a EPC excluía essa natureza do bloco de realocação usado nas movimentações entre estabelecimentos e terceiros. No novo fluxo, a geração acompanha a atualização confirmada do recebimento no Datasul.
- O gatilho é a atualização do documento no RE1001, com tratamento no ponto de extensão confirmado durante a implementação.
- A rotina deve selecionar apenas itens ativos na parametrização específica.
- A identificação deve considerar estabelecimento, item, lote e validade.
- A consolidação e o rateio nunca atravessam essa combinação. O mesmo item em lotes ou validades diferentes gera ocorrências separadas no evento e somente utiliza etiquetas compatíveis do respectivo saldo.
- A geração de recebimentos normais deve produzir somente embalagens completas. A carga inicial inventariada é a única exceção: pode criar uma embalagem com quantidade positiva inferior à capacidade, conforme medição física e vínculo ao PRE de origem.
- O número da etiqueta deve permanecer globalmente único.
- A geração deve ser idempotente: o mesmo evento não pode duplicar etiquetas.
- Cancelamento, anulação ou desatualização exigem tratamento consistente e histórico; a regra exata por evento deve ser confirmada nos casos de uso antes da implementação definitiva.

## 8. Movimentação e ciclo de vida

A rastreabilidade deve registrar eventos relevantes sem substituir o movimento real do estoque. Estão no escopo funcional macro:

Os tipos de transferência tratados no recebimento legado são referência de levantamento, não limite do novo projeto. O ciclo também deverá atender devoluções, empréstimos, cancelamento de notas e renovação de empréstimos, conforme reforçado pelo responsável técnico (DT-028). Cada operação terá regra própria para seus efeitos físicos e fiscais; não tratar todas como transferência nem gerar novas identidades somente por existir outro documento.

- recebimento e geração;
- cancelamento, anulação e desatualização do documento;
- transferência entre estabelecimentos;
- saída total ou parcial para o campo;
- retorno parcial por estorno no processo integrado ao GATEC;
- empréstimos;
- devoluções de empréstimos;
- renovação de empréstimos;
- devoluções de compras;
- retornos de armazenagem;
- armazenamento em Bags;
- descarte;
- faturamento e demais saídas que alterem o ciclo da embalagem.

No fluxo entre estabelecimentos, a linha fiscal consolida as embalagens de mesmo item, lote e validade. A saída do estabelecimento emissor e a entrada no estabelecimento recebedor rateiam essa quantidade entre os saldos individuais e registram os movimentos correspondentes. Não foi definida movimentação de embalagens entre depósitos. O depósito `INS` é referência operacional já levantada, mas seu uso definitivo em cada evento deve ser validado na regra correspondente.

Nas remessas de armazenagem em terceiros, o controle individual deve acompanhar o efeito confirmado pelo padrão Datasul: as embalagens selecionadas deixam a disponibilidade interna do estabelecimento remetente e passam à posição/custódia `TERCEIRO`, conservando identidade, item, lote, validade, quantidade, contraparte e vínculo com o documento de origem. Esse deslocamento não zera o conteúdo da embalagem e não cria nova identidade. No retorno total ou parcial, as mesmas embalagens e quantidades devem baixar a pendência específica em terceiro e voltar à posição interna confirmada pelo movimento padrão. `saldo-estoq` e o controle padrão de terceiros permanecem como autoridades consolidadas; `contr_emb_*` apenas espelha o fato por embalagem, sem lançar outro movimento no ERP (DT-053).

**E11/DT-097 — primeira etapa do empréstimo, 02/10/2026:** remessa iniciada pela seleção de embalagens inteiras e natureza classificada como REMESSA_TERCEIROS (NFS/NFT, terceiros tipo 3) pode seguir pelo WT/nota padrão. Confirmado o estoque no FT2100, registrar SAIDA_REMESSA_TERCEIROS, posição ESTAB→TERCEIRO, contraparte do documento e quantidade/situação conservadas. Operação passa a EXECUTADA (não significa empréstimo devolvido); desatualização sem fatos posteriores registra compensação e retorna operação a SOLICITADA com posições anteriores. Reatualização gera ciclo novo. Estoque e saldo-terc são somente lidos para comparação por documento/linha; a customização não cria ou baixa saldo padrão. Entrada no outro estabelecimento e retorno FT4012 continuam etapas próprias, não liberadas por esse ramo. Cenário isolado usa massa da compra 9999802, etiquetas 151/161 e natureza 5949IM, destino 11301; código definitivo não fixa esses valores.

A aplicação dessa mesma regra aos empréstimos entre empresas depende do enquadramento da natureza e do efeito efetivamente produzido pelo padrão na instalação. Quando o Datasul criar ou baixar saldo de terceiros, o específico deverá refletir esse efeito; o nome “empréstimo” sozinho não autoriza presumir a transição.

### 8.1 Bags: tipo de embalagem e lacre

**E10/DT-096 — devolução de compra, 02/10/2026:** após WT preparado por origem e seleção, BODI317EF vincula a nota e FT2100 aplica o mesmo ciclo histórico das saídas: atualização registra SAIDA_ESTOQUE/SAIDA_DEVOLUCAO_COMPRA, desatualização registra DESATUALIZACAO_SAIDA compensando o movimento anterior e reatualização cria ciclo novo. No recorte de embalagens inteiras, a saída muda ESTAB para TRANSITO, conserva quantidade/situação e identifica a contraparte; não encerra a identidade. Reversão restaura o estado anterior e exige ausência de fatos posteriores. Natureza NFD revalidada pelo cadastro, sem código fixo. Consultar saldo-terc antes/depois de cada passo apenas para comprovar efeito padrão, sem escrita customizada ou presumir que devolução de compra movimenta terceiros. Confirmação de entrega física ao fornecedor, cancelamento e empréstimo continuam recortes pendentes.

- `bag_embalagens` é o cadastro legado de tipos de embalagem, confirmado pelo responsável técnico; contém `cod_embalagem`, `desc_embalagem` e `sigla`. No novo modelo, `contr_emb_bag` atenderá a essa finalidade com campos, formatos e índices definidos para o projeto, sem obrigação de reproduzir o cadastro legado.
- `contr_emb_bag` designa o cadastro de tipos de embalagem. Cada ocorrência operacional de Bag será registrada em `contr_emb_bag_lacre`; o conteúdo atual fica em `contr_emb_etiqueta` e as inclusões/retiradas são fatos em `contr_emb_movto`, conforme o modelo corrente v1.7.
- Cada Bag é associada a um tipo de embalagem e somente pode receber vínculos de embalagens desse mesmo tipo.
- O tipo representa a natureza/material ou variante da embalagem e não sua capacidade. `contr_emb_bag.cod-tipo` é a única chave curta; não existe uma sigla separada. Exemplos válidos: `PL`, `PL1`, `PL2`, `001` e `002`.
- `cod-tipo` tem preenchimento manual, é obrigatório, único e imutável. A API remove espaços externos, converte letras para maiúsculas e exige 2 ou 3 caracteres no padrão `^[A-Z0-9]{2,3}$`. A capacidade permanece em campo próprio.
- Uma Bag de descarte pode misturar itens, lotes, validades e capacidades. A restrição de conteúdo é exclusivamente o mesmo `cod-tipo` da Bag.
- O controle operacional das Bags é realizado por lacre; no legado, esse dado está em `bag.nro_lacre`.
- No novo modelo, a compatibilidade deve comparar o tipo explícito da embalagem com o tipo da Bag. A identificação pelo prefixo de `cod-refer`, existente no legado, não será utilizada.
- Formato, unicidade e regras de troca ou reutilização do lacre ainda dependem de definição; não se presume que ele seja a chave física da tabela.

## 9. Empréstimos e renovações

**DT-102 / 05/10 — recebimento integral do retorno no credor:** ampliar o servico de entrada do emprestimo para NFE/terceiros tipo 5, sem fixar codigo de natureza. Correlacionar a nota recebida com DOCUMENTO_SAIDA_FLUIG da operacao RETORNO_TERCEIROS por vinculo persistido, chave NF-e ou identidade fiscal exata, remetente/destinatario e WT. O destino do retorno vem da operacao REMESSA_TERCEIROS ligada por id-oper-origem, nao de cod-estabel-dest vazio do retorno. Validar essa cadeia e as linhas de origem; referencia nativa dos itens pode identificar a remessa original, e nao deve substituir a nota fiscal do retorno. Referencia parcial/divergente, origem ambigua ou chegada ativa bloqueiam. Entrada confirmada recebe mesmas etiquetas inteiras de TRANSITO do devolvedor para ESTAB do credor, conservando quantidade/situacao/identidade e registrando RECEBIMENTO_RETORNO_EMPRESTIMO/ENTRADA_RETORNO_EMPRESTIMO. RE0402 compensa por snapshot e nova atualizacao cria outro ciclo. Nenhuma escrita no estoque/terceiros padrao, nova tabela, rota REST ou criacao de entrada; ANFe continua responsavel. SAVE e ensaio integrado permanecem obrigatorios antes do aceite.

**DT-100 — vínculo persistente dos recebimentos, implementação autorizada em 04/10/2026:** buscar origem por associação existente/histórico, referência completa dos itens, chave eletrônica da mesma NF-e e identidade do cabeçalho quando for a mesma nota; exigir saída única, emissor/destinatário, WT/operação e composição compatíveis. Gravar VINCULO_ENTRADA_SAIDA na estrutura de eventos, sem novo saldo padrão. Referência parcial ou contraditória bloqueia. Origem de entrada substituta pode ser associada explicitamente pelo serviço interno; outro número não exige igualdade com o cabeçalho. Último movimento valida saída pendente ou reversão da chegada dessa mesma origem, inclusive de outro documento. Verificar chegadas ativas em toda a origem e revalidar sob bloqueio da operação. A regra substitui as restrições de numeração/predecessor da DT-099; não libera cancelamento/anulação, parcialidade ou busca por quantidade. Implementação e aceite nativo continuam estados separados. Revisão: `docs/entregas/REVISAO_VINCULO_RECEBIMENTOS_20261004.md`.

**DT-099 — correlação da entrada de empréstimo sem campos complementares:** quando série/número de origem dos itens estiverem ambos vazios, usar série/número do cabeçalho da entrada, emitente para resolver o emissor e destinatário para confirmar o recebedor. Não preencher campos padrão. Campos parcialmente preenchidos ou divergentes do documento fiscal recebido bloqueiam. Validar uma única nota de saída, WT/operação/destino e ciclo ativo, reconciliando todos os grupos e etiquetas. Entrada manual 1949OE demonstrou campos complementares vazios; isso não autoriza buscar somente por item ou quantidade. Conciliação dirigida em TESTE pode registrar chegada específica da entrada já atualizada, atomicamente e com as mesmas guardas/idempotência, sem repetir atualização de estoque padrão.

**E12/DT-098 — recebimento e devolução do empréstimo:** entrada NFE de terceiros tipo 3, correlacionada de forma única à remessa rastreada, recebe as mesmas embalagens inteiras em ESTAB do destino. Validar integralmente todas as linhas/rateios por item, lote, validade e unidade, sem gerar identidades; grupos repetidos com destinos físicos distintos são ambíguos e recusados. Evento RECEBIMENTO_EMPRESTIMO e movimento ENTRADA_EMPRESTIMO apontam à saída ativa. Reversão restaura o snapshot TERCEIRO/contraparte e admite novo ciclo, sem apagar fatos. Retorno de terceiros tipo 2/5 usa a entrada recebida como origem no FT4012; sua saída registra SAIDA_RETORNO_TERCEIROS e ESTAB→TRANSITO, preservando conteúdo e contraparte. Atualização/desatualização/reatualização seguem ciclos da saída. Saldo de terceiros e estoque padrão são somente observados, nunca escritos pela customização. Recebimento do retorno no credor é etapa posterior. Preparação não equivale a compilação ou aprovação nativa.

**Regra confirmada — DT-034:** a renovação de empréstimo acompanha as transações efetivamente realizadas pelo produto padrão. Se uma transação fiscal movimentar o saldo consolidado do item em `saldo-estoq` e houver vínculo com etiquetas/embalagens, o controle específico deve registrar e refletir esse movimento nas identidades vinculadas. Não excluir movimentos por classificar a operação como renovação, simbólica ou exclusivamente fiscal, nem exigir deslocamento material para reconhecer uma movimentação de estoque confirmada no ERP.

Se o padrão produzir uma entrada e uma saída na renovação, ambas devem permanecer rastreáveis, mesmo com efeito líquido zero. Deduplicação vale para repetição da mesma ocorrência, não para suprimir transações distintas. Somente quando não houver efeito no estoque consolidado não haverá reflexo quantitativo por esse motivo; documentos e vínculos continuam registrados. Preservar as identidades existentes, sem gerar novas etiquetas por renovação. A parametrização e os contratos determinam o efeito de cada etapa; o nome da operação não o determina.

Conforme esclarecimento do responsável técnico (DT-033), a devolução no fluxo utilizado parte da seleção do documento de origem do empréstimo, seus itens e quantidades, admitindo devolução integral ou parcial. Preservar essa relação na integração e no controle individual: documento/linha de origem, baixa da operação, documento de devolução e etiquetas efetivamente envolvidas. A natureza e o enquadramento padrão instalado ainda precisam ser conferidos; não equiparar toda devolução a devolução de compra.

Quando a natureza confirmada mantiver saldo de terceiros, a remessa e o retorno seguem também a DT-053: a pendência consolidada do padrão deve possuir correspondência nas embalagens em custódia de terceiro, e cada retorno baixa somente a origem, as etiquetas e a quantidade efetivamente selecionadas. Pagamento documental sem retorno físico acompanha apenas os efeitos que o padrão realmente confirmar e não pode recolocar embalagem no estabelecimento por inferência.

O [detalhamento de devoluções e reversões](../referencias/padrao-datasul/DEVOLUCOES_E_REVERSOES.md) complementa a matriz existente, incluindo seleção de origem, disponibilidade/alocação, rateio parcial e compensação da baixa específica. O levantamento também classifica os eventos sem NF que podem afetar etiquetas, para confirmar cobertura no ambiente sem aprovar automaticamente novos fluxos de estoque ou corrigir saldos legados.

- O prazo de referência do empréstimo é 180 dias.
- Se a empresa não possuir material físico para devolver, a nota de pagamento sem saldo não deve criar consumo fictício no saldo de embalagens.
- Uma entrada posterior de novo empréstimo cria o saldo correspondente.
- A atualização do documento que efetivamente representa a movimentação deve produzir o evento no controle.
- Mesmo quando a operação fiscal ou operacional for uma manobra específica do cliente, os eventos devem ser registrados de forma identificável para explicar o ciclo ocorrido.

## 10. Integrações previstas

### 10.1 Fluig e Datasul

Toda nova integração do projeto deve seguir o baseline REST v1.0. As regras centrais são:

- Widget consulta Dataset; não chama diretamente o banco nem mantém credenciais.
- No endpoint `/api/public/ecm/dataset/search`, os filtros são enviados em `filterFields`.
- Dataset recebe constraints, monta query parameters e chama o serviço autorizado.
- API ut-api recebe os query parameters como `JsonArray`.
- ABL aplica regras e filtros no servidor e devolve JSON estável.
- O código definitivo não pode conter filtros de teste chumbados.

O controle funcional do usuário é feito no Fluig por grupos. A interface usa esses grupos para exibir telas e ações; o Dataset usa a sessão real do Fluig e não aceita do navegador identidade, permissão ou contexto de autorização. Quando o grupo também restringir fazenda ou estabelecimento, o Dataset transforma essa configuração em uma lista explícita de estabelecimentos permitidos para a chamada. O ABL recebe a lista já resolvida, aplica-a antes dos demais filtros e recusa a operação quando ela estiver vazia ou não contiver o estabelecimento alterado. A relação final entre grupos e estabelecimentos será afinada com o desenvolvedor Fluig e não ficará chumbada no Progress.

### 10.2 ANFE

O ANFE passa a ser a origem do fluxo de recebimento fiscal. A pré-aprovação inicial da fazenda abrange os XMLs emitidos contra seu estabelecimento, independentemente de existirem itens controlados pelo projeto. A fazenda reconhece o documento válido ou rejeita uma emissão indevida; após o reconhecimento, o documento segue o fluxo fiscal já existente no ANFE da usina, onde o responsável assume e valida a entrada conforme seu tipo antes de importá-la para o Datasul/RE1001.

Na reunião de 11/09/2026, a equipe ANFE apresentou o AED (Aprovação Eletrônica de Documentos) como módulo padrão candidato a atender essa pré-aprovação. Foi informado que o XML entra bloqueado, usuários não fiscais recebem perfil restrito à aprovação e o reconhecimento libera o documento para o fluxo fiscal atual. A adoção depende de demonstração conjunta com o cliente e o responsável técnico do AED, sobretudo para confirmar restrição de visualização por estabelecimento, rejeição, permissões, auditoria e cobertura dos tipos de documento usados pela BP.

O AED é a alternativa preferencial enquanto essa validação estiver aberta. `Monitor-Xml` permanece como esboço e contingência: somente se o AED não atender ao fluxo aprovado será levantada uma integração própria no Fluig, usando contrato ou chamada oficialmente suportada pelo ANFE e seguindo a baseline REST. Nenhuma identificação de item parametrizado pertence a essa etapa. O Controle de Embalagens consulta a parametrização somente após a atualização confirmada do documento no RE1001.

### 10.3 GATEC

As consultas utilizadas pelo GATEC deverão considerar a nova rastreabilidade individual em conjunto com o saldo consolidado do ERP. Não alterar contratos existentes sem levantamento e validação com o responsável pela integração.

### 10.4 Pontos de extensão Datasul

O planejamento das integrações utilizará a biblioteca de APIs e BOs de Recebimento e Faturamento, incluindo NF-e e complementos fornecidos, em `referencias/padrao-datasul/README.md`. A coleta abrange todas as referências enviadas, sem se limitar às chamadas legadas; a seleção será relacionada às transações em `MATRIZ_TRANSACOES.md`. Link catalogado, conteúdo lido, contrato analisado, versão conferida e serviço homologado são estados distintos. A biblioteca não altera o escopo de negócio nem autoriza portar todas as rotinas (DT-029).

O levantamento cobre RE1001/RE1005RP, RE0402, cálculo/efetivação de saída, FT2100 e FT2200, além dos monitores que acionam esses processos. Deve contemplar estoque automático parametrizado na natureza e execução sem interface, conforme a release instalada. A matriz de execução distingue eventos citados no TDN de pontos ainda sem contrato comprovado. O nome de uma tela ou um evento de integração de outro módulo não comprova sozinho um ponto adequado de implementação para este projeto.

## 11. Estrutura de dados

As entidades conceituais necessárias são:

- parametrização do item controlado;
- identificação individual da etiqueta;
- saldo/situação/localização atual da embalagem;
- consolidação da linha fiscal e rateio entre as embalagens individuais;
- vínculo com documentos fiscais;
- histórico imutável dos movimentos e eventos.

O prefixo aprovado para as novas tabelas específicas é `contr_emb_`, para diferenciá-las das tabelas padrão com prefixo `emb` informadas pelo responsável técnico.

A tabela de parametrização terá o nome físico `contr_emb_param`. Não está prevista outra tabela de parametrização, dispensando o sufixo `_item`.

O cadastro de tipos de embalagem terá o nome físico `contr_emb_bag`, com definição própria conforme a seção 4.5. A entidade operacional de Bags e lacres também deverá ser modelada para as necessidades do projeto. O levantamento das tabelas legadas não impõe correspondência de uma tabela antiga para uma tabela nova.

As novas procedures serão implementadas diretamente sobre as tabelas `contr_emb_*` e as tabelas padrão autoritativas do Datasul. `etiquetas-CD`, `bag`, `bag_embalagens`, `bag_etiquetas` e `bag_log` permanecem apenas como fontes de levantamento ou migração; não serão uma camada temporária da aplicação nova. Migrações, quando definidas, serão isoladas do fluxo operacional REST.

As propostas anteriores com prefixo `emb_` estão substituídas pelo padrão acima. Por solicitação do responsável técnico, o modelo completo passa a ser definido em `docs/05_MODELO_DADOS.md`, acompanhado do dicionário estruturado corrente `docs/modelo-dados/contr_emb_v1.json`.

Após revisão orientada à simplicidade, o modelo corrente v1.7 abrange 10 tabelas: `contr_emb_bag`, `contr_emb_param`, `contr_emb_evento`, `contr_emb_evento_item`, `contr_emb_etiqueta`, `contr_emb_movto`, `contr_emb_bag_lacre`, `contr_emb_oper`, `contr_emb_oper_item` e `contr_emb_audit`. A etiqueta reúne identidade, origem e projeção atual; os fatos permanecem separados em movimentos. As propostas v1.0 até v1.6 foram preservadas apenas como histórico em `docs/modelo-dados/`; não são as estruturas indicadas para implementação.

Trata-se da arquitetura aprovada para implementação. Em 09/09/2026, sua estrutura física foi criada no Oracle de teste `BPTESTE/EMS2ESP` e as dez tabelas foram carregadas e verificadas no schema holder `shmgesp`. Em 10/09/2026, as dez sequências e seus vínculos físicos foram confirmados em nova sessão ABL. Isso comprova a estrutura de TESTE; a homologação funcional de cada fluxo continua dependendo de seus testes. Ela estabelece chaves, relacionamentos, campos e controles de integridade próprios. Chaves externas, regras de eventos e políticas de lacre ainda exigem as conferências identificadas no modelo antes dos respectivos fluxos.

Os eixos estáveis são: uma parametrização por estabelecimento e item; tipos explícitos; `contr_emb_etiqueta` como registro da identidade permanente da embalagem e de sua projeção individual atual; `contr_emb_movto` como histórico imutável; documentos padrão referenciados por fotografias mínimas nos eventos; controle de repetição e auditoria; Bags por ocorrência e lacre; operações com itens e baixas concentrados. A entidade controlada é a embalagem. A etiqueta materializa seu código e pode ser reimpressa sem criar nova embalagem, identidade ou movimento. Depois do vínculo inicial, código e embalagem representam a mesma identidade durante todo o ciclo. O evento concentra documento, tipo documental e natureza; cada movimento referencia o evento e, quando aplicável, seu item, sem repetir a fotografia documental completa. Acréscimos de campos deverão preservar esses eixos e os contratos publicados.

Na transição, a mesma estrutura admite `tipo-controle = PRE_SALDO` para identificar que determinada combinação de estabelecimento, depósito/localização, item, lote e validade já existia quando o item passou a ter suas embalagens controladas. Seu código técnico usa o prefixo `PRE-`. O PRE não reconstrói nem pretende explicar qualquer fato anterior ao corte. Sem inventário, fica fora do fluxo específico: não recebe `contr_emb_movto`, não entra em Bag, não é impresso e não representa embalagens conhecidas. Se o cliente decidir saná-lo, precisa inventariar as embalagens físicas; um evento de rateio zera total ou parcialmente o PRE e cria registros `EMBALAGEM`, cada qual mantendo `id-pre-origem` permanentemente. Somente essas embalagens individualizadas passam a participar do fluxo, como as novas entradas do item. Novos recebimentos criam apenas embalagens.

`contr_emb_evento_item` representa o agrupamento lógico de cada linha/lote fiscal consolidado. O rateio da saída ou da entrada é composto pelos registros de `contr_emb_movto` ligados ao mesmo `id-item-evento`, cada um associado à embalagem afetada e ao seu saldo atual. Assim a consulta por documento recupera itens consolidados, movimentos, embalagens e saldos sem uma etiqueta-mãe redundante.

## 12. Interfaces Fluig previstas

Destino das telas atualizado em 11/09/2026 (DT-052): substituir **Item por Etiqueta** pela parametrização de itens controlados; validar primeiro o **AED padrão do ANFE** como substituto da pré-aprovação feita pelas fazendas na tela legada de recebimento; manter `Monitor-Xml` apenas como contingência caso o AED não atenda aos requisitos aprovados; concentrar consulta e impressão de **Etiquetas Item — Centro de Distribuição** na manutenção de etiquetas, preservando ao máximo esta última. A retirada operacional das telas legadas depende da demonstração do AED e da conferência de paridade. Não houve desativação nesta etapa.

Os quatro repositórios fornecidos foram gravados em `referencias/fontes-fluig-github/2026-09-04/`, com commits e inventário em [fontes Fluig recebidos](../referencias/fontes-fluig-github/README.md). Controle-Bags e manutenção v2 são referências de homologação do legado; o Monitor-Xml é esboço do projeto novo. A publicação desses commits nos ambientes não foi conferida.

O agrupamento entregue ao desenvolvedor Fluig está em [Mapa das telas Fluig](entregas/MAPA_TELAS_FLUIG.md): uma tela nova de parametrização, adequação da manutenção de etiquetas e adequação do Controle de Bags. Transferências, terceiros, devoluções e empréstimos permanecem como fluxos/modais da manutenção; conversão do item não cria tela própria.

- Pré-aprovação de XMLs pelas fazendas preferencialmente no AED; Monitor Fluig somente se houver lacuna comprovada.
- Parametrização dos itens controlados.
- Manutenção e consulta das etiquetas.
- Transferência de embalagens.
- Pesquisa por nota específica e múltiplas notas.
- Filtros para notas de retorno.
- Consultas de saldo, localização, situação e histórico.

## 13. Requisitos não funcionais

### 13.1 Organização do backend Progress

O backend específico será organizado por responsabilidade de negócio, sem um arquivo por operação CRUD:

- `contr-emb.p`: fachada, regras transversais, tipos, parâmetros, Bags/lacres e auditoria;
- `contr-emb-rastreio.p`: eventos, itens do evento, embalagem/etiqueta e movimentos;
- `contr-emb-operacao.p`: solicitações, transferências, baixas, devoluções, descarte e compensações;
- `contr-emb.i`: temp-tables e contratos compartilhados pelos três módulos.

Procedures internas agrupam as operações de cada módulo. Os adaptadores REST permanecem finos e não duplicam regras. `contr-emb-rastreio.p` e `contr-emb-operacao.p` somente serão materializados quando seus recortes entrarem em implementação. A integração GATEC continua em levantamento; seu encaixe será decidido pelas responsabilidades confirmadas, podendo justificar `contr-emb-gatec.p` sem alterar os três módulos centrais.

- APIs REST com contrato JSON versionável e mensagens legíveis.
- Limite e paginação em consultas potencialmente volumosas.
- Idempotência nos eventos de criação e atualização.
- Histórico auditável sem exclusão silenciosa de movimentos.
- Nenhuma credencial, token, cookie ou conteúdo de sessão em fonte, resposta ou log.
- Atualizações do PASOE devem confirmar `.r`, PROPATH e refresh dos agentes do ambiente correto.
- Quantidades do projeto devem preservar quatro casas decimais quando o dado de negócio exigir.
- Consultas devem ser filtradas no servidor; não retornar milhares de registros para filtrar no navegador.
- Fontes e diagnósticos devem consultar cada registro no banco lógico proprietário: cadastros mestres e item em `mgcad`, saldos/movimentos/documentos de estoque em `mgmov` e estruturas específicas `contr_emb_*` em `mgesp`. Conexões de schema holder servem apenas à compilação e à leitura/manutenção de metadados e não podem ser usadas como origem de registros funcionais.
- A propriedade do dado não obriga prefixar toda tabela no ABL. Preservar a resolução validada na sessão Datasul: saldo-estoq é consultada sem qualificação e sem FIELDS, mantendo o filtro por item (DT-060, atualização de 16/09/2026).
- Identificadores e versões específicos usam `INTEGER`, conforme o padrão definido para esta implantação.
- A estrutura específica não usa `CLOB` ou `LONGCHAR`; conteúdos técnicos persistidos são textos `CHARACTER` com limite explícito e conteúdo mínimo.
- No Oracle de teste, as tabelas físicas serão criadas no owner `EMS2ESP` e tablespace `TS_EMS2`. `DATETIME-TZ` usa `TIMESTAMP(6) WITH TIME ZONE`; `DATE`, `CHARACTER`, `INTEGER`, `DECIMAL` e `LOGICAL` usam respectivamente `DATE`, `VARCHAR2`, `NUMBER`, `NUMBER` com escala definida e `NUMBER`. Cada tabela recebe sequência, `PROGRESS_RECID`, índice `##REC` e índices `##I<n>` conforme o padrão DataServer conferido no ambiente.

### 13.2 Buscas dos campos e rastreabilidade da interface — DT-064

Cada campo, botão e modal das três telas terá identificador estável na matriz `docs/entregas/MATRIZ_TELAS_CAMPOS_ACOES.md`, ligado ao catálogo, procedure, API, dependência e evidência. Elementos locais não chamam API. Nomes propostos permanecem separados de procedures implementadas.

Autocomplete: mínimo de 2 caracteres, espera de 350 ms após digitação, até 20 opções por chamada, paginação por cursor, cancelamento e descarte de respostas antigas. Não baixar o cadastro inteiro para filtrar no navegador. Mudança do campo pai limpa a seleção dependente. Exigir seleção de código válido; texto digitado não é identidade. Lista vazia de estabelecimentos autorizados nega antes de ler dados. O Dataset reconstrói esse contexto da sessão/grupos.

Primeiro recorte: consultar estabelecimentos permitidos e catálogo global de itens em `mgcad`, dentro de `contr-emb.p`, por código inicial ou nome/descrição literal. Escolher estabelecimento para buscar item é contexto de autorização; não afirma que o item tenha saldo ou vínculo naquele estabelecimento. Depósito, localização, lote, documentos, contraparte e motorista exigem contrato/fonte própria comprovada. Consulta de CD permanece baseline independente.

Os protótipos identificam dados de demonstração, mostram os fluxos internos e não representam homologação ou execução fiscal. Conversão continua parte interna da parametrização.

Manutenção incremental obrigatória: ao identificar necessidade de novo autocomplete durante a evolução do projeto, incluí-lo no mesmo checkpoint em `docs/entregas/cobertura-telas.json`, com tela/campo, dependências, procedure, método/rota, arquivo e estado real. Quando fonte ou contrato ainda não estiver comprovado, registrar como pendente, sem inventar implementação. Regenerar a matriz de controles e os inventários das matrizes REST/Progress; atualizar catálogo e pendências conforme a definição evoluir. Não esperar implementação ou conclusão da tela para mapear a necessidade.

A mesma manutenção vale para novas procedures: registrar a necessidade no catálogo e na matriz Progress no mesmo checkpoint, com finalidade, módulo/arquivo, dependências e estado. Acrescentar exposição REST à matriz de APIs quando aplicável e relacionar tela/campo/botão no mapa de controles quando houver interação de interface. Procedures internas de apoio também têm rastreio no catálogo/Progress. Atualizar acompanhamento e Planner quando houver checkpoint aceito que altere o avanço, respeitando a referência gerencial vigente.

### 13.4 Recorte somente leitura de Bags — DT-066

Adiantar `consultarBags` e `consultarConteudoBag` no núcleo existente. Autorizar pelo estabelecimento responsável da Bag; ao listar conteúdo, exigir também autorização do estabelecimento atual de cada etiqueta. Ocultar Bag inexistente ou sem acesso com a mesma resposta. Paginação por ID exclusivo, padrão/teto 20; consulta não cria vínculos, eventos, movimentos ou transições. Conteúdo refere-se ao vínculo atual e não prova elegibilidade, disponibilidade ou descarte. O primeiro recorte não agrega quantidades de itens/unidades diferentes nem produz resumo global; futuras totalizações precisam contrato próprio. REST/JSON seguem pendentes de adaptação e prova, sem declarar rota pronta apenas pela implementação ABL.

### 13.3 Validações da consolidação Referência → Lote — DT-065

Repetir o tipo atual é sucesso sem alteração; não exigir pré-condições de mutação ou ler histórico nessa repetição. Isso não dispensa existência do item nem as validações quando houver troca real.

Não exigir igualdade de todos os campos de `saldo-estoq` para consolidar referências. Essa comparação genérica não foi comprovada como exigência do CE0111 e bloqueava diferenças de fabricação, registro zero e outros atributos sem relação demonstrada com a identidade do saldo. Preservar os atributos não somados da linha sobrevivente original, priorizando não F conforme DT-063, sem inventar data de fabricação ou recalcular `log-reg-zero`. Diferenças nesses atributos deixam de impedir a consolidação, inclusive entre referências não F.

Manter as seis somas e as máximas datas de entrada/contagem, as posições e os lotes. Quantidade/alocação desconhecida continua impedindo soma. Validades diferentes na mesma posição/item/lote permanecem separadas conceitualmente e não podem ser fundidas: o conversor mantém recusa explícita até comprovar a chave física que permita preservar ambas depois de retirar a referência. Essa recusa é uma limitação técnica do backend próprio, não uma regra atribuída à TOTVS. Falha de API, lock ou integridade física deve desfazer a transação. Cadastro mestre de referência e vínculos de terceiros permanecem preservados. Não dispensar a prova 4→3/3→1 e a reconciliação antes da integração à parametrização.

### 13.5 Desenvolvimento local sem compilador — DT-070

Servidor 103 indisponível para os ensaios do responsável: adiantar consultas já contratadas, mantendo fila de compilação/teste, sem alterações remotas. Não declarar avanço funcional por fonte novo.

Expor recortes somente leitura BAG-04/BAG-08 existentes em `GET /bags` e `GET /conteudo-bag` (`idBag` em query). A rota simples de conteúdo é o contrato técnico deste recorte; `/bags/{idBag}/conteudo` permanece proposta da API completa, sem presumir suporte de path params. Mesmos filtros/autorizações/teto/cursor do catálogo 22, datas ISO opcionais inclusivas na lista. Sem totais globais, transições, elegibilidade ou efeitos em estoque.

Autocomplete de tipos `GET /apoios/tipos`, procedure `consultarTiposApoio` no núcleo existente: busca código por prefixo OU descrição por trecho, mínimo dois caracteres, filtro até 100, limite padrão/teto 20 e cursor exclusivo por código. Ativos por padrão; `ativo=false` busca inativos e `ativo=todos` atende filtros históricos; situação omitida equivale a ativos. Permissão global para tipos segue Dataset/grupos e serviço autorizado já definidos; não inferir vínculo de tipo ao estabelecimento. Reutilizar projeção ttEmbTipo, sem mudança física.

Query fornecida com tipo, ID/cursor/limite ou data inválidos deve falhar, sem ampliar busca por transformar erro em filtro vazio. IDs e cursor saem como texto; data usa YYYY-MM-DD. Atualizar mapa tela/campo e matrizes no mesmo checkpoint. A publicação conjunta depende de SAVE, ET-01F integrado já pendente e testes específicos das novas consultas.

### 13.6 Recorte backend adicional — DT-072

Desenvolver em arquivos existentes: consultarFamilias (autocomplete cadastral em mgcad.familia por fm-codigo/descricao, fonte comprovada no legado recebido) e obterDadosImpressao (GER-05, uma identidade EMBALAGEM por chamada). Família é catálogo global consultável com lista explícita não vazia de estabelecimentos autorizados; não promete saldo/vínculo/elegibilidade nesse estabelecimento. Busca de 2–100 caracteres, prefixo do código OU descrição literal, teto 20 e cursor exclusivo. Não inferir grupo de estoque a partir de família.

Dados de impressão usam registro específico autorizado pela posição atual, tipo EMBALAGEM e evento de geração CONCLUIDO existente. Rejeitar PRE_SALDO e geração não confirmada; devolver dados da identidade persistida sem gerar código, embalagem, movimento ou alterar contador. Não imprimir papel nem definir layout/cópias/serviço. Bag inteira/batch de etiquetas continuam contrato próprio; não tratar recorte por uma etiqueta como impressão da Bag.

Transportes GET /apoios/familias e /dados-impressao preparados com parser estrito existente e contexto do Dataset autorizado. Mudanças exclusivamente backend; nenhum comportamento de campo/UX Fluig desenvolvido. Compilação, massa, REST e homologação pendentes; ações cadastrais existentes permanecem nos contratos próprios. Não iniciar escrita fiscal/Bag com contratos ainda abertos.

### 13.7 Massa sintética para ensaios em TESTE — DT-074

Em 17/09 o responsável autorizou criar registros de teste para desbloquear cenários positivos. Usar executor específico de teste, com confirmação explícita de TESTE e conexão ao holder documentado de homologação. Preparar tipos, eventos, Bags e projeções de etiquetas somente na transação do ensaio; sempre desfazer a massa, inclusive em erro, conferindo os IDs/códigos após rollback. Sequências podem avançar. Não alterar cadastros ou estoque padrão, nem criar documentos fiscais.

Essas projeções são fixtures de consulta, não resultado de geração RE1001, inclusão operacional em Bag ou movimentação: tais produtores e seu histórico continuam pendentes dos contratos próprios. Reaproveitar os testes readonly compilados; registrar separadamente evidências com massa e sem massa. A autorização não abrange produção nem promove ensaio ABL a homologação REST.

### 13.8 Consulta do resultado de geração — DT-075

Fechar GER-04 como consulta somente leitura por `idEvento`. A autorização usa o estabelecimento fotografado no evento e a lista explícita recebida da camada confiável. A resposta separa o cabeçalho funcional, a memória de cálculo dos itens/lotes e a página das identidades `tipo-controle = EMBALAGEM` nascidas no evento. `PRE_SALDO` não aparece como etiqueta gerada.

A fotografia de nascimento não replica posição, posse, Bag, situação ou quantidade atuais; esses dados continuam em `consultarEtiquetas`. Não devolver hashes, token de processamento ou `dados-evento`. Paginação por `id-etiqueta`, cursor exclusivo, limite padrão 20 e máximo 100. Expor `GET /geracoes?idEvento=...`; IDs JSON são texto. A consulta não cria evento, item, etiqueta ou movimento e não substitui o gatilho pendente do RE1001/AED.

### 13.9 Núcleo comum de fatos — ET-02 / DT-076

Implementar uma única infraestrutura em `contr-emb-rastreio.p` para registrar eventos idempotentes e aplicar movimentos individuais. `registrarEvento` recebe uma fotografia já canônica em `ttEmbEventoComando`, autorização e usuário confiáveis; mesma origem/chave/conteúdo devolve o evento existente, enquanto reutilização da chave com conteúdo ou tipo diferente é conflito. Evento novo nasce `RECEBIDO`, com tentativa zero, sem assumir processamento, conclusão ou regra fiscal.

`aplicarMovimento` recebe um comando preparado em `ttEmbMovimentoComando`. Sob bloqueio do evento e da etiqueta, confere sequência do evento, tipo `EMBALAGEM`, versão e último movimento esperados, relações opcionais e destino válido; grava `contr_emb_movto` e atualiza a projeção de `contr_emb_etiqueta` atomicamente. O primeiro movimento é a única exceção sem estado/origem anterior e parte de quantidade anterior zero. Movimento posterior fotografa a projeção bloqueada. `PRE_SALDO` é recusado.

Esse núcleo não classifica natureza, não chama BO fiscal, não dispara RE1001 e não decide efeitos próprios de transferência, devolução, terceiros ou compensação. O produtor específico prepara o destino e a quantidade final conforme seu contrato aprovado. Repetição da mesma sequência e conteúdo devolve o mesmo movimento; sequência reutilizada com conteúdo diferente é conflito. O teste ET-02 usa somente massa sintética em TESTE e rollback integral.

### 13.10 Fronteira dos gatilhos Datasul — DT-077

O projeto não recria importação, atualização, desatualização ou cancelamento de documentos de entrada. ANFE e o recebimento padrão criam/importam o documento; o Datasul atualiza, desatualiza ou cancela e mantém o estoque consolidado. Um ponto de extensão fino identifica o fato confirmado, obtém sua identidade estável, classifica o caso e delega às rotinas específicas, que reutilizam `registrarEvento` e `aplicarMovimento`. A extensão não grava outro movimento no estoque padrão.

Compra de fornecedor confirmada pode gerar novas identidades apenas para itens com parametrização vigente. Entrada de transferência, retorno ou continuidade de operação reutiliza as identidades vinculadas à saída/origem e nunca executa novamente a seleção pelo Fluig. Desatualização ou cancelamento não apaga histórico: registra o fato e aplica somente a compensação correspondente ao efeito que o padrão realmente reverteu.

No primeiro recorte da compra `1101IS`, a desatualização confirmada pelo RE0402 preserva a identidade e o nascimento de cada embalagem. Se todas permanecem no primeiro movimento, sem Bag ou movimento posterior, o específico registra um evento ligado ao recebimento e um movimento compensatório por etiqueta, com motivo “Documento desatualizado no RE0402” e identidade da nota. O movimento zera a quantidade atual da projeção individual e marca a etiqueta `CANCELADA`; não altera o estoque padrão nem apaga histórico. Dependência posterior ou múltiplos ciclos ambíguos bloqueiam esse recorte. A UPC só pode ser ativada após comprovar transação e estado do documento no evento backend; novo ciclo por reatualização ainda requer definição própria.

Quando uma saída nasce no Fluig, cada execução de criação produz um documento. A camada customizada valida e persiste seleção/rateio, chama a BO/API padrão instalada para criar esse documento e guarda sua identidade devolvida. Criação ou efetivação fiscal não constitui, sozinha, confirmação do movimento individual. Atualização/desatualização do estoque e cancelamento continuam no padrão e são refletidos por pontos de extensão. Não haverá REST customizado para substituir RE1001, RE0402, FT2100 ou o cancelamento padrão.

Na manutenção de etiquetas/embalagens, o usuário seleciona as embalagens e a natureza de operação. A natureza determina o ramo do fluxo. Em devolução, o Fluig deve obter o documento de origem, emitente e itens/quantidades elegíveis antes de solicitar à BO padrão a criação do único documento desta execução; a origem pode ser escolhida em etapa anterior conforme a experiência da tela, desde que seja revalidada após a natureza. A chamada exata à BO/API de devolução depende do contrato instalado e ainda não está homologada.

Para E04, a captura da atualização e da desatualização do estoque da saída deve cobrir tanto o processamento pelo FT2100 quanto a atualização automática durante o FT4003. Em TESTE, o caminho FT4003 passou pelo FT2100RP e ambos os sentidos foram observados no EPC `end-ft2100`: `i-tipo-atual=1` para atualizar, `2` para desatualizar, `l-desfaz=no`, ROWID da nota e transação ativa. O fonte FT2100RP confirma que `l-desfaz=yes` desfaz o bloco da nota. A UPC tratará os dois sentidos e deduplicará pelo fato confirmado, sem inferir etiquetas do saldo consolidado. **Neste recorte, somente notas originadas pelo Fluig possuem embalagens selecionadas e vinculadas; notas criadas diretamente no Datasul não produzem movimento individual de etiquetas.** Uma futura seleção em específico do FT4003 não está no escopo atual. A seleção do Fluig precisa permanecer vinculada à operação e ao documento criado nessa execução antes do efeito de estoque. O cancelamento fiscal permanece marco distinto. O E04 observa a nota padrão; não é a rotina que a cria.

O Fluig cria um documento por execução do seu comando; já o FT2100 pode atualizar ou desatualizar várias notas numa execução em faixa. O EPC `end-ft2100` deve tratar cada nota separadamente pelo ROWID recebido. Para persistir a seleção individual antes desse fato, a extensão candidata v1.8 adiciona `id-etiqueta` às linhas `SOLICITACAO` de `contr_emb_oper_item`, mantendo cada etiqueta/quantidade ligada à operação e ao evento do documento. Essa extensão ainda exige implantação e prova em TESTE; não altera a v1.7 já implantada.

Como uma operação pode selecionar milhares de etiquetas, a v1.8 candidata também deve indexar `id-etiqueta` em `contr_emb_oper_item` para consultar reservas anteriores sem varrer todas as linhas. Cada linha representa uma embalagem selecionada e permanece como histórico da intenção; movimentos confirmados continuam em `contr_emb_movto`. O índice não torna a seleção uma movimentação nem dispensa validação transacional de duplicidade.

Restrição de tempo do fluxo Fluig/Datasul: uma operação pode conter cerca de 3.000 embalagens e a chamada síncrona que cria o `wt-docto` pela BODI317 tem limite informado de **200 segundos**. A seleção feita na tela é enviada no comando; o backend valida as identidades, mas somente persiste operação, linhas individuais e vínculo com `i-seq-wt-docto` após a BO confirmar a criação. Se a criação falhar efetivamente, nenhuma seleção específica é gravada e o usuário pode selecionar novamente. A implantação das duas colunas v1.8 em TESTE libera o ensaio isolado e reversível desse registro, sem ativar a UPC. A gravação pós-criação e a capacidade de desfazer o documento padrão se essa gravação falhar ainda precisam ser comprovadas na PI real; timeout isolado não comprova falha da BO.

Na transferência iniciada no Fluig, a seleção das embalagens deve permanecer vinculada à operação e ao documento de trabalho `wt-docto` criado no FT4003. A v1.8 candidata registra `seq-wt-docto` na operação após a criação confirmada pela BO e `id-etiqueta` em cada linha selecionada. Quando o documento de trabalho resultar em nota, **antes de qualquer atualização de estoque automática ou posterior pelo FT2100**, gravar esse WT em slot versionado de `nota-fiscal.char-2` (posições 1500–1519), preservando todas as demais posições; a gravação exige simultaneamente o ID do WT e o ROWID da nota, recusa conflito e aceita repetição idêntica. FT2100 recebe o ROWID da nota, confere o WT gravado com a operação e registra ou compensa os movimentos sem perder a seleção nem o histórico. Uma atualização posterior pode produzir outra numeração; não pressupor que isso ocorra em todos os casos, e a nova nota deve carregar o mesmo WT. O ponto de chamada no FT4003 instalado e a persistência do slot ao longo da atualização/desatualização ainda precisam de comprovação antes de ligar o E04. No recebimento de transferência entre estabelecimentos da mesma empresa, o ANFE/RE1001 recebe a nota de entrada; a customização deverá correlacioná-la à saída de origem para movimentar **as mesmas identidades**, sem criar etiquetas novas. O contrato de correlação e o marco confirmado dessa entrada ainda são pendentes.

No recorte E04 aprovado em TESTE, atualização e desatualização da nota `0019557` preservaram a seleção e o histórico da operação. A consulta posterior comprovou que `mgcad.wt-docto` `492960` não existe mais; a desatualização pelo FT2100 não o devolveu ao FT4003 neste caso. Se **a mesma nota** for atualizada novamente pelo FT2100, sua marca `CEWT1:492960` e a operação `6` permitem recuperar a seleção histórica das etiquetas 101/103. Essa nova atualização deve criar outro evento e dois novos movimentos de saída, com `seq-ciclo` seguinte; uma nova desatualização compensa somente essa saída nova. Repetição da mesma ocorrência mantém seu resultado, sem suprimir ciclos distintos nem apagar histórico. Uma nota de **novo número** exige vínculo documental próprio com uma operação/seleção comprovada; não presumir retorno do WT nem reaproveitamento automático do vínculo pela interface.

**Ordem funcional da criação de saída:** transferência, devolução e devolução de empréstimo partem sempre das embalagens escolhidas explicitamente. O backend usa a seleção para obter item, lote, validade, estabelecimento, depósito, localização e quantidade, confere a correspondência com o saldo padrão e agrupa as quantidades compatíveis em linhas do documento. Cada etiqueta escolhida continua identificada individualmente na operação, mesmo quando várias formam uma única linha fiscal. A atualização e a desatualização posteriores não recebem nova seleção: aplicam o fato às etiquetas já vinculadas ao documento/WT. Os contratos fiscais específicos de devolução e retorno permanecem próprios e pendentes; esta regra de origem da seleção não define por si só a BO de cada ramo.

A cobertura de cancelamento deve abranger documentos de entrada e de saída. Na entrada, registrar o sinal de cancelamento e acompanhar o tratamento padrão até a desatualização efetiva pelo RE0402 quando houver; na saída, distinguir o cancelamento pelo FT2200 da desatualização do estoque pelo FT2100 ou FT4003. A palavra “anulação” não é sinônimo técnico aprovado de cancelamento: pode designar outro procedimento fiscal ou um documento compensatório. Cada cenário só produzirá movimento específico quando o efeito real do Datasul e sua ligação com as etiquetas estiverem comprovados.

Correlação de recebimento de transferência deve ser serviço reutilizável, separado do código da extensão: localizar operação/documentos de saída, itens, lotes e etiquetas, suportando parcialidade e múltiplos documentos. Até comprovar o relacionamento padrão e os campos disponíveis na release, registrar `PONTO_DATASUL_A_CONFIRMAR`; não inventar chaves, tabelas, BOs ou assinaturas.

**Primeiro recorte executável da entrada 5557 → 1557, em preparação no TESTE:** após o RE1001 confirmar `docum-est.ce-atual=YES`, o serviço usa `item-doc-est.nro-comp/serie-comp` e o emitente da entrada para procurar uma única nota de saída 5557 no estabelecimento de origem, emitida ao estabelecimento destinatário. Exige o vínculo documental `DOCUMENTO_SAIDA_FLUIG`, operação `TRANSFERENCIA` com destino igual à entrada, marcador WT concordante na nota e exatamente uma saída de estoque não compensada. Para este primeiro ensaio, aceita uma única linha e um único rateio integral `rat-lote OF item-doc-est`: item, lote, validade, unidade e quantidade devem coincidir com todas as etiquetas selecionadas na operação, ainda em `TRANSITO` no último movimento dessa saída. Depósito e localização de destino vêm do rateio de estoque exibido no RE1001; os campos homônimos de `item-doc-est` podem permanecer vazios. Só então registra o evento de chegada e um movimento por identidade, levando-as ao destino sem criar novas etiquetas nem movimentar novamente o estoque padrão. Ausência, ambiguidade, parcialidade, dependência posterior ou divergência bloqueiam o específico. A entrada manual `10913/1/0019557` confirmou `nro-comp/serie-comp` e toda a cadeia de origem; a importação real pelo ANFE permanece pendente de prova end-to-end. O fluxo com múltiplas linhas/rateios/documentos e a reversão dessa chegada permanecem pendentes.

**Ciclos posteriores da mesma entrada, DT-092:** cada desatualização efetiva pelo RE0402 (`ce-atual=NO`) cria um evento `DESATUALIZACAO_ENTRADA` ligado ao recebimento ativo e um movimento compensatório por etiqueta, de `ESTAB` no destino de volta ao `TRANSITO` da saída original. Quantidade e situação permanecem, e os fatos anteriores não são apagados. A nova atualização efetiva pelo RE1001 (`ce-atual=YES`) cria outro `RECEBIMENTO_TRANSFERENCIA` e outra entrada individual; os ciclos ficam numerados 1, 2, 3 etc. A compensação exige que cada etiqueta ainda esteja no último movimento da chegada correspondente; dependência posterior ou histórico ambíguo bloqueia. Fonte preparado em TESTE, ainda sem SAVE/ensaio dos ciclos. Não desatualizar a entrada de ensaio antes da instalação validada.

A cobertura de backend passa a contar somente capacidades `CUSTOM_BACKEND`. `DATASUL_STANDARD`, `UPC_HOOK`, `STANDARD_BO_CALL`, `REST_API`, `UI_DATASET`, `LOCAL_UI` e `EXTERNAL` possuem inventários próprios e não aumentam o denominador de procedures customizadas. A matriz vigente está em `docs/entregas/MATRIZ_GATILHOS_DATASUL.md`.

### 13.11 Núcleo de validação e geração — GER-02/GER-03 / DT-078

O serviço interno recebe ocorrências fiscais já fotografadas pelo futuro adaptador de recebimento. `validarGeracao` confere estabelecimento, item, participação pela parametrização ativa, controle por lote, tipo ativo, capacidade, unidade, lote, validade, precisão e unicidade da ocorrência `sequencia + seq-lote`; calcula somente embalagens completas e resíduo. Item sem parâmetro ativo é preservado como `IGNORADO`. Nesta revisão, unidade recebida diferente da unidade de estoque/parametrização é recusada com `CONVERSAO_UNIDADE_NAO_COMPROVADA`; nenhum fator é inferido.

`gerarEtiquetas` aceita somente a memória previamente validada, registra evento e itens, cria identidades `EMBALAGEM`, aplica o movimento `NASCIMENTO_RECEBIMENTO` pelo núcleo ET-02 e conclui o evento em uma transação local. Não cria `PRE_SALDO`, não altera estoque padrão, não expõe rota REST e não liga RE1001/RE1005. Repetição idempotente de evento concluído devolve o mesmo resultado sem nova gravação; conteúdo divergente é conflito.

Quando a embalagem não possui localização interna, `contr_emb_etiqueta.cod-localiz` deve permanecer vazio (`""`), como em `saldo-estoq`; o primeiro movimento e os movimentos seguintes não devem projetar `?` nesse campo da etiqueta. Essa normalização vale para novas gravações e não reescreve identidades históricas automaticamente.

### 13.12 Dispatcher inicial do recebimento — GER-01 / DT-079

`processarRecebimento` recebe internamente o `ROWID` entregue pelo EPC apenas para localizar a fotografia padrão; o `ROWID` não integra a identidade persistida. O dispatcher exige documento existente com `ce-atual = sim`, classifica neste recorte somente a natureza confirmada `1101IS`, lê cabeçalho e ocorrências diretamente de `mgmov.docum-est` e `mgmov.item-doc-est`, seleciona somente itens com parametrização ativa e chama GER-02/GER-03. Naturezas diferentes retornam `NAO_APLICAVEL`, sem criar evento nem antecipar transferência, terceiros ou empréstimo.

A identidade inicial usa estabelecimento, emitente, série, documento e natureza, com ciclo 1; o conteúdo canônico inclui as ocorrências participantes ordenadas por sequência e ocorrência de lote. Repetição com o mesmo conteúdo recupera o evento concluído; divergência é conflito. Reatualização posterior à desatualização continua fora deste recorte até o inverso definir o ciclo seguinte.

O fonte legado e o TDN oficial comprovam `re1005rp`/`fim-atualizacao`; o legado também comprova a assinatura `p-ind-event`, `TABLE tt-epc` e o parâmetro `docum-est rowid`. Em 22/09/2026, a sonda no TESTE comprovou a execução do EPC, `TRANSACTION_ATIVA=SIM`, `ce-atual=SIM` e cabeçalho/dez ocorrências disponíveis. Isso libera preparar a ligação interna. Antes de ativá-la, ainda é necessário conferir a UPC efetivamente instalada e provar que uma falha propagada da chamada desfaz a atualização padrão; transação ativa, isoladamente, não comprova esse comportamento. Nenhuma rota REST é criada.

Na candidata da UPC RE1005RP de TESTE, o tratamento de etiquetas legadas por referência, seus movimentos artificiais e a realocação de etiqueta-mãe/filhas são substituídos pelo serviço GER-01 e não devem continuar executando. Permanecem na mesma UPC a atualização de situação da solicitação e dos itens do CD e o procedimento `pi-atualiza-follow-up` da outra consultoria, com suas dependências. A sonda de diagnóstico não integra a UPC operacional. A chamada de GER-01 exige `ce-atual = sim`; esta limpeza não altera os contratos de GER-02/03 nem o estoque padrão.

## 14. Macro de esforço existente

A macro disponibilizada registra 240 horas, distribuídas em 160 horas Progress e 80 horas Fluig:

- levantamento e revisão dos processos: 12h;
- adequação do fluxo ANFE/RE1001: 38h;
- evolução da arquitetura de rastreabilidade: 48h;
- adequação das regras de negócio: 40h;
- adequação das funcionalidades existentes: 44h;
- integração GATEC: 16h;
- parametrizações e implantação: 18h;
- testes integrados e homologação: 24h.

Essa macro é referência de planejamento e deve ser revisada quando o escopo físico das tabelas, contratos do ANFE e eventos detalhados forem fechados.

## 15. Fora do escopo sem aprovação adicional

- Correção de inconsistências preexistentes no Datasul, Fluig, ANFE ou GATEC.
- Alteração de customizações sem relação comprovada com este projeto.
- Mudança em regra já homologada que não seja necessária à nova arquitetura.
- Parametrização padrão do ERP não exclusiva ao funcionamento da solução.
- Movimento artificial para encobrir processo operacional sem saldo ou sem documento correspondente.

## 16. Critério de aceite técnico

- API direta, Dataset e Widget produzem resultados coerentes para os mesmos parâmetros.
- Filtro vazio, filtro preenchido, limite inválido e limite máximo têm comportamento definido.
- Eventos repetidos não duplicam etiqueta nem movimento.
- A rastreabilidade pode ser conciliada com os documentos e movimentos reais do Datasul.
- Nenhum elemento legado de referência participa do novo controle.
- Reinício ou refresh do PASOE não altera o contrato nem alterna versões entre chamadas.
- Logs e respostas não expõem dados de autenticação.
- Documentação, decisões, pendências e changelog estão atualizados.

## 17. Fontes desta consolidação

Em 04/09/2026, a leitura individual do TDN pelo navegador permitiu mapear candidatos padrão em `referencias/padrao-datasul/MAPEAMENTO_APIS_BOS.md` e atualizar a matriz de transações. São evidências documentais para planejamento, não contratos homologados: preservar a compra centralizada no ANFE, utilizar as BOs internas por trás da fronteira REST e confirmar separadamente efetivação fiscal, autorização eletrônica e atualização de estoque. Não houve alteração de tabelas ou regras de negócio nessa pesquisa. Fontes/includes da release instalada e eventos de confirmação seguem pendentes.

O detalhamento da fase de nascimento das embalagens está em `07_CICLO_VIDA_EMBALAGEM.md`, seção 7, e suas rotinas propostas em `06_CATALOGO_PROCEDURES.md`, seção 10. A atualização confirmada do recebimento permanece como gatilho; a classificação entre geração de novas identidades e recebimento de etiquetas existentes precisa respeitar a operação real. Transferências preservam as identidades da origem. O detalhamento não aprova espécies/naturezas fiscais, cancelamento ou contratos de integração ainda pendentes e não altera a estrutura física nesta etapa.

- Proposta “Adequação do Projeto de Rastreabilidade de Embalagens à Centralização do Recebimento Fiscal por meio do ANFE”, de 30/07/2026.
- Macro `MacroAdequaçãoAnfe.xlsx`.
- Fontes Progress e includes fornecidos para análise do legado.
- Baseline REST Fluig-Datasul v1.0 validado em 03/09/2026.
- Definições técnicas registradas durante os levantamentos do projeto.






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
