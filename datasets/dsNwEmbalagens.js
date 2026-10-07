/** DT-116: modelo ES5 para publicar como dsNwEmbalagens.
 * Entrada: constraints acao e parametros (objeto JSON textual).
 * Saida: UMA linha; resultadoJson contem o envelope funcional da API.
 * Configurar regras reais abaixo antes de publicar. Nao alterar o Dataset de tipos.
 * Sem sincronizacao, credenciais, URL livre ou repeticao automatica de comandos.
 */
var NW_CONFIG = {
    serviceCode: "DATASUL_REST_HOMOLOG",
    base: "/dts/datasul-rest/resources/prg/esp/v1/controle-embalagens",
    // TESTE: comandos habilitados um a um, conforme a tela que os usa for integrada.
    // Aceita false, true (todos) ou a lista de acoes. Nao substitui a permissao por grupo em regras.
    escritasHabilitadas: ["incluirTipo", "alterarTipo"],
    timeoutSegundos: "60",
    maxEntrada: 120000,
    maxResposta: 2000000,
    // Configuracao de servidor, NAO recebida do Widget.
    // Cada regra: { grupo: codigoReal, acoes: [nomesExatos], estabelecimentos: [codigosReais] }.
    // Para tipos globais, estabelecimentos pode ser []; nenhuma regra usa wildcard.
    // TESTE (07/10/2026, definido pelo usuario): DefaultGroup-1 libera tipos para o grupo padrao da empresa 1.
    // Grupo definitivo por acao continua pendente (DT-054); revisar antes de producao.
    regras: [
        { grupo: "DefaultGroup-1", acoes: ["consultarTipos", "consultarTiposApoio", "incluirTipo", "alterarTipo"], estabelecimentos: [] }
    ]
};

var NW_COLUNAS = ["acao", "sucesso", "codigoErro", "mensagem", "httpStatus",
    "total", "temMais", "campoCursor", "proximoCursor", "repeticao", "resultadoJson"];

// Registro fechado. Metodos/rotas nunca sao escolhidos pelo navegador.
var NW_ACOES = {
    consultarTipos: nwGet("/tipos", false, "codigoDe codigoAte descricao ativo aposCodigo limite", "", "proximoCodigo", "aposCodigo", 100),
    incluirTipo: nwWrite("post", "/tipos", false, "codTipo descricao ativo versao chaveIdempotente", "codTipo descricao ativo chaveIdempotente"),
    alterarTipo: nwWrite("patch", "/tipos", false, "codTipo descricao ativo versao acao chaveIdempotente", "codTipo descricao ativo versao acao chaveIdempotente"),
    consultarParametros: nwGet("/parametros", true, "estabelDe estabelAte itemDe itemAte ativo aposId limite", "", "proximoId", "aposId", 100),
    incluirParametro: nwWrite("post", "/parametros", true, "idParam codEstabel item codTipo capacidade unidade ativo versao loteMigracao validadeMigracao chaveIdempotente", "codEstabel item codTipo capacidade unidade ativo chaveIdempotente"),
    alterarParametro: nwWrite("patch", "/parametros", true, "idParam codEstabel item codTipo capacidade unidade ativo versao acao loteMigracao validadeMigracao chaveIdempotente", "idParam codEstabel item codTipo capacidade unidade ativo versao acao chaveIdempotente"),
    consultarEtiquetas: nwGet("/etiquetas", true, "codEstabel codEtiqueta item lote codTipo tipoControle tipoLocal situacao idBag aposId limite", "", "proximoId", "aposId", 100),
    apoiarEstabelecimentos: nwGet("/apoios/estabelecimentos", true, "filtro aposCodigo limite", "filtro", "proximoCodigo", "aposCodigo", 20),
    apoiarItens: nwGet("/apoios/itens", true, "codEstabel filtro aposCodigo limite", "codEstabel filtro", "proximoCodigo", "aposCodigo", 20),
    apoiarTipos: nwGet("/apoios/tipos", false, "filtro ativo aposCodigo limite", "filtro", "proximoCodigo", "aposCodigo", 20),
    apoiarFamilias: nwGet("/apoios/familias", true, "filtro aposCodigo limite", "filtro", "proximoCodigo", "aposCodigo", 20),
    consultarBags: nwGet("/bags", true, "idBag codEstabel filtroLacre codTipo situacao inicio fim aposId limite", "", "proximoId", "aposId", 20),
    consultarConteudoBag: nwGet("/conteudo-bag", true, "idBag aposId limite", "idBag", "proximoId", "aposId", 20),
    obterDadosImpressao: nwGet("/dados-impressao", true, "idEtiqueta", "idEtiqueta", "proximoId", "", 0),
    consultarGeracao: nwGet("/geracoes", true, "idEvento aposId limite", "idEvento", "proximoId", "aposId", 100),
    classificarNatureza: nwGet("/operacoes/natureza", true, "codEstabel natureza", "codEstabel natureza", "", "", 0),
    consultarEmbalagensOrigem: nwGet("/operacoes/embalagens-origem", true, "codEstabel natureza emitenteOrigem serieOrigem numeroOrigem naturezaOrigem aposIdEtiqueta limite", "codEstabel natureza emitenteOrigem serieOrigem numeroOrigem naturezaOrigem", "proximoId", "aposIdEtiqueta", 100),
    consultarOperacoes: nwGet("/operacoes", true, "codEstabel idOperacao wt situacao tipoOperacao aposId limite", "codEstabel", "proximoId", "aposId", 100),
    consultarResultadoOperacao: nwGet("/operacoes/resultado", true, "codEstabel chaveIdempotente ramo emitenteOrigem serieOrigem numeroOrigem naturezaOrigem", "codEstabel chaveIdempotente ramo", "proximoId", "", 0),
    consultarItensOperacao: nwGet("/operacoes/itens", true, "codEstabel idOperacao aposId limite", "codEstabel idOperacao", "proximoId", "aposId", 100),
    consultarEventosOperacao: nwGet("/operacoes/eventos", true, "codEstabel idOperacao aposId limite", "codEstabel idOperacao", "proximoId", "aposId", 100),
    criarTransferencia: nwWrite("post", "/operacoes/transferencias", true, "codEstabel codEstabelDestino emitenteDestino natureza serie valorItem chaveIdempotente selecao", "codEstabel codEstabelDestino natureza serie valorItem chaveIdempotente selecao"),
    criarRemessa: nwWrite("post", "/operacoes/remessas", true, "codEstabel codEstabelDestino emitenteDestino natureza serie valorItem chaveIdempotente selecao", "codEstabel natureza serie valorItem chaveIdempotente selecao"),
    criarDevolucao: nwWrite("post", "/operacoes/devolucoes", true, "codEstabel natureza serie emitenteOrigem serieOrigem numeroOrigem naturezaOrigem chaveIdempotente selecao", "codEstabel natureza serie emitenteOrigem serieOrigem numeroOrigem naturezaOrigem chaveIdempotente selecao")
};

// Nome da consulta de apoio usado pelo autocomplete; preserva a acao apoiarTipos.
NW_ACOES.consultarTiposApoio = NW_ACOES.apoiarTipos;

function nwGet(rota, estabel, campos, obrigatorios, cursor, entradaCursor, teto) {
    return { metodo: "get", rota: rota, estabel: estabel, campos: campos.split(" "),
        obrigatorios: obrigatorios ? obrigatorios.split(" ") : [], cursor: cursor,
        entradaCursor: entradaCursor, teto: teto };
}
function nwWrite(metodo, rota, estabel, campos, obrigatorios) {
    return { metodo: metodo, rota: rota, estabel: estabel, campos: campos.split(" "),
        obrigatorios: obrigatorios.split(" "), cursor: "", entradaCursor: "", teto: 0 };
}
function defineStructure() {
    for (var i = 0; i < NW_COLUNAS.length; i++) addColumn(NW_COLUNAS[i]);
}
function onSync(lastSyncDate) { return null; }
function onMobileSync(user) { return null; }

function createDataset(fields, constraints, sortFields) {
    var ds = DatasetBuilder.newDataset();
    for (var i = 0; i < NW_COLUNAS.length; i++) ds.addColumn(NW_COLUNAS[i]);
    var acao = "", status = "", escrita = false, invocou = false, confirmouResultado = false;
    try {
        if ((fields && fields.length) || (sortFields && sortFields.length))
            nwFalhar("ENTRADA_INVALIDA", "Use o envelope completo e a ordenacao da API.");
        var entrada = nwEntrada(constraints);
        acao = entrada.acao;
        if (!nwTem(NW_ACOES, acao)) nwFalhar("ACAO_INVALIDA", "Acao nao disponivel neste Dataset.");
        var regra = NW_ACOES[acao];
        escrita = regra.metodo !== "get";
        var parametros = nwParametros(entrada.parametros, regra);
        var usuario = nwSessao("WKUser"), empresa = nwSessao("WKCompany");
        if (!usuario || !empresa) nwFalhar("CONTEXTO_INVALIDO", "Nao foi possivel identificar a sessao Fluig.");
        var permitidos = nwAutorizar(usuario, empresa, acao, regra.estabel);
        nwConferirEstabelecimentos(parametros, permitidos);
        if (escrita && !nwEscritaHabilitada(acao))
            nwFalhar("ESCRITA_DESABILITADA", "Comandos ainda nao habilitados nesta configuracao do Dataset.");

        var req = { companyId: empresa, serviceCode: NW_CONFIG.serviceCode,
            endpoint: NW_CONFIG.base + regra.rota, method: regra.metodo,
            timeoutService: NW_CONFIG.timeoutSegundos, headers: { "Accept": "application/json" } };
        if (!escrita) {
            var query = ["usuario=" + encodeURIComponent(usuario)];
            if (regra.estabel) for (i = 0; i < permitidos.length; i++)
                query.push("estabelecimentoPermitido=" + encodeURIComponent(permitidos[i]));
            for (var nome in parametros) if (nwTem(parametros, nome))
                query.push(encodeURIComponent(nome) + "=" + encodeURIComponent(String(parametros[nome])));
            req.endpoint += "?" + query.join("&");
        } else {
            parametros.usuario = usuario;
            if (regra.estabel) parametros.estabelecimentosPermitidos = permitidos;
            req.params = parametros;
            req.options = { encoding: "UTF-8", mediaType: "application/json" };
            req.headers["Content-Type"] = "application/json";
        }
        var client = fluigAPI.getAuthorizeClientService();
        invocou = true;
        var resposta = client.invoke(JSON.stringify(req)); // Uma unica invocacao; sem retry.
        try { status = nwTexto(resposta.getHttpStatusResult()); } catch (eStatus) { status = ""; }
        if (!/^[0-9]{3}$/.test(status)) nwFalhar("HTTP_STATUS_INDISPONIVEL", "Nao foi possivel confirmar o status HTTP da API.");
        var numeroStatus = Number(status);
        if (numeroStatus < 200 || numeroStatus >= 300)
            nwFalhar("HTTP_" + status, "A API respondeu HTTP " + status + ".");
        var corpo = nwTexto(resposta.getResult());
        if (!corpo || corpo.length > NW_CONFIG.maxResposta)
            nwFalhar("RESPOSTA_INVALIDA", "Resposta vazia ou acima do limite do Dataset.");
        var resultado;
        try { resultado = JSON.parse(corpo); }
        catch (eJson) { nwFalhar("RESPOSTA_INVALIDA", "A API nao retornou JSON valido."); }
        nwValidarResposta(resultado, regra, parametros);
        confirmouResultado = true;
        if (!resultado.sucesso) {
            var codigo = /^[A-Z0-9_]{1,100}$/.test(resultado.codigoErro || "") ? resultado.codigoErro : "RECUSA_API";
            nwFalhar(codigo, nwMensagem(resultado.mensagem));
        }
        nwLinha(ds, acao, status, resultado, regra.cursor);
    } catch (erro) {
        var codigoErro = erro && erro.nwCodigo ? erro.nwCodigo : "FALHA_CHAMADA";
        var mensagem = erro && erro.nwCodigo ? erro.nwMensagem : "Nao foi possivel concluir a chamada autorizada.";
        // Timeout/HTTP/JSON invalidos apos envio de comando nao provam rollback.
        if (escrita && invocou && !confirmouResultado) {
            mensagem += " Se o resultado for incerto, consulte a mesma chave antes de repetir; nao gere chave nova.";
        }
        log.warn("[dsNwEmbalagens] acao=" + (nwTem(NW_ACOES, acao) ? acao : "INVALIDA") + " codigo=" + codigoErro);
        nwLinha(ds, acao && nwTem(NW_ACOES, acao) ? acao : "", status,
            { sucesso: false, codigoErro: codigoErro, mensagem: mensagem }, "");
    }
    return ds;
}

// Constraints que o proprio Fluig acrescenta na chamada (nao vem do Widget e nao sao repassadas a API).
var NW_CONSTRAINTS_FLUIG = ["sqlLimit"];

function nwEntrada(constraints) {
    var entrada = {}, nomes = ["acao", "parametros"];
    for (var i = 0; constraints && i < constraints.length; i++) {
        var c = constraints[i], nome = nwTexto(c.getFieldName());
        if (nwIndice(NW_CONSTRAINTS_FLUIG, nome) >= 0) continue;
        if (nwIndice(nomes, nome) < 0 || nwTem(entrada, nome))
            nwFalhar("ENTRADA_INVALIDA", "Constraint desconhecida ou repetida: " + nome.replace(/[^A-Za-z0-9_.-]/g, "").substring(0, 40) + ".");
        var valor = nwTexto(c.getInitialValue());
        var valorFinal = c.getFinalValue ? nwTexto(c.getFinalValue()) : "";
        // filterFields pode chegar sem valor final; isso e constraint escalar.
        if (valorFinal !== "" && valorFinal !== valor) nwFalhar("ENTRADA_INVALIDA", "Faixas de constraints nao sao aceitas; use parametros JSON.");
        if (valor.length > NW_CONFIG.maxEntrada) nwFalhar("ENTRADA_INVALIDA", "Entrada acima do limite.");
        entrada[nome] = valor;
    }
    if (!entrada.acao || entrada.acao.length > 80) nwFalhar("ACAO_INVALIDA", "Informe uma acao nominal.");
    return { acao: entrada.acao, parametros: entrada.parametros || "{}" };
}

function nwParametros(texto, regra) {
    var p;
    try { p = JSON.parse(texto); } catch (e) { nwFalhar("PARAMETROS_INVALIDOS", "parametros deve conter um objeto JSON valido."); }
    if (!nwObjeto(p)) nwFalhar("PARAMETROS_INVALIDOS", "parametros deve ser um objeto JSON.");
    for (var nome in p) if (nwTem(p, nome)) {
        if (nwIndice(regra.campos, nome) < 0) nwFalhar("CAMPO_NAO_PERMITIDO", "Campo nao permitido para esta acao.");
        var v = p[nome];
        if (nome === "selecao") { nwSelecao(v); continue; }
        if (v === null || (typeof v !== "string" && typeof v !== "number" && typeof v !== "boolean"))
            nwFalhar("PARAMETROS_INVALIDOS", "Tipo de parametro invalido.");
        if (typeof v === "string" && (v.length > (nome === "chaveIdempotente" ? 200 : 100) || /[\x00-\x1f]/.test(v)))
            nwFalhar("PARAMETROS_INVALIDOS", "Texto invalido ou acima do limite.");
        if (regra.metodo === "get") {
            if (nome === "limite") {
                if (!/^[1-9][0-9]*$/.test(String(v)) || Number(v) > regra.teto) nwFalhar("LIMITE_INVALIDO", "Limite fora da faixa desta consulta.");
            } else if (nome === "ativo") {
                if (v !== true && v !== false && v !== "true" && v !== "false" && !(regra.rota === "/apoios/tipos" && v === "todos")) nwFalhar("PARAMETROS_INVALIDOS", "ativo deve ser true ou false; todos somente no apoio de tipos.");
            } else if (typeof v !== "string") nwFalhar("PARAMETROS_INVALIDOS", "Filtros e IDs devem ser texto; limite pode ser numero.");
        } else {
            if (nwIndice(["idParam", "versao"], nome) >= 0) {
                // O adaptador cadastral vigente usa GetInteger: numeros JSON aqui.
                if (typeof v !== "number" || v % 1 !== 0 || v < 0 || v > 2147483647) nwFalhar("PARAMETROS_INVALIDOS", "Versao/idParam cadastral deve ser inteiro JSON valido.");
            } else if (nome === "capacidade" || nome === "valorItem") {
                if (typeof v !== "number" || !isFinite(v) || v < 0) nwFalhar("PARAMETROS_INVALIDOS", "Quantidade monetaria/capacidade deve ser numero nao negativo.");
            } else if (nome === "ativo") {
                if (typeof v !== "boolean") nwFalhar("PARAMETROS_INVALIDOS", "ativo deve ser booleano JSON.");
            } else if (typeof v !== "string") nwFalhar("PARAMETROS_INVALIDOS", "Codigos e identificadores devem ser texto.");
        }
    }
    for (var i = 0; i < regra.obrigatorios.length; i++) {
        var obrigatorio = regra.obrigatorios[i];
        if (!nwTem(p, obrigatorio) || p[obrigatorio] === "") nwFalhar("PARAMETRO_OBRIGATORIO", "Faltam parametros obrigatorios desta acao.");
    }
    if (regra.teto && !nwTem(p, "limite")) p.limite = 20;
    if (nwTem(p, "filtro") && p.filtro.replace(/^\s+|\s+$/g, "").length < 2) nwFalhar("FILTRO_INVALIDO", "Digite pelo menos dois caracteres.");
    if (nwTem(p, "chaveIdempotente") && !p.chaveIdempotente.replace(/^\s+|\s+$/g, "")) nwFalhar("PARAMETROS_INVALIDOS", "Chave idempotente obrigatoria.");
    if (regra.rota === "/operacoes/resultado") {
        if (p.ramo !== "DIRETO" && p.ramo !== "DEVOLUCAO") nwFalhar("PARAMETROS_INVALIDOS", "Ramo deve ser DIRETO ou DEVOLUCAO.");
        if (p.ramo === "DEVOLUCAO") for (i = 0; i < 4; i++) {
            var origem = ["emitenteOrigem", "serieOrigem", "numeroOrigem", "naturezaOrigem"][i];
            if (!p[origem]) nwFalhar("PARAMETRO_OBRIGATORIO", "Informe a identidade completa da origem.");
        }
    }
    return p;
}

function nwSelecao(lista) {
    if (!nwArray(lista) || lista.length < 1 || lista.length > 100) nwFalhar("SELECAO_INVALIDA", "Selecione de uma a cem embalagens.");
    var ids = {};
    for (var i = 0; i < lista.length; i++) {
        var e = lista[i];
        if (!nwObjeto(e)) nwFalhar("SELECAO_INVALIDA", "Cada selecao deve ser um objeto.");
        for (var nome in e) if (nwTem(e, nome) && nwIndice(["idEtiqueta", "versao", "quantidade"], nome) < 0)
            nwFalhar("SELECAO_INVALIDA", "Campo desconhecido na selecao.");
        if (!nwIdPositivo(e.idEtiqueta) || !nwIdPositivo(e.versao)) nwFalhar("SELECAO_INVALIDA", "Etiqueta/versao devem ser inteiros positivos em texto.");
        if (nwTem(ids, e.idEtiqueta)) nwFalhar("SELECAO_INVALIDA", "Etiqueta repetida.");
        ids[e.idEtiqueta] = true;
        if (typeof e.quantidade !== "number" || !isFinite(e.quantidade) || e.quantidade <= 0 ||
            Math.abs(e.quantidade * 10000 - Math.round(e.quantidade * 10000)) > 0.00001)
            nwFalhar("SELECAO_INVALIDA", "Quantidade deve ser positiva, com ate quatro casas decimais.");
    }
}

function nwAutorizar(usuario, empresa, acao, exigeEstabel) {
    if (!nwArray(NW_CONFIG.regras) || !NW_CONFIG.regras.length) nwFalhar("AUTORIZACAO_NAO_CONFIGURADA", "Configure os grupos e permissoes no servidor Fluig.");
    // Campos documentados do Dataset interno; conferir na instalacao 1.8.1.
    var constraints = [
        DatasetFactory.createConstraint("colleagueGroupPK.companyId", empresa, empresa, ConstraintType.MUST),
        DatasetFactory.createConstraint("colleagueGroupPK.colleagueId", usuario, usuario, ConstraintType.MUST)
    ];
    var grupos = DatasetFactory.getDataset("colleagueGroup", null, constraints, null);
    if (!grupos || typeof grupos.rowsCount === "undefined") nwFalhar("FALHA_AUTORIZACAO", "Nao foi possivel consultar os grupos da sessao.");
    var membros = {};
    for (var i = 0; i < grupos.rowsCount; i++) {
        // Revalidar identidade mesmo se a instalacao ignorar algum filtro.
        if (nwCampoGrupo(grupos, i, "companyId") !== empresa ||
            nwCampoGrupo(grupos, i, "colleagueId") !== usuario) continue;
        var grupo = nwCampoGrupo(grupos, i, "groupId");
        if (grupo) membros["g:" + grupo] = true;
    }
    var liberado = false, permitidos = [];
    for (i = 0; i < NW_CONFIG.regras.length; i++) {
        var r = NW_CONFIG.regras[i];
        if (!nwObjeto(r) || !r.grupo || !nwArray(r.acoes) || !nwArray(r.estabelecimentos)) nwFalhar("AUTORIZACAO_NAO_CONFIGURADA", "Politica de autorizacao invalida.");
        if (!nwTem(membros, "g:" + r.grupo) || nwIndice(r.acoes, acao) < 0) continue;
        liberado = true;
        // Uniao SOMENTE de regras que concedem ESTA acao; nao misturar permissoes.
        for (var j = 0; j < r.estabelecimentos.length; j++) {
            var est = r.estabelecimentos[j];
            if (typeof est !== "string" || !/^[A-Za-z0-9_-]{1,20}$/.test(est)) nwFalhar("AUTORIZACAO_NAO_CONFIGURADA", "Estabelecimento da politica invalido.");
            if (nwIndice(permitidos, est) < 0) permitidos.push(est);
        }
    }
    if (!liberado || (exigeEstabel && !permitidos.length)) nwFalhar("SEM_PERMISSAO", "Acao ou estabelecimento nao autorizado.");
    permitidos.sort();
    return permitidos;
}

// TESTE 1.8.1 (07/10/2026): pela API REST o colleagueGroup aceita o filtro colleagueGroupPK.colleagueId,
// mas devolve as colunas como companyId/groupId/colleagueId. Le o nome PK documentado e, vazio, o nome
// curto da MESMA linha. Nao confirmado ainda dentro de um Dataset publicado.
function nwCampoGrupo(grupos, linha, campo) {
    var valor = "";
    try { valor = nwTexto(grupos.getValue(linha, "colleagueGroupPK." + campo)); } catch (ePk) { valor = ""; }
    if (valor === "" || valor === "null") {
        try { valor = nwTexto(grupos.getValue(linha, campo)); } catch (eCurto) { valor = ""; }
    }
    return valor === "null" ? "" : valor;
}

function nwEscritaHabilitada(acao) {
    var cfg = NW_CONFIG.escritasHabilitadas;
    return cfg === true || (nwArray(cfg) && nwIndice(cfg, acao) >= 0);
}

function nwConferirEstabelecimentos(p, permitidos) {
    var nomes = ["codEstabel", "codEstabelDestino"];
    for (var i = 0; i < nomes.length; i++) if (nwTem(p, nomes[i]) && p[nomes[i]] !== "" && nwIndice(permitidos, p[nomes[i]]) < 0)
        nwFalhar("SEM_PERMISSAO", "Estabelecimento nao autorizado para esta acao.");
}

function nwValidarResposta(r, regra, parametros) {
    if (!nwObjeto(r) || typeof r.sucesso !== "boolean") nwFalhar("RESPOSTA_INVALIDA", "Envelope funcional da API invalido.");
    if (!r.sucesso) return;
    if (nwTem(r, "dados") && !nwArray(r.dados)) nwFalhar("RESPOSTA_INVALIDA", "dados deve ser uma lista.");
    if (regra.metodo === "get" && regra.teto) {
        // Geracoes usa etiquetas/itens/geracao, NAO dados; preservar esse contrato.
        var linhas = regra.rota === "/geracoes" ? r.etiquetas : r.dados;
        if (!nwArray(linhas) || typeof r.total !== "number" || r.total !== linhas.length ||
            typeof r.temMais !== "boolean" || linhas.length > Number(parametros.limite))
            nwFalhar("RESPOSTA_INVALIDA", "Envelope da pagina invalido.");
        if (r.temMais) {
            var cursor = r[regra.cursor];
            if (typeof cursor !== "string" || !cursor || !linhas.length || cursor === parametros[regra.entradaCursor])
                nwFalhar("CURSOR_INVALIDO", "A API informou mais dados sem um cursor novo valido.");
            if (/^aposId/.test(regra.entradaCursor) && (!nwIdPositivo(cursor) || Number(cursor) <= Number(parametros[regra.entradaCursor] || "0")))
                nwFalhar("CURSOR_INVALIDO", "Cursor numerico nao avancou.");
        }
    }
    // Defesa contra propagacao acidental de campos tecnicos/credenciais.
    nwConferirRespostaSegura(r, 0);
}
function nwConferirRespostaSegura(valor, nivel) {
    if (nivel > 15) nwFalhar("RESPOSTA_INVALIDA", "Resposta acima da profundidade permitida.");
    if (typeof valor === "string" && /(?:authorization\s*[:=]|bearer\s+|set-cookie\s*:|(?:acTk|rfTk)\s*[:=])/i.test(valor))
        nwFalhar("RESPOSTA_INVALIDA", "Resposta contem informacao tecnica nao permitida.");
    if (!valor || typeof valor !== "object") return;
    for (var nome in valor) if (nwTem(valor, nome)) {
        if (/^(?:__proto__|prototype|constructor|password|senha|token|access_token|refresh_token|authorization|cookie|cookies|headers|oInput|stack|observacao|dados-evento|resultadoTecnico)$/i.test(nome))
            nwFalhar("RESPOSTA_INVALIDA", "Resposta contem campo nao permitido.");
        nwConferirRespostaSegura(valor[nome], nivel + 1);
    }
}

function nwLinha(ds, acao, status, r, cursor) {
    ds.addRow([acao, String(r.sucesso), nwTexto(r.codigoErro), nwTexto(r.mensagem), status,
        nwTem(r, "total") ? nwTexto(r.total) : "", nwTem(r, "temMais") ? String(r.temMais) : "",
        cursor, cursor ? nwTexto(r[cursor]) : "", nwTem(r, "repeticao") ? String(r.repeticao) : "", JSON.stringify(r)]);
}
function nwSessao(nome) { try { return nwTexto(getValue(nome)).replace(/^\s+|\s+$/g, ""); } catch (e) { return ""; } }
function nwMensagem(v) {
    if (typeof v !== "string" || /(?:cookie|authorization|bearer|acTk|rfTk|password|senha|stack|SOAPFaultException)/i.test(v)) return "A API recusou a operacao.";
    return v.substring(0, 300) || "A API recusou a operacao.";
}
function nwFalhar(codigo, mensagem) { var e = new Error(codigo); e.nwCodigo = codigo; e.nwMensagem = mensagem; throw e; }
function nwTexto(v) { return v === null || typeof v === "undefined" ? "" : String(v); }
function nwTem(o, k) { return Object.prototype.hasOwnProperty.call(o, k); }
function nwIndice(lista, v) { for (var i = 0; i < lista.length; i++) if (lista[i] === v) return i; return -1; }
function nwArray(v) { return Object.prototype.toString.call(v) === "[object Array]"; }
function nwObjeto(v) { return v !== null && Object.prototype.toString.call(v) === "[object Object]"; }
function nwIdPositivo(v) { return typeof v === "string" && /^[1-9][0-9]{0,9}$/.test(v) && Number(v) <= 2147483647; }
