/* DT129/130: contrato interno comum a selecao manual e automatica.
   Quantidades de origem devem vir do atendimento confirmado por embalagem.
   Planejamento nao movimenta ERP nem encerra vinculos. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

PROCEDURE ratearRetorno:
    DEFINE INPUT PARAMETER pdSaidaRm AS DECIMAL NO-UNDO.
    DEFINE INPUT PARAMETER pdSaidaDiv AS DECIMAL NO-UNDO.
    DEFINE INPUT PARAMETER pdRetorno AS DECIMAL NO-UNDO.
    DEFINE OUTPUT PARAMETER pdRetornoDiv AS DECIMAL NO-UNDO.
    DEFINE OUTPUT PARAMETER pdRetornoDrm AS DECIMAL NO-UNDO.
    DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
    ASSIGN pdRetornoDiv = 0 pdRetornoDrm = 0 pcErro = "QUANTIDADE_INVALIDA".
    IF pdSaidaRm = ? OR pdSaidaDiv = ? OR pdRetorno = ? OR
       pdSaidaRm < 0 OR pdSaidaDiv < 0 OR pdRetorno < 0 OR
       ROUND(pdSaidaRm,4) <> pdSaidaRm OR ROUND(pdSaidaDiv,4) <> pdSaidaDiv OR
       ROUND(pdRetorno,4) <> pdRetorno THEN RETURN.
    IF pdSaidaRm + pdSaidaDiv <= 0 THEN DO:
        pcErro = "ATENDIMENTO_SEM_QUANTIDADE". RETURN.
    END.
    IF pdRetorno > pdSaidaRm + pdSaidaDiv THEN DO:
        pcErro = "RETORNO_SUPERA_ENVIO". RETURN.
    END.
    ASSIGN pdRetornoDiv = MINIMUM(pdRetorno,pdSaidaDiv)
           pdRetornoDrm = pdRetorno - pdRetornoDiv
           pcErro = "".
END PROCEDURE.
