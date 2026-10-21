# Tela e código — widget_nw_embalagens

> Descrição do JS e da tela em 21/10/2026. **O fonte manda**: se divergir, vale `src/` e este arquivo é atualizado.
> Decisões do usuário que explicam o comportamento: `decisoes.md`.

## Tela (`view.ftl`)
- Container `#cadastro-embalagens_${instanceId}.fluig-style-guide.cadastro-embalagens`, `data-params="cadastroEmbalagens.instance()"`.
  CDN no `view.ftl`: Bootstrap Icons 1.11.3, Mulish, CSS do Tabulator 6.4.0 (`tabulator_simple`); o JS do Tabulator é carregado pelo widget.
- Cabeçalho "Tipos de Embalagens" / "Cadastre, edite, inative e consulte os tipos de embalagem." com botão **Novo** (`data-novo`).
- Uma aba só, **Tipos de Embalagens** (`data-tab`, indicador animado).
- Filtro **Tipo de Embalagem** (`data-filtro-tipo`, `FLUIGC.autocomplete`, mínimo 2 caracteres) e **Buscar** (`data-buscar`; Enter no
  filtro também busca, se o menu de sugestões estiver fechado). Vazio = busca todos. Tipo escolhido vira badge `código — descrição`
  sobre o campo (que fica `readonly`), com X para remover. Texto digitado sem escolher → toast info "Selecione um tipo na lista…".
- Tabela (`data-tabela`, Tabulator, 10 por página, ordenação local): **Descrição**, **Sigla** (`embalagens-sigla`), **Situação**
  (Ativo/Inativo) e **Ações**: interruptor de situação (`role="switch"`), Editar (`bi-pencil`) e Excluir (`bi-trash`).
- Modal `<dialog data-modal-novo>` (Novo/Editar): Descrição (até 100) e Sigla (`maxlength="3"`, 2 a 3 letras/números; na edição fica
  `readonly`, "A sigla não pode ser alterada."). Editar exige descrição diferente da atual.
- Modal `<dialog data-modal-excluir>` (`alertdialog`): "Deseja excluir <descrição (sigla)>?", Cancelar/Excluir.
- Avisos por `FLUIGC.toast` (`avisar`): sucesso "… editado/ativado/desativado/excluído com sucesso!"; `repeticao` → info "Esta gravação
  já tinha sido registrada pelo Datasul.". Erros de validação ficam no próprio modal (`data-erro`, `data-modal-alerta`).

## Arquitetura do JS
- **Funções soltas (topo)**: transporte `chamarEmbalagens` (`$.ajax` + `$.Deferred`, valida o envelope de uma linha, devolve promessa com
  `abort`); montagem de parâmetros por ação (`montar*`); `gerarChaveIdempotente` (UUID v4 com `crypto.getRandomValues`).
- **`cadastroEmbalagens`** (SuperWidget): tela, autocomplete, tabela e modais. Estado: `carregandoTipos`, `salvando`, `consultaSeq`/
  `consultasAbertas` (descarta resposta de busca antiga), `apoioSeq`/`timerApoio` (sugestões com atraso de 250 ms), `intencoes`
  (chave idempotente por intenção), `linhaEditando`, `linhaExcluindo`.
- **Busca** (`carregarTipos`): lê todas as páginas por cursor (`proximoCodigo`; cursor vazio ou repetido = erro), junta sem duplicar
  (`mesclarTiposSemDuplicacao`) e só então `setData` + `setPage(1)`. Erro → `mostrarErroCarga` (alerta na tabela + console `[cadastroEmbalagens]`).
- **Loading global** (`prepararCarregamentoGlobal`, `definirCarregamentoGlobal`, `.embalagens-carregando-global`): overlay dentro do
  widget no carregamento inicial (inclusive espera do Tabulator) e em toda busca; `aria-busy`, filtro/Buscar/Novo desabilitados;
  toast info "Carregando..." (600000 ms) único, removido 100 ms após o fim (`fadeOut` 200 ms); busca próxima cancela a remoção e reaproveita.
  Comandos e autocomplete não usam o overlay.
- **Idempotência** (`executarComando`): a chave é guardada por `acao|parametros` em `intencoes` e só é descartada no sucesso; repetir
  a mesma intenção reaproveita a chave. Resultado incerto (transporte, `FALHA_CHAMADA`, `RESPOSTA_INVALIDA`, `HTTP_*`) → "Não foi
  possível confirmar se a gravação foi concluída…" e detalhe no console. Não repetir comando automaticamente.
- **Gravação** (`salvarCadastro`, `alterarSituacao`, `confirmarExclusao`): exigem `versao` inteira vinda da consulta (senão "A versão
  deste tipo não veio da consulta…"). Sucesso aplica a resposta na linha (`aplicarFotografia`: `updateOrAddData`, reordena, mantém a
  página, rola até a linha). `TIPO_JA_EXISTE`/`CODIGO_INVALIDO` marcam o campo Sigla.
- **Interruptor**: `definirSalvando` põe `disabled` + `aria-busy`; o CSS (`.embalagens-interruptor[aria-busy="true"]`, ~linha 958) troca
  o interruptor por spinner de 18 px até o comando e a atualização da linha terminarem.

## Mapa do fonte (`widget_nw_embalagens.js`)
~870 linhas, CRLF. Pode ler por trechos (`offset`/`limit`) achando o nome com Grep: `^function <nome>`, `^var <NOME>`,
`^    <nome>\(` (métodos do SuperWidget). Linhas aproximadas (21/10/2026); o Grep manda.

| Bloco (linhas) | Nomes |
|---|---|
| Constantes (1–13) | `URL_SCRIPT_TABULATOR`, `promessaCarregamentoTabulator`, `LIMITE_CONSULTA_TIPOS`, `MENSAGENS_ERRO_CADASTRO` |
| Funções soltas (15–124) | `temResultadoGravacaoIncerto`, `obterMensagemResultado`, `escaparTextoHtml`, `formatarRotulo`, `montarConsultasTipos`, `normalizarTipoEmbalagem`, `mesclarTiposSemDuplicacao`, `montarParametrosInclusao/Alteracao/Situacao/Exclusao`, `gerarChaveIdempotente`, `chamarEmbalagens` |
| SuperWidget `cadastroEmbalagens` (126–873) | ver abaixo |

| Assunto | Métodos |
|---|---|
| Início e abas | `init`, `bindings`, `selecionarAba`, `navegarAbas`, `ativarAba`, `moverIndicador` |
| Filtro (autocomplete) | `prepararAutocompleteTipo`, `mostrarSelecionado`, `removerSelecionado`, `cancelarSugestoesTipos`, `consultarSugestoesTipos`, `obterCodigoFiltro` |
| Tabela e busca | `carregarTabulator`, `montarTabela` (colunas), `carregarTipos`, `cancelarConsultas`, `mostrarErroCarga`, `montarBotoesAcoes`, `buscar`, `teclaFiltro`, `reaplicarOrdem`, `destacarLinha` |
| Loading | `definirCarregamentoTipos`, `prepararCarregamentoGlobal`, `definirCarregamentoGlobal` |
| Comandos | `executarComando`, `aplicarFotografia`, `avisar`, `definirSalvando`, `alterarSituacao` |
| Modal Novo/Editar | `prepararModalNovo`, `abrirModalNovo`, `abrirModalEditar`, `abrirModalCadastro`, `fecharModalNovo`, `limparFormNovo`, `marcarErro`, `salvarCadastro` |
| Modal Excluir | `prepararModalExcluir`, `abrirModalExcluir`, `fecharModalExcluir`, `confirmarExclusao` |

CSS: `widget_nw_embalagens.css` (~1.075 linhas), seletores `.fluig-style-guide.cadastro-embalagens .embalagens-*`.
