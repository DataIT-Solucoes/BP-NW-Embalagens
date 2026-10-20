/* Adaptador REST v1 do Controle de Embalagens.
   O controle de grupos e a identidade do usuario sao resolvidos no Fluig.
   O Dataset injeta usuario e estabelecimentos permitidos; o Widget nao envia
   esses valores como contexto de autorizacao.
   Este recurso deve ser acessivel somente pelo servico autorizado do Fluig.
   Regras e persistencia permanecem em fontes/progress/contr-emb.p. */
{utp/ut-api.i}

{utp/ut-api-action.i pi-consultar-tipos      GET   /tipos~* }
{utp/ut-api-action.i pi-salvar-tipo          POST  /tipos~* }
{utp/ut-api-action.i pi-salvar-tipo          PATCH /tipos~* }
{utp/ut-api-action.i pi-consultar-parametros GET   /parametros~* }
{utp/ut-api-action.i pi-salvar-parametro     POST  /parametros~* }
{utp/ut-api-action.i pi-salvar-parametro     PATCH /parametros~* }
{utp/ut-api-action.i pi-estornar-etiqueta POST /etiquetas/estorno~* }
{utp/ut-api-action.i pi-inutilizar-etiqueta POST /etiquetas/inutilizacao~* }
{utp/ut-api-action.i pi-registrar-perda POST /etiquetas/perda-extravio~* }
{utp/ut-api-action.i pi-confirmar-etiqueta POST /etiquetas/confirmacoes~* }
{utp/ut-api-action.i pi-situacao-etiqueta GET /etiquetas/situacao~* }
{utp/ut-api-action.i pi-historico-etiqueta GET /etiquetas/historico~* }
{utp/ut-api-action.i pi-consultar-etiquetas  GET   /etiquetas~* }
{utp/ut-api-action.i pi-apoios-estabelecimentos GET /apoios/estabelecimentos~* }
{utp/ut-api-action.i pi-apoios-itens GET /apoios/itens~* }

{utp/ut-api-action.i pi-apoios-tipos GET /apoios/tipos~* }
{utp/ut-api-action.i pi-elegiveis-bag GET /bags/elegiveis~* }
{utp/ut-api-action.i pi-historico-bag GET /bags/historico~* }
{utp/ut-api-action.i pi-conteudo-bag-comando POST /bags/conteudo~* }
{utp/ut-api-action.i pi-evento-bag POST /bags/eventos~* }
{utp/ut-api-action.i pi-editar-bag PATCH /bags~* }
{utp/ut-api-action.i pi-abrir-bag POST /bags~* }
{utp/ut-api-action.i pi-consultar-bags GET /bags~* }
{utp/ut-api-action.i pi-consultar-conteudo-bag GET /conteudo-bag~* }

{utp/ut-api-action.i pi-apoios-familias GET /apoios/familias~* }
{utp/ut-api-action.i pi-dados-impressao GET /dados-impressao~* }
{utp/ut-api-action.i pi-consultar-geracao GET /geracoes~* }

{utp/ut-api-action.i pi-classificar-natureza GET /operacoes/natureza~* }

{utp/ut-api-action.i pi-embalagens-origem GET /operacoes/embalagens-origem~* }

{utp/ut-api-action.i pi-criar-transferencia POST /operacoes/transferencias~* }
{utp/ut-api-action.i pi-criar-remessa POST /operacoes/remessas~* }
{utp/ut-api-action.i pi-criar-devolucao POST /operacoes/devolucoes~* }
{utp/ut-api-action.i pi-resultado-operacao GET /operacoes/resultado~* }
{utp/ut-api-action.i pi-itens-operacao GET /operacoes/itens~* }
{utp/ut-api-action.i pi-eventos-operacao GET /operacoes/eventos~* }
{utp/ut-api-action.i pi-listar-operacoes GET /operacoes~* }

{utp/ut-api-action.i pi-xml-detalhe GET /xmls/detalhe~* }
{utp/ut-api-action.i pi-xml-lista GET /xmls~* }

{utp/ut-api-action.i pi-recebimentos-itens GET /recebimentos/itens~* }
{utp/ut-api-action.i pi-recebimentos-embalagens GET /recebimentos/embalagens~* }
{utp/ut-api-action.i pi-recebimentos GET /recebimentos~* }
{utp/ut-api-action.i pi-apoios-depositos GET /apoios/depositos~* }
{utp/ut-api-action.i pi-apoios-lotes GET /apoios/lotes~* }
{utp/ut-api-action.i pi-apoios-documentos GET /apoios/documentos-entrada~* }

{utp/ut-api-notfound.i}
{fontes/progress/contr-emb.i}
{fontes/progress/includes/contr-emb-confirmacao-comum.i}

/* Declaracoes antecipadas: o OpenEdge exige que funcoes chamadas pelas
   procedures estejam conhecidas no ponto da chamada. As implementacoes
   permanecem no final deste arquivo para manter os auxiliares agrupados. */
FUNCTION fnQueryChar RETURNS CHARACTER
    (INPUT poQuery AS JsonObject, INPUT pcNome AS CHARACTER,
     INPUT pcPadrao AS CHARACTER) FORWARD.
FUNCTION fnQueryInteger RETURNS INTEGER
    (INPUT poQuery AS JsonObject, INPUT pcNome AS CHARACTER,
     INPUT piPadrao AS INTEGER) FORWARD.
FUNCTION fnQueryLogical RETURNS LOGICAL
    (INPUT poQuery AS JsonObject, INPUT pcNome AS CHARACTER) FORWARD.
FUNCTION fnBodyChar RETURNS CHARACTER
    (INPUT poBody AS JsonObject, INPUT pcNome AS CHARACTER,
     INPUT pcPadrao AS CHARACTER) FORWARD.
FUNCTION fnBodyRequestMethod RETURNS CHARACTER
    (INPUT poInput AS JsonObject) FORWARD.
FUNCTION fnBodyInteger RETURNS INTEGER
    (INPUT poBody AS JsonObject, INPUT pcNome AS CHARACTER,
     INPUT piPadrao AS INTEGER) FORWARD.
FUNCTION fnBodyDecimal RETURNS DECIMAL
    (INPUT poBody AS JsonObject, INPUT pcNome AS CHARACTER,
     INPUT pdPadrao AS DECIMAL) FORWARD.
FUNCTION fnBodyLogical RETURNS LOGICAL
    (INPUT poBody AS JsonObject, INPUT pcNome AS CHARACTER) FORWARD.
FUNCTION fnSha256 RETURNS CHARACTER
    (INPUT pcValor AS CHARACTER) FORWARD.

FUNCTION fnQueryTextoEstrito RETURNS CHARACTER
    (INPUT poQuery AS JsonObject, INPUT pcNome AS CHARACTER, INPUT pcPadrao AS CHARACTER) FORWARD.
FUNCTION fnQueryNumeroEstrito RETURNS INTEGER
    (INPUT poQuery AS JsonObject, INPUT pcNome AS CHARACTER, INPUT piPadrao AS INTEGER) FORWARD.
FUNCTION fnDataISO RETURNS DATE (INPUT pcData AS CHARACTER) FORWARD.

PROCEDURE pi-apoios-depositos:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piApoiosManutencao(oInput,"DEPOSITOS",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-apoios-lotes:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piApoiosManutencao(oInput,"LOTES",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-apoios-documentos:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piApoiosManutencao(oInput,"DOCUMENTOS",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE piFiltrosManutencao:
    DEFINE INPUT PARAMETER oManQuery AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER filtros AS JsonObject NO-UNDO.
    DEFINE VARIABLE campos AS CHARACTER NO-UNDO INITIAL
        "codEstabel,codEtiqueta,item,lote,codTipo,tipoControle,tipoLocal,situacao,idBag,aposId,limite,filtro,aposCodigo,estabelDe,estabelAte,itemDe,itemAte,depositoDe,depositoAte,etiquetaDe,etiquetaAte,loteDe,loteAte,validadeDe,validadeAte,familiaDe,familiaAte,notaDe,notaAte,modoNotas,somenteComEmbalagens".
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE valor AS CHARACTER NO-UNDO.
    filtros = NEW JsonObject().
    DO n = 1 TO NUM-ENTRIES(campos):
        IF NOT oManQuery:Has(ENTRY(n,campos)) THEN NEXT.
        valor = fnQueryTextoEstrito(oManQuery,ENTRY(n,campos),?).
        IF valor = ? THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        filtros:Add(ENTRY(n,campos),valor).
    END.
    IF oManQuery:Has("documento") THEN filtros:Add("documentos",oManQuery:GetJsonArray("documento")).
END PROCEDURE.
PROCEDURE piAbrirManutencao:
    DEFINE OUTPUT PARAMETER nucleo AS HANDLE NO-UNDO.
    DEFINE VARIABLE modulo AS CHARACTER NO-UNDO.
    modulo = SEARCH("esp/api/v1/contr-emb-recebimentos.r").
    IF modulo = ? THEN modulo = SEARCH("_bp/api/ET-01_TESTE/fontes/progress/contr-emb-recebimentos.r").
    IF modulo = ? THEN modulo = SEARCH("fontes/progress/contr-emb-recebimentos.r").
    IF modulo = ? THEN UNDO, THROW NEW Progress.Lang.AppError("RECEBIMENTOS_NAO_LOCALIZADO",0).
    RUN VALUE(modulo) PERSISTENT SET nucleo.
END PROCEDURE.
PROCEDURE piApoiosManutencao:
    DEFINE INPUT PARAMETER inputJson AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER consulta AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    DEFINE VARIABLE oManParser AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE oManQuery AS JsonObject NO-UNDO.
    DEFINE VARIABLE filtros AS JsonObject NO-UNDO.
    DEFINE VARIABLE nucleo AS HANDLE NO-UNDO.
    DEFINE VARIABLE cFalhaMan AS CHARACTER NO-UNDO.
    DO ON ERROR UNDO, THROW:
        ASSIGN oManParser = NEW JsonAPIRequestParser(inputJson) oManQuery = oManParser:GetQueryParams().
        IF fnQueryTextoEstrito(oManQuery,"usuario","") = ? OR
            TRIM(fnQueryTextoEstrito(oManQuery,"usuario","")) = "" THEN DO:
            RUN piRespostaErro(OUTPUT resposta,"USUARIO_NAO_INFORMADO","Usuario da sessao obrigatorio.").
            RETURN.
        END.
        RUN piCarregarEstabelecimentosQuery(oManQuery).
        RUN piFiltrosManutencao(oManQuery,OUTPUT filtros).
        RUN piAbrirManutencao(OUTPUT nucleo).
        RUN consultarApoiosManutencao IN nucleo(consulta,INPUT TABLE ttEmbEstabelPermitido,filtros,OUTPUT resposta).
        CATCH falha AS Progress.Lang.Error:
            cFalhaMan = IF falha:NumMessages > 0 THEN falha:GetMessage(1) ELSE "".
            IF LOOKUP(cFalhaMan,"FILTRO_INVALIDO,RECEBIMENTOS_NAO_LOCALIZADO") = 0 THEN cFalhaMan = "FALHA_CONSULTA_APOIO".
            RUN piRespostaErro(OUTPUT resposta,cFalhaMan,"Nao foi possivel consultar opcoes; confira contexto, filtros e modulo publicado.").
        END CATCH.
        FINALLY:
            IF VALID-HANDLE(nucleo) THEN DELETE PROCEDURE nucleo NO-ERROR.
        END FINALLY.
    END.
END PROCEDURE.

PROCEDURE pi-recebimentos:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piRecebimentosConsulta(INPUT oInput, INPUT "DOCUMENTOS", OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-recebimentos-itens:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piRecebimentosConsulta(INPUT oInput, INPUT "ITENS", OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-recebimentos-embalagens:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piRecebimentosConsulta(INPUT oInput, INPUT "EMBALAGENS", OUTPUT oOutput).
END PROCEDURE.
PROCEDURE piRecebimentosConsulta:
    DEFINE INPUT PARAMETER poInput AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER pcConsulta AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER poOutput AS JsonObject NO-UNDO.
    DEFINE VARIABLE oParser AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE oQuery AS JsonObject NO-UNDO.
    DEFINE VARIABLE oFiltros AS JsonObject NO-UNDO.
    DEFINE VARIABLE cCampos AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCampo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cModulo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hConsulta AS HANDLE NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DO ON ERROR UNDO, THROW:
        ASSIGN oParser = NEW JsonAPIRequestParser(poInput) oQuery = oParser:GetQueryParams()
            oFiltros = NEW JsonObject().
        IF fnQueryTextoEstrito(oQuery,"usuario","") = "" THEN DO:
            RUN piRespostaErro(OUTPUT poOutput,"USUARIO_NAO_INFORMADO","Usuario da sessao obrigatorio.").
            RETURN.
        END.
        RUN piCarregarEstabelecimentosQuery(INPUT oQuery).
        cCampos = IF pcConsulta = "DOCUMENTOS" THEN
            "codEstabel,dataIni,dataFim,tipoData,emitente,serie,numero,natureza,item,etiqueta,atualizado,somenteComEmbalagens,aposDocumento,limite"
            ELSE IF pcConsulta = "ITENS" THEN
            "codEstabel,emitente,serie,numero,natureza,idEvento,aposSequencia,limite"
            ELSE "codEstabel,emitente,serie,numero,natureza,idEvento,sequencia,aposId,limite".
        DO i = 1 TO NUM-ENTRIES(cCampos):
            cCampo = ENTRY(i,cCampos).
            IF oQuery:Has(cCampo) THEN DO:
                cValor = fnQueryTextoEstrito(oQuery,cCampo,"").
                oFiltros:Add(cCampo,cValor).
            END.
        END.
        cModulo = SEARCH("esp/api/v1/contr-emb-recebimentos.r").
        IF cModulo = ? THEN cModulo = SEARCH("_bp/api/ET-01_TESTE/fontes/progress/contr-emb-recebimentos.r").
        IF cModulo = ? THEN cModulo = SEARCH("fontes/progress/contr-emb-recebimentos.r").
        IF cModulo = ? THEN DO:
            RUN piRespostaErro(OUTPUT poOutput,"RECEBIMENTOS_NAO_LOCALIZADO","Modulo de recebimentos nao localizado.").
            RETURN.
        END.
        RUN VALUE(cModulo) PERSISTENT SET hConsulta.
        RUN consultarRecebimentos IN hConsulta(INPUT pcConsulta, INPUT TABLE ttEmbEstabelPermitido,
            INPUT oFiltros, OUTPUT poOutput).
        CATCH falha AS Progress.Lang.Error:
            RUN piRespostaErro(OUTPUT poOutput,"FALHA_CONSULTA_RECEBIMENTOS","Nao foi possivel consultar recebimentos.").
        END CATCH.
        FINALLY:
            IF VALID-HANDLE(hConsulta) THEN DELETE PROCEDURE hConsulta NO-ERROR.
        END FINALLY.
    END.
END PROCEDURE.

/* Entrada exata selecionada; devolve a pagina de embalagens e impedimentos. */
PROCEDURE pi-embalagens-origem:
DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
DEFINE VARIABLE oRequest AS JsonAPIRequestParser NO-UNDO.
DEFINE VARIABLE oQuery AS JsonObject NO-UNDO.
DEFINE VARIABLE oOrigem AS JsonObject NO-UNDO.
DEFINE VARIABLE aDados AS JsonArray NO-UNDO.
DEFINE VARIABLE oLinha AS JsonObject NO-UNDO.
DEFINE VARIABLE hOper AS HANDLE NO-UNDO.
DEFINE VARIABLE cModulo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstabel AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNatureza AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSerie AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNumero AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNatOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagem AS CHARACTER NO-UNDO.
DEFINE VARIABLE iEmitente AS INTEGER NO-UNDO.
DEFINE VARIABLE iApos AS INTEGER NO-UNDO.
DEFINE VARIABLE iLimite AS INTEGER NO-UNDO.
DEFINE VARIABLE iEvento AS INTEGER NO-UNDO.
DEFINE VARIABLE iProximo AS INTEGER NO-UNDO.
DEFINE VARIABLE lMais AS LOGICAL NO-UNDO.
DEFINE VARIABLE lSucesso AS LOGICAL NO-UNDO.
DO ON ERROR UNDO, THROW:
    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    EMPTY TEMP-TABLE ttEmbOrigemDevolucao.
    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput)
           oQuery = oRequest:GetQueryParams()
           cUsuario = fnQueryTextoEstrito(oQuery,"usuario","")
           cEstabel = fnQueryTextoEstrito(oQuery,"codEstabel","")
           cNatureza = fnQueryTextoEstrito(oQuery,"natureza","")
           cSerie = fnQueryTextoEstrito(oQuery,"serieOrigem","")
           cNumero = fnQueryTextoEstrito(oQuery,"numeroOrigem","")
           cNatOrigem = fnQueryTextoEstrito(oQuery,"naturezaOrigem","")
           iEmitente = fnQueryNumeroEstrito(oQuery,"emitenteOrigem",0)
           iApos = fnQueryNumeroEstrito(oQuery,"aposIdEtiqueta",0)
           iLimite = fnQueryNumeroEstrito(oQuery,"limite",20).
    IF cUsuario = ? OR TRIM(cUsuario) = "" THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT YES,
            "USUARIO_NAO_INFORMADO", "Usuario da sessao obrigatorio.").
        RETURN.
    END.
    RUN piCarregarEstabelecimentosQuery(INPUT oQuery).
    cModulo = SEARCH("esp/api/v1/contr-emb-operacao.r").
    IF cModulo = ? THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT YES,
            "OPERACAO_NAO_LOCALIZADA", "Modulo de operacoes nao localizado no PROPATH.").
        RETURN.
    END.
    RUN VALUE(cModulo) PERSISTENT SET hOper.
    RUN consultarEmbalagensOrigem IN hOper
        (INPUT TABLE ttEmbEstabelPermitido, INPUT cEstabel, INPUT cNatureza,
         INPUT iEmitente, INPUT cSerie, INPUT cNumero, INPUT cNatOrigem,
         INPUT iApos, INPUT iLimite, OUTPUT TABLE ttEmbOrigemDevolucao,
         OUTPUT iEvento, OUTPUT lMais, OUTPUT iProximo,
         OUTPUT lSucesso, OUTPUT cErro, OUTPUT cMensagem).
    IF NOT lSucesso THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT YES, cErro, cMensagem).
        RETURN.
    END.
    ASSIGN aDados = NEW JsonArray() oOrigem = NEW JsonObject().
    oOrigem:Add("codEstabel",TRIM(cEstabel)).
    oOrigem:Add("emitente",STRING(iEmitente)).
    oOrigem:Add("serie",TRIM(cSerie)).
    oOrigem:Add("numero",TRIM(cNumero)).
    oOrigem:Add("natureza",TRIM(cNatOrigem)).
    oOrigem:Add("idEvento",STRING(iEvento)).
    FOR EACH ttEmbOrigemDevolucao BY ttEmbOrigemDevolucao.id-etiqueta:
        oLinha = NEW JsonObject().
        oLinha:Add("idEtiqueta",STRING(ttEmbOrigemDevolucao.id-etiqueta)).
        oLinha:Add("codEtiqueta",ttEmbOrigemDevolucao.cod-etiqueta).
        oLinha:Add("idEventoOrigem",STRING(ttEmbOrigemDevolucao.id-evento-origem)).
        oLinha:Add("idMovtoOrigem",STRING(ttEmbOrigemDevolucao.id-movto-origem)).
        oLinha:Add("sequenciaOrigem",ttEmbOrigemDevolucao.sequencia-origem).
        oLinha:Add("item",ttEmbOrigemDevolucao.it-codigo).
        oLinha:Add("lote",ttEmbOrigemDevolucao.lote).
        oLinha:Add("validadeLote",ttEmbOrigemDevolucao.dt-vali-lote).
        oLinha:Add("unidade",ttEmbOrigemDevolucao.un).
        oLinha:Add("deposito",ttEmbOrigemDevolucao.cod-depos).
        oLinha:Add("localizacao",ttEmbOrigemDevolucao.cod-localiz).
        oLinha:Add("quantidadeOrigem",ttEmbOrigemDevolucao.quantidade-origem).
        oLinha:Add("quantidadeAtual",ttEmbOrigemDevolucao.quantidade-atual).
        oLinha:Add("disponivelLinha",ttEmbOrigemDevolucao.disponivel-linha).
        oLinha:Add("versaoEtiqueta",ttEmbOrigemDevolucao.versao-etiqueta).
        oLinha:Add("podeSelecionar",ttEmbOrigemDevolucao.pode-selecionar).
        oLinha:Add("motivo",ttEmbOrigemDevolucao.motivo).
        aDados:Add(oLinha).
    END.
    oOutput = NEW JsonObject().
    oOutput:Add("sucesso",TRUE).
    oOutput:Add("codigoErro","").
    oOutput:Add("mensagem","").
    oOutput:Add("total",aDados:Length).
    oOutput:Add("temMais",lMais).
    oOutput:Add("proximoId",IF lMais THEN STRING(iProximo) ELSE "").
    oOutput:Add("origem",oOrigem).
    oOutput:Add("dados",aDados).
    CATCH eEmbOrigem AS Progress.Lang.Error:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT YES,
            "FALHA_CONSULTA_ORIGEM", "Nao foi possivel consultar as embalagens da origem.").
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hOper) THEN DELETE PROCEDURE hOper NO-ERROR.
        EMPTY TEMP-TABLE ttEmbEstabelPermitido.
        EMPTY TEMP-TABLE ttEmbOrigemDevolucao.
    END FINALLY.
END.
END PROCEDURE.

/* Natureza exata escolhida no modal; nao enumera nem autoriza naturezas. */
PROCEDURE pi-classificar-natureza:
DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
DEFINE VARIABLE oRequest AS JsonAPIRequestParser NO-UNDO.
DEFINE VARIABLE oQuery AS JsonObject NO-UNDO.
DEFINE VARIABLE aDados AS JsonArray NO-UNDO.
DEFINE VARIABLE oLinha AS JsonObject NO-UNDO.
DEFINE VARIABLE hOper AS HANDLE NO-UNDO.
DEFINE VARIABLE cModulo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstabel AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNatureza AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFluxo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cRamo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagem AS CHARACTER NO-UNDO.
DEFINE VARIABLE lOrigem AS LOGICAL NO-UNDO.
DEFINE VARIABLE lQuantidade AS LOGICAL NO-UNDO.
DEFINE VARIABLE lPreco AS LOGICAL NO-UNDO.
DEFINE VARIABLE lSucesso AS LOGICAL NO-UNDO.
DO ON ERROR UNDO, THROW:
    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput)
           oQuery = oRequest:GetQueryParams()
           cUsuario = fnQueryTextoEstrito(oQuery,"usuario","")
           cEstabel = fnQueryTextoEstrito(oQuery,"codEstabel","")
           cNatureza = fnQueryTextoEstrito(oQuery,"natureza","").
    IF cUsuario = ? OR TRIM(cUsuario) = "" THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT NO,
            "USUARIO_NAO_INFORMADO", "Usuario da sessao obrigatorio.").
        RETURN.
    END.
    IF cEstabel = ? OR TRIM(cEstabel) = ""
        OR cNatureza = ? OR TRIM(cNatureza) = "" THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT NO,
            "PARAMETRO_INVALIDO", "Informe estabelecimento e natureza de operacao.").
        RETURN.
    END.
    ASSIGN cEstabel = TRIM(cEstabel) cNatureza = TRIM(cNatureza).
    RUN piCarregarEstabelecimentosQuery(INPUT oQuery).
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido
        WHERE ttEmbEstabelPermitido.cod-estabel = cEstabel) THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT NO,
            "SEM_PERMISSAO", "Estabelecimento fora do contexto autorizado.").
        RETURN.
    END.
    cModulo = SEARCH("esp/api/v1/contr-emb-operacao.r").
    IF cModulo = ? THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT NO,
            "OPERACAO_NAO_LOCALIZADA", "Modulo de operacoes nao localizado no PROPATH.").
        RETURN.
    END.
    RUN VALUE(cModulo) PERSISTENT SET hOper.
    IF NOT VALID-HANDLE(hOper) THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT NO,
            "FALHA_CARREGAR_OPERACAO", "Nao foi possivel carregar o modulo de operacoes.").
        RETURN.
    END.
    RUN classificarNaturezaOperacao IN hOper
        (INPUT cNatureza, OUTPUT cFluxo, OUTPUT cRamo,
         OUTPUT lOrigem, OUTPUT lQuantidade, OUTPUT lPreco,
         OUTPUT lSucesso, OUTPUT cErro).
    IF NOT lSucesso THEN DO:
        CASE cErro:
            WHEN "NATUREZA_NAO_ENCONTRADA" THEN
                cMensagem = "Natureza de operacao nao cadastrada.".
            WHEN "NATUREZA_FORA_DOS_RAMOS_SUPORTADOS" THEN
                cMensagem = "Natureza fora dos ramos de saida suportados neste fluxo.".
            WHEN "BANCO_NAO_CONECTADO" THEN
                cMensagem = "Banco de cadastros nao conectado na sessao.".
            OTHERWISE cMensagem = "Nao foi possivel classificar a natureza informada.".
        END CASE.
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT NO, cErro, cMensagem).
        RETURN.
    END.
    ASSIGN aDados = NEW JsonArray() oLinha = NEW JsonObject().
    oLinha:Add("natureza",cNatureza).
    oLinha:Add("codEstabel",cEstabel).
    oLinha:Add("fluxo",cFluxo).
    oLinha:Add("ramoPadrao",cRamo).
    oLinha:Add("exigeOrigem",lOrigem).
    oLinha:Add("editaQuantidade",lQuantidade).
    oLinha:Add("editaPreco",lPreco).
    aDados:Add(oLinha).
    oOutput = NEW JsonObject().
    oOutput:Add("sucesso",TRUE).
    oOutput:Add("codigoErro","").
    oOutput:Add("mensagem","").
    oOutput:Add("total",1).
    oOutput:Add("temMais",FALSE).
    oOutput:Add("proximoCodigo","").
    oOutput:Add("dados",aDados).
    CATCH eNatureza AS Progress.Lang.Error:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT NO,
            "FALHA_CONSULTA", "Nao foi possivel consultar o direcionamento da natureza.").
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hOper) THEN DELETE PROCEDURE hOper NO-ERROR.
        EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    END FINALLY.
END.
END PROCEDURE.

PROCEDURE pi-apoios-familias:
DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
DEFINE VARIABLE oRequest AS JsonAPIRequestParser NO-UNDO.
DEFINE VARIABLE oQuery AS JsonObject NO-UNDO.
DEFINE VARIABLE aDados AS JsonArray NO-UNDO.
DEFINE VARIABLE oLinha AS JsonObject NO-UNDO.
DEFINE VARIABLE hCore AS HANDLE NO-UNDO.
DEFINE VARIABLE lLocalizado AS LOGICAL NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFiltro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cApos AS CHARACTER NO-UNDO.
DEFINE VARIABLE iLimite AS INTEGER NO-UNDO.
DEFINE VARIABLE lSucesso AS LOGICAL NO-UNDO.
DEFINE VARIABLE lMais AS LOGICAL NO-UNDO.
DEFINE VARIABLE cProximo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagem AS CHARACTER NO-UNDO.
DO ON ERROR UNDO, THROW:
    EMPTY TEMP-TABLE ttEmbFamilia.
    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput) oQuery = oRequest:GetQueryParams()
        cUsuario = fnQueryTextoEstrito(oQuery,"usuario","")
        cFiltro = fnQueryTextoEstrito(oQuery,"filtro","")
        cApos = fnQueryTextoEstrito(oQuery,"aposCodigo","")
        iLimite = fnQueryNumeroEstrito(oQuery,"limite",20).
    IF cUsuario = ? OR TRIM(cUsuario) = "" THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT NO,"USUARIO_NAO_INFORMADO","Usuario da sessao obrigatorio.").
        RETURN.
    END.
    RUN piCarregarEstabelecimentosQuery(INPUT oQuery).
    RUN piAbrirCore(OUTPUT hCore,OUTPUT lLocalizado,OUTPUT cErro,OUTPUT cMensagem).
    IF NOT lLocalizado THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT NO,cErro,cMensagem).
        RETURN.
    END.
    RUN consultarFamilias IN hCore(INPUT TABLE ttEmbEstabelPermitido,
        INPUT cFiltro,INPUT cApos,INPUT iLimite,OUTPUT TABLE ttEmbFamilia,
        OUTPUT lMais,OUTPUT cProximo,OUTPUT lSucesso,OUTPUT cErro,OUTPUT cMensagem).
    aDados = NEW JsonArray().
    IF lSucesso THEN DO:
      FOR EACH ttEmbFamilia BY ttEmbFamilia.codigo:
        oLinha = NEW JsonObject().
        oLinha:Add("codigo",ttEmbFamilia.codigo).
        oLinha:Add("descricao",ttEmbFamilia.descricao).
        aDados:Add(oLinha).
      END.
    END.
    oOutput = NEW JsonObject().
    oOutput:Add("sucesso",lSucesso).
    oOutput:Add("codigoErro",cErro).
    oOutput:Add("mensagem",cMensagem).
    oOutput:Add("total",aDados:Length).
    oOutput:Add("temMais",lMais).
    oOutput:Add("proximoCodigo",cProximo).
    oOutput:Add("dados",aDados).
    CATCH eFamilias AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbFamilia.
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT NO,"FALHA_CONSULTA","Nao foi possivel consultar as familias.").
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hCore) THEN DELETE PROCEDURE hCore NO-ERROR.
        EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    END FINALLY.
END.
END PROCEDURE.

PROCEDURE pi-dados-impressao:
DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
DEFINE VARIABLE oRequest AS JsonAPIRequestParser NO-UNDO.
DEFINE VARIABLE oQuery AS JsonObject NO-UNDO.
DEFINE VARIABLE aDados AS JsonArray NO-UNDO.
DEFINE VARIABLE oLinha AS JsonObject NO-UNDO.
DEFINE VARIABLE hRastreio AS HANDLE NO-UNDO.
DEFINE VARIABLE lLocalizado AS LOGICAL NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE iIdEtiqueta AS INTEGER NO-UNDO.
DEFINE VARIABLE lSucesso AS LOGICAL NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagem AS CHARACTER NO-UNDO.
DO ON ERROR UNDO, THROW:
    EMPTY TEMP-TABLE ttEmbEtiqueta.
    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput) oQuery = oRequest:GetQueryParams()
        cUsuario = fnQueryTextoEstrito(oQuery,"usuario","")
        iIdEtiqueta = fnQueryNumeroEstrito(oQuery,"idEtiqueta",0).
    IF cUsuario = ? OR TRIM(cUsuario) = "" THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT YES,"USUARIO_NAO_INFORMADO","Usuario da sessao obrigatorio.").
        RETURN.
    END.
    RUN piCarregarEstabelecimentosQuery(INPUT oQuery).
    RUN piAbrirRastreio(OUTPUT hRastreio,OUTPUT lLocalizado,OUTPUT cErro,OUTPUT cMensagem).
    IF NOT lLocalizado THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT YES,cErro,cMensagem).
        RETURN.
    END.
    RUN obterDadosImpressao IN hRastreio(INPUT TABLE ttEmbEstabelPermitido,INPUT iIdEtiqueta,
        OUTPUT TABLE ttEmbEtiqueta,OUTPUT lSucesso,OUTPUT cErro,OUTPUT cMensagem).
    aDados = NEW JsonArray().
    IF lSucesso THEN DO:
        FOR EACH ttEmbEtiqueta BY ttEmbEtiqueta.id-etiqueta:
            oLinha = NEW JsonObject().
            oLinha:Add("idEtiqueta", STRING(ttEmbEtiqueta.id-etiqueta)).
            oLinha:Add("codEtiqueta", ttEmbEtiqueta.cod-etiqueta).
            oLinha:Add("tipoControle", ttEmbEtiqueta.tipo-controle).
            oLinha:Add("idPreOrigem", IF ttEmbEtiqueta.id-pre-origem = ? THEN ?
                       ELSE STRING(ttEmbEtiqueta.id-pre-origem)).
            oLinha:Add("idEventoGeracao", STRING(ttEmbEtiqueta.id-evento-geracao)).
            oLinha:Add("idItemEvento", IF ttEmbEtiqueta.id-item-evento = ? THEN ?
                       ELSE STRING(ttEmbEtiqueta.id-item-evento)).
            oLinha:Add("seqGeracao", ttEmbEtiqueta.seq-geracao).
            oLinha:Add("item", ttEmbEtiqueta.it-codigo).
            oLinha:Add("codTipo", ttEmbEtiqueta.cod-tipo).
            oLinha:Add("lote", ttEmbEtiqueta.lote).
            oLinha:Add("validadeLote", ttEmbEtiqueta.dt-vali-lote).
            oLinha:Add("unidade", ttEmbEtiqueta.un).
            oLinha:Add("capacidade", ttEmbEtiqueta.capacidade-emb).
            oLinha:Add("quantidadeInicial", ttEmbEtiqueta.qtidade-ini).
            oLinha:Add("quantidadeAtual", ttEmbEtiqueta.qtidade-atu).
            oLinha:Add("codEstabel", ttEmbEtiqueta.cod-estabel).
            oLinha:Add("deposito", ttEmbEtiqueta.cod-depos).
            oLinha:Add("localizacao", ttEmbEtiqueta.cod-localiz).
            oLinha:Add("tipoLocal", ttEmbEtiqueta.tipo-local).
            oLinha:Add("codEmitentePosse", ttEmbEtiqueta.cod-emitente-posse).
            oLinha:Add("origemLocalExterno", ttEmbEtiqueta.origem-local-ext).
            oLinha:Add("codLocalExterno", ttEmbEtiqueta.cod-local-ext).
            oLinha:Add("idBag", IF ttEmbEtiqueta.id-bag = ? THEN ?
                       ELSE STRING(ttEmbEtiqueta.id-bag)).
            oLinha:Add("situacao", ttEmbEtiqueta.situacao).
            oLinha:Add("idUltimoMovimento", IF ttEmbEtiqueta.id-movto-ult = ? THEN ?
                       ELSE STRING(ttEmbEtiqueta.id-movto-ult)).
            oLinha:Add("versao", ttEmbEtiqueta.versao).
            oLinha:Add("dtInclusao", ttEmbEtiqueta.dt-inclusao).
            oLinha:Add("usuarioInclusao", ttEmbEtiqueta.usuario-inclusao).
            oLinha:Add("dtAlteracao", ttEmbEtiqueta.dt-alteracao).
            oLinha:Add("usuarioAlteracao", ttEmbEtiqueta.usuario-alteracao).
            aDados:Add(oLinha).
        END.
    END.
    oOutput = NEW JsonObject().
    oOutput:Add("sucesso",lSucesso).
    oOutput:Add("codigoErro",cErro).
    oOutput:Add("mensagem",cMensagem).
    oOutput:Add("total",aDados:Length).
    oOutput:Add("temMais",FALSE).
    oOutput:Add("proximoId","").
    oOutput:Add("dados",aDados).
    CATCH eImpressao AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbEtiqueta.
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT YES,"FALHA_CONSULTA","Nao foi possivel obter os dados de impressao.").
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hRastreio) THEN DELETE PROCEDURE hRastreio NO-ERROR.
        EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    END FINALLY.
END.
END PROCEDURE.

PROCEDURE pi-apoios-tipos:
DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
DEFINE VARIABLE oRequest AS JsonAPIRequestParser NO-UNDO.
DEFINE VARIABLE oQuery AS JsonObject NO-UNDO.
DEFINE VARIABLE aDados AS JsonArray NO-UNDO.
DEFINE VARIABLE oLinha AS JsonObject NO-UNDO.
DEFINE VARIABLE hCore AS HANDLE NO-UNDO.
DEFINE VARIABLE lLocalizado AS LOGICAL NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFiltro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cApos AS CHARACTER NO-UNDO.
DEFINE VARIABLE cAtivo AS CHARACTER NO-UNDO.
DEFINE VARIABLE lAtivo AS LOGICAL NO-UNDO.
DEFINE VARIABLE iLimite AS INTEGER NO-UNDO.
DEFINE VARIABLE lSucesso AS LOGICAL NO-UNDO.
DEFINE VARIABLE lMais AS LOGICAL NO-UNDO.
DEFINE VARIABLE cProximo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagem AS CHARACTER NO-UNDO.
DO ON ERROR UNDO, THROW:
    EMPTY TEMP-TABLE ttEmbTipo.
    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput) oQuery = oRequest:GetQueryParams()
        cUsuario = fnQueryTextoEstrito(oQuery,"usuario","")
        cFiltro = fnQueryTextoEstrito(oQuery,"filtro","")
        cApos = fnQueryTextoEstrito(oQuery,"aposCodigo","")
        cAtivo = CAPS(fnQueryTextoEstrito(oQuery,"ativo","true"))
        iLimite = fnQueryNumeroEstrito(oQuery,"limite",20).
    IF cUsuario = ? OR TRIM(cUsuario) = "" THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT NO,"USUARIO_NAO_INFORMADO","Usuario da sessao obrigatorio.").
        RETURN.
    END.
    IF cAtivo = ? OR LOOKUP(cAtivo,"TRUE,FALSE,TODOS") = 0 THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT NO,"FILTRO_INVALIDO","Use ativo true, false ou todos.").
        RETURN.
    END.
    lAtivo = IF cAtivo = "TODOS" THEN ? ELSE cAtivo = "TRUE".
    RUN piAbrirCore(OUTPUT hCore,OUTPUT lLocalizado,OUTPUT cErro,OUTPUT cMensagem).
    IF NOT lLocalizado THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT NO,cErro,cMensagem).
        RETURN.
    END.
    /* Permissao global vem do grupo/Dataset e servico protegido, como GET /tipos.
       Usuario declarado sozinho nao homologa essa fronteira. */
    RUN consultarTiposApoio IN hCore(INPUT YES,INPUT cFiltro,INPUT cApos,INPUT lAtivo,INPUT iLimite,
        OUTPUT TABLE ttEmbTipo,OUTPUT lMais,OUTPUT cProximo,OUTPUT lSucesso,OUTPUT cErro,OUTPUT cMensagem).
    aDados = NEW JsonArray().
    IF lSucesso THEN DO:
      FOR EACH ttEmbTipo BY ttEmbTipo.cod-tipo:
        oLinha = NEW JsonObject().
        oLinha:Add("codigo",ttEmbTipo.cod-tipo).
        oLinha:Add("descricao",ttEmbTipo.desc-embalagem).
        oLinha:Add("ativo",ttEmbTipo.ativo).
        oLinha:Add("versao",ttEmbTipo.versao).
        aDados:Add(oLinha).
      END.
    END.
    oOutput = NEW JsonObject().
    oOutput:Add("sucesso",lSucesso).
    oOutput:Add("codigoErro",cErro).
    oOutput:Add("mensagem",cMensagem).
    oOutput:Add("total",aDados:Length).
    oOutput:Add("temMais",lMais).
    oOutput:Add("proximoCodigo",cProximo).
    oOutput:Add("dados",aDados).
    CATCH eTipos AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbTipo.
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT NO,"FALHA_CONSULTA","Nao foi possivel consultar os tipos.").
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hCore) THEN DELETE PROCEDURE hCore NO-ERROR.
    END FINALLY.
END.
END PROCEDURE.

PROCEDURE pi-consultar-bags:
DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
RUN piConsultarBagRest(INPUT oInput,INPUT NO,OUTPUT oOutput).
END PROCEDURE.

PROCEDURE pi-consultar-conteudo-bag:
DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
RUN piConsultarBagRest(INPUT oInput,INPUT YES,OUTPUT oOutput).
END PROCEDURE.

PROCEDURE piConsultarBagRest:
DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER plConteudo AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
DEFINE VARIABLE oRequest AS JsonAPIRequestParser NO-UNDO.
DEFINE VARIABLE oQuery AS JsonObject NO-UNDO.
DEFINE VARIABLE aDados AS JsonArray NO-UNDO.
DEFINE VARIABLE oLinha AS JsonObject NO-UNDO.
DEFINE VARIABLE hCore AS HANDLE NO-UNDO.
DEFINE VARIABLE lLocalizado AS LOGICAL NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstabel AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLacre AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSituacao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cInicio AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFim AS CHARACTER NO-UNDO.
DEFINE VARIABLE dtInicio AS DATE NO-UNDO.
DEFINE VARIABLE dtFim AS DATE NO-UNDO.
DEFINE VARIABLE iIdBag AS INTEGER NO-UNDO.
DEFINE VARIABLE iApos AS INTEGER NO-UNDO.
DEFINE VARIABLE iLimite AS INTEGER NO-UNDO.
DEFINE VARIABLE lSucesso AS LOGICAL NO-UNDO.
DEFINE VARIABLE lMais AS LOGICAL NO-UNDO.
DEFINE VARIABLE iProximo AS INTEGER NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagem AS CHARACTER NO-UNDO.
DO ON ERROR UNDO, THROW:
    EMPTY TEMP-TABLE ttEmbBag.
    EMPTY TEMP-TABLE ttEmbEtiqueta.
    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput) oQuery = oRequest:GetQueryParams()
        cUsuario = fnQueryTextoEstrito(oQuery,"usuario","")
        iIdBag = fnQueryNumeroEstrito(oQuery,"idBag",0)
        iApos = fnQueryNumeroEstrito(oQuery,"aposId",0)
        iLimite = fnQueryNumeroEstrito(oQuery,"limite",20).
    IF cUsuario = ? OR TRIM(cUsuario) = "" THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT YES,"USUARIO_NAO_INFORMADO","Usuario da sessao obrigatorio.").
        RETURN.
    END.
    RUN piCarregarEstabelecimentosQuery(INPUT oQuery).
    RUN piAbrirCore(OUTPUT hCore,OUTPUT lLocalizado,OUTPUT cErro,OUTPUT cMensagem).
    IF NOT lLocalizado THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT YES,cErro,cMensagem).
        RETURN.
    END.
    IF plConteudo THEN
        RUN consultarConteudoBag IN hCore(INPUT TABLE ttEmbEstabelPermitido,
            INPUT iIdBag,INPUT iApos,INPUT iLimite,OUTPUT TABLE ttEmbEtiqueta,
            OUTPUT lMais,OUTPUT iProximo,OUTPUT lSucesso,OUTPUT cErro,OUTPUT cMensagem).
    ELSE DO:
        ASSIGN cEstabel = fnQueryTextoEstrito(oQuery,"codEstabel","")
            cLacre = fnQueryTextoEstrito(oQuery,"filtroLacre","")
            cTipo = fnQueryTextoEstrito(oQuery,"codTipo","")
            cSituacao = fnQueryTextoEstrito(oQuery,"situacao","")
            cInicio = fnQueryTextoEstrito(oQuery,"inicio","")
            cFim = fnQueryTextoEstrito(oQuery,"fim","")
            dtInicio = fnDataISO(cInicio) dtFim = fnDataISO(cFim).
        IF cInicio = ? OR cFim = ? OR (cInicio <> "" AND dtInicio = ?)
           OR (cFim <> "" AND dtFim = ?) THEN DO:
            RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT YES,"FILTRO_INVALIDO","Use inicio/fim validos no formato YYYY-MM-DD.").
            RETURN.
        END.
        RUN consultarBags IN hCore(INPUT TABLE ttEmbEstabelPermitido,
            INPUT cEstabel,INPUT iIdBag,INPUT cLacre,INPUT cTipo,INPUT cSituacao,
            INPUT dtInicio,INPUT dtFim,INPUT iApos,INPUT iLimite,OUTPUT TABLE ttEmbBag,
            OUTPUT lMais,OUTPUT iProximo,OUTPUT lSucesso,OUTPUT cErro,OUTPUT cMensagem).
    END.
    aDados = NEW JsonArray().
    IF lSucesso THEN DO:
        IF plConteudo THEN DO:
            /* Projecao identica a consulta de etiquetas; sem payload de evento. */
            FOR EACH ttEmbEtiqueta BY ttEmbEtiqueta.id-etiqueta:
                oLinha = NEW JsonObject().
                oLinha:Add("idEtiqueta", STRING(ttEmbEtiqueta.id-etiqueta)).
                oLinha:Add("codEtiqueta", ttEmbEtiqueta.cod-etiqueta).
                oLinha:Add("tipoControle", ttEmbEtiqueta.tipo-controle).
                oLinha:Add("idPreOrigem", IF ttEmbEtiqueta.id-pre-origem = ? THEN ?
                           ELSE STRING(ttEmbEtiqueta.id-pre-origem)).
                oLinha:Add("idEventoGeracao", STRING(ttEmbEtiqueta.id-evento-geracao)).
                oLinha:Add("idItemEvento", IF ttEmbEtiqueta.id-item-evento = ? THEN ?
                           ELSE STRING(ttEmbEtiqueta.id-item-evento)).
                oLinha:Add("seqGeracao", ttEmbEtiqueta.seq-geracao).
                oLinha:Add("item", ttEmbEtiqueta.it-codigo).
                oLinha:Add("codTipo", ttEmbEtiqueta.cod-tipo).
                oLinha:Add("lote", ttEmbEtiqueta.lote).
                oLinha:Add("validadeLote", ttEmbEtiqueta.dt-vali-lote).
                oLinha:Add("unidade", ttEmbEtiqueta.un).
                oLinha:Add("capacidade", ttEmbEtiqueta.capacidade-emb).
                oLinha:Add("quantidadeInicial", ttEmbEtiqueta.qtidade-ini).
                oLinha:Add("quantidadeAtual", ttEmbEtiqueta.qtidade-atu).
                oLinha:Add("codEstabel", ttEmbEtiqueta.cod-estabel).
                oLinha:Add("deposito", ttEmbEtiqueta.cod-depos).
                oLinha:Add("localizacao", ttEmbEtiqueta.cod-localiz).
                oLinha:Add("tipoLocal", ttEmbEtiqueta.tipo-local).
                oLinha:Add("codEmitentePosse", ttEmbEtiqueta.cod-emitente-posse).
                oLinha:Add("origemLocalExterno", ttEmbEtiqueta.origem-local-ext).
                oLinha:Add("codLocalExterno", ttEmbEtiqueta.cod-local-ext).
                oLinha:Add("idBag", IF ttEmbEtiqueta.id-bag = ? THEN ?
                           ELSE STRING(ttEmbEtiqueta.id-bag)).
                oLinha:Add("situacao", ttEmbEtiqueta.situacao).
                oLinha:Add("idUltimoMovimento", IF ttEmbEtiqueta.id-movto-ult = ? THEN ?
                           ELSE STRING(ttEmbEtiqueta.id-movto-ult)).
                oLinha:Add("versao", ttEmbEtiqueta.versao).
                oLinha:Add("dtInclusao", ttEmbEtiqueta.dt-inclusao).
                oLinha:Add("usuarioInclusao", ttEmbEtiqueta.usuario-inclusao).
                oLinha:Add("dtAlteracao", ttEmbEtiqueta.dt-alteracao).
                oLinha:Add("usuarioAlteracao", ttEmbEtiqueta.usuario-alteracao).
                aDados:Add(oLinha).
            END.
        END.
        ELSE DO:
            FOR EACH ttEmbBag BY ttEmbBag.id-bag:
                oLinha = NEW JsonObject().
                oLinha:Add("idBag",STRING(ttEmbBag.id-bag)).
                oLinha:Add("codTipo",ttEmbBag.cod-tipo).
                oLinha:Add("codEstabel",ttEmbBag.cod-estabel).
                oLinha:Add("deposito",ttEmbBag.cod-depos).
                oLinha:Add("nroLacre",ttEmbBag.nro-lacre).
                oLinha:Add("situacao",ttEmbBag.situacao).
                oLinha:Add("dtLacre",ttEmbBag.dt-lacre).
                oLinha:Add("dtEnvio",ttEmbBag.dt-envio).
                oLinha:Add("dtDevolucao",ttEmbBag.dt-devolucao).
                oLinha:Add("tipoDestino",ttEmbBag.tipo-destino).
                oLinha:Add("codEstabelDestino",ttEmbBag.cod-estabel-dest).
                oLinha:Add("codEmitenteDestino",ttEmbBag.cod-emitente-dest).
                oLinha:Add("origemLocalDestino",ttEmbBag.origem-local-dest).
                oLinha:Add("codLocalDestino",ttEmbBag.cod-local-dest).
                oLinha:Add("motorista",ttEmbBag.motorista).
                oLinha:Add("destino",IF ttEmbBag.tipo-destino = "LOCAL" AND ttEmbBag.origem-local-dest = "MANUAL"
                    THEN ttEmbBag.cod-local-dest ELSE ?).
                oLinha:Add("idBagAnterior",IF ttEmbBag.id-bag-anterior = ? OR ttEmbBag.id-bag-anterior <= 0 THEN "" ELSE STRING(ttEmbBag.id-bag-anterior)).
                oLinha:Add("dtInclusao",ttEmbBag.dt-inclusao).
                oLinha:Add("dtAlteracao",ttEmbBag.dt-alteracao).
                oLinha:Add("versao",ttEmbBag.versao).
                aDados:Add(oLinha).
            END.
        END.
    END.
    oOutput = NEW JsonObject().
    oOutput:Add("sucesso",lSucesso).
    oOutput:Add("codigoErro",cErro).
    oOutput:Add("mensagem",cMensagem).
    oOutput:Add("total",aDados:Length).
    oOutput:Add("temMais",lMais).
    oOutput:Add("proximoId",IF iProximo > 0 THEN STRING(iProximo) ELSE "").
    oOutput:Add("dados",aDados).
    CATCH eBag AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbBag.
        EMPTY TEMP-TABLE ttEmbEtiqueta.
        RUN piRespostaErroConsulta(OUTPUT oOutput,INPUT YES,"FALHA_CONSULTA","Nao foi possivel consultar a Bag.").
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hCore) THEN DELETE PROCEDURE hCore NO-ERROR.
        EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    END FINALLY.
END.
END PROCEDURE.

PROCEDURE piRespostaErroConsulta:
DEFINE OUTPUT PARAMETER poOutput AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER plCursorId AS LOGICAL NO-UNDO.
DEFINE INPUT PARAMETER pcCodigo AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
RUN piRespostaErro(OUTPUT poOutput,INPUT pcCodigo,INPUT pcMensagem).
poOutput:Add("total",0).
poOutput:Add("temMais",FALSE).
IF plCursorId THEN poOutput:Add("proximoId","").
ELSE poOutput:Add("proximoCodigo","").
poOutput:Add("dados",NEW JsonArray()).
END PROCEDURE.

PROCEDURE pi-apoios-estabelecimentos:
DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
RUN piConsultarApoio(INPUT oInput, INPUT NO, OUTPUT oOutput).
END PROCEDURE.

PROCEDURE pi-apoios-itens:
DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
RUN piConsultarApoio(INPUT oInput, INPUT YES, OUTPUT oOutput).
END PROCEDURE.

PROCEDURE piConsultarApoio:
DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER plItens AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
DEFINE VARIABLE oRequest AS JsonAPIRequestParser NO-UNDO.
DEFINE VARIABLE oQuery AS JsonObject NO-UNDO.
DEFINE VARIABLE aDados AS JsonArray NO-UNDO.
DEFINE VARIABLE oLinha AS JsonObject NO-UNDO.
DEFINE VARIABLE hCore AS HANDLE NO-UNDO.
DEFINE VARIABLE lLocalizado AS LOGICAL NO-UNDO.
DEFINE VARIABLE lSucesso AS LOGICAL NO-UNDO.
DEFINE VARIABLE lTemMais AS LOGICAL NO-UNDO.
DEFINE VARIABLE cProximo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFiltro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cApos AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstabel AS CHARACTER NO-UNDO.
DEFINE VARIABLE iLimite AS INTEGER NO-UNDO.
/* Qualquer excecao descarta integralmente as temp-tables desta chamada. */
DEFINE VARIABLE cControleEstoque AS CHARACTER NO-UNDO.
DEFINE VARIABLE iControleEstoque AS INTEGER NO-UNDO.
DO ON ERROR UNDO, THROW:
    EMPTY TEMP-TABLE ttEmbEstabelecimento.
    EMPTY TEMP-TABLE ttEmbItem.
    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput)
           oQuery = oRequest:GetQueryParams()
           cFiltro = fnQueryChar(oQuery, "filtro", "")
           cApos = fnQueryChar(oQuery, "aposCodigo", "")
           cEstabel = fnQueryChar(oQuery, "codEstabel", "")
           iLimite = fnQueryInteger(oQuery, "limite", 20).
    IF TRIM(fnQueryChar(oQuery, "usuario", "")) = "" THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, "USUARIO_NAO_INFORMADO", "Usuario da sessao obrigatorio.").
        RETURN.
    END.
    RUN piCarregarEstabelecimentosQuery(INPUT oQuery).
    IF plItens AND oQuery:Has("tipoControleEstoque") THEN DO:
        cControleEstoque = fnQueryTextoEstrito(oQuery, "tipoControleEstoque", ?).
        IF cControleEstoque = ? OR cControleEstoque <> "3" THEN DO:
            RUN piRespostaErro(OUTPUT oOutput, "FILTRO_INVALIDO", "Informe tipoControleEstoque=3 ou omita o filtro.").
            RETURN.
        END.
        iControleEstoque = 3.
    END.
    RUN piAbrirCore(OUTPUT hCore, OUTPUT lLocalizado, OUTPUT cErro, OUTPUT cMensagem).
    IF NOT lLocalizado THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, cErro, cMensagem).
        RETURN.
    END.
    IF plItens THEN
        RUN consultarItensPorControle IN hCore(INPUT TABLE ttEmbEstabelPermitido,
            INPUT cEstabel, INPUT cFiltro, INPUT cApos, INPUT iLimite, INPUT iControleEstoque,
            OUTPUT TABLE ttEmbItem, OUTPUT lTemMais, OUTPUT cProximo,
            OUTPUT lSucesso, OUTPUT cErro, OUTPUT cMensagem).
    ELSE
        RUN consultarEstabelecimentos IN hCore(INPUT TABLE ttEmbEstabelPermitido,
            INPUT cFiltro, INPUT cApos, INPUT iLimite,
            OUTPUT TABLE ttEmbEstabelecimento, OUTPUT lTemMais, OUTPUT cProximo,
            OUTPUT lSucesso, OUTPUT cErro, OUTPUT cMensagem).
    DELETE PROCEDURE hCore NO-ERROR.
    aDados = NEW JsonArray().
    IF lSucesso THEN DO:
        IF plItens THEN DO:
            FOR EACH ttEmbItem BY ttEmbItem.codigo:
                oLinha = NEW JsonObject().
                oLinha:Add("codigo", ttEmbItem.codigo).
                oLinha:Add("descricao", ttEmbItem.descricao).
                oLinha:Add("un", ttEmbItem.un).
                oLinha:Add("tipoControleEstoque", ttEmbItem.tipo-controle-estoque).
                aDados:Add(oLinha).
            END.
        END.
        ELSE DO:
            FOR EACH ttEmbEstabelecimento BY ttEmbEstabelecimento.codigo:
                oLinha = NEW JsonObject().
                oLinha:Add("codigo", ttEmbEstabelecimento.codigo).
                oLinha:Add("descricao", ttEmbEstabelecimento.descricao).
                aDados:Add(oLinha).
            END.
        END.
    END.
    oOutput = NEW JsonObject().
    oOutput:Add("sucesso", lSucesso).
    oOutput:Add("codigoErro", cErro).
    oOutput:Add("mensagem", cMensagem).
    oOutput:Add("total", aDados:Length).
    oOutput:Add("temMais", lTemMais).
    oOutput:Add("proximoCodigo", cProximo).
    oOutput:Add("dados", aDados).
    CATCH oFalha AS Progress.Lang.Error:
        IF VALID-HANDLE(hCore) THEN DELETE PROCEDURE hCore NO-ERROR.
        EMPTY TEMP-TABLE ttEmbEstabelecimento.
        EMPTY TEMP-TABLE ttEmbItem.
        RUN piRespostaErro(OUTPUT oOutput, "FALHA_CONSULTA_APOIO", "Nao foi possivel consultar as opcoes.").
    END CATCH.
END.
END PROCEDURE.

PROCEDURE piAbrirCore:
    DEFINE OUTPUT PARAMETER phCore AS HANDLE NO-UNDO.
    DEFINE OUTPUT PARAMETER plLocalizado AS LOGICAL NO-UNDO.
    DEFINE OUTPUT PARAMETER pcCodigoErro AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcMensagemErro AS CHARACTER NO-UNDO.

    DEFINE VARIABLE cCore AS CHARACTER NO-UNDO.

    ASSIGN phCore = ?
           plLocalizado = NO
           pcCodigoErro = ""
           pcMensagemErro = "".

    IF NOT CONNECTED("mgesp") THEN DO:
        ASSIGN pcCodigoErro = "BANCO_MGESP_NAO_CONECTADO"
               pcMensagemErro = "O banco mgesp nao esta conectado na sessao do PASOE.".
        RETURN.
    END.

    /* No PASOE, EMS2 e uma raiz do PROPATH. O nucleo publicado em
       EMS2/esp/api/v1 possui um unico caminho logico de runtime. */
    cCore = SEARCH("esp/api/v1/contr-emb.r").

    IF cCore = ? THEN DO:
        ASSIGN pcCodigoErro = "NUCLEO_NAO_LOCALIZADO"
               pcMensagemErro = "O modulo central contr-emb.r nao foi localizado no PROPATH do PASOE.".
        RETURN.
    END.

    DO ON ERROR UNDO, THROW:
        RUN VALUE(cCore) PERSISTENT SET phCore.
        plLocalizado = VALID-HANDLE(phCore).

        IF NOT plLocalizado THEN
            ASSIGN pcCodigoErro = "FALHA_CARREGAR_NUCLEO"
                   pcMensagemErro = "O modulo central contr-emb.r nao pode ser iniciado.".

        CATCH oFalha AS Progress.Lang.Error:
            ASSIGN phCore = ?
                   plLocalizado = NO
                   pcCodigoErro = "FALHA_CARREGAR_NUCLEO"
                   pcMensagemErro = "O modulo central contr-emb.r foi localizado, mas nao pode ser carregado.".
            LOG-MANAGER:WRITE-MESSAGE(
                "CONTROLE_EMBALAGENS|ABRIR_NUCLEO|" +
                (IF oFalha:NumMessages > 0 THEN oFalha:GetMessage(1)
                 ELSE "Falha sem mensagem ABL.")).
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE piAbrirRastreio:
    DEFINE OUTPUT PARAMETER phRastreio AS HANDLE NO-UNDO.
    DEFINE OUTPUT PARAMETER plLocalizado AS LOGICAL NO-UNDO.
    DEFINE OUTPUT PARAMETER pcCodigoErro AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcMensagemErro AS CHARACTER NO-UNDO.

    DEFINE VARIABLE cRastreio AS CHARACTER NO-UNDO.

    ASSIGN phRastreio = ?
           plLocalizado = NO
           pcCodigoErro = ""
           pcMensagemErro = "".

    IF NOT CONNECTED("mgesp") THEN DO:
        ASSIGN pcCodigoErro = "BANCO_MGESP_NAO_CONECTADO"
               pcMensagemErro = "O banco mgesp nao esta conectado na sessao do PASOE.".
        RETURN.
    END.

    cRastreio = SEARCH("esp/api/v1/contr-emb-rastreio.r").
    IF cRastreio = ? THEN DO:
        ASSIGN pcCodigoErro = "RASTREIO_NAO_LOCALIZADO"
               pcMensagemErro = "O modulo contr-emb-rastreio.r nao foi localizado no PROPATH do PASOE.".
        RETURN.
    END.

    DO ON ERROR UNDO, THROW:
        RUN VALUE(cRastreio) PERSISTENT SET phRastreio.
        plLocalizado = VALID-HANDLE(phRastreio).
        IF NOT plLocalizado THEN
            ASSIGN pcCodigoErro = "FALHA_CARREGAR_RASTREIO"
                   pcMensagemErro = "O modulo contr-emb-rastreio.r nao pode ser iniciado.".

        CATCH oFalha AS Progress.Lang.Error:
            ASSIGN phRastreio = ?
                   plLocalizado = NO
                   pcCodigoErro = "FALHA_CARREGAR_RASTREIO"
                   pcMensagemErro = "O modulo contr-emb-rastreio.r foi localizado, mas nao pode ser carregado.".
            LOG-MANAGER:WRITE-MESSAGE(
                "CONTROLE_EMBALAGENS|ABRIR_RASTREIO|" +
                (IF oFalha:NumMessages > 0 THEN oFalha:GetMessage(1)
                 ELSE "Falha sem mensagem ABL.")).
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE pi-consultar-tipos:
    DEFINE INPUT  PARAMETER oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE oRequest       AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE oQuery         AS JsonObject NO-UNDO.
    DEFINE VARIABLE aDados         AS JsonArray NO-UNDO.
    DEFINE VARIABLE oLinha         AS JsonObject NO-UNDO.
    DEFINE VARIABLE hCore          AS HANDLE NO-UNDO.
    DEFINE VARIABLE lCoreLocalizado AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cUsuario       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCodigoDe      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCodigoAte     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDescricao     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cAposCodigo    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lAtivo         AS LOGICAL NO-UNDO.
    DEFINE VARIABLE iLimite        AS INTEGER NO-UNDO.
    DEFINE VARIABLE lTemMais       AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cProximo       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lSucesso       AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cErro          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cMensagem      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cEtapa         AS CHARACTER NO-UNDO.

    ASSIGN oOutput  = NEW JsonObject()
           aDados   = NEW JsonArray()
           oRequest = NEW JsonAPIRequestParser(oInput)
           oQuery   = oRequest:GetQueryParams()
           cUsuario = fnQueryChar(oQuery, "usuario", "")
           cCodigoDe = fnQueryChar(oQuery, "codigoDe", "")
           cCodigoAte = fnQueryChar(oQuery, "codigoAte", "")
           cDescricao = fnQueryChar(oQuery, "descricao", "")
           cAposCodigo = fnQueryChar(oQuery, "aposCodigo", "")
           lAtivo = fnQueryLogical(oQuery, "ativo")
           iLimite = fnQueryInteger(oQuery, "limite", 20).

    IF cUsuario = "" THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, "USUARIO_NAO_INFORMADO",
                           "Nao foi possivel identificar o usuario da sessao Fluig.").
        RETURN.
    END.

    DO ON ERROR UNDO, THROW:
        cEtapa = "ABRIR_NUCLEO".
        RUN piAbrirCore(OUTPUT hCore, OUTPUT lCoreLocalizado,
                        OUTPUT cErro, OUTPUT cMensagem).
        IF NOT lCoreLocalizado THEN DO:
            RUN piRespostaErro(OUTPUT oOutput, cErro, cMensagem).
            RETURN.
        END.
        cEtapa = "EXECUTAR_CONSULTA".
        RUN consultarTipos IN hCore(
            INPUT YES, INPUT cCodigoDe, INPUT cCodigoAte, INPUT cDescricao,
            INPUT cAposCodigo, INPUT lAtivo, INPUT iLimite,
            OUTPUT TABLE ttEmbTipo, OUTPUT lTemMais, OUTPUT cProximo,
            OUTPUT lSucesso, OUTPUT cErro, OUTPUT cMensagem).
        DELETE PROCEDURE hCore NO-ERROR.

        cEtapa = "MONTAR_RESPOSTA".
        FOR EACH ttEmbTipo BY ttEmbTipo.cod-tipo:
            oLinha = NEW JsonObject().
            oLinha:Add("codTipo", ttEmbTipo.cod-tipo).
            oLinha:Add("descricao", ttEmbTipo.desc-embalagem).
            oLinha:Add("ativo", ttEmbTipo.ativo).
            oLinha:Add("versao", ttEmbTipo.versao).
            oLinha:Add("dtInclusao", ttEmbTipo.dt-inclusao).
            oLinha:Add("usuarioInclusao", ttEmbTipo.usuario-inclusao).
            oLinha:Add("dtAlteracao", ttEmbTipo.dt-alteracao).
            oLinha:Add("usuarioAlteracao", ttEmbTipo.usuario-alteracao).
            aDados:Add(oLinha).
        END.

        oOutput:Add("sucesso", lSucesso).
        oOutput:Add("codigoErro", cErro).
        oOutput:Add("mensagem", cMensagem).
        oOutput:Add("total", aDados:Length).
        oOutput:Add("temMais", lTemMais).
        oOutput:Add("proximoCodigo", cProximo).
        oOutput:Add("dados", aDados).

        CATCH oFalha AS Progress.Lang.Error:
            IF VALID-HANDLE(hCore) THEN DELETE PROCEDURE hCore NO-ERROR.
            LOG-MANAGER:WRITE-MESSAGE(
                "CONTROLE_EMBALAGENS|CONSULTAR_TIPOS|" + cEtapa + "|" +
                (IF oFalha:NumMessages > 0 THEN oFalha:GetMessage(1)
                 ELSE "Falha sem mensagem ABL.")).
            IF cEtapa = "EXECUTAR_CONSULTA" THEN
                RUN piRespostaErro(OUTPUT oOutput, "FALHA_EXECUTAR_CONSULTA_TIPOS",
                                   "O nucleo foi carregado, mas a consulta de tipos falhou.").
            ELSE IF cEtapa = "MONTAR_RESPOSTA" THEN
                RUN piRespostaErro(OUTPUT oOutput, "FALHA_MONTAR_RESPOSTA_TIPOS",
                                   "A consulta foi executada, mas a resposta JSON nao pode ser montada.").
            ELSE
                RUN piRespostaErro(OUTPUT oOutput, "FALHA_INTERNA",
                                   "Nao foi possivel concluir a consulta de tipos.").
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE pi-consultar-etiquetas:
    DEFINE INPUT  PARAMETER oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE oRequest        AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE oQuery          AS JsonObject NO-UNDO.
    DEFINE VARIABLE aDados          AS JsonArray NO-UNDO.
    DEFINE VARIABLE oLinha          AS JsonObject NO-UNDO.
    DEFINE VARIABLE hRastreio       AS HANDLE NO-UNDO.
    DEFINE VARIABLE lLocalizado     AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cUsuario        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCodEstabel     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCodEtiqueta    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItem           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cLote           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCodTipo        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cTipoControle   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cTipoLocal      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSituacao       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iIdBag          AS INTEGER NO-UNDO.
    DEFINE VARIABLE iAposId         AS INTEGER NO-UNDO.
    DEFINE VARIABLE iLimite         AS INTEGER NO-UNDO.
    DEFINE VARIABLE lTemMais        AS LOGICAL NO-UNDO.
    DEFINE VARIABLE iProximoId      AS INTEGER NO-UNDO.
    DEFINE VARIABLE lSucesso        AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cErro           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cMensagem       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cEtapa          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE oManFiltros AS JsonObject NO-UNDO.
    DEFINE VARIABLE lManConsulta AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cManCampos AS CHARACTER NO-UNDO INITIAL
        "estabelDe,estabelAte,itemDe,itemAte,depositoDe,depositoAte,etiquetaDe,etiquetaAte,loteDe,loteAte,validadeDe,validadeAte,familiaDe,familiaAte,notaDe,notaAte,modoNotas,documento".
    DEFINE VARIABLE iManCampo AS INTEGER NO-UNDO.

    ASSIGN oOutput = NEW JsonObject()
           aDados = NEW JsonArray()
           oRequest = NEW JsonAPIRequestParser(oInput)
           oQuery = oRequest:GetQueryParams()
           cUsuario = fnQueryChar(oQuery, "usuario", "")
           cCodEstabel = fnQueryChar(oQuery, "codEstabel", "")
           cCodEtiqueta = fnQueryChar(oQuery, "codEtiqueta", "")
           cItem = fnQueryChar(oQuery, "item", "")
           cLote = fnQueryChar(oQuery, "lote", "")
           cCodTipo = fnQueryChar(oQuery, "codTipo", "")
           cTipoControle = fnQueryChar(oQuery, "tipoControle", "")
           cTipoLocal = fnQueryChar(oQuery, "tipoLocal", "")
           cSituacao = fnQueryChar(oQuery, "situacao", "")
           iIdBag = fnQueryInteger(oQuery, "idBag", 0)
           iAposId = fnQueryInteger(oQuery, "aposId", 0)
           iLimite = fnQueryInteger(oQuery, "limite", 20).

    IF cUsuario = "" THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, "USUARIO_NAO_INFORMADO",
                           "Nao foi possivel identificar o usuario da sessao Fluig.").
        RETURN.
    END.

    RUN piCarregarEstabelecimentosQuery(INPUT oQuery).
    DO ON ERROR UNDO, THROW:
        cEtapa = "ABRIR_RASTREIO".
        DO iManCampo = 1 TO NUM-ENTRIES(cManCampos):
            IF oQuery:Has(ENTRY(iManCampo,cManCampos)) THEN lManConsulta = YES.
        END.
        IF lManConsulta THEN DO:
            RUN piFiltrosManutencao(oQuery,OUTPUT oManFiltros).
            RUN piAbrirManutencao(OUTPUT hRastreio).
            lLocalizado = VALID-HANDLE(hRastreio).
        END.
        ELSE RUN piAbrirRastreio(OUTPUT hRastreio, OUTPUT lLocalizado,
                            OUTPUT cErro, OUTPUT cMensagem).
        IF NOT lLocalizado THEN DO:
            RUN piRespostaErro(OUTPUT oOutput, cErro, cMensagem).
            RETURN.
        END.

        cEtapa = "EXECUTAR_CONSULTA".
        IF lManConsulta THEN
            RUN consultarEtiquetasManutencao IN hRastreio(
                INPUT TABLE ttEmbEstabelPermitido, INPUT oManFiltros,
                OUTPUT TABLE ttEmbEtiqueta, OUTPUT lTemMais, OUTPUT iProximoId,
                OUTPUT lSucesso, OUTPUT cErro, OUTPUT cMensagem).
        ELSE RUN consultarEtiquetas IN hRastreio(
            INPUT TABLE ttEmbEstabelPermitido,
            INPUT cCodEstabel, INPUT cCodEtiqueta, INPUT cItem, INPUT cLote,
            INPUT cCodTipo, INPUT cTipoControle, INPUT cTipoLocal,
            INPUT cSituacao, INPUT iIdBag, INPUT iAposId, INPUT iLimite,
            OUTPUT TABLE ttEmbEtiqueta, OUTPUT lTemMais, OUTPUT iProximoId,
            OUTPUT lSucesso, OUTPUT cErro, OUTPUT cMensagem).
        DELETE PROCEDURE hRastreio NO-ERROR.

        cEtapa = "MONTAR_RESPOSTA".
        FOR EACH ttEmbEtiqueta BY ttEmbEtiqueta.id-etiqueta:
            oLinha = NEW JsonObject().
            oLinha:Add("idEtiqueta", STRING(ttEmbEtiqueta.id-etiqueta)).
            oLinha:Add("codEtiqueta", ttEmbEtiqueta.cod-etiqueta).
            oLinha:Add("tipoControle", ttEmbEtiqueta.tipo-controle).
            oLinha:Add("idPreOrigem", IF ttEmbEtiqueta.id-pre-origem = ? THEN ?
                       ELSE STRING(ttEmbEtiqueta.id-pre-origem)).
            oLinha:Add("idEventoGeracao", STRING(ttEmbEtiqueta.id-evento-geracao)).
            oLinha:Add("idItemEvento", IF ttEmbEtiqueta.id-item-evento = ? THEN ?
                       ELSE STRING(ttEmbEtiqueta.id-item-evento)).
            oLinha:Add("seqGeracao", ttEmbEtiqueta.seq-geracao).
            oLinha:Add("item", ttEmbEtiqueta.it-codigo).
            oLinha:Add("codTipo", ttEmbEtiqueta.cod-tipo).
            oLinha:Add("lote", ttEmbEtiqueta.lote).
            oLinha:Add("validadeLote", ttEmbEtiqueta.dt-vali-lote).
            oLinha:Add("unidade", ttEmbEtiqueta.un).
            oLinha:Add("capacidade", ttEmbEtiqueta.capacidade-emb).
            oLinha:Add("quantidadeInicial", ttEmbEtiqueta.qtidade-ini).
            oLinha:Add("quantidadeAtual", ttEmbEtiqueta.qtidade-atu).
            oLinha:Add("codEstabel", ttEmbEtiqueta.cod-estabel).
            oLinha:Add("deposito", ttEmbEtiqueta.cod-depos).
            oLinha:Add("localizacao", ttEmbEtiqueta.cod-localiz).
            oLinha:Add("tipoLocal", ttEmbEtiqueta.tipo-local).
            oLinha:Add("codEmitentePosse", ttEmbEtiqueta.cod-emitente-posse).
            oLinha:Add("origemLocalExterno", ttEmbEtiqueta.origem-local-ext).
            oLinha:Add("codLocalExterno", ttEmbEtiqueta.cod-local-ext).
            oLinha:Add("idBag", IF ttEmbEtiqueta.id-bag = ? THEN ?
                       ELSE STRING(ttEmbEtiqueta.id-bag)).
            oLinha:Add("situacao", ttEmbEtiqueta.situacao).
            oLinha:Add("situacaoApresentada",fEmResumo(ttEmbEtiqueta.id-etiqueta)).
            oLinha:Add("descricaoSituacao",fEmDescricao(fEmResumo(ttEmbEtiqueta.id-etiqueta))).
            oLinha:Add("impressaoConfirmada",fEmConfirmada(ttEmbEtiqueta.id-etiqueta,"CONFIRMACAO_IMPRESSAO","")).
            oLinha:Add("recebimentoFisicoConfirmado",ttEmbEtiqueta.tipo-local = "ESTAB" AND
                fEmConfirmada(ttEmbEtiqueta.id-etiqueta,"RECEBIMENTO_FISICO",fEmContexto(ttEmbEtiqueta.id-etiqueta))).
            oLinha:Add("idUltimoMovimento", IF ttEmbEtiqueta.id-movto-ult = ? THEN ?
                       ELSE STRING(ttEmbEtiqueta.id-movto-ult)).
            oLinha:Add("versao", ttEmbEtiqueta.versao).
            oLinha:Add("dtInclusao", ttEmbEtiqueta.dt-inclusao).
            oLinha:Add("usuarioInclusao", ttEmbEtiqueta.usuario-inclusao).
            oLinha:Add("dtAlteracao", ttEmbEtiqueta.dt-alteracao).
            oLinha:Add("usuarioAlteracao", ttEmbEtiqueta.usuario-alteracao).
            aDados:Add(oLinha).
        END.

        oOutput:Add("sucesso", lSucesso).
        oOutput:Add("codigoErro", cErro).
        oOutput:Add("mensagem", cMensagem).
        oOutput:Add("total", aDados:Length).
        oOutput:Add("temMais", lTemMais).
        oOutput:Add("proximoId", STRING(iProximoId)).
        oOutput:Add("dados", aDados).

        CATCH oFalha AS Progress.Lang.Error:
            IF VALID-HANDLE(hRastreio) THEN DELETE PROCEDURE hRastreio NO-ERROR.
            LOG-MANAGER:WRITE-MESSAGE(
                "CONTROLE_EMBALAGENS|CONSULTAR_ETIQUETAS|" + cEtapa + "|" +
                (IF oFalha:NumMessages > 0 THEN oFalha:GetMessage(1)
                 ELSE "Falha sem mensagem ABL.")).
            IF lManConsulta AND oFalha:NumMessages > 0 AND
                LOOKUP(oFalha:GetMessage(1),"FILTRO_INVALIDO,RECEBIMENTOS_NAO_LOCALIZADO") > 0 THEN
                RUN piRespostaErro(OUTPUT oOutput,oFalha:GetMessage(1),"Confira filtros e modulo de recebimentos publicado.").
            ELSE IF cEtapa = "EXECUTAR_CONSULTA" THEN
                RUN piRespostaErro(OUTPUT oOutput, "FALHA_EXECUTAR_CONSULTA_ETIQUETAS",
                                   "O modulo foi carregado, mas a consulta de etiquetas falhou.").
            ELSE IF cEtapa = "MONTAR_RESPOSTA" THEN
                RUN piRespostaErro(OUTPUT oOutput, "FALHA_MONTAR_RESPOSTA_ETIQUETAS",
                                   "A consulta foi executada, mas a resposta JSON nao pode ser montada.").
            ELSE
                RUN piRespostaErro(OUTPUT oOutput, "FALHA_INTERNA",
                                   "Nao foi possivel concluir a consulta de etiquetas.").
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE pi-consultar-geracao:
DEFINE INPUT  PARAMETER oInput  AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
DEFINE VARIABLE oRequest AS JsonAPIRequestParser NO-UNDO.
DEFINE VARIABLE oQuery AS JsonObject NO-UNDO.
DEFINE VARIABLE oGeracao AS JsonObject NO-UNDO.
DEFINE VARIABLE oLinha AS JsonObject NO-UNDO.
DEFINE VARIABLE aItens AS JsonArray NO-UNDO.
DEFINE VARIABLE aEtiquetas AS JsonArray NO-UNDO.
DEFINE VARIABLE hRastreio AS HANDLE NO-UNDO.
DEFINE VARIABLE lLocalizado AS LOGICAL NO-UNDO.
DEFINE VARIABLE lSucesso AS LOGICAL NO-UNDO.
DEFINE VARIABLE lTemMais AS LOGICAL NO-UNDO.
DEFINE VARIABLE iIdEvento AS INTEGER NO-UNDO.
DEFINE VARIABLE iAposId AS INTEGER NO-UNDO.
DEFINE VARIABLE iLimite AS INTEGER NO-UNDO.
DEFINE VARIABLE iProximoId AS INTEGER NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEtapa AS CHARACTER NO-UNDO.

DO ON ERROR UNDO, THROW:
    EMPTY TEMP-TABLE ttEmbGeracao.
    EMPTY TEMP-TABLE ttEmbGeracaoItem.
    EMPTY TEMP-TABLE ttEmbEtiquetaGerada.
    ASSIGN oRequest = NEW JsonAPIRequestParser(oInput)
           oQuery = oRequest:GetQueryParams()
           cUsuario = fnQueryTextoEstrito(oQuery, "usuario", "")
           iIdEvento = fnQueryNumeroEstrito(oQuery, "idEvento", 0)
           iAposId = fnQueryNumeroEstrito(oQuery, "aposId", 0)
           iLimite = fnQueryNumeroEstrito(oQuery, "limite", 20).
    IF cUsuario = ? OR TRIM(cUsuario) = "" THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT YES,
            "USUARIO_NAO_INFORMADO", "Usuario da sessao obrigatorio.").
        RETURN.
    END.
    RUN piCarregarEstabelecimentosQuery(INPUT oQuery).
    ASSIGN cEtapa = "ABRIR_RASTREIO".
    RUN piAbrirRastreio(OUTPUT hRastreio, OUTPUT lLocalizado,
        OUTPUT cErro, OUTPUT cMensagem).
    IF NOT lLocalizado THEN DO:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT YES, cErro, cMensagem).
        RETURN.
    END.

    ASSIGN cEtapa = "EXECUTAR_CONSULTA".
    RUN consultarGeracao IN hRastreio(
        INPUT TABLE ttEmbEstabelPermitido,
        INPUT iIdEvento, INPUT iAposId, INPUT iLimite,
        OUTPUT TABLE ttEmbGeracao,
        OUTPUT TABLE ttEmbGeracaoItem,
        OUTPUT TABLE ttEmbEtiquetaGerada,
        OUTPUT lTemMais, OUTPUT iProximoId,
        OUTPUT lSucesso, OUTPUT cErro, OUTPUT cMensagem).

    ASSIGN cEtapa = "MONTAR_RESPOSTA"
           oGeracao = NEW JsonObject()
           aItens = NEW JsonArray()
           aEtiquetas = NEW JsonArray().
    FOR EACH ttEmbGeracao:
        oGeracao:Add("idEvento", STRING(ttEmbGeracao.id-evento)).
        oGeracao:Add("origem", ttEmbGeracao.origem).
        oGeracao:Add("tipoEvento", ttEmbGeracao.tipo-evento).
        oGeracao:Add("idOperacao", IF ttEmbGeracao.id-operacao = ? THEN ? ELSE STRING(ttEmbGeracao.id-operacao)).
        oGeracao:Add("idEventoOrigem", IF ttEmbGeracao.id-evento-origem = ? THEN ? ELSE STRING(ttEmbGeracao.id-evento-origem)).
        oGeracao:Add("sequenciaCiclo", ttEmbGeracao.seq-ciclo).
        oGeracao:Add("dataEvento", ttEmbGeracao.dt-evento).
        oGeracao:Add("versaoContrato", ttEmbGeracao.versao-contrato).
        oGeracao:Add("tipoDocumento", ttEmbGeracao.tipo-docto).
        oGeracao:Add("chaveDocumento", ttEmbGeracao.chave-docto).
        oGeracao:Add("codEstabel", ttEmbGeracao.cod-estabel).
        oGeracao:Add("codEmitente", ttEmbGeracao.cod-emitente).
        oGeracao:Add("cgcEmitente", ttEmbGeracao.cgc-emitente).
        oGeracao:Add("serie", ttEmbGeracao.serie).
        oGeracao:Add("numeroDocumento", ttEmbGeracao.nro-docto).
        oGeracao:Add("chaveAcesso", ttEmbGeracao.chave-acesso).
        oGeracao:Add("naturezaOperacao", ttEmbGeracao.nat-operacao).
        oGeracao:Add("dataEmissao", ttEmbGeracao.dt-emissao).
        oGeracao:Add("situacao", ttEmbGeracao.situacao).
        oGeracao:Add("tentativas", ttEmbGeracao.tentativas).
        oGeracao:Add("dataConclusao", ttEmbGeracao.dt-conclusao).
        oGeracao:Add("resultado", ttEmbGeracao.resultado).
        oGeracao:Add("mensagem", ttEmbGeracao.mensagem).
        oGeracao:Add("versao", ttEmbGeracao.versao).
    END.
    FOR EACH ttEmbGeracaoItem
        BY ttEmbGeracaoItem.sequencia BY ttEmbGeracaoItem.seq-lote:
        oLinha = NEW JsonObject().
        oLinha:Add("idItemEvento", STRING(ttEmbGeracaoItem.id-item-evento)).
        oLinha:Add("sequencia", ttEmbGeracaoItem.sequencia).
        oLinha:Add("sequenciaLote", ttEmbGeracaoItem.seq-lote).
        oLinha:Add("item", ttEmbGeracaoItem.it-codigo).
        oLinha:Add("itemOrigem", ttEmbGeracaoItem.cod-item-origem).
        oLinha:Add("lote", ttEmbGeracaoItem.lote).
        oLinha:Add("validadeLote", ttEmbGeracaoItem.dt-vali-lote).
        oLinha:Add("quantidadeOrigem", ttEmbGeracaoItem.qt-origem).
        oLinha:Add("unidadeOrigem", ttEmbGeracaoItem.un-origem).
        oLinha:Add("fatorConversao", ttEmbGeracaoItem.fator-conversao).
        oLinha:Add("quantidade", ttEmbGeracaoItem.quantidade).
        oLinha:Add("unidade", ttEmbGeracaoItem.un).
        oLinha:Add("deposito", ttEmbGeracaoItem.cod-depos).
        oLinha:Add("idParametroOrigem", IF ttEmbGeracaoItem.id-param-origem = ? THEN ? ELSE STRING(ttEmbGeracaoItem.id-param-origem)).
        oLinha:Add("versaoParametro", ttEmbGeracaoItem.versao-param).
        oLinha:Add("codTipo", ttEmbGeracaoItem.cod-tipo).
        oLinha:Add("capacidade", ttEmbGeracaoItem.capacidade-emb).
        oLinha:Add("quantidadeEtiquetas", ttEmbGeracaoItem.qtd-etiquetas).
        oLinha:Add("quantidadeResiduo", ttEmbGeracaoItem.qt-residuo).
        oLinha:Add("situacao", ttEmbGeracaoItem.situacao-item).
        oLinha:Add("mensagem", ttEmbGeracaoItem.mensagem).
        aItens:Add(oLinha).
    END.
    FOR EACH ttEmbEtiquetaGerada BY ttEmbEtiquetaGerada.id-etiqueta:
        oLinha = NEW JsonObject().
        oLinha:Add("idEtiqueta", STRING(ttEmbEtiquetaGerada.id-etiqueta)).
        oLinha:Add("codEtiqueta", ttEmbEtiquetaGerada.cod-etiqueta).
        oLinha:Add("tipoControle", ttEmbEtiquetaGerada.tipo-controle).
        oLinha:Add("idItemEvento", IF ttEmbEtiquetaGerada.id-item-evento = ? THEN ? ELSE STRING(ttEmbEtiquetaGerada.id-item-evento)).
        oLinha:Add("sequenciaGeracao", ttEmbEtiquetaGerada.seq-geracao).
        oLinha:Add("item", ttEmbEtiquetaGerada.it-codigo).
        oLinha:Add("codTipo", ttEmbEtiquetaGerada.cod-tipo).
        oLinha:Add("lote", ttEmbEtiquetaGerada.lote).
        oLinha:Add("validadeLote", ttEmbEtiquetaGerada.dt-vali-lote).
        oLinha:Add("unidade", ttEmbEtiquetaGerada.un).
        oLinha:Add("capacidade", ttEmbEtiquetaGerada.capacidade-emb).
        oLinha:Add("quantidadeInicial", ttEmbEtiquetaGerada.qtidade-ini).
        oLinha:Add("dataInclusao", ttEmbEtiquetaGerada.dt-inclusao).
        aEtiquetas:Add(oLinha).
    END.
    oOutput = NEW JsonObject().
    oOutput:Add("sucesso", lSucesso).
    oOutput:Add("codigoErro", cErro).
    oOutput:Add("mensagem", cMensagem).
    oOutput:Add("geracao", oGeracao).
    oOutput:Add("itens", aItens).
    oOutput:Add("total", aEtiquetas:Length).
    oOutput:Add("temMais", lTemMais).
    oOutput:Add("proximoId", IF iProximoId > 0 THEN STRING(iProximoId) ELSE "").
    oOutput:Add("etiquetas", aEtiquetas).

    CATCH eGeracaoRest AS Progress.Lang.Error:
        RUN piRespostaErroConsulta(OUTPUT oOutput, INPUT YES,
            "FALHA_CONSULTA_GERACAO", "Nao foi possivel consultar a geracao.").
        LOG-MANAGER:WRITE-MESSAGE(
            "CONTROLE_EMBALAGENS|CONSULTAR_GERACAO|" + cEtapa + "|" +
            (IF eGeracaoRest:NumMessages > 0 THEN eGeracaoRest:GetMessage(1)
             ELSE "Falha sem mensagem ABL.")).
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hRastreio) THEN DELETE PROCEDURE hRastreio NO-ERROR.
        EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    END FINALLY.
END.
END PROCEDURE.

PROCEDURE pi-salvar-tipo:
    DEFINE INPUT  PARAMETER oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE oRequest       AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE oBody          AS JsonObject NO-UNDO.
    DEFINE VARIABLE hCore          AS HANDLE NO-UNDO.
    DEFINE VARIABLE lCoreLocalizado AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cMetodo        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cAcao          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCodigo        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDescricao     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUsuario       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cChave         AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cHashChave     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cHashConteudo  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCanonico      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lAtivo         AS LOGICAL NO-UNDO.
    DEFINE VARIABLE iVersao        AS INTEGER NO-UNDO.
    DEFINE VARIABLE lSucesso       AS LOGICAL NO-UNDO.
    DEFINE VARIABLE lRepeticao     AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cCodResult     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDescResult    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lAtivoResult   AS LOGICAL NO-UNDO.
    DEFINE VARIABLE iVersaoResult  AS INTEGER NO-UNDO.
    DEFINE VARIABLE iIdEvento      AS INTEGER NO-UNDO.
    DEFINE VARIABLE cErro          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cMensagem      AS CHARACTER NO-UNDO.

    ASSIGN oOutput  = NEW JsonObject()
           oRequest = NEW JsonAPIRequestParser(oInput)
           oBody    = oRequest:GetPayload()
           cMetodo  = CAPS(fnBodyRequestMethod(oInput))
           cCodigo  = fnBodyChar(oBody, "codTipo", "")
           cDescricao = fnBodyChar(oBody, "descricao", "")
           cUsuario = fnBodyChar(oBody, "usuario", "")
           cChave   = fnBodyChar(oBody, "chaveIdempotente", "")
           lAtivo   = fnBodyLogical(oBody, "ativo")
           iVersao  = fnBodyInteger(oBody, "versao", 0)
           cAcao    = IF cMetodo = "POST" THEN "INCLUIR"
                      ELSE CAPS(fnBodyChar(oBody, "acao", "ALTERAR")).

    IF cMetodo = "PATCH" AND LOOKUP(cAcao, "ALTERAR,INATIVAR,EXCLUIR") = 0 THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, "ACAO_INVALIDA",
                           "Use ALTERAR, INATIVAR ou EXCLUIR para modificar um tipo.").
        RETURN.
    END.
    IF cUsuario = "" OR cChave = "" THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, "CONTEXTO_INVALIDO",
                           "Usuario da sessao e chave idempotente sao obrigatorios.").
        RETURN.
    END.

    ASSIGN cCanonico = cAcao + "|" + CAPS(TRIM(cCodigo, " ")) + "|" +
                       TRIM(cDescricao, " ") + "|" +
                       (IF lAtivo = ? THEN "?" ELSE IF lAtivo THEN "1" ELSE "0") + "|" +
                       STRING(iVersao)
           cHashChave = fnSha256("FLUIG|" + cChave)
           cHashConteudo = fnSha256(cCanonico).

    DO ON ERROR UNDO, THROW:
        RUN piAbrirCore(OUTPUT hCore, OUTPUT lCoreLocalizado,
                        OUTPUT cErro, OUTPUT cMensagem).
        IF NOT lCoreLocalizado THEN DO:
            RUN piRespostaErro(OUTPUT oOutput, cErro, cMensagem).
            RETURN.
        END.
        RUN salvarTipo IN hCore(
            INPUT cAcao, INPUT cCodigo, INPUT cDescricao, INPUT lAtivo,
            INPUT iVersao, INPUT "FLUIG", INPUT cChave,
            INPUT cHashChave, INPUT cHashConteudo, INPUT cUsuario, INPUT YES,
            OUTPUT lSucesso, OUTPUT lRepeticao, OUTPUT cCodResult,
            OUTPUT cDescResult, OUTPUT lAtivoResult, OUTPUT iVersaoResult,
            OUTPUT iIdEvento, OUTPUT cErro, OUTPUT cMensagem).
        DELETE PROCEDURE hCore NO-ERROR.

        oOutput:Add("sucesso", lSucesso).
        oOutput:Add("repeticao", lRepeticao).
        oOutput:Add("codigoErro", cErro).
        oOutput:Add("mensagem", cMensagem).
        oOutput:Add("codTipo", cCodResult).
        oOutput:Add("descricao", cDescResult).
        oOutput:Add("ativo", lAtivoResult).
        oOutput:Add("versao", iVersaoResult).
        oOutput:Add("idEvento", STRING(iIdEvento)).
        oOutput:Add("excluido", lSucesso AND cAcao = "EXCLUIR").

        CATCH oFalha AS Progress.Lang.Error:
            IF VALID-HANDLE(hCore) THEN DELETE PROCEDURE hCore NO-ERROR.
            RUN piRespostaErro(OUTPUT oOutput, "FALHA_INTERNA",
                               "Nao foi possivel concluir a manutencao do tipo.").
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE pi-consultar-parametros:
    DEFINE INPUT  PARAMETER oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE oRequest       AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE oQuery         AS JsonObject NO-UNDO.
    DEFINE VARIABLE aDados         AS JsonArray NO-UNDO.
    DEFINE VARIABLE oLinha         AS JsonObject NO-UNDO.
    DEFINE VARIABLE hCore          AS HANDLE NO-UNDO.
    DEFINE VARIABLE lCoreLocalizado AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cUsuario       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cEstabelDe     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cEstabelAte    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItemDe        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItemAte       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCodTipo       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDescricaoEstabel AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDescricaoItem AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDescricaoTipo AS CHARACTER NO-UNDO.
    DEFINE BUFFER bEstabelTela FOR mgcad.estabelec.
    DEFINE BUFFER bItemTela FOR mgcad.item.
    DEFINE BUFFER bTipoTela FOR mgesp.contr_emb_bag.
    DEFINE VARIABLE lAtivo         AS LOGICAL NO-UNDO.
    DEFINE VARIABLE iAposId        AS INTEGER NO-UNDO.
    DEFINE VARIABLE iLimite        AS INTEGER NO-UNDO.
    DEFINE VARIABLE lTemMais       AS LOGICAL NO-UNDO.
    DEFINE VARIABLE iProximo       AS INTEGER NO-UNDO.
    DEFINE VARIABLE lSucesso       AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cErro          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cMensagem      AS CHARACTER NO-UNDO.

    ASSIGN oOutput  = NEW JsonObject()
           aDados   = NEW JsonArray()
           oRequest = NEW JsonAPIRequestParser(oInput)
           oQuery   = oRequest:GetQueryParams()
           cUsuario = fnQueryChar(oQuery, "usuario", "")
           cEstabelDe = fnQueryChar(oQuery, "estabelDe", "")
           cEstabelAte = fnQueryChar(oQuery, "estabelAte", "")
           cItemDe = fnQueryChar(oQuery, "itemDe", "")
           cItemAte = fnQueryChar(oQuery, "itemAte", "")
           cCodTipo = fnQueryTextoEstrito(oQuery, "codTipo", "")
           lAtivo = fnQueryLogical(oQuery, "ativo")
           iAposId = fnQueryInteger(oQuery, "aposId", 0)
           iLimite = fnQueryInteger(oQuery, "limite", 20).

    IF cUsuario = "" THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, "USUARIO_NAO_INFORMADO",
                           "Nao foi possivel identificar o usuario da sessao Fluig.").
        RETURN.
    END.

    RUN piCarregarEstabelecimentosQuery(INPUT oQuery).
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, "SEM_PERMISSAO",
                           "O usuario nao possui estabelecimento autorizado.").
        RETURN.
    END.

    DO ON ERROR UNDO, THROW:
        RUN piAbrirCore(OUTPUT hCore, OUTPUT lCoreLocalizado,
                        OUTPUT cErro, OUTPUT cMensagem).
        IF NOT lCoreLocalizado THEN DO:
            RUN piRespostaErro(OUTPUT oOutput, cErro, cMensagem).
            RETURN.
        END.
        IF NOT CONNECTED("mgcad") THEN DO:
            DELETE PROCEDURE hCore NO-ERROR.
            RUN piRespostaErro(OUTPUT oOutput, "BANCO_MGCAD_NAO_CONECTADO",
                               "O banco de cadastros nao esta conectado.").
            RETURN.
        END.
        RUN consultarParametrosFiltrados IN hCore(
            INPUT TABLE ttEmbEstabelPermitido, INPUT cEstabelDe, INPUT cEstabelAte,
            INPUT cItemDe, INPUT cItemAte, INPUT cCodTipo, INPUT lAtivo, INPUT iAposId, INPUT iLimite,
            OUTPUT TABLE ttEmbParametro, OUTPUT lTemMais, OUTPUT iProximo,
            OUTPUT lSucesso, OUTPUT cErro, OUTPUT cMensagem).
        DELETE PROCEDURE hCore NO-ERROR.

        FOR EACH ttEmbParametro BY ttEmbParametro.id-param:
            ASSIGN cDescricaoEstabel = ? cDescricaoItem = ? cDescricaoTipo = ?.
            RELEASE bEstabelTela.
            RELEASE bItemTela.
            RELEASE bTipoTela.
            FOR FIRST bEstabelTela NO-LOCK WHERE bEstabelTela.cod-estabel = ttEmbParametro.cod-estabel:
                cDescricaoEstabel = bEstabelTela.nome.
            END.
            FOR FIRST bItemTela NO-LOCK WHERE bItemTela.it-codigo = ttEmbParametro.it-codigo:
                cDescricaoItem = bItemTela.desc-item.
            END.
            FOR FIRST bTipoTela NO-LOCK WHERE bTipoTela.cod-tipo = ttEmbParametro.cod-tipo:
                cDescricaoTipo = bTipoTela.desc-embalagem.
            END.
            oLinha = NEW JsonObject().
            oLinha:Add("idParam", STRING(ttEmbParametro.id-param)).
            oLinha:Add("codEstabel", ttEmbParametro.cod-estabel).
            oLinha:Add("item", ttEmbParametro.it-codigo).
            oLinha:Add("codTipo", ttEmbParametro.cod-tipo).
            oLinha:Add("descricaoEstabelecimento", cDescricaoEstabel).
            oLinha:Add("descricaoItem", cDescricaoItem).
            oLinha:Add("descricaoTipo", cDescricaoTipo).
            oLinha:Add("capacidade", ttEmbParametro.capacidade-emb).
            oLinha:Add("unidade", ttEmbParametro.un).
            oLinha:Add("ativo", ttEmbParametro.ativo).
            oLinha:Add("versao", ttEmbParametro.versao).
            oLinha:Add("dtInclusao", ttEmbParametro.dt-inclusao).
            oLinha:Add("usuarioInclusao", ttEmbParametro.usuario-inclusao).
            oLinha:Add("dtAlteracao", ttEmbParametro.dt-alteracao).
            oLinha:Add("usuarioAlteracao", ttEmbParametro.usuario-alteracao).
            aDados:Add(oLinha).
        END.

        oOutput:Add("sucesso", lSucesso).
        oOutput:Add("codigoErro", cErro).
        oOutput:Add("mensagem", cMensagem).
        oOutput:Add("total", aDados:Length).
        oOutput:Add("temMais", lTemMais).
        oOutput:Add("proximoId", STRING(iProximo)).
        oOutput:Add("dados", aDados).

        CATCH oFalha AS Progress.Lang.Error:
            IF VALID-HANDLE(hCore) THEN DELETE PROCEDURE hCore NO-ERROR.
            RUN piRespostaErro(OUTPUT oOutput, "FALHA_INTERNA",
                               "Nao foi possivel concluir a consulta de parametros.").
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE pi-salvar-parametro:
    DEFINE INPUT  PARAMETER oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE oRequest       AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE oBody          AS JsonObject NO-UNDO.
    DEFINE VARIABLE hCore          AS HANDLE NO-UNDO.
    DEFINE VARIABLE lCoreLocalizado AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cMetodo        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cAcao          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUsuario       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cChave         AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cEstabel       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItem          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cTipo          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cLoteMigracao AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cValidadeMigracao AS CHARACTER NO-UNDO.
    DEFINE VARIABLE dtValidadeMigracao AS DATE NO-UNDO.
    DEFINE VARIABLE iAno AS INTEGER NO-UNDO.
    DEFINE VARIABLE iMes AS INTEGER NO-UNDO.
    DEFINE VARIABLE iDia AS INTEGER NO-UNDO.
    DEFINE VARIABLE iPos AS INTEGER NO-UNDO.
    DEFINE VARIABLE lDataValida AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cUnidade       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE dCapacidade    AS DECIMAL NO-UNDO.
    DEFINE VARIABLE lAtivo         AS LOGICAL NO-UNDO.
    DEFINE VARIABLE iIdParam       AS INTEGER NO-UNDO.
    DEFINE VARIABLE iVersao        AS INTEGER NO-UNDO.
    DEFINE VARIABLE cCanonico      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cHashChave     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cHashConteudo  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lAutorizado    AS LOGICAL NO-UNDO.
    DEFINE VARIABLE lSucesso       AS LOGICAL NO-UNDO.
    DEFINE VARIABLE lRepeticao     AS LOGICAL NO-UNDO.
    DEFINE VARIABLE iIdResult      AS INTEGER NO-UNDO.
    DEFINE VARIABLE cEstabelResult AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItemResult    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cTipoResult    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE dCapResult     AS DECIMAL NO-UNDO.
    DEFINE VARIABLE cUnResult      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lAtivoResult   AS LOGICAL NO-UNDO.
    DEFINE VARIABLE iVersaoResult  AS INTEGER NO-UNDO.
    DEFINE VARIABLE lExcluido      AS LOGICAL NO-UNDO.
    DEFINE VARIABLE iIdEvento      AS INTEGER NO-UNDO.
    DEFINE VARIABLE cErro          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cMensagem      AS CHARACTER NO-UNDO.

    ASSIGN oOutput  = NEW JsonObject()
           oRequest = NEW JsonAPIRequestParser(oInput)
           oBody    = oRequest:GetPayload()
           cMetodo  = CAPS(fnBodyRequestMethod(oInput))
           cUsuario = fnBodyChar(oBody, "usuario", "")
           cChave   = fnBodyChar(oBody, "chaveIdempotente", "")
           cEstabel = fnBodyChar(oBody, "codEstabel", "")
           cItem    = fnBodyChar(oBody, "item", "")
           cTipo    = fnBodyChar(oBody, "codTipo", "")
           cUnidade = fnBodyChar(oBody, "unidade", "")
           dCapacidade = fnBodyDecimal(oBody, "capacidade", ?)
           lAtivo   = fnBodyLogical(oBody, "ativo")
           iIdParam = fnBodyInteger(oBody, "idParam", 0)
           iVersao  = fnBodyInteger(oBody, "versao", 0)
           cAcao    = IF cMetodo = "POST" THEN "INCLUIR"
                      ELSE CAPS(fnBodyChar(oBody, "acao", "ALTERAR")).

    IF oBody = ? THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, "CONTEXTO_INVALIDO", "Informe o corpo JSON da parametrizacao.").
        RETURN.
    END.
    ASSIGN cLoteMigracao = "" cValidadeMigracao = "" dtValidadeMigracao = ?.
    IF oBody:Has("loteMigracao") THEN DO:
        cLoteMigracao = oBody:GetCharacter("loteMigracao") NO-ERROR.
        IF ERROR-STATUS:ERROR OR cLoteMigracao = ? THEN DO:
            RUN piRespostaErro(OUTPUT oOutput, "LOTE_MIGRACAO_INVALIDO", "Lote de migracao deve ser texto.").
            RETURN.
        END.
        cLoteMigracao = TRIM(cLoteMigracao, " ").
        /* Teto do envelope especifico implantado: 40 caracteres; nao inferir tamanho nativo. */
        IF LENGTH(cLoteMigracao, "CHARACTER") > 40 OR INDEX(cLoteMigracao, "|") > 0 THEN DO:
            RUN piRespostaErro(OUTPUT oOutput, "LOTE_MIGRACAO_INVALIDO", "Confira o lote de migracao.").
            RETURN.
        END.
    END.
    IF oBody:Has("validadeMigracao") THEN DO:
        cValidadeMigracao = oBody:GetCharacter("validadeMigracao") NO-ERROR.
        IF ERROR-STATUS:ERROR OR cValidadeMigracao = ? THEN DO:
            RUN piRespostaErro(OUTPUT oOutput, "VALIDADE_MIGRACAO_INVALIDA", "Use validade ISO YYYY-MM-DD em texto.").
            RETURN.
        END.
        IF cValidadeMigracao <> "" THEN DO:
            lDataValida = LENGTH(cValidadeMigracao) = 10
                AND SUBSTRING(cValidadeMigracao, 5, 1) = "-"
                AND SUBSTRING(cValidadeMigracao, 8, 1) = "-".
            DO iPos = 1 TO LENGTH(cValidadeMigracao):
                IF iPos <> 5 AND iPos <> 8 AND
                   INDEX("0123456789", SUBSTRING(cValidadeMigracao, iPos, 1)) = 0 THEN lDataValida = NO.
            END.
            IF lDataValida THEN DO:
                ASSIGN iAno = INTEGER(SUBSTRING(cValidadeMigracao, 1, 4))
                       iMes = INTEGER(SUBSTRING(cValidadeMigracao, 6, 2))
                       iDia = INTEGER(SUBSTRING(cValidadeMigracao, 9, 2))
                       dtValidadeMigracao = DATE(iMes, iDia, iAno) NO-ERROR.
                IF ERROR-STATUS:ERROR OR dtValidadeMigracao = ? OR iAno < 1 THEN lDataValida = NO.
            END.
            IF NOT lDataValida THEN DO:
                RUN piRespostaErro(OUTPUT oOutput, "VALIDADE_MIGRACAO_INVALIDA", "Use uma data valida no formato YYYY-MM-DD.").
                RETURN.
            END.
        END.
    END.

    IF cMetodo = "PATCH" AND LOOKUP(cAcao, "ALTERAR,INATIVAR,EXCLUIR") = 0 THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, "ACAO_INVALIDA",
                           "Use ALTERAR, INATIVAR ou EXCLUIR para modificar a parametrizacao.").
        RETURN.
    END.
    IF cUsuario = "" OR cChave = "" THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, "CONTEXTO_INVALIDO",
                           "Usuario da sessao e chave idempotente sao obrigatorios.").
        RETURN.
    END.

    RUN piCarregarEstabelecimentosBody(INPUT oBody).
    lAutorizado = CAN-FIND(FIRST ttEmbEstabelPermitido
        WHERE ttEmbEstabelPermitido.cod-estabel = cEstabel).
    IF NOT lAutorizado THEN DO:
        RUN piRespostaErro(OUTPUT oOutput, "SEM_PERMISSAO",
                           "O usuario nao possui acesso ao estabelecimento informado.").
        RETURN.
    END.

    ASSIGN cCanonico = cAcao + "|" + STRING(iIdParam) + "|" + cEstabel + "|" +
                       cItem + "|" + CAPS(TRIM(cTipo, " ")) + "|" +
                       STRING(dCapacidade) + "|" + cUnidade + "|" +
                       (IF lAtivo = ? THEN "?" ELSE IF lAtivo THEN "1" ELSE "0") + "|" +
                       STRING(iVersao)
           cHashChave = fnSha256("FLUIG|" + cChave)
           cHashConteudo = fnSha256(cCanonico).

    /* Sem os campos novos, conservar hash anterior para repeticoes ja gravadas. */
    IF cLoteMigracao <> "" OR cValidadeMigracao <> "" THEN
        cHashConteudo = fnSha256(cCanonico + "|MIGRACAO|" + cLoteMigracao + "|" + cValidadeMigracao).

    DO ON ERROR UNDO, THROW:
        RUN piAbrirCore(OUTPUT hCore, OUTPUT lCoreLocalizado,
                        OUTPUT cErro, OUTPUT cMensagem).
        IF NOT lCoreLocalizado THEN DO:
            RUN piRespostaErro(OUTPUT oOutput, cErro, cMensagem).
            RETURN.
        END.
        RUN salvarParametro IN hCore(
            INPUT cAcao, INPUT iIdParam, INPUT cEstabel, INPUT cItem,
            INPUT cTipo, INPUT dCapacidade, INPUT cUnidade, INPUT lAtivo,
            INPUT cLoteMigracao, INPUT dtValidadeMigracao,
            INPUT iVersao, INPUT "FLUIG", INPUT cChave,
            INPUT cHashChave, INPUT cHashConteudo, INPUT cUsuario, INPUT YES,
            OUTPUT lSucesso, OUTPUT lRepeticao, OUTPUT iIdResult,
            OUTPUT cEstabelResult, OUTPUT cItemResult, OUTPUT cTipoResult,
            OUTPUT dCapResult, OUTPUT cUnResult, OUTPUT lAtivoResult,
            OUTPUT iVersaoResult, OUTPUT lExcluido, OUTPUT iIdEvento,
            OUTPUT cErro, OUTPUT cMensagem).
        DELETE PROCEDURE hCore NO-ERROR.

        oOutput:Add("sucesso", lSucesso).
        oOutput:Add("repeticao", lRepeticao).
        oOutput:Add("codigoErro", cErro).
        oOutput:Add("mensagem", cMensagem).
        oOutput:Add("idParam", STRING(iIdResult)).
        oOutput:Add("codEstabel", cEstabelResult).
        oOutput:Add("item", cItemResult).
        oOutput:Add("codTipo", cTipoResult).
        oOutput:Add("capacidade", dCapResult).
        oOutput:Add("unidade", cUnResult).
        oOutput:Add("ativo", lAtivoResult).
        oOutput:Add("versao", iVersaoResult).
        oOutput:Add("excluido", lExcluido).
        oOutput:Add("idEvento", STRING(iIdEvento)).

        CATCH oFalha AS Progress.Lang.Error:
            IF VALID-HANDLE(hCore) THEN DELETE PROCEDURE hCore NO-ERROR.
            RUN piRespostaErro(OUTPUT oOutput, "FALHA_INTERNA",
                               "Nao foi possivel concluir a manutencao da parametrizacao.").
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE piCarregarEstabelecimentosQuery:
    DEFINE INPUT PARAMETER poQuery AS JsonObject NO-UNDO.

    DEFINE VARIABLE aEstabelecimentos AS JsonArray NO-UNDO.
    DEFINE VARIABLE cEstabelecimento  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE i                 AS INTEGER NO-UNDO.

    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    IF poQuery = ? OR NOT poQuery:Has("estabelecimentoPermitido") THEN RETURN.

    aEstabelecimentos = poQuery:GetJsonArray("estabelecimentoPermitido") NO-ERROR.
    IF ERROR-STATUS:ERROR OR aEstabelecimentos = ? THEN RETURN.

    DO i = 1 TO aEstabelecimentos:Length:
        cEstabelecimento = aEstabelecimentos:GetCharacter(i) NO-ERROR.
        IF NOT ERROR-STATUS:ERROR
        AND cEstabelecimento <> ?
        AND TRIM(cEstabelecimento) <> ""
        AND NOT CAN-FIND(FIRST ttEmbEstabelPermitido
            WHERE ttEmbEstabelPermitido.cod-estabel = TRIM(cEstabelecimento)) THEN DO:
            CREATE ttEmbEstabelPermitido.
            ttEmbEstabelPermitido.cod-estabel = TRIM(cEstabelecimento).
        END.
    END.
END PROCEDURE.

PROCEDURE piCarregarEstabelecimentosBody:
    DEFINE INPUT PARAMETER poBody AS JsonObject NO-UNDO.

    DEFINE VARIABLE aEstabelecimentos AS JsonArray NO-UNDO.
    DEFINE VARIABLE cEstabelecimento  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE i                 AS INTEGER NO-UNDO.

    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    IF poBody = ? OR NOT poBody:Has("estabelecimentosPermitidos") THEN RETURN.

    aEstabelecimentos = poBody:GetJsonArray("estabelecimentosPermitidos") NO-ERROR.
    IF ERROR-STATUS:ERROR OR aEstabelecimentos = ? THEN RETURN.

    DO i = 1 TO aEstabelecimentos:Length:
        cEstabelecimento = aEstabelecimentos:GetCharacter(i) NO-ERROR.
        IF NOT ERROR-STATUS:ERROR
        AND cEstabelecimento <> ?
        AND TRIM(cEstabelecimento) <> ""
        AND NOT CAN-FIND(FIRST ttEmbEstabelPermitido
            WHERE ttEmbEstabelPermitido.cod-estabel = TRIM(cEstabelecimento)) THEN DO:
            CREATE ttEmbEstabelPermitido.
            ttEmbEstabelPermitido.cod-estabel = TRIM(cEstabelecimento).
        END.
    END.
END PROCEDURE.

PROCEDURE piRespostaErro:
    DEFINE OUTPUT PARAMETER poOutput   AS JsonObject NO-UNDO.
    DEFINE INPUT  PARAMETER pcCodigo   AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcMensagem AS CHARACTER NO-UNDO.

    poOutput = NEW JsonObject().
    poOutput:Add("sucesso", FALSE).
    poOutput:Add("codigoErro", pcCodigo).
    poOutput:Add("mensagem", pcMensagem).
END PROCEDURE.

FUNCTION fnQueryChar RETURNS CHARACTER
    (poQuery AS JsonObject, pcNome AS CHARACTER, pcPadrao AS CHARACTER):
    DEFINE VARIABLE aValor AS JsonArray NO-UNDO.
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    IF poQuery = ? OR NOT poQuery:Has(pcNome) THEN RETURN pcPadrao.
    aValor = poQuery:GetJsonArray(pcNome) NO-ERROR.
    IF ERROR-STATUS:ERROR OR aValor = ? OR aValor:Length = 0 THEN RETURN pcPadrao.
    cValor = aValor:GetCharacter(1) NO-ERROR.
    IF ERROR-STATUS:ERROR OR cValor = ? THEN RETURN pcPadrao.
    RETURN cValor.
END FUNCTION.

FUNCTION fnQueryInteger RETURNS INTEGER
    (poQuery AS JsonObject, pcNome AS CHARACTER, piPadrao AS INTEGER):
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iValor AS INTEGER NO-UNDO.
    cValor = fnQueryChar(poQuery, pcNome, "").
    IF cValor = "" THEN RETURN piPadrao.
    iValor = INTEGER(cValor) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN RETURN ?.
    RETURN iValor.
END FUNCTION.

FUNCTION fnQueryLogical RETURNS LOGICAL
    (poQuery AS JsonObject, pcNome AS CHARACTER):
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    cValor = CAPS(fnQueryChar(poQuery, pcNome, "")).
    IF cValor = "" THEN RETURN ?.
    IF LOOKUP(cValor, "TRUE,1,SIM,YES") > 0 THEN RETURN YES.
    IF LOOKUP(cValor, "FALSE,0,NAO,NO") > 0 THEN RETURN NO.
    RETURN ?.
END FUNCTION.

FUNCTION fnBodyChar RETURNS CHARACTER
    (poBody AS JsonObject, pcNome AS CHARACTER, pcPadrao AS CHARACTER):
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    IF poBody = ? OR NOT poBody:Has(pcNome) THEN RETURN pcPadrao.
    cValor = poBody:GetCharacter(pcNome) NO-ERROR.
    IF ERROR-STATUS:ERROR OR cValor = ? THEN RETURN pcPadrao.
    RETURN cValor.
END FUNCTION.

FUNCTION fnBodyRequestMethod RETURNS CHARACTER (poInput AS JsonObject):
    DEFINE VARIABLE cMetodo AS CHARACTER NO-UNDO.
    IF poInput = ? OR NOT poInput:Has("method") THEN RETURN "".
    cMetodo = poInput:GetCharacter("method") NO-ERROR.
    IF ERROR-STATUS:ERROR OR cMetodo = ? THEN RETURN "".
    RETURN cMetodo.
END FUNCTION.

FUNCTION fnBodyInteger RETURNS INTEGER
    (poBody AS JsonObject, pcNome AS CHARACTER, piPadrao AS INTEGER):
    DEFINE VARIABLE iValor AS INTEGER NO-UNDO.
    IF poBody = ? OR NOT poBody:Has(pcNome) THEN RETURN piPadrao.
    iValor = poBody:GetInteger(pcNome) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN RETURN ?.
    RETURN iValor.
END FUNCTION.

FUNCTION fnBodyDecimal RETURNS DECIMAL
    (poBody AS JsonObject, pcNome AS CHARACTER, pdPadrao AS DECIMAL):
    DEFINE VARIABLE dValor AS DECIMAL NO-UNDO.
    IF poBody = ? OR NOT poBody:Has(pcNome) THEN RETURN pdPadrao.
    dValor = poBody:GetDecimal(pcNome) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN RETURN ?.
    RETURN dValor.
END FUNCTION.

FUNCTION fnBodyLogical RETURNS LOGICAL
    (poBody AS JsonObject, pcNome AS CHARACTER):
    DEFINE VARIABLE lValor AS LOGICAL NO-UNDO.
    IF poBody = ? OR NOT poBody:Has(pcNome) THEN RETURN ?.
    lValor = poBody:GetLogical(pcNome) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN RETURN ?.
    RETURN lValor.
END FUNCTION.

FUNCTION fnSha256 RETURNS CHARACTER (pcValor AS CHARACTER):
    DEFINE VARIABLE rDigest AS RAW NO-UNDO.
    DEFINE VARIABLE cDigest AS CHARACTER NO-UNDO.

    rDigest = MESSAGE-DIGEST("SHA-256", pcValor).
    cDigest = HEX-ENCODE(rDigest).
    RETURN cDigest.
END FUNCTION.

FUNCTION fnQueryTextoEstrito RETURNS CHARACTER
    (poQuery AS JsonObject,pcNome AS CHARACTER,pcPadrao AS CHARACTER):
DEFINE VARIABLE aValor AS JsonArray NO-UNDO.
DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
IF poQuery = ? THEN RETURN pcPadrao.
IF NOT poQuery:Has(pcNome) THEN RETURN pcPadrao.
aValor = poQuery:GetJsonArray(pcNome) NO-ERROR.
IF ERROR-STATUS:ERROR OR aValor = ? THEN RETURN ?.
IF aValor:Length <> 1 THEN RETURN ?.
cValor = aValor:GetCharacter(1) NO-ERROR.
IF ERROR-STATUS:ERROR OR cValor = ? THEN RETURN ?.
RETURN cValor.
END FUNCTION.

FUNCTION fnQueryNumeroEstrito RETURNS INTEGER
    (poQuery AS JsonObject,pcNome AS CHARACTER,piPadrao AS INTEGER):
DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
DEFINE VARIABLE iValor AS INTEGER NO-UNDO.
DEFINE VARIABLE iPos AS INTEGER NO-UNDO.
IF poQuery = ? THEN RETURN piPadrao.
IF NOT poQuery:Has(pcNome) THEN RETURN piPadrao.
cValor = fnQueryTextoEstrito(poQuery,pcNome,?).
IF cValor = ? THEN RETURN ?.
IF LENGTH(cValor) < 1 OR LENGTH(cValor) > 10 THEN RETURN ?.
DO iPos = 1 TO LENGTH(cValor):
    IF INDEX("0123456789",SUBSTRING(cValor,iPos,1)) = 0 THEN RETURN ?.
END.
iValor = INTEGER(cValor) NO-ERROR.
IF ERROR-STATUS:ERROR OR iValor = ? THEN RETURN ?.
RETURN iValor.
END FUNCTION.

FUNCTION fnDataISO RETURNS DATE (pcData AS CHARACTER):
DEFINE VARIABLE iPos AS INTEGER NO-UNDO.
DEFINE VARIABLE iAno AS INTEGER NO-UNDO.
DEFINE VARIABLE dtData AS DATE NO-UNDO.
IF pcData = ? THEN RETURN ?.
IF LENGTH(pcData) <> 10 THEN RETURN ?.
IF SUBSTRING(pcData,5,1) <> "-" OR SUBSTRING(pcData,8,1) <> "-" THEN RETURN ?.
DO iPos = 1 TO 10:
    IF iPos <> 5 AND iPos <> 8 AND
        INDEX("0123456789",SUBSTRING(pcData,iPos,1)) = 0 THEN RETURN ?.
END.
iAno = INTEGER(SUBSTRING(pcData,1,4)).
IF iAno < 1 THEN RETURN ?.
dtData = DATE(INTEGER(SUBSTRING(pcData,6,2)),INTEGER(SUBSTRING(pcData,9,2)),iAno) NO-ERROR.
IF ERROR-STATUS:ERROR OR dtData = ? THEN RETURN ?.
IF YEAR(dtData) <> iAno THEN RETURN ?.
RETURN dtData.
END FUNCTION.

{fontes/progress/includes/contr-emb-api-operacoes.i}

{fontes/progress/includes/contr-emb-api-confirmacoes.i}
{fontes/progress/includes/contr-emb-api-bags.i}



{fontes/progress/includes/contr-emb-api-estorno.i}

{fontes/progress/includes/contr-emb-api-xml.i}
