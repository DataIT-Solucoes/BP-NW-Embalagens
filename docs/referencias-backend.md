# Referências de dados e backend — widget_nw_embalagens

> Onde está a verdade e o que já foi levantado nos fontes, para não reler tudo de novo.
> Ao levantar algo novo no Dataset ou na API, registrar aqui com a data e o arquivo:linha.

## Contrato usado pela tela (Dataset `dsNwEmbalagens`)
- Cadeia: Widget → `chamarEmbalagens(acao, parametros)` → `POST /api/public/ecm/dataset/search` (`dsNwEmbalagens`) → serviço
  `DATASUL_REST_HOMOLOG` → `/dts/datasul-rest/resources/prg/esp/v1/controle-embalagens`.
- Transporte: `filterFields` com `acao` e `parametros` (JSON); resposta de **uma linha** com o envelope em `resultadoJson`
  (`sucesso` tem de bater com o da linha). O `limit` de transporte é `"1"`; o limite de negócio é outro parâmetro.
- Fonte da verdade: `dsNwEmbalagens.js` do GitHub **`DataIT-Solucoes/BP-NW-DATASET`** (decisão do usuário, 19/10). A cópia local
  `datasets/` foi removida a pedido do usuário (27/10). Conferir `NW_CONFIG`,
  `NW_ACOES` e `NW_COLUNAS` antes de mudar integrações; não editar o Dataset sem pedido.
- Identidade, empresa, grupos e estabelecimentos autorizados são resolvidos no Dataset, nunca no navegador.

| Operação | Ação e parâmetros usados pela tela |
|---|---|
| Autocomplete de tipo | `consultarTiposApoio`: `filtro`, `ativo: 'todos'` (inclui inativos), `limite: 20` |
| Buscar selecionado | `consultarTipos`: `codigoDe` = `codigoAte` = código, `limite: 1` |
| Buscar todos | `consultarTipos`: `limite: 20` e cursor `aposCodigo` = `proximoCodigo` enquanto `temMais` (lê todas as páginas) |
| Cadastrar | `incluirTipo`: `codTipo`, `descricao`, `ativo: true`, `versao: 0`, `chaveIdempotente` |
| Editar | `alterarTipo`: `codTipo`, `descricao`, `ativo`, `versao` (número), `acao: 'ALTERAR'`, `chaveIdempotente` |
| Inativar / reativar | `alterarTipo`: `ativo` invertido, `acao: 'INATIVAR'` (ou `'ALTERAR'` ao reativar) |
| Excluir (no fonte) | `alterarTipo` com `acao: 'excluir'`. Descreve o fonte; suporte/homologação na API não confirmados |

- Campos de tipo usados: `codTipo`, `descricao`, `ativo`, `versao`. Apoio: `codigo`, `descricao`. Resposta de comando: `sucesso`,
  `codigoErro`, `mensagem`, `repeticao` e o tipo gravado (aplicado na linha).
- Códigos com texto próprio (`MENSAGENS_ERRO_CADASTRO`): `AUTORIZACAO_NAO_CONFIGURADA`, `SEM_PERMISSAO`, `ESCRITA_DESABILITADA`,
  `CODIGO_INVALIDO`, `TIPO_JA_EXISTE`, `CONFLITO_VERSAO`. Resultado incerto: `FALHA_CHAMADA`, `RESPOSTA_INVALIDA`, `HTTP_*`.

## Descobertas (20/10/2026)
- `datasets/dsNwEmbalagens.js:1` (cópia local, removida em 27/10): serviço `DATASUL_REST_HOMOLOG`, regras `DefaultGroup-1`, estabelecimentos 10904/11301 nas ações com
  recorte e escritas habilitadas além de tipos. Não usar a lista antiga de 24 ações como contrato atual.
- O transporte está no JS principal; não há `chamar-embalagens.js` separado registrado no `application.info`.
- Consulta de `colleagueGroup` por REST em 07/10 teria aceitado `colleagueGroupPK.colleagueId` e devolvido `companyId/groupId/colleagueId`;
  execução dentro do Dataset publicado não confirmada.
- Notas antigas ("Dataset não publicado", "sem exclusão") são históricas: o fonte mudou.

## Fontes da verdade
| O quê | Onde |
|---|---|
| Widget | repositório deste widget (`git remote -v`), branch `main` |
| Dataset publicado | `https://github.com/DataIT-Solucoes/BP-NW-DATASET` → `dsNwEmbalagens.js` |
| Testes | `package.json` + `testes/*.cjs` (dois deles ainda leem `datasets/`, removida: ver `pendencias.md`) |
| API e decisões técnicas | `fluig-rest/docs/02_DECISOES_TECNICAS.md` (`grep -n "^## DT-"`) e `fluig-rest/docs/entregas/MATRIZ_TELAS_CAMPOS_ACOES.md` (não revisados por inteiro) |
| Contexto compartilhado | `CLAUDE.md` da raiz e skill local `.claude/skills/fluig-branco-peres/` |

## Verificação e build
- `npm test` (Node): `testar-dataset-unico.cjs`, `testar-chamar-embalagens.cjs`, `testar-tela-tipos.cjs`, com `jquery-falso.cjs`; sem Fluig/Datasul
  reais. Em 20/10: Dataset 46/0, transporte 11/0, tela 33/0 (90). Registro de 07/10: 25/0, 7/0, 9/0.
- WAR: `src/main/webapp/` na raiz e `src/main/resources/` em `WEB-INF/classes/` (sem Java). Em 20/10: `target/widget_nw_embalagens.war`,
  12 entradas, 26835 bytes, SHA-256 `b225822532bdc9482cadb895fe3059119ccba9bd76142292369cdecbe1a99801`. Hoje: `scripts/entregar.ps1`.
- Hashes das alterações locais preexistentes (20/10): Dataset `1fca73eaa71d05e20d18b3098c762058d0a2d7bef432ace9394c7d6eb1a2d7f3`;
  teste de Dataset `7fbca33fe5ed11ca2f5e60e262ffb28c0c45c58b66858c68416e567cc91c176f`. Ficam fora dos commits até decisão do usuário.

## Loading global — referência do `widget_nw_bags` (lida em 20/10, HEAD 779c152)
Resumo do que foi estudado para aplicar aqui (linhas relativas aos fontes do bags naquela data):
- Overlay `$carregandoGlobal` criado com jQuery dentro de `this.DOM` (`role="status"`, `aria-live`, spinner, texto `sr-only`); container
  `position: relative`; overlay `inset: 0`, `z-index: 50`, fundo translúcido; cobre só o widget e intercepta cliques.
- Ativo = carregando tela || comando || preparando modal; marca `aria-busy`. Não é contador genérico de AJAX. O overlay não substitui
  o bloqueio dos controles.
- Toast info "Carregando..." (timeout 600000 ms), único; sai 100 ms depois do fim (`fadeOut` 200 ms), o que permite reaproveitar entre
  operações próximas. `avisar` move o `#toaster` para dentro do `<dialog>` aberto e o devolve ao `body` no `close`.
- Adaptar com classes e `this.DOM` deste widget e jQuery; não copiar nomes, regras de negócio nem `async/await` do bags.
