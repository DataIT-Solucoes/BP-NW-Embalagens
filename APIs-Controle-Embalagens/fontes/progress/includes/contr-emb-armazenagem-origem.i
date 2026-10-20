/* DT-103: retorno externo identifica a remessa da fazenda, nao uma saida do terceiro. */
PROCEDURE resolverOrigemArmazenagem:
DEFINE INPUT PARAMETER prDocumento AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER piInformado AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piDocumento AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piOperacao AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcOrigem AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcSerie AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcNumero AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcChave AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plAplicavel AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bArmEntrada FOR mgmov.docum-est.
DEFINE BUFFER bArmLinha FOR mgmov.item-doc-est.
DEFINE BUFFER bArmDoc FOR mgesp.contr_emb_evento.
DEFINE BUFFER bArmVinc FOR mgesp.contr_emb_evento.
DEFINE BUFFER bArmOper FOR mgesp.contr_emb_oper.
DEFINE BUFFER bArmNota FOR mgmov.nota-fiscal.
DEFINE BUFFER bArmNat FOR mgcad.natur-oper.
DEFINE VARIABLE cSerieRef AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNumeroRef AS CHARACTER NO-UNDO.
DEFINE VARIABLE iNotas AS INTEGER NO-UNDO.
DEFINE VARIABLE iDocumentos AS INTEGER NO-UNDO.
DEFINE VARIABLE iVinculos AS INTEGER NO-UNDO.
DEFINE VARIABLE iOperVinculo AS INTEGER NO-UNDO.
ASSIGN piDocumento = 0 piOperacao = 0 pcOrigem = "" pcSerie = "" pcNumero = ""
    pcChave = "" plAplicavel = NO plSucesso = NO pcErro = "ARM_ORIGEM_INVALIDA"
    pcMensagem = "Informar referencia completa da remessa original.".
IF prDocumento = ? OR piInformado = ? OR piInformado < 0 THEN RETURN.
FIND FIRST bArmEntrada NO-LOCK WHERE ROWID(bArmEntrada) = prDocumento NO-ERROR.
IF NOT AVAILABLE bArmEntrada THEN RETURN.
FIND FIRST bArmNat NO-LOCK WHERE bArmNat.nat-operacao = bArmEntrada.nat-operacao NO-ERROR.
IF NOT AVAILABLE bArmNat OR bArmNat.especie-doc = ? OR
   CAPS(TRIM(bArmNat.especie-doc)) <> "NFE" OR bArmNat.terceiros = ? OR bArmNat.terceiros <> YES OR
   bArmNat.tp-oper-terc = ? OR bArmNat.tp-oper-terc <> 5 THEN RETURN.
pcChave = "ENTRADA|" + STRING(LENGTH(bArmEntrada.cod-estabel)) + ":" + bArmEntrada.cod-estabel
    + "|" + STRING(bArmEntrada.cod-emitente)
    + "|" + STRING(LENGTH(bArmEntrada.serie-docto)) + ":" + bArmEntrada.serie-docto
    + "|" + STRING(LENGTH(bArmEntrada.nro-docto)) + ":" + bArmEntrada.nro-docto
    + "|" + bArmEntrada.nat-operacao.
FOR EACH bArmVinc NO-LOCK WHERE bArmVinc.chave-docto = pcChave
    AND bArmVinc.tipo-evento = "VINCULO_ENTRADA_SAIDA":
    ASSIGN iVinculos = iVinculos + 1 plAplicavel = YES.
    IF bArmVinc.situacao <> "CONCLUIDO" OR bArmVinc.id-evento-origem = ? OR
       bArmVinc.id-evento-origem <= 0 THEN RETURN.
    ASSIGN piDocumento = bArmVinc.id-evento-origem iOperVinculo = bArmVinc.id-operacao.
END.
IF iVinculos > 1 THEN DO:
    pcErro = "ARM_VINCULO_AMBIGUO".
    RETURN.
END.
IF piInformado > 0 THEN DO:
    plAplicavel = YES.
    IF piDocumento > 0 AND piDocumento <> piInformado THEN DO:
        pcErro = "ARM_VINCULO_DIVERGENTE".
        RETURN.
    END.
    piDocumento = piInformado.
END.
IF piDocumento = 0 AND NOT CAN-FIND(FIRST bArmOper WHERE
    bArmOper.tipo-operacao = "REMESSA_TERCEIROS"
    AND bArmOper.cod-estabel-orig = bArmEntrada.cod-estabel
    AND bArmOper.cod-emitente = bArmEntrada.cod-emitente) THEN DO:
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "Entrada sem remessa do projeto.".
    RETURN.
END.
/* Todo item precisa apontar a mesma remessa; nao usar cabecalho do retorno externo. */
FOR EACH bArmLinha OF bArmEntrada NO-LOCK:
    IF fRecTexto(bArmLinha.serie-comp) = "" OR fRecTexto(bArmLinha.nro-comp) = "" THEN DO:
        ASSIGN plAplicavel = YES pcErro = "ARM_REFERENCIA_INCOMPLETA".
        RETURN.
    END.
    IF cNumeroRef <> "" AND (cSerieRef <> fRecTexto(bArmLinha.serie-comp) OR
       cNumeroRef <> fRecTexto(bArmLinha.nro-comp)) THEN DO:
        ASSIGN plAplicavel = YES pcErro = "ARM_MULTIPLAS_REMESSAS".
        RETURN.
    END.
    ASSIGN cSerieRef = fRecTexto(bArmLinha.serie-comp) cNumeroRef = fRecTexto(bArmLinha.nro-comp).
END.
IF cNumeroRef = "" THEN RETURN.
FOR EACH bArmDoc NO-LOCK WHERE bArmDoc.tipo-evento = "DOCUMENTO_SAIDA_FLUIG"
    AND bArmDoc.tipo-docto = "SAIDA" AND bArmDoc.cod-estabel = bArmEntrada.cod-estabel
    AND bArmDoc.cod-emitente = bArmEntrada.cod-emitente
    AND bArmDoc.serie = cSerieRef AND bArmDoc.nro-docto = cNumeroRef:
    FIND FIRST bArmOper NO-LOCK WHERE bArmOper.id-operacao = bArmDoc.id-operacao NO-ERROR.
    IF NOT AVAILABLE bArmOper OR bArmOper.tipo-operacao <> "REMESSA_TERCEIROS" THEN NEXT.
    ASSIGN plAplicavel = YES iDocumentos = iDocumentos + 1.
    IF piDocumento > 0 AND piDocumento <> bArmDoc.id-evento THEN DO:
        pcErro = "ARM_REFERENCIA_DIVERGENTE".
        RETURN.
    END.
    piDocumento = bArmDoc.id-evento.
END.
IF iDocumentos <> 1 THEN DO:
    ASSIGN pcErro = "ARM_REMESSA_NAO_UNICA" pcMensagem = "Referencia nao identifica uma remessa rastreada unica.".
    RETURN.
END.
FIND FIRST bArmDoc NO-LOCK WHERE bArmDoc.id-evento = piDocumento NO-ERROR.
FIND FIRST bArmOper NO-LOCK WHERE bArmOper.id-operacao = bArmDoc.id-operacao NO-ERROR.
IF NOT AVAILABLE bArmOper OR bArmDoc.situacao <> "CONCLUIDO" OR
   bArmOper.cod-estabel-orig <> bArmEntrada.cod-estabel OR
   bArmOper.cod-emitente <> bArmEntrada.cod-emitente OR
   (iVinculos = 1 AND iOperVinculo <> bArmOper.id-operacao) THEN RETURN.
FOR EACH bArmNota NO-LOCK WHERE bArmNota.cod-estabel = bArmDoc.cod-estabel
    AND bArmNota.serie = bArmDoc.serie AND bArmNota.nr-nota-fis = bArmDoc.nro-docto:
    iNotas = iNotas + 1.
END.
IF iNotas <> 1 THEN RETURN.
FIND FIRST bArmNota NO-LOCK WHERE bArmNota.cod-estabel = bArmDoc.cod-estabel
    AND bArmNota.serie = bArmDoc.serie AND bArmNota.nr-nota-fis = bArmDoc.nro-docto NO-ERROR.
FIND FIRST bArmNat NO-LOCK WHERE bArmNat.nat-operacao = bArmNota.nat-operacao NO-ERROR.
IF NOT AVAILABLE bArmNat OR bArmNat.especie-doc = ? OR
   LOOKUP(CAPS(TRIM(bArmNat.especie-doc)), "NFS,NFT") = 0 OR
   bArmNat.terceiros = ? OR bArmNat.terceiros <> YES OR
   bArmNat.tp-oper-terc = ? OR bArmNat.tp-oper-terc <> 3 OR
   bArmNota.cod-emitente <> bArmEntrada.cod-emitente OR
   bArmNota.nat-operacao <> bArmDoc.nat-operacao OR
   bArmOper.seq-wt-docto = ? OR bArmOper.seq-wt-docto <= 0 OR
   fRecTexto(SUBSTRING(bArmNota.char-2, 1500, 20)) <> "CEWT1:" + STRING(bArmOper.seq-wt-docto) THEN RETURN.
ASSIGN piOperacao = bArmOper.id-operacao pcOrigem = bArmDoc.cod-estabel
    pcSerie = bArmDoc.serie pcNumero = bArmDoc.nro-docto
    plAplicavel = YES plSucesso = YES pcErro = "" pcMensagem = "".
END PROCEDURE.

PROCEDURE validarOrigemArmazenagem:
DEFINE INPUT PARAMETER prDocumento AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER piDocumento AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE VARIABLE iDocumento AS INTEGER NO-UNDO.
DEFINE VARIABLE iOperacao AS INTEGER NO-UNDO.
DEFINE VARIABLE cOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSerie AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNumero AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChave AS CHARACTER NO-UNDO.
DEFINE VARIABLE lAplicavel AS LOGICAL NO-UNDO.
RUN resolverOrigemArmazenagem(INPUT prDocumento, INPUT piDocumento,
    OUTPUT iDocumento, OUTPUT iOperacao, OUTPUT cOrigem, OUTPUT cSerie,
    OUTPUT cNumero, OUTPUT cChave, OUTPUT lAplicavel, OUTPUT plSucesso,
    OUTPUT pcErro, OUTPUT pcMensagem).
IF NOT lAplicavel OR iDocumento <> piDocumento THEN plSucesso = NO.
END PROCEDURE.
