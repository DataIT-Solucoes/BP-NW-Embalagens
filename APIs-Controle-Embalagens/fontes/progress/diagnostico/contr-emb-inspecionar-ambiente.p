/* Diagnostico somente leitura para preparar o .df do Controle de Embalagens.
   Nao consulta dados de negocio e nao altera banco. */
DEFINE VARIABLE cArquivo AS CHARACTER NO-UNDO.
DEFINE VARIABLE iBanco   AS INTEGER   NO-UNDO.
DEFINE VARIABLE hBuffer  AS HANDLE    NO-UNDO.
DEFINE VARIABLE hCampo   AS HANDLE    NO-UNDO.

cArquivo = SESSION:TEMP-DIRECTORY + "contr-emb-ambiente.txt".
OUTPUT TO VALUE(cArquivo).

PUT UNFORMATTED
    "GERAL" SKIP
    "proversion=" PROVERSION SKIP
    "cpinternal=" SESSION:CPINTERNAL SKIP
    "cpstream=" SESSION:CPSTREAM SKIP
    "temp-directory=" SESSION:TEMP-DIRECTORY SKIP
    "propath=" PROPATH SKIP(1)
    "BANCOS" SKIP.

DO iBanco = 1 TO NUM-DBS:
    PUT UNFORMATTED
        "logical=" LDBNAME(iBanco)
        ";physical=" PDBNAME(iBanco)
        ";connected=" CONNECTED(LDBNAME(iBanco)) SKIP.
END.

PUT UNFORMATTED SKIP "CAMPOS" SKIP
    "tabela;campo;encontrado;tipo;formato;extent;obrigatorio" SKIP.

RUN inspecionarCampo("estabelec", "cod-estabel").
RUN inspecionarCampo("item", "it-codigo").
RUN inspecionarCampo("item", "un").
RUN inspecionarCampo("saldo-estoq", "lote").
RUN inspecionarCampo("saldo-estoq", "dt-vali-lote").
RUN inspecionarCampo("saldo-estoq", "cod-depos").
RUN inspecionarCampo("saldo-estoq", "cod-localiz").
RUN inspecionarCampo("emitente", "cod-emitente").
RUN inspecionarCampo("emitente", "cgc").
RUN inspecionarCampo("docum-est", "serie-docto").
RUN inspecionarCampo("docum-est", "nro-docto").
RUN inspecionarCampo("natur-oper", "nat-operacao").

OUTPUT CLOSE.
MESSAGE "Diagnostico concluido:" SKIP cArquivo VIEW-AS ALERT-BOX INFO.

PROCEDURE inspecionarCampo:
    DEFINE INPUT PARAMETER pcTabela AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcCampo  AS CHARACTER NO-UNDO.

    ASSIGN hBuffer = ?
           hCampo  = ?.

    CREATE BUFFER hBuffer FOR TABLE pcTabela NO-ERROR.
    IF VALID-HANDLE(hBuffer) THEN
        hCampo = hBuffer:BUFFER-FIELD(pcCampo) NO-ERROR.

    IF VALID-HANDLE(hCampo) THEN
        PUT UNFORMATTED
            pcTabela ";" pcCampo ";sim;"
            hCampo:DATA-TYPE ";"
            hCampo:FORMAT ";"
            hCampo:EXTENT ";"
            hCampo:MANDATORY SKIP.
    ELSE
        PUT UNFORMATTED pcTabela ";" pcCampo ";nao;;;;" SKIP.

    IF VALID-HANDLE(hBuffer) THEN DELETE OBJECT hBuffer.
END PROCEDURE.
