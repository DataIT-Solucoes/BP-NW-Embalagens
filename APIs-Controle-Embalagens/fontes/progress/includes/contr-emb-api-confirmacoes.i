/* DT121. Contexto de autorizacao continua vindo do servico Fluig autorizado. */
PROCEDURE pi-confirmar-etiqueta:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piManutencaoConfirmacao(INPUT oInput,INPUT "COMANDO",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-situacao-etiqueta:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piManutencaoConfirmacao(INPUT oInput,INPUT "SITUACAO",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-historico-etiqueta:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piManutencaoConfirmacao(INPUT oInput,INPUT "HISTORICO",OUTPUT oOutput).
END PROCEDURE.

PROCEDURE piManutencaoConfirmacao:
    DEFINE INPUT PARAMETER entrada AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER modo AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    DEFINE VARIABLE pedido AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE corpo AS JsonObject NO-UNDO.
    DEFINE VARIABLE consulta AS JsonObject NO-UNDO.
    DEFINE VARIABLE modulo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE usuario AS CHARACTER NO-UNDO.
    DEFINE VARIABLE estab AS CHARACTER NO-UNDO.
    DEFINE VARIABLE apos AS CHARACTER NO-UNDO.
    DEFINE VARIABLE etiqueta AS INTEGER NO-UNDO.
    DEFINE VARIABLE limite AS INTEGER NO-UNDO.
    DEFINE VARIABLE hMan AS HANDLE NO-UNDO.
    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    DO ON ERROR UNDO, THROW:
        pedido = NEW JsonAPIRequestParser(entrada).
        IF modo = "COMANDO" THEN DO:
            corpo = pedido:GetPayload().
            IF corpo = ? THEN DO:
                RUN piRespostaErro(OUTPUT resposta,"CORPO_INVALIDO","Informe um objeto JSON."). RETURN.
            END.
            usuario = fApiTexto(corpo,"usuario","").
            RUN piCarregarEstabelecimentosBody(INPUT corpo).
        END.
        ELSE DO:
            consulta = pedido:GetQueryParams().
            ASSIGN usuario = fnQueryTextoEstrito(consulta,"usuario","")
                estab = fnQueryTextoEstrito(consulta,"codEstabel","")
                etiqueta = fnQueryNumeroEstrito(consulta,"idEtiqueta",0)
                limite = fnQueryNumeroEstrito(consulta,"limite",20)
                apos = fnQueryTextoEstrito(consulta,"aposRegistro","").
            RUN piCarregarEstabelecimentosQuery(INPUT consulta).
            IF estab = ? OR estab = "" OR etiqueta = ? OR etiqueta <= 0 OR
               limite = ? OR limite < 1 OR limite > 100 OR apos = ? THEN DO:
                RUN piRespostaErro(OUTPUT resposta,"FILTRO_INVALIDO","Confira identidade, cursor e limite."). RETURN.
            END.
        END.
        IF usuario = ? OR usuario = "" OR LENGTH(usuario) > 128 OR
           NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN DO:
            RUN piRespostaErro(OUTPUT resposta,"SEM_PERMISSAO","Contexto autorizado obrigatorio."). RETURN.
        END.
        modulo = SEARCH("esp/api/v1/contr-emb-manutencao.r").
        IF modulo = ? THEN DO:
            RUN piRespostaErro(OUTPUT resposta,"MANUTENCAO_NAO_LOCALIZADA","Modulo de confirmacoes nao localizado."). RETURN.
        END.
        RUN VALUE(modulo) PERSISTENT SET hMan.
        CASE modo:
            WHEN "COMANDO" THEN RUN confirmarEtiqueta IN hMan(INPUT TABLE ttEmbEstabelPermitido,INPUT corpo,OUTPUT resposta).
            WHEN "SITUACAO" THEN RUN consultarSituacao IN hMan(INPUT TABLE ttEmbEstabelPermitido,INPUT estab,INPUT etiqueta,OUTPUT resposta).
            WHEN "HISTORICO" THEN RUN consultarHistorico IN hMan(INPUT TABLE ttEmbEstabelPermitido,INPUT estab,INPUT etiqueta,INPUT apos,INPUT limite,OUTPUT resposta).
        END CASE.
        CATCH falha AS Progress.Lang.Error:
            RUN piRespostaErro(OUTPUT resposta,"FALHA_MANUTENCAO","Nao foi possivel concluir a solicitacao.").
        END CATCH.
        FINALLY:
            IF VALID-HANDLE(hMan) THEN DELETE PROCEDURE hMan NO-ERROR.
            EMPTY TEMP-TABLE ttEmbEstabelPermitido.
        END FINALLY.
    END.
END PROCEDURE.
