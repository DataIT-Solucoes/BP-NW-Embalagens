/* Monitor XML: consulta propria, somente leitura. Layout comprovado no TESTE19/10/2026.
   Nao executa importador/BO de processamento. Nao presume valor de original/traduzido. */
USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
{fontes/progress/contr-emb.i}
DEFINE BUFFER bNfe FOR mgind.doc-orig-nfe.
DEFINE BUFFER bCte FOR mgind.docto-orig-cte.
DEFINE BUFFER bNfse FOR mgind.docto-orig-nfse.
DEFINE BUFFER bDocXml FOR mgmov.docum-est.
DEFINE BUFFER bEmitXml FOR mgcad.emitente.
DEFINE BUFFER bEstXml FOR mgcad.estabelec.
DEFINE BUFFER bEstFiscal FOR mgcad.estabelec.
DEFINE TEMP-TABLE ttXml NO-UNDO
    FIELD identidade AS CHARACTER FIELD tipo AS CHARACTER FIELD chave AS CHARACTER
    FIELD dataOrdem AS DATE
    INDEX pk IS PRIMARY UNIQUE identidade
    INDEX ordem dataOrdem DESCENDING identidade.
DEFINE TEMP-TABLE ttXmlRep NO-UNDO
    FIELD identidade AS CHARACTER FIELD origem AS INTEGER
    FIELD cabecalho AS CLASS Progress.Lang.Object
    INDEX pk IS PRIMARY UNIQUE identidade origem.
DEFINE VARIABLE cEstabelXml AS CHARACTER NO-UNDO.
DEFINE VARIABLE hRecebXml AS HANDLE NO-UNDO.
DEFINE VARIABLE iLidosXml AS INTEGER NO-UNDO.
DEFINE VARIABLE lTemEmbXml AS LOGICAL NO-UNDO.
DEFINE VARIABLE cFiscalXml AS CHARACTER NO-UNDO.
FUNCTION xTexto RETURNS CHARACTER (INPUT p AS JsonObject, INPUT nome AS CHARACTER, INPUT padrao AS CHARACTER) FORWARD.
FUNCTION xFiscal RETURNS CHARACTER (INPUT valor AS CHARACTER) FORWARD.
FUNCTION xData RETURNS DATE (INPUT valor AS CHARACTER) FORWARD.
FUNCTION xIso RETURNS CHARACTER (INPUT valor AS DATE) FORWARD.
FUNCTION xInteiro RETURNS INTEGER (INPUT valor AS CHARACTER) FORWARD.
FUNCTION xSituacao RETURNS CHARACTER (INPUT tipo AS CHARACTER, INPUT codigo AS INTEGER) FORWARD.
FUNCTION xCab RETURNS JsonObject (INPUT tipo AS CHARACTER, INPUT chave AS CHARACTER,
    INPUT origem AS INTEGER, INPUT numero AS CHARACTER, INPUT serie AS CHARACTER,
    INPUT emitente AS INTEGER, INPUT nome AS CHARACTER, INPUT emissao AS DATE,
    INPUT transacao AS DATE, INPUT situacao AS INTEGER, INPUT valor AS DECIMAL) FORWARD.
FUNCTION xGrupo RETURNS JsonObject () FORWARD.

PROCEDURE consultarXmls:
    DEFINE INPUT PARAMETER pcConsulta AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER poFiltros AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER poResposta AS JsonObject NO-UNDO.
    DEFINE VARIABLE cTipo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cTipoData AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cEmbalagens AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSituacao AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cNumero AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSerie AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cChave AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCursor AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cIdCursor AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPermitidos AS CHARACTER NO-UNDO.
    DEFINE VARIABLE nomes AS CHARACTER EXTENT NO-UNDO.
    DEFINE VARIABLE dtIni AS DATE NO-UNDO.
    DEFINE VARIABLE dtFim AS DATE NO-UNDO.
    DEFINE VARIABLE dtCursor AS DATE NO-UNDO.
    DEFINE VARIABLE dtOrdem AS DATE NO-UNDO.
    DEFINE VARIABLE iEmitente AS INTEGER NO-UNDO.
    DEFINE VARIABLE iLimite AS INTEGER NO-UNDO.
    DEFINE VARIABLE iTotal AS INTEGER NO-UNDO.
    DEFINE VARIABLE iEstabelFiscal AS INTEGER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE lDetalhe AS LOGICAL NO-UNDO.
    DEFINE VARIABLE lMais AS LOGICAL NO-UNDO.
    DEFINE VARIABLE o AS JsonObject NO-UNDO.
    DEFINE VARIABLE a AS JsonArray NO-UNDO.
    ASSIGN poResposta = NEW JsonObject() a = NEW JsonArray() iLidosXml = 0 cErro = "".
    EMPTY TEMP-TABLE ttXml.
    EMPTY TEMP-TABLE ttXmlRep.
    DO ON ERROR UNDO, THROW:
        IF poFiltros = ? OR LOOKUP(pcConsulta,"LISTA,DETALHE") = 0 THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        lDetalhe = pcConsulta = "DETALHE".
        cPermitidos = IF lDetalhe THEN "codEstabel,tipoDocumento,chaveXml" ELSE
            "codEstabel,dataIni,dataFim,tipoDocumento,tipoData,situacao,emitente,numero,serie,embalagens,limite,aposXml".
        nomes = poFiltros:GetNames().
        DO i = 1 TO EXTENT(nomes):
            IF LOOKUP(nomes[i],cPermitidos) = 0 THEN
                UNDO, THROW NEW Progress.Lang.AppError("CAMPO_NAO_PERMITIDO",0).
        END.
        ASSIGN cEstabelXml = xTexto(poFiltros,"codEstabel","")
            cTipo = xTexto(poFiltros,"tipoDocumento",IF lDetalhe THEN "" ELSE "TODOS")
            cTipoData = xTexto(poFiltros,"tipoData","EMISSAO")
            cEmbalagens = xTexto(poFiltros,"embalagens","TODOS")
            cSituacao = xTexto(poFiltros,"situacao","")
            cNumero = xTexto(poFiltros,"numero","") cSerie = xTexto(poFiltros,"serie","")
            cChave = xTexto(poFiltros,"chaveXml","")
            cCursor = xTexto(poFiltros,"aposXml","")
            iEmitente = xInteiro(xTexto(poFiltros,"emitente","0"))
            iLimite = xInteiro(xTexto(poFiltros,"limite","20")).
        IF cEstabelXml = "" OR NOT CAN-FIND(FIRST ttEmbEstabelPermitido
            WHERE ttEmbEstabelPermitido.cod-estabel = cEstabelXml) THEN
            UNDO, THROW NEW Progress.Lang.AppError("XML_INDISPONIVEL",0).
        IF NOT CONNECTED("mgind") OR NOT CONNECTED("mgmov") OR
            NOT CONNECTED("mgcad") OR NOT CONNECTED("mgesp") THEN
            UNDO, THROW NEW Progress.Lang.AppError("BANCO_NAO_CONECTADO",0).
        IF LOOKUP(cTipo,IF lDetalhe THEN "NFE,CTE,NFSE" ELSE "TODOS,NFE,CTE,NFSE") = 0 OR
            LOOKUP(cTipoData,"EMISSAO,TRANSACAO") = 0 OR LOOKUP(cEmbalagens,"TODOS,COM,SEM") = 0 OR
            LENGTH(cEstabelXml) > 5 OR LENGTH(cNumero) > 16 OR LENGTH(cSerie) > 5 OR
            LENGTH(cChave) > 100 OR iEmitente < 0 OR
            (cSituacao <> "" AND xInteiro(cSituacao) > 99) THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        IF iLimite < 1 OR iLimite > 100 THEN
            UNDO, THROW NEW Progress.Lang.AppError("LIMITE_INVALIDO",0).
        IF lDetalhe THEN DO:
            IF cChave = "" THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        END.
        ELSE DO:
            ASSIGN dtIni = xData(xTexto(poFiltros,"dataIni","")) dtFim = xData(xTexto(poFiltros,"dataFim","")).
            IF dtIni = ? OR dtFim = ? OR dtIni > dtFim OR dtFim - dtIni > 365 THEN
                UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
            IF cCursor <> "" THEN DO:
                dtCursor = xData(SUBSTRING(cCursor,1,10)).
                cIdCursor = SUBSTRING(cCursor,12).
                IF LENGTH(cCursor) > 120 OR dtCursor = ? OR SUBSTRING(cCursor,11,1) <> "|" OR
                    LENGTH(cIdCursor) < 5 OR INDEX(cIdCursor,"|") = 0 THEN
                    UNDO, THROW NEW Progress.Lang.AppError("CURSOR_INVALIDO",0).
            END.
        END.
        IF cTipo = "TODOS" OR cTipo = "NFE" THEN DO:
            FOR EACH bNfe NO-LOCK WHERE bNfe.cod-estabel = cEstabelXml
                AND ((lDetalhe AND bNfe.ch-acesso-comp-nfe = cChave) OR
                    (NOT lDetalhe AND ((cTipoData = "EMISSAO" AND bNfe.dt-emissao >= dtIni AND bNfe.dt-emissao <= dtFim) OR
                      (cTipoData = "TRANSACAO" AND bNfe.dt-transacao >= dtIni AND bNfe.dt-transacao <= dtFim)))):
                RUN xContar.
                IF NOT lDetalhe AND ((iEmitente > 0 AND bNfe.cod-emitente <> iEmitente) OR
                    (cNumero <> "" AND bNfe.nro-docto <> cNumero) OR
                    (cSerie <> "" AND bNfe.serie-docto <> cSerie) OR
                    (cSituacao <> "" AND bNfe.idi-situacao <> xInteiro(cSituacao))) THEN NEXT.
                dtOrdem = IF cTipoData = "EMISSAO" THEN bNfe.dt-emissao ELSE bNfe.dt-transacao.
                o = xCab("NFE",bNfe.ch-acesso-comp-nfe,bNfe.idi-orig-trad,bNfe.nro-docto,bNfe.serie-docto,
                    bNfe.cod-emitente,bNfe.razao-social,bNfe.dt-emissao,bNfe.dt-transacao,bNfe.idi-situacao,bNfe.valor-total).
                RUN xGuardar(INPUT o, INPUT dtOrdem).
            END.
        END.
        IF cTipo = "TODOS" OR cTipo = "CTE" THEN DO:
            FOR EACH bCte NO-LOCK WHERE bCte.cod-estabel = cEstabelXml
                AND ((lDetalhe AND bCte.cod-aces-comp-nfe = cChave) OR
                    (NOT lDetalhe AND ((cTipoData = "EMISSAO" AND bCte.dt-emissao >= dtIni AND bCte.dt-emissao <= dtFim) OR
                      (cTipoData = "TRANSACAO" AND bCte.dt-trans >= dtIni AND bCte.dt-trans <= dtFim)))):
                RUN xContar.
                IF NOT lDetalhe AND ((iEmitente > 0 AND bCte.cod-emitente <> iEmitente) OR
                    (cNumero <> "" AND bCte.nro-docto <> cNumero) OR
                    (cSerie <> "" AND bCte.serie-docto <> cSerie) OR
                    (cSituacao <> "" AND bCte.idi-situacao <> xInteiro(cSituacao))) THEN NEXT.
                dtOrdem = IF cTipoData = "EMISSAO" THEN bCte.dt-emissao ELSE bCte.dt-trans.
                o = xCab("CTE",bCte.cod-aces-comp-nfe,bCte.idi-orig-trad,bCte.nro-docto,bCte.serie-docto,
                    bCte.cod-emitente,"",bCte.dt-emissao,bCte.dt-trans,bCte.idi-situacao,?).
                o:Add("valorMercadorias",bCte.val-tot-mercad).
                RUN xGuardar(INPUT o, INPUT dtOrdem).
            END.
        END.
        IF cTipo = "TODOS" OR cTipo = "NFSE" THEN DO:
            FIND FIRST bEstXml NO-LOCK WHERE bEstXml.cod-estabel = cEstabelXml NO-ERROR.
            IF NOT AVAILABLE bEstXml THEN UNDO, THROW NEW Progress.Lang.AppError("AUTORIZACAO_NFSE_NAO_COMPROVADA",0).
            cFiscalXml = xFiscal(bEstXml.cgc).
            IF (LENGTH(cFiscalXml) <> 11 AND LENGTH(cFiscalXml) <> 14) OR
                cFiscalXml = FILL(SUBSTRING(cFiscalXml,1,1),LENGTH(cFiscalXml)) THEN
                UNDO, THROW NEW Progress.Lang.AppError("AUTORIZACAO_NFSE_NAO_COMPROVADA",0).
            FOR EACH bEstFiscal NO-LOCK WHERE bEstFiscal.cgc <> "":
                IF xFiscal(bEstFiscal.cgc) = cFiscalXml THEN iEstabelFiscal = iEstabelFiscal + 1.
                IF iEstabelFiscal > 1 THEN LEAVE.
            END.
            IF iEstabelFiscal <> 1 THEN UNDO, THROW NEW Progress.Lang.AppError("AUTORIZACAO_NFSE_NAO_COMPROVADA",0).
            FOR EACH bNfse NO-LOCK WHERE
                ((LENGTH(cFiscalXml) = 14 AND xFiscal(bNfse.cod-cnpj-tomador) = cFiscalXml) OR
                 (LENGTH(cFiscalXml) = 11 AND xFiscal(bNfse.cod-cpf-tomador) = cFiscalXml))
                AND ((lDetalhe AND bNfse.cod-chave-aces-nfse = cChave) OR
                    (NOT lDetalhe AND ((cTipoData = "EMISSAO" AND bNfse.dt-emissao >= dtIni AND bNfse.dt-emissao <= dtFim) OR
                      (cTipoData = "TRANSACAO" AND bNfse.dt-transacao >= dtIni AND bNfse.dt-transacao <= dtFim)))):
                RUN xContar.
                IF NOT lDetalhe AND ((iEmitente > 0 AND bNfse.cod-emitente <> iEmitente) OR
                    (cNumero <> "" AND bNfse.nro-docto <> cNumero) OR
                    (cSerie <> "" AND bNfse.serie-docto <> cSerie) OR
                    (cSituacao <> "" AND bNfse.idi-situacao <> xInteiro(cSituacao))) THEN NEXT.
                dtOrdem = IF cTipoData = "EMISSAO" THEN bNfse.dt-emissao ELSE bNfse.dt-transacao.
                o = xCab("NFSE",bNfse.cod-chave-aces-nfse,bNfse.idi-orig-trad,bNfse.nro-docto,bNfse.serie-docto,
                    bNfse.cod-emitente,bNfse.des-razao-social-prestdor,bNfse.dt-emissao,bNfse.dt-transacao,bNfse.idi-situacao,bNfse.val-servico).
                RUN xGuardar(INPUT o, INPUT dtOrdem).
            END.
        END.
        IF lDetalhe THEN DO:
            FIND FIRST ttXml NO-ERROR.
            IF NOT AVAILABLE ttXml THEN UNDO, THROW NEW Progress.Lang.AppError("XML_INDISPONIVEL",0).
            o = xGrupo().
            a = o:GetJsonArray("representacoes").
            poResposta:Add("tipoDocumento",ttXml.tipo). poResposta:Add("chaveXml",ttXml.chave).
            poResposta:Add("codEstabel",cEstabelXml).
            poResposta:Add("recebimentos",o:GetJsonArray("recebimentos")).
            poResposta:Add("temEmbalagens",lTemEmbXml).
            iTotal = a:Length.
        END.
        ELSE DO:
          FOR EACH ttXml BY ttXml.dataOrdem DESCENDING BY ttXml.identidade:
            IF cCursor <> "" AND NOT (ttXml.dataOrdem < dtCursor OR
                (ttXml.dataOrdem = dtCursor AND ttXml.identidade > cIdCursor)) THEN NEXT.
            o = xGrupo().
            IF (cEmbalagens = "COM" AND (lTemEmbXml = ? OR lTemEmbXml = NO)) OR
               (cEmbalagens = "SEM" AND (lTemEmbXml = ? OR lTemEmbXml = YES)) THEN NEXT.
            IF iTotal = iLimite THEN DO: lMais = YES. LEAVE. END.
            a:Add(o). iTotal = iTotal + 1.
            cChave = xIso(ttXml.dataOrdem) + "|" + ttXml.identidade.
          END.
        END.
        CATCH falhaXml AS Progress.Lang.AppError:
            cErro = falhaXml:GetMessage(1).
        END CATCH.
        CATCH falhaTecnicaXml AS Progress.Lang.Error:
            cErro = "FALHA_CONSULTA_XML".
        END CATCH.
        FINALLY:
            IF VALID-HANDLE(hRecebXml) THEN DELETE PROCEDURE hRecebXml NO-ERROR.
        END FINALLY.
    END.
    IF cErro <> "" THEN ASSIGN poResposta = NEW JsonObject() a = NEW JsonArray() iTotal = 0 lMais = NO.
    poResposta:Add("sucesso",cErro = ""). poResposta:Add("codigoErro",cErro).
    poResposta:Add("mensagem",IF cErro = "" THEN "" ELSE "Confira filtros, permissao e disponibilidade da consulta XML.").
    poResposta:Add("dados",a). poResposta:Add("total",iTotal).
    poResposta:Add("temMais",lMais). poResposta:Add("proximoXml",IF lMais THEN cChave ELSE "").
END PROCEDURE.

PROCEDURE xContar:
    iLidosXml = iLidosXml + 1.
    IF iLidosXml > 5000 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA",0).
END PROCEDURE.
PROCEDURE xGuardar:
    DEFINE INPUT PARAMETER p AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER dt AS DATE NO-UNDO.
    DEFINE VARIABLE id AS CHARACTER NO-UNDO.
    id = p:GetCharacter("tipoDocumento") + "|" + p:GetCharacter("chaveXml").
    IF p:GetCharacter("chaveXml") = "" THEN
        UNDO, THROW NEW Progress.Lang.AppError("CHAVE_XML_INDISPONIVEL",0).
    FIND ttXml WHERE ttXml.identidade = id NO-ERROR.
    IF NOT AVAILABLE ttXml THEN DO:
        CREATE ttXml.
        ASSIGN ttXml.identidade = id ttXml.tipo = p:GetCharacter("tipoDocumento")
            ttXml.chave = p:GetCharacter("chaveXml") ttXml.dataOrdem = dt.
    END.
    ELSE IF dt > ttXml.dataOrdem THEN ttXml.dataOrdem = dt.
    CREATE ttXmlRep.
    ASSIGN ttXmlRep.identidade = id ttXmlRep.origem = p:GetInteger("representacao") ttXmlRep.cabecalho = p.
END PROCEDURE.
FUNCTION xGrupo RETURNS JsonObject ():
    DEFINE VARIABLE o AS JsonObject NO-UNDO.
    DEFINE VARIABLE aRep AS JsonArray NO-UNDO.
    DEFINE VARIABLE aDocs AS JsonArray NO-UNDO.
    DEFINE VARIABLE oFiltro AS JsonObject NO-UNDO.
    DEFINE VARIABLE oResp AS JsonObject NO-UNDO.
    DEFINE VARIABLE oCab AS JsonObject NO-UNDO.
    DEFINE VARIABLE cModulo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE lConhecido AS LOGICAL NO-UNDO INITIAL YES.
    DEFINE VARIABLE lCom AS LOGICAL NO-UNDO.
    ASSIGN o = NEW JsonObject() aRep = NEW JsonArray() aDocs = NEW JsonArray().
    FOR EACH ttXmlRep WHERE ttXmlRep.identidade = ttXml.identidade BY ttXmlRep.origem:
        aRep:Add(CAST(ttXmlRep.cabecalho,JsonObject)).
    END.
    FOR EACH bDocXml NO-LOCK WHERE bDocXml.cod-chave-aces-nf-eletro = ttXml.chave
        AND bDocXml.cod-estabel = cEstabelXml:
        n = n + 1.
        IF n > 100 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA",0).
        IF NOT VALID-HANDLE(hRecebXml) THEN DO:
            cModulo = SEARCH("esp/api/v1/contr-emb-recebimentos.r").
            IF cModulo = ? THEN cModulo = SEARCH("_bp/api/ET-01_TESTE/fontes/progress/contr-emb-recebimentos.r").
            IF cModulo = ? THEN cModulo = SEARCH("fontes/progress/contr-emb-recebimentos.r").
            IF cModulo = ? THEN UNDO, THROW NEW Progress.Lang.AppError("RECEBIMENTOS_NAO_LOCALIZADO",0).
            RUN VALUE(cModulo) PERSISTENT SET hRecebXml.
        END.
        oFiltro = NEW JsonObject().
        oFiltro:Add("codEstabel",cEstabelXml). oFiltro:Add("emitente",STRING(bDocXml.cod-emitente)).
        oFiltro:Add("serie",bDocXml.serie-docto). oFiltro:Add("numero",bDocXml.nro-docto).
        oFiltro:Add("natureza",bDocXml.nat-operacao). oFiltro:Add("limite","1").
        RUN consultarRecebimentos IN hRecebXml("EMBALAGENS", INPUT TABLE ttEmbEstabelPermitido, oFiltro, OUTPUT oResp).
        IF NOT oResp:GetLogical("sucesso") THEN
            UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_RECEBIMENTO_INDISPONIVEL",0).
        oCab = oResp:GetJsonObject("cabecalho").
        aDocs:Add(oCab).
        IF oCab:GetCharacter("situacaoControle") = "PROCESSAMENTO_PENDENTE" THEN lConhecido = NO.
        ELSE IF oCab:GetInteger("qtdEmbalagens") > 0 THEN lCom = YES.
    END.
    o:Add("tipoDocumento",ttXml.tipo). o:Add("chaveXml",ttXml.chave). o:Add("codEstabel",cEstabelXml).
    o:Add("representacoes",aRep). o:Add("recebimentos",aDocs).
    lTemEmbXml = IF lCom THEN YES ELSE IF n = 0 OR NOT lConhecido THEN ? ELSE NO.
    o:Add("temEmbalagens",lTemEmbXml).
    RETURN o.
END FUNCTION.
FUNCTION xCab RETURNS JsonObject (INPUT tipo AS CHARACTER, INPUT chave AS CHARACTER,
    INPUT origem AS INTEGER, INPUT numero AS CHARACTER, INPUT serie AS CHARACTER,
    INPUT emitente AS INTEGER, INPUT nome AS CHARACTER, INPUT emissao AS DATE,
    INPUT transacao AS DATE, INPUT situacao AS INTEGER, INPUT valor AS DECIMAL):
    DEFINE VARIABLE o AS JsonObject NO-UNDO.
    IF nome = "" OR nome = ? THEN DO:
        FIND FIRST bEmitXml NO-LOCK WHERE bEmitXml.cod-emitente = emitente NO-ERROR.
        IF AVAILABLE bEmitXml THEN nome = bEmitXml.nome-emit.
    END.
    o = NEW JsonObject().
    o:Add("tipoDocumento",tipo). o:Add("chaveXml",chave). o:Add("codEstabel",cEstabelXml).
    o:Add("representacao",origem). o:Add("numero",numero). o:Add("serie",serie).
    o:Add("emitente",STRING(emitente)). o:Add("descricaoEmitente",nome).
    o:Add("dataEmissao",emissao). o:Add("dataTransacao",transacao).
    o:Add("situacao",situacao). o:Add("descricaoSituacao",xSituacao(tipo,situacao)).
    o:Add("valorDocumento",valor).
    RETURN o.
END FUNCTION.
FUNCTION xSituacao RETURNS CHARACTER (INPUT tipo AS CHARACTER, INPUT codigo AS INTEGER):
    /* Codigos NF-e/CT-e publicados no fluxo TC2. NFSe nao herda por suposicao. */
    IF tipo <> "NFSE" THEN DO:
      CASE codigo:
        WHEN 1 THEN RETURN "Digitada no recebimento fiscal".
        WHEN 2 THEN RETURN "Erro de negocio".
        WHEN 3 THEN RETURN "Atualizada no recebimento fiscal".
        WHEN 4 THEN RETURN "Eliminada no recebimento".
        WHEN 5 THEN RETURN "Cancelada".
        WHEN 6 THEN RETURN "Digitada no recebimento fisico".
        WHEN 7 THEN RETURN "Atualizada no recebimento fisico".
        WHEN 8 THEN RETURN "Inutilizada".
        WHEN 9 THEN RETURN "Em validacao".
      END CASE.
    END.
    RETURN "Situacao " + STRING(codigo) + " (descricao a confirmar)".
END FUNCTION.
FUNCTION xTexto RETURNS CHARACTER (INPUT p AS JsonObject, INPUT nome AS CHARACTER, INPUT padrao AS CHARACTER):
    DEFINE VARIABLE valor AS CHARACTER NO-UNDO.
    IF NOT p:Has(nome) THEN RETURN padrao.
    valor = p:GetCharacter(nome) NO-ERROR.
    IF ERROR-STATUS:ERROR OR valor = ? OR LENGTH(valor) > 200 THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
    RETURN TRIM(valor).
END FUNCTION.
FUNCTION xInteiro RETURNS INTEGER (INPUT valor AS CHARACTER):
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    IF valor = "" THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
    DO i = 1 TO LENGTH(valor):
        IF INDEX("0123456789",SUBSTRING(valor,i,1)) = 0 THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
    END.
    n = INTEGER(valor) NO-ERROR.
    IF ERROR-STATUS:ERROR OR n = ? THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
    RETURN n.
END FUNCTION.
FUNCTION xData RETURNS DATE (INPUT valor AS CHARACTER):
    DEFINE VARIABLE d AS DATE NO-UNDO.
    IF LENGTH(valor) <> 10 OR SUBSTRING(valor,5,1) <> "-" OR SUBSTRING(valor,8,1) <> "-" THEN RETURN ?.
    d = DATE(INTEGER(SUBSTRING(valor,6,2)),INTEGER(SUBSTRING(valor,9,2)),INTEGER(SUBSTRING(valor,1,4))) NO-ERROR.
    IF ERROR-STATUS:ERROR OR d = ? THEN RETURN ?.
    IF xIso(d) <> valor THEN RETURN ?.
    RETURN d.
END FUNCTION.
FUNCTION xIso RETURNS CHARACTER (INPUT valor AS DATE):
    RETURN STRING(YEAR(valor),"9999") + "-" + STRING(MONTH(valor),"99") + "-" + STRING(DAY(valor),"99").
END FUNCTION.

FUNCTION xFiscal RETURNS CHARACTER (INPUT valor AS CHARACTER):
    DEFINE VARIABLE resultado AS CHARACTER NO-UNDO.
    DEFINE VARIABLE caractere AS CHARACTER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    IF valor = ? THEN RETURN "".
    DO i = 1 TO LENGTH(valor):
        caractere = SUBSTRING(valor,i,1).
        IF INDEX("0123456789",caractere) > 0 THEN resultado = resultado + caractere.
        ELSE IF INDEX("./- ",caractere) = 0 THEN RETURN "".
    END.
    RETURN resultado.
END FUNCTION.
