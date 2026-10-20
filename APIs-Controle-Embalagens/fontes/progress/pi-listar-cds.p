USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonObject.

PROCEDURE pi-listar-cds:

    DEFINE INPUT  PARAMETER oInput  AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER oOutput AS JsonObject NO-UNDO.

    DEFINE VARIABLE oQueryParams AS JsonObject NO-UNDO.
    DEFINE VARIABLE aFiltro      AS JsonArray  NO-UNDO.
    DEFINE VARIABLE aLimit       AS JsonArray  NO-UNDO.
    DEFINE VARIABLE aDados       AS JsonArray  NO-UNDO.
    DEFINE VARIABLE oCD          AS JsonObject NO-UNDO.
    DEFINE VARIABLE cFiltro      AS CHARACTER  NO-UNDO INITIAL "".
    DEFINE VARIABLE iLimit       AS INTEGER    NO-UNDO INITIAL 20.
    DEFINE VARIABLE iTotal       AS INTEGER    NO-UNDO.

    DEFINE BUFFER bEstabelec FOR mgcad.estabelec.

    ASSIGN
        oOutput      = NEW JsonObject()
        aDados       = NEW JsonArray()
        oQueryParams = oInput:GetJsonObject("queryParams").

    IF oQueryParams:Has("filtro") THEN DO:
        aFiltro = oQueryParams:GetJsonArray("filtro").

        IF aFiltro:Length > 0 THEN
            cFiltro = aFiltro:GetCharacter(1).
    END.

    IF oQueryParams:Has("limit") THEN DO:
        aLimit = oQueryParams:GetJsonArray("limit").

        IF aLimit:Length > 0 THEN
            iLimit = INTEGER(aLimit:GetCharacter(1)) NO-ERROR.

        IF ERROR-STATUS:ERROR OR iLimit <= 0 THEN
            iLimit = 20.
    END.

    IF iLimit > 100 THEN
        iLimit = 100.

    FOR EACH cd_estabelecimento NO-LOCK
        WHERE cd_estabelecimento.ativo = YES,

        FIRST bEstabelec NO-LOCK
        WHERE bEstabelec.cod-estabel = cd_estabelecimento.cod-estabel
          AND (cFiltro = ""
               OR bEstabelec.cod-estabel BEGINS cFiltro
               OR bEstabelec.nome MATCHES ("*" + cFiltro + "*"))

        BY bEstabelec.cod-estabel:

        oCD = NEW JsonObject().
        oCD:Add("codEstabel", cd_estabelecimento.cod-estabel).
        oCD:Add("nomeEstabel", bEstabelec.nome).
        aDados:Add(oCD).

        iTotal = iTotal + 1.

        IF iTotal >= iLimit THEN
            LEAVE.
    END.

    oOutput:Add("sucesso", TRUE).
    oOutput:Add("total", iTotal).
    oOutput:Add("dados", aDados).
    oOutput:Add("filtroRecebido", cFiltro).
    oOutput:Add("limitRecebido", iLimit).

END PROCEDURE.
