/* DT134: edicao parcial, cancelamento e reabertura; DT125 preservado. */
PROCEDURE pi-editar-bag:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piBagOperacional(INPUT oInput,"EDITAR",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-evento-bag:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piBagOperacional(INPUT oInput,"EVENTO",OUTPUT oOutput).
END PROCEDURE.
/* DT123. Contexto reconstruido pelo Dataset/servico autorizado. */
PROCEDURE pi-abrir-bag:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piBagOperacional(INPUT oInput,"ABRIR",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-conteudo-bag-comando:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piBagOperacional(INPUT oInput,"CONTEUDO",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-elegiveis-bag:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piBagOperacional(INPUT oInput,"ELEGIVEIS",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE pi-historico-bag:
    DEFINE INPUT PARAMETER oInput AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.
    RUN piBagOperacional(INPUT oInput,"HISTORICO",OUTPUT oOutput).
END PROCEDURE.
PROCEDURE piBagOperacional:
    DEFINE INPUT PARAMETER entrada AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER modo AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    DEFINE VARIABLE pedido AS JsonAPIRequestParser NO-UNDO.
    DEFINE VARIABLE corpo AS JsonObject NO-UNDO.
    DEFINE VARIABLE consulta AS JsonObject NO-UNDO.
    DEFINE VARIABLE usuario AS CHARACTER NO-UNDO.
    DEFINE VARIABLE acao AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE VARIABLE modulo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE idBag AS INTEGER NO-UNDO.
    DEFINE VARIABLE apos AS INTEGER NO-UNDO.
    DEFINE VARIABLE limite AS INTEGER NO-UNDO.
    DEFINE VARIABLE hBag AS HANDLE NO-UNDO.
    EMPTY TEMP-TABLE ttEmbEstabelPermitido.
    DO ON ERROR UNDO, THROW:
        pedido = NEW JsonAPIRequestParser(entrada).
        IF modo = "ABRIR" OR modo = "CONTEUDO" OR modo = "EVENTO" OR modo = "EDITAR" THEN DO:
            corpo = pedido:GetPayload().
            IF corpo = ? THEN DO:
                RUN piRespostaErro(OUTPUT resposta,"CORPO_INVALIDO","Informe um objeto JSON."). RETURN.
            END.
            usuario = fApiTexto(corpo,"usuario","").
            RUN piCarregarEstabelecimentosBody(INPUT corpo).
            acao = IF modo = "ABRIR" THEN "ABRIR" ELSE IF modo = "EDITAR" THEN "EDITAR" ELSE fApiTexto(corpo,"acao","").
            IF modo = "EVENTO" AND LOOKUP(acao,"LACRAR,ENVIAR,CANCELAR,REABRIR") = 0 THEN DO:
                RUN piRespostaErro(OUTPUT resposta,"COMANDO_INVALIDO","Informe LACRAR, ENVIAR, CANCELAR ou REABRIR."). RETURN.
            END.
            IF modo = "CONTEUDO" AND LOOKUP(acao,"INCLUIR,RETIRAR") = 0 THEN DO:
                RUN piRespostaErro(OUTPUT resposta,"COMANDO_INVALIDO","Informe INCLUIR ou RETIRAR."). RETURN.
            END.
        END.
        ELSE DO:
            consulta = pedido:GetQueryParams().
            ASSIGN usuario = fnQueryTextoEstrito(consulta,"usuario","")
                idBag = fnQueryNumeroEstrito(consulta,"idBag",0)
                apos = fnQueryNumeroEstrito(consulta,"aposId",0)
                limite = fnQueryNumeroEstrito(consulta,"limite",20).
            RUN piCarregarEstabelecimentosQuery(INPUT consulta).
            IF idBag = ? OR idBag <= 0 OR apos = ? OR apos < 0 OR limite = ? OR limite < 1 OR limite > 20 THEN DO:
                RUN piRespostaErro(OUTPUT resposta,"FILTRO_INVALIDO","Confira ID, cursor e limite1..20."). RETURN.
            END.
        END.
        IF usuario = ? OR usuario = "" OR LENGTH(usuario) > 128 OR NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN DO:
            RUN piRespostaErro(OUTPUT resposta,"SEM_PERMISSAO","Contexto autorizado obrigatorio."). RETURN.
        END.
        modulo = SEARCH("esp/api/v1/contr-emb-bags.r").
        IF modulo = ? THEN DO:
            RUN piRespostaErro(OUTPUT resposta,"BAGS_NAO_LOCALIZADO","Modulo de Bags nao localizado."). RETURN.
        END.
        RUN VALUE(modulo) PERSISTENT SET hBag.
        IF modo = "ABRIR" OR modo = "CONTEUDO" OR modo = "EVENTO" OR modo = "EDITAR" THEN
            RUN executarComandoBag IN hBag(INPUT TABLE ttEmbEstabelPermitido,INPUT corpo,INPUT acao,OUTPUT resposta).
        ELSE RUN consultarBagOperacional IN hBag(INPUT TABLE ttEmbEstabelPermitido,INPUT idBag,INPUT modo,INPUT apos,INPUT limite,OUTPUT resposta).
        CATCH falha AS Progress.Lang.Error:
            RUN piRespostaErro(OUTPUT resposta,"FALHA_BAG","Nao foi possivel concluir a solicitacao.").
        END CATCH.
        FINALLY:
            IF VALID-HANDLE(hBag) THEN DELETE PROCEDURE hBag NO-ERROR.
            EMPTY TEMP-TABLE ttEmbEstabelPermitido.
        END FINALLY.
    END.
END PROCEDURE.
