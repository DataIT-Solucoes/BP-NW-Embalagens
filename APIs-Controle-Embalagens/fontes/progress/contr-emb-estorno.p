/* DT126. Include padrao resolvido na instalacao pelo PROPATH. */
USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
{fontes/progress/contr-emb.i}
{fontes/progress/includes/contr-emb-confirmacao-comum.i}
{include/ceapi001k.i}
/* Retorno da API conforme etiquetas.i legado, linhas396..401.
   ceapi001k.i declara tt-movto; tt-erros pertence ao chamador. */
DEFINE TEMP-TABLE tt-erros NO-UNDO
    FIELD i-sequen AS INTEGER
    FIELD cd-erro AS INTEGER
    FIELD mensagem AS CHARACTER FORMAT "x(255)".

FUNCTION eTexto RETURNS CHARACTER (INPUT p AS JsonObject, INPUT nome AS CHARACTER):
    DEFINE VARIABLE c AS CHARACTER NO-UNDO.
    IF NOT p:Has(nome) THEN RETURN "".
    c = p:GetCharacter(nome) NO-ERROR.
    IF ERROR-STATUS:ERROR OR c = ? THEN RETURN ?.
    RETURN TRIM(c).
END FUNCTION.
FUNCTION eParte RETURNS CHARACTER (INPUT c AS CHARACTER):
    RETURN STRING(LENGTH(c)) + ":" + c.
END FUNCTION.
FUNCTION eFalha RETURNS JsonObject (INPUT codigo AS CHARACTER):
    DEFINE VARIABLE o AS JsonObject NO-UNDO.
    o = NEW JsonObject(). o:Add("sucesso",NO). o:Add("codigoErro",codigo).
    o:Add("mensagem","Confira contexto, versao, justificativa e pre-requisitos da etiqueta.").
    RETURN o.
END FUNCTION.

PROCEDURE estornarEtiqueta:
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER p AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    RUN piExecutarAjusteEtiqueta(INPUT TABLE ttEmbEstabelPermitido,INPUT p,INPUT "ESTORNAR",OUTPUT resposta).
END PROCEDURE.

/* Comando proprio DT133; nao chama estornarEtiqueta nem recebe alvo. */
PROCEDURE inutilizarEtiqueta:
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER p AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    RUN piExecutarAjusteEtiqueta(INPUT TABLE ttEmbEstabelPermitido,INPUT p,INPUT "INUTILIZAR",OUTPUT resposta).
END PROCEDURE.

/* DT131: comando proprio; nao chama Estorno nem recebe quantidade alvo. */
PROCEDURE registrarPerdaEtiqueta:
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER p AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    RUN piExecutarAjusteEtiqueta(INPUT TABLE ttEmbEstabelPermitido,INPUT p,INPUT "REGISTRAR_PERDA_EXTRAVIO",OUTPUT resposta).
END PROCEDURE.

/* Primitiva interna comum: intencao fixada pelo adaptador, nunca pelo texto. */
PROCEDURE piExecutarAjusteEtiqueta:
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER p AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER modo AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    DEFINE BUFFER bEt FOR mgesp.contr_emb_etiqueta.
    DEFINE BUFFER bGer FOR mgesp.contr_emb_evento.
    DEFINE BUFFER bEv FOR mgesp.contr_emb_evento.
    DEFINE BUFFER bAu FOR mgesp.contr_emb_audit.
    DEFINE BUFFER bMovConferido FOR mgesp.contr_emb_movto.
    DEFINE BUFFER bItem FOR mgcad.item.
    DEFINE BUFFER bContextoEvento FOR mgesp.contr_emb_evento.
    DEFINE BUFFER bReserva FOR mgesp.contr_emb_oper_item.
    DEFINE BUFFER bReservaLock FOR mgesp.contr_emb_oper_item.
    DEFINE BUFFER bReservaOper FOR mgesp.contr_emb_oper.
    DEFINE BUFFER bReservaAudit FOR mgesp.contr_emb_audit.
    DEFINE BUFFER bSaldo FOR mgmov.saldo-estoq.
    DEFINE VARIABLE usuario AS CHARACTER NO-UNDO.
    DEFINE VARIABLE estab AS CHARACTER NO-UNDO.
    DEFINE VARIABLE codigo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE chave AS CHARACTER NO-UNDO.
    DEFINE VARIABLE motivo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE conta AS CHARACTER NO-UNDO.
    DEFINE VARIABLE unNeg AS CHARACTER NO-UNDO.
    DEFINE VARIABLE identidade AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hashChave AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hashConteudo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE erro AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mensagem AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cModuloEstorno AS CHARACTER NO-UNDO.
    DEFINE VARIABLE antesSituacao AS CHARACTER NO-UNDO.
    DEFINE VARIABLE origem AS CHARACTER NO-UNDO.
    DEFINE VARIABLE ocorrencia AS CHARACTER NO-UNDO.
    DEFINE VARIABLE acaoEntrada AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE VARIABLE eventoInutilizacao AS INTEGER NO-UNDO.
    DEFINE VARIABLE correcao AS LOGICAL NO-UNDO.
    DEFINE VARIABLE inutilizacao AS LOGICAL NO-UNDO.
    DEFINE VARIABLE perda AS LOGICAL NO-UNDO.
    DEFINE VARIABLE correcaoPerda AS LOGICAL NO-UNDO.
    DEFINE VARIABLE eventoPerda AS INTEGER NO-UNDO.
    DEFINE VARIABLE prefixoAuditoria AS CHARACTER NO-UNDO.
    DEFINE VARIABLE etiqueta AS INTEGER NO-UNDO.
    DEFINE VARIABLE versao AS INTEGER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE movimento AS INTEGER NO-UNDO.
    DEFINE VARIABLE novaVersao AS INTEGER NO-UNDO.
    DEFINE VARIABLE alvo AS DECIMAL NO-UNDO.
    DEFINE VARIABLE antes AS DECIMAL NO-UNDO.
    DEFINE VARIABLE diferenca AS DECIMAL NO-UNDO.
    DEFINE VARIABLE diferencaERP AS DECIMAL NO-UNDO.
    DEFINE VARIABLE disponivelERP AS DECIMAL NO-UNDO.
    DEFINE VARIABLE interno AS LOGICAL NO-UNDO.
    DEFINE VARIABLE reservasLiberadas AS INTEGER NO-UNDO.
    DEFINE VARIABLE fotoReserva AS JsonObject NO-UNDO.
    DEFINE VARIABLE contextoAnterior AS JsonObject NO-UNDO.
    DEFINE VARIABLE saldoAntes AS DECIMAL NO-UNDO.
    DEFINE VARIABLE saldoDepois AS DECIMAL NO-UNDO.
    DEFINE VARIABLE agora AS DATETIME-TZ NO-UNDO.
    DEFINE VARIABLE hApi AS HANDLE NO-UNDO.
    DEFINE VARIABLE hRastro AS HANDLE NO-UNDO.
    DEFINE VARIABLE sucesso AS LOGICAL NO-UNDO.
    DEFINE VARIABLE repeticao AS LOGICAL NO-UNDO.
    DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
    DEFINE VARIABLE texto AS LONGCHAR NO-UNDO.
    DEFINE VARIABLE foto AS JsonObject NO-UNDO.
    FIX-CODEPAGE(texto) = "UTF-8".
    EMPTY TEMP-TABLE tt-movto. EMPTY TEMP-TABLE tt-erros.
    resposta = eFalha("COMANDO_INVALIDO").
    IF p = ? THEN RETURN.
    IF modo = ? OR LOOKUP(modo,"ESTORNAR,INUTILIZAR,REGISTRAR_PERDA_EXTRAVIO") = 0 THEN RETURN.
    ASSIGN inutilizacao = modo = "INUTILIZAR" perda = modo = "REGISTRAR_PERDA_EXTRAVIO".
    origem = IF perda THEN "PERDA_ETIQUETA" ELSE IF inutilizacao THEN "INUTIL_ETIQUETA" ELSE "ESTORNO_ETIQUETA".
    ocorrencia = IF perda THEN "PERDA_EXTRAVIO_EMBALAGEM" ELSE IF inutilizacao THEN "INUTILIZACAO_EMBALAGEM" ELSE "AJUSTE_SALDO_MANUAL".
    IF inutilizacao OR perda THEN DO:
        acaoEntrada = eTexto(p,"acao").
        IF acaoEntrada = ? OR acaoEntrada <> modo THEN DO:
            resposta = eFalha("ACAO_INVALIDA"). RETURN.
        END.
        IF p:Has("quantidadeAtual") THEN DO: resposta = eFalha("PARAMETRO_NAO_PERMITIDO"). RETURN. END.
    END.
    ASSIGN usuario = eTexto(p,"usuario") estab = eTexto(p,"codEstabel") codigo = eTexto(p,"idEtiqueta")
        chave = eTexto(p,"chaveIdempotente") motivo = eTexto(p,"justificativa")
        conta = "59801001" unNeg = "903".
    IF usuario = ? OR usuario = "" OR LENGTH(usuario) > 128 OR estab = ? OR estab = "" OR
        codigo = ? OR codigo = "" OR LENGTH(codigo) > 10 OR chave = ? OR LENGTH(chave) < 1 OR LENGTH(chave) > 64 THEN RETURN.
    DO i = 1 TO LENGTH(codigo):
        IF INDEX("0123456789",SUBSTRING(codigo,i,1)) = 0 THEN RETURN.
    END.
    DO i = 1 TO LENGTH(chave):
        IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-",SUBSTRING(chave,i,1)) = 0 THEN RETURN.
    END.
    ASSIGN etiqueta = INTEGER(codigo) versao = p:GetInteger("versao") NO-ERROR.
    IF ERROR-STATUS:ERROR OR etiqueta = ? OR etiqueta <= 0 OR STRING(etiqueta) <> codigo OR versao = ? OR versao <= 0 THEN RETURN.
    IF inutilizacao OR perda THEN alvo = 0.
    ELSE DO:
        alvo = p:GetDecimal("quantidadeAtual") NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO: resposta = eFalha("QUANTIDADE_INVALIDA"). RETURN. END.
    END.
    IF alvo = ? OR alvo < 0 OR ROUND(alvo,4) <> alvo THEN DO: resposta = eFalha("QUANTIDADE_INVALIDA"). RETURN. END.
    IF motivo = ? OR motivo = "" OR LENGTH(motivo) > 1000 THEN DO: resposta = eFalha("JUSTIFICATIVA_OBRIGATORIA"). RETURN. END.
    /* DT126: valores de negocio do estorno legado, mantidos por instrucao
       expressa do responsavel; nao sao massa de teste nem input do Widget. */
    IF p:Has("contaContabil") OR p:Has("unidadeNegocio") THEN DO:
        resposta = eFalha("PARAMETRO_NAO_PERMITIDO"). RETURN.
    END.
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = estab) THEN DO:
        resposta = eFalha("SEM_PERMISSAO"). RETURN.
    END.
    /* JSON preserva as quatro casas sem depender do FORMAT decimal da sessao. */
    foto = NEW JsonObject(). foto:Add("quantidadeAtual",alvo). texto = foto:GetJsonText().
    ASSIGN identidade = eParte(estab) + eParte(usuario) + eParte(chave)
        hashChave = HEX-ENCODE(MESSAGE-DIGEST("SHA-256",origem + "|" + identidade))
        hashConteudo = HEX-ENCODE(MESSAGE-DIGEST("SHA-256",identidade + eParte(codigo) + eParte(STRING(versao))
            + eParte(STRING(texto)) + eParte(motivo) + eParte(conta) + eParte(unNeg))).
    ajuste:
    DO TRANSACTION ON ERROR UNDO, THROW:
        FIND FIRST bEt WHERE bEt.id-etiqueta = etiqueta EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF LOCKED bEt THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("ETIQUETA_BLOQUEADA",0).
        IF NOT AVAILABLE bEt THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("ETIQUETA_NAO_DISPONIVEL",0).
        IF bEt.cod-estabel = ? OR bEt.cod-estabel <> estab THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("ETIQUETA_NAO_DISPONIVEL",0).
        FIND FIRST bEv NO-LOCK WHERE bEv.hash-chave = hashChave NO-ERROR.
        IF AVAILABLE bEv THEN DO:
            IF bEv.origem <> origem OR bEv.chave-evento <> identidade OR bEv.hash-conteudo <> hashConteudo THEN
                UNDO ajuste, THROW NEW Progress.Lang.AppError("CONFLITO_IDEMPOTENCIA",0).
            IF bEv.situacao <> "CONCLUIDO" OR bEv.resultado = ? THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("EVENTO_NAO_CONCLUIDO",0).
            ASSIGN texto = bEv.resultado parser = NEW ObjectModelParser() resposta = CAST(parser:Parse(texto),JsonObject).
            resposta:Set("repeticao",YES). LEAVE ajuste.
        END.
        IF bEt.versao = ? OR bEt.versao <> versao THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("CONFLITO_VERSAO",0).
        /* ENCERRADA so reabre quando aponta para a perda vigente deste fluxo. */
        correcaoPerda = modo = "ESTORNAR" AND bEt.situacao = "ENCERRADA".
        IF correcaoPerda THEN DO:
            eventoPerda = fEmEventoPerda(etiqueta).
            IF eventoPerda <= 0 THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("ENCERRAMENTO_NAO_CORRIGIVEL",0).
        END.
        IF bEt.tipo-controle <> "EMBALAGEM" OR bEt.tipo-controle = ? OR
            (bEt.situacao <> "ATIVA" AND NOT correcaoPerda) OR bEt.situacao = ? OR
            bEt.tipo-local = ? OR LOOKUP(bEt.tipo-local,"ESTAB,CAMPO,TERCEIRO,TRANSITO") = 0 OR
            (NOT perda AND NOT correcaoPerda AND bEt.tipo-local <> "ESTAB") OR bEt.id-bag <> ? OR bEt.id-movto-ult = ? OR
            bEt.qtidade-atu = ? OR bEt.qtidade-atu < 0 OR bEt.capacidade-emb = ? OR alvo > bEt.capacidade-emb THEN
            UNDO ajuste, THROW NEW Progress.Lang.AppError("ETIQUETA_INDISPONIVEL",0).
        eventoInutilizacao = fEmEventoInutilizacao(etiqueta).
        IF inutilizacao AND eventoInutilizacao > 0 THEN
            UNDO ajuste, THROW NEW Progress.Lang.AppError("ETIQUETA_JA_INUTILIZADA",0).
        correcao = modo = "ESTORNAR" AND (eventoInutilizacao > 0 OR correcaoPerda).
        IF NOT perda AND (inutilizacao OR correcao) AND fEmReservaAtiva(etiqueta) THEN
            UNDO ajuste, THROW NEW Progress.Lang.AppError("ETIQUETA_RESERVADA",0).
        IF correcao THEN ocorrencia = IF correcaoPerda THEN "CORRECAO_PERDA_EXTRAVIO" ELSE "CORRECAO_INUTILIZACAO".
        prefixoAuditoria = IF perda OR correcaoPerda THEN "DT132|" ELSE IF inutilizacao OR correcao THEN "DT133|" ELSE "DT126|".
        interno = bEt.tipo-local = "ESTAB".
        IF (interno AND (bEt.cod-depos = ? OR bEt.cod-depos = "" OR bEt.cod-localiz = ?))
            OR bEt.lote = ? OR bEt.lote = "" OR bEt.dt-vali-lote = ? THEN
            UNDO ajuste, THROW NEW Progress.Lang.AppError("POSICAO_INVALIDA",0).
        FIND FIRST bGer NO-LOCK WHERE bGer.id-evento = bEt.id-evento-geracao NO-ERROR.
        IF NOT AVAILABLE bGer THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("GERACAO_NAO_CONFIRMADA",0).
        IF bGer.situacao = ? OR bGer.situacao <> "CONCLUIDO" THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("GERACAO_NAO_CONFIRMADA",0).
        FIND FIRST bItem NO-LOCK WHERE bItem.it-codigo = bEt.it-codigo NO-ERROR.
        IF NOT AVAILABLE bItem THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("ITEM_NAO_ENCONTRADO",0).
        IF bItem.tipo-con-est = ? OR bItem.tipo-con-est <> 3 OR bItem.un = ? OR bItem.un <> bEt.un THEN
            UNDO ajuste, THROW NEW Progress.Lang.AppError("ITEM_CONTROLE_DIVERGENTE",0).
        /* DT135: a posicao atual precisa ser um fato confirmado, nao um texto
           enviado pelo cliente. Externo nao e saldo disponivel do almoxarifado. */
        IF perda OR correcaoPerda THEN DO:
            FIND FIRST bMovConferido NO-LOCK WHERE bMovConferido.id-movto = bEt.id-movto-ult
                AND bMovConferido.id-etiqueta = etiqueta NO-ERROR.
            IF NOT AVAILABLE bMovConferido THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("CONTEXTO_DIVERGENTE",0).
            FIND FIRST bContextoEvento NO-LOCK WHERE bContextoEvento.id-evento = bMovConferido.id-evento
                AND bContextoEvento.situacao = "CONCLUIDO" NO-ERROR.
            IF NOT AVAILABLE bContextoEvento OR bMovConferido.tipo-local-dest <> bEt.tipo-local
                OR bMovConferido.cod-estabel-dest <> estab OR bMovConferido.qtidade-atu <> bEt.qtidade-atu
                OR bMovConferido.situacao-atu <> bEt.situacao
                OR NOT fEmPosicaoIgual(bMovConferido.cod-depos-dest,bEt.cod-depos)
                OR NOT fEmPosicaoIgual(bMovConferido.cod-localiz-dest,bEt.cod-localiz)
                OR NOT fEmPosicaoIgual(STRING(bMovConferido.cod-emitente-dest),STRING(bEt.cod-emitente-posse))
                OR NOT fEmPosicaoIgual(bMovConferido.origem-local-ext-dest,bEt.origem-local-ext)
                OR NOT fEmPosicaoIgual(bMovConferido.cod-local-ext-dest,bEt.cod-local-ext) THEN
                UNDO ajuste, THROW NEW Progress.Lang.AppError("CONTEXTO_DIVERGENTE",0).
        END.
        ASSIGN antes = bEt.qtidade-atu diferenca = alvo - antes antesSituacao = fEmResumo(etiqueta)
            diferencaERP = IF interno THEN diferenca ELSE 0.
        contextoAnterior = NEW JsonObject().
        contextoAnterior:Add("tipoLocal",bEt.tipo-local). contextoAnterior:Add("codEstabel",estab).
        contextoAnterior:Add("deposito",bEt.cod-depos). contextoAnterior:Add("localizacao",bEt.cod-localiz).
        contextoAnterior:Add("codEmitentePosse",bEt.cod-emitente-posse).
        contextoAnterior:Add("origemLocalExterno",bEt.origem-local-ext). contextoAnterior:Add("codLocalExterno",bEt.cod-local-ext).
        contextoAnterior:Add("idMovimentoAnterior",STRING(bEt.id-movto-ult)).
        IF diferenca = 0 AND NOT inutilizacao AND NOT perda AND NOT correcao THEN
            UNDO ajuste, THROW NEW Progress.Lang.AppError("SEM_ALTERACAO",0).
        /* Padrao permanece autoritativo. Bloquear linhas existentes da posicao;
           a entrada pode recriar saldo inexistente pela propria API. */
        IF interno THEN
        FOR EACH bSaldo WHERE bSaldo.cod-estabel = estab AND bSaldo.it-codigo = bEt.it-codigo
            AND bSaldo.cod-depos = bEt.cod-depos AND bSaldo.cod-localiz = bEt.cod-localiz
            AND bSaldo.lote = bEt.lote AND bSaldo.dt-vali-lote = bEt.dt-vali-lote EXCLUSIVE-LOCK:
            IF bSaldo.qtidade-atu = ? THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("SALDO_INVALIDO",0).
            saldoAntes = saldoAntes + bSaldo.qtidade-atu.
            IF perda THEN DO:
                IF bSaldo.qt-alocada = ? OR bSaldo.qt-aloc-prod = ? OR bSaldo.qt-aloc-ped = ? THEN
                    UNDO ajuste, THROW NEW Progress.Lang.AppError("SALDO_INVALIDO",0).
                disponivelERP = disponivelERP + bSaldo.qtidade-atu - bSaldo.qt-alocada - bSaldo.qt-aloc-prod - bSaldo.qt-aloc-ped.
            END.
        END.
        IF diferencaERP < 0 AND (IF perda THEN disponivelERP ELSE saldoAntes) < ABSOLUTE(diferencaERP) THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("SALDO_INSUFICIENTE",0).
        ASSIGN agora = NOW cModuloEstorno = SEARCH("esp/api/v1/contr-emb-rastreio.r").
        IF cModuloEstorno = ? THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("RASTREIO_NAO_LOCALIZADO",0).
        RUN VALUE(cModuloEstorno) PERSISTENT SET hRastro.
        CREATE bEv.
        ASSIGN bEv.id-evento = NEXT-VALUE(CONTR_EMB_EVENTO_ID_SEQ,mgesp) bEv.origem = origem
            bEv.chave-evento = identidade bEv.hash-chave = hashChave bEv.hash-conteudo = hashConteudo
            bEv.tipo-evento = ocorrencia bEv.id-operacao = ?
            bEv.id-evento-origem = IF correcaoPerda THEN eventoPerda ELSE IF correcao THEN eventoInutilizacao ELSE bEt.id-evento-geracao bEv.seq-ciclo = 1
            bEv.dt-evento = agora bEv.versao-contrato = 1 bEv.cod-estabel = estab bEv.tipo-docto = ? bEv.chave-docto = ?
            bEv.hash-docto = ? bEv.cod-emitente = ? bEv.cgc-emitente = ? bEv.serie = ? bEv.nro-docto = ?
            bEv.chave-acesso = ? bEv.nat-operacao = ? bEv.dt-emissao = ? bEv.situacao = "PROCESSANDO"
            bEv.tentativas = 1 bEv.dt-proxima-tent = ? bEv.token-execucao = ? bEv.dt-expira-exec = ? bEv.dt-conclusao = ?
            bEv.mensagem = "" bEv.dt-inclusao = agora bEv.dt-alteracao = agora bEv.usuario-inclusao = usuario
            bEv.usuario-alteracao = usuario bEv.versao = 1 bEv.dados-evento = "".
        VALIDATE bEv.
        IF perda THEN DO:
            FOR EACH bReserva NO-LOCK WHERE bReserva.id-etiqueta = etiqueta AND bReserva.tipo-item = "SOLICITACAO"
                BY bReserva.id-operacao BY bReserva.id-item-oper:
                FIND FIRST bReservaOper WHERE bReservaOper.id-operacao = bReserva.id-operacao
                    EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
                IF LOCKED bReservaOper THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("RESERVA_BLOQUEADA",0).
                IF NOT AVAILABLE bReservaOper THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("RESERVA_INCONSISTENTE",0).
                IF bReservaOper.situacao = ? OR LOOKUP(bReservaOper.situacao,"RASCUNHO,SOLICITADA,EM_EXECUCAO,EXECUTADA,CANCELADA") = 0 THEN
                    UNDO ajuste, THROW NEW Progress.Lang.AppError("RESERVA_INCONSISTENTE",0).
                IF LOOKUP(bReservaOper.situacao,"EXECUTADA,CANCELADA") > 0 THEN NEXT.
                FIND FIRST bReservaLock WHERE bReservaLock.id-item-oper = bReserva.id-item-oper
                    EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
                IF LOCKED bReservaLock THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("RESERVA_BLOQUEADA",0).
                IF NOT AVAILABLE bReservaLock THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("RESERVA_INCONSISTENTE",0).
                IF bReservaLock.tipo-item <> "SOLICITACAO" OR bReservaLock.id-etiqueta <> etiqueta
                    OR bReservaLock.it-codigo <> bEt.it-codigo OR bReservaLock.un <> bEt.un THEN
                    UNDO ajuste, THROW NEW Progress.Lang.AppError("RESERVA_INCONSISTENTE",0).
                fotoReserva = NEW JsonObject().
                fotoReserva:Add("idOperacao",STRING(bReservaLock.id-operacao)).
                fotoReserva:Add("idEtiqueta",codigo). fotoReserva:Add("tipoItem",bReservaLock.tipo-item).
                fotoReserva:Add("quantidade",bReservaLock.quantidade).
                texto = fotoReserva:GetJsonText().
                CREATE bReservaAudit.
                ASSIGN bReservaAudit.id-audit = NEXT-VALUE(CONTR_EMB_AUDIT_ID_SEQ,mgesp)
                    bReservaAudit.id-evento = bEv.id-evento bReservaAudit.nome-tabela = "contr_emb_oper_item"
                    bReservaAudit.chave-registro = STRING(bReservaLock.id-item-oper) bReservaAudit.acao = "ALTERACAO"
                    bReservaAudit.versao-ant = bReservaLock.versao bReservaAudit.versao-atu = bReservaLock.versao + 1
                    bReservaAudit.dados-ant = STRING(texto) bReservaAudit.dados-atu = "DT135|LIBERADA|" + STRING(bReservaLock.id-operacao)
                    bReservaAudit.justificativa = motivo bReservaAudit.usuario = usuario bReservaAudit.dt-registro = agora.
                ASSIGN bReservaLock.tipo-item = "LIBERADA" bReservaLock.versao = bReservaLock.versao + 1
                    bReservaLock.dt-alteracao = agora bReservaLock.usuario-alteracao = usuario.
                VALIDATE bReservaLock. VALIDATE bReservaAudit.
                reservasLiberadas = reservasLiberadas + 1.
            END.
        END.
        IF diferencaERP <> 0 THEN DO:
        CREATE tt-movto.
        ASSIGN tt-movto.ct-codigo = conta tt-movto.usuario = usuario tt-movto.tipo-trans = IF diferencaERP > 0 THEN 1 ELSE 2
            tt-movto.esp-docto = 6 tt-movto.it-codigo = bEt.it-codigo tt-movto.cod-estabel = estab
            tt-movto.cod-depos = bEt.cod-depos tt-movto.lote = bEt.lote tt-movto.nro-docto = "" tt-movto.cod-emitente = 0
            tt-movto.serie = "DIV" tt-movto.nr-ord-produ = 0 tt-movto.cod-localiz = bEt.cod-localiz tt-movto.dt-trans = TODAY
            tt-movto.un = bEt.un tt-movto.quantidade = ABSOLUTE(diferencaERP) tt-movto.dt-vali-lote = bEt.dt-vali-lote
            tt-movto.cod-versao-integracao = 1 tt-movto.cod-prog-orig = "FLUIG-ETIQUETAS" tt-movto.cod-unid-negoc = unNeg.
        RUN cep/ceapi001k.p PERSISTENT SET hApi.
        RUN pi-execute IN hApi(INPUT-OUTPUT TABLE tt-movto,INPUT-OUTPUT TABLE tt-erros,INPUT YES).
        IF CAN-FIND(FIRST tt-erros) THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("AJUSTE_ESTOQUE_RECUSADO",0).
        END.
        IF interno THEN
        FOR EACH bSaldo NO-LOCK WHERE bSaldo.cod-estabel = estab AND bSaldo.it-codigo = bEt.it-codigo
            AND bSaldo.cod-depos = bEt.cod-depos AND bSaldo.cod-localiz = bEt.cod-localiz
            AND bSaldo.lote = bEt.lote AND bSaldo.dt-vali-lote = bEt.dt-vali-lote:
            IF bSaldo.qtidade-atu = ? THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("SALDO_INVALIDO",0).
            saldoDepois = saldoDepois + bSaldo.qtidade-atu.
        END.
        IF saldoDepois <> saldoAntes + diferencaERP THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("DIVERGENCIA_SALDO_CONSOLIDADO",0).
        EMPTY TEMP-TABLE ttEmbMovimentoComando. CREATE ttEmbMovimentoComando.
        ASSIGN ttEmbMovimentoComando.id-evento = bEv.id-evento ttEmbMovimentoComando.sequencia = 1
            ttEmbMovimentoComando.id-etiqueta = etiqueta ttEmbMovimentoComando.id-item-evento = 0 ttEmbMovimentoComando.id-item-oper = 0
            ttEmbMovimentoComando.id-movto-ant-esperado = bEt.id-movto-ult ttEmbMovimentoComando.id-movto-origem = IF correcaoPerda THEN bEt.id-movto-ult ELSE 0
            ttEmbMovimentoComando.id-bag-relac = 0 ttEmbMovimentoComando.id-bag-destino = 0
            ttEmbMovimentoComando.tipo-movto = ocorrencia ttEmbMovimentoComando.dt-movto = agora
            ttEmbMovimentoComando.un = bEt.un ttEmbMovimentoComando.quantidade = ABSOLUTE(diferenca)
            ttEmbMovimentoComando.qtidade-atu = alvo ttEmbMovimentoComando.situacao-atu = IF perda THEN "ENCERRADA" ELSE IF correcaoPerda THEN "ATIVA" ELSE bEt.situacao
            ttEmbMovimentoComando.cod-estabel-dest = estab ttEmbMovimentoComando.cod-depos-dest = bEt.cod-depos
            ttEmbMovimentoComando.cod-localiz-dest = bEt.cod-localiz ttEmbMovimentoComando.tipo-local-dest = bEt.tipo-local
            ttEmbMovimentoComando.cod-emitente-dest = bEt.cod-emitente-posse ttEmbMovimentoComando.origem-local-ext-dest = bEt.origem-local-ext
            ttEmbMovimentoComando.cod-local-ext-dest = bEt.cod-local-ext ttEmbMovimentoComando.origem-movto-erp = ?
            ttEmbMovimentoComando.chave-movto-erp = ? ttEmbMovimentoComando.justificativa = motivo
            ttEmbMovimentoComando.versao-etiqueta-esperada = versao ttEmbMovimentoComando.usuario = usuario.
        IF ttEmbMovimentoComando.qtidade-atu <> alvo OR
            ttEmbMovimentoComando.quantidade <> ABSOLUTE(diferenca) THEN
            UNDO ajuste, THROW NEW Progress.Lang.AppError("DIVERGENCIA_SALDO_INDIVIDUAL",0).
        RUN aplicarMovimento IN hRastro(INPUT TABLE ttEmbMovimentoComando,YES,OUTPUT sucesso,OUTPUT repeticao,
            OUTPUT movimento,OUTPUT novaVersao,OUTPUT erro,OUTPUT mensagem).
        IF NOT sucesso THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("MOVIMENTO_INDIVIDUAL_RECUSADO",0).
        FIND FIRST bEt WHERE bEt.id-etiqueta = etiqueta EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF NOT AVAILABLE bEt THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("DIVERGENCIA_SALDO_INDIVIDUAL",0).
        FIND FIRST bMovConferido NO-LOCK WHERE bMovConferido.id-movto = movimento NO-ERROR.
        IF NOT AVAILABLE bMovConferido THEN UNDO ajuste, THROW NEW Progress.Lang.AppError("DIVERGENCIA_SALDO_INDIVIDUAL",0).
        IF bEt.qtidade-atu <> alvo OR bEt.versao <> novaVersao OR bEt.id-movto-ult <> movimento OR
            bMovConferido.id-etiqueta <> etiqueta OR bMovConferido.qtidade-ant <> antes OR
            bMovConferido.qtidade-atu <> alvo OR bMovConferido.quantidade <> ABSOLUTE(diferenca) THEN
            UNDO ajuste, THROW NEW Progress.Lang.AppError("DIVERGENCIA_SALDO_INDIVIDUAL",0).
        /* Disponivel na consulta da propria transacao; commit permanece atomico. */
        ASSIGN bEv.situacao = "CONCLUIDO" bEv.dt-conclusao = agora.
        VALIDATE bEv.
        CREATE bAu.
        ASSIGN bAu.id-audit = NEXT-VALUE(CONTR_EMB_AUDIT_ID_SEQ,mgesp) bAu.id-evento = bEv.id-evento
            bAu.nome-tabela = "contr_emb_etiqueta" bAu.chave-registro = codigo bAu.acao = "ALTERACAO"
            bAu.versao-ant = versao bAu.versao-atu = novaVersao
            bAu.dados-ant = prefixoAuditoria + STRING(antes,"->>>>>>>>>9.9999") + "|" + antesSituacao
            bAu.dados-atu = prefixoAuditoria + STRING(alvo,"->>>>>>>>>9.9999") + "|" + fEmResumo(etiqueta) bAu.justificativa = motivo
            bAu.dt-registro = agora bAu.usuario = usuario.
        foto = NEW JsonObject().
        IF diferencaERP <> 0 THEN foto:Add("api","cep/ceapi001k.p::pi-execute"). ELSE foto:AddNull("api").
        foto:Add("diferenca",diferenca). foto:Add("diferencaERP",diferencaERP).
        IF perda OR correcaoPerda THEN DO:
            foto:Add("contrato","DT135"). foto:Add("contextoAnterior",contextoAnterior).
            foto:Add("reservasLiberadas",reservasLiberadas).
        END.
        foto:Add("contaContabil",conta). foto:Add("unidadeNegocio",unNeg). texto = foto:GetJsonText(). bEv.dados-evento = STRING(texto).
        resposta = NEW JsonObject(). resposta:Add("sucesso",YES). resposta:Add("codigoErro",""). resposta:Add("mensagem","").
        resposta:Add("repeticao",NO). resposta:Add("acao",IF modo = "ESTORNAR" THEN "ESTORNAR_SALDO" ELSE modo). resposta:Add("idEtiqueta",codigo).
        resposta:Add("idEvento",STRING(bEv.id-evento)). resposta:Add("idRegistro",STRING(bAu.id-audit)).
        resposta:Add("idMovimento",STRING(movimento)). resposta:Add("versao",novaVersao).
        resposta:Add("quantidadeAnterior",antes). resposta:Add("quantidadeAtual",alvo). resposta:Add("diferenca",diferenca).
        IF interno THEN DO:
            resposta:Add("saldoConsolidadoAnterior",saldoAntes). resposta:Add("saldoConsolidadoAtual",saldoDepois).
        END.
        ELSE DO:
            resposta:AddNull("saldoConsolidadoAnterior"). resposta:AddNull("saldoConsolidadoAtual").
        END.
        IF perda OR correcaoPerda THEN DO:
            resposta:Add("contrato","DT135"). resposta:Add("tipoLocal",bEt.tipo-local).
            resposta:Add("diferencaERP",diferencaERP). resposta:Add("reservasLiberadas",reservasLiberadas).
            resposta:Add("contextoAnterior",contextoAnterior).
        END.
        IF inutilizacao OR perda OR correcao THEN DO:
            resposta:Add("movimentoERPExecutado",diferencaERP <> 0).
            IF correcaoPerda THEN resposta:Add("idPerdaCorrigida",STRING(eventoPerda)).
            ELSE IF correcao THEN resposta:Add("idInutilizacaoCorrigida",STRING(eventoInutilizacao)).
        END.
        resposta:Add("situacaoApresentada",fEmResumo(etiqueta)). texto = resposta:GetJsonText().
        ASSIGN bEv.resultado = STRING(texto) bEv.situacao = "CONCLUIDO" bEv.dt-conclusao = agora.
        IF LENGTH(bEv.dados-evento,"RAW") > 4000 OR LENGTH(bEv.resultado,"RAW") > 4000 THEN
            UNDO ajuste, THROW NEW Progress.Lang.AppError("FALHA_ESTORNO",0).
        VALIDATE bEv. VALIDATE bAu.
        CATCH falha AS Progress.Lang.Error:
            erro = IF falha:NumMessages > 0 THEN falha:GetMessage(1) ELSE "FALHA_ESTORNO".
            IF LOOKUP(erro,"ETIQUETA_BLOQUEADA,ETIQUETA_NAO_DISPONIVEL,CONFLITO_IDEMPOTENCIA,EVENTO_NAO_CONCLUIDO,CONFLITO_VERSAO,ETIQUETA_INDISPONIVEL,POSICAO_INVALIDA,GERACAO_NAO_CONFIRMADA,ITEM_NAO_ENCONTRADO,ITEM_CONTROLE_DIVERGENTE,SEM_ALTERACAO,SALDO_INVALIDO,SALDO_INSUFICIENTE,RASTREIO_NAO_LOCALIZADO,AJUSTE_ESTOQUE_RECUSADO,DIVERGENCIA_SALDO_CONSOLIDADO,DIVERGENCIA_SALDO_INDIVIDUAL,MOVIMENTO_INDIVIDUAL_RECUSADO,ETIQUETA_RESERVADA,ETIQUETA_JA_INUTILIZADA,ENCERRAMENTO_NAO_CORRIGIVEL,CONTEXTO_DIVERGENTE,RESERVA_BLOQUEADA,RESERVA_INCONSISTENTE") = 0 THEN
                erro = IF perda THEN "FALHA_PERDA_EXTRAVIO" ELSE IF inutilizacao THEN "FALHA_INUTILIZACAO" ELSE "FALHA_ESTORNO".
            resposta = eFalha(erro).
        END CATCH.
        FINALLY:
            IF VALID-HANDLE(hApi) THEN DELETE PROCEDURE hApi NO-ERROR.
            IF VALID-HANDLE(hRastro) THEN DELETE PROCEDURE hRastro NO-ERROR.
            EMPTY TEMP-TABLE tt-movto. EMPTY TEMP-TABLE tt-erros.
        END FINALLY.
    END.
END PROCEDURE.
