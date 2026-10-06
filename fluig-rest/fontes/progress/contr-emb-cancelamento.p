/* Encerramento documental. Nao escreve em estoque, etiquetas ou movimentos. */
PROCEDURE concluirCancelamentoNota:
DEFINE INPUT PARAMETER prNota AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER pcUsuario AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plAplicavel AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piOperacao AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bNota FOR mgmov.nota-fiscal.
DEFINE BUFFER bOutraNota FOR mgmov.nota-fiscal.
DEFINE BUFFER bDoc FOR mgesp.contr_emb_evento.
DEFINE BUFFER bTodos FOR mgesp.contr_emb_evento.
DEFINE BUFFER bOper FOR mgesp.contr_emb_oper.
DEFINE VARIABLE iDocs AS INTEGER NO-UNDO.
DEFINE VARIABLE iDoc AS INTEGER NO-UNDO.
DEFINE VARIABLE lValido AS LOGICAL NO-UNDO.
DEFINE VARIABLE lTodosCancelados AS LOGICAL NO-UNDO INITIAL YES.

ASSIGN plAplicavel = NO plSucesso = NO plRepeticao = NO
    piOperacao = 0 pcErro = "CANCELAMENTO_PARAMETRO_INVALIDO" pcMensagem = "".
IF prNota = ? OR pcUsuario = ? OR TRIM(pcUsuario) = "" THEN RETURN.
FIND bNota NO-LOCK WHERE ROWID(bNota) = prNota NO-ERROR.
IF NOT AVAILABLE bNota THEN DO:
    pcErro = "CANCELAMENTO_NOTA_AUSENTE".
    RETURN.
END.
FOR EACH bDoc NO-LOCK WHERE bDoc.tipo-evento = "DOCUMENTO_SAIDA_FLUIG"
    AND bDoc.tipo-docto = "SAIDA" AND bDoc.cod-estabel = bNota.cod-estabel
    AND bDoc.serie = bNota.serie AND bDoc.nro-docto = bNota.nr-nota-fis
    AND bDoc.cod-emitente = bNota.cod-emitente:
    ASSIGN iDocs = iDocs + 1 iDoc = bDoc.id-evento piOperacao = bDoc.id-operacao.
END.
IF iDocs = 0 THEN DO:
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "Nota sem operacao especifica.".
    RETURN.
END.
plAplicavel = YES.
IF iDocs <> 1 OR piOperacao = ? OR piOperacao <= 0 THEN DO:
    pcErro = "CANCELAMENTO_VINCULO_AMBIGUO".
    RETURN.
END.

fechamento: DO TRANSACTION ON ERROR UNDO, THROW:
    FIND bOper WHERE bOper.id-operacao = piOperacao EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
    IF NOT AVAILABLE bOper OR LOCKED bOper THEN DO:
        pcErro = "CANCELAMENTO_OPERACAO_BLOQUEADA".
        UNDO fechamento, LEAVE fechamento.
    END.
    RUN validarDocumentoCancelado(iDoc, bOper.seq-wt-docto,
        OUTPUT lValido, OUTPUT pcErro).
    IF NOT lValido THEN UNDO fechamento, LEAVE fechamento.

    /* Operacao pode gerar varias notas: nunca encerra pelas demais ainda ativas. */
    FOR EACH bTodos NO-LOCK WHERE bTodos.id-operacao = piOperacao
        AND bTodos.tipo-evento = "DOCUMENTO_SAIDA_FLUIG"
        AND bTodos.tipo-docto = "SAIDA":
        FIND FIRST bOutraNota NO-LOCK
            WHERE bOutraNota.cod-estabel = bTodos.cod-estabel
              AND bOutraNota.serie = bTodos.serie
              AND bOutraNota.nr-nota-fis = bTodos.nro-docto NO-ERROR.
        IF NOT AVAILABLE bOutraNota THEN DO:
            pcErro = "CANCELAMENTO_NOTA_ASSOCIADA_AUSENTE".
            UNDO fechamento, LEAVE fechamento.
        END.
        IF bOutraNota.dt-cancela = ? THEN DO:
            lTodosCancelados = NO.
            NEXT.
        END.
        RUN validarDocumentoCancelado(bTodos.id-evento, bOper.seq-wt-docto,
            OUTPUT lValido, OUTPUT pcErro).
        IF NOT lValido THEN UNDO fechamento, LEAVE fechamento.
    END.
    IF NOT lTodosCancelados THEN DO:
        IF bOper.situacao = "CANCELADA" THEN DO:
            pcErro = "CANCELAMENTO_OPERACAO_DIVERGENTE".
            UNDO fechamento, LEAVE fechamento.
        END.
        ASSIGN plSucesso = YES pcErro = ""
            pcMensagem = "Cancelamento da nota confirmado; outras notas ainda abertas.".
        LEAVE fechamento.
    END.
    IF bOper.situacao = "CANCELADA" THEN
        ASSIGN plSucesso = YES plRepeticao = YES pcErro = ""
            pcMensagem = "Operacao ja encerrada por cancelamento.".
    ELSE DO:
        ASSIGN bOper.situacao = "CANCELADA" bOper.dt-alteracao = NOW
            bOper.usuario-alteracao = pcUsuario bOper.versao = bOper.versao + 1
            plSucesso = YES pcErro = "" pcMensagem = "Operacao encerrada por cancelamento.".
    END.
END.
END PROCEDURE.

PROCEDURE validarDocumentoCancelado:
DEFINE INPUT PARAMETER piDoc AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piWt AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plValido AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE BUFFER bDoc FOR mgesp.contr_emb_evento.
DEFINE BUFFER bNota FOR mgmov.nota-fiscal.
DEFINE BUFFER bSaida FOR mgesp.contr_emb_evento.
DEFINE BUFFER bReversao FOR mgesp.contr_emb_evento.
DEFINE VARIABLE iReversoes AS INTEGER NO-UNDO.
ASSIGN plValido = NO pcErro = "CANCELAMENTO_DOCUMENTO_INVALIDO".
FIND bDoc NO-LOCK WHERE bDoc.id-evento = piDoc NO-ERROR.
IF NOT AVAILABLE bDoc OR bDoc.situacao <> "CONCLUIDO" THEN RETURN.
FIND FIRST bNota NO-LOCK WHERE bNota.cod-estabel = bDoc.cod-estabel
    AND bNota.serie = bDoc.serie AND bNota.nr-nota-fis = bDoc.nro-docto NO-ERROR.
IF NOT AVAILABLE bNota THEN RETURN.
IF bNota.cod-emitente <> bDoc.cod-emitente OR bNota.nat-operacao <> bDoc.nat-operacao
    OR piWt = ? OR piWt <= 0 OR bNota.char-2 = ? OR
    TRIM(SUBSTRING(bNota.char-2, 1500, 20)) <> "CEWT1:" + STRING(piWt) THEN RETURN.
pcErro = "CANCELAMENTO_NAO_CONFIRMADO".
IF bNota.dt-cancela = ? THEN RETURN.
pcErro = "CANCELAMENTO_ESTOQUE_AINDA_CONFIRMADO".
IF bNota.dt-confirma <> ? THEN RETURN.
FOR EACH bSaida NO-LOCK WHERE bSaida.id-evento-origem = piDoc
    AND bSaida.tipo-evento = "SAIDA_ESTOQUE":
    pcErro = "CANCELAMENTO_SAIDA_INCOMPLETA".
    IF bSaida.situacao <> "CONCLUIDO" THEN RETURN.
    iReversoes = 0.
    FOR EACH bReversao NO-LOCK WHERE bReversao.id-evento-origem = bSaida.id-evento
        AND bReversao.tipo-evento = "DESATUALIZACAO_SAIDA":
        IF bReversao.situacao <> "CONCLUIDO" OR bReversao.id-operacao <> bDoc.id-operacao THEN RETURN.
        iReversoes = iReversoes + 1.
    END.
    pcErro = "CANCELAMENTO_COMPENSACAO_AUSENTE_OU_AMBIGUA".
    IF iReversoes <> 1 THEN RETURN.
END.
ASSIGN plValido = YES pcErro = "".
END PROCEDURE.

