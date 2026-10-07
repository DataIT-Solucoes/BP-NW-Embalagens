// jQuery mínimo para os testes em Node (sem DOM). Implementa só o que chamar-embalagens.js e as
// funções testadas do widget usam, com a mesma assinatura do jQuery 3.6.3:
// $.ajax(...).then(ok(data, textStatus, jqXHR), falha(jqXHR, textStatus, errorThrown)) e .abort().
// A fidelidade com o jQuery real é conferida no navegador, não aqui.
// servidor(opcoes) devolve { status, corpo } (corpo em texto) ou lança erro de rede.
function criarJQueryFalso(servidor) {
    const $ = function () { throw new Error('$(seletor) não disponível nos testes em Node.'); };
    $.chamadasAjax = [];
    $.ajax = function (opcoes) {
        $.chamadasAjax.push(opcoes);
        let abortado = false;
        const resposta = Promise.resolve().then(() => servidor(opcoes));
        const xhr = {
            status: 0,
            abort() { abortado = true; },
            then(ok, falha) {
                return resposta.then(r => {
                    if (abortado) throw { textStatus: 'abort' };
                    xhr.status = r.status;
                    if (r.status < 200 || r.status >= 300) throw { textStatus: 'error' };
                    if (opcoes.dataType !== 'json') return r.corpo;
                    try { return JSON.parse(r.corpo); } catch (e) { throw { textStatus: 'parsererror' }; }
                }, () => { throw { textStatus: abortado ? 'abort' : 'error' }; })
                    .then(dados => ok(dados, 'success', xhr),
                        e => falha ? falha(xhr, e.textStatus, '') : Promise.reject(e));
            }
        };
        return xhr;
    };
    $.Deferred = function () {
        let resolver, rejeitar;
        const p = new Promise((a, b) => { resolver = a; rejeitar = b; });
        return { resolve(v) { resolver(v); return this; }, reject(e) { rejeitar(e); return this; }, promise() { return p; } };
    };
    // $.when(p1, p2): ok recebe um argumento por promise
    $.when = function (...ps) {
        return { then: (ok, falha) => Promise.all(ps).then(v => ok(...v), falha) };
    };
    $.extend = (...a) => Object.assign(...a);
    $.isPlainObject = v => Object.prototype.toString.call(v) === '[object Object]';
    $.map = (lista, fn) => Array.prototype.reduce.call(lista, (acc, v, i) => {
        const r = fn(v, i);
        return r == null ? acc : acc.concat(r);
    }, []);
    $.grep = (lista, fn) => Array.prototype.filter.call(lista, (v, i) => fn(v, i));
    $.each = (lista, fn) => { Array.prototype.forEach.call(lista, (v, i) => fn(i, v)); return lista; };
    $.inArray = (v, lista) => Array.prototype.indexOf.call(lista, v);
    return $;
}
module.exports = { criarJQueryFalso };
