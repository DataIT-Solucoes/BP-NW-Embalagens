/* Consulta propria de XML; contexto confiavel reconstruido pelo Dataset. */
PROCEDURE pi-xml-lista:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piXmlConsulta(INPUT oInput, INPUT "LISTA", OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-xml-detalhe:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piXmlConsulta(INPUT oInput, INPUT "DETALHE", OUTPUT oOutput).
END PROCEDURE.
PROCEDURE piXmlConsulta:
    DEFINE INPUT PARAMETER poInput AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER pcConsulta AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER poOutput AS JsonObject NO-UNDO.
    DEFINE VARIABLE parser AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE queryXml AS JsonObject NO-UNDO.
    DEFINE VARIABLE filtrosXml AS JsonObject NO-UNDO.
    DEFINE VARIABLE camposXml AS CHARACTER NO-UNDO.
    DEFINE VARIABLE nomesXml AS CHARACTER EXTENT NO-UNDO.
    DEFINE VARIABLE nomeXml AS CHARACTER NO-UNDO.
    DEFINE VARIABLE moduloXml AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hXml AS HANDLE NO-UNDO.
    DEFINE VARIABLE nXml AS INTEGER NO-UNDO.
    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    DO ON ERROR UNDO, THROW:
        ASSIGN parser = NEW JsonAPIRequestParser(poInput) queryXml = parser:GetQueryParams()
            filtrosXml = NEW JsonObject().
        IF fnQueryTextoEstrito(queryXml,"usuario","") = "" THEN DO:
            RUN piRespostaErro(OUTPUT poOutput,"USUARIO_NAO_INFORMADO","Usuario da sessao obrigatorio."). RETURN.
        END.
        RUN piCarregarEstabelecimentosQuery(INPUT queryXml).
        camposXml = IF pcConsulta = "DETALHE" THEN "codEstabel,tipoDocumento,chaveXml" ELSE
            "codEstabel,dataIni,dataFim,tipoDocumento,tipoData,situacao,emitente,numero,serie,embalagens,limite,aposXml".
        nomesXml = queryXml:GetNames().
        DO nXml = 1 TO EXTENT(nomesXml):
            nomeXml = nomesXml[nXml].
            IF LOOKUP(nomeXml,camposXml + ",usuario,estabelecimentoPermitido") = 0 THEN DO:
                RUN piRespostaErro(OUTPUT poOutput,"CAMPO_NAO_PERMITIDO","Campo nao permitido nesta consulta."). RETURN.
            END.
        END.
        DO nXml = 1 TO NUM-ENTRIES(camposXml):
            nomeXml = ENTRY(nXml,camposXml).
            IF queryXml:Has(nomeXml) THEN filtrosXml:Add(nomeXml,fnQueryTextoEstrito(queryXml,nomeXml,"")).
        END.
        moduloXml = SEARCH("esp/api/v1/contr-emb-xml.r").
        IF moduloXml = ? THEN moduloXml = SEARCH("_bp/api/ET-01_TESTE/fontes/progress/contr-emb-xml.r").
        IF moduloXml = ? THEN moduloXml = SEARCH("fontes/progress/contr-emb-xml.r").
        IF moduloXml = ? THEN DO:
            RUN piRespostaErro(OUTPUT poOutput,"XML_NAO_LOCALIZADO","Modulo de consulta XML nao localizado."). RETURN.
        END.
        RUN VALUE(moduloXml) PERSISTENT SET hXml.
        RUN consultarXmls IN hXml(INPUT pcConsulta, INPUT TABLE ttEmbEstabelPermitido,
            INPUT filtrosXml, OUTPUT poOutput).
        CATCH falhaXmlRest AS Progress.Lang.Error:
            RUN piRespostaErro(OUTPUT poOutput,"FALHA_CONSULTA_XML","Nao foi possivel consultar os XMLs.").
        END CATCH.
        FINALLY:
            IF VALID-HANDLE(hXml) THEN DELETE PROCEDURE hXml NO-ERROR.
            EMPTY TEMP-TABLE ttEmbEstabelPermitido.
        END FINALLY.
    END.
END PROCEDURE.
