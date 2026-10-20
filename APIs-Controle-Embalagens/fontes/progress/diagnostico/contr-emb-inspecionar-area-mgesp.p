/* Diagnostico somente leitura das Storage Areas no banco especifico mgesp. */
DEFINE VARIABLE cArquivo AS CHARACTER NO-UNDO.

cArquivo = SESSION:TEMP-DIRECTORY + "contr-emb-area-mgesp.txt".
OUTPUT TO VALUE(cArquivo).
PUT UNFORMATTED "tabela;numero;area-numero;area-nome" SKIP.

RUN listarArea("cd_estabelecimento").
RUN listarArea("etiquetas-CD").
RUN listarArea("bag_embalagens").
RUN listarArea("bag").
RUN listarArea("bag_etiquetas").
RUN listarArea("bag_log").

OUTPUT CLOSE.
MESSAGE "Diagnostico concluido:" SKIP cArquivo VIEW-AS ALERT-BOX INFO.

PROCEDURE listarArea:
    DEFINE INPUT PARAMETER pcTabela AS CHARACTER NO-UNDO.
    /* mgesp e o alias de negocio; o metaschema pertence ao schema holder shmgesp. */
    DEFINE BUFFER bFile    FOR shmgesp._File.
    DEFINE BUFFER bStorage FOR shmgesp._StorageObject.
    DEFINE BUFFER bArea    FOR shmgesp._Area.

    FIND FIRST bFile NO-LOCK
         WHERE bFile._File-Name = pcTabela
         NO-ERROR.
    IF NOT AVAILABLE bFile THEN DO:
        PUT UNFORMATTED pcTabela ";nao-encontrada;;" SKIP.
        RETURN.
    END.

    FIND FIRST bStorage NO-LOCK
         WHERE bStorage._Object-type   = 1
           AND bStorage._Object-number = bFile._File-number
         NO-ERROR.
    IF NOT AVAILABLE bStorage THEN DO:
        PUT UNFORMATTED pcTabela ";" bFile._File-number ";sem-storage;" SKIP.
        RETURN.
    END.

    FIND FIRST bArea NO-LOCK
         WHERE bArea._Area-number = bStorage._Area-number
         NO-ERROR.

    PUT UNFORMATTED
        pcTabela ";"
        bFile._File-number ";"
        bStorage._Area-number ";"
        (IF AVAILABLE bArea THEN bArea._Area-name ELSE "nao-encontrada") SKIP.
END PROCEDURE.
