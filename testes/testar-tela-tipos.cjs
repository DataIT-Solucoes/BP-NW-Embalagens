// Cadeia local da tela de tipos, sem Fluig/Datasul reais:
// funcoes do widget -> chamarEmbalagens ($.ajax) -> POST /api/public/ecm/dataset/search (simulado)
// -> dsNwEmbalagens.createDataset -> invoke do servico autorizado (simulado).
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm'), assert = require('node:assert/strict');
const { webcrypto } = require('node:crypto');
const { criarJQueryFalso } = require('./jquery-falso.cjs');
const root = path.resolve(__dirname, '..');
const ler = f => fs.readFileSync(path.join(root, f), 'utf8');
const fonteDataset = ler('datasets/dsNwEmbalagens.js');
const fonteWidget = ler('src/main/webapp/resources/js/widget_nw_embalagens.js');

function montar(opcoes = {}) {
    const chamadasApi = [], transportes = [];
    const estado = { respostas: [], falharInvoke: false, falharRede: false, regras: opcoes.regras };
    const ds = {
        JSON, Object, Math, Number, String, Error, isFinite, encodeURIComponent,
        getValue: k => k === 'WKUser' ? 'usuario-sessao' : k === 'WKCompany' ? '1' : '',
        log: { warn() {} }, ConstraintType: { MUST: 1 },
        DatasetBuilder: { newDataset: () => ({ columns: [], values: [], addColumn(n) { this.columns.push(n); }, addRow(r) { this.values.push(r); } }) },
        DatasetFactory: {
            createConstraint: (name, initial, final, type) => ({ name, initial, final, type }),
            getDataset: () => ({ rowsCount: 1, getValue: (i, k) => k === 'colleagueGroupPK.companyId' ? '1' : k === 'colleagueGroupPK.colleagueId' ? 'usuario-sessao' : 'grupo-tipos' })
        },
        fluigAPI: { getAuthorizeClientService: () => ({ invoke(raw) {
            chamadasApi.push(JSON.parse(raw));
            if (estado.falharInvoke) throw new Error('Read timed out');
            const r = estado.respostas.shift();
            return { getHttpStatusResult: () => '200', getResult: () => JSON.stringify(r) };
        } }) }
    };
    vm.createContext(ds); vm.runInContext(fonteDataset, ds);
    if (Array.isArray(estado.regras)) ds.NW_CONFIG.regras = estado.regras;

    // Transporte do Fluig: filterFields [campo, valor, ...] viram constraints do Dataset.
    const $ = criarJQueryFalso(opcoesAjax => {
        if (estado.falharRede) throw new Error('rede');
        assert.equal(opcoesAjax.url, '/api/public/ecm/dataset/search');
        assert.equal(opcoesAjax.type, 'POST');
        const corpo = JSON.parse(opcoesAjax.data);
        transportes.push(corpo);
        assert.equal(corpo.datasetId, 'dsNwEmbalagens');
        assert.equal(corpo.limit, '1');
        // o Fluig acrescenta sqlLimit em toda chamada (visto no TESTE em 07/10/2026)
        const constraints = [{ getFieldName: () => 'sqlLimit', getInitialValue: () => corpo.limit, getFinalValue: () => corpo.limit }];
        for (let i = 0; i < corpo.filterFields.length; i += 2) {
            const nome = corpo.filterFields[i], valor = corpo.filterFields[i + 1];
            constraints.push({ getFieldName: () => nome, getInitialValue: () => valor, getFinalValue: () => valor });
        }
        const saida = ds.createDataset(null, constraints, null);
        const content = saida.values.map(linha => Object.fromEntries(saida.columns.map((c, i) => [c, linha[i]])));
        return { status: 200, corpo: JSON.stringify({ content, message: null }) };
    });
    const web = {
        JSON, Object, Array, Math, Number, String, Error, Uint8Array, setTimeout, clearTimeout,
        window: { crypto: webcrypto },
        SuperWidget: { extend: o => o },
        $
    };
    vm.createContext(web); vm.runInContext(fonteWidget, web);
    return { ds, web, estado, chamadasApi, transportes };
}

const REGRA_TIPOS = [{ grupo: 'grupo-tipos', acoes: ['consultarTipos', 'consultarTiposApoio', 'incluirTipo', 'alterarTipo'], estabelecimentos: [] }];
const pagina = (dados, temMais = false, proximoCodigo = '') => ({ sucesso: true, codigoErro: '', mensagem: '', total: dados.length, temMais, proximoCodigo, dados });
const fotografia = (t, extra = {}) => Object.assign({ sucesso: true, repeticao: false, codigoErro: '', mensagem: '', idEvento: '41' }, t, extra);
const query = chamada => new URL('http://x' + chamada.endpoint).searchParams;

function montarInterruptor(h, tipo) {
    const avisos = [], estadoBotao = {};
    const botao = {
        prop(k, v) { estadoBotao[k] = v; return this; },
        attr(k, v) { estadoBotao[k] = v; return this; }
    };
    const tela = Object.assign({}, h.web.cadastroEmbalagens, {
        salvando: false, intencoes: {},
        avisar: (mensagem, nivel) => avisos.push({ mensagem, nivel }),
        aplicarFotografia(resultado) {
            Object.assign(tipo, h.web.normalizarTipoEmbalagem(resultado));
            return Promise.resolve();
        }
    });
    return { tela, tipo, linha: { getData: () => tipo }, botao, estadoBotao, avisos };
}

function montarConsultaTabela(h, codigo = '') {
    const $original = h.web.$;
    const filtro = { valor: codigo ? codigo + ' — TIPO' : '', handlers: {} };
    const avisos = [], botao = { prop() { return this; } };
    const input = {
        val: () => filtro.valor,
        prop: () => false,
        on(eventos, handler) { for (const nome of eventos.split(' ')) (filtro.handlers[nome] ||= []).push(handler); return this; }
    };
    filtro.emitir = (evento, item) => { for (const fn of filtro.handlers[evento] || []) fn({ item }); };
    const $ = function (seletor) {
        if (seletor === '[data-filtro-tipo]') return input;
        if (seletor === '[data-buscar], [data-novo]') return botao;
        if (seletor === '[data-tabela]') return [{}];
        if (seletor === '<span>') {
            const span = [{}]; span.text = v => { span[0].textContent = v; return span; }; return span;
        }
        throw new Error('Seletor inesperado: ' + seletor);
    };
    Object.assign($, $original); h.web.$ = $;
    const dados = { linhas: [], gravacoes: 0, pagina: 7, alerta: null, autocomplete: null, badges: [] };
    h.web.FLUIGC = h.web.window.FLUIGC = {
        autocomplete(target, options) {
            assert.equal(target, input); dados.autocomplete = options;
            return { val(valor) { if (arguments.length) filtro.valor = valor; return filtro.valor; } };
        }
    };
    const tabela = {
        alert(conteudo, tipo) { dados.alerta = { conteudo, tipo }; },
        clearAlert() { dados.alerta = null; },
        clearData() { dados.linhas = []; },
        setData(linhas) { dados.linhas = linhas; dados.gravacoes++; return Promise.resolve(); },
        setPage(pagina) { dados.pagina = pagina; return Promise.resolve(); }
    };
    const instancia = Object.assign({}, h.web.cadastroEmbalagens, {
        tabela, consultaSeq: 0, consultasAbertas: [], instanceId: 99,
        tipoSelecionado: codigo ? { codigo, rotulo: filtro.valor } : null,
        // a badge mexe no DOM; aqui só registra a chamada
        mostrarSelecionado: item => dados.badges.push(item.codigo),
        avisar: (mensagem, nivel) => avisos.push({ mensagem, nivel })
    });
    return { tela: instancia, tabela, dados, filtro, avisos };
}

async function main() {
    let casos = 0;
    const caso = async (nome, fn) => { await fn(); casos++; console.log('OK ' + nome); };

    function montarInicio(h) {
        const s = montarConsultaTabela(h), original = h.web.$;
        function elemento() {
            return {
                length: 1, props: {}, attrs: {}, removido: false,
                prop(k, v) { this.props[k] = v; return this; },
                attr(k, v) { this.attrs[k] = v; return this; },
                append() { return this; }, appendTo() { return this; }, text() { return this; },
                on() { return this; }, last() { return this; }, html() { return this; },
                stop() { return this; }, fadeOut(ms, fn) { this.duracao = ms; fn(); return this; },
                remove() { this.removido = true; }
            };
        }
        const dom = elemento(), filtro = elemento(), toast = elemento(), botoes = elemento();
        const toasts = [], timers = [];
        const $ = function (seletor, attrs) {
            if (seletor === dom || seletor === h.web.window) return dom;
            if (seletor === '[data-filtro-tipo]') return filtro;
            if (seletor === '[data-buscar], [data-novo]') return botoes;
            if (seletor === '#toaster .alert') return toast;
            if (seletor === '.embalagens-abas' || seletor === '[data-tabela]') return elemento();
            if (seletor === '<div>' || (seletor === '<span>' && attrs)) return elemento();
            return original(seletor);
        };
        Object.assign($, original); h.web.$ = $;
        h.web.document = {};
        h.web.FLUIGC.toast = opcoes => toasts.push(opcoes);
        h.web.setTimeout = (fn, ms) => { timers.push({ fn, ms }); };
        const biblioteca = $.Deferred();
        Object.assign(s.tela, {
            DOM: dom, prepararAutocompleteTipo() {}, moverIndicador() {},
            prepararModalNovo() {}, prepararModalExcluir() {},
            carregarTabulator: () => biblioteca.promise(), montarTabela() { this.montou = true; },
            obterCodigoFiltro: () => ''
        });
        return Object.assign(s, { dom, filtro, toast, botoes, toasts, timers, biblioteca });
    }

    await caso('inicio: loading aguarda biblioteca, todas as paginas e renderizacao; nao reaparece na busca', async () => {
        const h = montar({ regras: REGRA_TIPOS }), s = montarInicio(h);
        s.tela.init();
        assert.equal(s.dom.attrs['aria-busy'], 'true');
        assert.equal(s.filtro.props.disabled, true); assert.equal(s.botoes.props.disabled, true);
        assert.equal(s.toasts.length, 1); assert.equal(s.toasts[0].type, 'info');
        assert.equal(s.toasts[0].timeout, 600000);
        s.biblioteca.resolve(); await Promise.resolve();
        assert.equal(s.tela.montou, true); assert.equal(s.tela.carregamentoInicial, true);
        h.estado.respostas.push(pagina([{ codTipo: 'CA', descricao: 'CAIXA', ativo: true, versao: 1 }], true, 'CA'), pagina([]));
        let liberarTabela;
        s.tabela.setPage = () => new Promise(resolve => { liberarTabela = resolve; });
        const consulta = s.tela.carregarTipos();
        while (!liberarTabela) await new Promise(resolve => setImmediate(resolve));
        assert.equal(h.chamadasApi.length, 2); assert.equal(s.tela.carregamentoInicial, true);
        assert.equal(s.dados.alerta, null); assert.equal(s.toast.removido, false);
        liberarTabela(); await consulta;
        assert.equal(s.tela.$carregandoGlobal.props.hidden, true);
        assert.equal(s.dom.attrs['aria-busy'], 'false'); assert.equal(s.filtro.props.disabled, false);
        assert.equal(s.botoes.props.disabled, false); assert.equal(s.toast.removido, false);
        assert.equal(s.timers[0].ms, 100); s.timers[0].fn();
        assert.equal(s.toast.removido, true); assert.equal(s.toast.duracao, 200);
        s.tabela.setPage = () => Promise.resolve(); h.estado.respostas.push(pagina([]));
        await s.tela.carregarTipos();
        assert.equal(s.toasts.length, 1); assert.equal(s.tela.carregamentoInicial, false);
    });

    await caso('inicio: falha da biblioteca libera overlay, filtro e botoes', async () => {
        const h = montar({ regras: REGRA_TIPOS }), s = montarInicio(h);
        s.tela.init(); s.biblioteca.reject(new Error('CDN indisponivel'));
        await Promise.resolve();
        assert.equal(s.tela.carregamentoInicial, false);
        assert.equal(s.tela.$carregandoGlobal.props.hidden, true);
        assert.equal(s.dom.attrs['aria-busy'], 'false'); assert.equal(s.filtro.props.disabled, false);
        assert.equal(s.botoes.props.disabled, false); assert.equal(s.timers.length, 1);
    });

    await caso('inicio: falha da consulta libera overlay e preserva alerta de erro', async () => {
        const h = montar({ regras: REGRA_TIPOS }), s = montarInicio(h);
        s.tela.init(); s.biblioteca.resolve(); await Promise.resolve();
        h.estado.falharRede = true;
        await s.tela.carregarTipos();
        assert.equal(s.tela.carregamentoInicial, false);
        assert.equal(s.tela.$carregandoGlobal.props.hidden, true);
        assert.equal(s.dados.alerta.tipo, 'error'); assert.equal(s.botoes.props.disabled, false);
        assert.equal(s.timers.length, 1);
    });

    function montarModal(h, sigla, tipo = null, descricao = 'CAIXA') {
        const dados = { erros: {}, removidas: 0, linhas: tipo ? [tipo] : [], fechou: false, foco: '', propriedades: {}, textos: {} };
        const valores = { sigla, descricao };
        const campo = nome => ({
            val(valor) { if (arguments.length) valores[nome] = valor; return valores[nome]; },
            trigger() { dados.foco = nome; },
            prop(propriedade, valor) { dados.propriedades[nome + '.' + propriedade] = valor; return this; },
            text(valor) { dados.textos[nome] = valor; }
        });
        const botao = { prop() { return this; }, attr() { return this; } };
        const tela = Object.assign({}, h.web.cadastroEmbalagens, {
            salvando: false, intencoes: {},
            linhaEditando: tipo ? { getData: () => tipo, delete() { dados.removidas++; dados.linhas = dados.linhas.filter(l => l.codTipo !== tipo.codTipo); return Promise.resolve(); } } : null,
            $formNovo: { find: seletor => seletor === '[type="submit"]' ? botao : campo(seletor.includes('sigla') ? 'sigla' : 'descricao'), trigger() {} },
            $modal: { 0: { showModal() { dados.abriu = true; } }, prop: () => false, find: seletor => ({ text(valor) { dados.textos[seletor] = valor; } }) },
            marcarErro: (nome, mensagem) => { dados.erros[nome] = mensagem; },
            fecharModalNovo() { dados.fechou = true; },
            tabela: {
                getPage: () => 1, getPageMax: () => 1,
                updateOrAddData(linhas) { dados.linhas = dados.linhas.filter(l => !linhas.some(n => n.codTipo === l.codTipo)).concat(linhas); return Promise.resolve(); },
                getRow: () => ({ reformat() {} }), setPage: () => Promise.resolve()
            },
            reaplicarOrdem() {}, destacarLinha() {}
        });
        return { tela, dados };
    }

    await caso('modal: inclusao aceita tres caracteres e edicao envia codigo original com nova descricao', async () => {
        for (const tipo of [null, { codTipo: 'CX', descricao: 'CAIXA', ativo: true, versao: 3 }]) {
            const h = montar({ regras: REGRA_TIPOS });
            const descricao = tipo ? 'CAIXA NOVA' : 'CAIXA';
            const codigo = tipo ? 'CX' : 'Z9R';
            // Mesmo se o campo for alterado fora da interface, editar usa a identidade em memoria.
            const s = montarModal(h, 'Z9R', tipo, descricao);
            h.estado.respostas.push(fotografia({ codTipo: codigo, descricao, ativo: true, versao: tipo ? 4 : 1 }));
            await s.tela.salvarCadastro();
            assert.equal(h.chamadasApi.length, 1);
            assert.equal(h.chamadasApi[0].params.codTipo, codigo);
            assert.equal(h.chamadasApi[0].params.descricao, descricao);
            assert.equal(h.chamadasApi[0].method, tipo ? 'patch' : 'post');
            assert.deepEqual(Object.keys(h.chamadasApi[0].params).sort(), (tipo ? ['acao', 'ativo', 'chaveIdempotente', 'codTipo', 'descricao', 'usuario', 'versao'] : ['ativo', 'chaveIdempotente', 'codTipo', 'descricao', 'usuario', 'versao']).sort());
            assert.deepEqual(Array.from(s.dados.linhas, l => l.codTipo), [codigo]);
            assert.equal(s.dados.removidas, 0);
            assert.equal(s.dados.fechou, true);
        }
    });

    await caso('modal: sigla somente leitura na edicao e liberada no cadastro', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarModal(h, '');
        const linha = { getData: () => ({ codTipo: 'CX', descricao: 'CAIXA', ativo: true, versao: 3 }) };
        s.tela.abrirModalCadastro(linha);
        assert.equal(s.dados.propriedades['sigla.readOnly'], true);
        assert.equal(s.tela.$formNovo.find('[name="sigla"]').val(), 'CX');
        assert.equal(s.dados.textos['[data-modal-subtitulo]'], 'Altere a descrição e salve.');
        s.tela.abrirModalCadastro(null);
        assert.equal(s.dados.propriedades['sigla.readOnly'], false);
    });

    await caso('modal: edicao exige descricao diferente mesmo se o campo sigla for manipulado', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarModal(h, 'Z9R', { codTipo: 'CX', descricao: 'CAIXA', ativo: true, versao: 3 });
        await s.tela.salvarCadastro();
        assert.equal(h.transportes.length, 0);
        assert.equal(s.dados.erros.descricao, 'Altere a descrição para salvar.');
    });

    await caso('modal: codigo invalido mostra mensagem curta no cadastro sem enviar comando', async () => {
        for (const sigla of ['', 'A', 'ABCD', 'ÁB', 'A-']) {
            const h = montar({ regras: REGRA_TIPOS });
            const s = montarModal(h, sigla);
            await s.tela.salvarCadastro();
            assert.equal(h.transportes.length, 0);
            assert.equal(s.dados.erros.sigla, 'Informe um código válido');
            assert.equal(s.dados.foco, 'sigla');
        }
    });

    await caso('modal: recusa CODIGO_INVALIDO da API aparece no campo com a mensagem solicitada', async () => {
        for (const tipo of [null, { codTipo: 'CX', descricao: 'CAIXA', ativo: true, versao: 3 }]) {
            const h = montar({ regras: REGRA_TIPOS });
            const s = montarModal(h, 'Z9R', tipo, tipo ? 'CAIXA NOVA' : 'CAIXA');
            h.estado.respostas.push({ sucesso: false, codigoErro: 'CODIGO_INVALIDO', mensagem: 'Informe um codigo com 2 ou 3 letras ASCII ou numeros.' });
            await s.tela.salvarCadastro();
            assert.equal(s.dados.erros.sigla, 'Informe um código válido');
            assert.equal(s.dados.foco, 'sigla');
            assert.equal(s.dados.fechou, false);
            assert.equal(s.dados.removidas, 0);
            assert.deepEqual(s.dados.linhas, tipo ? [tipo] : []);
        }
    });

    await caso('consulta: selecao busca somente o codigo exato, em uma chamada', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        h.estado.respostas.push(pagina([{ codTipo: 'CX', descricao: 'CAIXA', ativo: false, versao: 5 }]));
        const consultas = h.web.montarConsultasTipos('CX', '');
        assert.equal(consultas.length, 1);
        const r = await h.web.chamarEmbalagens('consultarTipos', consultas[0]);
        const q = query(h.chamadasApi[0]);
        assert.equal(q.get('codigoDe'), 'CX'); assert.equal(q.get('codigoAte'), 'CX');
        assert.equal(q.get('limite'), '1'); assert.equal(q.get('descricao'), null);
        assert.equal(r.dados[0].codTipo, 'CX'); assert.equal(r.dados[0].ativo, false);
    });

    await caso('consulta: campo vazio usa cursor sem filtro por codigo ou descricao', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        h.estado.respostas.push(pagina([{ codTipo: 'Z9R', descricao: 'CAIXA TESTE', ativo: true, versao: 4 }]));
        const consultas = h.web.montarConsultasTipos('', 'CX');
        const r = await h.web.chamarEmbalagens('consultarTipos', consultas[0]);
        const q = query(h.chamadasApi[0]);
        assert.equal(q.get('aposCodigo'), 'CX'); assert.equal(q.get('limite'), '20');
        assert.equal(q.get('descricao'), null); assert.equal(q.get('codigoDe'), null);
        assert.equal(r.sucesso, true);
    });

    await caso('consulta: sem grupos configurados volta recusa (nao lista vazia) e nao chama a API', async () => {
        const h = montar({ regras: [] });
        const r = await h.web.chamarEmbalagens('consultarTipos', h.web.montarConsultasTipos('', '')[0]);
        assert.equal(r.sucesso, false); assert.equal(r.codigoErro, 'AUTORIZACAO_NAO_CONFIGURADA'); assert.ok(!('dados' in r));
        assert.equal(h.chamadasApi.length, 0);
        assert.match(h.web.obterMensagemResultado(r, ''), /grupos e permissões/);
    });

    await caso('inclusao: POST com versao 0 numerica, ativo booleano, usuario da sessao e chave UUID', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        h.estado.respostas.push(fotografia({ codTipo: 'CX', descricao: 'CAIXA', ativo: true, versao: 1 }));
        const tela = { intencoes: {} };
        const saida = await h.web.cadastroEmbalagens.executarComando.call(tela, 'incluirTipo', h.web.montarParametrosInclusao('CX', 'CAIXA'));
        assert.equal(saida.ok, true); assert.equal(saida.resultado.versao, 1);
        const req = h.chamadasApi[0];
        assert.equal(req.method, 'post'); assert.match(req.endpoint, /\/controle-embalagens\/tipos$/);
        assert.equal(req.params.versao, 0); assert.equal(req.params.ativo, true); assert.equal(req.params.usuario, 'usuario-sessao');
        assert.match(req.params.chaveIdempotente, /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
        assert.ok(!('estabelecimentosPermitidos' in req.params));
        assert.deepEqual(Object.keys(tela.intencoes), []);
    });

    await caso('comando incerto: uma chamada por clique, mesma chave no novo clique, chave nova se o conteudo mudar', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const tela = { intencoes: {} };
        const tipo = { codTipo: 'CX', descricao: 'CAIXA', ativo: true, versao: 3 };
        h.estado.falharInvoke = true;
        let s = await h.web.cadastroEmbalagens.executarComando.call(tela, 'alterarTipo', h.web.montarParametrosAlteracao(tipo, 'CAIXA NOVA'));
        assert.equal(s.ok, false); assert.equal(s.incerto, true); assert.equal(h.chamadasApi.length, 1);
        assert.match(s.mensagem, /mesma chave/);
        const chave1 = h.chamadasApi[0].params.chaveIdempotente;
        h.estado.falharInvoke = false;
        h.estado.respostas.push(fotografia({ codTipo: 'CX', descricao: 'CAIXA NOVA', ativo: true, versao: 4 }, { repeticao: true }));
        s = await h.web.cadastroEmbalagens.executarComando.call(tela, 'alterarTipo', h.web.montarParametrosAlteracao(tipo, 'CAIXA NOVA'));
        assert.equal(h.chamadasApi.length, 2); assert.equal(h.chamadasApi[1].params.chaveIdempotente, chave1);
        assert.equal(s.ok, true); assert.equal(s.resultado.repeticao, true);
        h.estado.respostas.push(fotografia({ codTipo: 'CX', descricao: 'CAIXA OUTRA', ativo: true, versao: 5 }));
        await h.web.cadastroEmbalagens.executarComando.call(tela, 'alterarTipo', h.web.montarParametrosAlteracao(tipo, 'CAIXA OUTRA'));
        assert.notEqual(h.chamadasApi[2].params.chaveIdempotente, chave1);
        assert.equal(h.chamadasApi[2].method, 'patch'); assert.equal(h.chamadasApi[2].params.acao, 'ALTERAR'); assert.equal(h.chamadasApi[2].params.versao, 3);
    });

    await caso('transporte falho: helper rejeita, comando fica incerto e nao repete sozinho', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        h.estado.falharRede = true;
        const tela = { intencoes: {} };
        const s = await h.web.cadastroEmbalagens.executarComando.call(tela, 'incluirTipo', h.web.montarParametrosInclusao('CX', 'CAIXA'));
        assert.equal(s.ok, false); assert.equal(s.incerto, true); assert.equal(h.chamadasApi.length, 0);
        assert.equal(Object.keys(tela.intencoes).length, 1);
    });

    await caso('recusa de negocio: TIPO_JA_EXISTE e CONFLITO_VERSAO nao sao incertos e chegam com mensagem da tela', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const tela = { intencoes: {} };
        h.estado.respostas.push({ sucesso: false, repeticao: false, codigoErro: 'TIPO_JA_EXISTE', mensagem: 'Tipo ja cadastrado.' },
            { sucesso: false, repeticao: false, codigoErro: 'CONFLITO_VERSAO', mensagem: 'Versao divergente.' });
        let s = await h.web.cadastroEmbalagens.executarComando.call(tela, 'incluirTipo', h.web.montarParametrosInclusao('CX', 'CAIXA'));
        assert.equal(s.ok, false); assert.equal(s.incerto, false); assert.equal(s.codigoErro, 'TIPO_JA_EXISTE'); assert.match(s.mensagem, /sigla/);
        s = await h.web.cadastroEmbalagens.executarComando.call(tela, 'alterarTipo', h.web.montarParametrosAlteracao({ codTipo: 'CX', descricao: 'A', ativo: true, versao: 1 }, 'B'));
        assert.equal(s.incerto, false); assert.match(s.mensagem, /outra pessoa/);
    });

    await caso('inativar usa INATIVAR com ativo false; reativar usa ALTERAR com ativo true', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const tela = { intencoes: {} };
        h.estado.respostas.push(fotografia({ codTipo: 'PL', descricao: 'PLASTICO', ativo: false, versao: 3 }),
            fotografia({ codTipo: 'PL', descricao: 'PLASTICO', ativo: true, versao: 4 }));
        let s = await h.web.cadastroEmbalagens.executarComando.call(tela, 'alterarTipo', h.web.montarParametrosSituacao({ codTipo: 'PL', descricao: 'PLASTICO', ativo: true, versao: 2 }));
        assert.equal(s.ok, true); assert.equal(h.chamadasApi[0].params.acao, 'INATIVAR'); assert.equal(h.chamadasApi[0].params.ativo, false);
        s = await h.web.cadastroEmbalagens.executarComando.call(tela, 'alterarTipo', h.web.montarParametrosSituacao({ codTipo: 'PL', descricao: 'PLASTICO', ativo: false, versao: 3 }));
        assert.equal(h.chamadasApi[1].params.acao, 'ALTERAR'); assert.equal(h.chamadasApi[1].params.ativo, true); assert.equal(h.chamadasApi[1].params.versao, 3);
        assert.equal(h.web.normalizarTipoEmbalagem(s.resultado).versao, 4);
    });

    await caso('grupo so com consulta nao grava tipo; widget nao envia usuario/grupo/endpoint', async () => {
        const h = montar({ regras: [{ grupo: 'grupo-tipos', acoes: ['consultarTipos'], estabelecimentos: [] }] });
        const tela = { intencoes: {} };
        const s = await h.web.cadastroEmbalagens.executarComando.call(tela, 'incluirTipo', h.web.montarParametrosInclusao('CX', 'CAIXA'));
        assert.equal(s.codigoErro, 'SEM_PERMISSAO'); assert.equal(s.incerto, false); assert.equal(h.chamadasApi.length, 0);
        const enviados = JSON.parse(h.transportes[0].filterFields[3]);
        assert.deepEqual(Object.keys(enviados).sort(), ['ativo', 'chaveIdempotente', 'codTipo', 'descricao', 'versao']);
    });

    await caso('interruptor direto: ativa/inativa, aplica resposta e bloqueia clique repetido', async () => {
        for (const ativo of [true, false]) {
            const h = montar({ regras: REGRA_TIPOS });
            const s = montarInterruptor(h, { codTipo: 'CX', descricao: 'CAIXA', ativo, versao: 3 });
            h.estado.respostas.push(fotografia({ codTipo: 'CX', descricao: 'CAIXA', ativo: !ativo, versao: 4 }));
            const gravacao = s.tela.alterarSituacao(s.linha, s.botao);
            assert.equal(s.estadoBotao.disabled, true);
            assert.equal(s.estadoBotao['aria-busy'], 'true');
            assert.equal(s.tipo.ativo, ativo);
            assert.equal(s.tela.alterarSituacao(s.linha, s.botao), undefined);
            await gravacao;
            assert.equal(h.chamadasApi.length, 1);
            assert.equal(h.chamadasApi[0].params.acao, ativo ? 'INATIVAR' : 'ALTERAR');
            assert.equal(h.chamadasApi[0].params.ativo, !ativo);
            assert.equal(s.tipo.ativo, !ativo); assert.equal(s.tipo.versao, 4);
            assert.equal(s.estadoBotao.disabled, false); assert.equal(s.tela.salvando, false);
            assert.equal(s.estadoBotao['aria-busy'], 'false'); assert.equal(s.avisos.length, 1);
            assert.equal(s.avisos[0].nivel, 'success');
            assert.equal(s.avisos[0].mensagem, 'CAIXA ' + (ativo ? 'desativado' : 'ativado') + ' com sucesso!');
        }
    });

    await caso('interruptor: recusa e falha de rede mantem estado e liberam novo clique', async () => {
        for (const rede of [false, true]) {
            const h = montar({ regras: REGRA_TIPOS });
            const s = montarInterruptor(h, { codTipo: 'CX', descricao: 'CAIXA', ativo: true, versao: 3 });
            if (rede) h.estado.falharRede = true;
            else h.estado.respostas.push({ sucesso: false, codigoErro: 'CONFLITO_VERSAO', mensagem: 'Versao divergente.' });
            await s.tela.alterarSituacao(s.linha, s.botao);
            assert.equal(s.tipo.ativo, true); assert.equal(s.tipo.versao, 3);
            assert.equal(s.estadoBotao.disabled, false); assert.equal(s.tela.salvando, false);
            assert.equal(s.avisos.length, 1); assert.equal(s.avisos[0].nivel, 'danger');
            assert.match(s.avisos[0].mensagem, rede ? /Buscar/ : /outra pessoa/);
        }
    });

    await caso('interruptor: bloqueio dura ate atualizar a tabela e libera se atualizacao falhar', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarInterruptor(h, { codTipo: 'CX', descricao: 'CAIXA', ativo: true, versao: 3 });
        let rejeitar, avisarAplicacao;
        const aplicando = new Promise(resolve => { avisarAplicacao = resolve; });
        s.tela.aplicarFotografia = () => {
            avisarAplicacao();
            return new Promise((resolve, reject) => { rejeitar = reject; });
        };
        h.estado.respostas.push(fotografia({ codTipo: 'CX', descricao: 'CAIXA', ativo: false, versao: 4 }));
        const gravacao = s.tela.alterarSituacao(s.linha, s.botao);
        await aplicando;
        assert.equal(s.tela.salvando, true); assert.equal(s.estadoBotao.disabled, true);
        assert.equal(s.tela.alterarSituacao(s.linha, s.botao), undefined);
        rejeitar(new Error('Falha ao atualizar tabela'));
        await gravacao;
        assert.equal(h.chamadasApi.length, 1);
        assert.equal(s.tela.salvando, false); assert.equal(s.estadoBotao.disabled, false);
        assert.match(s.avisos[0].mensagem, /Buscar/);
    });

    await caso('interruptor: versao ausente impede envio e avisa para consultar novamente', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarInterruptor(h, { codTipo: 'CX', descricao: 'CAIXA', ativo: true });
        await s.tela.alterarSituacao(s.linha, s.botao);
        assert.equal(h.transportes.length, 0); assert.equal(s.tipo.ativo, true);
        assert.equal(s.tela.salvando, false); assert.match(s.avisos[0].mensagem, /Buscar/);
    });

    await caso('paginacao: vazio percorre todos os cursores e remove siglas duplicadas', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarConsultaTabela(h);
        const tipo = codTipo => ({ codTipo, descricao: 'CAIXA ' + codTipo, ativo: true, versao: 1 });
        h.estado.respostas.push(pagina([tipo('CA'), tipo('CB')], true, 'CB'),
            pagina([tipo('CX'), tipo('CY')], true, 'CY'), pagina([tipo('CY'), tipo('CZ')]));
        await s.tela.carregarTipos();
        assert.equal(h.chamadasApi.length, 3);
        assert.equal(query(h.chamadasApi[1]).get('aposCodigo'), 'CB');
        assert.equal(query(h.chamadasApi[2]).get('aposCodigo'), 'CY');
        for (const c of h.chamadasApi) assert.equal(query(c).get('descricao'), null);
        assert.deepEqual(Array.from(s.dados.linhas, l => l.codTipo), ['CA', 'CB', 'CX', 'CY', 'CZ']);
        assert.equal(s.dados.gravacoes, 1); assert.equal(s.dados.pagina, 1);
        assert.equal(s.dados.alerta, null); assert.equal(s.tela.carregandoTipos, false);
    });

    await caso('paginacao: falha intermediaria impede exibir lista parcial como completa', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarConsultaTabela(h);
        h.estado.respostas.push(pagina([{ codTipo: 'CX', descricao: 'CAIXA', ativo: true, versao: 1 }], true, 'CX'),
            { sucesso: false, codigoErro: 'SEM_PERMISSAO', mensagem: 'Sem permissao.' });
        await s.tela.carregarTipos();
        assert.equal(h.chamadasApi.length, 2); assert.equal(s.dados.gravacoes, 0);
        assert.equal(s.dados.linhas.length, 0); assert.equal(s.tela.carregandoTipos, false);
        assert.equal(s.dados.alerta.tipo, 'error'); assert.match(s.dados.alerta.conteudo.textContent, /permissão/);
    });

    await caso('paginacao: cursor repetido interrompe consultas sem entrar em loop', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarConsultaTabela(h);
        const tipos = [{ codTipo: 'CX', descricao: 'CAIXA', ativo: true, versao: 1 }];
        h.estado.respostas.push(pagina(tipos, true, 'CX'), pagina(tipos, true, 'CX'));
        await s.tela.carregarTipos();
        assert.equal(h.chamadasApi.length, 2); assert.equal(s.dados.gravacoes, 0);
        assert.equal(s.tela.carregandoTipos, false); assert.equal(s.dados.alerta.tipo, 'error');
        assert.match(s.dados.alerta.conteudo.textContent, /cursor/);
    });

    await caso('paginacao: busca nova ignora resposta antiga e interrompe os cursores antigos', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarConsultaTabela(h, 'AN');
        h.estado.respostas.push(pagina([{ codTipo: 'AN', descricao: 'ANTIGO', ativo: true, versao: 1 }], true, 'AN'),
            pagina([{ codTipo: 'NV', descricao: 'NOVO', ativo: true, versao: 2 }]));
        const antiga = s.tela.carregarTipos();
        s.filtro.valor = 'NV — NOVO';
        s.tela.tipoSelecionado = { codigo: 'NV', rotulo: s.filtro.valor };
        const nova = s.tela.carregarTipos();
        await Promise.all([antiga, nova]);
        assert.equal(h.chamadasApi.length, 2); assert.equal(s.dados.gravacoes, 1);
        assert.deepEqual(Array.from(s.dados.linhas, l => l.codTipo), ['NV']);
        assert.equal(s.dados.alerta, null); assert.equal(s.tela.carregandoTipos, false);
    });

    await caso('paginacao: configuracao da tabela usa 10 registros, quatro setas e contador', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarConsultaTabela(h);
        let opcoes;
        h.web.Tabulator = function (el, config) { opcoes = config; return { on() {} }; };
        s.tela.montarTabela();
        assert.equal(opcoes.pagination, true); assert.equal(opcoes.paginationSize, 10);
        assert.equal(opcoes.footerElement, undefined);
        assert.equal(opcoes.paginationCounter(10, 11, 2, 23), 'Mostrando 11–20 de 23');
        assert.equal(opcoes.paginationCounter(10, 21, 3, 23), 'Mostrando 21–23 de 23');
        assert.equal(opcoes.paginationCounter(10, 1, 1, 0), '');
        const nav = opcoes.langs['pt-br'].pagination;
        assert.match(nav.first, /chevron-double-left/); assert.match(nav.prev, /chevron-left/);
        assert.match(nav.next, /chevron-right/); assert.match(nav.last, /chevron-double-right/);
    });

    await caso('paginacao: atualizar situacao preserva pagina atual mesmo com ordenacao', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        let paginaAtual = 2, reformatou = false, atualizado;
        const tela = Object.assign({}, h.web.cadastroEmbalagens, {
            tabela: {
                getPage: () => paginaAtual,
                getPageMax: () => 3,
                getSorters: () => [{ field: 'descricao', dir: 'asc' }],
                setSort() { paginaAtual = 1; },
                setPage(p) { paginaAtual = p; return Promise.resolve(); },
                updateOrAddData(linhas) { atualizado = linhas[0]; return Promise.resolve(); },
                getRow: () => ({ reformat() { reformatou = true; } })
            },
            destacarLinha() { throw new Error('Toggle não deve destacar a linha'); }
        });
        await tela.aplicarFotografia(fotografia({ codTipo: 'CX', descricao: 'CAIXA', ativo: false, versao: 4 }), false);
        assert.equal(paginaAtual, 2); assert.equal(reformatou, true);
        assert.equal(atualizado.ativo, false); assert.equal(atualizado.versao, 4);
    });

    await caso('toast: sucesso usa FLUIGC.toast e descricao com HTML aparece como texto', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const descricao = 'CAIXA <img src=x onerror=alert(1)> & PAPEL';
        const s = montarInterruptor(h, { codTipo: 'CX', descricao, ativo: false, versao: 3 });
        const toasts = [];
        h.web.FLUIGC = h.web.window.FLUIGC = { toast: opcoes => toasts.push(opcoes) };
        s.tela.avisar = h.web.cadastroEmbalagens.avisar;
        h.estado.respostas.push(fotografia({ codTipo: 'CX', descricao, ativo: true, versao: 4 }));
        await s.tela.alterarSituacao(s.linha, s.botao);
        assert.equal(toasts.length, 1); assert.equal(toasts[0].type, 'success');
        assert.equal(toasts[0].message, 'CAIXA &lt;img src=x onerror=alert(1)&gt; &amp; PAPEL ativado com sucesso!');
    });

    await caso('autocomplete: source usa apoio Fluig e a ultima selecao limita busca a uma sigla', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarConsultaTabela(h);
        s.tela.prepararAutocompleteTipo();
        h.estado.respostas.push(pagina([{ codigo: 'CX', descricao: 'CAIXA', ativo: true }, { codigo: 'PL', descricao: 'PLASTICO', ativo: false }]));
        const itens = await new Promise(resolve => s.dados.autocomplete.source('ca', resolve));
        assert.equal(s.dados.autocomplete.type, 'autocomplete'); assert.equal(s.dados.autocomplete.minLength, 2);
        assert.match(h.chamadasApi[0].endpoint, /\/apoios\/tipos\?/);
        assert.equal(h.transportes[0].filterFields[1], 'consultarTiposApoio');
        assert.equal(query(h.chamadasApi[0]).get('ativo'), 'todos');
        assert.equal(query(h.chamadasApi[0]).get('filtro'), 'ca');
        s.filtro.emitir('fluig.autocomplete.selected', itens[0]);
        s.filtro.emitir('fluig.autocomplete.selected', itens[1]);
        assert.equal(s.tela.tipoSelecionado.codigo, 'PL'); assert.equal(s.filtro.valor, 'PL — PLASTICO');
        assert.deepEqual(s.dados.badges, ['CX', 'PL']);
        h.estado.respostas.push(pagina([{ codTipo: 'PL', descricao: 'PLASTICO', ativo: false, versao: 2 }]));
        await s.tela.carregarTipos();
        assert.equal(h.chamadasApi.length, 2);
        const q = query(h.chamadasApi[1]);
        assert.equal(q.get('codigoDe'), 'PL'); assert.equal(q.get('codigoAte'), 'PL'); assert.equal(q.get('descricao'), null);
        assert.deepEqual(Array.from(s.dados.linhas, l => l.codTipo), ['PL']);
    });

    await caso('autocomplete: apagar selecao consulta tudo; texto editado exige nova selecao', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarConsultaTabela(h);
        s.tela.prepararAutocompleteTipo();
        s.filtro.emitir('fluig.autocomplete.selected', { codigo: 'CX', rotulo: 'CX — CAIXA' });
        s.filtro.valor = 'PL'; s.filtro.emitir('input');
        assert.equal(s.tela.tipoSelecionado, null);
        await s.tela.carregarTipos();
        assert.equal(h.transportes.length, 0); assert.equal(s.avisos[0].nivel, 'info');
        s.filtro.valor = ''; s.filtro.emitir('input');
        h.estado.respostas.push(pagina([{ codTipo: 'CA', descricao: 'CAIXA', ativo: true, versao: 1 }]));
        await s.tela.carregarTipos();
        assert.equal(h.chamadasApi.length, 1); assert.equal(query(h.chamadasApi[0]).get('codigoDe'), null);
        assert.equal(query(h.chamadasApi[0]).get('descricao'), null);
    });

    await caso('autocomplete: debounce consulta somente o ultimo texto e menos de dois caracteres nao chama API', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const s = montarConsultaTabela(h);
        s.tela.prepararAutocompleteTipo();
        let descartadas = 0;
        const curtas = await new Promise(resolve => s.dados.autocomplete.source('c', resolve));
        assert.equal(curtas.length, 0); assert.equal(h.transportes.length, 0);
        h.estado.respostas.push(pagina([{ codigo: 'CX', descricao: 'CAIXA', ativo: true }]));
        s.dados.autocomplete.source('ca', () => descartadas++);
        const itens = await new Promise(resolve => s.dados.autocomplete.source('cx', resolve));
        assert.equal(h.chamadasApi.length, 1); assert.equal(query(h.chamadasApi[0]).get('filtro'), 'cx');
        assert.equal(itens[0].rotulo, 'CX — CAIXA'); assert.equal(descartadas, 0);
    });

    console.log('TELA_TIPOS|CENARIOS=' + casos + '|FALHAS=0|FLUIG_REAL=nao');
}
main().catch(e => { console.error(e); process.exitCode = 1; });
