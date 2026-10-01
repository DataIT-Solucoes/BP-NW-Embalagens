// Tabulator (tabela) vem do CDN. Carregado uma vez só, mesmo com várias instâncias do widget na página.
var NWE_TABULATOR_JS = 'https://cdnjs.cloudflare.com/ajax/libs/tabulator/6.4.0/js/tabulator.min.js';
var nweTabulatorPromise = null;

// DADOS MOCKADOS, só para visualizar a tabela. Trocar pelo dataset quando ele for definido.
var NWE_DADOS_MOCK = [
    { descricao: 'Caixa', sigla: 'CX' },
    { descricao: 'Fardo', sigla: 'FD' },
    { descricao: 'Saco', sigla: 'SC' },
    { descricao: 'Pallet', sigla: 'PL' },
    { descricao: 'Bag', sigla: 'BG' },
    { descricao: 'Granel', sigla: 'GR' },
    { descricao: 'Pacote', sigla: 'PC' },
    { descricao: 'Tambor', sigla: 'TB' },
    { descricao: 'Bombona', sigla: 'BB' },
    { descricao: 'Contêiner', sigla: 'CT' },
    { descricao: 'Engradado', sigla: 'EG' },
    { descricao: 'Bobina', sigla: 'BO' },
    { descricao: 'Rolo', sigla: 'RL' },
    { descricao: 'Unidade', sigla: 'UN' },
    { descricao: 'Lata', sigla: 'LT' },
    { descricao: 'Garrafa', sigla: 'GF' },
    { descricao: 'Barrica', sigla: 'BR' },
    { descricao: 'Sacola', sigla: 'SL' },
    { descricao: 'Envelope', sigla: 'EV' },
    { descricao: 'Display', sigla: 'DP' },
    { descricao: 'Kit', sigla: 'K' },
    { descricao: 'Balde', sigla: 'BD' }
];

var widget_nw_embalagens = SuperWidget.extend({

    //aba atualmente selecionada
    abaAtual: 'tipos-embalagem',

    //instância do Tabulator
    tabela: null,

    //linha do Tabulator em edição (null = modal em modo "novo") e linha aguardando confirmação de exclusão
    linhaEditando: null,
    linhaExcluindo: null,

    //método iniciado quando a widget é carregada
    init() {
        var self = this;
        this.$tabs = $('.nwe-tabs', this.DOM);
        this.moverIndicador();
        $(window).on('resize.nwe' + this.instanceId, function () { self.moverIndicador(); });
        //a fonte Mulish chega depois e muda a largura da aba: medir de novo
        if (document.fonts && document.fonts.ready) {
            document.fonts.ready.then(function () { self.moverIndicador(); });
            document.fonts.addEventListener('loadingdone', function () { self.moverIndicador(); });
        }

        this.carregarTabulator().then(function () {
            self.montarTabela();
        }, function () {
            $('[data-tabela]', self.DOM).html('<p class="nwe-tabela-erro">Não foi possível carregar a tabela. Verifique a conexão com a internet e recarregue a página.</p>');
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
            'filtro-sigla': ['keydown_teclaFiltro'],
            'novo': ['click_abrirModalNovo'],
            'fechar-modal': ['click_fecharModalNovo'],
            'fechar-excluir': ['click_fecharModalExcluir'],
            'confirmar-excluir': ['click_confirmarExclusao']
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

    // ---------- Tabela ----------

    carregarTabulator() {
        if (window.Tabulator) return Promise.resolve();
        if (!nweTabulatorPromise) {
            nweTabulatorPromise = new Promise(function (resolve, reject) {
                var script = document.createElement('script');
                script.src = NWE_TABULATOR_JS;
                script.onload = resolve;
                script.onerror = function () {
                    nweTabulatorPromise = null;
                    reject();
                };
                document.head.appendChild(script);
            });
        }
        return nweTabulatorPromise;
    },

    montarTabela() {
        var self = this;
        this.tabela = new Tabulator($('[data-tabela]', this.DOM)[0], {
            data: NWE_DADOS_MOCK,
            layout: 'fitColumns',
            responsiveLayout: false,
            pagination: true,
            paginationSize: 10,
            paginationCounter: function (pageSize, currentRow, currentPage, totalRows) {
                if (!totalRows) return '';
                var ate = Math.min(currentRow + pageSize - 1, totalRows);
                return 'Mostrando ' + currentRow + '–' + ate + ' de ' + totalRows;
            },
            initialSort: [{ column: 'descricao', dir: 'asc' }],
            placeholder: 'Nenhum tipo de embalagem encontrado.',
            locale: 'pt-br',
            langs: {
                'pt-br': {
                    data: { loading: 'Carregando...', error: 'Erro ao carregar' },
                    pagination: {
                        //o Tabulator coloca estes textos como HTML no botão: ícones em vez de « ‹ › »
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
                    title: 'Sigla', field: 'sigla', sorter: 'string', width: 140, hozAlign: 'left', vertAlign: 'middle',
                    formatter: function (cell) {
                        var span = document.createElement('span');
                        span.className = 'nwe-sigla';
                        span.textContent = cell.getValue();
                        return span;
                    }
                },
                {
                    //sem ordenação de verdade: a seta do cabeçalho é só visual (CSS .nwe-col-acoes)
                    title: 'Ações', headerSort: false, cssClass: 'nwe-col-acoes', width: 120, hozAlign: 'right', vertAlign: 'middle',
                    formatter: function (cell) { return self.montarBotoesAcoes(cell.getRow().getData()); },
                    cellClick: function (event, cell) {
                        var botao = event.target.closest('[data-acao]');
                        if (!botao) return;
                        if (botao.getAttribute('data-acao') === 'editar') self.abrirModalEditar(cell.getRow());
                        else self.abrirModalExcluir(cell.getRow());
                    }
                }
            ]
        });
    },

    montarBotoesAcoes(dados) {
        var grupo = document.createElement('div');
        grupo.className = 'nwe-acoes';
        [
            { acao: 'editar', icone: 'bi-pencil', texto: 'Editar' },
            { acao: 'excluir', icone: 'bi-trash3', texto: 'Excluir' }
        ].forEach(function (b) {
            var botao = document.createElement('button');
            botao.type = 'button';
            botao.className = 'nwe-acao nwe-acao-' + b.acao;
            botao.setAttribute('data-acao', b.acao);
            botao.setAttribute('aria-label', b.texto + ' ' + dados.descricao);
            botao.title = b.texto;
            botao.innerHTML = '<i class="bi ' + b.icone + '" aria-hidden="true"></i>';
            grupo.appendChild(botao);
        });
        return grupo;
    },

    buscar(htmlElement, event) {
        if (!this.tabela) return;
        var tipo = this.normalizar($('[data-filtro-tipo]', this.DOM).val());
        var sigla = this.normalizar($('[data-filtro-sigla]', this.DOM).val());
        var self = this;

        if (!tipo && !sigla) {
            this.tabela.clearFilter();
            return;
        }
        this.tabela.setFilter(function (linha) {
            return self.normalizar(linha.descricao).indexOf(tipo) !== -1
                && self.normalizar(linha.sigla).indexOf(sigla) !== -1;
        });
    },

    //Enter nos campos de filtro dispara a busca
    teclaFiltro(htmlElement, event) {
        if (event.key !== 'Enter') return;
        event.preventDefault();
        this.buscar();
    },

    // ---------- Modal "Novo tipo de embalagem" (<dialog> nativo, não o FLUIGC.modal) ----------

    prepararModalNovo() {
        var self = this;
        this.$modal = $('[data-modal-novo]', this.DOM);
        this.$formNovo = this.$modal.find('form');

        //fechar com Esc não passa por fecharModalNovo: o "close" cobre esse caso.
        //Ele é assíncrono: se o modal já foi reaberto (ex.: em modo edição), não apaga o que foi preenchido.
        this.$modal.on('close', function () {
            if (!self.$modal[0].open) self.limparFormNovo();
        });

        //clique no fundo escurecido: o alvo é o próprio <dialog> (o conteúdo fica dentro do <form>)
        this.$modal.on('click', function (event) {
            if (event.target === self.$modal[0]) self.fecharModalNovo();
        });

        this.$formNovo.on('submit', function (event) {
            event.preventDefault();
            self.salvarNovo();
        });

        //o erro de um campo some assim que a pessoa volta a digitar nele
        this.$formNovo.on('input', '.nwe-campo-input', function () {
            self.marcarErro(this.name, '');
        });
    },

    abrirModalNovo(htmlElement, event) {
        this.abrirModalCadastro(null);
    },

    abrirModalEditar(linha) {
        this.abrirModalCadastro(linha);
    },

    //mesmo modal para criar (linha = null) e editar (linha = linha do Tabulator)
    abrirModalCadastro(linha) {
        var modal = this.$modal[0];
        if (!modal || typeof modal.showModal !== 'function' || modal.open) return;
        //limpa também ao abrir: o evento "close" é assíncrono e o Chrome não o dispara com a aba oculta
        this.limparFormNovo();

        var editando = !!linha;
        this.$modal.find('[data-modal-titulo]').text(editando ? 'Editar tipo de embalagem' : 'Novo tipo de embalagem');
        this.$modal.find('[data-modal-subtitulo]').text(editando ? 'Altere a descrição ou a sigla e salve.' : 'Preencha a descrição e a sigla para cadastrar.');
        this.$modal.find('[data-modal-salvar]').text(editando ? 'Salvar alterações' : 'Salvar');
        if (editando) {
            this.linhaEditando = linha;
            this.$formNovo.find('[name="descricao"]').val(linha.getData().descricao);
            this.$formNovo.find('[name="sigla"]').val(linha.getData().sigla);
        }
        modal.showModal();
    },

    fecharModalNovo(htmlElement, event) {
        var modal = this.$modal[0];
        if (!modal || !modal.open) return;
        modal.close();
        this.limparFormNovo();
    },

    limparFormNovo() {
        this.linhaEditando = null;
        this.$formNovo[0].reset();
        this.marcarErro('descricao', '');
        this.marcarErro('sigla', '');
    },

    marcarErro(campo, mensagem) {
        this.$formNovo.find('[name="' + campo + '"]')
            .toggleClass('is-invalido', !!mensagem)
            .attr('aria-invalid', mensagem ? 'true' : 'false');
        this.$formNovo.find('[data-erro="' + campo + '"]').text(mensagem);
    },

    salvarNovo() {
        var self = this;
        var descricao = $.trim(this.$formNovo.find('[name="descricao"]').val());
        var sigla = $.trim(this.$formNovo.find('[name="sigla"]').val());
        var primeiroInvalido = null;

        if (!descricao) {
            this.marcarErro('descricao', 'Informe a descrição.');
            primeiroInvalido = primeiroInvalido || 'descricao';
        }
        if (!sigla) {
            this.marcarErro('sigla', 'Informe a sigla.');
            primeiroInvalido = primeiroInvalido || 'sigla';
        } else if (sigla.length > 2) {
            this.marcarErro('sigla', 'A sigla tem no máximo 2 caracteres.');
            primeiroInvalido = primeiroInvalido || 'sigla';
        }
        if (primeiroInvalido) {
            this.$formNovo.find('[name="' + primeiroInvalido + '"]').trigger('focus');
            return;
        }

        //MOCK: só altera a tabela da tela. Trocar pela gravação no dataset quando ele for definido.
        var linhaEditando = this.linhaEditando;   //guardar antes: fechar limpa o formulário
        this.fecharModalNovo();
        if (!this.tabela) return;

        var gravar = linhaEditando
            ? linhaEditando.update({ descricao: descricao, sigla: sigla }).then(function () {
                linhaEditando.reformat();   //atualiza o aria-label dos botões de ação
                return linhaEditando;
            })
            : this.tabela.addRow({ descricao: descricao, sigla: sigla });

        gravar.then(function (linha) {
            self.reaplicarOrdem();
            self.destacarLinha(linha);
        });
    },

    reaplicarOrdem() {
        var ordem = this.tabela.getSorters().map(function (s) { return { column: s.field, dir: s.dir }; });
        if (ordem.length) this.tabela.setSort(ordem);
    },

    // ---------- Confirmação de exclusão ----------

    prepararModalExcluir() {
        var self = this;
        this.$modalExcluir = $('[data-modal-excluir]', this.DOM);
        this.$modalExcluir.on('close', function () {
            if (!self.$modalExcluir[0].open) self.linhaExcluindo = null;
        });
        this.$modalExcluir.on('click', function (event) {
            if (event.target === self.$modalExcluir[0]) self.fecharModalExcluir();
        });
    },

    abrirModalExcluir(linha) {
        var modal = this.$modalExcluir[0];
        if (!modal || typeof modal.showModal !== 'function' || modal.open) return;
        var dados = linha.getData();
        this.linhaExcluindo = linha;
        this.$modalExcluir.find('[data-excluir-item]').text(dados.descricao + ' (' + dados.sigla + ')');
        modal.showModal();
    },

    fecharModalExcluir(htmlElement, event) {
        var modal = this.$modalExcluir[0];
        if (modal && modal.open) modal.close();
        this.linhaExcluindo = null;
    },

    //MOCK: só remove da tabela da tela. Trocar pela exclusão no dataset quando ele for definido.
    confirmarExclusao(htmlElement, event) {
        var linha = this.linhaExcluindo;
        this.fecharModalExcluir();
        if (linha) linha.delete();
    },

    //leva até a página da linha nova e pisca em laranja (se ela não estiver escondida pelo filtro)
    destacarLinha(linha) {
        var visivel = this.tabela.getRows('active').indexOf(linha) !== -1;
        if (!visivel) return;
        linha.pageTo().then(function () {
            var el = linha.getElement();
            el.classList.remove('nwe-linha-nova');
            void el.offsetWidth;
            el.classList.add('nwe-linha-nova');
            setTimeout(function () { el.classList.remove('nwe-linha-nova'); }, 2200);
        });
    },

    //minúsculas e sem acento, para a busca não depender disso
    normalizar(texto) {
        return String(texto || '').trim().toLowerCase()
            .normalize('NFD').replace(/[̀-ͯ]/g, '');
    }
});
