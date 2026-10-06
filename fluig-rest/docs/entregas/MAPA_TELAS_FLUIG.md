# Mapa das telas Fluig — Controle de Embalagens

**Data:** 21/09/2026  
**Objetivo:** orientar o desenvolvimento visual e a integração sem separar artificialmente operações que pertencem à mesma experiência.

## Organização visual aprovada

O mockup está organizado em quatro áreas: **Embalagens**, **Bags**, **Manutenção de Etiquetas** e **Monitor de Documentos de Recebimento**. Embalagens possui as abas **Tipos de Embalagem** e **Itens Controlados**; Bags possui as abas **Manutenção de Bags** e **Consulta de Bags**. Aba, modal e fluxo guiado são somente organização da experiência e não criam backend independente.

Nas listagens, usar filtros no topo, Buscar/Limpar, Novo à direita, ações por registro e toggle Ativo/Inativo na linha. Cadastro e edição abrem modal. Ações em lote usam checkbox e comando imediatamente acima da grid.

Estabelecimento, Item e Tipo de Embalagem usam um único campo físico por entidade. O usuário digita código ou descrição; o Progress executa o match por código **OU** descrição; o Fluig apresenta código + descrição e envia o código selecionado. Não criar campos separados para código e descrição.

## 1. Embalagens

É a primeira tela nova e pode ter o desenvolvimento visual iniciado agora. Substitui a função legada **Item por Etiqueta**.

### Aba Tipos de Embalagem

- filtros por Tipo de Embalagem e situação;
- Novo abre modal;
- Editar é ação da linha e abre modal;
- Ativo/Inativo usa toggle na linha;
- código manual de 2 a 3 caracteres, descrição e situação permanecem no cadastro;
- a aba reaproveita os contratos de tipos existentes; não possui serviço próprio.

### Aba Itens Controlados

- consulta por Estabelecimento, Item, Tipo de Embalagem e situação, sem campo separado de descrição;
- lista das parametrizações autorizadas para o usuário;
- Novo e Editar abrem modal com estabelecimento, item Datasul, unidade de estoque somente leitura, tipo de embalagem e capacidade;
- Editar, Excluir e demais ações aplicáveis pertencem ao registro da grid;
- Ativo/Inativo usa toggle na linha;
- confirmação e apresentação do resultado da operação, inclusive repetição, conflito de versão e erro controlado;
- nenhuma tela ou passo manual separado para converter o controle de estoque do item.

Ao salvar uma parametrização ativa, o backend deve parametrizar e, quando necessário, converter o item para Lote dentro da mesma operação. Ao retirar o último parâmetro ativo do item, o backend deve executar a reversão segura para Serial. A interface não altera diretamente o cadastro padrão do item.

O diagnóstico ET-01H ainda definirá se lote e validade de migração precisam ser solicitados ao usuário no primeiro vínculo ou se serão resolvidos por regra controlada. Esses campos não devem ser fixados no layout definitivo antes dessa prova.

### Integração disponível

- tipos: `GET`, `POST` e `PATCH` já tiveram o ciclo REST técnico comprovado;
- parâmetros: consulta e recusas iniciais já foram comprovadas; o fluxo positivo aguarda ET-01H, integração da conversão e ET-01F;
- identidade, grupos e estabelecimentos devem ser obtidos pelo Dataset a partir da sessão Fluig.

## 2. Bags — ajustar a existente

Usar `Controle-Bags` como referência visual e funcional, adaptando-o ao modelo `contr_emb_*`.

### Aba Manutenção de Bags

- filtros por Estabelecimento, Tipo de Embalagem, lacre, situação e período;
- Nova Bag abre modal; Editar, Conteúdo e Eventos ficam na linha;
- o modal de conteúdo lista somente as etiquetas já vinculadas;
- **Pesquisar dentro desta Bag** filtra localmente no Fluig somente o conteúdo já carregado;
- Remover selecionadas da Bag é ação em lote sobre os registros vinculados;
- Inserir embalagens abre uma etapa própria dentro do contexto da Bag, com leitura/digitação de uma etiqueta e busca de elegíveis para inclusão em lote;
- busca de elegíveis, vínculo e retirada preservam os contratos BAG já propostos e não criam rota nova;
- registrar envio, retorno, troca de lacre e descarte conforme as transições que forem aprovadas.

### Aba Consulta de Bags

- usa os mesmos filtros visuais da área;
- é somente leitura;
- Conteúdo, Histórico e Impressão ficam como ações da linha;
- consultar uma Bag não permite criar, editar, vincular, retirar ou executar evento.

O backend de Bags ainda não está liberado para integração. O desenvolvimento imediato deve se limitar ao inventário da tela atual, desenho e componentes reaproveitáveis até o fechamento das transições, permissões e contratos.

## 3. Manutenção de etiquetas — ajustar a existente

Preservar ao máximo a manutenção `manutencao-etiquetas-v2`. Ela será a tela central de consulta, impressão e início das operações de saída.

### Consulta e manutenção

- filtros por etiqueta, item, estabelecimento, depósito, lote, validade, família/grupo, situação, Bag e nota fiscal;
- lista com identidade, item, lote/validade, quantidade, unidade, posição, custódia, situação e Bag;
- detalhe com documentos vinculados e histórico de movimentos;
- impressão e reimpressão individual ou em lote sem criar nova identidade nem movimentar saldo;
- pesquisa por intervalo de notas e por múltiplas notas específicas.

`GET /etiquetas` já compilou e passou no teste ABL somente leitura, mas ainda precisa ser publicado e validado pelo REST. Histórico detalhado e impressão ainda dependem de contratos próprios.

### Operações abertas dentro da manutenção

Usar modal ou fluxo guiado sobre as etiquetas selecionadas, sem criar uma tela independente para cada natureza:

- transferência entre estabelecimentos;
- remessa e retorno de armazenagem em terceiros;
- operação entre estabelecimentos de empresas diferentes;
- devolução integral ou parcial;
- empréstimo, pagamento/retorno e renovação;
- acompanhamento e retomada de operação pendente, concluída ou com falha.

A natureza dirige o ramo padrão Datasul. Devoluções e terceiros precisam acrescentar seleção do documento de origem, itens, quantidades original/devolvida/alocada/disponível e rateio das etiquetas. Esses contratos ainda dependem da validação das rotinas instaladas equivalentes a FT4011/FT4012; o desenvolvedor pode trabalhar no desenho e reaproveitamento visual, mas não fechar payloads ou integração fiscal por suposição.

## 4. Monitor de Documentos de Recebimento

O Monitor aparece como área independente no mockup, mas permanece informativo. Filtros, colunas, ações e integração aguardam a validação do AED padrão do ANFE por estabelecimento. A existência da área visual não libera Monitor XML, consulta, aprovação, recebimento ou atualização de documento.

## 5. Telas que não entram no desenvolvimento agora

| Tela/conjunto | Direção vigente |
|---|---|
| Formulário Fluig de recebimento | Não recriar. A entrada passa pelo ANFE e a geração começa após a atualização confirmada no Datasul/RE1001. |
| Monitor XML funcional | Em espera. A área visual independente não altera a decisão: só será implementado se a demonstração comprovar que o AED padrão não atende ao reconhecimento/rejeição por fazenda. |
| Etiquetas Item — Centro de Distribuição | Consolidar suas consultas e impressão na manutenção de etiquetas; retirar somente após conferir paridade. |
| Conversão do controle do item | Não criar tela. É parte interna da ação de salvar/inativar a parametrização. |

## 6. Ordem de trabalho para o desenvolvedor Fluig

1. Criar a área Embalagens com as abas Tipos de Embalagem e Itens Controlados.
2. Criar o Dataset comum que obtém usuário e grupos da sessão e resolve os estabelecimentos permitidos.
3. Adaptar a consulta da manutenção de etiquetas ao novo contrato, preservando o layout útil existente.
4. Mapear os modais atuais de transferência e desenhar a seleção de origem para devoluções/terceiros.
5. Adaptar Bags nas abas Manutenção e Consulta, preservando pendências dos contratos operacionais.
6. Manter o Monitor de Documentos como mockup informativo até o AED ser formalmente recusado.

## 7. Regra de segurança entre as camadas

O Widget controla apresentação e envia somente dados funcionais. O Dataset obtém a identidade real da sessão, verifica grupos e transforma a regra em lista explícita de estabelecimentos. O serviço cadastrado chama a API Datasul. O Progress aplica o recorte recebido e as regras de negócio; não interpreta nome de grupo nem aceita usuário ou permissão escolhidos no navegador.


## 8. Trabalho independente enquanto o compilador do 103 está indisponível

**Checkpoint de 16/09/2026:** o responsável está com acesso somente à sessão Datasul; o servidor 103, que hospeda o compilador oficial, está sendo utilizado por outras atividades. A revisão DT-063 fica aguardando compilação SAVE 5/0 e diagnóstico somente leitura. Isso não impede a preparação e o desenvolvimento visual abaixo. Não usar a sessão runtime Datasul como substituta do compilador nem executar a conversão com r-code anterior.

### Entrega imediata ao Dev Fluig

| Recorte | Trabalho que pode avançar | Aceite deste recorte | Dependência para integrar |
|---|---|---|---|
| Embalagens | Montar as abas Tipos de Embalagem e Itens Controlados; filtros no topo, ações por linha, modais e toggles; unidade somente leitura; estabelecimento/item imutáveis ao editar um vínculo existente. | Apresentar estados carregando, vazio, erro e confirmação; preservar campos digitados em erro; impedir duplo envio; apresentar conflito de versão e repetição conforme retorno. | As abas reutilizam os contratos existentes e não criam backend independente. A busca de item/unidade precisa de fonte contratada; não inventar endpoint. |
| Identidade e estabelecimentos | Preparar o adaptador do Dataset e o mapeamento dos grupos/estabelecimentos, separado dos campos funcionais do Widget. | Widget não escolhe usuário, grupo ou permissão; ausência de autorização impede a chamada; limite por estabelecimento aplicado no servidor. | Códigos dos grupos e correspondência com estabelecimentos ainda precisam ser fornecidos/validados no Fluig (DT-054). |
| Consulta de etiquetas | Adaptar visualmente a manutenção existente aos filtros e à projeção contratados em ET-02A; distinguir EMBALAGEM de PRE_SALDO e as dimensões situação/posição/custódia/Bag. | Estados carregando/vazio/erro, paginação do servidor e descarte de respostas antigas na troca de filtro; PRE não recebe ações de embalagem. | Publicação/REST de ET-02A e Dataset autorizado. Filtros ampliados, histórico, impressão e operações fiscais têm contratos próprios ainda pendentes. |

Usar dados de demonstração identificados somente no protótipo visual, sem transformar telas ou respostas simuladas em prova funcional. Chamadas reais devem respeitar a API existente e a autorização resolvida pelo Dataset. Nenhuma ação de conversão vira botão/tela independente.

**Atenção ao fonte existente:** `fontes/fluig/datasets/dsControleEmbalagensAPI.js` implementa a consulta de CD do baseline, apontando para `cd-ressuprimento`. Ele é referência de transporte; não representa Dataset cadastral/etiquetas implementado nem libera o ciclo novo. Preservar esse teste pioneiro e preparar o adaptador do novo recurso conforme ET-01G/ET-02A, sem misturar os dois contratos. Na chamada assíncrona Dataset search, seguir `filterFields` do baseline.

### Trabalho possível com a sessão Datasul disponível

Usar as telas padrão somente para conferir a apresentação e os cadastros da massa de TESTE e levantar evidências solicitadas por um recorte. Não precisa alterar o controle dos itens, movimentar estoque ou reiniciar serviço para avançar no desenho das telas. Os testes DT-063 ficam para a janela do compilador; a compilação aprovada anterior não cobre os fontes atualizados.

### Retomada técnica quando o 103 estiver disponível

Seguir `ET-01H_CONVERSAO_CONTROLE_ITEM.md`, seção 5, com os caminhos absolutos: transportar pacote, compilar SAVE 5/0 no OESTUDIO oficial, executar diagnóstico .r somente leitura e devolver TXT. Somente diagnóstico aprovado libera o ensaio autenticado com rollback. Depois provar 3→1 e a integração ao parâmetro; não antecipar essa integração durante a espera.

Este checkpoint organiza trabalho independente; não comprova tela desenvolvida, nova compilação/publicação ou aceite integrado. Não há alteração de rota REST, regra de negócio ou percentual do planner; Fase 2 permanece 51%.

## 9. Entrega navegável ao Dev — DT-064

- [Mockup das quatro áreas, quatro abas e formulários internos](mockups/index.html).
- [109 campos/ações com procedure, método/rota, arquivo e situação](MATRIZ_TELAS_CAMPOS_ACOES.md).
- [Datas e avanço do Planner oficial](CRONOGRAMA_PLANNER_GESTAO.md).
- [Contrato dos apoios de estabelecimento e item](ET-01I_APOIOS_AUTOCOMPLETE.md), implementados em fonte e aguardando TESTE.

Exemplo: **Bags → Manutenção de Bags → Nova Bag → abrirBag (BAG-05; proposta) → POST /bags (proposta) → contr-emb.p (proposto)**. Nova Bag abre o modal; POST só ocorre depois da confirmação. A aba e o modal não criam uma chamada adicional, e os nomes propostos não são chamadas prontas.

Mockups usam dados demonstrativos e não chamam servidor. Mapa técnico pode ser aberto na própria tela. Consulta de CD permanece baseline separado. Depósito/localização/lote/documentos/natureza/Bag e filtros ampliados ainda têm contratos/implementações a fechar. Conversão permanece interna à parametrização.

O responsável confirmou o Planner Teams apresentado à gestão: Fase 2 50%, interface nova até 25/09, APIs/telas até 19/10, realização até 22/10, testes 23–29/10, usuários 30/10–06/11. Percentual local 51% dos registros anteriores é histórico não sincronizado; não é a referência gerencial vigente. Preparação de layout/fonte não altera automaticamente avanço oficial.
