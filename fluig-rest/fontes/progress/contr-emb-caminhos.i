/* DT109: caminhos de TESTE por PROPATH, sem alterar a sessao. */
FUNCTION ceResolverPrograma RETURNS CHARACTER (INPUT pcRelativo AS CHARACTER):
    DEFINE VARIABLE cAchado AS CHARACTER NO-UNDO.
    IF pcRelativo = ? OR TRIM(pcRelativo) = "" THEN RETURN ?.
    cAchado = SEARCH("_bp/api/ET-01_TESTE/" + pcRelativo).
    IF cAchado = ? THEN cAchado = SEARCH(pcRelativo).
    RETURN cAchado.
END FUNCTION.
FUNCTION ceDiretorioDiagnostico RETURNS CHARACTER ():
    DEFINE VARIABLE cDiretorio AS CHARACTER NO-UNDO.
    cDiretorio = OS-GETENV("TEMP").
    IF cDiretorio = ? OR TRIM(cDiretorio) = "" THEN cDiretorio = OS-GETENV("TMP").
    IF cDiretorio = ? OR TRIM(cDiretorio) = "" THEN cDiretorio = SESSION:TEMP-DIRECTORY.
    IF cDiretorio = ? OR TRIM(cDiretorio) = "" THEN RETURN ?.
    cDiretorio = REPLACE(cDiretorio, CHR(92), "/").
    IF NOT cDiretorio ENDS "/" THEN cDiretorio = cDiretorio + "/".
    RETURN cDiretorio.
END FUNCTION.
FUNCTION ceArquivoPacote RETURNS CHARACTER (INPUT pcRelativo AS CHARACTER):
    DEFINE VARIABLE cAncora AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSufixo AS CHARACTER NO-UNDO INITIAL
        "fontes/progress/contr-emb-caminhos.i".
    IF pcRelativo = ? OR TRIM(pcRelativo) = "" THEN RETURN ?.
    cAncora = ceResolverPrograma(cSufixo).
    IF cAncora = ? THEN RETURN ?.
    cAncora = REPLACE(cAncora, CHR(92), "/").
    IF cAncora BEGINS "//" THEN RETURN ceDiretorioDiagnostico() + pcRelativo.
    RETURN SUBSTRING(cAncora, 1, LENGTH(cAncora) - LENGTH(cSufixo)) + pcRelativo.
END FUNCTION.
FUNCTION ceResolverUpc RETURNS CHARACTER (INPUT pcNome AS CHARACTER):
    DEFINE VARIABLE cAchado AS CHARACTER NO-UNDO.
    IF pcNome = ? OR TRIM(pcNome) = "" THEN RETURN ?.
    cAchado = SEARCH("_bp/EMS2/Upc/" + pcNome).
    IF cAchado = ? THEN cAchado = SEARCH("Upc/" + pcNome).
    IF cAchado = ? THEN cAchado = SEARCH(pcNome).
    /* Sonda local pode carregar adaptador compilado no pacote. */
    IF cAchado = ? THEN cAchado = ceResolverPrograma("testes/e04/" + pcNome).
    RETURN cAchado.
END FUNCTION.


