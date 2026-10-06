/**
 * Baseline REST Fluig-Datasul v1.0
 * Dataset proxy para consulta de Centros de Distribuicao.
 *
 * Constraints:
 *   filtro - codigo ou nome do estabelecimento (opcional)
 *   limit  - quantidade maxima (padrao 20; maximo 100)
 */

var CODIGO_SERVICO = "DATASUL_REST_BP";
var ENDPOINT_API =
    "/dts/datasul-rest/resources/prg/esp/v1/cd-ressuprimento/";

var COLUNAS = [
    "sucesso",
    "httpStatus",
    "codEstabel",
    "nomeEstabel",
    "mensagem"
];

function defineStructure() {
    for (var i = 0; i < COLUNAS.length; i++) {
        addColumn(COLUNAS[i]);
    }
}

function onSync(lastSyncDate) {
    return null;
}

function onMobileSync(user) {
    return null;
}

function createDataset(fields, constraints, sortFields) {
    var dataset = DatasetBuilder.newDataset();

    for (var i = 0; i < COLUNAS.length; i++) {
        dataset.addColumn(COLUNAS[i]);
    }

    var filtro = obterConstraint(constraints, "filtro");
    var limite = parseInt(obterConstraint(constraints, "limit"), 10);

    if (filtro == null) {
        filtro = "";
    }

    if (isNaN(limite) || limite < 1) {
        limite = 20;
    }

    if (limite > 100) {
        limite = 100;
    }

    var endpoint = ENDPOINT_API +
        "?filtro=" + encodeURIComponent(filtro) +
        "&limit=" + limite +
        "&_ts=" + new Date().getTime();

    try {
        var requisicao = {
            companyId: obterCompanyId(),
            serviceCode: CODIGO_SERVICO,
            endpoint: endpoint,
            method: "get",
            timeoutService: "60",
            headers: {
                "Accept": "application/json"
            }
        };

        log.info("[dsControleEmbalagensAPI] GET " + endpoint);

        var clientService = fluigAPI.getAuthorizeClientService();
        var resposta = clientService.invoke(JSON.stringify(requisicao));
        var httpStatus = obterHttpStatus(resposta);
        var conteudo = resposta.getResult();

        if (!statusOk(httpStatus)) {
            adicionarErro(dataset, httpStatus,
                "A API respondeu HTTP " + valorTexto(httpStatus) + ".");
            return dataset;
        }

        if (conteudo == null || limpar(conteudo) == "") {
            adicionarErro(dataset, httpStatus, "A API retornou corpo vazio.");
            return dataset;
        }

        var retorno;

        try {
            retorno = JSON.parse(String(conteudo));
        } catch (erroJson) {
            adicionarErro(dataset, httpStatus,
                "A API nao retornou um JSON valido.");
            return dataset;
        }

        if (retorno.sucesso !== true) {
            adicionarErro(dataset, httpStatus,
                mensagemSegura(retorno));
            return dataset;
        }

        var dados = retorno.dados || [];

        if (!(dados instanceof Array)) {
            adicionarErro(dataset, httpStatus,
                "A propriedade dados nao e uma lista.");
            return dataset;
        }

        for (var linha = 0; linha < dados.length; linha++) {
            dataset.addRow([
                "true",
                valorTexto(httpStatus),
                valorTexto(dados[linha].codEstabel),
                valorTexto(dados[linha].nomeEstabel),
                ""
            ]);
        }

    } catch (erro) {
        log.error("[dsControleEmbalagensAPI] Falha ao chamar a API.");
        adicionarErro(dataset, "", mensagemExcecaoSegura(erro));
    }

    return dataset;
}

function adicionarErro(dataset, httpStatus, mensagem) {
    dataset.addRow([
        "false",
        valorTexto(httpStatus),
        "",
        "",
        valorTexto(mensagem)
    ]);
}

function obterConstraint(constraints, nomeCampo) {
    if (constraints == null) {
        return null;
    }

    for (var i = 0; i < constraints.length; i++) {
        if (String(constraints[i].getFieldName()) == nomeCampo) {
            var valor = limpar(constraints[i].getInitialValue());
            return valor == "" ? null : valor;
        }
    }

    return null;
}

function obterCompanyId() {
    try {
        var companyId = limpar(getValue("WKCompany"));
        return companyId == "" ? "1" : companyId;
    } catch (erro) {
        return "1";
    }
}

function obterHttpStatus(resposta) {
    try {
        return valorTexto(resposta.getHttpStatusResult());
    } catch (erro) {
        return "";
    }
}

function statusOk(httpStatus) {
    if (limpar(httpStatus) == "") {
        return true;
    }

    var numero = parseInt(httpStatus, 10);
    return !isNaN(numero) && numero >= 200 && numero < 300;
}

function mensagemSegura(retorno) {
    var mensagem = retorno.mensagem || retorno.erro || retorno.message;
    return limpar(mensagem) == ""
        ? "A API retornou sucesso diferente de true."
        : recortar(mensagem, 300);
}

function mensagemExcecaoSegura(erro) {
    var texto = valorTexto(erro && erro.message ? erro.message : erro);

    if (texto.indexOf("cookie") >= 0 ||
        texto.indexOf("acTk") >= 0 ||
        texto.indexOf("rfTk") >= 0 ||
        texto.indexOf("Authorization") >= 0) {
        return "Falha na chamada autorizada. Consulte o log do servidor.";
    }

    return recortar(texto, 300);
}

function recortar(valor, tamanho) {
    var texto = limpar(valor);
    return texto.length > tamanho ? texto.substring(0, tamanho) + "..." : texto;
}

function limpar(valor) {
    return valorTexto(valor).replace(/^\s+|\s+$/g, "");
}

function valorTexto(valor) {
    return valor == null ? "" : String(valor);
}
