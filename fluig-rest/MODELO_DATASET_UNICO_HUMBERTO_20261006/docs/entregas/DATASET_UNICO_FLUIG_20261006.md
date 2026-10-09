# Dataset central de embalagens — orientação para Humberto / DT-116

## Decisão e alcance

Usar um único Dataset customizado é uma opção válida de arquitetura para este projeto. Não é exigência nem padrão universal da TOTVS. Funciona porque o Dataset atua como fachada de transporte/autorização com ações fechadas, enquanto as regras de negócio permanecem no ABL. A quantidade de Datasets, por si só, não determina qualidade ou segurança.

Modelo: `fontes/fluig/datasets/dsNwEmbalagens.js`. Nome proposto de publicação: **dsNwEmbalagens**. Inclui as **24 ações REST atuais: 17 consultas e 7 comandos**, inclusive consulta, inclusão, alteração/inativação e autocomplete de tipos. Não inclui rotas futuras de recebimentos, mutação de Bags, GATEC ou anulação.

O `dsNwEmbalagensTipos` enviado por Wallison já comunica com o serviço **DATASUL_REST_HOMOLOG**. Esse serviço foi aproveitado no modelo. Não recriar serviço nem mudar domínio/autenticação para instalar o novo Dataset. A implementação antiga permanece intacta; seu código recebido está preservado como referência. O Dataset central tem outro contrato de saída: migrar a chamada da tela e sua leitura juntas.

## Arquivos para abrir no Work

Pasta autossuficiente: `docs/entregas/MODELO_DATASET_UNICO_HUMBERTO_20261006`.

- `README.md`: passos de adaptação/publicação.
- `PROMPT_PARA_WORK.md`: contexto pronto para GPT/Claude do Humberto.
- `fontes/fluig/datasets/dsNwEmbalagens.js`: fonte completo ES5 do Dataset central.
- `fontes/fluig/componentes/chamar-embalagens.js`: função de transporte do Widget.
- `testes/fluig/`: testes sem Fluig/banco, por dublês locais.
- `ACOES_DATASET.json`: nomes, métodos, rotas, parâmetros e cursores extraídos do modelo.
- `docs/entregas/`: este contrato, contratos REST operacionais/cadastrais e baseline.
- `MANIFESTO.json`: hashes das cópias entregues.

Sem credenciais, r-code ou ZIP novo. Essa pasta é para desenvolvimento Fluig, não é uma árvore para sobrepor no Datasul. Nenhuma compilação ABL adicional é necessária para este modelo JavaScript; fontes ABL e hooks existentes não foram alterados.

## Configurar uma vez no servidor

1. Manter `NW_CONFIG.serviceCode = "DATASUL_REST_HOMOLOG"`, conforme o Dataset que já funciona em TESTE. Se o cadastro real mudar, ajustar somente a configuração do ambiente. Credenciais ficam nesse serviço; nunca no Widget/fonte.
2. Definir os códigos reais dos grupos e os estabelecimentos permitidos em `NW_CONFIG.regras`. Cada regra contém `grupo`, `acoes` e `estabelecimentos`. Não há grupos/estabelecimentos de negócio inventados no modelo.
3. O código consulta o Dataset **interno** `colleagueGroup` usando empresa e matrícula reais da sessão. Isso não exige criar um segundo Dataset customizado. Confere novamente empresa/matrícula nas linhas recebidas. Os campos `colleagueGroupPK.companyId`, `colleagueGroupPK.colleagueId` e `colleagueGroupPK.groupId` são documentados pela TOTVS; conferir retorno/acesso na instalação 1.8.1. Ausência ou falha nega, sem fallback para super/admin.
4. A união dos estabelecimentos usa somente as regras que concedem a ação pedida. Ter consulta em uma fazenda não concede escrita nela. Origem e destino interno também são conferidos no servidor antes da chamada.
5. Tipos e apoio de tipos são globais: precisam de autorização funcional, mas podem ter lista de estabelecimentos vazia. Demais ações exigem lista explícita. Para visão global, relacionar os estabelecimentos realmente permitidos; não usar wildcard.
6. `escritasHabilitadas` começa `false`. Após configurar o serviço e as permissões na instalação, habilitar os comandos em TESTE conforme a integração das telas. Essa chave não substitui permissão por ação; cada comando continua exigindo grupo autorizado. Não exige nova aprovação informal do projeto.

Formato de uma regra (substituir variáveis pelos valores reais, apenas na configuração de servidor):

```javascript
{
  grupo: codigoRealDoGrupo,
  acoes: ["consultarTipos", "apoiarTipos", "consultarEtiquetas"],
  estabelecimentos: codigosReaisPermitidos
}
```

Grupos, permissões e estabelecimentos não são campos de formulário nem parâmetros da chamada. O código é um modelo configurável; não publicar com regras vazias esperando acesso liberado. Se a organização já tiver um resolvedor confiável de grupos/estabelecimentos, Humberto pode adaptar `nwAutorizar` preservando este contrato e os testes de segregação. Não introduzir permissões a partir de constraints.

## Entrada única para todas as ações

O Widget informa somente:

| Constraint | Conteúdo |
|---|---|
| `acao` | Nome exato do registro `NW_ACOES`, por exemplo `consultarTipos`. |
| `parametros` | Objeto JSON textual com filtros/corpo de negócio da ação. |

Não recebe endpoint, método, headers, usuário, empresa, grupos ou lista autorizada. Campos desconhecidos, constraints repetidas e faixas são recusados. Cada ação tem lista própria de campos e obrigatórios. Validação fiscal, saldo, concorrência e efeito nativo continuam no Datasul; o Dataset não reimplementa essas regras.

Na baseline `/api/public/ecm/dataset/search`, usar `filterFields`, e não `constraints`. O nome de `acao` dentro de `parametros` de PATCH (`ALTERAR`, `INATIVAR`, `EXCLUIR`) é uma ação cadastral do ABL, distinta da constraint externa que escolhe a rota.

## Saída estável: uma linha de envelope

Dataset é tabular, mas as rotas possuem respostas distintas. Evitamos centenas de colunas vazias e perda de metadados retornando **uma linha por execução**, inclusive vazio ou erro.

| Coluna | Conteúdo |
|---|---|
| `acao` | Ação executada; vazia se a entrada não identifica uma ação válida. |
| `sucesso`, `codigoErro`, `mensagem` | Resultado funcional, com booleano textual na coluna. |
| `httpStatus` | Status HTTP do serviço Datasul; vazio quando nenhuma resposta foi obtida. |
| `total`, `temMais` | Metadados da página quando presentes; total não é total global. |
| `campoCursor`, `proximoCursor` | Nome do campo de saída da API e seu valor. |
| `repeticao` | Repetição idempotente, quando informada pela API. |
| `resultadoJson` | JSON funcional preservado, com coleções, identidades e metadados da rota. |

Ler `JSON.parse(linha.resultadoJson)`. Não confundir a linha do Dataset com uma embalagem. Na consulta de tipos, a grade usa `resultado.dados`. Em gerações, a resposta usa **geracao/itens/etiquetas**; não transformar cegamente em dados. Comandos cadastrais possuem fotografia no nível superior. Comandos operacionais possuem WT/idOperacao/repeticao. Todos permanecem acessíveis em `resultadoJson`.

`sucesso=false` nunca vira `dados=[]` de sucesso. Erros de transporte/JSON não devolvem corpo bruto ou exceção Java. Logs contêm somente ação conhecida e código controlado. Na instalação, confirmar que `getHttpStatusResult()` fornece o status; o modelo não presume sucesso quando esse dado está ausente.

## Exemplo pronto de Widget: consultar tipos

Incluir `chamar-embalagens.js` nos recursos da Widget. Não colar esse arquivo como Dataset: ele é código do navegador.

```javascript
const resultado = await chamarEmbalagens("consultarTipos", {
  descricao: textoDigitado,
  ativo: true,
  limite: 20
});
if (!resultado.sucesso) {
  exibirErro(resultado.codigoErro, resultado.mensagem);
  return;
}
renderizarTipos(resultado.dados);
// Mais resultados: mesma acao/filtros com aposCodigo: resultado.proximoCodigo.
```

O helper efetua um POST para o transporte de Dataset do Fluig; a ação selecionada efetua **GET** na API Datasul. `limit: "1"` no transporte significa uma linha de envelope, enquanto `parametros.limite: 20` limita os tipos no Datasul. Não trocar esses dois limites.

Chamada sem helper, equivalente:

```javascript
const resposta = await fetch("/api/public/ecm/dataset/search", {
  method: "POST",
  credentials: "same-origin",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    datasetId: "dsNwEmbalagens",
    filterFields: ["acao", "consultarTipos", "parametros", JSON.stringify({ limite: 20 })],
    resultFields: [], limit: "1", orderBy: ""
  })
});
```

## Tipos: todas as ações incluídas

| Ação externa | Método/rota | Parâmetros de negócio |
|---|---|---|
| `consultarTipos` | GET /tipos | codigoDe, codigoAte, descricao, ativo, aposCodigo, limite. |
| `apoiarTipos` | GET /apoios/tipos | filtro, ativo, aposCodigo, limite; teto20/min2caracteres. |
| `incluirTipo` | POST /tipos | codTipo, descricao, ativo, versao opcional0, chaveIdempotente. |
| `alterarTipo` | PATCH /tipos | codTipo, descricao, ativo, versao lida, acao ALTERAR/INATIVAR, chaveIdempotente. |

Exemplo de inclusão, sem valores de teste chumbados:

```javascript
const resultado = await chamarEmbalagens("incluirTipo", {
  codTipo: formulario.codTipo,
  descricao: formulario.descricao,
  ativo: formulario.ativo,
  versao: 0,
  chaveIdempotente: chaveDaIntencao
});
```

Alteração usa `alterarTipo` com `acao: "ALTERAR"` ou `"INATIVAR"`, fotografia exigida e versão recebida. Não enviar uma nova chave em retry. Usuário é injetado pelo Dataset.

## Demais ações

`ACOES_DATASET.json` é o mapa completo dos 24 nomes para métodos/rotas/filtros/cursor. Fonte e testes confrontam o registro com o adaptador ABL. Não criar action genérica `executarUrl`.

Consultas: consultarParametros, consultarEtiquetas, apoiarEstabelecimentos, apoiarItens, apoiarFamilias, consultarBags, consultarConteudoBag, obterDadosImpressao, consultarGeracao, classificarNatureza, consultarEmbalagensOrigem, consultarOperacoes, consultarResultadoOperacao, consultarItensOperacao, consultarEventosOperacao.

Comandos adicionais: incluirParametro, alterarParametro, criarTransferencia, criarRemessa, criarDevolucao. Contratos exatos em ET-01G_API_REST_CADASTROS.md e REST_FLUXOS_ABL_20261006.md. O comando não calcula/atualiza/cancela NF. Parâmetros `loteMigracao` e `validadeMigracao` já previstos no adaptador são transportados quando aplicáveis; não omitir a integração com conversão.

IDs/versões de seleção operacionais são textos canônicos, por exemplo a `versao` de cada objeto da seleção. **Exceção do contrato cadastral vigente:** `idParam` e `versao` no corpo de tipos/parâmetros usam números JSON porque o adaptador usa GetInteger. Não mudar esse contrato no Dataset nem converter indiscriminadamente todos os códigos para Number. Número de documento/série preservam zeros. Quantidade/capacidade/valor são números JSON; quantidade de seleção preserva até quatro casas. O ABL é autoridade para limites funcionais e elegibilidade.

## Paginação e concorrência

Cada GET traz somente uma página. O modelo não percorre 50 páginas ou devolve truncamento como sucesso. O Widget mantém filtros e informa o cursor correto na próxima chamada. `campoCursor` é o nome de saída (`proximoCodigo`/`proximoId`); o nome de entrada consta no catálogo (`aposCodigo`/`aposId`/**aposIdEtiqueta** para embalagens de origem). Não usar cursor por índice/offset.

Autocomplete: mínimo2caracteres, debounce350ms, até20opções, cancelar/ignorar resposta antiga, limpar dependentes ao trocar estabelecimento/item. Não carregar todo o cadastro. Bag/conteúdo têm teto20; tipos/parâmetros/etiquetas/operações têm teto100 no registro. Resultado por chave e classificação não precisam de paginação na entrada.

Em comandos, chave identifica a intenção e versão identifica a fotografia. Uma única invocação por clique; desabilitar botão enquanto aguarda. Sem retry automático por falha de rede. Em resultado incerto de preparação de WT, consultar `consultarResultadoOperacao` com mesma chave/contexto/ramo; se necessário repetir o mesmo comando/conteúdo/chave. Não trocar a chave porque houve timeout. Abort de fetch na Widget não prova que a transação do servidor foi desfeita. ABL continua sendo responsável pela idempotência e atomicidade.

## Adaptação e publicação em TESTE

1. Abrir a pasta no Work; ler PROMPT_PARA_WORK.md e este guia.
2. Configurar os grupos reais e conferir os campos do colleagueGroup; conservar o serviço já funcional. Não precisa inventar outro intermediário customizado.
3. Publicar o novo Dataset com o nome combinado `dsNwEmbalagens`, sem sincronização/agendamento/mobile e sem substituir `dsNwEmbalagensTipos`.
4. Integrar uma chamada real da tela de tipos usando o helper. Migrar a renderização para resultado.dados; a versão antiga tinha uma linha por tipo.
5. Ligar demais telas às ações do catálogo conforme evoluírem. Habilitar comandos na configuração TESTE e conferir o envio de JSON/arrays/booleanos/decimais por params no serviço instalado, sobretudo PATCH e seleção. GET já funcionando não prova essa serialização.
6. Validar autorização no Dataset mesmo com botão oculto. Não cadastrar o Dataset central como fonte de Zoom ou sincronização que reexecute comandos ao listar/atualizar.

Não repetir toda a bateria fiscal já aceita para provar o transporte. Testes locais fornecidos verificam o modelo; confirmar apenas os pontos novos de integração na instalação e tratar falhas pontualmente. Os candidatos fiscais aprovados permanecem intactos. Não copiar pacote Datasul inteiro nem alterar/recompilar hooks para publicar JavaScript Fluig.

## Referências e limites

Baseline local: docs/00_BASELINE_REST_FLUIG_DATASUL_v1.0.docx. Modelo de serviço usa o invoke confirmado no Dataset recebido e params/options JSON documentados pela [TOTVS — client REST](https://tdn.totvs.com/pages/viewpage.action?pageId=239041233). Grupos usam os campos descritos em [TOTVS — Datasets internos](https://tdn.totvs.com/display/fluig/Datasets%2Binternos). Documentação consultada em06/10/2026 não substitui a verificação da instalação Silver Mist1.8.1/build137.

Código/testes são modelo de desenvolvimento, não prova de publicação Fluig. Faltam os códigos reais de grupos, a configuração da política e a migração das chamadas das telas. Não falta criar 24 Datasets nem reescrever as regras ABL.
