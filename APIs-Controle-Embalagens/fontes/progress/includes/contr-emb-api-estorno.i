/* DT126. Contexto autorizado; conta e unidade de negocio mantidas no nucleo. */
PROCEDURE pi-estornar-etiqueta:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piAjusteEtiquetaRest(INPUT oInput,INPUT "ESTORNAR",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-inutilizar-etiqueta:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piAjusteEtiquetaRest(INPUT oInput,INPUT "INUTILIZAR",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-registrar-perda:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piAjusteEtiquetaRest(INPUT oInput,INPUT "REGISTRAR_PERDA_EXTRAVIO",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE piAjusteEtiquetaRest:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER modo AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    DEFINE VARIABLE parser AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE corpo AS JsonObject NO-UNDO.
    DEFINE VARIABLE cModuloEstorno AS CHARACTER NO-UNDO.
    DEFINE VARIABLE usuario AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hEstorno AS HANDLE NO-UNDO.
    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    DO ON ERROR UNDO, THROW:
        parser = NEW JsonAPIRequestParser(oInput). corpo = parser:GetPayload().
        IF corpo = ? THEN DO:
            RUN piRespostaErro(OUTPUT oOutput,"CORPO_INVALIDO","Informe um objeto JSON."). RETURN.
        END.
        usuario = fApiTexto(corpo,"usuario","").
        RUN piCarregarEstabelecimentosBody(INPUT corpo).
        IF usuario = ? OR usuario = "" OR LENGTH(usuario) > 128 OR NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN DO:
            RUN piRespostaErro(OUTPUT oOutput,"SEM_PERMISSAO","Contexto autorizado obrigatorio."). RETURN.
        END.
        cModuloEstorno = SEARCH("esp/api/v1/contr-emb-estorno.r").
        IF cModuloEstorno = ? THEN DO:
            RUN piRespostaErro(OUTPUT oOutput,"ESTORNO_NAO_LOCALIZADO","Modulo de estorno nao localizado."). RETURN.
        END.
        RUN VALUE(cModuloEstorno) PERSISTENT SET hEstorno.
        IF modo = "REGISTRAR_PERDA_EXTRAVIO" THEN
            RUN registrarPerdaEtiqueta IN hEstorno(INPUT TABLE ttEmbEstabelPermitido,INPUT corpo,OUTPUT oOutput).
        ELSE IF modo = "INUTILIZAR" THEN
            RUN inutilizarEtiqueta IN hEstorno(INPUT TABLE ttEmbEstabelPermitido,INPUT corpo,OUTPUT oOutput).
        ELSE RUN estornarEtiqueta IN hEstorno(INPUT TABLE ttEmbEstabelPermitido,INPUT corpo,OUTPUT oOutput).
        CATCH falha AS Progress.Lang.Error:
            RUN piRespostaErro(OUTPUT oOutput,
                IF modo = "REGISTRAR_PERDA_EXTRAVIO" THEN "FALHA_PERDA_EXTRAVIO" ELSE IF modo = "INUTILIZAR" THEN "FALHA_INUTILIZACAO" ELSE "FALHA_ESTORNO",
                "Nao foi possivel concluir o comando da etiqueta.").
        END CATCH.
        FINALLY:
            IF VALID-HANDLE(hEstorno) THEN DELETE PROCEDURE hEstorno NO-ERROR.
            EMPTY TEMP-TABLE ttEmbEstabelPermitido.
        END FINALLY.
    END.
END PROCEDURE.
