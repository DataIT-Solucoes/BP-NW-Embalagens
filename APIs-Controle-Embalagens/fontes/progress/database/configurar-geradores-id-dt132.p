/* DT132 R6: vincula somente as nove sequencias novas *_ID_SEQ.
   Executar na sessao ADMINISTRATIVA TESTE depois dos dois incrementos DF.
   Nao consome sequencias, nao altera Oracle nem os dez vinculos tecnicos. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE BUFFER bSeq FOR shmgesp._Sequence.
DEFINE VARIABLE antigos AS CHARACTER NO-UNDO INITIAL "CONTR_EMB_AUDIT_SEQ,CONTR_EMB_BAG_LACRE_SEQ,CONTR_EMB_BAG_SEQ,CONTR_EMB_ETIQUETA_SEQ,CONTR_EMB_EVENTO_ITEM_SEQ,CONTR_EMB_EVENTO_SEQ,CONTR_EMB_MOVTO_SEQ,CONTR_EMB_OPER_ITEM_SEQ,CONTR_EMB_OPER_SEQ,CONTR_EMB_PARAM_SEQ".
DEFINE VARIABLE novos AS CHARACTER NO-UNDO INITIAL "CONTR_EMB_AUDIT_ID_SEQ,CONTR_EMB_BAG_LACRE_ID_SEQ,CONTR_EMB_ETIQUETA_ID_SEQ,CONTR_EMB_EVENTO_ID_SEQ,CONTR_EMB_EVENTO_ITEM_ID_SEQ,CONTR_EMB_MOVTO_ID_SEQ,CONTR_EMB_OPER_ID_SEQ,CONTR_EMB_OPER_ITEM_ID_SEQ,CONTR_EMB_PARAM_ID_SEQ".
DEFINE VARIABLE nome AS CHARACTER NO-UNDO.
DEFINE VARIABLE caminhoHolder AS CHARACTER NO-UNDO.
DEFINE VARIABLE relatorio AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE atualizadas AS INTEGER NO-UNDO.
DEFINE VARIABLE falhas AS INTEGER NO-UNDO.
DEFINE STREAM sRel.
relatorio = SESSION:TEMP-DIRECTORY + "configuracao-geradores-dt132.txt".
OUTPUT STREAM sRel TO VALUE(relatorio).
PUT STREAM sRel UNFORMATTED "DT132_MAPEAMENTO|REVISAO=R6|OpenEdge=" PROVERSION "|INSTANTE=" NOW SKIP.
DO ON ERROR UNDO, THROW:
    IF NOT CONNECTED("shmgesp") OR NOT CONNECTED("mgesp") THEN
        UNDO, THROW NEW Progress.Lang.AppError("CONEXOES_OBRIGATORIAS_SHMGESP_MGESP",0).
    caminhoHolder = CAPS(REPLACE(PDBNAME("shmgesp"),CHR(92),"/")).
    IF caminhoHolder = ? OR INDEX(caminhoHolder,"/TESTE/") = 0 OR INDEX(caminhoHolder,"SHEMS2ESP") = 0 THEN
        UNDO, THROW NEW Progress.Lang.AppError("HOLDER_FORA_DO_CAMINHO_TESTE",0).
    PUT STREAM sRel UNFORMATTED "HOLDER=" caminhoHolder SKIP.
    DO TRANSACTION ON ERROR UNDO, THROW:
        /* Confere todos antes de escrever; duplicacao entre imagens e recusada. */
        DO i = 1 TO NUM-ENTRIES(antigos) + NUM-ENTRIES(novos):
            ASSIGN nome = IF i <= NUM-ENTRIES(antigos) THEN ENTRY(i,antigos)
                          ELSE ENTRY(i - NUM-ENTRIES(antigos),novos)
                   n = 0.
            FOR EACH bSeq WHERE bSeq._Seq-Name = nome EXCLUSIVE-LOCK:
                n = n + 1.
                IF i <= NUM-ENTRIES(antigos) THEN DO:
                    IF bSeq._Seq-Misc[1] = ? OR bSeq._Seq-Misc[1] <> nome
                       OR bSeq._Seq-Misc[2] = ? OR bSeq._Seq-Misc[2] <> "EMS2ESP" THEN
                        UNDO, THROW NEW Progress.Lang.AppError("VINCULO_TECNICO_DIVERGENTE:" + nome,0).
                END.
                ELSE DO:
                    IF bSeq._Seq-Misc[1] <> ? AND bSeq._Seq-Misc[1] <> "" AND bSeq._Seq-Misc[1] <> nome THEN
                        UNDO, THROW NEW Progress.Lang.AppError("VINCULO_ID_DIVERGENTE:" + nome,0).
                    IF bSeq._Seq-Misc[2] <> ? AND bSeq._Seq-Misc[2] <> "" AND bSeq._Seq-Misc[2] <> "EMS2ESP" THEN
                        UNDO, THROW NEW Progress.Lang.AppError("OWNER_ID_DIVERGENTE:" + nome,0).
                END.
            END.
            IF n <> 1 THEN UNDO, THROW NEW Progress.Lang.AppError("SEQUENCIA_AUSENTE_OU_DUPLICADA:" + nome,0).
        END.
        DO i = 1 TO NUM-ENTRIES(novos):
            nome = ENTRY(i,novos).
            FIND FIRST bSeq WHERE bSeq._Seq-Name = nome EXCLUSIVE-LOCK.
            ASSIGN bSeq._Seq-Misc[1] = nome bSeq._Seq-Misc[2] = "EMS2ESP"
                   atualizadas = atualizadas + 1.
        END.
    END.
    DO i = 1 TO NUM-ENTRIES(novos):
        nome = ENTRY(i,novos).
        PUT STREAM sRel UNFORMATTED "VINCULO_ID|NOME=" nome "|MISC1=" nome "|MISC2=EMS2ESP" SKIP.
    END.
    CATCH erro AS Progress.Lang.Error:
        falhas = 1.
        PUT STREAM sRel UNFORMATTED "ERRO=" erro:GetMessage(1) SKIP.
    END CATCH.
    FINALLY:
        PUT STREAM sRel UNFORMATTED "NOVOS_CONFIGURADOS=" (IF falhas = 0 THEN atualizadas ELSE 0)
            "|TECNICOS_ALTERADOS=0|FALHAS=" falhas "|SEQUENCIAS_CONSUMIDAS=0" SKIP.
        OUTPUT STREAM sRel CLOSE.
    END FINALLY.
END.
MESSAGE relatorio VIEW-AS ALERT-BOX INFORMATION.
IF falhas > 0 THEN RETURN ERROR "CONFIGURACAO_GERADORES_FALHOU".
