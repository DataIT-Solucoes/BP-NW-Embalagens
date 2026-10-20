/* DT121: confirmacoes e linha do tempo. Sem escrita no estoque padrao. */
USING Progress.Json.ObjectModel.*.
{fontes/progress/contr-emb.i}
{fontes/progress/includes/contr-emb-confirmacao-comum.i}

DEFINE TEMP-TABLE ttLinhaTempo NO-UNDO
    FIELD cursor-registro AS CHARACTER
    FIELD data-registro AS DATETIME-TZ
    FIELD categoria AS CHARACTER
    FIELD evento-ordem AS INTEGER
    FIELD id-registro AS INTEGER
    FIELD objeto AS Progress.Lang.Object
    INDEX pk IS PRIMARY UNIQUE cursor-registro.

FUNCTION mParte RETURNS CHARACTER (INPUT pc AS CHARACTER):
    RETURN STRING(LENGTH(pc)) + ":" + pc.
END FUNCTION.
FUNCTION mTexto RETURNS CHARACTER (INPUT po AS JsonObject, INPUT pc AS CHARACTER, INPUT padrao AS CHARACTER):
    DEFINE VARIABLE c AS CHARACTER NO-UNDO.
    IF NOT po:Has(pc) THEN RETURN padrao.
    c = po:GetCharacter(pc) NO-ERROR.
    IF ERROR-STATUS:ERROR OR c = ? THEN RETURN ?.
    RETURN TRIM(c).
END FUNCTION.
FUNCTION mNumero RETURNS INTEGER (INPUT po AS JsonObject, INPUT pc AS CHARACTER):
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    i = po:GetInteger(pc) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN RETURN ?.
    RETURN i.
END FUNCTION.
FUNCTION mId RETURNS INTEGER (INPUT pc AS CHARACTER):
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    IF pc = ? OR pc = "" OR LENGTH(pc) > 10 THEN RETURN ?.
    DO i = 1 TO LENGTH(pc):
        IF INDEX("0123456789",SUBSTRING(pc,i,1)) = 0 THEN RETURN ?.
    END.
    n = INTEGER(pc) NO-ERROR.
    IF ERROR-STATUS:ERROR OR n = ? OR n <= 0 OR STRING(n) <> pc THEN RETURN ?.
    RETURN n.
END FUNCTION.
FUNCTION mCursor RETURNS CHARACTER (INPUT evento AS INTEGER, INPUT categoria AS CHARACTER, INPUT registro AS INTEGER):
    RETURN STRING(evento,"9999999999") + categoria + STRING(registro,"9999999999").
END FUNCTION.
FUNCTION mFalha RETURNS JsonObject (INPUT pcErro AS CHARACTER):
    DEFINE VARIABLE o AS JsonObject NO-UNDO.
    o = NEW JsonObject().
    o:Add("sucesso",NO). o:Add("codigoErro",pcErro).
    o:Add("mensagem","Confira contexto, versao e pre-requisitos da etiqueta.").
    RETURN o.
END FUNCTION.

PROCEDURE consultarSituacao:
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER pcEstabel AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piEtiqueta AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER po AS JsonObject NO-UNDO.
    DEFINE BUFFER bEt FOR mgesp.contr_emb_etiqueta.
    DEFINE VARIABLE cResumo AS CHARACTER NO-UNDO.
    po = mFalha("ETIQUETA_NAO_DISPONIVEL").
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = pcEstabel) THEN RETURN.
    FIND FIRST bEt NO-LOCK WHERE bEt.id-etiqueta = piEtiqueta AND bEt.cod-estabel = pcEstabel NO-ERROR.
    IF NOT AVAILABLE bEt THEN RETURN.
    ASSIGN po = NEW JsonObject() cResumo = fEmResumo(piEtiqueta).
    po:Add("sucesso",YES). po:Add("codigoErro",""). po:Add("mensagem","").
    po:Add("idEtiqueta",STRING(piEtiqueta)). po:Add("codEtiqueta",bEt.cod-etiqueta).
    po:Add("codEstabel",bEt.cod-estabel). po:Add("deposito",bEt.cod-depos).
    po:Add("situacao",bEt.situacao). po:Add("tipoLocal",bEt.tipo-local).
    po:Add("quantidadeAtual",bEt.qtidade-atu). po:Add("unidade",bEt.un).
    po:Add("versao",bEt.versao). po:Add("idBag",IF bEt.id-bag = ? THEN ? ELSE STRING(bEt.id-bag)).
    po:Add("impressaoConfirmada",fEmConfirmada(piEtiqueta,"CONFIRMACAO_IMPRESSAO","")).
    po:Add("recebimentoFisicoConfirmado",bEt.tipo-local = "ESTAB" AND
        fEmConfirmada(piEtiqueta,"RECEBIMENTO_FISICO",fEmContexto(piEtiqueta))).
    po:Add("situacaoApresentada",cResumo). po:Add("descricaoSituacao",fEmDescricao(cResumo)).
END PROCEDURE.

PROCEDURE confirmarEtiqueta:
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER p AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    DEFINE BUFFER bEt FOR mgesp.contr_emb_etiqueta.
    DEFINE BUFFER bEv FOR mgesp.contr_emb_evento.
    DEFINE BUFFER bGer FOR mgesp.contr_emb_evento.
    DEFINE BUFFER bAu FOR mgesp.contr_emb_audit.
    DEFINE VARIABLE usuario AS CHARACTER NO-UNDO.
    DEFINE VARIABLE estab AS CHARACTER NO-UNDO.
    DEFINE VARIABLE chave AS CHARACTER NO-UNDO.
    DEFINE VARIABLE acao AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE VARIABLE motivo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE identidade AS CHARACTER NO-UNDO.
    DEFINE VARIABLE conteudo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hashChave AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hashConteudo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE tipo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE contexto AS CHARACTER NO-UNDO.
    DEFINE VARIABLE antes AS CHARACTER NO-UNDO.
    DEFINE VARIABLE depois AS CHARACTER NO-UNDO.
    DEFINE VARIABLE erro AS CHARACTER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE etiqueta AS INTEGER NO-UNDO.
    DEFINE VARIABLE versao AS INTEGER NO-UNDO.
    DEFINE VARIABLE agora AS DATETIME-TZ NO-UNDO.
    DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
    DEFINE VARIABLE textoJson AS LONGCHAR NO-UNDO.
    DEFINE VARIABLE fotografia AS JsonObject NO-UNDO.
    /* CHARACTER do banco usa -cpinternal; atribuir ao LONGCHAR UTF-8 converte
       o texto antes do Parse, inclusive em sessoes ISO8859-1. */
    FIX-CODEPAGE(textoJson) = "UTF-8".
    resposta = mFalha("COMANDO_INVALIDO").
    IF p = ? THEN RETURN.
    ASSIGN usuario = mTexto(p,"usuario","") estab = mTexto(p,"codEstabel","")
        chave = mTexto(p,"chaveIdempotente","") acao = mTexto(p,"acao","")
        motivo = mTexto(p,"justificativa","") etiqueta = mId(mTexto(p,"idEtiqueta",""))
        versao = mNumero(p,"versao").
    IF usuario = ? OR usuario = "" OR LENGTH(usuario) > 128 OR estab = ? OR estab = "" OR
       chave = ? OR LENGTH(chave) < 1 OR LENGTH(chave) > 64 OR motivo = ? OR LENGTH(motivo) > 1000 OR
       etiqueta = ? OR versao = ? OR versao <= 0 OR acao = ? OR
       LOOKUP(acao,"CONFIRMAR_IMPRESSAO,RECEBER_FISICO") = 0 THEN RETURN.
    DO i = 1 TO LENGTH(chave):
        IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-",SUBSTRING(chave,i,1)) = 0 THEN RETURN.
    END.
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = estab) THEN DO:
        resposta = mFalha("SEM_PERMISSAO"). RETURN.
    END.
    ASSIGN identidade = mParte(estab) + mParte(usuario) + mParte(chave)
        conteudo = identidade + mParte(acao) + mParte(STRING(etiqueta)) + mParte(STRING(versao)) + mParte(motivo)
        hashChave = HEX-ENCODE(MESSAGE-DIGEST("SHA-256","MANUT_ETIQUETA|" + identidade))
        hashConteudo = HEX-ENCODE(MESSAGE-DIGEST("SHA-256",conteudo))
        tipo = IF acao = "CONFIRMAR_IMPRESSAO" THEN "CONFIRMACAO_IMPRESSAO" ELSE "RECEBIMENTO_FISICO".
    confirmar:
    DO TRANSACTION ON ERROR UNDO, THROW:
        FIND FIRST bEt WHERE bEt.id-etiqueta = etiqueta EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF LOCKED bEt THEN UNDO confirmar, THROW NEW Progress.Lang.AppError("ETIQUETA_BLOQUEADA",0).
        IF NOT AVAILABLE bEt THEN UNDO confirmar, THROW NEW Progress.Lang.AppError("ETIQUETA_NAO_DISPONIVEL",0).
        IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = bEt.cod-estabel) THEN
            UNDO confirmar, THROW NEW Progress.Lang.AppError("ETIQUETA_NAO_DISPONIVEL",0).
        FIND FIRST bEv NO-LOCK WHERE bEv.hash-chave = hashChave NO-ERROR.
        IF AVAILABLE bEv THEN DO:
            IF bEv.origem <> "MANUT_ETIQUETA" OR bEv.chave-evento <> identidade OR
               bEv.hash-conteudo <> hashConteudo OR bEv.tipo-evento <> tipo THEN
                UNDO confirmar, THROW NEW Progress.Lang.AppError("CONFLITO_IDEMPOTENCIA",0).
            IF bEv.situacao <> "CONCLUIDO" OR bEv.resultado = ? THEN
                UNDO confirmar, THROW NEW Progress.Lang.AppError("EVENTO_NAO_CONCLUIDO",0).
            ASSIGN parser = NEW ObjectModelParser() textoJson = bEv.resultado
                resposta = CAST(parser:Parse(textoJson),JsonObject).
            resposta:Set("repeticao",YES).
            LEAVE confirmar.
        END.
        IF bEt.cod-estabel <> estab THEN UNDO confirmar, THROW NEW Progress.Lang.AppError("ETIQUETA_NAO_DISPONIVEL",0).
        IF bEt.versao <> versao THEN UNDO confirmar, THROW NEW Progress.Lang.AppError("CONFLITO_VERSAO",0).
        IF bEt.tipo-controle <> "EMBALAGEM" OR bEt.situacao <> "ATIVA" THEN
            UNDO confirmar, THROW NEW Progress.Lang.AppError("ETIQUETA_INDISPONIVEL",0).
        FIND FIRST bGer NO-LOCK WHERE bGer.id-evento = bEt.id-evento-geracao NO-ERROR.
        IF NOT AVAILABLE bGer OR bGer.situacao <> "CONCLUIDO" THEN
            UNDO confirmar, THROW NEW Progress.Lang.AppError("GERACAO_NAO_CONFIRMADA",0).
        ASSIGN contexto = fEmContexto(etiqueta) antes = fEmResumo(etiqueta).
        IF contexto = "" THEN UNDO confirmar, THROW NEW Progress.Lang.AppError("CONTEXTO_NAO_COMPROVADO",0).
        IF acao = "RECEBER_FISICO" THEN DO:
            IF motivo = "" THEN UNDO confirmar, THROW NEW Progress.Lang.AppError("JUSTIFICATIVA_OBRIGATORIA",0).
            IF bEt.tipo-local <> "ESTAB" OR bEt.id-bag <> ? OR bEt.qtidade-atu <= 0 THEN
                UNDO confirmar, THROW NEW Progress.Lang.AppError("ETIQUETA_INDISPONIVEL",0).
            IF NOT fEmConfirmada(etiqueta,"CONFIRMACAO_IMPRESSAO","") THEN
                UNDO confirmar, THROW NEW Progress.Lang.AppError("ETIQUETA_NAO_IMPRESSA",0).
            IF fEmConfirmada(etiqueta,"RECEBIMENTO_FISICO",contexto) THEN
                UNDO confirmar, THROW NEW Progress.Lang.AppError("RECEBIMENTO_JA_CONFIRMADO",0).
        END.
        agora = NOW.
        fotografia = NEW JsonObject().
        fotografia:Add("idEtiqueta",STRING(etiqueta)). fotografia:Add("contexto",contexto).
        fotografia:Add("quantidade",bEt.qtidade-atu). fotografia:Add("situacao",bEt.situacao).
        fotografia:Add("tipoLocal",bEt.tipo-local). fotografia:Add("codEstabel",bEt.cod-estabel).
        fotografia:Add("deposito",IF bEt.cod-depos = ? THEN "" ELSE bEt.cod-depos).
        fotografia:Add("localizacao",IF bEt.cod-localiz = ? THEN "" ELSE bEt.cod-localiz).
        fotografia:Add("unidade",bEt.un).
        fotografia:Add("idBag",IF bEt.id-bag = ? THEN ? ELSE STRING(bEt.id-bag)).
        textoJson = fotografia:GetJsonText().
        CREATE bEv.
        ASSIGN bEv.id-evento = NEXT-VALUE(CONTR_EMB_EVENTO_ID_SEQ,mgesp)
            bEv.origem = "MANUT_ETIQUETA" bEv.chave-evento = identidade bEv.hash-chave = hashChave
            bEv.hash-conteudo = hashConteudo bEv.tipo-evento = tipo bEv.id-operacao = ?
            bEv.id-evento-origem = bEt.id-evento-geracao bEv.seq-ciclo = 1
            bEv.dt-evento = agora bEv.versao-contrato = 1 bEv.cod-estabel = estab
            bEv.tipo-docto = ? bEv.chave-docto = ? bEv.hash-docto = ? bEv.cod-emitente = ?
            bEv.cgc-emitente = ? bEv.serie = ? bEv.nro-docto = ? bEv.chave-acesso = ?
            bEv.nat-operacao = ? bEv.dt-emissao = ? bEv.situacao = "CONCLUIDO"
            bEv.tentativas = 1 bEv.dt-proxima-tent = ? bEv.token-execucao = ? bEv.dt-expira-exec = ?
            bEv.dt-conclusao = agora bEv.mensagem = "" bEv.dt-inclusao = agora bEv.dt-alteracao = agora
            bEv.usuario-inclusao = usuario bEv.usuario-alteracao = usuario bEv.versao = 1
            bEv.dados-evento = STRING(textoJson).
        CREATE bAu.
        ASSIGN bAu.id-audit = NEXT-VALUE(CONTR_EMB_AUDIT_ID_SEQ,mgesp) bAu.id-evento = bEv.id-evento
            bAu.nome-tabela = "contr_emb_etiqueta" bAu.chave-registro = STRING(etiqueta)
            bAu.acao = "ALTERACAO" bAu.versao-ant = versao bAu.versao-atu = versao
            bAu.dados-ant = "DT121|" + antes
            bAu.dados-atu = "DT121|" + tipo + "|" + contexto + "|"
            bAu.justificativa = motivo bAu.dt-registro = agora bAu.usuario = usuario.
        /* A confirmacao ja e visivel nesta transacao para compor o resumo. */
        VALIDATE bEv. VALIDATE bAu.
        depois = fEmResumo(etiqueta).
        bAu.dados-atu = bAu.dados-atu + depois.
        resposta = NEW JsonObject().
        resposta:Add("sucesso",YES). resposta:Add("codigoErro",""). resposta:Add("mensagem","").
        resposta:Add("repeticao",NO). resposta:Add("idEvento",STRING(bEv.id-evento)).
        resposta:Add("idRegistro",STRING(bAu.id-audit)). resposta:Add("idEtiqueta",STRING(etiqueta)).
        resposta:Add("versao",versao). resposta:Add("acao",acao).
        resposta:Add("situacaoApresentada",depois).
        textoJson = resposta:GetJsonText().
        bEv.resultado = STRING(textoJson).
        VALIDATE bEv. VALIDATE bAu.
        CATCH falha AS Progress.Lang.Error:
            erro = IF falha:NumMessages > 0 THEN falha:GetMessage(1) ELSE "FALHA_CONFIRMACAO".
            IF LOOKUP(erro,"ETIQUETA_BLOQUEADA,ETIQUETA_NAO_DISPONIVEL,CONFLITO_IDEMPOTENCIA,EVENTO_NAO_CONCLUIDO,CONFLITO_VERSAO,ETIQUETA_INDISPONIVEL,GERACAO_NAO_CONFIRMADA,CONTEXTO_NAO_COMPROVADO,JUSTIFICATIVA_OBRIGATORIA,ETIQUETA_NAO_IMPRESSA,RECEBIMENTO_JA_CONFIRMADO") = 0 THEN erro = "FALHA_CONFIRMACAO".
            resposta = mFalha(erro).
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE consultarHistorico:
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER pcEstabel AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piEtiqueta AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER pcApos AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piLimite AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    DEFINE BUFFER bEt FOR mgesp.contr_emb_etiqueta.
    DEFINE BUFFER bMv FOR mgesp.contr_emb_movto.
    DEFINE BUFFER bAu FOR mgesp.contr_emb_audit.
    DEFINE BUFFER bOcorrAudit FOR mgesp.contr_emb_audit.
    DEFINE BUFFER bEv FOR mgesp.contr_emb_evento.
    DEFINE VARIABLE linha AS JsonObject NO-UNDO.
    DEFINE VARIABLE foto AS JsonObject NO-UNDO.
    DEFINE VARIABLE dados AS JsonArray NO-UNDO.
    DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
    DEFINE VARIABLE textoJson AS LONGCHAR NO-UNDO.
    DEFINE VARIABLE cursorAtual AS CHARACTER NO-UNDO.
    DEFINE VARIABLE ultimo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE erro AS CHARACTER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE lidos AS INTEGER NO-UNDO.
    DEFINE VARIABLE total AS INTEGER NO-UNDO.
    DEFINE VARIABLE dataCursor AS DATETIME-TZ NO-UNDO.
    DEFINE VARIABLE categoriaCursor AS CHARACTER NO-UNDO.
    DEFINE VARIABLE registroCursor AS INTEGER NO-UNDO.
    DEFINE VARIABLE eventoCursor AS INTEGER NO-UNDO.
    DEFINE VARIABLE mais AS LOGICAL NO-UNDO.
    /* Fixar ainda vazio: a atribuicao do snapshot converte para o parser. */
    FIX-CODEPAGE(textoJson) = "UTF-8".
    EMPTY TEMP-TABLE ttLinhaTempo.
    resposta = mFalha("ETIQUETA_NAO_DISPONIVEL").
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = pcEstabel) THEN RETURN.
    FIND FIRST bEt NO-LOCK WHERE bEt.id-etiqueta = piEtiqueta AND bEt.cod-estabel = pcEstabel NO-ERROR.
    IF NOT AVAILABLE bEt THEN RETURN.
    resposta = mFalha("FILTRO_INVALIDO").
    IF piLimite = ? OR piLimite < 1 OR piLimite > 100 OR pcApos = ? THEN RETURN.
    IF pcApos <> "" THEN DO:
        IF LENGTH(pcApos) <> 21 OR LOOKUP(SUBSTRING(pcApos,11,1),"A,M") = 0 THEN RETURN.
        DO i = 1 TO 21:
            IF i <> 11 AND INDEX("0123456789",SUBSTRING(pcApos,i,1)) = 0 THEN RETURN.
        END.
        ASSIGN categoriaCursor = SUBSTRING(pcApos,11,1)
            registroCursor = INTEGER(SUBSTRING(pcApos,12,10))
            eventoCursor = INTEGER(SUBSTRING(pcApos,1,10)) NO-ERROR.
        IF ERROR-STATUS:ERROR OR registroCursor = ? OR registroCursor <= 0 OR eventoCursor = ? OR eventoCursor <= 0 THEN RETURN.
        IF categoriaCursor = "A" THEN DO:
            FIND FIRST bAu NO-LOCK WHERE bAu.id-audit = registroCursor AND bAu.id-evento = eventoCursor
                AND bAu.nome-tabela = "contr_emb_etiqueta" AND bAu.chave-registro = STRING(piEtiqueta) NO-ERROR.
            IF NOT AVAILABLE bAu THEN RETURN.
            FIND FIRST bEv NO-LOCK WHERE bEv.id-evento = eventoCursor AND bEv.origem = "MANUT_ETIQUETA"
                AND bEv.situacao = "CONCLUIDO" NO-ERROR.
            IF NOT AVAILABLE bEv THEN RETURN.
            IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = bEv.cod-estabel) THEN RETURN.
            dataCursor = bAu.dt-registro.
        END.
        ELSE DO:
            FIND FIRST bMv NO-LOCK WHERE bMv.id-movto = registroCursor AND bMv.id-etiqueta = piEtiqueta
                AND bMv.id-evento = eventoCursor NO-ERROR.
            IF NOT AVAILABLE bMv THEN RETURN.
            IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = bMv.cod-estabel-dest) THEN RETURN.
            IF bMv.cod-estabel-orig <> ? AND NOT CAN-FIND(FIRST ttEmbEstabelPermitido
                WHERE ttEmbEstabelPermitido.cod-estabel = bMv.cod-estabel-orig) THEN RETURN.
            dataCursor = bMv.dt-registro.
        END.
        IF dataCursor = ? THEN RETURN.
    END.
    DO ON ERROR UNDO, THROW:
        FOR EACH bMv NO-LOCK WHERE bMv.id-etiqueta = piEtiqueta:
            lidos = lidos + 1.
            IF lidos > 10000 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA",0).
            cursorAtual = mCursor(bMv.id-evento,"M",bMv.id-movto).
            IF dataCursor <> ? AND (bMv.dt-registro < dataCursor OR
                (bMv.dt-registro = dataCursor AND (bMv.id-evento < eventoCursor OR
                 (bMv.id-evento = eventoCursor AND ("M" < categoriaCursor OR
                  (categoriaCursor = "M" AND bMv.id-movto <= registroCursor)))))) THEN NEXT.
            IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = bMv.cod-estabel-dest) THEN NEXT.
            IF bMv.cod-estabel-orig <> ? AND NOT CAN-FIND(FIRST ttEmbEstabelPermitido
                WHERE ttEmbEstabelPermitido.cod-estabel = bMv.cod-estabel-orig) THEN NEXT.
            FIND FIRST bEv NO-LOCK WHERE bEv.id-evento = bMv.id-evento NO-ERROR.
            IF NOT AVAILABLE bEv OR bEv.situacao <> "CONCLUIDO" THEN NEXT.
            linha = NEW JsonObject().
            linha:Add("cursorRegistro",cursorAtual). linha:Add("origemRegistro","MOVIMENTO").
            linha:Add("idRegistro",STRING(bMv.id-movto)). linha:Add("idEvento",STRING(bMv.id-evento)).
            linha:Add("ocorrencia",bMv.tipo-movto). linha:Add("dataEvento",bMv.dt-movto).
            linha:Add("dataRegistro",bMv.dt-registro). linha:Add("usuario",bMv.usuario).
            linha:Add("justificativa",bMv.justificativa).
            linha:Add("quantidadeAnterior",bMv.qtidade-ant). linha:Add("quantidadeAtual",bMv.qtidade-atu).
            linha:Add("unidade",bMv.un).
            linha:Add("situacaoAnterior",bMv.situacao-ant). linha:Add("situacaoAtual",bMv.situacao-atu).
            linha:Add("tipoLocalAnterior",bMv.tipo-local-orig). linha:Add("tipoLocalAtual",bMv.tipo-local-dest).
            linha:Add("codEstabelAnterior",bMv.cod-estabel-orig). linha:Add("codEstabelAtual",bMv.cod-estabel-dest).
            linha:Add("depositoAnterior",bMv.cod-depos-orig). linha:Add("depositoAtual",bMv.cod-depos-dest).
            /* DT133: mostrar o estado no instante do fato, nao o resumo atual. */
            RELEASE bOcorrAudit.
            IF LOOKUP(bMv.tipo-movto,"INUTILIZACAO_EMBALAGEM,CORRECAO_INUTILIZACAO,PERDA_EXTRAVIO_EMBALAGEM,CORRECAO_PERDA_EXTRAVIO") > 0 THEN
                FIND FIRST bOcorrAudit NO-LOCK WHERE bOcorrAudit.id-evento = bMv.id-evento
                    AND bOcorrAudit.nome-tabela = "contr_emb_etiqueta"
                    AND bOcorrAudit.chave-registro = STRING(piEtiqueta) NO-ERROR.
            IF AVAILABLE bOcorrAudit AND
                ((bOcorrAudit.dados-ant BEGINS "DT133|" AND bOcorrAudit.dados-atu BEGINS "DT133|") OR
                 (bOcorrAudit.dados-ant BEGINS "DT132|" AND bOcorrAudit.dados-atu BEGINS "DT132|"))
                AND NUM-ENTRIES(bOcorrAudit.dados-ant,"|") >= 3
                AND NUM-ENTRIES(bOcorrAudit.dados-atu,"|") >= 3 THEN DO:
                linha:Add("situacaoApresentadaAnterior",ENTRY(3,bOcorrAudit.dados-ant,"|")).
                linha:Add("situacaoApresentadaAtual",ENTRY(3,bOcorrAudit.dados-atu,"|")).
            END.
            ELSE DO:
                linha:AddNull("situacaoApresentadaAnterior"). linha:AddNull("situacaoApresentadaAtual").
            END.
            /* DT135: fotografia do contexto e efeito quantitativo do fato,
               nunca recalculados a partir da projecao de hoje. */
            IF LOOKUP(bMv.tipo-movto,"PERDA_EXTRAVIO_EMBALAGEM,CORRECAO_PERDA_EXTRAVIO") > 0
                AND bEv.resultado <> ? AND bEv.resultado BEGINS CHR(123) THEN DO:
                ASSIGN parser = NEW ObjectModelParser() textoJson = bEv.resultado
                    foto = CAST(parser:Parse(textoJson),JsonObject).
                IF foto:Has("contrato") AND foto:GetCharacter("contrato") = "DT135" THEN DO:
                    linha:Add("contrato","DT135"). linha:Add("contextoAnterior",foto:GetJsonObject("contextoAnterior")).
                    linha:Add("diferencaERP",foto:GetDecimal("diferencaERP")).
                    linha:Add("reservasLiberadas",foto:GetInteger("reservasLiberadas")).
                    linha:Add("movimentoERPExecutado",foto:GetLogical("movimentoERPExecutado")).
                END.
            END.
            linha:Add("idMovimentoOrigem",IF bMv.id-movto-origem = ? THEN ? ELSE STRING(bMv.id-movto-origem)).
            CREATE ttLinhaTempo.
            ASSIGN ttLinhaTempo.cursor-registro = cursorAtual ttLinhaTempo.objeto = linha
                ttLinhaTempo.data-registro = bMv.dt-registro ttLinhaTempo.categoria = "M" ttLinhaTempo.id-registro = bMv.id-movto.
            ttLinhaTempo.evento-ordem = bMv.id-evento.
        END.
        FOR EACH bAu NO-LOCK WHERE bAu.nome-tabela = "contr_emb_etiqueta" AND bAu.chave-registro = STRING(piEtiqueta):
            lidos = lidos + 1.
            IF lidos > 10000 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA",0).
            IF bAu.id-evento = ? OR bAu.dados-atu = ? OR NOT bAu.dados-atu BEGINS "DT121|" THEN NEXT.
            cursorAtual = mCursor(bAu.id-evento,"A",bAu.id-audit).
            IF dataCursor <> ? AND (bAu.dt-registro < dataCursor OR
                (bAu.dt-registro = dataCursor AND (bAu.id-evento < eventoCursor OR
                 (bAu.id-evento = eventoCursor AND ("A" < categoriaCursor OR
                  (categoriaCursor = "A" AND bAu.id-audit <= registroCursor)))))) THEN NEXT.
            FIND FIRST bEv NO-LOCK WHERE bEv.id-evento = bAu.id-evento NO-ERROR.
            IF NOT AVAILABLE bEv OR bEv.origem <> "MANUT_ETIQUETA" OR bEv.situacao <> "CONCLUIDO" THEN NEXT.
            IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = bEv.cod-estabel) THEN NEXT.
            IF NUM-ENTRIES(bAu.dados-atu,"|") <> 4 OR bAu.dados-ant = ? OR
               NUM-ENTRIES(bAu.dados-ant,"|") <> 2 THEN UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
            ASSIGN parser = NEW ObjectModelParser() textoJson = bEv.dados-evento
                foto = CAST(parser:Parse(textoJson),JsonObject).
            IF foto:GetCharacter("idEtiqueta") <> STRING(piEtiqueta) THEN
                UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
            linha = NEW JsonObject().
            linha:Add("cursorRegistro",cursorAtual). linha:Add("origemRegistro","CONFIRMACAO").
            linha:Add("idRegistro",STRING(bAu.id-audit)). linha:Add("idEvento",STRING(bAu.id-evento)).
            linha:Add("ocorrencia",bEv.tipo-evento). linha:Add("dataEvento",bEv.dt-evento).
            linha:Add("dataRegistro",bAu.dt-registro). linha:Add("usuario",bAu.usuario).
            linha:Add("justificativa",bAu.justificativa).
            linha:Add("quantidadeAnterior",foto:GetDecimal("quantidade")). linha:Add("quantidadeAtual",foto:GetDecimal("quantidade")).
            linha:Add("unidade",foto:GetCharacter("unidade")).
            linha:Add("situacaoAnterior",foto:GetCharacter("situacao")). linha:Add("situacaoAtual",foto:GetCharacter("situacao")).
            linha:Add("tipoLocalAnterior",foto:GetCharacter("tipoLocal")). linha:Add("tipoLocalAtual",foto:GetCharacter("tipoLocal")).
            linha:Add("codEstabelAnterior",bEv.cod-estabel). linha:Add("codEstabelAtual",bEv.cod-estabel).
            linha:Add("depositoAnterior",foto:GetCharacter("deposito")). linha:Add("depositoAtual",foto:GetCharacter("deposito")).
            linha:Add("situacaoApresentadaAnterior",ENTRY(2,bAu.dados-ant,"|")).
            linha:Add("situacaoApresentadaAtual",ENTRY(4,bAu.dados-atu,"|")).
            linha:AddNull("idMovimentoOrigem").
            CREATE ttLinhaTempo.
            ASSIGN ttLinhaTempo.cursor-registro = cursorAtual ttLinhaTempo.objeto = linha
                ttLinhaTempo.data-registro = bAu.dt-registro ttLinhaTempo.categoria = "A" ttLinhaTempo.id-registro = bAu.id-audit.
            ttLinhaTempo.evento-ordem = bAu.id-evento.
        END.
        dados = NEW JsonArray().
        FOR EACH ttLinhaTempo BY ttLinhaTempo.data-registro BY ttLinhaTempo.evento-ordem BY ttLinhaTempo.categoria BY ttLinhaTempo.id-registro:
            IF total = piLimite THEN DO: mais = YES. LEAVE. END.
            dados:Add(CAST(ttLinhaTempo.objeto,JsonObject)).
            ASSIGN total = total + 1 ultimo = ttLinhaTempo.cursor-registro.
        END.
        resposta = NEW JsonObject().
        resposta:Add("sucesso",YES). resposta:Add("codigoErro",""). resposta:Add("mensagem","").
        resposta:Add("idEtiqueta",STRING(piEtiqueta)). resposta:Add("codEstabel",pcEstabel).
        resposta:Add("dados",dados). resposta:Add("total",total). resposta:Add("temMais",mais).
        resposta:Add("proximoRegistro",IF mais THEN ultimo ELSE "").
        CATCH falha AS Progress.Lang.Error:
            erro = IF falha:NumMessages > 0 THEN falha:GetMessage(1) ELSE "FALHA_HISTORICO".
            IF LOOKUP(erro,"CONSULTA_AMPLA,HISTORICO_INCONSISTENTE") = 0 THEN erro = "FALHA_HISTORICO".
            resposta = mFalha(erro).
        END CATCH.
        FINALLY:
            EMPTY TEMP-TABLE ttLinhaTempo.
        END FINALLY.
    END.
END PROCEDURE.
