# widget_nw_embalagens

> Regras gerais (versões, SuperWidget, Style Guide): `CLAUDE.md` da raiz do repositório. Aqui fica só o que é deste widget.
> Preencher só com o que o usuário informou ou o que está nos fontes. O que não se sabe fica "a definir".

## Objetivo
Tela **Tipos de Embalagens**: consultar, cadastrar, alterar a descrição e inativar/reativar tipos de embalagem
do Controle de Embalagens (Datasul). Fluxo e detalhes da tela: `README.md` desta pasta.

## Identificação
- `application.code`: `widget_nw_embalagens`
- Título (`application.title`): `widget_nw_embalagens` (valor gerado pela extensão)
- Versão: `0.1.0` · categoria `SYSTEM` · `application.uiwidget=true` · `application.mobileapp=false`
- Context-root: `/widget_nw_embalagens`
- Onde é usado: página `/portal/p/1/cadastro_de_embalagens` do Fluig de TESTE

## Estado atual (2026-10-07)
- Tela integrada ao Dataset central **`dsNwEmbalagens`** (modelo DT-116 recebido em
  `fluig-rest/MODELO_DATASET_UNICO_HUMBERTO_20261006/`, mantido como veio). Fonte do projeto: `datasets/dsNwEmbalagens.js`.
- `dsNwEmbalagensTipos` (antigo, uma linha por tipo) segue publicado e intacto; a tela não o usa mais.
- `dsNwEmbalagens` **não publicado** no TESTE (conferido em 07/10 pela lista de datasets).
- Testes locais: `npm test` → Dataset 25/0, transporte 7/0, tela de tipos 9/0 (sem Fluig/Datasul reais).
  Tela também conferida no navegador com Fluig/API simulados (busca, cursor, inclusão, duplicidade, edição,
  falha incerta com mesma chave, inativar/reativar).

## Recursos declarados no `application.info`
| Índice | Tipo | Valor |
|---|---|---|
| 1 | js | `/resources/js/widget_nw_embalagens.js` |
| 2 | css | `/resources/css/widget_nw_embalagens.css` |
| 3 | js | `/resources/js/chamar-embalagens.js` (função `chamarEmbalagens`, global) |

Próximo índice livre: 4

## Dados
- Dataset: `dsNwEmbalagens` (customizado, sem sincronização). Entrada `filterFields`: `acao` + `parametros` (JSON).
  Saída: uma linha; `resultadoJson` = envelope da API.
- Ações usadas pela tela: `consultarTipos` (GET /tipos), `incluirTipo` (POST /tipos), `alterarTipo` (PATCH /tipos,
  `ALTERAR`/`INATIVAR`). Reativar = `ALTERAR` com `ativo: true`. A API de tipos não tem exclusão.
- Serviço: `DATASUL_REST_HOMOLOG` (já existente; credenciais só no serviço).
- Campos de tipo: `codTipo` (texto, até 3 na API), `descricao`, `ativo` (booleano), `versao` (número), `dtInclusao`,
  `usuarioInclusao`, `dtAlteracao`, `usuarioAlteracao`.
- Configuração TESTE no Dataset: `escritasHabilitadas: ["incluirTipo", "alterarTipo"]` (aceita `true`/`false`/lista);
  `regras: []`.
- `colleagueGroup` no TESTE (API REST, 07/10): filtro `colleagueGroupPK.colleagueId` funciona; colunas voltam como
  `companyId`/`groupId`/`colleagueId`. O Dataset lê o nome PK e, vazio, o curto. Dentro de Dataset publicado: não confirmado.

## Regras de negócio
- Sigla: até 2 caracteres no cadastro pela tela (decisão de tela; a API aceita até 3, ex.: `Z9R`). Imutável na edição.
- Maiúsculas na sigla: a definir (a tela envia como digitado).

## Pendências / decisões em aberto
- **Grupos (DT-054):** códigos reais dos grupos Fluig que consultam/mantêm tipos. Preencher `NW_CONFIG.regras` em
  `datasets/dsNwEmbalagens.js`, ex.: `{ grupo: <código real>, acoes: ["consultarTipos","incluirTipo","alterarTipo"], estabelecimentos: [] }`.
  Sem isso tudo é negado (`AUTORIZACAO_NAO_CONFIGURADA`).
- Publicar `dsNwEmbalagens` no TESTE e o `.war` do widget (com `chamar-embalagens.js`).
- No servidor: confirmar `getHttpStatusResult()`, o envio de `params` JSON (booleano/número) no POST/PATCH pelo
  serviço e os nomes de coluna do `colleagueGroup` dentro do Dataset.
- Demais telas (`widget_nw_itensComCtrllDeEmb`, `widget_nw_manutEtiq`) ainda não migradas para o `dsNwEmbalagens`.
