/* DT115. Fronteira JSON: IDs em texto, selecao inteira, erro sanitizado. */
FUNCTION fApiTexto RETURNS CHARACTER
    (INPUT poBody AS JsonObject, INPUT pcNome AS CHARACTER, INPUT pcPadrao AS CHARACTER):
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    IF poBody = ? THEN RETURN ?.
    IF NOT poBody:Has(pcNome) THEN RETURN pcPadrao.
    cValor = poBody:GetCharacter(pcNome) NO-ERROR.
    IF ERROR-STATUS:ERROR OR cValor = ? THEN RETURN ?.
    RETURN TRIM(cValor).
END FUNCTION.

FUNCTION fApiId RETURNS INTEGER
    (INPUT poBody AS JsonObject, INPUT pcNome AS CHARACTER, INPUT piPadrao AS INTEGER):
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE iValor AS INTEGER NO-UNDO.
    IF poBody = ? THEN RETURN ?.
    IF NOT poBody:Has(pcNome) THEN RETURN piPadrao.
    cValor = fApiTexto(poBody,pcNome,?).
    IF cValor = ? OR LENGTH(cValor) < 1 OR LENGTH(cValor) > 10 THEN RETURN ?.
    DO i = 1 TO LENGTH(cValor):
        IF INDEX("0123456789",SUBSTRING(cValor,i,1)) = 0 THEN RETURN ?.
    END.
    iValor = INTEGER(cValor) NO-ERROR.
    IF ERROR-STATUS:ERROR OR iValor = ? OR STRING(iValor) <> cValor THEN RETURN ?.
    RETURN iValor.
END FUNCTION.

PROCEDURE pi-criar-transferencia:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piCriarWtRest(INPUT oInput,INPUT "TRANSFERENCIA",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-criar-remessa:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piCriarWtRest(INPUT oInput,INPUT "REMESSA_TERCEIROS",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-criar-devolucao:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piCriarWtRest(INPUT oInput,INPUT "DEVOLUCAO",OUTPUT oOutput).
END PROCEDURE.

PROCEDURE piCriarWtRest:
DEFINE INPUT PARAMETER poInput AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER pcFluxo AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER poOutput AS JsonObject NO-UNDO.
DEFINE VARIABLE oRequest AS JsonAPIRequestParser NO-UNDO.
DEFINE VARIABLE oBody AS JsonObject NO-UNDO.
DEFINE VARIABLE aSelecao AS JsonArray NO-UNDO.
DEFINE VARIABLE oSelecao AS JsonObject NO-UNDO.
DEFINE VARIABLE aDados AS JsonArray NO-UNDO.
DEFINE VARIABLE oLinha AS JsonObject NO-UNDO.
DEFINE VARIABLE hOper AS HANDLE NO-UNDO.
DEFINE VARIABLE hDevol AS HANDLE NO-UNDO.
DEFINE VARIABLE cModulo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChave AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstabel AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDestino AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNatureza AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSerie AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSerieOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNumeroOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNatOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagem AS CHARACTER NO-UNDO.
DEFINE VARIABLE iEmitente AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE iWt AS INTEGER NO-UNDO.
DEFINE VARIABLE iOperacao AS INTEGER NO-UNDO.
DEFINE VARIABLE iEtiqueta AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersao AS INTEGER NO-UNDO.
DEFINE VARIABLE dQuantidade AS DECIMAL NO-UNDO.
DEFINE VARIABLE dValor AS DECIMAL NO-UNDO.
DEFINE VARIABLE lSucesso AS LOGICAL NO-UNDO.
DEFINE VARIABLE lRepeticao AS LOGICAL NO-UNDO.
DO ON ERROR UNDO, THROW:
    EMPTY TEMP-TABLE ttEmbDevolucaoSelecao.
    EMPTY TEMP-TABLE ttEmbDevolucaoLinha.
    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    ASSIGN oRequest = NEW JsonAPIRequestParser(poInput) oBody = oRequest:GetPayload().
    IF oBody = ? THEN DO:
        RUN piRespostaErro(OUTPUT poOutput,"CORPO_INVALIDO","Informe um objeto JSON de preparacao.").
        RETURN.
    END.
    ASSIGN cUsuario = fApiTexto(oBody,"usuario","") cChave = fApiTexto(oBody,"chaveIdempotente","")
        cEstabel = fApiTexto(oBody,"codEstabel","") cDestino = fApiTexto(oBody,"codEstabelDestino","")
        cNatureza = fApiTexto(oBody,"natureza","") cSerie = fApiTexto(oBody,"serie","")
        cSerieOrigem = fApiTexto(oBody,"serieOrigem","") cNumeroOrigem = fApiTexto(oBody,"numeroOrigem","")
        cNatOrigem = fApiTexto(oBody,"naturezaOrigem","")
        iEmitente = fApiId(oBody,IF pcFluxo = "DEVOLUCAO" THEN "emitenteOrigem" ELSE "emitenteDestino",0).
    IF cUsuario = ? OR cUsuario = "" OR cChave = ? OR cChave = "" OR
       cEstabel = ? OR cEstabel = "" OR cDestino = ? OR cNatureza = ? OR cNatureza = "" OR
       cSerie = ? OR cSerie = "" OR cSerieOrigem = ? OR cNumeroOrigem = ? OR cNatOrigem = ? OR iEmitente = ? THEN DO:
        RUN piRespostaErro(OUTPUT poOutput,"PARAMETRO_INVALIDO","Contexto e identificadores devem ter o formato contratado.").
        RETURN.
    END.
    RUN piCarregarEstabelecimentosBody(INPUT oBody).
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = cEstabel) THEN DO:
        RUN piRespostaErro(OUTPUT poOutput,"SEM_PERMISSAO","Estabelecimento fora do contexto autorizado.").
        RETURN.
    END.
    aSelecao = oBody:GetJsonArray("selecao") NO-ERROR.
    IF ERROR-STATUS:ERROR OR aSelecao = ? THEN DO:
        RUN piRespostaErro(OUTPUT poOutput,"SELECAO_INVALIDA","Informe a lista de embalagens.").
        RETURN.
    END.
    IF aSelecao:Length < 1 OR aSelecao:Length > 100 THEN DO:
        RUN piRespostaErro(OUTPUT poOutput,"LIMITE_SELECAO_INVALIDO","Selecione de 1 a 100 embalagens.").
        RETURN.
    END.
    DO i = 1 TO aSelecao:Length:
        oSelecao = aSelecao:GetJsonObject(i) NO-ERROR.
        IF ERROR-STATUS:ERROR OR oSelecao = ? THEN DO:
            RUN piRespostaErro(OUTPUT poOutput,"SELECAO_INVALIDA","Cada selecao deve ser um objeto JSON.").
            RETURN.
        END.
        ASSIGN iEtiqueta = fApiId(oSelecao,"idEtiqueta",0) iVersao = fApiId(oSelecao,"versao",0)
            dQuantidade = fnBodyDecimal(oSelecao,"quantidade",?).
        IF iEtiqueta = ? OR iEtiqueta <= 0 OR iVersao = ? OR iVersao <= 0 OR
            dQuantidade = ? OR dQuantidade <= 0 OR ROUND(dQuantidade,4) <> dQuantidade THEN DO:
            RUN piRespostaErro(OUTPUT poOutput,"SELECAO_INVALIDA","Confira ID, versao e quantidade de cada embalagem.").
            RETURN.
        END.
        IF CAN-FIND(FIRST ttEmbDevolucaoSelecao WHERE ttEmbDevolucaoSelecao.id-etiqueta = iEtiqueta) THEN DO:
            RUN piRespostaErro(OUTPUT poOutput,"ETIQUETA_DUPLICADA","A mesma embalagem aparece mais de uma vez.").
            RETURN.
        END.
        CREATE ttEmbDevolucaoSelecao.
        ASSIGN ttEmbDevolucaoSelecao.id-etiqueta = iEtiqueta ttEmbDevolucaoSelecao.versao = iVersao
            ttEmbDevolucaoSelecao.quantidade = dQuantidade.
    END.
    cModulo = SEARCH("esp/api/v1/contr-emb-operacao.r").
    IF cModulo = ? THEN DO:
        RUN piRespostaErro(OUTPUT poOutput,"OPERACAO_NAO_LOCALIZADA","Modulo de operacoes nao localizado no PROPATH.").
        RETURN.
    END.
    RUN VALUE(cModulo) PERSISTENT SET hOper.
    IF pcFluxo = "DEVOLUCAO" THEN DO:
        IF cSerieOrigem = "" OR cNumeroOrigem = "" OR cNatOrigem = "" OR iEmitente <= 0 THEN DO:
            RUN piRespostaErro(OUTPUT poOutput,"ORIGEM_INVALIDA","Informe a identidade completa do recebimento de origem.").
            RETURN.
        END.
        cModulo = SEARCH("esp/api/v1/contr-emb-devolucao.r").
        IF cModulo = ? THEN DO:
            RUN piRespostaErro(OUTPUT poOutput,"DEVOLUCAO_NAO_LOCALIZADA","Modulo de devolucao nao localizado no PROPATH.").
            RETURN.
        END.
        RUN VALUE(cModulo) PERSISTENT SET hDevol.
        RUN criarWtDevolucao IN hDevol (INPUT hOper, INPUT TABLE ttEmbEstabelPermitido,
            INPUT cEstabel, INPUT cNatureza, INPUT cSerie, INPUT iEmitente,
            INPUT cSerieOrigem, INPUT cNumeroOrigem, INPUT cNatOrigem, INPUT cUsuario, INPUT cChave,
            INPUT TABLE ttEmbDevolucaoSelecao, OUTPUT TABLE ttEmbDevolucaoLinha,
            OUTPUT iWt, OUTPUT iOperacao, OUTPUT lSucesso, OUTPUT lRepeticao, OUTPUT cErro, OUTPUT cMensagem).
    END.
    ELSE DO:
        dValor = fnBodyDecimal(oBody,"valorItem",?).
        IF dValor = ? OR dValor < 0 THEN DO:
            RUN piRespostaErro(OUTPUT poOutput,"VALOR_INVALIDO","Informe valorItem numerico nao negativo.").
            RETURN.
        END.
        RUN criarWtSaidaDireta IN hOper (INPUT TABLE ttEmbEstabelPermitido,
            INPUT pcFluxo, INPUT cEstabel, INPUT cDestino, INPUT iEmitente, INPUT cNatureza, INPUT cSerie,
            INPUT dValor, INPUT cUsuario, INPUT cChave, INPUT TABLE ttEmbDevolucaoSelecao,
            OUTPUT iWt, OUTPUT iOperacao, OUTPUT lSucesso, OUTPUT lRepeticao, OUTPUT cErro, OUTPUT cMensagem).
    END.
    /* O modulo legado de devolucao pode retornar diagnostico BO detalhado:
       a fronteira publica nao o reproduz. */
    IF lSucesso = ? OR lSucesso = NO THEN DO:
        /* Preservar codigos funcionais conhecidos, nunca texto bruto de BO. */
        IF cErro = ? OR LOOKUP(cErro,"PARAMETRO_INVALIDO,SEM_PERMISSAO,BANCO_NAO_CONECTADO,ETIQUETA_DUPLICADA,LIMITE_SELECAO_INVALIDO,CHAVE_IDEMPOTENTE_DIVERGENTE,CHAVE_IDEMPOTENTE_AMBIGUA,OPERACAO_CANCELADA,ORIGEM_BLOQUEADA,ORIGEM_NAO_ENCONTRADA,ETIQUETA_BLOQUEADA,ETIQUETA_NAO_ENCONTRADA,VERSAO_ETIQUETA_DIVERGENTE,QUANTIDADE_OU_VERSAO_DIVERGENTE,ETIQUETA_INDISPONIVEL,ORIGEM_NAO_ELEGIVEL,ETIQUETA_FORA_DA_ORIGEM,NATUREZA_FORA_DA_DEVOLUCAO,NATUREZA_FORA_DO_FLUXO,DESTINO_INVALIDO,DESTINO_OBRIGATORIO,EMITENTE_DESTINO_INVALIDO,EMITENTE_DESTINO_DIVERGENTE,EMPRESAS_DIFERENTES,ESTABELECIMENTO_NAO_ENCONTRADO,EMITENTE_NAO_ENCONTRADO,ITEM_OU_UNIDADE_INVALIDA,SALDO_ESTOQ_INSUFICIENTE_PARA_SELECAO") = 0 THEN
            cErro = "PREPARACAO_WT_RECUSADA".
        RUN piRespostaErro(OUTPUT poOutput,cErro,
            "Nao foi possivel preparar o WT; confira origem, disponibilidade, versoes e parametros.").
        RETURN.
    END.
    ASSIGN poOutput = NEW JsonObject() aDados = NEW JsonArray().
    FOR EACH ttEmbDevolucaoLinha BY ttEmbDevolucaoLinha.sequencia-origem:
        oLinha = NEW JsonObject().
        oLinha:Add("sequenciaOrigem",ttEmbDevolucaoLinha.sequencia-origem).
        oLinha:Add("idItemWt",STRING(ttEmbDevolucaoLinha.seq-wt-it-docto)).
        oLinha:Add("item",ttEmbDevolucaoLinha.it-codigo).
        oLinha:Add("unidade",ttEmbDevolucaoLinha.un).
        oLinha:Add("quantidade",ttEmbDevolucaoLinha.quantidade).
        oLinha:Add("lote",ttEmbDevolucaoLinha.lote).
        oLinha:Add("validadeLote",ttEmbDevolucaoLinha.dt-vali-lote).
        oLinha:Add("deposito",ttEmbDevolucaoLinha.cod-depos).
        oLinha:Add("localizacao",ttEmbDevolucaoLinha.cod-localiz).
        aDados:Add(oLinha).
    END.
    poOutput:Add("sucesso",TRUE).
    poOutput:Add("repeticao",lRepeticao).
    poOutput:Add("codigoErro","").
    poOutput:Add("mensagem",IF lRepeticao THEN "Preparacao ja registrada; consulte a operacao."
        ELSE "WT preparado; efetivacao da nota permanece no Datasul.").
    poOutput:Add("wt",STRING(iWt)).
    poOutput:Add("idOperacao",STRING(iOperacao)).
    poOutput:Add("dados",aDados).
    poOutput:Add("total",aDados:Length).
    CATCH eWt AS Progress.Lang.Error:
        LOG-MANAGER:WRITE-MESSAGE("CONTROLE_EMBALAGENS|REST_WT|ABL="
            + (IF eWt:NumMessages > 0 THEN STRING(eWt:GetMessageNum(1)) ELSE "0")) NO-ERROR.
        RUN piRespostaErro(OUTPUT poOutput,"FALHA_PREPARACAO_WT",
            "Falha na preparacao. Consulte o resultado pela mesma chave antes de repetir a solicitacao.").
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hDevol) THEN DELETE PROCEDURE hDevol NO-ERROR.
        IF VALID-HANDLE(hOper) THEN DELETE PROCEDURE hOper NO-ERROR.
        EMPTY TEMP-TABLE ttEmbDevolucaoLinha.
        EMPTY TEMP-TABLE ttEmbDevolucaoSelecao.
        EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    END FINALLY.
END.
END PROCEDURE.

PROCEDURE pi-listar-operacoes:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piConsultarOperacaoRest(INPUT oInput,INPUT "LISTA",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-resultado-operacao:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piConsultarOperacaoRest(INPUT oInput,INPUT "RESULTADO",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-itens-operacao:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piConsultarOperacaoRest(INPUT oInput,INPUT "ITENS",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-eventos-operacao:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piConsultarOperacaoRest(INPUT oInput,INPUT "EVENTOS",OUTPUT oOutput).
END PROCEDURE.

PROCEDURE piConsultarOperacaoRest:
DEFINE INPUT PARAMETER poInput AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER pcModo AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER poOutput AS JsonObject NO-UNDO.
DEFINE VARIABLE oRequest AS JsonAPIRequestParser NO-UNDO.
DEFINE VARIABLE oQuery AS JsonObject NO-UNDO.
DEFINE VARIABLE hOper AS HANDLE NO-UNDO.
DEFINE VARIABLE cModulo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstabel AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSituacao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChave AS CHARACTER NO-UNDO.
DEFINE VARIABLE cRamo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSerieOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNumeroOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNatOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE iOperacao AS INTEGER NO-UNDO.
DEFINE VARIABLE iWt AS INTEGER NO-UNDO.
DEFINE VARIABLE iEmitente AS INTEGER NO-UNDO.
DEFINE VARIABLE iApos AS INTEGER NO-UNDO.
DEFINE VARIABLE iLimite AS INTEGER NO-UNDO.
DO ON ERROR UNDO, THROW:
    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    ASSIGN oRequest = NEW JsonAPIRequestParser(poInput) oQuery = oRequest:GetQueryParams()
        cUsuario = fnQueryTextoEstrito(oQuery,"usuario","") cEstabel = fnQueryTextoEstrito(oQuery,"codEstabel","")
        cSituacao = fnQueryTextoEstrito(oQuery,"situacao","") cTipo = fnQueryTextoEstrito(oQuery,"tipoOperacao","")
        cChave = fnQueryTextoEstrito(oQuery,"chaveIdempotente","") cRamo = fnQueryTextoEstrito(oQuery,"ramo","")
        cSerieOrigem = fnQueryTextoEstrito(oQuery,"serieOrigem","") cNumeroOrigem = fnQueryTextoEstrito(oQuery,"numeroOrigem","")
        cNatOrigem = fnQueryTextoEstrito(oQuery,"naturezaOrigem","")
        iOperacao = fnQueryNumeroEstrito(oQuery,"idOperacao",0) iWt = fnQueryNumeroEstrito(oQuery,"wt",0)
        iEmitente = fnQueryNumeroEstrito(oQuery,"emitenteOrigem",0)
        iApos = fnQueryNumeroEstrito(oQuery,"aposId",0) iLimite = fnQueryNumeroEstrito(oQuery,"limite",20).
    IF cUsuario = ? OR TRIM(cUsuario) = "" OR cEstabel = ? OR TRIM(cEstabel) = "" OR
        cSituacao = ? OR cTipo = ? OR cChave = ? OR cRamo = ? OR
        cSerieOrigem = ? OR cNumeroOrigem = ? OR cNatOrigem = ? OR iEmitente = ? THEN DO:
        RUN piRespostaErroConsulta(OUTPUT poOutput,INPUT YES,"PARAMETRO_INVALIDO","Confira filtros e contexto da sessao.").
        RETURN.
    END.
    RUN piCarregarEstabelecimentosQuery(INPUT oQuery).
    cModulo = SEARCH("esp/api/v1/contr-emb-operacao.r").
    IF cModulo = ? THEN DO:
        RUN piRespostaErroConsulta(OUTPUT poOutput,INPUT YES,"OPERACAO_NAO_LOCALIZADA","Modulo de operacoes nao localizado no PROPATH.").
        RETURN.
    END.
    RUN VALUE(cModulo) PERSISTENT SET hOper.
    RUN consultarOperacoesRest IN hOper (INPUT TABLE ttEmbEstabelPermitido,
        INPUT pcModo, INPUT cEstabel, INPUT iOperacao, INPUT iWt, INPUT cSituacao, INPUT cTipo,
        INPUT cUsuario, INPUT cChave, INPUT cRamo, INPUT iEmitente, INPUT cSerieOrigem,
        INPUT cNumeroOrigem, INPUT cNatOrigem, INPUT iApos, INPUT iLimite, OUTPUT poOutput).
    CATCH eOperacao AS Progress.Lang.Error:
        RUN piRespostaErroConsulta(OUTPUT poOutput,INPUT YES,"FALHA_CONSULTA_OPERACAO","Nao foi possivel consultar a operacao.").
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hOper) THEN DELETE PROCEDURE hOper NO-ERROR.
        EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    END FINALLY.
END.
END PROCEDURE.

