// Transporte no widget_nw_embalagens.js (versão jQuery/$.ajax), com jQuery simulado e sem Fluig real.
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm'), assert = require('node:assert/strict');
const { criarJQueryFalso } = require('./jquery-falso.cjs');
const source = fs.readFileSync(path.join(__dirname, '../src/main/webapp/resources/js/widget_nw_embalagens.js'), 'utf8');

async function main() {
    let casos = 0;
    const envelope = r => ({ content: [{ acao: 'consultarTipos', sucesso: String(r.sucesso), resultadoJson: JSON.stringify(r) }] });
    function harness(result, options = {}) {
        const $ = criarJQueryFalso(() => {
            if (options.redeFalha) throw new Error('rede');
            return { status: options.httpError ? 503 : 200, corpo: options.corpo !== undefined ? options.corpo : JSON.stringify(options.transport || envelope(result)) };
        });
        const sandbox = { $, JSON, Object, Array, String, Error, SuperWidget: { extend: definicao => definicao } };
        vm.createContext(sandbox); vm.runInContext(source, sandbox);
        return { sandbox, $ };
    }

    let h = harness({ sucesso: true, dados: [], total: 0, temMais: false, proximoCodigo: '' });
    let r = await h.sandbox.chamarEmbalagens('consultarTipos', {});
    assert.equal(r.sucesso, true);
    const req = h.$.chamadasAjax[0];
    assert.equal(req.url, '/api/public/ecm/dataset/search'); assert.equal(req.type, 'POST');
    assert.equal(req.dataType, 'json'); assert.equal(req.contentType, 'application/json');
    const body = JSON.parse(req.data);
    assert.equal(body.datasetId, 'dsNwEmbalagens'); assert.equal(body.limit, '1');
    assert.deepEqual(body.filterFields, ['acao', 'consultarTipos', 'parametros', '{}']); casos++;

    h = harness({ sucesso: false, codigoErro: 'SEM_PERMISSAO', mensagem: 'Recusado' });
    r = await h.sandbox.chamarEmbalagens('consultarTipos', {}); assert.equal(r.codigoErro, 'SEM_PERMISSAO'); casos++;

    h = harness({ sucesso: true }, { httpError: true });
    await assert.rejects(h.sandbox.chamarEmbalagens('consultarTipos', {}), /503/); assert.equal(h.$.chamadasAjax.length, 1); casos++;

    for (const transport of [{ content: [] }, { content: [{}, {}] }, { content: [{ acao: 'consultarTipos', sucesso: 'true', resultadoJson: '{' }] }, { content: [{ acao: 'outra', sucesso: 'true', resultadoJson: '{"sucesso":true}' }] }]) {
        h = harness({ sucesso: true }, { transport });
        await assert.rejects(h.sandbox.chamarEmbalagens('consultarTipos', {})); casos++;
    }

    h = harness({ sucesso: true }, { corpo: '<html>login</html>' });
    await assert.rejects(h.sandbox.chamarEmbalagens('consultarTipos', {}), /JSON valido/); casos++;

    h = harness({ sucesso: true }, { redeFalha: true });
    await assert.rejects(h.sandbox.chamarEmbalagens('consultarTipos', {}), /Falha HTTP 0/); casos++;

    h = harness({ sucesso: true, dados: [], total: 0, temMais: false, proximoCodigo: '' });
    const p = h.sandbox.chamarEmbalagens('consultarTipos', {}); p.abort();
    await assert.rejects(p, /cancelada/); casos++;

    h = harness({ sucesso: true });
    await assert.rejects(h.sandbox.chamarEmbalagens('consultarTipos', 'texto'), /acao e parametros/);
    assert.equal(h.$.chamadasAjax.length, 0); casos++;

    console.log('WIDGET_DATASET_UNICO|CENARIOS=' + casos + '|FALHAS=0|FLUIG_REAL=nao');
}
main().catch(e => { console.error(e); process.exitCode = 1; });
