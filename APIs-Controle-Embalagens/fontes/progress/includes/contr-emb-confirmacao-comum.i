/* DT121. Leitura da projecao operacional derivada; nenhuma escrita. */
/* DT126 R3: campos opcionais vazios/desconhecidos representam ausencia.
   aplicarMovimento normaliza destino; isso nao e deslocamento fisico. */
/* DT130: vinculo historico executado nao e reserva atual. */
FUNCTION fEmReservaAtiva RETURNS LOGICAL (INPUT piEtiqueta AS INTEGER):
    DEFINE BUFFER bReservaLinha FOR mgesp.contr_emb_oper_item.
    DEFINE BUFFER bReservaOper FOR mgesp.contr_emb_oper.
    IF piEtiqueta = ? OR piEtiqueta <= 0 THEN RETURN YES.
    FOR EACH bReservaLinha NO-LOCK
        WHERE bReservaLinha.id-etiqueta = piEtiqueta
          AND bReservaLinha.tipo-item = "SOLICITACAO":
        FIND FIRST bReservaOper NO-LOCK
            WHERE bReservaOper.id-operacao = bReservaLinha.id-operacao NO-ERROR.
        /* Origem ausente ou estado desconhecido nao libera a etiqueta. */
        IF NOT AVAILABLE bReservaOper THEN RETURN YES.
        IF bReservaOper.situacao = ? OR
           LOOKUP(bReservaOper.situacao,"EXECUTADA,CANCELADA") = 0 THEN RETURN YES.
    END.
    RETURN NO.
END FUNCTION.

FUNCTION fEmPosicaoIgual RETURNS LOGICAL
    (INPUT a AS CHARACTER, INPUT b AS CHARACTER):
    IF a = ? THEN a = "".
    IF b = ? THEN b = "".
    RETURN TRIM(a) = TRIM(b).
END FUNCTION.

FUNCTION fEmContexto RETURNS CHARACTER (INPUT piEtiqueta AS INTEGER):
    DEFINE BUFFER bCtx FOR mgesp.contr_emb_movto.
    FOR EACH bCtx NO-LOCK WHERE bCtx.id-etiqueta = piEtiqueta BY bCtx.id-movto DESCENDING:
        IF bCtx.id-movto-ant = ? OR
           NOT (bCtx.cod-estabel-orig = bCtx.cod-estabel-dest) OR
           NOT (bCtx.tipo-local-orig = bCtx.tipo-local-dest) OR
           NOT fEmPosicaoIgual(bCtx.cod-depos-orig,bCtx.cod-depos-dest) OR
           NOT fEmPosicaoIgual(bCtx.cod-localiz-orig,bCtx.cod-localiz-dest)
        THEN RETURN STRING(bCtx.id-movto).
    END.
    RETURN "".
END FUNCTION.

FUNCTION fEmConfirmada RETURNS LOGICAL
    (INPUT piEtiqueta AS INTEGER, INPUT pcTipo AS CHARACTER, INPUT pcContexto AS CHARACTER):
    DEFINE BUFFER bConfAudit FOR mgesp.contr_emb_audit.
    DEFINE BUFFER bConfEvento FOR mgesp.contr_emb_evento.
    FOR EACH bConfAudit NO-LOCK WHERE bConfAudit.nome-tabela = "contr_emb_etiqueta"
        AND bConfAudit.chave-registro = STRING(piEtiqueta) BY bConfAudit.id-audit DESCENDING:
        IF bConfAudit.id-evento = ? THEN NEXT.
        FIND FIRST bConfEvento NO-LOCK WHERE bConfEvento.id-evento = bConfAudit.id-evento NO-ERROR.
        IF NOT AVAILABLE bConfEvento THEN NEXT.
        IF bConfEvento.origem <> "MANUT_ETIQUETA" OR bConfEvento.situacao <> "CONCLUIDO" OR
           bConfEvento.tipo-evento <> pcTipo THEN NEXT.
        IF bConfAudit.dados-atu = ? OR NUM-ENTRIES(bConfAudit.dados-atu,"|") < 4 THEN NEXT.
        IF ENTRY(1,bConfAudit.dados-atu,"|") <> "DT121" OR
           ENTRY(2,bConfAudit.dados-atu,"|") <> pcTipo THEN NEXT.
        IF pcContexto = "" OR ENTRY(3,bConfAudit.dados-atu,"|") = pcContexto THEN RETURN YES.
    END.
    RETURN NO.
END FUNCTION.

/* DT133: ocorrencia vigente, nao enum fisico. Vinculo/retirada de Bag e
   confirmacoes nao apagam o dano; somente a correcao explicita o encerra. */
FUNCTION fEmEventoInutilizacao RETURNS INTEGER (INPUT piEtiqueta AS INTEGER):
    DEFINE BUFFER bInutMov FOR mgesp.contr_emb_movto.
    DEFINE BUFFER bInutEv FOR mgesp.contr_emb_evento.
    IF piEtiqueta = ? OR piEtiqueta <= 0 THEN RETURN 0.
    FOR EACH bInutMov NO-LOCK WHERE bInutMov.id-etiqueta = piEtiqueta
        AND (bInutMov.tipo-movto = "INUTILIZACAO_EMBALAGEM"
          OR bInutMov.tipo-movto = "CORRECAO_INUTILIZACAO")
        BY bInutMov.id-movto DESCENDING:
        FIND FIRST bInutEv NO-LOCK WHERE bInutEv.id-evento = bInutMov.id-evento NO-ERROR.
        IF NOT AVAILABLE bInutEv THEN NEXT.
        IF bInutEv.situacao = ? OR bInutEv.situacao <> "CONCLUIDO" THEN NEXT.
        IF bInutMov.tipo-movto = "CORRECAO_INUTILIZACAO"
            AND bInutEv.origem = "ESTORNO_ETIQUETA"
            AND bInutEv.tipo-evento = "CORRECAO_INUTILIZACAO" THEN RETURN 0.
        IF bInutMov.tipo-movto = "INUTILIZACAO_EMBALAGEM"
            AND bInutEv.origem = "INUTIL_ETIQUETA"
            AND bInutEv.tipo-evento = "INUTILIZACAO_EMBALAGEM" THEN RETURN bInutEv.id-evento.
    END.
    RETURN 0.
END FUNCTION.

/* DT135: somente perda vigente, mesmo contexto/custodia, permite correcao. */
FUNCTION fEmEventoPerda RETURNS INTEGER (INPUT piEtiqueta AS INTEGER):
    DEFINE BUFFER bPerdaEt FOR mgesp.contr_emb_etiqueta.
    DEFINE BUFFER bPerdaMv FOR mgesp.contr_emb_movto.
    DEFINE BUFFER bPerdaEv FOR mgesp.contr_emb_evento.
    FIND FIRST bPerdaEt NO-LOCK WHERE bPerdaEt.id-etiqueta = piEtiqueta NO-ERROR.
    IF NOT AVAILABLE bPerdaEt THEN RETURN 0.
    IF bPerdaEt.situacao = ? OR bPerdaEt.situacao <> "ENCERRADA" OR
        bPerdaEt.qtidade-atu = ? OR bPerdaEt.qtidade-atu <> 0 OR bPerdaEt.id-movto-ult = ? THEN RETURN 0.
    FIND FIRST bPerdaMv NO-LOCK WHERE bPerdaMv.id-movto = bPerdaEt.id-movto-ult
        AND bPerdaMv.id-etiqueta = piEtiqueta AND bPerdaMv.tipo-movto = "PERDA_EXTRAVIO_EMBALAGEM" NO-ERROR.
    IF NOT AVAILABLE bPerdaMv THEN RETURN 0.
    IF bPerdaMv.situacao-atu = ? OR bPerdaMv.situacao-atu <> "ENCERRADA" OR
        bPerdaMv.qtidade-atu = ? OR bPerdaMv.qtidade-atu <> 0 OR
        bPerdaMv.cod-estabel-dest = ? OR bPerdaMv.cod-estabel-dest <> bPerdaEt.cod-estabel OR
        bPerdaMv.tipo-local-dest = ? OR bPerdaMv.tipo-local-dest <> bPerdaEt.tipo-local OR
        LOOKUP(bPerdaEt.tipo-local,"ESTAB,CAMPO,TERCEIRO,TRANSITO") = 0 OR
        NOT fEmPosicaoIgual(STRING(bPerdaMv.cod-emitente-dest),STRING(bPerdaEt.cod-emitente-posse)) OR
        NOT fEmPosicaoIgual(bPerdaMv.origem-local-ext-dest,bPerdaEt.origem-local-ext) OR
        NOT fEmPosicaoIgual(bPerdaMv.cod-local-ext-dest,bPerdaEt.cod-local-ext) OR
        NOT fEmPosicaoIgual(bPerdaMv.cod-depos-dest,bPerdaEt.cod-depos) OR
        NOT fEmPosicaoIgual(bPerdaMv.cod-localiz-dest,bPerdaEt.cod-localiz) THEN RETURN 0.
    FIND FIRST bPerdaEv NO-LOCK WHERE bPerdaEv.id-evento = bPerdaMv.id-evento
        AND bPerdaEv.origem = "PERDA_ETIQUETA" AND bPerdaEv.tipo-evento = "PERDA_EXTRAVIO_EMBALAGEM"
        AND bPerdaEv.cod-estabel = bPerdaEt.cod-estabel
        AND bPerdaEv.situacao = "CONCLUIDO" NO-ERROR.
    IF NOT AVAILABLE bPerdaEv THEN RETURN 0.
    RETURN bPerdaEv.id-evento.
END FUNCTION.

FUNCTION fEmResumo RETURNS CHARACTER (INPUT piEtiqueta AS INTEGER):
    DEFINE BUFFER bResumo FOR mgesp.contr_emb_etiqueta.
    FIND FIRST bResumo NO-LOCK WHERE bResumo.id-etiqueta = piEtiqueta NO-ERROR.
    IF NOT AVAILABLE bResumo THEN RETURN "DESCONHECIDA".
    IF bResumo.tipo-controle = "PRE_SALDO" THEN RETURN "SEM_CONTROLE_INDIVIDUAL".
    IF bResumo.situacao = "CANCELADA" THEN RETURN "CANCELADA".
    IF bResumo.situacao = "DESCARTADA" THEN RETURN "DESCARTADA".
    IF bResumo.id-bag <> ? THEN RETURN "EM_BAG".
    IF bResumo.situacao = "ATIVA" AND bResumo.tipo-local = "ESTAB"
        AND fEmEventoInutilizacao(piEtiqueta) > 0 THEN RETURN "INUTILIZADA".
    /* Disponivel zero nao confirma retorno fisico vazio do campo. */
    IF bResumo.situacao = "ATIVA" AND bResumo.tipo-local = "CAMPO" THEN RETURN "EM_CAMPO".
    IF bResumo.situacao = "ENCERRADA" THEN RETURN "ENCERRADA".
    IF bResumo.qtidade-atu = 0 THEN RETURN "ZERADA".
    CASE bResumo.tipo-local:
        WHEN "CAMPO" THEN RETURN "EM_CAMPO".
        WHEN "TRANSITO" THEN RETURN "AGUARDANDO_RECEBIMENTO".
        WHEN "TERCEIRO" THEN RETURN "EM_TERCEIRO".
        WHEN "ESTAB" THEN DO:
            IF NOT fEmConfirmada(piEtiqueta,"CONFIRMACAO_IMPRESSAO","") THEN RETURN "NAO_IMPRESSA".
            IF NOT fEmConfirmada(piEtiqueta,"RECEBIMENTO_FISICO",fEmContexto(piEtiqueta)) THEN RETURN "IMPRESSA".
            RETURN "EM_ESTOQUE".
        END.
    END CASE.
    RETURN "DESCONHECIDA".
END FUNCTION.

FUNCTION fEmDescricao RETURNS CHARACTER (INPUT pcSituacao AS CHARACTER):
    CASE pcSituacao:
        WHEN "NAO_IMPRESSA" THEN RETURN "Nao impressa".
        WHEN "IMPRESSA" THEN RETURN "Impressa - aguardando recebimento fisico".
        WHEN "EM_ESTOQUE" THEN RETURN "Em estoque".
        WHEN "EM_CAMPO" THEN RETURN "Em campo".
        WHEN "AGUARDANDO_RECEBIMENTO" THEN RETURN "Aguardando recebimento".
        WHEN "EM_TERCEIRO" THEN RETURN "Em terceiro".
        WHEN "EM_BAG" THEN RETURN "Em Bag".
        WHEN "INUTILIZADA" THEN RETURN "Inutilizada".
        WHEN "ZERADA" THEN RETURN "Zerada".
        WHEN "DESCARTADA" THEN RETURN "Descartada".
        WHEN "CANCELADA" THEN RETURN "Cancelada".
        WHEN "ENCERRADA" THEN RETURN "Encerrada".
        WHEN "SEM_CONTROLE_INDIVIDUAL" THEN RETURN "Sem controle individual".
    END CASE.
    RETURN "Desconhecida".
END FUNCTION.
