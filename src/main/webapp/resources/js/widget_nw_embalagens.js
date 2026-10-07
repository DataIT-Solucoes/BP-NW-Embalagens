// Tabulator (tabela) vem do CDN. Carregado uma vez só, mesmo com várias instâncias do widget na página.
var NWE_TABULATOR_JS = 'https://cdnjs.cloudflare.com/ajax/libs/tabulator/6.4.0/js/tabulator.min.js';
var nweTabulatorPromise = null;

// Tipos vêm do Dataset central dsNwEmbalagens (fonte em datasets/dsNwEmbalagens.js) pela função
// chamarEmbalagens (resources/js/chamar-embalagens.js). Cada consulta traz UMA página; a próxima usa o cursor.
// NWE_LIMITE_PAGINA é o limite de NEGÓCIO enviado à API (máx. 100). O limit "1" do transporte fica no helper.
var NWE_LIMITE_PAGINA = 20;
// Código de tipo tem até 3 caracteres na API (ex.: Z9R). Texto desse tamanho também é procurado como código exato.
var NWE_MAX_CODIGO = 3;

// Mensagens da tela para os códigos mais comuns; os demais usam a mensagem devolvida pelo Dataset/API.
var NWE_MENSAGENS = {
    AUTORIZACAO_NAO_CONFIGURADA: 'O acesso a esta tela ainda não foi configurado no Fluig (grupos e permissões).',
    SEM_PERMISSAO: 'Você não tem permissão para esta ação.',
    ESCRITA_DESABILITADA: 'A gravação ainda não está habilitada para esta ação.',
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

// A API não tem filtro "código OU descrição" numa chamada só: a descrição pagina pelo cursor e,
// na primeira página, um texto curto também é procurado como código exato.
function nweConsultasTipos(termo, cursor) {
    var porDescricao = { limite: NWE_LIMITE_PAGINA };
    if (termo) porDescricao.descricao = termo;
    if (cursor) {
        porDescricao.aposCodigo = cursor;
        return [porDescricao];
    }
    var consultas = [porDescricao];
    if (termo && termo.length <= NWE_MAX_CODIGO) consultas.push({ codigoDe: termo, codigoAte: termo, limite: 1 });
    return consultas;
}

function nweLinhaTipo(tipo) {
    return { codTipo: tipo.codTipo, descricao: tipo.descricao, ativo: tipo.ativo === true, versao: tipo.versao };
}

// código exato primeiro, sem repetir o que a página por descrição também trouxe
function nweMesclarTipos(porDescricao, exatos) {
    var vistos = {};
    return (exatos || []).concat(porDescricao || []).filter(function (tipo) {
        if (vistos[tipo.codTipo]) return false;
        vistos[tipo.codTipo] = true;
        return true;
    }).map(nweLinhaTipo);
}

// Corpos de comando no contrato cadastral vigente: versao numérica (GetInteger no ABL), ativo booleano.
// Usuário e chave NÃO entram aqui: o usuário é injetado pelo Dataset e a chave pela intenção.
function nweParametrosInclusao(sigla, descricao) {
    return { codTipo: sigla, descricao: descricao, ativo: true, versao: 0 };
}

function nweParametrosAlteracao(tipo, descricao) {
    return { codTipo: tipo.codTipo, descricao: descricao, ativo: tipo.ativo, versao: Number(tipo.versao), acao: 'ALTERAR' };
}

// Inativar usa INATIVAR; reativar é ALTERAR com ativo = true (a API de tipos não tem exclusão).
function nweParametrosSituacao(tipo) {
    return {
        codTipo: tipo.codTipo, descricao: tipo.descricao, ativo: !tipo.ativo,
        versao: Number(tipo.versao), acao: tipo.ativo ? 'INATIVAR' : 'ALTERAR'
    };
}

// UUID v4 com getRandomValues: crypto.randomUUID só existe em HTTPS e o Fluig de teste é HTTP.
function nweNovaChave() {
    var bytes = new Uint8Array(16);
    window.crypto.getRandomValues(bytes);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    var hex = Array.prototype.map.call(bytes, function (b) { return (b + 0x100).toString(16).slice(1); }).join('');
    return hex.slice(0, 8) + '-' + hex.slice(8, 12) + '-' + hex.slice(12, 16) + '-' + hex.slice(16, 20) + '-' + hex.slice(20);
}

function nweChamar(acao, parametros, opcoes) {
    if (typeof chamarEmbalagens !== 'function') return Promise.reject(new Error('chamar-embalagens.js não carregado.'));
    return chamarEmbalagens(acao, parametros, opcoes);
}

var widget_nw_embalagens = SuperWidget.extend({

    //aba atualmente selecionada
    abaAtual: 'tipos-embalagem',

    //instância do Tabulator
    tabela: null,

    carregandoTipos: true,
    salvando: false,

    //filtro e cursor da lista atual: "Carregar mais" continua com o mesmo filtro
    termoAtual: '',
    cursorTipos: '',
    consultaSeq: 0,
    abortConsulta: null,

    //chave idempotente por intenção (ação + conteúdo); criado no init para não ser compartilhado entre instâncias
    intencoes: null,

    //linha do Tabulator em edição (null = modal em modo "novo") e linha aguardando inativar/reativar
    linhaEditando: null,
    linhaSituacao: null,

    //método iniciado quando a widget é carregada
    init() {
        var self = this;
        this.intencoes = {};
        this.definirCarregamentoTipos(true);
        this.$tabs = $('.nwe-tabs', this.DOM);
        this.moverIndicador();
        $(window).on('resize.nwe' + this.instanceId, function () { self.moverIndicador(); });
        //a fonte Mulish chega depois e muda a largura da aba: medir de novo
        if (document.fonts && document.fonts.ready) {
            document.fonts.ready.then(function () { self.moverIndicador(); });
            document.fonts.addEventListener('loadingdone', function () { self.moverIndicador(); });
        }

        //o botão "Carregar mais" fica no rodapé criado pelo Tabulator
        $(this.DOM).on('click', '[data-carregar-mais]', function () {
            if (!self.carregandoTipos && self.cursorTipos) self.carregarTipos(true);
        });

        this.carregarTabulator().then(function () {
            self.montarTabela();
        }, function () {
            $('[data-tabela]', self.DOM).html('<p class="nwe-tabela-erro">Não foi possível carregar a tabela. Verifique a conexão com a internet e recarregue a página.</p>');
            self.definirCarregamentoTipos(false);
        });

        this.prepararModalNovo();
        this.prepararModalSituacao();
    },

    //BIND de eventos
    bindings: {
        local: {
            'tab': ['click_selecionarAba', 'keydown_navegarAbas'],
            'buscar': ['click_buscar'],
            'filtro-tipo': ['keydown_teclaFiltro'],
            'novo': ['click_abrirModalNovo'],
            'fechar-modal': ['click_fecharModalNovo'],
            'fechar-situacao': ['click_fecharModalSituacao'],
            'confirmar-situacao': ['click_confirmarSituacao']
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
        //sem paginação local: cada consulta traz uma página da API e "Carregar mais" acrescenta a seguinte
        var rodape = document.createElement('div');
        rodape.className = 'nwe-rodape';
        rodape.innerHTML = '<span class="nwe-rodape-contador" aria-live="polite" data-contador></span>'
            + '<button type="button" class="nwe-btn nwe-btn-contorno nwe-btn-mais" data-carregar-mais hidden>'
            + '<i class="bi bi-arrow-down-circle" aria-hidden="true"></i><span data-carregar-mais-texto>Carregar mais</span></button>';

        this.tabela = new Tabulator($('[data-tabela]', this.DOM)[0], {
            data: [],
            index: 'codTipo',
            layout: 'fitColumns',
            responsiveLayout: false,
            footerElement: rodape,
            placeholder: 'Nenhum tipo de embalagem encontrado.',
            locale: 'pt-br',
            langs: {
                'pt-br': {
                    data: { loading: 'Carregando...', error: 'Erro ao carregar' }
                }
            },
            columns: [
                { title: 'Descrição', field: 'descricao', sorter: 'string', widthGrow: 3, minWidth: 160, vertAlign: 'middle' },
                {
                    title: 'Sigla', field: 'codTipo', sorter: 'string', width: 120, hozAlign: 'left', vertAlign: 'middle',
                    formatter: function (cell) {
                        var span = document.createElement('span');
                        span.className = 'nwe-sigla';
                        span.textContent = cell.getValue();
                        return span;
                    }
                },
                {
                    title: 'Situação', field: 'ativo', sorter: 'boolean', width: 130, hozAlign: 'left', vertAlign: 'middle',
                    formatter: function (cell) {
                        var span = document.createElement('span');
                        span.className = 'nwe-situacao ' + (cell.getValue() ? 'is-ativo' : 'is-inativo');
                        span.textContent = cell.getValue() ? 'Ativo' : 'Inativo';
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
                        else self.abrirModalSituacao(cell.getRow());
                    }
                }
            ]
        });
        this.tabela.on('tableBuilt', function () { self.carregarTipos(false); });
    },

    definirCarregamentoTipos(carregando) {
        this.carregandoTipos = carregando;
        $('[data-buscar], [data-novo], [data-carregar-mais]', this.DOM).prop('disabled', carregando);
    },

    //continuar = false: nova consulta com o texto do filtro; true: próxima página com o mesmo filtro e o cursor
    carregarTipos(continuar) {
        var self = this;
        var termo = continuar ? this.termoAtual : $.trim($('[data-filtro-tipo]', this.DOM).val());
        var consultas = nweConsultasTipos(termo, continuar ? this.cursorTipos : '');
        var seq = ++this.consultaSeq;

        if (this.abortConsulta) this.abortConsulta.abort();
        var controle = window.AbortController ? new AbortController() : null;
        this.abortConsulta = controle;

        this.definirCarregamentoTipos(true);
        if (continuar) {
            $('[data-carregar-mais-texto]', this.DOM).text('Carregando...');
        } else {
            this.tabela.alert('<div class="nwe-carregando" role="status" aria-label="Carregando tipos de embalagem"><span class="loader" aria-hidden="true"></span></div>');
        }

        Promise.all(consultas.map(function (parametros) {
            return nweChamar('consultarTipos', parametros, { signal: controle ? controle.signal : undefined });
        })).then(function (resultados) {
            if (seq !== self.consultaSeq) return;
            //sucesso = false nunca vira lista vazia
            var falha = resultados.filter(function (r) { return !r.sucesso; })[0];
            if (falha) {
                self.mostrarErroCarga(nweMensagem(falha, 'Não foi possível consultar os tipos de embalagem.'), falha.codigoErro, continuar);
                return;
            }
            var pagina = resultados[0];
            var linhas = nweMesclarTipos(pagina.dados, resultados[1] && resultados[1].dados);
            var gravar = continuar ? self.tabela.updateOrAddData(linhas) : self.tabela.setData(linhas);
            self.termoAtual = termo;
            self.cursorTipos = pagina.temMais ? pagina.proximoCodigo : '';
            return gravar.then(function () {
                if (continuar) self.reaplicarOrdem();
                self.tabela.clearAlert();
                self.definirCarregamentoTipos(false);
                self.atualizarRodape();
            }, function () {
                self.mostrarErroCarga('Não foi possível preencher a tabela de tipos de embalagem.', null, continuar);
            });
        }, function (erro) {
            //uma busca nova cancela a anterior: a resposta antiga é ignorada
            if (seq !== self.consultaSeq) return;
            self.mostrarErroCarga('Não foi possível consultar os tipos de embalagem.', erro && erro.message, continuar);
        });
    },

    mostrarErroCarga(mensagem, detalhe, continuar) {
        if (window.console) console.error('[widget_nw_embalagens] ' + (detalhe ? detalhe + ': ' : '') + mensagem);
        this.definirCarregamentoTipos(false);
        if (continuar) {
            //a página que já está na tela continua valendo; o cursor fica para tentar de novo
            this.atualizarRodape();
            this.avisar(mensagem, 'danger');
            return;
        }
        this.cursorTipos = '';
        this.tabela.clearData();
        this.atualizarRodape();
        //o Tabulator trata texto como HTML: a mensagem da API vai como texto puro
        var aviso = document.createElement('span');
        aviso.textContent = mensagem + ' Clique em Buscar para tentar de novo.';
        this.tabela.alert(aviso, 'error');
    },

    atualizarRodape() {
        var total = this.tabela ? this.tabela.getDataCount() : 0;
        var texto = !total ? '' : 'Mostrando ' + total + (total === 1 ? ' tipo' : ' tipos') + (this.cursorTipos ? ' · há mais resultados' : '');
        $('[data-contador]', this.DOM).text(texto);
        $('[data-carregar-mais-texto]', this.DOM).text('Carregar mais');
        $('[data-carregar-mais]', this.DOM).prop('hidden', !this.cursorTipos);
    },

    montarBotoesAcoes(dados) {
        var grupo = document.createElement('div');
        grupo.className = 'nwe-acoes';
        [
            { acao: 'editar', classe: 'editar', icone: 'bi-pencil', texto: 'Editar' },
            dados.ativo
                ? { acao: 'situacao', classe: 'inativar', icone: 'bi-slash-circle', texto: 'Inativar' }
                : { acao: 'situacao', classe: 'reativar', icone: 'bi-arrow-counterclockwise', texto: 'Reativar' }
        ].forEach(function (b) {
            var botao = document.createElement('button');
            botao.type = 'button';
            botao.className = 'nwe-acao nwe-acao-' + b.classe;
            botao.setAttribute('data-acao', b.acao);
            botao.setAttribute('aria-label', b.texto + ' ' + dados.descricao);
            botao.title = b.texto;
            botao.innerHTML = '<i class="bi ' + b.icone + '" aria-hidden="true"></i>';
            grupo.appendChild(botao);
        });
        return grupo;
    },

    buscar(htmlElement, event) {
        if (!this.tabela || this.carregandoTipos) return;
        this.carregarTipos(false);
    },

    //Enter no campo de filtro dispara a busca
    teclaFiltro(htmlElement, event) {
        if (event.key !== 'Enter') return;
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

        return nweChamar(acao, corpo).then(function (resultado) {
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
    aplicarFotografia(resultado) {
        var self = this;
        return this.tabela.updateOrAddData([nweLinhaTipo(resultado)]).then(function () {
            var linha = self.tabela.getRow(resultado.codTipo);
            if (!linha) return;
            linha.reformat();   //atualiza situação e botões de ação
            self.reaplicarOrdem();
            self.atualizarRodape();
            self.destacarLinha(linha);
        });
    },

    avisar(mensagem, tipo) {
        if (window.FLUIGC && FLUIGC.toast) FLUIGC.toast({ title: '', message: mensagem, type: tipo });
    },

    // ---------- Modal "Novo/Editar tipo de embalagem" (<dialog> nativo, não o FLUIGC.modal) ----------

    prepararModalNovo() {
        var self = this;
        this.$modal = $('[data-modal-novo]', this.DOM);
        this.$formNovo = this.$modal.find('form');

        //fechar com Esc não passa por fecharModalNovo: o "close" cobre esse caso.
        //Ele é assíncrono: se o modal já foi reaberto (ex.: em modo edição), não apaga o que foi preenchido.
        this.$modal.on('close', function () {
            if (!self.$modal[0].open) self.limparFormNovo();
        });
        //enquanto grava, o modal não fecha (nem pelo Esc)
        this.$modal.on('cancel', function (event) {
            if (self.salvando) event.preventDefault();
        });

        //clique no fundo escurecido: o alvo é o próprio <dialog> (o conteúdo fica dentro do <form>)
        this.$modal.on('click', function (event) {
            if (event.target === self.$modal[0]) self.fecharModalNovo();
        });

        this.$formNovo.on('submit', function (event) {
            event.preventDefault();
            self.salvarCadastro();
        });

        //o erro de um campo some assim que a pessoa volta a digitar nele
        this.$formNovo.on('input', '.nwe-campo-input', function () {
            self.marcarErro(this.name, '');
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
        if (!modal || typeof modal.showModal !== 'function' || modal.open) return;
        //limpa também ao abrir: o evento "close" é assíncrono e o Chrome não o dispara com a aba oculta
        this.limparFormNovo();

        var editando = !!linha;
        this.$modal.find('[data-modal-titulo]').text(editando ? 'Editar tipo de embalagem' : 'Novo tipo de embalagem');
        this.$modal.find('[data-modal-subtitulo]').text(editando ? 'Altere a descrição e salve.' : 'Preencha a descrição e a sigla para cadastrar.');
        this.$modal.find('[data-modal-salvar]').text(editando ? 'Salvar alterações' : 'Salvar');
        //a sigla (código do tipo) não muda depois do cadastro
        this.$formNovo.find('[name="sigla"]').prop('readOnly', editando);
        this.$formNovo.find('[data-sigla-dica]').text(editando ? 'A sigla não pode ser alterada.' : 'Até 2 caracteres.');
        if (editando) {
            this.linhaEditando = linha;
            this.$formNovo.find('[name="descricao"]').val(linha.getData().descricao);
            this.$formNovo.find('[name="sigla"]').val(linha.getData().codTipo);
        }
        modal.showModal();
    },

    fecharModalNovo(htmlElement, event) {
        var modal = this.$modal[0];
        if (!modal || !modal.open || this.salvando) return;
        modal.close();
        this.limparFormNovo();
    },

    limparFormNovo() {
        this.linhaEditando = null;
        this.$formNovo[0].reset();
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
        var descricao = $.trim(this.$formNovo.find('[name="descricao"]').val());
        var sigla = $.trim(this.$formNovo.find('[name="sigla"]').val());
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
        if (!tipo) {
            if (!sigla) {
                this.marcarErro('sigla', 'Informe a sigla.');
                primeiroInvalido = primeiroInvalido || 'sigla';
            } else if (sigla.length > 2) {
                this.marcarErro('sigla', 'A sigla tem no máximo 2 caracteres.');
                primeiroInvalido = primeiroInvalido || 'sigla';
            }
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

        this.executarComando(acao, parametros).then(function (saida) {
            self.definirSalvando(false, $salvar);
            if (!saida.ok) {
                if (saida.codigoErro === 'TIPO_JA_EXISTE') {
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
        var ordem = this.tabela.getSorters().map(function (s) { return { column: s.field, dir: s.dir }; });
        if (ordem.length) this.tabela.setSort(ordem);
    },

    // ---------- Confirmação de inativar/reativar ----------

    prepararModalSituacao() {
        var self = this;
        this.$modalSituacao = $('[data-modal-situacao]', this.DOM);
        this.$modalSituacao.on('close', function () {
            if (!self.$modalSituacao[0].open) self.linhaSituacao = null;
        });
        this.$modalSituacao.on('cancel', function (event) {
            if (self.salvando) event.preventDefault();
        });
        this.$modalSituacao.on('click', function (event) {
            if (event.target === self.$modalSituacao[0]) self.fecharModalSituacao();
        });
    },

    abrirModalSituacao(linha) {
        var modal = this.$modalSituacao[0];
        if (!modal || typeof modal.showModal !== 'function' || modal.open) return;
        var dados = linha.getData();
        var inativar = dados.ativo;
        this.linhaSituacao = linha;
        this.$modalSituacao.toggleClass('is-reativar', !inativar);
        this.$modalSituacao.find('[data-situacao-icone]').attr('class', 'bi ' + (inativar ? 'bi-slash-circle' : 'bi-arrow-counterclockwise'));
        this.$modalSituacao.find('[data-situacao-titulo]').text(inativar ? 'Inativar tipo de embalagem?' : 'Reativar tipo de embalagem?');
        this.$modalSituacao.find('[data-situacao-item]').text(dados.descricao + ' (' + dados.codTipo + ')');
        this.$modalSituacao.find('[data-situacao-efeito]').text(inativar
            ? ' ficará inativo e deixará de ser oferecido nas seleções. Você pode reativá-lo depois.'
            : ' voltará a ficar ativo.');
        this.$modalSituacao.find('[data-situacao-botao]').text(inativar ? 'Inativar' : 'Reativar');
        this.$modalSituacao.find('[data-confirmar-situacao]')
            .toggleClass('nwe-btn-perigo', inativar).toggleClass('nwe-btn-destaque', !inativar);
        this.$modalSituacao.find('[data-situacao-alerta]').text('');
        modal.showModal();
    },

    fecharModalSituacao(htmlElement, event) {
        var modal = this.$modalSituacao[0];
        if (this.salvando) return;
        if (modal && modal.open) modal.close();
        this.linhaSituacao = null;
    },

    confirmarSituacao(htmlElement, event) {
        var self = this;
        var linha = this.linhaSituacao;
        if (!linha || this.salvando) return;
        var tipo = linha.getData();
        var $alerta = this.$modalSituacao.find('[data-situacao-alerta]');
        $alerta.text('');
        if (!Number.isInteger(Number(tipo.versao))) {
            $alerta.text('A versão deste tipo não veio da consulta. Clique em Buscar e tente de novo.');
            return;
        }
        var $botao = this.$modalSituacao.find('[data-confirmar-situacao]');
        this.definirSalvando(true, $botao);

        this.executarComando('alterarTipo', nweParametrosSituacao(tipo)).then(function (saida) {
            self.definirSalvando(false, $botao);
            if (!saida.ok) {
                $alerta.text(saida.mensagem);
                return;
            }
            self.fecharModalSituacao();
            if (saida.resultado.repeticao) self.avisar('Esta gravação já tinha sido registrada pelo Datasul.', 'info');
            return self.aplicarFotografia(saida.resultado);
        });
    },

    //rola até a linha gravada e pisca em amarelo (se ela não estiver escondida)
    destacarLinha(linha) {
        var visivel = this.tabela.getRows('active').indexOf(linha) !== -1;
        if (!visivel) return;
        var el = linha.getElement();
        if (el.scrollIntoView) el.scrollIntoView({ block: 'nearest' });
        el.classList.remove('nwe-linha-nova');
        void el.offsetWidth;
        el.classList.add('nwe-linha-nova');
        setTimeout(function () { el.classList.remove('nwe-linha-nova'); }, 2200);
    }
});
