/* DT120: incluir no modulo de recebimentos; reutiliza carregarHistorico DT119.
   Consulta atual de identidades, vinculada a recebimentos nao compensados. */
DEFINE BUFFER bManEt FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bManDepos FOR mgcad.deposito.
DEFINE BUFFER bManItem FOR mgcad.item.
DEFINE TEMP-TABLE ttManVinculo NO-UNDO
    FIELD idEtiqueta AS INTEGER INDEX pk IS UNIQUE PRIMARY idEtiqueta.
DEFINE TEMP-TABLE ttManDocumento NO-UNDO
    FIELD chave AS CHARACTER FIELD estabel AS CHARACTER FIELD emitente AS INTEGER
    FIELD serie AS CHARACTER FIELD numero AS CHARACTER FIELD natureza AS CHARACTER
    INDEX pk IS UNIQUE PRIMARY chave.
DEFINE TEMP-TABLE ttManOpcao NO-UNDO
    FIELD codigo AS CHARACTER FIELD objeto AS CLASS Progress.Lang.Object
    INDEX pk IS UNIQUE PRIMARY codigo.

FUNCTION manEntre RETURNS LOGICAL (INPUT valor AS CHARACTER,
    INPUT cDe AS CHARACTER, INPUT cAte AS CHARACTER):
    IF cDe = "" AND cAte = "" THEN RETURN YES.
    RETURN valor <> ? AND (cDe = "" OR valor >= cDe) AND (cAte = "" OR valor <= cAte).
END FUNCTION.

FUNCTION manErro RETURNS CHARACTER (INPUT falha AS Progress.Lang.Error):
    DEFINE VARIABLE codigo AS CHARACTER NO-UNDO.
    codigo = IF falha:NumMessages > 0 THEN falha:GetMessage(1) ELSE "".
    IF LOOKUP(codigo,"SEM_PERMISSAO,FILTRO_INVALIDO,FILTRO_CURTO,LIMITE_INVALIDO,CURSOR_INVALIDO,DOCUMENTO_INDISPONIVEL,BANCO_NAO_CONECTADO,CONSULTA_AMPLA,HISTORICO_INCONSISTENTE") = 0 THEN
        codigo = "FALHA_CONSULTA_MANUTENCAO".
    RETURN codigo.
END FUNCTION.

PROCEDURE manValidarContexto:
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN
        UNDO, THROW NEW Progress.Lang.AppError("SEM_PERMISSAO",0).
    FOR EACH ttEmbEstabelPermitido:
        IF ttEmbEstabelPermitido.cod-estabel = ? OR
            TRIM(ttEmbEstabelPermitido.cod-estabel) = "" THEN
            UNDO, THROW NEW Progress.Lang.AppError("SEM_PERMISSAO",0).
    END.
    IF NOT CONNECTED("mgcad") OR NOT CONNECTED("mgmov") OR NOT CONNECTED("mgesp") THEN
        UNDO, THROW NEW Progress.Lang.AppError("BANCO_NAO_CONECTADO",0).
END PROCEDURE.

PROCEDURE manValidarIntervalos:
    DEFINE INPUT PARAMETER p AS JsonObject NO-UNDO.
    DEFINE VARIABLE campos AS CHARACTER NO-UNDO INITIAL
        "estabel,item,deposito,etiqueta,lote,familia,nota".
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE cDe AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cAte AS CHARACTER NO-UNDO.
    DO n = 1 TO NUM-ENTRIES(campos):
        ASSIGN cDe = texto(p,ENTRY(n,campos) + "De","")
            cAte = texto(p,ENTRY(n,campos) + "Ate","").
        IF cDe <> "" AND cAte <> "" AND cDe > cAte THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
    END.
END PROCEDURE.

PROCEDURE manDecodificarDocumento:
    DEFINE INPUT PARAMETER chave AS CHARACTER NO-UNDO.
    DEFINE VARIABLE posicao AS INTEGER NO-UNDO INITIAL 1.
    DEFINE VARIABLE doisPontos AS INTEGER NO-UNDO.
    DEFINE VARIABLE tamanho AS INTEGER NO-UNDO.
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE partes AS CHARACTER EXTENT 5 NO-UNDO.
    IF chave = ? OR LENGTH(chave) > 256 THEN
        UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
    DO n = 1 TO 5:
        doisPontos = INDEX(chave,":",posicao).
        IF doisPontos <= posicao THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        tamanho = inteiro(SUBSTRING(chave,posicao,doisPontos - posicao)).
        IF tamanho < 1 OR doisPontos + tamanho > LENGTH(chave) THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        ASSIGN partes[n] = SUBSTRING(chave,doisPontos + 1,tamanho)
            posicao = doisPontos + tamanho + 1.
    END.
    IF posicao <> LENGTH(chave) + 1 THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE
        ttEmbEstabelPermitido.cod-estabel = partes[1]) THEN
        UNDO, THROW NEW Progress.Lang.AppError("DOCUMENTO_INDISPONIVEL",0).
    IF CAN-FIND(FIRST ttManDocumento WHERE ttManDocumento.chave = chave) THEN RETURN.
    CREATE ttManDocumento.
    ASSIGN ttManDocumento.chave = chave ttManDocumento.estabel = partes[1]
        ttManDocumento.emitente = inteiro(partes[2]) ttManDocumento.serie = partes[3]
        ttManDocumento.numero = partes[4] ttManDocumento.natureza = partes[5].
    IF ttManDocumento.emitente = 0 THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
END PROCEDURE.

PROCEDURE manAcumularDocumento:
    /* bDoc ja esta localizado e autorizado. Nao usa numero isolado nem lote
       para inferir identidade. So o ciclo valido ativo participa do filtro. */
    RUN carregarHistorico.
    IF CAN-FIND(FIRST ttCiclo WHERE ttCiclo.situacao <> "CONCLUIDO") THEN
        UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
    IF iAtual = 0 THEN RETURN.
    FOR EACH ttParticipacao WHERE ttParticipacao.idEvento = iAtual:
        IF NOT CAN-FIND(FIRST ttManVinculo WHERE
            ttManVinculo.idEtiqueta = ttParticipacao.idEtiqueta) THEN DO:
            CREATE ttManVinculo.
            ttManVinculo.idEtiqueta = ttParticipacao.idEtiqueta.
        END.
    END.
END PROCEDURE.

PROCEDURE consultarEtiquetasManutencao:
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER p AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER TABLE FOR ttEmbEtiqueta.
    DEFINE OUTPUT PARAMETER mais AS LOGICAL NO-UNDO.
    DEFINE OUTPUT PARAMETER proximo AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER sucesso AS LOGICAL NO-UNDO.
    DEFINE OUTPUT PARAMETER erro AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER mensagem AS CHARACTER NO-UNDO.
    DEFINE VARIABLE aDocumentos AS JsonArray NO-UNDO.
    DEFINE VARIABLE modo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE estabel AS CHARACTER NO-UNDO.
    DEFINE VARIABLE validadeDe AS DATE NO-UNDO.
    DEFINE VARIABLE validadeAte AS DATE NO-UNDO.
    DEFINE VARIABLE usaNotas AS LOGICAL NO-UNDO.
    DEFINE VARIABLE limite AS INTEGER NO-UNDO.
    DEFINE VARIABLE apos AS INTEGER NO-UNDO.
    DEFINE VARIABLE idBag AS INTEGER NO-UNDO.
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE lidos AS INTEGER NO-UNDO.
    DEFINE VARIABLE iManTotal AS INTEGER NO-UNDO.
    DEFINE VARIABLE ultimo AS INTEGER NO-UNDO.
    EMPTY TEMP-TABLE ttEmbEtiqueta.
    EMPTY TEMP-TABLE ttManVinculo.
    EMPTY TEMP-TABLE ttManDocumento.
    ASSIGN sucesso = NO mais = NO proximo = 0 erro = "" mensagem = "".
    DO ON ERROR UNDO, THROW:
        RUN manValidarContexto.
        RUN manValidarIntervalos(p).
        ASSIGN limite = inteiro(texto(p,"limite","20"))
            apos = inteiro(texto(p,"aposId","0")) idBag = inteiro(texto(p,"idBag","0"))
            estabel = texto(p,"codEstabel","") modo = CAPS(texto(p,"modoNotas","INTERVALO"))
            validadeDe = dataIso(texto(p,"validadeDe",""))
            validadeAte = dataIso(texto(p,"validadeAte","")).
        IF limite = 0 THEN limite = 20.
        IF limite > 100 THEN UNDO, THROW NEW Progress.Lang.AppError("LIMITE_INVALIDO",0).
        IF LENGTH(texto(p,"codEtiqueta","")) > 24 OR LENGTH(texto(p,"codTipo","")) > 3 THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        IF estabel <> "" AND NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE
            ttEmbEstabelPermitido.cod-estabel = estabel) THEN
            UNDO, THROW NEW Progress.Lang.AppError("SEM_PERMISSAO",0).
        IF (texto(p,"validadeDe","") <> "" AND validadeDe = ?) OR
            (texto(p,"validadeAte","") <> "" AND validadeAte = ?) OR
            (validadeDe <> ? AND validadeAte <> ? AND validadeDe > validadeAte) OR
            LOOKUP(modo,"INTERVALO,ESPECIFICAS") = 0 THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        IF texto(p,"tipoControle","") <> "" AND LOOKUP(CAPS(texto(p,"tipoControle","")),"EMBALAGEM,PRE_SALDO") = 0 THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        IF texto(p,"tipoLocal","") <> "" AND LOOKUP(CAPS(texto(p,"tipoLocal","")),"ESTAB,CAMPO,TERCEIRO,TRANSITO") = 0 THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        IF texto(p,"situacao","") <> "" AND LOOKUP(CAPS(texto(p,"situacao","")),"ATIVA,ENCERRADA,CANCELADA,DESCARTADA") = 0 THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        usaNotas = modo = "ESPECIFICAS" OR texto(p,"notaDe","") <> "" OR texto(p,"notaAte","") <> "".
        IF modo = "ESPECIFICAS" THEN DO:
            IF texto(p,"notaDe","") <> "" OR texto(p,"notaAte","") <> "" OR NOT p:Has("documentos") THEN
                UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
            aDocumentos = p:GetJsonArray("documentos").
            IF aDocumentos:Length < 1 OR aDocumentos:Length > 20 THEN
                UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
            DO n = 1 TO aDocumentos:Length:
                RUN manDecodificarDocumento(aDocumentos:GetCharacter(n)).
            END.
            FOR EACH ttManDocumento:
                IF NOT manEntre(ttManDocumento.estabel,texto(p,"estabelDe",""),texto(p,"estabelAte","")) OR
                    (estabel <> "" AND ttManDocumento.estabel <> estabel) THEN
                    UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
                FIND FIRST bDoc NO-LOCK WHERE bDoc.cod-estabel = ttManDocumento.estabel
                    AND bDoc.cod-emitente = ttManDocumento.emitente AND bDoc.serie-docto = ttManDocumento.serie
                    AND bDoc.nro-docto = ttManDocumento.numero AND bDoc.nat-operacao = ttManDocumento.natureza NO-ERROR.
                IF NOT AVAILABLE bDoc THEN UNDO, THROW NEW Progress.Lang.AppError("DOCUMENTO_INDISPONIVEL",0).
                RUN manAcumularDocumento.
            END.
        END.
        ELSE DO:
            IF p:Has("documentos") THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
            IF usaNotas THEN FOR EACH ttEmbEstabelPermitido:
                IF NOT manEntre(ttEmbEstabelPermitido.cod-estabel,texto(p,"estabelDe",""),texto(p,"estabelAte","")) OR
                    (estabel <> "" AND ttEmbEstabelPermitido.cod-estabel <> estabel) THEN NEXT.
                FOR EACH bDoc NO-LOCK WHERE bDoc.cod-estabel = ttEmbEstabelPermitido.cod-estabel
                    AND (texto(p,"notaDe","") = "" OR bDoc.nro-docto >= texto(p,"notaDe",""))
                    AND (texto(p,"notaAte","") = "" OR bDoc.nro-docto <= texto(p,"notaAte","")):
                    lidos = lidos + 1.
                    IF lidos > 5000 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA",0).
                    RUN manAcumularDocumento.
                END.
            END.
        END.
        lidos = 0.
        FOR EACH bManEt NO-LOCK WHERE bManEt.id-etiqueta > apos
            AND (estabel = "" OR bManEt.cod-estabel = estabel)
            AND (texto(p,"item","") = "" OR bManEt.it-codigo = texto(p,"item",""))
            AND (texto(p,"codEtiqueta","") = "" OR bManEt.cod-etiqueta = texto(p,"codEtiqueta",""))
            AND (texto(p,"lote","") = "" OR bManEt.lote = texto(p,"lote",""))
            AND (texto(p,"codTipo","") = "" OR bManEt.cod-tipo = CAPS(texto(p,"codTipo","")))
            AND (texto(p,"tipoControle","") = "" OR bManEt.tipo-controle = CAPS(texto(p,"tipoControle","")))
            AND (texto(p,"tipoLocal","") = "" OR bManEt.tipo-local = CAPS(texto(p,"tipoLocal","")))
            AND (texto(p,"situacao","") = "" OR bManEt.situacao = CAPS(texto(p,"situacao","")))
            AND (idBag = 0 OR bManEt.id-bag = idBag)
            BY bManEt.id-etiqueta:
            IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE
                ttEmbEstabelPermitido.cod-estabel = bManEt.cod-estabel) THEN NEXT.
            lidos = lidos + 1.
            IF lidos > 50000 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA",0).
            IF NOT manEntre(bManEt.cod-estabel,texto(p,"estabelDe",""),texto(p,"estabelAte","")) OR
                NOT manEntre(bManEt.it-codigo,texto(p,"itemDe",""),texto(p,"itemAte","")) OR
                NOT manEntre(bManEt.cod-depos,texto(p,"depositoDe",""),texto(p,"depositoAte","")) OR
                NOT manEntre(bManEt.cod-etiqueta,texto(p,"etiquetaDe",""),texto(p,"etiquetaAte","")) OR
                NOT manEntre(bManEt.lote,texto(p,"loteDe",""),texto(p,"loteAte","")) THEN NEXT.
            IF (validadeDe <> ? AND (bManEt.dt-vali-lote = ? OR bManEt.dt-vali-lote < validadeDe)) OR
                (validadeAte <> ? AND (bManEt.dt-vali-lote = ? OR bManEt.dt-vali-lote > validadeAte)) THEN NEXT.
            IF texto(p,"familiaDe","") <> "" OR texto(p,"familiaAte","") <> "" THEN DO:
                FIND FIRST bManItem NO-LOCK WHERE bManItem.it-codigo = bManEt.it-codigo NO-ERROR.
                IF NOT AVAILABLE bManItem THEN NEXT.
                IF NOT manEntre(bManItem.fm-codigo,texto(p,"familiaDe",""),texto(p,"familiaAte","")) THEN NEXT.
            END.
            IF usaNotas AND NOT CAN-FIND(FIRST ttManVinculo WHERE ttManVinculo.idEtiqueta = bManEt.id-etiqueta) THEN NEXT.
            IF iManTotal = limite THEN DO: mais = YES. proximo = ultimo. LEAVE. END.
            CREATE ttEmbEtiqueta.
            BUFFER-COPY bManEt TO ttEmbEtiqueta.
            ASSIGN iManTotal = iManTotal + 1 ultimo = bManEt.id-etiqueta.
        END.
        ASSIGN sucesso = YES erro = "" mensagem = "".
        CATCH falha AS Progress.Lang.Error:
            EMPTY TEMP-TABLE ttEmbEtiqueta.
            ASSIGN sucesso = NO mais = NO proximo = 0 erro = manErro(falha)
                mensagem = "Confira contexto, filtros e vinculo fiscal; consulta nao concluida.".
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE consultarApoiosManutencao:
    DEFINE INPUT PARAMETER consulta AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER p AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    DEFINE VARIABLE dados AS JsonArray NO-UNDO.
    DEFINE VARIABLE linha AS JsonObject NO-UNDO.
    DEFINE VARIABLE filtro AS CHARACTER NO-UNDO.
    DEFINE VARIABLE apos AS CHARACTER NO-UNDO.
    DEFINE VARIABLE estabel AS CHARACTER NO-UNDO.
    DEFINE VARIABLE codigo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE limite AS INTEGER NO-UNDO.
    DEFINE VARIABLE lidos AS INTEGER NO-UNDO.
    DEFINE VARIABLE iManTotal AS INTEGER NO-UNDO.
    DEFINE VARIABLE mais AS LOGICAL NO-UNDO.
    DEFINE VARIABLE proximo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE erro AS CHARACTER NO-UNDO.
    DEFINE VARIABLE somenteComEmbalagens AS CHARACTER CASE-SENSITIVE NO-UNDO.
    EMPTY TEMP-TABLE ttManOpcao.
    DO ON ERROR UNDO, THROW:
        RUN manValidarContexto.
        RUN manValidarIntervalos(p).
        ASSIGN filtro = CAPS(texto(p,"filtro","")) apos = texto(p,"aposCodigo","")
            estabel = texto(p,"codEstabel","") limite = inteiro(texto(p,"limite","20")).
        IF LENGTH(filtro) < 2 THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_CURTO",0).
        IF LENGTH(filtro) > 100 OR LOOKUP(consulta,"DEPOSITOS,LOTES,DOCUMENTOS") = 0 THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        IF limite = 0 THEN limite = 20.
        IF limite > 20 THEN UNDO, THROW NEW Progress.Lang.AppError("LIMITE_INVALIDO",0).
        IF consulta = "DOCUMENTOS" THEN DO:
            somenteComEmbalagens = texto(p,"somenteComEmbalagens","false").
            IF somenteComEmbalagens = ? OR
                (somenteComEmbalagens <> "true" AND somenteComEmbalagens <> "false") THEN
                UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
        END.
        IF estabel <> "" AND NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE
            ttEmbEstabelPermitido.cod-estabel = estabel) THEN
            UNDO, THROW NEW Progress.Lang.AppError("SEM_PERMISSAO",0).
        IF consulta = "DEPOSITOS" THEN DO:
            /* Cadastro global: contexto nao comprova elegibilidade item/deposito. */
            FOR EACH bManDepos NO-LOCK WHERE bManDepos.cod-depos > apos
                AND (CAPS(bManDepos.cod-depos) BEGINS filtro OR INDEX(CAPS(bManDepos.nome),filtro) > 0)
                BY bManDepos.cod-depos:
                IF iManTotal = limite THEN DO: mais = YES. LEAVE. END.
                linha = NEW JsonObject().
                linha:Add("codigo",bManDepos.cod-depos). linha:Add("descricao",bManDepos.nome).
                CREATE ttManOpcao.
                ASSIGN ttManOpcao.codigo = bManDepos.cod-depos ttManOpcao.objeto = linha
                    iManTotal = iManTotal + 1 proximo = bManDepos.cod-depos.
            END.
        END.
        ELSE IF consulta = "LOTES" THEN DO:
            FOR EACH bManEt NO-LOCK WHERE bManEt.tipo-controle = "EMBALAGEM"
                AND bManEt.lote > apos AND INDEX(CAPS(bManEt.lote),filtro) > 0
                AND (estabel = "" OR bManEt.cod-estabel = estabel)
                AND (texto(p,"item","") = "" OR bManEt.it-codigo = texto(p,"item","")):
                IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE
                    ttEmbEstabelPermitido.cod-estabel = bManEt.cod-estabel) THEN NEXT.
                lidos = lidos + 1.
                IF lidos > 50000 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA",0).
                IF NOT manEntre(bManEt.cod-estabel,texto(p,"estabelDe",""),texto(p,"estabelAte","")) OR
                    NOT manEntre(bManEt.it-codigo,texto(p,"itemDe",""),texto(p,"itemAte","")) OR
                    NOT manEntre(bManEt.cod-depos,texto(p,"depositoDe",""),texto(p,"depositoAte","")) THEN NEXT.
                IF CAN-FIND(FIRST ttManOpcao WHERE ttManOpcao.codigo = bManEt.lote) THEN NEXT.
                linha = NEW JsonObject().
                linha:Add("codigo",bManEt.lote). linha:Add("descricao",bManEt.lote).
                CREATE ttManOpcao.
                ASSIGN ttManOpcao.codigo = bManEt.lote ttManOpcao.objeto = linha.
            END.
        END.
        ELSE DO:
            FOR EACH ttEmbEstabelPermitido:
                IF (estabel <> "" AND estabel <> ttEmbEstabelPermitido.cod-estabel) OR
                    NOT manEntre(ttEmbEstabelPermitido.cod-estabel,texto(p,"estabelDe",""),texto(p,"estabelAte","")) THEN NEXT.
                /* Numero prefixado permite informar nota/serie sem inventar
                   vinculo com embalagem. Emitente vai descrito no retorno. */
                FOR EACH bDoc NO-LOCK WHERE bDoc.cod-estabel = ttEmbEstabelPermitido.cod-estabel
                    AND INDEX(CAPS(bDoc.nro-docto),filtro) > 0:
                    lidos = lidos + 1.
                    IF lidos > 5000 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA",0).
                    codigo = chaveDocumento().
                    IF codigo <= apos THEN NEXT.
                    RUN carregarHistorico.
                    /* DT124: mesma participacao vigente usada pelo filtro de notas
                       da manutencao; nunca inferir vinculo pela natureza. */
                    IF somenteComEmbalagens = "true" THEN DO:
                        IF CAN-FIND(FIRST ttCiclo WHERE ttCiclo.situacao <> "CONCLUIDO") THEN
                            UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
                        IF iAtual = 0 OR NOT CAN-FIND(FIRST ttParticipacao
                            WHERE ttParticipacao.idEvento = iAtual) THEN NEXT.
                    END.
                    linha = cabecalho().
                    linha:Add("codigo",codigo).
                    linha:Add("descricao",bDoc.nro-docto + " / " + bDoc.serie-docto + " / " +
                        STRING(bDoc.cod-emitente) + " / " + bDoc.cod-estabel + " / " + bDoc.nat-operacao).
                    CREATE ttManOpcao.
                    ASSIGN ttManOpcao.codigo = codigo ttManOpcao.objeto = linha.
                END.
            END.
        END.
        ASSIGN dados = NEW JsonArray() iManTotal = 0.
        FOR EACH ttManOpcao BY ttManOpcao.codigo:
            IF iManTotal = limite THEN DO: mais = YES. LEAVE. END.
            dados:Add(CAST(ttManOpcao.objeto,JsonObject)).
            ASSIGN iManTotal = iManTotal + 1 proximo = ttManOpcao.codigo.
        END.
        resposta = NEW JsonObject().
        resposta:Add("sucesso",YES). resposta:Add("codigoErro",""). resposta:Add("mensagem","").
        resposta:Add("total",iManTotal). resposta:Add("dados",dados). resposta:Add("temMais",mais).
        resposta:Add("proximoCodigo",IF mais THEN proximo ELSE "").
        CATCH falha AS Progress.Lang.Error:
            erro = manErro(falha).
            resposta = NEW JsonObject().
            resposta:Add("sucesso",NO). resposta:Add("codigoErro",erro).
            resposta:Add("mensagem","Confira contexto e filtro; opcoes nao consultadas.").
            resposta:Add("dados",NEW JsonArray()). resposta:Add("total",0).
            resposta:Add("temMais",NO). resposta:Add("proximoCodigo","").
        END CATCH.
    END.
END PROCEDURE.

