/* Configura o vinculo das dez sequencias CONTR_EMB no schema holder.
   Nao chama NEXT-VALUE, nao altera valores correntes e nao grava no Oracle. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE cSequencias AS CHARACTER NO-UNDO INITIAL
    "CONTR_EMB_AUDIT_SEQ,CONTR_EMB_BAG_LACRE_SEQ,CONTR_EMB_BAG_SEQ,CONTR_EMB_ETIQUETA_SEQ,CONTR_EMB_EVENTO_ITEM_SEQ,CONTR_EMB_EVENTO_SEQ,CONTR_EMB_MOVTO_SEQ,CONTR_EMB_OPER_ITEM_SEQ,CONTR_EMB_OPER_SEQ,CONTR_EMB_PARAM_SEQ".
DEFINE VARIABLE iAtualizadas AS INTEGER NO-UNDO.

DO TRANSACTION ON ERROR UNDO, THROW:
    FOR EACH shmgesp._Sequence EXCLUSIVE-LOCK
        WHERE LOOKUP(CAPS(shmgesp._Sequence._Seq-Name), cSequencias) > 0:
        IF shmgesp._Sequence._Seq-Misc[1] <> ? AND
           shmgesp._Sequence._Seq-Misc[1] <> CAPS(shmgesp._Sequence._Seq-Name) THEN
            UNDO, THROW NEW Progress.Lang.AppError(
                "A sequencia " + shmgesp._Sequence._Seq-Name +
                " ja possui outro nome fisico.", 0).

        IF shmgesp._Sequence._Seq-Misc[2] <> ? AND
           shmgesp._Sequence._Seq-Misc[2] <> "EMS2ESP" THEN
            UNDO, THROW NEW Progress.Lang.AppError(
                "A sequencia " + shmgesp._Sequence._Seq-Name +
                " ja possui outro owner fisico.", 0).

        ASSIGN shmgesp._Sequence._Seq-Misc[1] = CAPS(shmgesp._Sequence._Seq-Name)
               shmgesp._Sequence._Seq-Misc[2] = "EMS2ESP"
               iAtualizadas = iAtualizadas + 1.
    END.

    IF iAtualizadas <> 10 THEN
        UNDO, THROW NEW Progress.Lang.AppError(
            "Esperadas 10 sequencias; encontradas " + STRING(iAtualizadas) + ".", 0).
END.

MESSAGE
    "Metadados das sequencias configurados." SKIP
    "TOTAL=" iAtualizadas
    VIEW-AS ALERT-BOX INFORMATION.
