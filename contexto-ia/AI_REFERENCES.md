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

## Loading global e toast info — referência da widget bags (2026-10-20)

Fonte consultada somente para leitura: C:/Users/DataIt/Documents/brancoperes2026/wcm/widget/widget_nw_bags, HEAD 779c152. JS e CSS sem alterações rastreadas naquele momento; havia apenas debug.log não rastreado. O pedido foi aprender o funcionamento; não autoriza aplicar mudanças na interface de embalagens.

- JS principal: src/main/webapp/resources/js/widget_nw_bags.js; CSS: src/main/webapp/resources/css/widget_nw_bags.css. Linhas abaixo relativas a esses fontes.
- JS:742–747: cria $carregandoGlobal via jQuery, dentro de this.DOM, inicialmente hidden, com role="status", aria-live="polite", spinner aria-hidden e texto sr-only. Inicia definirCarregando(true); falha ao carregar Tabulator desliga o estado.
- CSS:26, :957 e :973: container .nwb com position: relative; overlay absoluto inset: 0, z-index: 50, flex centralizado, fundo rgba(247,245,238,0.72), cursor progress; [hidden] recebe display: none. Cobre o widget, não a página inteira, e intercepta cliques. Spinner circular 48×48, borda 5 px branca com trecho na cor principal, rotação contínua de 1 s.
- JS:1788: definirCarregando altera carregandoTela, desabilita Buscar/Novo e recalcula o overlay. JS:1795: ativo = carregandoTela || comandoEmAndamento || preparandoModal; altera hidden e aria-busy do widget e chama atualizarAvisoCarregando. Não é um contador genérico de requisições AJAX.
- JS:3173: bloquearComando registra o disabled anterior dos controles, bloqueia-os e depois restaura os estados; atualiza aria-busy dos dialogs e o overlay. O overlay sozinho não substitui bloqueios de controles e guardas de execução.
- JS:1809: atualizarAvisoCarregando limpa o timer anterior. Quando ativo, cria somente um aviso "Carregando..." com type: "info", timeout: 600000 ms, se não existir aviso genérico nem $avisoCriando. Ao encerrar, aguarda 100 ms, chama removerAviso e zera a referência. O atraso permite reaproveitar o aviso entre operações próximas.
- JS:1594: avisar(mensagem, tipo, timeout) chama FLUIGC.toast com title vazio e timeout opcional; retorna o último #toaster .alert para remoção antecipada. Sem FLUIGC.toast, retorna jQuery vazio.
- Ainda em avisar: procura o último dialog[open] desta instância e move o #toaster para dentro dele; o modal nativo está na camada superior do navegador, que z-index não supera. No evento close, devolve o toaster ao body se ele ainda pertencer àquele dialog.
- JS:1614: removerAviso usa stop(true).fadeOut(200) e depois remove o elemento. A remoção começa 100 ms após o fim no caso do aviso genérico; a animação dura mais 200 ms.
- JS:2414–2436: na criação, valida com o modal aberto; fecha-o antes do comando e mostra "Criando bag..." (info, 600000 ms). Não cria simultaneamente o toast genérico enquanto $avisoCriando existir. Mantém o aviso até preparar/abrir o Inserir; remove e limpa a referência tanto no sucesso como no catch.
- JS:2514 e :2745: históricos e Inserir preparam dados com preparandoModal ativo e abrem prontos. Inserir abre temporariamente invisível (is-preparando) para calcular a tabela; finally limpa a classe e o estado e recalcula o loading.
- Escopo de eventual adaptação: usar classes e this.DOM da widget embalagens, APIs jQuery e seus fluxos reais. Não copiar nomes, regras de negócio ou async/await do bags automaticamente.
- Verificação desta leitura: inspeção estática dos fontes. Comportamento no Fluig e entre múltiplas widgets/modais simultâneos não confirmado nesta sessão.

## Aplicação no carregamento inicial de embalagens — 2026-10-20

- Pedido posterior autorizou aplicar o padrão ao carregamento inicial. O registro acima de “somente aprender” descreve a tarefa anterior.
- JS principal: init chama iniciarCarregamentoInicial antes de carregar o Tabulator. Cria overlay por instância com jQuery, role=status, aria-live e texto acessível; marca aria-busy e desabilita o filtro. Buscar/Novo seguem definirCarregamentoTipos.
- finalizarCarregamentoInicial é chamado ao encerrar definirCarregamentoTipos(false), tanto após consulta/renderização completas como no erro. Esconde o overlay, libera o filtro e aria-busy e remove apenas o toast capturado (info, timeout 600000 ms), após 100 ms e fadeOut de 200 ms.
- No fluxo inicial não aparece simultaneamente o spinner da tabela; buscas posteriores conservam seu comportamento. Não foi estendido o loading global aos comandos ou modais.
- CSS: container passa a position: relative; .embalagens-carregando-global cobre a widget com inset:0, z-index:50 e fundo translúcido; reutiliza o spinner existente e respeita hidden.
- npm test: Dataset 46/0, transporte 11/0, tela 31/0 (88 cenários). Os três novos cenários verificam espera pela biblioteca/páginas/renderização, limpeza em falha da biblioteca e em falha da consulta; também verificam o tempo do toast e que buscas posteriores não reativam o overlay inicial.
- Verificação no Fluig: não confirmada; nenhuma publicação realizada.

## Loading global também ao Buscar — 2026-10-20

- Pedido posterior substituiu a limitação ao carregamento inicial. A descrição da seção anterior corresponde à entrega 3bf6ce3.
- prepararCarregamentoGlobal cria o overlay uma vez no init. definirCarregamentoTipos agora chama definirCarregamentoGlobal em todas as consultas, ativando hidden/aria-busy/bloqueio do filtro e o toast info. O spinner interno da tabela foi retirado do fluxo de consulta.
- O fim é determinado pela renderização de todas as páginas (setData/setPage) ou pelo tratamento de erro, preservando as guardas de sequenciaConsulta. Autocomplete e comandos não foram ampliados nesta tarefa.
- O toast usa timeout 600000 ms e remoção controlada: 100 ms após encerrar, fadeOut de 200 ms. Nova busca cancela a remoção pendente e reutiliza a referência, evitando duplicação/piscadas; após remoção completa, a próxima busca cria um novo aviso.
- npm test: Dataset 46/0, transporte 11/0, tela 33/0, total 90. Verificados loading na busca após início concluído, erro posterior e reuso/cancelamento do timer em buscas próximas, além dos cenários anteriores de paginação e renderização.
- Validação visual no Fluig ainda não confirmada; nenhuma publicação realizada.
