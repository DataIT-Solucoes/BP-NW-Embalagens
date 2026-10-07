// Cadeia local da tela de tipos, sem Fluig/Datasul reais:
// funcoes do widget -> chamarEmbalagens -> POST /api/public/ecm/dataset/search (simulado)
// -> dsNwEmbalagens.createDataset -> invoke do servico autorizado (simulado).
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm'), assert = require('node:assert/strict');
const { webcrypto } = require('node:crypto');
const root = path.resolve(__dirname, '..');
const ler = f => fs.readFileSync(path.join(root, f), 'utf8');
const fonteDataset = ler('datasets/dsNwEmbalagens.js');
const fonteHelper = ler('src/main/webapp/resources/js/chamar-embalagens.js');
const fonteWidget = ler('src/main/webapp/resources/js/widget_nw_embalagens.js');

function montar(opcoes = {}) {
    const chamadasApi = [], transportes = [];
    const estado = { respostas: [], falharInvoke: false, regras: opcoes.regras };
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
    if (estado.regras) ds.NW_CONFIG.regras = estado.regras;

    // Transporte do Fluig: filterFields [campo, valor, ...] viram constraints do Dataset.
    const web = {
        JSON, Object, Array, Math, Number, String, Error, Promise, Uint8Array,
        window: { crypto: webcrypto },
        SuperWidget: { extend: o => o },
        $: { extend: (...a) => Object.assign(...a), trim: v => String(v == null ? '' : v).trim() },
        fetch: async (url, req) => {
            assert.equal(url, '/api/public/ecm/dataset/search');
            const corpo = JSON.parse(req.body);
            transportes.push(corpo);
            assert.equal(corpo.datasetId, 'dsNwEmbalagens');
            assert.equal(corpo.limit, '1');
            const constraints = [];
            for (let i = 0; i < corpo.filterFields.length; i += 2) {
                const nome = corpo.filterFields[i], valor = corpo.filterFields[i + 1];
                constraints.push({ getFieldName: () => nome, getInitialValue: () => valor, getFinalValue: () => valor });
            }
            const saida = ds.createDataset(null, constraints, null);
            const content = saida.values.map(linha => Object.fromEntries(saida.columns.map((c, i) => [c, linha[i]])));
            return { ok: true, status: 200, json: async () => ({ content }) };
        }
    };
    vm.createContext(web); vm.runInContext(fonteHelper, web); vm.runInContext(fonteWidget, web);
    return { ds, web, estado, chamadasApi, transportes };
}

const REGRA_TIPOS = [{ grupo: 'grupo-tipos', acoes: ['consultarTipos', 'incluirTipo', 'alterarTipo'], estabelecimentos: [] }];
const pagina = (dados, temMais = false, proximoCodigo = '') => ({ sucesso: true, codigoErro: '', mensagem: '', total: dados.length, temMais, proximoCodigo, dados });
const fotografia = (t, extra = {}) => Object.assign({ sucesso: true, repeticao: false, codigoErro: '', mensagem: '', idEvento: '41' }, t, extra);
const query = chamada => new URL('http://x' + chamada.endpoint).searchParams;

async function main() {
    let casos = 0;
    const caso = async (nome, fn) => { await fn(); casos++; console.log('OK ' + nome); };

    await caso('consulta: texto curto busca descricao paginada e codigo exato, sem baixar tudo', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        h.estado.respostas.push(
            pagina([{ codTipo: 'CA', descricao: 'CAIXA', ativo: true, versao: 2 }, { codTipo: 'CX', descricao: 'CX PAPELAO', ativo: false, versao: 5 }], true, 'CX'),
            pagina([{ codTipo: 'CX', descricao: 'CX PAPELAO', ativo: false, versao: 5 }]));
        const consultas = h.web.nweConsultasTipos('cx', '');
        const resultados = await Promise.all(consultas.map(p => h.web.chamarEmbalagens('consultarTipos', p)));
        assert.equal(h.chamadasApi.length, 2);
        const q1 = query(h.chamadasApi[0]), q2 = query(h.chamadasApi[1]);
        assert.equal(q1.get('descricao'), 'cx'); assert.equal(q1.get('limite'), '20'); assert.equal(q1.get('usuario'), 'usuario-sessao');
        assert.equal(q2.get('codigoDe'), 'cx'); assert.equal(q2.get('codigoAte'), 'cx'); assert.equal(q2.get('limite'), '1');
        assert.equal(h.chamadasApi[0].method, 'get'); assert.equal(h.chamadasApi[0].serviceCode, 'DATASUL_REST_HOMOLOG');
        const linhas = h.web.nweMesclarTipos(resultados[0].dados, resultados[1].dados);
        assert.deepEqual(linhas.map(l => l.codTipo), ['CX', 'CA']);
        assert.equal(linhas[0].ativo, false); assert.equal(linhas[0].versao, 5);
        assert.equal(resultados[0].temMais, true); assert.equal(resultados[0].proximoCodigo, 'CX');
    });

    await caso('consulta: "Carregar mais" usa o cursor aposCodigo com o mesmo filtro, uma chamada', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        h.estado.respostas.push(pagina([{ codTipo: 'Z9R', descricao: 'CAIXA TESTE', ativo: true, versao: 4 }]));
        const consultas = h.web.nweConsultasTipos('caixa', 'CX');
        assert.equal(consultas.length, 1);
        const r = await h.web.chamarEmbalagens('consultarTipos', consultas[0]);
        assert.equal(r.sucesso, true); assert.equal(r.temMais, false);
        const q = query(h.chamadasApi[0]);
        assert.equal(q.get('aposCodigo'), 'CX'); assert.equal(q.get('descricao'), 'caixa'); assert.equal(q.get('codigoDe'), null);
    });

    await caso('consulta: sem grupos configurados volta recusa (nao lista vazia) e nao chama a API', async () => {
        const h = montar();
        const r = await h.web.chamarEmbalagens('consultarTipos', h.web.nweConsultasTipos('', '')[0]);
        assert.equal(r.sucesso, false); assert.equal(r.codigoErro, 'AUTORIZACAO_NAO_CONFIGURADA'); assert.ok(!('dados' in r));
        assert.equal(h.chamadasApi.length, 0);
        assert.match(h.web.nweMensagem(r, ''), /grupos e permissões/);
    });

    await caso('inclusao: POST com versao 0 numerica, ativo booleano, usuario da sessao e chave UUID', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        h.estado.respostas.push(fotografia({ codTipo: 'CX', descricao: 'CAIXA', ativo: true, versao: 1 }));
        const tela = { intencoes: {} };
        const saida = await h.web.widget_nw_embalagens.executarComando.call(tela, 'incluirTipo', h.web.nweParametrosInclusao('CX', 'CAIXA'));
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
        let s = await h.web.widget_nw_embalagens.executarComando.call(tela, 'alterarTipo', h.web.nweParametrosAlteracao(tipo, 'CAIXA NOVA'));
        assert.equal(s.ok, false); assert.equal(s.incerto, true); assert.equal(h.chamadasApi.length, 1);
        assert.match(s.mensagem, /mesma chave/);
        const chave1 = h.chamadasApi[0].params.chaveIdempotente;
        h.estado.falharInvoke = false;
        h.estado.respostas.push(fotografia({ codTipo: 'CX', descricao: 'CAIXA NOVA', ativo: true, versao: 4 }, { repeticao: true }));
        s = await h.web.widget_nw_embalagens.executarComando.call(tela, 'alterarTipo', h.web.nweParametrosAlteracao(tipo, 'CAIXA NOVA'));
        assert.equal(h.chamadasApi.length, 2); assert.equal(h.chamadasApi[1].params.chaveIdempotente, chave1);
        assert.equal(s.ok, true); assert.equal(s.resultado.repeticao, true);
        h.estado.respostas.push(fotografia({ codTipo: 'CX', descricao: 'CAIXA OUTRA', ativo: true, versao: 5 }));
        await h.web.widget_nw_embalagens.executarComando.call(tela, 'alterarTipo', h.web.nweParametrosAlteracao(tipo, 'CAIXA OUTRA'));
        assert.notEqual(h.chamadasApi[2].params.chaveIdempotente, chave1);
        assert.equal(h.chamadasApi[2].method, 'patch'); assert.equal(h.chamadasApi[2].params.acao, 'ALTERAR'); assert.equal(h.chamadasApi[2].params.versao, 3);
    });

    await caso('transporte falho: helper rejeita, comando fica incerto e nao repete sozinho', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        h.web.fetch = async () => { throw new TypeError('Failed to fetch'); };
        const tela = { intencoes: {} };
        const s = await h.web.widget_nw_embalagens.executarComando.call(tela, 'incluirTipo', h.web.nweParametrosInclusao('CX', 'CAIXA'));
        assert.equal(s.ok, false); assert.equal(s.incerto, true); assert.equal(h.chamadasApi.length, 0);
        assert.equal(Object.keys(tela.intencoes).length, 1);
    });

    await caso('recusa de negocio: TIPO_JA_EXISTE e CONFLITO_VERSAO nao sao incertos e chegam com mensagem da tela', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const tela = { intencoes: {} };
        h.estado.respostas.push({ sucesso: false, repeticao: false, codigoErro: 'TIPO_JA_EXISTE', mensagem: 'Tipo ja cadastrado.' },
            { sucesso: false, repeticao: false, codigoErro: 'CONFLITO_VERSAO', mensagem: 'Versao divergente.' });
        let s = await h.web.widget_nw_embalagens.executarComando.call(tela, 'incluirTipo', h.web.nweParametrosInclusao('CX', 'CAIXA'));
        assert.equal(s.ok, false); assert.equal(s.incerto, false); assert.equal(s.codigoErro, 'TIPO_JA_EXISTE'); assert.match(s.mensagem, /sigla/);
        s = await h.web.widget_nw_embalagens.executarComando.call(tela, 'alterarTipo', h.web.nweParametrosAlteracao({ codTipo: 'CX', descricao: 'A', ativo: true, versao: 1 }, 'B'));
        assert.equal(s.incerto, false); assert.match(s.mensagem, /outra pessoa/);
    });

    await caso('inativar usa INATIVAR com ativo false; reativar usa ALTERAR com ativo true', async () => {
        const h = montar({ regras: REGRA_TIPOS });
        const tela = { intencoes: {} };
        h.estado.respostas.push(fotografia({ codTipo: 'PL', descricao: 'PLASTICO', ativo: false, versao: 3 }),
            fotografia({ codTipo: 'PL', descricao: 'PLASTICO', ativo: true, versao: 4 }));
        let s = await h.web.widget_nw_embalagens.executarComando.call(tela, 'alterarTipo', h.web.nweParametrosSituacao({ codTipo: 'PL', descricao: 'PLASTICO', ativo: true, versao: 2 }));
        assert.equal(s.ok, true); assert.equal(h.chamadasApi[0].params.acao, 'INATIVAR'); assert.equal(h.chamadasApi[0].params.ativo, false);
        s = await h.web.widget_nw_embalagens.executarComando.call(tela, 'alterarTipo', h.web.nweParametrosSituacao({ codTipo: 'PL', descricao: 'PLASTICO', ativo: false, versao: 3 }));
        assert.equal(h.chamadasApi[1].params.acao, 'ALTERAR'); assert.equal(h.chamadasApi[1].params.ativo, true); assert.equal(h.chamadasApi[1].params.versao, 3);
        assert.equal(h.web.nweLinhaTipo(s.resultado).versao, 4);
    });

    await caso('grupo so com consulta nao grava tipo; widget nao envia usuario/grupo/endpoint', async () => {
        const h = montar({ regras: [{ grupo: 'grupo-tipos', acoes: ['consultarTipos'], estabelecimentos: [] }] });
        const tela = { intencoes: {} };
        const s = await h.web.widget_nw_embalagens.executarComando.call(tela, 'incluirTipo', h.web.nweParametrosInclusao('CX', 'CAIXA'));
        assert.equal(s.codigoErro, 'SEM_PERMISSAO'); assert.equal(s.incerto, false); assert.equal(h.chamadasApi.length, 0);
        const enviados = JSON.parse(h.transportes[0].filterFields[3]);
        assert.deepEqual(Object.keys(enviados).sort(), ['ativo', 'chaveIdempotente', 'codTipo', 'descricao', 'versao']);
    });

    console.log('TELA_TIPOS|CENARIOS=' + casos + '|FALHAS=0|FLUIG_REAL=nao');
}
main().catch(e => { console.error(e); process.exitCode = 1; });
