# ET-02A — Consulta da projeção atual de etiquetas

## Situação

Recorte somente leitura compilado no OpenEdge 12.2 de TESTE e aprovado em `TOTAL=7 FALHAS=0`. A base estava sem etiquetas, portanto o código exato permanece pendente de massa. A revisão ainda não foi publicada no PASOE nem validada pela rota REST.

O segundo módulo de negócio aprovado é `fontes/progress/contr-emb-rastreio.p`. A procedure `consultarEtiquetas` lê `contr_emb_etiqueta` e o adaptador REST existente expõe `GET /etiquetas`; não foi criado um adaptador ou arquivo por rota.

## Autorização e paginação

O Dataset injeta `usuario` e uma ocorrência de `estabelecimentoPermitido` por estabelecimento autorizado. Lista vazia responde `SEM_PERMISSAO`. `codEstabel`, quando informado, precisa constar nessa lista. A consulta ordena por `id-etiqueta`, recebe `aposId`, usa limite padrão 20 e máximo 100 e devolve `proximoId` como texto.

## Filtros

- `codEstabel`
- `codEtiqueta`
- `item`
- `lote`
- `codTipo`
- `tipoControle`: `EMBALAGEM` ou `PRE_SALDO`
- `tipoLocal`: `ESTAB`, `CAMPO`, `TERCEIRO` ou `TRANSITO`
- `situacao`: `ATIVA`, `ENCERRADA`, `CANCELADA` ou `DESCARTADA`
- `idBag`: zero não filtra; positivo filtra a ocorrência

## Resposta

A projeção reúne identidade e origem, item/tipo/lote/validade, capacidade e quantidades, posição e custódia atuais, vínculo com Bag, situação, último movimento, datas, usuários e versão. IDs são textos no JSON. A leitura de `PRE_SALDO` não o transforma em embalagem individual e não cria movimento.

## Validação preparada

`testes/et02/testar-consultar-etiquetas.p` não grava banco e cobre:

1. ausência de estabelecimentos permitidos;
2. `tipoControle` inválido;
3. `tipoLocal` inválido;
4. cursor negativo;
5. limite acima de 100;
6. página atual vazia ou com massa;
7. código exato quando houver registro;
8. repetição da consulta.

Em 14/09/2026, `testes/et01/executar-validacoes-teste.p` comprovou `FONTES=9 FALHAS=0` e o teste ET-02A terminou em `TOTAL=7 FALHAS=0`. O próximo passo é compilar com `SAVE` o núcleo de rastreio e o adaptador para `EMS2/esp/api/v1`, reiniciar somente o PASOE de TESTE e validar a rota autenticada. O conversor permanece fora do REST até seu teste de rollback.


## 17/09, 15:28 — ET-02A parcial 9/0

9 casos executados passaram, zero falhas, REGISTROS_ETIQUETAS=0. Comprovados recusas de autorização/filtros/cursor/limite, consulta vazia/repetição e recusas de impressão sem permissão/ID inválido. Pendentes consulta por código exato e impressão positiva: a base consultada não apresentou etiquetas; o executor procura até 20 registros para impressão. Não comprova geração, impressão física, filtros ampliados nem REST/Dataset. Evidência transcrita do resultado informado pelo responsável: docs/entregas/evidencias/resultado_et02a_2026-09-17_152850.txt.

Nenhum fonte alterado; manter r-codes do SAVE aprovado. Próximo: testar-consultar-bags.r, somente leitura, INPUT 0 para selecionar Bag existente. Sem nova cópia/compilação ou reinício de serviço. Avanço técnico local de consultas permanece 60%; resultado sem massa positiva não fecha essa frente.


## 17/09, 15:49 — consultas com massa aprovadas (DT-074)

Quatro TXT conferidos: principal 19/0, Bag com conteúdo 16/0, Bag vazia 13/0 e etiquetas/impressão 17/0. Comprovados consulta exata, conteúdo autorizado/recusado, repetição, cursor de conteúdo, duas páginas de Bags e tipos, código exato de etiqueta, recusa PRE/geração ERRO e dados/reimpressão preservando identidade. Dez conferências de rollback aprovaram ausência dos dois tipos, dois eventos, duas Bags e quatro etiquetas. Fonte do executor da raiz coincide com o transportado. Evidências preservadas fora do pacote em docs/entregas/evidencias/consultas_massa_dt074_2026-09-17_154934/.

PENDENTE=MASSA_SEGUNDA_PAGINA_CONTEUDO apenas no relatório da Bag vazia é esperado: não existe segunda linha nesse caso. A Bag com conteúdo aprovou CURSOR_EXCLUSIVO/SEGUNDA_PAGINA. Pendências anteriores de massa Bag/etiqueta/impressão e segunda página de tipos ficam resolvidas para os cenários ABL exercitados. Não prova geração RE1001, produtor de vínculo/movimento, impressão física, REST/Dataset, autorização cruzada entre estabelecimentos, concorrência ou filtros combinados/período.

Próximo: ET-01I positivos de item/unidade e cursor de famílias. Ajustado somente testes/et01/testar-consultar-apoios.p: escolher item existente com código >=2 caracteres e preferir prefixo presente em duas famílias nativas; sem criar/alterar cadastro padrão. Fonte sincronizado com a pasta completa oficial; recompilar somente esse teste com SAVE antes do RUN .r. API/core/rastreio e o lote de 13 fontes não mudaram. Nova seleção de massa ainda aguarda compilação/execução. Tipos podem continuar registrando falta de segunda página no filtro do teste readonly; paginação desse recurso já foi aprovada com fixture DT-074.
