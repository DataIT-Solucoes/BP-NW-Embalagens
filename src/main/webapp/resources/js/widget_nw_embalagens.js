// Tabulator (tabela) vem do CDN. Carregado uma vez só, mesmo com várias instâncias do widget na página.
var NWE_TABULATOR_JS = 'https://cdnjs.cloudflare.com/ajax/libs/tabulator/6.4.0/js/tabulator.min.js';
var nweTabulatorPromise = null;

// Tipos vêm do Dataset central dsNwEmbalagens (fonte em datasets/dsNwEmbalagens.js) pela função
// chamarEmbalagens, definida neste arquivo. A busca percorre os cursores antes de paginar na tela.
// NWE_LIMITE_PAGINA é o limite de NEGÓCIO enviado à API (máx. 100). O limit "1" do transporte fica em chamarEmbalagens.
var NWE_LIMITE_PAGINA = 20;

// Mensagens da tela para os códigos mais comuns; os demais usam a mensagem devolvida pelo Dataset/API.
var NWE_MENSAGENS = {
    AUTORIZACAO_NAO_CONFIGURADA: 'O acesso a esta tela ainda não foi configurado no Fluig (grupos e permissões).',
    SEM_PERMISSAO: 'Você não tem permissão para esta ação.',
    ESCRITA_DESABILITADA: 'A gravação ainda não está habilitada para esta ação.',
    CODIGO_INVALIDO: 'Informe um código válido',
    TIPO_JA_EXISTE: 'Já existe um tipo de embalagem com esta sigla.',
    CONFLITO_VERSAO: 'Este tipo foi alterado por outra pessoa depois que a lista foi carregada. Clique em Buscar para recarregar e tente de novo.'
};

// Falhas em que um comando pode ter sido gravado sem a tela saber (rede, HTTP, resposta ilegível).
function nweResultadoIncerto(codigoErro) {
    return codigoErro === 'FALHA_CHAMADA' || codigoErro === 'RESPOSTA_INVALIDA' ||
        codigoErro === 'HTTP_STATUS_INDISPONIVEL' || /^HTTP_/.test(codigoErro || '');
}

function nweMensagem(resultado, padrao) {
    return NWE_MENSAGENS[resultado.codigoErro] || resultado.mensagem || padrao;
}

// Seleção do autocomplete consulta somente o código exato; vazio percorre todos os tipos.
function nweConsultasTipos(codigo, cursor) {
    if (codigo) return [{ codigoDe: codigo, codigoAte: codigo, limite: 1 }];
    var parametros = { limite: NWE_LIMITE_PAGINA };
    if (cursor) parametros.aposCodigo = cursor;
    return [parametros];
}

function nweLinhaTipo(tipo) {
    return { codTipo: tipo.codTipo, descricao: tipo.descricao, ativo: tipo.ativo === true, versao: tipo.versao };
}

// código exato primeiro, sem repetir o que a página por descrição também trouxe
function nweMesclarTipos(porDescricao, exatos) {
    var vistos = {};
    var unicos = $.grep((exatos || []).concat(porDescricao || []), function (tipo) {
        if (vistos[tipo.codTipo]) return false;
        vistos[tipo.codTipo] = true;
        return true;
    });
    return $.map(unicos, nweLinhaTipo);
}

// Corpos de comando no contrato cadastral vigente: versao numérica (GetInteger no ABL), ativo booleano.
// Usuário e chave NÃO entram aqui: o usuário é injetado pelo Dataset e a chave pela intenção.
function nweParametrosInclusao(sigla, descricao) {
    return { codTipo: sigla, descricao: descricao, ativo: true, versao: 0 };
}

function nweParametrosAlteracao(tipo, descricao) {
    return { codTipo: tipo.codTipo, descricao: descricao, ativo: tipo.ativo, versao: Number(tipo.versao), acao: 'ALTERAR' };
}

// Inativar usa INATIVAR; reativar é ALTERAR com ativo = true.
function nweParametrosSituacao(tipo) {
    return {
        codTipo: tipo.codTipo, descricao: tipo.descricao, ativo: !tipo.ativo,
        versao: Number(tipo.versao), acao: tipo.ativo ? 'INATIVAR' : 'ALTERAR'
    };
}

// Exclusão preparada no PATCH /tipos; implementação da ação no servidor ainda pendente.
function nweParametrosExclusao(tipo) {
    return {
        codTipo: tipo.codTipo, descricao: tipo.descricao, ativo: tipo.ativo,
        versao: Number(tipo.versao), acao: 'excluir'
    };
}

// UUID v4 com getRandomValues: crypto.randomUUID só existe em HTTPS e o Fluig de teste é HTTP.
// (API de criptografia do navegador: não há equivalente no jQuery.)
function nweNovaChave() {
    var bytes = new Uint8Array(16);
    window.crypto.getRandomValues(bytes);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    var hex = $.map(bytes, function (b) { return (b + 0x100).toString(16).slice(1); }).join('');
    return hex.slice(0, 8) + '-' + hex.slice(8, 12) + '-' + hex.slice(12, 16) + '-' + hex.slice(16, 20) + '-' + hex.slice(20);
}

// Transporte para dsNwEmbalagens: uma linha de envelope JSON, sem repeticao automatica.
// Promise jQuery com .abort() para cancelar consultas.
function chamarEmbalagens(acao, parametros) {
    if (typeof acao !== "string" || !acao || !$.isPlainObject(parametros)) {
        return $.Deferred().reject(new Error("Informe acao e parametros de negocio.")).promise();
    }
    var xhr = $.ajax({
        url: "/api/public/ecm/dataset/search",
        type: "POST",
        contentType: "application/json",
        dataType: "json",
        data: JSON.stringify({
            datasetId: "dsNwEmbalagens",
            filterFields: ["acao", acao, "parametros", JSON.stringify(parametros)],
            resultFields: [], limit: "1", orderBy: ""
        })
    });
    var resultado = xhr.then(function (transporte) {
        if (!transporte || !Array.isArray(transporte.content) || transporte.content.length !== 1) {
            throw new Error("Dataset fora do contrato de uma linha de envelope.");
        }
        var linha = transporte.content[0];
        if (linha.acao && linha.acao !== acao) throw new Error("Acao da resposta divergente.");
        var envelope;
        try { envelope = JSON.parse(linha.resultadoJson); }
        catch (erro) { throw new Error("Envelope JSON do Dataset invalido."); }
        if (!envelope || typeof envelope.sucesso !== "boolean" ||
            String(envelope.sucesso) !== String(linha.sucesso)) {
            throw new Error("Resultado funcional do Dataset invalido.");
        }
        // Recusas funcionais retornam sucesso=false/codigoErro; nao viram lista vazia.
        // Preserva geracao/itens/etiquetas, classificacao de natureza, WT e repeticao.
        return envelope;
    }, function (jqXHR, textStatus) {
        if (textStatus === "abort") throw new Error("Chamada cancelada.");
        if (textStatus === "parsererror") throw new Error("O Fluig nao retornou JSON valido.");
        throw new Error("Falha HTTP " + jqXHR.status + " no transporte Fluig.");
    });
    resultado.abort = function () { xhr.abort(); };
    return resultado;
}

var widget_nw_embalagens = SuperWidget.extend({

    //aba atualmente selecionada
    abaAtual: 'tipos-embalagem',

    //instância do Tabulator
    tabela: null,

    carregandoTipos: true,
    salvando: false,

    //controle das consultas da busca atual
    consultaSeq: 0,
    consultasAbertas: null,

    autocompleteTipo: null,
    tipoSelecionado: null,
    consultaApoio: null,
    timerApoio: null,
    apoioSeq: 0,
    menuAutocompleteAberto: false,

    //chave idempotente por intenção (ação + conteúdo); criado no init para não ser compartilhado entre instâncias
    intencoes: null,

    //linha do Tabulator em edição (null = modal em modo "novo")
    linhaEditando: null,
    linhaExcluindo: null,

    //método iniciado quando a widget é carregada
    init() {
        var self = this;
        this.intencoes = {};
        this.consultasAbertas = [];
        this.definirCarregamentoTipos(true);
        this.prepararAutocompleteTipo();
        this.$tabs = $('.nwe-tabs', this.DOM);
        this.moverIndicador();
        $(window).on('resize.nwe' + this.instanceId, function () { self.moverIndicador(); });
        //a fonte Mulish chega depois e muda a largura da aba: medir de novo
        //(API de fontes do navegador: não há evento equivalente no jQuery)
        if (document.fonts && document.fonts.ready) {
            document.fonts.ready.then(function () { self.moverIndicador(); });
            $(document.fonts).on('loadingdone', function () { self.moverIndicador(); });
        }

        this.carregarTabulator().then(function () {
            self.montarTabela();
        }, function () {
            $('[data-tabela]', self.DOM).html('<p class="nwe-tabela-erro">Não foi possível carregar a tabela. Verifique a conexão com a internet e recarregue a página.</p>');
            self.definirCarregamentoTipos(false);
        });

        this.prepararModalNovo();
        this.prepararModalExcluir();
    },

    //BIND de eventos
    bindings: {
        local: {
            'tab': ['click_selecionarAba', 'keydown_navegarAbas'],
            'buscar': ['click_buscar'],
            'filtro-tipo': ['keydown_teclaFiltro'],
            'novo': ['click_abrirModalNovo'],
            'fechar-modal': ['click_fecharModalNovo'],
            'fechar-excluir': ['click_fecharModalExcluir']
        },
        global: {}
    },

    selecionarAba(htmlElement, event) {
        this.ativarAba($(htmlElement));
    },

    //setas/Home/End movem o foco entre as abas (padrão WAI-ARIA)
    navegarAbas(htmlElement, event) {
        var abas = this.$tabs.find('.nwe-tab');
        var i = abas.index(htmlElement);
        var destino = null;

        if (event.key === 'ArrowRight') destino = (i + 1) % abas.length;
        else if (event.key === 'ArrowLeft') destino = (i - 1 + abas.length) % abas.length;
        else if (event.key === 'Home') destino = 0;
        else if (event.key === 'End') destino = abas.length - 1;
        if (destino === null) return;

        event.preventDefault();
        this.ativarAba(abas.eq(destino));
        abas.eq(destino).trigger('focus');
    },

    ativarAba($aba) {
        this.$tabs.find('.nwe-tab')
            .removeClass('is-active').attr({ 'aria-selected': 'false', tabindex: '-1' });
        $aba.addClass('is-active').attr({ 'aria-selected': 'true', tabindex: '0' });
        this.abaAtual = $aba.data('aba');
        this.moverIndicador();
    },

    moverIndicador() {
        var $ativa = this.$tabs.find('.nwe-tab.is-active');
        if (!$ativa.length) return;
        this.$tabs.find('.nwe-tabs-indicador').css({
            width: $ativa.outerWidth() + 'px',
            transform: 'translateX(' + $ativa.position().left + 'px)'
        });
    },

    // ---------- Filtro: autocomplete Fluig, uma única seleção ----------

    prepararAutocompleteTipo() {
        var self = this;
        this.tipoSelecionado = null;
        this.$filtroTipo = $('[data-filtro-tipo]', this.DOM);
        //Registrar antes do componente: o input invalida a seleção e cancela a consulta anterior.
        this.$filtroTipo.on('input', function () {
            self.tipoSelecionado = null;
            self.cancelarSugestoesTipos();
        });
        this.$filtroTipo.on('fluig.autocomplete.selected fluig.autocomplete.autocompleted', function (event) {
            var item = event.item;
            if (!item || typeof item.codigo !== 'string' || !item.codigo) return;
            self.autocompleteTipo.val(item.rotulo);
            self.tipoSelecionado = { codigo: item.codigo, rotulo: item.rotulo };
            self.cancelarSugestoesTipos();
        });
        this.$filtroTipo.on('fluig.autocomplete.opened', function () { self.menuAutocompleteAberto = true; });
        this.$filtroTipo.on('fluig.autocomplete.closed', function () { self.menuAutocompleteAberto = false; });
        this.autocompleteTipo = FLUIGC.autocomplete(this.$filtroTipo, {
            type: 'autocomplete',
            name: 'nwe-tipos-' + this.instanceId,
            minLength: 2,
            hint: false,
            highlight: true,
            autoLoading: false,
            displayKey: 'rotulo',
            templates: { suggestion: '.nwe-tipo-sugestao-' + this.instanceId },
            source: function (termo, responder) { self.consultarSugestoesTipos(termo, responder); }
        });
    },

    cancelarSugestoesTipos() {
        this.apoioSeq++;
        if (this.timerApoio) clearTimeout(this.timerApoio);
        this.timerApoio = null;
        if (this.consultaApoio && this.consultaApoio.abort) this.consultaApoio.abort();
        this.consultaApoio = null;
    },

    consultarSugestoesTipos(termo, responder) {
        var self = this;
        termo = String(termo || '').trim();
        this.cancelarSugestoesTipos();
        var seq = this.apoioSeq;
        if (termo.length < 2) {
            responder([]);
            return;
        }
        //O source por função usa o Dataset central, com debounce e cancelamento próprios.
        this.timerApoio = setTimeout(function () {
            self.timerApoio = null;
            var consulta = chamarEmbalagens('consultarTiposApoio', { filtro: termo, ativo: 'todos', limite: 20 });
            self.consultaApoio = consulta;
            consulta.then(function (resultado) {
                if (seq !== self.apoioSeq) return;
                self.consultaApoio = null;
                if (!resultado.sucesso) {
                    responder([]);
                    self.avisar(nweMensagem(resultado, 'Não foi possível consultar as sugestões de tipos.'), 'danger');
                    return;
                }
                var itens = $.grep(resultado.dados || [], function (item) {
                    return item && typeof item.codigo === 'string' && item.codigo && typeof item.descricao === 'string';
                });
                responder($.map(itens, function (item) {
                    return { codigo: item.codigo, descricao: item.descricao, rotulo: item.codigo + ' — ' + item.descricao };
                }));
            }, function () {
                if (seq !== self.apoioSeq) return;
                self.consultaApoio = null;
                responder([]);
                self.avisar('Não foi possível consultar as sugestões de tipos. Tente novamente.', 'danger');
            });
        }, 250);
    },

    obterCodigoFiltro() {
        var valor = this.autocompleteTipo ? this.autocompleteTipo.val() : $('[data-filtro-tipo]', this.DOM).val();
        var texto = String(valor || '').trim();
        if (!texto) {
            this.tipoSelecionado = null;
            return '';
        }
        if (!this.tipoSelecionado || texto !== String(this.tipoSelecionado.rotulo).trim()) {
            this.avisar('Selecione um tipo na lista de sugestões ou limpe o campo para buscar todos.', 'info');
            return null;
        }
        return this.tipoSelecionado.codigo;
    },

    // ---------- Tabela ----------

    carregarTabulator() {
        if (window.Tabulator) return $.Deferred().resolve().promise();
        if (!nweTabulatorPromise) {
            nweTabulatorPromise = $.ajax({ url: NWE_TABULATOR_JS, dataType: 'script', cache: true })
                .fail(function () { nweTabulatorPromise = null; });
        }
        return nweTabulatorPromise;
    },

    montarTabela() {
        var self = this;
        //o Tabulator recebe elementos DOM: $(...)[0]
        this.tabela = new Tabulator($('[data-tabela]', this.DOM)[0], {
            data: [],
            index: 'codTipo',
            layout: 'fitColumns',
            responsiveLayout: false,
            pagination: true,
            paginationSize: 10,
            paginationCounter: function (pageSize, currentRow, currentPage, totalRows) {
                if (!totalRows) return '';
                var ate = Math.min(currentRow + pageSize - 1, totalRows);
                return 'Mostrando ' + currentRow + '–' + ate + ' de ' + totalRows;
            },
            placeholder: 'Nenhum tipo de embalagem encontrado.',
            locale: 'pt-br',
            langs: {
                'pt-br': {
                    data: { loading: 'Carregando...', error: 'Erro ao carregar' },
                    pagination: {
                        first: '<i class="bi bi-chevron-double-left" aria-hidden="true"></i>', first_title: 'Primeira página',
                        last: '<i class="bi bi-chevron-double-right" aria-hidden="true"></i>', last_title: 'Última página',
                        prev: '<i class="bi bi-chevron-left" aria-hidden="true"></i>', prev_title: 'Página anterior',
                        next: '<i class="bi bi-chevron-right" aria-hidden="true"></i>', next_title: 'Próxima página'
                    }
                }
            },
            columns: [
                { title: 'Descrição', field: 'descricao', sorter: 'string', widthGrow: 3, minWidth: 160, vertAlign: 'middle' },
                {
                    title: 'Sigla', field: 'codTipo', sorter: 'string', width: 120, hozAlign: 'left', vertAlign: 'middle',
                    formatter: function (cell) {
                        return $('<span>', { 'class': 'nwe-sigla', text: cell.getValue() })[0];
                    }
                },
                {
                    title: 'Situação', field: 'ativo', sorter: 'boolean', width: 130, hozAlign: 'left', vertAlign: 'middle',
                    formatter: function (cell) {
                        var ativo = cell.getValue();
                        return $('<span>', {
                            'class': 'nwe-situacao ' + (ativo ? 'is-ativo' : 'is-inativo'),
                            text: ativo ? 'Ativo' : 'Inativo'
                        })[0];
                    }
                },
                {
                    //sem ordenação de verdade: a seta do cabeçalho é só visual (CSS .nwe-col-acoes)
                    title: 'Ações', headerSort: false, cssClass: 'nwe-col-acoes', width: 200, hozAlign: 'right', vertAlign: 'middle',
                    formatter: function (cell) { return self.montarBotoesAcoes(cell.getRow().getData()); },
                    cellClick: function (event, cell) {
                        var $botao = $(event.target).closest('[data-acao]');
                        if (!$botao.length || self.salvando || $botao.prop('disabled')) return;
                        var acao = $botao.attr('data-acao');
                        if (acao === 'editar') self.abrirModalEditar(cell.getRow());
                        else if (acao === 'situacao') self.alterarSituacao(cell.getRow(), $botao);
                        else if (acao === 'excluir') self.abrirModalExcluir(cell.getRow());
                    }
                }
            ]
        });
        this.tabela.on('tableBuilt', function () { self.carregarTipos(); });
    },

    definirCarregamentoTipos(carregando) {
        this.carregandoTipos = carregando;
        $('[data-buscar], [data-novo]', this.DOM).prop('disabled', carregando);
    },

    //cancela as consultas ainda abertas quando uma busca nova substitui a anterior
    cancelarConsultas() {
        $.each(this.consultasAbertas, function (i, consulta) {
            if (consulta && consulta.abort) consulta.abort();
        });
        this.consultasAbertas = [];
    },

    //A API pagina por cursor; a tabela pagina a lista completa em grupos de 10.
    carregarTipos() {
        var self = this;
        var codigo = this.obterCodigoFiltro();
        if (codigo === null) return;
        var seq = ++this.consultaSeq;
        var linhas = [];
        var cursores = {};

        this.cancelarConsultas();
        this.definirCarregamentoTipos(true);
        this.tabela.alert('<div class="nwe-carregando" role="status" aria-label="Carregando tipos de embalagem"><span class="loader" aria-hidden="true"></span></div>');

        function consultar(cursor) {
            if (seq !== self.consultaSeq) return;
            self.consultasAbertas = $.map(nweConsultasTipos(codigo, cursor), function (parametros) {
                return chamarEmbalagens('consultarTipos', parametros);
            });
            //$.when entrega um argumento por consulta, na mesma ordem.
            return $.when.apply($, self.consultasAbertas).then(function () {
                if (seq !== self.consultaSeq) return;
                var resultados = Array.prototype.slice.call(arguments);
                self.consultasAbertas = [];
                var falha = $.grep(resultados, function (r) { return !r.sucesso; })[0];
                if (falha) throw new Error(nweMensagem(falha, 'Não foi possível consultar os tipos de embalagem.'));
                var pagina = resultados[0];
                var novos = nweMesclarTipos(pagina.dados);
                linhas = nweMesclarTipos(linhas.concat(novos));
                if (pagina.temMais) {
                    var proximo = pagina.proximoCodigo;
                    if (!proximo || cursores[proximo]) throw new Error('A consulta devolveu um cursor inválido. Clique em Buscar para tentar de novo.');
                    cursores[proximo] = true;
                    return consultar(proximo);
                }
                return self.tabela.setData(linhas).then(function () {
                    if (seq !== self.consultaSeq) return;
                    //Uma busca nova começa sempre na primeira página.
                    return self.tabela.setPage(1).then(function () {
                        if (seq !== self.consultaSeq) return;
                        self.tabela.clearAlert();
                        self.definirCarregamentoTipos(false);
                    });
                });
            });
        }

        return consultar('').then(null, function (erro) {
            //A resposta de uma busca cancelada não altera a lista atual.
            if (seq !== self.consultaSeq) return;
            self.cancelarConsultas();
            self.mostrarErroCarga(erro && erro.message || 'Não foi possível consultar os tipos de embalagem.');
        });
    },

    mostrarErroCarga(mensagem) {
        if (window.console) console.error('[widget_nw_embalagens] ' + mensagem);
        this.definirCarregamentoTipos(false);
        this.tabela.clearData();
        //O Tabulator trata texto como HTML: a mensagem vai como texto puro (.text).
        this.tabela.alert($('<span>').text(mensagem + ' Clique em Buscar para tentar de novo.')[0], 'error');
    },

    montarBotoesAcoes(dados) {
        var $grupo = $('<div>', { 'class': 'nwe-acoes', role: 'group', 'aria-label': 'Ações para ' + dados.descricao });
        $('<button>', {
            type: 'button',
            'class': 'nwe-interruptor',
            'data-acao': 'situacao',
            role: 'switch',
            'aria-checked': dados.ativo ? 'true' : 'false',
            'aria-label': 'Ativo: ' + dados.descricao,
            title: dados.ativo ? 'Desativar' : 'Ativar'
        }).append($('<span>', { 'class': 'nwe-interruptor-bolinha', 'aria-hidden': 'true' })).appendTo($grupo);
        $('<span>', { 'class': 'nwe-acoes-divisor', 'aria-hidden': 'true' }).appendTo($grupo);
        $('<button>', {
            type: 'button',
            'class': 'nwe-acao nwe-acao-editar',
            'data-acao': 'editar',
            'aria-label': 'Editar ' + dados.descricao,
            title: 'Editar'
        }).append($('<i>', { 'class': 'bi bi-pencil', 'aria-hidden': 'true' })).appendTo($grupo);
        $('<button>', {
            type: 'button',
            'class': 'nwe-acao nwe-acao-excluir',
            'data-acao': 'excluir',
            'aria-label': 'Excluir ' + dados.descricao,
            title: 'Excluir'
        }).append($('<i>', { 'class': 'bi bi-trash', 'aria-hidden': 'true' })).appendTo($grupo);
        return $grupo[0];
    },

    buscar(htmlElement, event) {
        if (!this.tabela || this.carregandoTipos) return;
        this.carregarTipos();
    },

    //Enter no campo de filtro dispara a busca
    teclaFiltro(htmlElement, event) {
        if (event.key !== 'Enter' || this.menuAutocompleteAberto) return;
        event.preventDefault();
        this.buscar();
    },

    // ---------- Comandos (incluirTipo / alterarTipo) ----------

    //Uma única chamada por clique, sem repetição automática. Mesma ação + mesmo conteúdo reaproveita a chave
    //(inclusive depois de falha incerta); conteúdo diferente é outra intenção e recebe chave nova.
    executarComando(acao, parametros) {
        var self = this;
        var assinatura = acao + '|' + JSON.stringify(parametros);
        if (!this.intencoes[assinatura]) this.intencoes[assinatura] = nweNovaChave();
        var corpo = $.extend({}, parametros, { chaveIdempotente: this.intencoes[assinatura] });

        return chamarEmbalagens(acao, corpo).then(function (resultado) {
            if (resultado.sucesso) {
                delete self.intencoes[assinatura];
                return { ok: true, resultado: resultado };
            }
            return {
                ok: false, codigoErro: resultado.codigoErro, incerto: nweResultadoIncerto(resultado.codigoErro),
                mensagem: nweMensagem(resultado, 'O Datasul recusou a gravação.')
            };
        }, function (erro) {
            return { ok: false, codigoErro: 'TRANSPORTE', incerto: true, mensagem: erro && erro.message };
        }).then(function (saida) {
            if (saida.incerto) {
                if (window.console) console.error('[widget_nw_embalagens] ' + acao + ' ' + saida.codigoErro + ': ' + saida.mensagem);
                saida.mensagem = 'Não foi possível confirmar se a gravação foi concluída. Clique em Buscar para conferir a lista antes de tentar de novo. '
                    + 'Se tentar de novo com os mesmos dados, a tela reaproveita a mesma chave e o Datasul não grava em dobro.';
            }
            return saida;
        });
    },

    //aplica na tabela a fotografia devolvida pelo comando (codTipo, descricao, ativo, versao)
    aplicarFotografia(resultado, destacar) {
        var self = this;
        var paginaAtual = this.tabela.getPage();
        return this.tabela.updateOrAddData([nweLinhaTipo(resultado)]).then(function () {
            var linha = self.tabela.getRow(resultado.codTipo);
            if (!linha) return;
            linha.reformat();   //atualiza situação e botões de ação
            self.reaplicarOrdem();
            return self.tabela.setPage(Math.min(paginaAtual, self.tabela.getPageMax())).then(function () {
                if (destacar !== false) self.destacarLinha(linha);
            });
        });
    },

    avisar(mensagem, tipo) {
        if (window.FLUIGC && FLUIGC.toast) FLUIGC.toast({ title: '', message: mensagem, type: tipo });
    },

    // ---------- Modal "Novo/Editar tipo de embalagem" (<dialog> nativo, não o FLUIGC.modal) ----------
    // showModal()/close() são métodos do <dialog>: não há equivalente no jQuery, por isso o [0].

    prepararModalNovo() {
        var self = this;
        this.$modal = $('[data-modal-novo]', this.DOM);
        this.$formNovo = this.$modal.find('form');

        //fechar com Esc não passa por fecharModalNovo: o "close" cobre esse caso.
        //Ele é assíncrono: se o modal já foi reaberto (ex.: em modo edição), não apaga o que foi preenchido.
        this.$modal.on('close', function () {
            if (!self.$modal.prop('open')) self.limparFormNovo();
        });
        //enquanto grava, o modal não fecha (nem pelo Esc)
        this.$modal.on('cancel', function (event) {
            if (self.salvando) event.preventDefault();
        });

        //clique no fundo escurecido: o alvo é o próprio <dialog> (o conteúdo fica dentro do <form>)
        this.$modal.on('click', function (event) {
            if ($(event.target).is(self.$modal)) self.fecharModalNovo();
        });

        this.$formNovo.on('submit', function (event) {
            event.preventDefault();
            self.salvarCadastro();
        });

        //o erro de um campo some assim que a pessoa volta a digitar nele
        this.$formNovo.on('input', '.nwe-campo-input', function () {
            self.marcarErro($(this).attr('name'), '');
        });
    },

    abrirModalNovo(htmlElement, event) {
        if (this.carregandoTipos) return;
        this.abrirModalCadastro(null);
    },

    abrirModalEditar(linha) {
        this.abrirModalCadastro(linha);
    },

    //mesmo modal para criar (linha = null) e editar (linha = linha do Tabulator)
    abrirModalCadastro(linha) {
        var modal = this.$modal[0];
        if (!modal || typeof modal.showModal !== 'function' || this.$modal.prop('open')) return;
        //limpa também ao abrir: o evento "close" é assíncrono e o Chrome não o dispara com a aba oculta
        this.limparFormNovo();

        var editando = !!linha;
        this.$modal.find('[data-modal-titulo]').text(editando ? 'Editar tipo de embalagem' : 'Novo tipo de embalagem');
        this.$modal.find('[data-modal-subtitulo]').text(editando ? 'Altere a descrição e salve.' : 'Preencha a descrição e a sigla para cadastrar.');
        this.$modal.find('[data-modal-salvar]').text(editando ? 'Salvar alterações' : 'Salvar');
        this.$formNovo.find('[name="sigla"]').prop('readOnly', editando);
        this.$formNovo.find('[data-sigla-dica]').text(editando ? 'A sigla não pode ser alterada.' : 'Até 3 caracteres.');
        if (editando) {
            this.linhaEditando = linha;
            this.$formNovo.find('[name="descricao"]').val(linha.getData().descricao);
            this.$formNovo.find('[name="sigla"]').val(linha.getData().codTipo);
        }
        modal.showModal();
    },

    fecharModalNovo(htmlElement, event) {
        if (!this.$modal.prop('open') || this.salvando) return;
        this.$modal[0].close();
        this.limparFormNovo();
    },

    limparFormNovo() {
        this.linhaEditando = null;
        this.$formNovo.trigger('reset');
        this.$formNovo.find('[name="sigla"]').prop('readOnly', false);
        this.marcarErro('descricao', '');
        this.marcarErro('sigla', '');
        this.$modal.find('[data-modal-alerta]').text('');
    },

    marcarErro(campo, mensagem) {
        this.$formNovo.find('[name="' + campo + '"]')
            .toggleClass('is-invalido', !!mensagem)
            .attr('aria-invalid', mensagem ? 'true' : 'false');
        this.$formNovo.find('[data-erro="' + campo + '"]').text(mensagem);
    },

    definirSalvando(salvando, $botao) {
        this.salvando = salvando;
        $botao.prop('disabled', salvando).attr('aria-busy', salvando ? 'true' : 'false');
    },

    salvarCadastro() {
        var self = this;
        if (this.salvando) return;
        var descricao = String(this.$formNovo.find('[name="descricao"]').val() || '').trim();
        var sigla = String(this.$formNovo.find('[name="sigla"]').val() || '').trim();
        var linhaEditando = this.linhaEditando;
        var tipo = linhaEditando ? linhaEditando.getData() : null;
        var primeiroInvalido = null;

        this.$modal.find('[data-modal-alerta]').text('');
        if (!descricao) {
            this.marcarErro('descricao', 'Informe a descrição.');
            primeiroInvalido = primeiroInvalido || 'descricao';
        } else if (tipo && descricao === tipo.descricao) {
            this.marcarErro('descricao', 'Altere a descrição para salvar.');
            primeiroInvalido = primeiroInvalido || 'descricao';
        }
        if (!tipo && !/^[A-Za-z0-9]{2,3}$/.test(sigla)) {
            this.marcarErro('sigla', 'Informe um código válido');
            primeiroInvalido = primeiroInvalido || 'sigla';
        }
        if (primeiroInvalido) {
            this.$formNovo.find('[name="' + primeiroInvalido + '"]').trigger('focus');
            return;
        }
        if (tipo && !Number.isInteger(Number(tipo.versao))) {
            this.$modal.find('[data-modal-alerta]').text('A versão deste tipo não veio da consulta. Clique em Buscar e tente de novo.');
            return;
        }

        var acao = tipo ? 'alterarTipo' : 'incluirTipo';
        var parametros = tipo ? nweParametrosAlteracao(tipo, descricao) : nweParametrosInclusao(sigla, descricao);
        var $salvar = this.$formNovo.find('[type="submit"]');
        this.definirSalvando(true, $salvar);

        return this.executarComando(acao, parametros).then(function (saida) {
            self.definirSalvando(false, $salvar);
            if (!saida.ok) {
                if (saida.codigoErro === 'TIPO_JA_EXISTE' || saida.codigoErro === 'CODIGO_INVALIDO') {
                    self.marcarErro('sigla', saida.mensagem);
                    self.$formNovo.find('[name="sigla"]').trigger('focus');
                } else {
                    self.$modal.find('[data-modal-alerta]').text(saida.mensagem);
                }
                return;
            }
            self.fecharModalNovo();
            if (saida.resultado.repeticao) self.avisar('Esta gravação já tinha sido registrada pelo Datasul.', 'info');
            return self.aplicarFotografia(saida.resultado);
        });
    },

    reaplicarOrdem() {
        var ordem = $.map(this.tabela.getSorters(), function (s) { return { column: s.field, dir: s.dir }; });
        if (ordem.length) this.tabela.setSort(ordem);
    },

    // ---------- Interruptor de situação: grava diretamente ao clicar ----------

    alterarSituacao(linha, $interruptor) {
        var self = this;
        if (!linha || this.salvando) return;
        var tipo = linha.getData();
        if (!Number.isInteger(Number(tipo.versao))) {
            this.avisar('A versão deste tipo não veio da consulta. Clique em Buscar e tente de novo.', 'danger');
            return;
        }
        this.definirSalvando(true, $interruptor);

        //O interruptor e o badge mudam com a fotografia confirmada pelo servidor.
        return this.executarComando('alterarTipo', nweParametrosSituacao(tipo)).then(function (saida) {
            if (!saida.ok) {
                self.avisar(saida.mensagem, 'danger');
                return;
            }
            if (saida.resultado.repeticao) self.avisar('Esta gravação já tinha sido registrada pelo Datasul.', 'info');
            return self.aplicarFotografia(saida.resultado, false).then(function () {
                var mensagem = saida.resultado.descricao + (saida.resultado.ativo ? ' ativado' : ' desativado') + ' com sucesso!';
                //O toast aceita HTML; a descrição deve aparecer como texto.
                mensagem = mensagem.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
                self.avisar(mensagem, 'success');
            });
        }).then(function () {
            self.definirSalvando(false, $interruptor);
        }, function () {
            self.definirSalvando(false, $interruptor);
            self.avisar('Não foi possível atualizar a situação na tela. Clique em Buscar para conferir a lista.', 'danger');
        });
    },

    // ---------- Modal Excluir: mesmo <dialog> e estilo do cadastro/edição ----------

    prepararModalExcluir() {
        var self = this;
        this.$modalExcluir = $('[data-modal-excluir]', this.DOM);
        this.$modalExcluir.on('close', function () {
            if (!self.$modalExcluir.prop('open')) self.linhaExcluindo = null;
        });
        this.$modalExcluir.on('cancel', function (event) {
            if (self.salvando) event.preventDefault();
        });
        this.$modalExcluir.on('click', function (event) {
            if ($(event.target).is(self.$modalExcluir)) self.fecharModalExcluir();
        });
        this.$modalExcluir.find('form').on('submit', function (event) {
            event.preventDefault();
            self.confirmarExclusao();
        });
    },

    abrirModalExcluir(linha) {
        if (!linha || this.salvando) return;
        var modal = this.$modalExcluir[0];
        if (!modal || typeof modal.showModal !== 'function' || this.$modalExcluir.prop('open')) return;
        this.linhaExcluindo = linha;
        var tipo = linha.getData();
        this.$modalExcluir.find('[data-excluir-item]').text(tipo.descricao + ' (' + tipo.codTipo + ')');
        this.$modalExcluir.find('[data-excluir-alerta]').text('');
        modal.showModal();
    },

    fecharModalExcluir(htmlElement, event) {
        if (this.salvando) return;
        if (this.$modalExcluir.prop('open')) this.$modalExcluir[0].close();
        this.linhaExcluindo = null;
    },

    confirmarExclusao() {
        var self = this;
        var linha = this.linhaExcluindo;
        if (!linha || this.salvando) return;
        var tipo = linha.getData();
        var $alerta = this.$modalExcluir.find('[data-excluir-alerta]');
        $alerta.text('');
        if (!Number.isInteger(Number(tipo.versao))) {
            $alerta.text('A versão deste tipo não veio da consulta. Clique em Buscar e tente de novo.');
            return;
        }
        var $botao = this.$modalExcluir.find('[data-confirmar-excluir]');
        var nome = String(tipo.descricao).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        this.definirSalvando(true, $botao);
        //A API de exclusão continua pendente; envio preparado com acao "excluir".
        return this.executarComando('alterarTipo', nweParametrosExclusao(tipo)).then(function (saida) {
            if (!saida.ok) {
                $alerta.text(saida.mensagem);
                return;
            }
            //A linha só é removida quando a API confirmar sucesso na exclusão.
            var paginaAtual = self.tabela.getPage();
            var linhaAtual = self.tabela.getRow(tipo.codTipo);
            var remover = linhaAtual ? linhaAtual.delete() : $.Deferred().resolve().promise();
            return remover.then(function () {
                return self.tabela.setPage(Math.max(1, Math.min(paginaAtual, self.tabela.getPageMax() || 1)));
            }).then(function () {
                self.definirSalvando(false, $botao);
                self.fecharModalExcluir();
                self.avisar(nome + ' excluído com sucesso!', 'success');
            });
        }).then(function () {
            self.definirSalvando(false, $botao);
        }, function () {
            self.definirSalvando(false, $botao);
            self.fecharModalExcluir();
            self.avisar('Não foi possível atualizar a lista após a exclusão. Clique em Buscar para conferir.', 'danger');
        });
    },

    //rola até a linha gravada (se estiver fora da tela)
    destacarLinha(linha) {
        var visivel = $.inArray(linha, this.tabela.getRows('active')) !== -1;
        if (!visivel) return;
        var $linha = $(linha.getElement());
        var $janela = $(window);
        var topo = $linha.offset().top;
        if (topo < $janela.scrollTop() || topo + $linha.outerHeight() > $janela.scrollTop() + $janela.height()) {
            $('html, body').animate({ scrollTop: Math.max(topo - 120, 0) }, 200);
        }
    }
});
