/**
 * dsNwEmbalagensTipos
 * Consulta TODOS os tipos de embalagem: GET /controle-embalagens/tipos.
 * A API devolve no maximo 100 por chamada; o Dataset repete a chamada com
 * aposCodigo = proximoCodigo ate temMais = false.
 *
 * Constraints aceitas (todas opcionais):
 *   descricao  - texto contido na descricao
 *   codigoDe   - codigo inicial (ate 3 caracteres)
 *   codigoAte  - codigo final (ate 3 caracteres)
 *   ativo      - "true" ou "false"; sem ela traz ativos e inativos
 *
 * O usuario vem do WKUser da sessao, nunca do Widget.
 * Retorno: uma linha por tipo com sucesso = "true".
 * Em erro: uma unica linha com sucesso = "false", codigoErro e mensagem.
 */

var CODIGO_SERVICO = "DATASUL_REST_HOMOLOG";
var ENDPOINT_API = "/dts/datasul-rest/resources/prg/esp/v1/controle-embalagens/tipos";
var LIMITE_POR_PAGINA = 100;   // maximo aceito pela API
var MAX_PAGINAS = 50;          // trava contra laco infinito

var FILTROS_ACEITOS = ["descricao", "codigoDe", "codigoAte", "ativo"];

var COLUNAS = [
    "sucesso",
    "codigoErro",
    "mensagem",
    "codTipo",
    "descricao",
    "ativo",
    "versao",
    "dtInclusao",
    "usuarioInclusao",
    "dtAlteracao",
    "usuarioAlteracao"
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

    var usuario = obterUsuario();
    if (usuario == "") {
        adicionarErro(dataset, "USUARIO_NAO_INFORMADO",
            "Nao foi possivel identificar o usuario da sessao Fluig.");
        return dataset;
    }

    var filtros = montarFiltros(constraints);
    if (filtros == null) {
        adicionarErro(dataset, "FILTRO_INVALIDO", "Confira os filtros informados.");
        return dataset;
    }

    var tipos = [];
    var aposCodigo = "";
    var paginas = 0;

    try {
        var clientService = fluigAPI.getAuthorizeClientService();

        do {
            var endpoint = ENDPOINT_API +
                "?usuario=" + encodeURIComponent(usuario) +
                "&limite=" + LIMITE_POR_PAGINA +
                filtros +
                (aposCodigo != "" ? "&aposCodigo=" + encodeURIComponent(aposCodigo) : "");

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

            var resposta = clientService.invoke(JSON.stringify(requisicao));
            var httpStatus = obterHttpStatus(resposta);
            var conteudo = resposta.getResult();

            if (!statusOk(httpStatus)) {
                adicionarErro(dataset, "HTTP_" + httpStatus,
                    "A API respondeu HTTP " + httpStatus + ".");
                return dataset;
            }

            if (conteudo == null || limpar(conteudo) == "") {
                adicionarErro(dataset, "RESPOSTA_VAZIA", "A API retornou corpo vazio.");
                return dataset;
            }

            var retorno;
            try {
                retorno = JSON.parse(String(conteudo));
            } catch (erroJson) {
                adicionarErro(dataset, "RESPOSTA_INVALIDA", "A API nao retornou um JSON valido.");
                return dataset;
            }

            // HTTP 200 pode trazer recusa de negocio: conferir sucesso/codigoErro
            if (retorno.sucesso !== true) {
                adicionarErro(dataset, limpar(retorno.codigoErro) || "SEM_SUCESSO",
                    mensagemSegura(retorno));
                return dataset;
            }

            var dados = retorno.dados || [];
            if (!(dados instanceof Array)) {
                adicionarErro(dataset, "RESPOSTA_INVALIDA", "A propriedade dados nao e uma lista.");
                return dataset;
            }

            tipos = tipos.concat(dados);
            aposCodigo = retorno.temMais === true ? limpar(retorno.proximoCodigo) : "";
            paginas++;
        } while (aposCodigo != "" && paginas < MAX_PAGINAS);

        if (aposCodigo != "") {
            log.warn("[dsNwEmbalagensTipos] Parou em " + MAX_PAGINAS + " paginas; ainda havia tipos apos " + aposCodigo + ".");
        }

    } catch (erro) {
        log.error("[dsNwEmbalagensTipos] Falha ao chamar a API: " + mensagemExcecaoSegura(erro));
        adicionarErro(dataset, "FALHA_CHAMADA", mensagemExcecaoSegura(erro));
        return dataset;
    }

    for (var t = 0; t < tipos.length; t++) {
        dataset.addRow([
            "true",
            "",
            "",
            valorTexto(tipos[t].codTipo),
            valorTexto(tipos[t].descricao),
            valorTexto(tipos[t].ativo),
            valorTexto(tipos[t].versao),
            valorTexto(tipos[t].dtInclusao),
            valorTexto(tipos[t].usuarioInclusao),
            valorTexto(tipos[t].dtAlteracao),
            valorTexto(tipos[t].usuarioAlteracao)
        ]);
    }

    return dataset;
}

// Monta a parte da query com os filtros aceitos. Retorna null se algum for invalido.
function montarFiltros(constraints) {
    var query = "";

    for (var i = 0; i < FILTROS_ACEITOS.length; i++) {
        var nome = FILTROS_ACEITOS[i];
        var valor = obterConstraint(constraints, nome);
        if (valor == null) continue;

        if ((nome == "codigoDe" || nome == "codigoAte") && valor.length > 3) return null;
        if (nome == "descricao" && valor.length > 100) return null;
        if (nome == "ativo") {
            valor = valor.toLowerCase();
            if (valor != "true" && valor != "false") return null;
        }

        query += "&" + nome + "=" + encodeURIComponent(valor);
    }

    return query;
}

function adicionarErro(dataset, codigoErro, mensagem) {
    dataset.addRow([
        "false",
        valorTexto(codigoErro),
        valorTexto(mensagem),
        "", "", "", "", "", "", "", ""
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

function obterUsuario() {
    try {
        return limpar(getValue("WKUser"));
    } catch (erro) {
        return "";
    }
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
