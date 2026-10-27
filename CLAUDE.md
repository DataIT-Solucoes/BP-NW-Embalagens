# widget_nw_embalagens

> Regras gerais (versões, SuperWidget, Style Guide): `CLAUDE.md` da raiz do repositório. Aqui fica só o que é deste widget.
> Preencher só com o que o usuário informou ou o que está nos fontes. O que não se sabe fica "a definir".

## Objetivo
Tela **Tipos de Embalagens**: consultar, cadastrar, alterar a descrição e inativar/reativar tipos de embalagem
do Controle de Embalagens (Datasul). Fluxo e detalhes da tela: `README.md` desta pasta.

## Identificação
- `application.code`: `widget_nw_embalagens`
- Título (`application.title`): `widget_nw_embalagens` (valor gerado pela extensão)
- Versão: `0.1.1` · categoria `SYSTEM` · `application.uiwidget=true` · `application.mobileapp=false`
- Context-root: `/widget_nw_embalagens`
- Onde é usado: página `/portal/p/1/cadastro_de_embalagens` do Fluig de TESTE

## Estado atual (2026-10-07)
- Tela integrada ao Dataset central **`dsNwEmbalagens`** (modelo DT-116 recebido em
  `fluig-rest/MODELO_DATASET_UNICO_HUMBERTO_20261006/`, mantido como veio). O fonte do Dataset não fica mais neste repositório (pasta `datasets/` retirada em 27/10/2026).
- `dsNwEmbalagensTipos` (antigo, uma linha por tipo) segue publicado e intacto; a tela não o usa mais.
- `dsNwEmbalagens` **não publicado** no TESTE (conferido em 07/10 pela lista de datasets).
- Testes locais: `npm test` → só transporte (`testes/testar-chamar-embalagens.cjs`, 11/0; sem Fluig/Datasul reais).
  Testes do Dataset e da tela de tipos retirados em 27/10/2026.
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
  `ALTERAR`/`INATIVAR`). Reativar = `ALTERAR` com `ativo: true`. Excluir = `alterarTipo` com `acao: 'excluir'`:
  exclusão lógica (some das consultas; a sigla fica reservada e `incluirTipo` devolve `CODIGO_TIPO_RESERVADO`; conferido no TESTE em 26/10/2026).
- Serviço: `DATASUL_REST_HOMOLOG` (já existente; credenciais só no serviço).
- Campos de tipo: `codTipo` (texto, até 3 na API), `descricao`, `ativo` (booleano), `versao` (número), `dtInclusao`,
  `usuarioInclusao`, `dtAlteracao`, `usuarioAlteracao`.
- Configuração TESTE no Dataset: `escritasHabilitadas: ["incluirTipo", "alterarTipo"]` (aceita `true`/`false`/lista);
  `regras`: TESTE com `DefaultGroup-1` → `consultarTipos`, `incluirTipo`, `alterarTipo` (definido pelo usuário em 07/10/2026).
- `colleagueGroup` no TESTE (API REST, 07/10): filtro `colleagueGroupPK.colleagueId` funciona; colunas voltam como
  `companyId`/`groupId`/`colleagueId`. O Dataset lê o nome PK e, vazio, o curto. Dentro de Dataset publicado: não confirmado.

## Regras de negócio
- Sigla: 2 ou 3 letras/números no cadastro pela tela (como a API, ex.: `Z9R`). Imutável na edição.
- Maiúsculas na sigla: a definir (a tela envia como digitado).

## Pendências / decisões em aberto
- **Grupos (DT-054):** em TESTE está `DefaultGroup-1` (grupo padrão: na prática libera tipos para todos os usuários
  da empresa 1). Grupo definitivo por ação ainda a definir antes de produção.
- Publicar `dsNwEmbalagens` no TESTE e o `.war` do widget (com `chamar-embalagens.js`).
- No servidor: confirmar `getHttpStatusResult()`, o envio de `params` JSON (booleano/número) no POST/PATCH pelo
  serviço e os nomes de coluna do `colleagueGroup` dentro do Dataset.
- Demais telas (`widget_nw_itensComCtrllDeEmb`, `widget_nw_manutEtiq`) ainda não migradas para o `dsNwEmbalagens`.

## Entrega (commit, push e .war)
Só quando o usuário pedir, pelo comando **`/entregar "texto"`** (`.claude/commands/entregar.md`, igual ao do `widget_nw_manutEtiq`).
Ele escolhe o prefixo, roda `npm test` se o JS ou os testes mudaram e chama `scripts/entregar.ps1` (cópia do script do `widget_nw_manutEtiq`):
```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/entregar.ps1 -Mensagem "FIX: Texto" <arquivos...>
```
- Confere BOM e quebra de linha misturada nos fontes de `src/`. Se algum arquivo estiver em `src/` e o `application.info` não estiver
  na lista, sobe o patch de `application.version` e inclui o `application.info` no commit. Também roda `node --check` e gera `target/widget_nw_embalagens.war` (`pack-widget.ps1`).
- Commit só dos arquivos informados (nunca `target/`), em português, sem coautor e sempre com prefixo (`FIX`, `FEAT`, `DOCS`, `TEST`, `CHORE`…).
- Push no branch atual e conferência do remoto. `-Simular` faz tudo menos commit e push.
- Importar o `.war` no Fluig: feito pelo usuário.
