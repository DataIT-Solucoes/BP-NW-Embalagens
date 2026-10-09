var URL_SCRIPT_TABULATOR = 'https://cdnjs.cloudflare.com/ajax/libs/tabulator/6.4.0/js/tabulator.min.js';
var promessaCarregamentoTabulator = null;

var LIMITE_CONSULTA_TIPOS = 20;

var MENSAGENS_ERRO_CADASTRO = {
    AUTORIZACAO_NAO_CONFIGURADA: 'O acesso a esta tela ainda não foi configurado no Fluig (grupos e permissões).',
    SEM_PERMISSAO: 'Você não tem permissão para esta ação.',
    ESCRITA_DESABILITADA: 'A gravação ainda não está habilitada para esta ação.',
    CODIGO_INVALIDO: 'Informe um código válido',
    TIPO_JA_EXISTE: 'Já existe um tipo de embalagem com esta sigla.',
    CONFLITO_VERSAO: 'Este tipo foi alterado por outra pessoa depois que a lista foi carregada. Clique em Buscar para recarregar e tente de novo.'
};

function temResultadoGravacaoIncerto(codigoErro) {
    return codigoErro === 'FALHA_CHAMADA' || codigoErro === 'RESPOSTA_INVALIDA' ||
        codigoErro === 'HTTP_STATUS_INDISPONIVEL' || /^HTTP_/.test(codigoErro || '');
}

function obterMensagemResultado(resultado, padrao) {
    return MENSAGENS_ERRO_CADASTRO[resultado.codigoErro] || resultado.mensagem || padrao;
}

function escaparTextoHtml(texto) {
    return texto.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function formatarRotulo(codigo, descricao) {
    return descricao ? codigo + ' — ' + descricao : codigo;
}

function montarConsultasTipos(codigo, cursor) {
    if (codigo) return [{ codigoDe: codigo, codigoAte: codigo, limite: 1 }];
    var parametros = { limite: LIMITE_CONSULTA_TIPOS };
    if (cursor) parametros.aposCodigo = cursor;
    return [parametros];
}

function normalizarTipoEmbalagem(tipo) {
    return { codTipo: tipo.codTipo, descricao: tipo.descricao, ativo: tipo.ativo === true, versao: tipo.versao };
}

function mesclarTiposSemDuplicacao(porDescricao, exatos) {
    var codigosEncontrados = {};
    var tiposUnicos = $.grep((exatos || []).concat(porDescricao || []), function (tipo) {
        if (codigosEncontrados[tipo.codTipo]) return false;
        codigosEncontrados[tipo.codTipo] = true;
        return true;
    });
    return $.map(tiposUnicos, normalizarTipoEmbalagem);
}

function montarParametrosInclusao(sigla, descricao) {
    return { codTipo: sigla, descricao: descricao, ativo: true, versao: 0 };
}

function montarParametrosAlteracao(tipo, descricao) {
    return { codTipo: tipo.codTipo, descricao: descricao, ativo: tipo.ativo, versao: Number(tipo.versao), acao: 'ALTERAR' };
}

function montarParametrosSituacao(tipo) {
    return {
        codTipo: tipo.codTipo, descricao: tipo.descricao, ativo: !tipo.ativo,
        versao: Number(tipo.versao), acao: tipo.ativo ? 'INATIVAR' : 'ALTERAR'
    };
}

function montarParametrosExclusao(tipo) {
    return {
        codTipo: tipo.codTipo, descricao: tipo.descricao, ativo: tipo.ativo,
        versao: Number(tipo.versao), acao: 'excluir'
    };
}

function gerarChaveIdempotente() {
    var bytes = new Uint8Array(16);
    window.crypto.getRandomValues(bytes);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    var chaveHexadecimal = $.map(bytes, function (byteAleatorio) { return (byteAleatorio + 0x100).toString(16).slice(1); }).join('');
    return chaveHexadecimal.slice(0, 8) + '-' + chaveHexadecimal.slice(8, 12) + '-' + chaveHexadecimal.slice(12, 16) + '-' + chaveHexadecimal.slice(16, 20) + '-' + chaveHexadecimal.slice(20);
}

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
    function interpretarResposta(transporte) {
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
        return envelope;
    }

    function tratarFalhaTransporte(jqXHR, textStatus) {
        if (textStatus === "abort") throw new Error("Chamada cancelada.");
        if (textStatus === "parsererror") throw new Error("O Fluig nao retornou JSON valido.");
        throw new Error("Falha HTTP " + jqXHR.status + " no transporte Fluig.");
    }

    var resultado = xhr.then(interpretarResposta, tratarFalhaTransporte);
    resultado.abort = function () { xhr.abort(); };
    return resultado;
}

var cadastroEmbalagens = SuperWidget.extend({

    abaAtual: 'tipos-embalagem',

    tabela: null,

    carregandoTipos: true,
    salvando: false,

    consultaSeq: 0,
    consultasAbertas: null,

    autocompleteTipo: null,
    tipoSelecionado: null,
    consultaApoio: null,
    timerApoio: null,
    apoioSeq: 0,
    menuAutocompleteAberto: false,

    intencoes: null,

    linhaEditando: null,
    linhaExcluindo: null,

    init() {
        var self = this;
        this.intencoes = {};
        this.consultasAbertas = [];
        this.definirCarregamentoTipos(true);
        this.prepararAutocompleteTipo();
        this.$tabs = $('.embalagens-abas', this.DOM);
        this.moverIndicador();
        $(window).on('resize.cadastroEmbalagens' + this.instanceId, function () { self.moverIndicador(); });
        if (document.fonts && document.fonts.ready) {
            document.fonts.ready.then(function () { self.moverIndicador(); });
            $(document.fonts).on('loadingdone', function () { self.moverIndicador(); });
        }

        this.carregarTabulator().then(function () {
            self.montarTabela();
        }, function () {
            $('[data-tabela]', self.DOM).html('<p class="embalagens-tabela-erro">Não foi possível carregar a tabela. Verifique a conexão com a internet e recarregue a página.</p>');
            self.definirCarregamentoTipos(false);
        });

        this.prepararModalNovo();
        this.prepararModalExcluir();
    },

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

    navegarAbas(htmlElement, event) {
        var $abas = this.$tabs.find('.embalagens-aba');
        var indiceAtual = $abas.index(htmlElement);
        var indiceDestino = null;

        if (event.key === 'ArrowRight') indiceDestino = (indiceAtual + 1) % $abas.length;
        else if (event.key === 'ArrowLeft') indiceDestino = (indiceAtual - 1 + $abas.length) % $abas.length;
        else if (event.key === 'Home') indiceDestino = 0;
        else if (event.key === 'End') indiceDestino = $abas.length - 1;
        if (indiceDestino === null) return;

        event.preventDefault();
        this.ativarAba($abas.eq(indiceDestino));
        $abas.eq(indiceDestino).trigger('focus');
    },

    ativarAba($aba) {
        this.$tabs.find('.embalagens-aba')
            .removeClass('is-active').attr({ 'aria-selected': 'false', tabindex: '-1' });
        $aba.addClass('is-active').attr({ 'aria-selected': 'true', tabindex: '0' });
        this.abaAtual = $aba.data('aba');
        this.moverIndicador();
    },

    moverIndicador() {
        var $abaAtiva = this.$tabs.find('.embalagens-aba.is-active');
        if (!$abaAtiva.length) return;
        this.$tabs.find('.embalagens-indicador-aba').css({
            width: $abaAtiva.outerWidth() + 'px',
            transform: 'translateX(' + $abaAtiva.position().left + 'px)'
        });
    },

    prepararAutocompleteTipo() {
        var self = this;
        this.tipoSelecionado = null;
        this.$filtroTipo = $('[data-filtro-tipo]', this.DOM);
        this.$filtroTipo.on('input', function () {
            if (self.$filtroTipo.prop('readonly')) return;
            self.tipoSelecionado = null;
            self.cancelarSugestoesTipos();
        });
        this.$filtroTipo.on('fluig.autocomplete.selected fluig.autocomplete.autocompleted', function (event) {
            var item = event.item;
            if (!item || typeof item.codigo !== 'string' || !item.codigo) return;
            self.autocompleteTipo.val(item.rotulo);
            self.tipoSelecionado = { codigo: item.codigo, rotulo: item.rotulo };
            self.cancelarSugestoesTipos();
            self.mostrarSelecionado(item);
        });
        this.$filtroTipo.on('fluig.autocomplete.opened', function () { self.menuAutocompleteAberto = true; });
        this.$filtroTipo.on('fluig.autocomplete.closed', function () { self.menuAutocompleteAberto = false; });
        this.autocompleteTipo = FLUIGC.autocomplete(this.$filtroTipo, {
            type: 'autocomplete',
            name: 'embalagens-tipos-' + this.instanceId,
            minLength: 2,
            hint: false,
            highlight: true,
            autoLoading: false,
            displayKey: 'rotulo',
            templates: { suggestion: '.embalagens-tipo-sugestao-' + this.instanceId },
            source: function (termo, responder) { self.consultarSugestoesTipos(termo, responder); }
        });
    },

    // O campo continua no lugar (com o texto escondido) e trava; a badge fica por cima dele.
    mostrarSelecionado(item) {
        var self = this;
        var $campo = this.$filtroTipo;
        if (!this.$badgeTipo) {
            this.$badgeTipo = $('<span>', { 'class': 'embalagens-selecionado', hidden: true })
                .append($('<span>', { 'class': 'embalagens-selecionado-chip' })
                    .append($('<span>', { 'class': 'embalagens-selecionado-texto' })
                        .append($('<span>', { 'class': 'embalagens-selecionado-codigo' }))
                        .append($('<span>', { 'class': 'embalagens-selecionado-descricao' })))
                    .append($('<button>', { type: 'button', 'class': 'embalagens-selecionado-remover' })
                        .append($('<i>', { 'class': 'bi bi-x', 'aria-hidden': 'true' }))
                        .on('click.cadastroEmbalagens', function () { self.removerSelecionado(); })))
                .appendTo($campo.closest('.embalagens-campo-caixa'));
        }

        var rotulo = formatarRotulo(item.codigo, item.descricao);
        this.$badgeTipo.find('.embalagens-selecionado-codigo').text(item.codigo);
        this.$badgeTipo.find('.embalagens-selecionado-descricao').text(item.descricao ? ' — ' + item.descricao : '');
        this.$badgeTipo.find('.embalagens-selecionado-chip').attr('title', rotulo);
        this.$badgeTipo.find('.embalagens-selecionado-remover').attr({ title: 'Remover', 'aria-label': 'Remover ' + rotulo });

        if (this.autocompleteTipo) this.autocompleteTipo.close();
        $campo.addClass('is-selecionado').prop('readOnly', true);
        this.$badgeTipo.prop('hidden', false);
        this.$badgeTipo.find('.embalagens-selecionado-remover').trigger('focus');
    },

    removerSelecionado() {
        var $campo = this.$filtroTipo;
        if (this.$badgeTipo) this.$badgeTipo.prop('hidden', true);
        $campo.removeClass('is-selecionado').prop('readOnly', false);
        this.tipoSelecionado = null;
        // o val('') do FLUIGC.autocomplete pode não limpar (vazio vira leitura): limpa o typeahead e o input direto
        if ($.fn.typeahead && $campo.hasClass('tt-input')) $campo.typeahead('val', '');
        $campo.val('');
        if (this.autocompleteTipo) this.autocompleteTipo.close();
        this.cancelarSugestoesTipos();
        $campo.trigger('focus');
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
        var sequenciaConsulta = this.apoioSeq;
        if (termo.length < 2 || this.$filtroTipo.prop('readonly')) {
            responder([]);
            return;
        }
        this.timerApoio = setTimeout(function () {
            self.timerApoio = null;
            var consulta = chamarEmbalagens('consultarTiposApoio', { filtro: termo, ativo: 'todos', limite: 20 });
            self.consultaApoio = consulta;
            consulta.then(function (resultado) {
                if (sequenciaConsulta !== self.apoioSeq) return;
                self.consultaApoio = null;
                if (!resultado.sucesso) {
                    responder([]);
                    self.avisar(obterMensagemResultado(resultado, 'Não foi possível consultar as sugestões de tipos.'), 'danger');
                    return;
                }
                var itens = $.grep(resultado.dados || [], function (item) {
                    return item && typeof item.codigo === 'string' && item.codigo && typeof item.descricao === 'string';
                });
                responder($.map(itens, function (item) {
                    return { codigo: item.codigo, descricao: item.descricao, rotulo: formatarRotulo(item.codigo, item.descricao) };
                }));
            }, function () {
                if (sequenciaConsulta !== self.apoioSeq) return;
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

    carregarTabulator() {
        if (window.Tabulator) return $.Deferred().resolve().promise();
        if (!promessaCarregamentoTabulator) {
            promessaCarregamentoTabulator = $.ajax({ url: URL_SCRIPT_TABULATOR, dataType: 'script', cache: true })
                .fail(function () { promessaCarregamentoTabulator = null; });
        }
        return promessaCarregamentoTabulator;
    },

    montarTabela() {
        var self = this;
        this.tabela = new Tabulator($('[data-tabela]', this.DOM)[0], {
            data: [],
            index: 'codTipo',
            layout: 'fitColumns',
            responsiveLayout: false,
            pagination: true,
            paginationSize: 10,
            paginationCounter: function (pageSize, currentRow, currentPage, totalRows) {
                if (!totalRows) return '';
                var ultimaLinha = Math.min(currentRow + pageSize - 1, totalRows);
                return 'Mostrando ' + currentRow + '–' + ultimaLinha + ' de ' + totalRows;
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
                        return $('<span>', { 'class': 'embalagens-sigla', text: cell.getValue() })[0];
                    }
                },
                {
                    title: 'Situação', field: 'ativo', sorter: 'boolean', width: 130, hozAlign: 'left', vertAlign: 'middle',
                    formatter: function (cell) {
                        var ativo = cell.getValue();
                        return $('<span>', {
                            'class': 'embalagens-situacao ' + (ativo ? 'is-ativo' : 'is-inativo'),
                            text: ativo ? 'Ativo' : 'Inativo'
                        })[0];
                    }
                },
                {
                    title: 'Ações', headerSort: false, cssClass: 'embalagens-coluna-acoes', width: 200, hozAlign: 'right', vertAlign: 'middle',
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

    cancelarConsultas() {
        $.each(this.consultasAbertas, function (indiceConsulta, consulta) {
            if (consulta && consulta.abort) consulta.abort();
        });
        this.consultasAbertas = [];
    },

    carregarTipos() {
        var self = this;
        var codigo = this.obterCodigoFiltro();
        if (codigo === null) return;
        var sequenciaConsulta = ++this.consultaSeq;
        var tiposCarregados = [];
        var cursoresConsultados = {};

        this.cancelarConsultas();
        this.definirCarregamentoTipos(true);
        this.tabela.alert('<div class="embalagens-carregando" role="status" aria-label="Carregando tipos de embalagem"><span class="loader" aria-hidden="true"></span></div>');

        function exibirTiposCarregados() {
            return self.tabela.setData(tiposCarregados).then(function () {
                if (sequenciaConsulta !== self.consultaSeq) return;
                return self.tabela.setPage(1).then(function () {
                    if (sequenciaConsulta !== self.consultaSeq) return;
                    self.tabela.clearAlert();
                    self.definirCarregamentoTipos(false);
                });
            });
        }

        function consultarPagina(cursor) {
            if (sequenciaConsulta !== self.consultaSeq) return;
            self.consultasAbertas = $.map(montarConsultasTipos(codigo, cursor), function (parametros) {
                return chamarEmbalagens('consultarTipos', parametros);
            });
            return $.when.apply($, self.consultasAbertas).then(function () {
                if (sequenciaConsulta !== self.consultaSeq) return;
                var resultados = Array.prototype.slice.call(arguments);
                self.consultasAbertas = [];
                var falha = $.grep(resultados, function (resultado) { return !resultado.sucesso; })[0];
                if (falha) throw new Error(obterMensagemResultado(falha, 'Não foi possível consultar os tipos de embalagem.'));
                var pagina = resultados[0];
                var tiposDaPagina = mesclarTiposSemDuplicacao(pagina.dados);
                tiposCarregados = mesclarTiposSemDuplicacao(tiposCarregados.concat(tiposDaPagina));
                if (pagina.temMais) {
                    var proximoCodigo = pagina.proximoCodigo;
                    if (!proximoCodigo || cursoresConsultados[proximoCodigo]) throw new Error('A consulta devolveu um cursor inválido. Clique em Buscar para tentar de novo.');
                    cursoresConsultados[proximoCodigo] = true;
                    return consultarPagina(proximoCodigo);
                }
                return exibirTiposCarregados();
            });
        }

        return consultarPagina('').then(null, function (erro) {
            if (sequenciaConsulta !== self.consultaSeq) return;
            self.cancelarConsultas();
            self.mostrarErroCarga(erro && erro.message || 'Não foi possível consultar os tipos de embalagem.');
        });
    },

    mostrarErroCarga(mensagem) {
        if (window.console) console.error('[cadastroEmbalagens] ' + mensagem);
        this.definirCarregamentoTipos(false);
        this.tabela.clearData();
        this.tabela.alert($('<span>').text(mensagem + ' Clique em Buscar para tentar de novo.')[0], 'error');
    },

    montarBotoesAcoes(dados) {
        var $grupo = $('<div>', { 'class': 'embalagens-acoes', role: 'group', 'aria-label': 'Ações para ' + dados.descricao });
        $('<button>', {
            type: 'button',
            'class': 'embalagens-interruptor',
            'data-acao': 'situacao',
            role: 'switch',
            'aria-checked': dados.ativo ? 'true' : 'false',
            'aria-label': 'Ativo: ' + dados.descricao,
            title: dados.ativo ? 'Desativar' : 'Ativar'
        }).append($('<span>', { 'class': 'embalagens-interruptor-bolinha', 'aria-hidden': 'true' })).appendTo($grupo);
        $('<span>', { 'class': 'embalagens-acoes-divisor', 'aria-hidden': 'true' }).appendTo($grupo);
        $('<button>', {
            type: 'button',
            'class': 'embalagens-acao embalagens-acao-editar',
            'data-acao': 'editar',
            'aria-label': 'Editar ' + dados.descricao,
            title: 'Editar'
        }).append($('<i>', { 'class': 'bi bi-pencil', 'aria-hidden': 'true' })).appendTo($grupo);
        $('<button>', {
            type: 'button',
            'class': 'embalagens-acao embalagens-acao-excluir',
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

    teclaFiltro(htmlElement, event) {
        if (event.key !== 'Enter' || this.menuAutocompleteAberto) return;
        event.preventDefault();
        this.buscar();
    },

    executarComando(acao, parametros) {
        var self = this;
        var assinaturaComando = acao + '|' + JSON.stringify(parametros);
        if (!this.intencoes[assinaturaComando]) this.intencoes[assinaturaComando] = gerarChaveIdempotente();
        var parametrosComChave = $.extend({}, parametros, { chaveIdempotente: this.intencoes[assinaturaComando] });

        function interpretarResultado(resultado) {
            if (resultado.sucesso) {
                delete self.intencoes[assinaturaComando];
                return { ok: true, resultado: resultado };
            }
            return {
                ok: false, codigoErro: resultado.codigoErro, incerto: temResultadoGravacaoIncerto(resultado.codigoErro),
                mensagem: obterMensagemResultado(resultado, 'O Datasul recusou a gravação.')
            };
        }

        function tratarFalhaTransporte(erro) {
            return { ok: false, codigoErro: 'TRANSPORTE', incerto: true, mensagem: erro && erro.message };
        }

        function tratarResultadoIncerto(saida) {
            if (saida.incerto) {
                if (window.console) console.error('[cadastroEmbalagens] ' + acao + ' ' + saida.codigoErro + ': ' + saida.mensagem);
                saida.mensagem = 'Não foi possível confirmar se a gravação foi concluída. Clique em Buscar para conferir a lista antes de tentar de novo. '
                    + 'Se tentar de novo com os mesmos dados, a tela reaproveita a mesma chave e o Datasul não grava em dobro.';
            }
            return saida;
        }

        return chamarEmbalagens(acao, parametrosComChave)
            .then(interpretarResultado, tratarFalhaTransporte)
            .then(tratarResultadoIncerto);
    },

    aplicarFotografia(resultado, destacar) {
        var self = this;
        var paginaAtual = this.tabela.getPage();
        return this.tabela.updateOrAddData([normalizarTipoEmbalagem(resultado)]).then(function () {
            var linha = self.tabela.getRow(resultado.codTipo);
            if (!linha) return;
            linha.reformat();
            self.reaplicarOrdem();
            return self.tabela.setPage(Math.min(paginaAtual, self.tabela.getPageMax())).then(function () {
                if (destacar !== false) self.destacarLinha(linha);
            });
        });
    },

    avisar(mensagem, tipo) {
        if (window.FLUIGC && FLUIGC.toast) FLUIGC.toast({ title: '', message: mensagem, type: tipo });
    },

    prepararModalNovo() {
        var self = this;
        this.$modal = $('[data-modal-novo]', this.DOM);
        this.$formNovo = this.$modal.find('form');

        this.$modal.on('close', function () {
            if (!self.$modal.prop('open')) self.limparFormNovo();
        });
        this.$modal.on('cancel', function (event) {
            if (self.salvando) event.preventDefault();
        });

        this.$modal.on('click', function (event) {
            if ($(event.target).is(self.$modal)) self.fecharModalNovo();
        });

        this.$formNovo.on('submit', function (event) {
            event.preventDefault();
            self.salvarCadastro();
        });

        this.$formNovo.on('input', '.embalagens-campo-entrada', function () {
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

    abrirModalCadastro(linha) {
        var modal = this.$modal[0];
        if (!modal || typeof modal.showModal !== 'function' || this.$modal.prop('open')) return;
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
        var primeiroCampoInvalido = null;

        this.$modal.find('[data-modal-alerta]').text('');
        if (!descricao) {
            this.marcarErro('descricao', 'Informe a descrição.');
            primeiroCampoInvalido = primeiroCampoInvalido || 'descricao';
        } else if (tipo && descricao === tipo.descricao) {
            this.marcarErro('descricao', 'Altere a descrição para salvar.');
            primeiroCampoInvalido = primeiroCampoInvalido || 'descricao';
        }
        if (!tipo && !/^[A-Za-z0-9]{2,3}$/.test(sigla)) {
            this.marcarErro('sigla', 'Informe um código válido');
            primeiroCampoInvalido = primeiroCampoInvalido || 'sigla';
        }
        if (primeiroCampoInvalido) {
            this.$formNovo.find('[name="' + primeiroCampoInvalido + '"]').trigger('focus');
            return;
        }
        if (tipo && !Number.isInteger(Number(tipo.versao))) {
            this.$modal.find('[data-modal-alerta]').text('A versão deste tipo não veio da consulta. Clique em Buscar e tente de novo.');
            return;
        }

        var acao = tipo ? 'alterarTipo' : 'incluirTipo';
        var parametros = tipo ? montarParametrosAlteracao(tipo, descricao) : montarParametrosInclusao(sigla, descricao);
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
            if (tipo) self.avisar(escaparTextoHtml(saida.resultado.descricao + ' editado com sucesso!'), 'success');
            if (saida.resultado.repeticao) self.avisar('Esta gravação já tinha sido registrada pelo Datasul.', 'info');
            return self.aplicarFotografia(saida.resultado);
        });
    },

    reaplicarOrdem() {
        var ordem = $.map(this.tabela.getSorters(), function (ordenacao) { return { column: ordenacao.field, dir: ordenacao.dir }; });
        if (ordem.length) this.tabela.setSort(ordem);
    },

    alterarSituacao(linha, $interruptor) {
        var self = this;
        if (!linha || this.salvando) return;
        var tipo = linha.getData();
        if (!Number.isInteger(Number(tipo.versao))) {
            this.avisar('A versão deste tipo não veio da consulta. Clique em Buscar e tente de novo.', 'danger');
            return;
        }
        this.definirSalvando(true, $interruptor);

        return this.executarComando('alterarTipo', montarParametrosSituacao(tipo)).then(function (saida) {
            if (!saida.ok) {
                self.avisar(saida.mensagem, 'danger');
                return;
            }
            if (saida.resultado.repeticao) self.avisar('Esta gravação já tinha sido registrada pelo Datasul.', 'info');
            return self.aplicarFotografia(saida.resultado, false).then(function () {
                var mensagem = saida.resultado.descricao + (saida.resultado.ativo ? ' ativado' : ' desativado') + ' com sucesso!';
                mensagem = escaparTextoHtml(mensagem);
                self.avisar(mensagem, 'success');
            });
        }).then(function () {
            self.definirSalvando(false, $interruptor);
        }, function () {
            self.definirSalvando(false, $interruptor);
            self.avisar('Não foi possível atualizar a situação na tela. Clique em Buscar para conferir a lista.', 'danger');
        });
    },

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
        var descricaoEscapada = escaparTextoHtml(String(tipo.descricao));
        this.definirSalvando(true, $botao);
        return this.executarComando('alterarTipo', montarParametrosExclusao(tipo)).then(function (saida) {
            if (!saida.ok) {
                $alerta.text(saida.mensagem);
                return;
            }
            var paginaAtual = self.tabela.getPage();
            var linhaAtual = self.tabela.getRow(tipo.codTipo);
            var remocaoLinha = linhaAtual ? linhaAtual.delete() : $.Deferred().resolve().promise();
            return remocaoLinha.then(function () {
                return self.tabela.setPage(Math.max(1, Math.min(paginaAtual, self.tabela.getPageMax() || 1)));
            }).then(function () {
                self.definirSalvando(false, $botao);
                self.fecharModalExcluir();
                self.avisar(descricaoEscapada + ' excluído com sucesso!', 'success');
            });
        }).then(function () {
            self.definirSalvando(false, $botao);
        }, function () {
            self.definirSalvando(false, $botao);
            self.fecharModalExcluir();
            self.avisar('Não foi possível atualizar a lista após a exclusão. Clique em Buscar para conferir.', 'danger');
        });
    },

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
