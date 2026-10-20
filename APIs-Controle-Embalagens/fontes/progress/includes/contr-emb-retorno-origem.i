/* DT-102: valida a cadeia retorno -> emprestimo sem escrever no ERP.
   Incluido pelo resolvedor comum; campos existentes do modelo implantado. */
PROCEDURE validarDocumentoRetorno:
DEFINE INPUT PARAMETER prEntrada AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER piDocumento AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER plValidarReferencia AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bRetEntrada FOR mgmov.docum-est.
DEFINE BUFFER bRetLinha FOR mgmov.item-doc-est.
DEFINE BUFFER bRetDoc FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRetRemessa FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRetOper FOR mgesp.contr_emb_oper.
DEFINE BUFFER bRetOrigem FOR mgesp.contr_emb_oper.
DEFINE BUFFER bRetCredor FOR mgcad.estabelec.
DEFINE BUFFER bRetDevedor FOR mgcad.estabelec.
DEFINE BUFFER bRetItem FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bRetItemOrig FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bRetNota FOR mgmov.nota-fiscal.
DEFINE VARIABLE iRemessas AS INTEGER NO-UNDO.
DEFINE VARIABLE iItens AS INTEGER NO-UNDO.
DEFINE VARIABLE cSerieRem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNumeroRem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSerieRef AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNumeroRef AS CHARACTER NO-UNDO.
ASSIGN plSucesso = NO pcErro = "REC_RETORNO_ORIGEM_INVALIDA"
    pcMensagem = "Retorno sem cadeia de emprestimo e contrapartes compativeis.".
FIND FIRST bRetEntrada NO-LOCK WHERE ROWID(bRetEntrada) = prEntrada NO-ERROR.
FIND FIRST bRetDoc NO-LOCK WHERE bRetDoc.id-evento = piDocumento NO-ERROR.
IF NOT AVAILABLE bRetEntrada OR NOT AVAILABLE bRetDoc OR
   bRetDoc.tipo-evento <> "DOCUMENTO_SAIDA_FLUIG" OR bRetDoc.situacao <> "CONCLUIDO" THEN RETURN.
FIND FIRST bRetOper NO-LOCK WHERE bRetOper.id-operacao = bRetDoc.id-operacao NO-ERROR.
IF NOT AVAILABLE bRetOper OR bRetOper.tipo-operacao <> "RETORNO_TERCEIROS" OR
   bRetOper.id-oper-origem = ? OR bRetOper.id-oper-origem <= 0 THEN RETURN.
FIND FIRST bRetOrigem NO-LOCK WHERE bRetOrigem.id-operacao = bRetOper.id-oper-origem NO-ERROR.
IF NOT AVAILABLE bRetOrigem OR bRetOrigem.tipo-operacao <> "REMESSA_TERCEIROS" OR
   bRetOrigem.cod-estabel-orig <> bRetEntrada.cod-estabel OR
   bRetOrigem.cod-estabel-dest <> bRetOper.cod-estabel-orig OR
   bRetDoc.cod-estabel <> bRetOper.cod-estabel-orig THEN RETURN.
FIND FIRST bRetCredor NO-LOCK WHERE bRetCredor.cod-estabel = bRetOrigem.cod-estabel-orig NO-ERROR.
FIND FIRST bRetDevedor NO-LOCK WHERE bRetDevedor.cod-estabel = bRetOper.cod-estabel-orig NO-ERROR.
IF NOT AVAILABLE bRetCredor OR NOT AVAILABLE bRetDevedor OR
   bRetEntrada.cod-emitente <> bRetDevedor.cod-emitente OR
   bRetOper.cod-emitente <> bRetCredor.cod-emitente OR
   bRetOrigem.cod-emitente <> bRetDevedor.cod-emitente OR
   bRetDoc.cod-emitente <> bRetCredor.cod-emitente THEN RETURN.
/* A remessa documental original deve ser unica e conservar seu WT na nota. */
FOR EACH bRetRemessa NO-LOCK WHERE bRetRemessa.id-operacao = bRetOrigem.id-operacao
    AND bRetRemessa.tipo-evento = "DOCUMENTO_SAIDA_FLUIG"
    AND bRetRemessa.tipo-docto = "SAIDA":
    IF bRetRemessa.situacao <> "CONCLUIDO" OR
       bRetRemessa.cod-estabel <> bRetCredor.cod-estabel OR
       bRetRemessa.cod-emitente <> bRetDevedor.cod-emitente THEN RETURN.
    ASSIGN iRemessas = iRemessas + 1 cSerieRem = bRetRemessa.serie
        cNumeroRem = bRetRemessa.nro-docto.
    FIND FIRST bRetNota NO-LOCK WHERE bRetNota.cod-estabel = bRetRemessa.cod-estabel
        AND bRetNota.serie = bRetRemessa.serie AND bRetNota.nr-nota-fis = bRetRemessa.nro-docto NO-ERROR.
    IF NOT AVAILABLE bRetNota OR bRetNota.cod-emitente <> bRetDevedor.cod-emitente OR
       bRetNota.nat-operacao <> bRetRemessa.nat-operacao OR
       bRetOrigem.seq-wt-docto = ? OR bRetOrigem.seq-wt-docto <= 0 OR
       fRecTexto(SUBSTRING(bRetNota.char-2, 1500, 20)) <>
           "CEWT1:" + STRING(bRetOrigem.seq-wt-docto) THEN RETURN.
END.
IF iRemessas <> 1 THEN RETURN.
/* Linhas do retorno apontam as mesmas etiquetas/linhas da remessa original. */
FOR EACH bRetItem NO-LOCK WHERE bRetItem.id-operacao = bRetOper.id-operacao
    AND bRetItem.tipo-item = "SOLICITACAO":
    FIND FIRST bRetItemOrig NO-LOCK WHERE bRetItemOrig.id-item-oper = bRetItem.id-item-origem NO-ERROR.
    IF NOT AVAILABLE bRetItemOrig OR bRetItemOrig.id-operacao <> bRetOrigem.id-operacao OR
       bRetItemOrig.tipo-item <> "SOLICITACAO" OR
       bRetItemOrig.quantidade = ? OR bRetItemOrig.quantidade <= 0 OR
       bRetItemOrig.id-etiqueta <> bRetItem.id-etiqueta OR
       bRetItemOrig.it-codigo <> bRetItem.it-codigo OR bRetItemOrig.un <> bRetItem.un OR
       bRetItemOrig.lote <> bRetItem.lote OR bRetItemOrig.dt-vali-lote <> bRetItem.dt-vali-lote OR
       bRetItem.quantidade = ? OR bRetItem.quantidade <= 0 OR
       bRetItem.quantidade > bRetItemOrig.quantidade THEN RETURN.
    iItens = iItens + 1.
END.
IF iItens = 0 THEN RETURN.
IF NOT plValidarReferencia THEN DO:
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    RETURN.
END.
/* serie-comp/nro-comp podem representar a remessa selecionada no RE1001J.
   Nao escolhem qual nota de retorno receber. Referencia completa e exata. */
FOR EACH bRetLinha OF bRetEntrada NO-LOCK:
    IF (fRecTexto(bRetLinha.serie-comp) = "") <> (fRecTexto(bRetLinha.nro-comp) = "") THEN DO:
        ASSIGN pcErro = "REC_ORIGEM_PARCIAL" pcMensagem = "Referencia de item parcialmente preenchida.".
        RETURN.
    END.
    IF fRecTexto(bRetLinha.nro-comp) = "" THEN NEXT.
    IF cNumeroRef <> "" AND (cNumeroRef <> fRecTexto(bRetLinha.nro-comp) OR
       cSerieRef <> fRecTexto(bRetLinha.serie-comp)) THEN DO:
        ASSIGN pcErro = "REC_MULTIPLAS_ORIGENS" pcMensagem = "Itens apontam referencias diferentes.".
        RETURN.
    END.
    ASSIGN cSerieRef = fRecTexto(bRetLinha.serie-comp) cNumeroRef = fRecTexto(bRetLinha.nro-comp).
    IF NOT ((cSerieRef = cSerieRem AND cNumeroRef = cNumeroRem) OR
            (cSerieRef = bRetDoc.serie AND cNumeroRef = bRetDoc.nro-docto)) THEN DO:
        ASSIGN pcErro = "REC_REFERENCIA_DIVERGENTE"
            pcMensagem = "Referencia nao corresponde a remessa original nem a saida do retorno.".
        RETURN.
    END.
END.
ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
END PROCEDURE.
