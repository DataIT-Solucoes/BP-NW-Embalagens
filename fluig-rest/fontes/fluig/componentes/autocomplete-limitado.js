/* DT-064. Transporte injetado: o componente nao define usuario/permissoes. */
(function (root) {
    'use strict';
    function criarBuscaLimitada(opcoes) {
        if (!opcoes || typeof opcoes.buscar !== 'function') throw new Error('Transporte obrigatorio.');
        var timer, controller, versao = 0, destruido = false;
        var informar = opcoes.informar || function () {};
        var atraso = opcoes.atraso === undefined ? 350 : opcoes.atraso;
        function cancelar() {
            versao += 1;
            clearTimeout(timer);
            if (controller) controller.abort();
            controller = null;
        }
        function consultar(texto, contexto, cursor) {
            cancelar();
            if (destruido) return;
            var termo = String(texto || '').trim(), atual = versao;
            if (termo.length < 2 || (opcoes.habilitado && !opcoes.habilitado(contexto))) {
                informar({estado: 'aguardando', dados: [], temMais: false});
                return;
            }
            if (termo.length > 100) {
                informar({estado: 'erro', dados: [], mensagem: 'Use ate 100 caracteres.'});
                return;
            }
            informar({estado: 'carregando', dados: []});
            timer = setTimeout(function () {
                if (destruido || atual !== versao) return;
                var cancelador = new AbortController();
                controller = cancelador;
                Promise.resolve().then(function () {
                    return opcoes.buscar({filtro: termo, limite: 20, aposCodigo: cursor || '',
                        contexto: contexto, signal: cancelador.signal});
                }).then(function (resposta) {
                    if (destruido || atual !== versao) return;
                    if (!resposta || resposta.sucesso !== true || !Array.isArray(resposta.dados)) {
                        throw new Error('Nao foi possivel consultar as opcoes.');
                    }
                    // Excesso indica quebra de contrato; nao mascara download de cadastro.
                    if (resposta.dados.length > 20) throw new Error('Consulta excedeu o limite de 20 opcoes.');
                    informar({estado: resposta.dados.length ? 'pronto' : 'vazio', dados: resposta.dados,
                        temMais: resposta.temMais === true, proximoCodigo: resposta.proximoCodigo || ''});
                }).catch(function (erro) {
                    if (destruido || atual !== versao || (erro && erro.name === 'AbortError')) return;
                    informar({estado: 'erro', dados: [], mensagem: 'Nao foi possivel consultar as opcoes. Tente novamente.'});
                });
            }, atraso);
        }
        return {consultar: consultar, cancelar: cancelar, destruir: function () {destruido = true; cancelar();}};
    }
    if (typeof module !== 'undefined' && module.exports) module.exports = criarBuscaLimitada;
    else root.criarBuscaLimitada = criarBuscaLimitada;
}(typeof window !== 'undefined' ? window : this));
