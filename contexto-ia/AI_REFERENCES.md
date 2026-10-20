# AI_REFERENCES — widget_nw_embalagens

## Fontes da verdade

| Assunto | Local | Versão / data consultada |
|---|---|---|
| Organização documental | C:/Users/DataIt/Documents/PADRAO_CONTEXTO_IA_WIDGETS.md | 2026-10-20 |
| Regras desta widget | AGENTS.md | Migradas do CLAUDE.md local anterior e confrontadas com os fontes em 2026-10-20 |
| Contexto compartilhado | C:/Users/DataIt/Documents/brancoperes2026/CLAUDE.md e skill fluig-branco-peres | 2026-10-20; resumos antigos podem divergir dos fontes |
| Widget | src/main/resources/view.ftl, src/main/webapp/resources/js/widget_nw_embalagens.js, src/main/webapp/resources/css/widget_nw_embalagens.css | Árvore local em 2026-10-20, HEAD 9b9b6d5 |
| Identificação | src/main/resources/application.info e src/main/webapp/WEB-INF/jboss-web.xml | 2026-10-20 |
| Dataset | datasets/dsNwEmbalagens.js | 2026-10-20, com alterações locais preexistentes; conferir novamente antes de integrar |
| Testes | package.json e testes/testar-chamar-embalagens.cjs | 2026-10-20; teste de Dataset também tem alteração preexistente |
| API e decisões técnicas | fluig-rest/docs/02_DECISOES_TECNICAS.md e fluig-rest/docs/entregas/MATRIZ_TELAS_CAMPOS_ACOES.md | Caminhos existentes; conteúdo completo não revisado nesta adoção |

## Descobertas confirmadas
- 2026-10-20 — src/main/resources/application.info: JS (1), CSS (2), versão 0.1.0; próximo recurso no índice 3.
- 2026-10-20 — src/main/resources/view.ftl:5: container cadastro-embalagens_${instanceId} e cadastroEmbalagens.instance(). O prefixo antigo nwe da skill não corresponde ao fonte atual.
- 2026-10-20 — src/main/resources/view.ftl:54: cadastro com maxlength="3"; descrição com máximo 100. Origem de aprovação da mudança do limite histórico de 2 não confirmada.
- 2026-10-20 — src/main/webapp/resources/js/widget_nw_embalagens.js:84: chamarEmbalagens integrado ao JS principal, $.ajax e envelope de uma linha. O antigo arquivo separado não está presente em src.
- 2026-10-20 — src/main/webapp/resources/js/widget_nw_embalagens.js:243 e :316: FLUIGC.autocomplete e consultarTiposApoio, incluindo inativos (ativo: 'todos').
- 2026-10-20 — src/main/webapp/resources/js/widget_nw_embalagens.js:32: código selecionado gera consulta exata; campo vazio consulta todos em páginas de 20, por cursor.
- 2026-10-20 — src/main/webapp/resources/js/widget_nw_embalagens.js:68 e :809: exclusão usa alterarTipo com acao: 'excluir'. Isso descreve o fonte, sem comprovar suporte/homologação da API.
- 2026-10-20 — datasets/dsNwEmbalagens.js:1: serviço DATASUL_REST_HOMOLOG, regras DefaultGroup-1, estabelecimentos 10904/11301 nas ações com recorte e escritas habilitadas além de tipos. Não usar a lista antiga de 24 ações como contrato atual.
- 2026-10-20 — datasets/ contém dsNwEmbalagens.js e um .bak; dsNwEmbalagensTipos.js não está presente. O .bak não foi consultado nem tratado como contrato vigente.

## Histórico preservado e limites
- CLAUDE.md anterior registrava testes de 07/10: Dataset 25/0, transporte 7/0 e tela 9/0, além de navegador com API simulada. Relatos históricos; não executados ou reconfirmados nesta sessão.
- Consulta de colleagueGroup por REST em 07/10 teria aceitado colleagueGroupPK.colleagueId e retornado colunas curtas companyId/groupId/colleagueId. O registro anterior deixava a execução dentro do Dataset publicado não confirmada.
- Notas antigas diziam que dsNwEmbalagens não estava publicado e que não havia exclusão. Não usar como diagnóstico atual: configuração e comportamento mudaram no fonte.
- Credenciais não devem ser copiadas para estes arquivos.

## Verificação e build
- git status --short, git diff --stat, git diff --check, git branch --show-current e git log -1: inspeção local do estado e diferenças.
- Conferência local dos caminhos de fontes citados, estrutura dos quatro arquivos e referências de continuidade; UTF-8 sem BOM e CRLF nos documentos finais.
- SHA-256 conjunto dos 83 arquivos rastreados existentes fora de CLAUDE.md/README.md, excluindo .r: a75dd11a18283c0d8be674b518b7e0f0a49d36e59078820474e2bc2cbbaa04b3. Calculado sobre mapa JSON ordenado caminho→hash; igual antes/depois da adoção.
- Hash do Dataset preexistente: 1fca73eaa71d05e20d18b3098c762058d0a2d7bef432ace9394c7d6eb1a2d7f3.
- Hash do teste de Dataset preexistente: 7fbca33fe5ed11ca2f5e60e262ffb28c0c45c58b66858c68416e567cc91c176f.
- npm test executado em 2026-10-20: Dataset 46/0, transporte 11/0, tela 28/0. Sem Fluig/Datasul reais.
- Build em 2026-10-20 com Python zipfile.ZipFile/ZIP_DEFLATED: src/main/webapp/ na raiz; src/main/resources/ em WEB-INF/classes/. Estrutura igual ao WAR anterior; testzip() sem erro e 12 arquivos iguais aos fontes. Não há fontes Java nesta widget.
- Artefato: target/widget_nw_embalagens.war; 26415 bytes; SHA-256 9b9a1700e8881ee14b8ba4250d5048961617d4bcacbfdb2ec21e728e5d778eee; ignorado pelo Git.
- Commit/push/build autorizados permanentemente em 2026-10-20. Publicação no Fluig não realizada.
