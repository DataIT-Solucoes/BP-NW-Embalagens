/* ET-01A: apoio ao preenchimento. A validacao definitiva pertence ao ABL.
   Sem acesso a rede, persistencia ou configuracao de ambiente. */
(function (root, factory) {
    "use strict";
    var api = factory();
    if (typeof module === "object" && module.exports) module.exports = api;
    else root.ControleEmbalagensTipo = api;
}(typeof globalThis !== "undefined" ? globalThis : this, function () {
    "use strict";
    function erro(codigo, mensagem) {
        return { sucesso: false, codigoErro: codigo, mensagem: mensagem, dados: null };
    }
    function retirarEspacos(texto) { return texto.replace(/^ +| +$/g, ""); }
    function validarTipo(entrada) {
        entrada = entrada || {};
        var codigo = typeof entrada.codTipo === "string" ? retirarEspacos(entrada.codTipo) : "";
        // Conferir ASCII antes da conversao: nao aceitar equivalencias Unicode.
        if (codigo.length < 2 || codigo.length > 3 || /[^A-Za-z0-9]/.test(codigo)) {
            return erro("CODIGO_INVALIDO", "Informe um codigo com 2 ou 3 letras ASCII ou numeros.");
        }
        codigo = codigo.toUpperCase();
        var descricao = typeof entrada.descEmbalagem === "string" ? retirarEspacos(entrada.descEmbalagem) : "";
        var caracteres = descricao.match(/[\uD800-\uDBFF][\uDC00-\uDFFF]|[\s\S]/g) || [];
        if (descricao.replace(/[ \t\r\n]/g, "") === "" || caracteres.length > 100) {
            return erro("DESCRICAO_INVALIDA", "Informe uma descricao com 1 a 100 caracteres.");
        }
        if (typeof entrada.ativo !== "boolean") {
            return erro("SITUACAO_INVALIDA", "Informe a situacao ativa ou inativa.");
        }
        return {
            sucesso: true, codigoErro: "", mensagem: "",
            dados: { codTipo: codigo, descEmbalagem: descricao, ativo: entrada.ativo }
        };
    }
    return { validarTipo: validarTipo };
}));
