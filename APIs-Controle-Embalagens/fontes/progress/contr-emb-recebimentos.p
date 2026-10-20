/* DT119: projecoes de recebimentos. Somente leitura de bancos funcionais.
   Contrato: docs/entregas/RECEBIMENTOS_REST_DT119_20261007.md. */
USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
{fontes/progress/contr-emb.i}
DEFINE BUFFER bDoc FOR mgmov.docum-est.
DEFINE BUFFER bLinha FOR mgmov.item-doc-est.
DEFINE BUFFER bRat FOR mgmov.rat-lote.
DEFINE BUFFER bEvento FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRev FOR mgesp.contr_emb_evento.
DEFINE BUFFER bMov FOR mgesp.contr_emb_movto.
DEFINE BUFFER bEt FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bEI FOR mgesp.contr_emb_evento_item.
DEFINE BUFFER bMestre FOR mgcad.item.
DEFINE BUFFER bEmit FOR mgcad.emitente.
DEFINE BUFFER bEst FOR mgcad.estabelec.
DEFINE TEMP-TABLE ttDocumento NO-UNDO
    FIELD chave AS CHARACTER FIELD dataOrdem AS DATE FIELD cabecalho AS CLASS Progress.Lang.Object
    INDEX ordem IS PRIMARY dataOrdem DESCENDING chave.
DEFINE TEMP-TABLE ttCiclo NO-UNDO
    FIELD idEvento AS INTEGER FIELD ciclo AS INTEGER FIELD tipo AS CHARACTER
    FIELD situacao AS CHARACTER FIELD dataEvento AS DATETIME-TZ
    FIELD compensado AS LOGICAL FIELD idCompensacao AS INTEGER
    INDEX pk IS UNIQUE PRIMARY idEvento.
DEFINE TEMP-TABLE ttParticipacao NO-UNDO
    FIELD idEvento AS INTEGER FIELD idEtiqueta AS INTEGER FIELD sequencia AS INTEGER
    FIELD codigo AS CHARACTER FIELD item AS CHARACTER FIELD un AS CHARACTER
    FIELD codTipo AS CHARACTER FIELD lote AS CHARACTER FIELD validade AS DATE
    FIELD capacidade AS DECIMAL FIELD quantidade AS DECIMAL
    INDEX pk IS UNIQUE PRIMARY idEvento idEtiqueta.
DEFINE VARIABLE cTipos AS CHARACTER NO-UNDO INITIAL
    "RECEBIMENTO_COMPRA,RECEBIMENTO_TRANSFERENCIA,RECEBIMENTO_EMPRESTIMO,RECEBIMENTO_RETORNO_EMPRESTIMO,RECEBIMENTO_RETORNO_TERCEIROS".
DEFINE VARIABLE iSelecionado AS INTEGER NO-UNDO.
DEFINE VARIABLE iAtual AS INTEGER NO-UNDO.
DEFINE VARIABLE iUltimo AS INTEGER NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagem AS CHARACTER NO-UNDO.
FUNCTION texto RETURNS CHARACTER (INPUT p AS JsonObject, INPUT nome AS CHARACTER,
    INPUT padrao AS CHARACTER) FORWARD.
FUNCTION inteiro RETURNS INTEGER (INPUT valor AS CHARACTER) FORWARD.
FUNCTION dataIso RETURNS DATE (INPUT valor AS CHARACTER) FORWARD.
FUNCTION parte RETURNS CHARACTER (INPUT valor AS CHARACTER) FORWARD.
FUNCTION chaveDocumento RETURNS CHARACTER () FORWARD.
FUNCTION cabecalho RETURNS JsonObject () FORWARD.
FUNCTION ciclos RETURNS JsonArray () FORWARD.
FUNCTION corresponde RETURNS LOGICAL (INPUT pItem AS CHARACTER, INPUT pEtiqueta AS CHARACTER) FORWARD.

PROCEDURE consultarRecebimentos:
    DEFINE INPUT PARAMETER pcConsulta AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER poFiltros AS JsonObject NO-UNDO.
    DEFINE OUTPUT PARAMETER poResposta AS JsonObject NO-UNDO.
    DEFINE VARIABLE aDados AS JsonArray NO-UNDO.
    DEFINE VARIABLE oLinha AS JsonObject NO-UNDO.
    DEFINE VARIABLE aRateios AS JsonArray NO-UNDO.
    DEFINE VARIABLE oRat AS JsonObject NO-UNDO.
    DEFINE VARIABLE cEstabel AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSerie AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cNumero AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cNatureza AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItem AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cEtiqueta AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cAtualizado AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cComEmb AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cTipoData AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCursor AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cChaveCursor AS CHARACTER NO-UNDO.
    DEFINE VARIABLE dtCursor AS DATE NO-UNDO.
    DEFINE VARIABLE dtIni AS DATE NO-UNDO.
    DEFINE VARIABLE dtFim AS DATE NO-UNDO.
    DEFINE VARIABLE dtOrdem AS DATE NO-UNDO.
    DEFINE VARIABLE iEmitente AS INTEGER NO-UNDO.
    DEFINE VARIABLE iLimite AS INTEGER NO-UNDO.
    DEFINE VARIABLE iApos AS INTEGER NO-UNDO.
    DEFINE VARIABLE iSeq AS INTEGER NO-UNDO.
    DEFINE VARIABLE iIdEvento AS INTEGER NO-UNDO.
    DEFINE VARIABLE iTotal AS INTEGER NO-UNDO.
    DEFINE VARIABLE iLidos AS INTEGER NO-UNDO.
    DEFINE VARIABLE iContagem AS INTEGER NO-UNDO.
    DEFINE VARIABLE iRateios AS INTEGER NO-UNDO.
    DEFINE VARIABLE lMais AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cProximo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lNaoMapeado AS LOGICAL NO-UNDO.
    DEFINE VARIABLE cDescricao AS CHARACTER NO-UNDO.
    ASSIGN poResposta = NEW JsonObject() aDados = NEW JsonArray()
        cErro = "" cMensagem = "" iSelecionado = 0 iAtual = 0 iUltimo = 0.
    EMPTY TEMP-TABLE ttDocumento.
    EMPTY TEMP-TABLE ttCiclo.
    EMPTY TEMP-TABLE ttParticipacao.
    DO ON ERROR UNDO, THROW:
        IF poFiltros = ? OR LOOKUP(pcConsulta,"DOCUMENTOS,ITENS,EMBALAGENS") = 0 THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO", 0).
        ASSIGN cEstabel = texto(poFiltros,"codEstabel","")
            cSerie = texto(poFiltros,"serie","") cNumero = texto(poFiltros,"numero","")
            cNatureza = CAPS(texto(poFiltros,"natureza",""))
            cItem = texto(poFiltros,"item","") cEtiqueta = texto(poFiltros,"etiqueta","")
            cAtualizado = texto(poFiltros,"atualizado","todos")
            cComEmb = texto(poFiltros,"somenteComEmbalagens","false")
            cTipoData = CAPS(texto(poFiltros,"tipoData","EMISSAO"))
            iEmitente = inteiro(texto(poFiltros,"emitente","0"))
            iLimite = inteiro(texto(poFiltros,"limite","20"))
            iIdEvento = inteiro(texto(poFiltros,"idEvento","0"))
            iSeq = inteiro(texto(poFiltros,"sequencia","0"))
            iApos = inteiro(texto(poFiltros,IF pcConsulta = "ITENS" THEN "aposSequencia" ELSE "aposId","0"))
            cCursor = texto(poFiltros,"aposDocumento","").
        IF iLimite < 1 OR iLimite > 100 THEN
            UNDO, THROW NEW Progress.Lang.AppError("LIMITE_INVALIDO", 0).
        IF cEstabel = "" OR NOT CAN-FIND(FIRST ttEmbEstabelPermitido
            WHERE ttEmbEstabelPermitido.cod-estabel = cEstabel) THEN
            UNDO, THROW NEW Progress.Lang.AppError("DOCUMENTO_INDISPONIVEL", 0).
        IF NOT CONNECTED("mgmov") OR NOT CONNECTED("mgcad") OR NOT CONNECTED("mgesp") THEN
            UNDO, THROW NEW Progress.Lang.AppError("BANCO_NAO_CONECTADO", 0).
        IF pcConsulta = "DOCUMENTOS" THEN DO:
            ASSIGN dtIni = dataIso(texto(poFiltros,"dataIni",""))
                dtFim = dataIso(texto(poFiltros,"dataFim","")).
            IF dtIni = ? OR dtFim = ? OR dtIni > dtFim OR dtFim - dtIni > 365 OR
                LOOKUP(cTipoData,"EMISSAO,TRANSACAO") = 0 OR
                LOOKUP(cAtualizado,"todos,true,false") = 0 OR
                LOOKUP(cComEmb,"true,false") = 0 THEN
                UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO", 0).
            IF cCursor <> "" THEN DO:
                dtCursor = dataIso(SUBSTRING(cCursor,1,10)).
                IF dtCursor = ? OR SUBSTRING(cCursor,11,1) <> "|" OR LENGTH(cCursor) < 13 THEN
                    UNDO, THROW NEW Progress.Lang.AppError("CURSOR_INVALIDO", 0).
                cChaveCursor = SUBSTRING(cCursor,12).
            END.
            /* Ambos os campos possuem indices por estabelecimento comprovados em T04.
               Predicado OR pode exigir triagem do otimizador; medir em TESTE. */
            FOR EACH bDoc NO-LOCK WHERE bDoc.cod-estabel = cEstabel
                AND ((cTipoData = "EMISSAO" AND bDoc.dt-emissao >= dtIni AND bDoc.dt-emissao <= dtFim)
                  OR (cTipoData = "TRANSACAO" AND bDoc.dt-trans >= dtIni AND bDoc.dt-trans <= dtFim)):
                iLidos = iLidos + 1.
                IF iLidos > 5000 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA", 0).
                IF (iEmitente > 0 AND bDoc.cod-emitente <> iEmitente) OR
                    (cSerie <> "" AND bDoc.serie-docto <> cSerie) OR
                    (cNumero <> "" AND bDoc.nro-docto <> cNumero) OR
                    (cNatureza <> "" AND bDoc.nat-operacao <> cNatureza) OR
                    (cAtualizado = "true" AND (bDoc.ce-atual = ? OR bDoc.ce-atual <> YES)) OR
                    (cAtualizado = "false" AND (bDoc.ce-atual = ? OR bDoc.ce-atual <> NO)) THEN NEXT.
                IF cItem <> "" AND NOT CAN-FIND(FIRST bLinha OF bDoc
                    WHERE bLinha.it-codigo = cItem) THEN NEXT.
                RUN carregarHistorico.
                IF cEtiqueta <> "" AND NOT corresponde("",cEtiqueta) THEN NEXT.
                IF cComEmb = "true" AND NOT CAN-FIND(FIRST ttParticipacao) THEN NEXT.
                dtOrdem = IF cTipoData = "EMISSAO" THEN bDoc.dt-emissao ELSE bDoc.dt-trans.
                IF cCursor <> "" AND NOT (dtOrdem < dtCursor OR
                    (dtOrdem = dtCursor AND chaveDocumento() > cChaveCursor)) THEN NEXT.
                CREATE ttDocumento.
                ASSIGN ttDocumento.chave = chaveDocumento() ttDocumento.dataOrdem = dtOrdem
                    ttDocumento.cabecalho = cabecalho().
            END.
            FOR EACH ttDocumento BY ttDocumento.dataOrdem DESCENDING BY ttDocumento.chave:
                IF iTotal = iLimite THEN DO: lMais = YES. LEAVE. END.
                aDados:Add(CAST(ttDocumento.cabecalho,JsonObject)).
                ASSIGN iTotal = iTotal + 1
                    cProximo = STRING(YEAR(ttDocumento.dataOrdem),"9999") + "-" +
                        STRING(MONTH(ttDocumento.dataOrdem),"99") + "-" +
                        STRING(DAY(ttDocumento.dataOrdem),"99") + "|" + ttDocumento.chave.
            END.
        END.
        ELSE DO:
            IF iEmitente = 0 OR cSerie = "" OR cNumero = "" OR cNatureza = "" THEN
                UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO", 0).
            FIND FIRST bDoc NO-LOCK WHERE bDoc.serie-docto = cSerie AND bDoc.nro-docto = cNumero
                AND bDoc.cod-emitente = iEmitente AND bDoc.nat-operacao = cNatureza NO-ERROR.
            IF NOT AVAILABLE bDoc THEN
                UNDO, THROW NEW Progress.Lang.AppError("DOCUMENTO_INDISPONIVEL", 0).
            IF bDoc.cod-estabel <> cEstabel THEN
                UNDO, THROW NEW Progress.Lang.AppError("DOCUMENTO_INDISPONIVEL", 0).
            RUN carregarHistorico.
            IF iIdEvento > 0 THEN DO:
                FIND FIRST ttCiclo WHERE ttCiclo.idEvento = iIdEvento NO-ERROR.
                IF NOT AVAILABLE ttCiclo THEN UNDO, THROW NEW Progress.Lang.AppError("CICLO_INDISPONIVEL", 0).
                IF ttCiclo.situacao <> "CONCLUIDO" THEN
                    UNDO, THROW NEW Progress.Lang.AppError("CICLO_NAO_CONCLUIDO", 0).
                iSelecionado = iIdEvento.
            END.
            poResposta:Add("cabecalho",cabecalho()).
            poResposta:Add("ciclos",ciclos()).
            lNaoMapeado = CAN-FIND(FIRST ttParticipacao WHERE
                ttParticipacao.idEvento = iSelecionado AND ttParticipacao.sequencia = ?).
            IF pcConsulta = "ITENS" THEN DO:
                FOR EACH bLinha OF bDoc NO-LOCK WHERE bLinha.sequencia > iApos BY bLinha.sequencia:
                    IF iTotal = iLimite THEN DO: lMais = YES. LEAVE. END.
                    ASSIGN oLinha = NEW JsonObject() aRateios = NEW JsonArray()
                        cDescricao = ? iContagem = 0.
                    FOR FIRST bMestre NO-LOCK WHERE bMestre.it-codigo = bLinha.it-codigo:
                        cDescricao = bMestre.desc-item.
                    END.
                    FOR EACH ttParticipacao WHERE ttParticipacao.idEvento = iSelecionado
                        AND ttParticipacao.sequencia = bLinha.sequencia:
                        iContagem = iContagem + 1.
                    END.
                    oLinha:Add("sequencia",bLinha.sequencia).
                    oLinha:Add("item",bLinha.it-codigo).
                    oLinha:Add("descricaoItem",cDescricao).
                    oLinha:Add("quantidadeDocumento",bLinha.quantidade).
                    oLinha:Add("unidadeDocumento",bLinha.un).
                    oLinha:Add("loteDocumento",bLinha.lote).
                    oLinha:Add("validadeDocumento",bLinha.dt-vali-lote).
                    oLinha:Add("qtdEmbalagens",IF lNaoMapeado THEN ? ELSE iContagem).
                    oLinha:Add("vinculoLinha",IF lNaoMapeado THEN "NAO_COMPROVADO" ELSE "COMPROVADO").
                    FOR EACH bRat OF bLinha NO-LOCK BY bRat.lote BY bRat.dt-vali-lote
                        BY bRat.cod-depos BY bRat.cod-localiz BY bRat.quantidade:
                        iRateios = iRateios + 1.
                        IF iRateios > 5000 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA",0).
                        oRat = NEW JsonObject().
                        oRat:Add("item",bRat.it-codigo).
                        oRat:Add("lote",bRat.lote).
                        oRat:Add("validade",bRat.dt-vali-lote).
                        oRat:Add("quantidade",bRat.quantidade).
                        oRat:Add("deposito",bRat.cod-depos).
                        oRat:Add("localizacao",bRat.cod-localiz).
                        aRateios:Add(oRat).
                    END.
                    oLinha:Add("rateios",aRateios).
                    aDados:Add(oLinha).
                    ASSIGN iTotal = iTotal + 1 cProximo = STRING(bLinha.sequencia).
                END.
            END.
            ELSE DO:
                IF iSeq > 0 AND lNaoMapeado THEN
                    UNDO, THROW NEW Progress.Lang.AppError("VINCULO_LINHA_NAO_COMPROVADO",0).
                FOR EACH ttParticipacao WHERE ttParticipacao.idEvento = iSelecionado
                    AND ttParticipacao.idEtiqueta > iApos
                    AND (iSeq = 0 OR ttParticipacao.sequencia = iSeq)
                    BY ttParticipacao.idEtiqueta:
                    IF iTotal = iLimite THEN DO: lMais = YES. LEAVE. END.
                    oLinha = NEW JsonObject().
                    oLinha:Add("idEtiqueta",STRING(ttParticipacao.idEtiqueta)).
                    oLinha:Add("etiqueta",ttParticipacao.codigo).
                    oLinha:Add("sequencia",ttParticipacao.sequencia).
                    oLinha:Add("vinculoLinha",IF ttParticipacao.sequencia = ? THEN "NAO_COMPROVADO" ELSE "COMPROVADO").
                    oLinha:Add("item",ttParticipacao.item).
                    oLinha:Add("unidade",ttParticipacao.un).
                    oLinha:Add("codTipo",ttParticipacao.codTipo).
                    oLinha:Add("capacidade",ttParticipacao.capacidade).
                    oLinha:Add("quantidadeRecebida",ttParticipacao.quantidade).
                    oLinha:Add("lote",ttParticipacao.lote).
                    oLinha:Add("validade",ttParticipacao.validade).
                    aDados:Add(oLinha).
                    ASSIGN iTotal = iTotal + 1 cProximo = STRING(ttParticipacao.idEtiqueta).
                END.
            END.
        END.
        poResposta:Add("sucesso",YES).
        poResposta:Add("codigoErro",""). poResposta:Add("mensagem","").
        poResposta:Add("dados",aDados). poResposta:Add("total",iTotal).
        poResposta:Add("temMais",lMais).
        poResposta:Add(IF pcConsulta = "DOCUMENTOS" THEN "proximoDocumento" ELSE
            IF pcConsulta = "ITENS" THEN "proximaSequencia" ELSE "proximoId",
            IF lMais THEN cProximo ELSE "").
        CATCH falha AS Progress.Lang.Error:
            IF falha:NumMessages > 0 THEN cErro = falha:GetMessage(1).
            IF LOOKUP(cErro,"FILTRO_INVALIDO,LIMITE_INVALIDO,CURSOR_INVALIDO,DOCUMENTO_INDISPONIVEL,BANCO_NAO_CONECTADO,CONSULTA_AMPLA,CICLO_INDISPONIVEL,CICLO_NAO_CONCLUIDO,VINCULO_LINHA_NAO_COMPROVADO,HISTORICO_INCONSISTENTE") = 0 THEN cErro = "FALHA_CONSULTA_RECEBIMENTOS".
            CASE cErro:
                WHEN "DOCUMENTO_INDISPONIVEL" THEN cMensagem = "Documento indisponivel para consulta.".
                WHEN "CONSULTA_AMPLA" THEN cMensagem = "Consulta excede o limite de leitura; refine o periodo ou os filtros.".
                WHEN "VINCULO_LINHA_NAO_COMPROVADO" THEN cMensagem = "Historico sem vinculo unico a linha; consulte embalagens por documento.".
                WHEN "HISTORICO_INCONSISTENTE" THEN cMensagem = "O historico exige verificacao; nao foi apresentado como ausencia de embalagens.".
                OTHERWISE cMensagem = "Nao foi possivel consultar recebimentos; confira filtros, contexto e disponibilidade.".
            END CASE.
            poResposta = NEW JsonObject().
            poResposta:Add("sucesso",NO). poResposta:Add("codigoErro",cErro).
            poResposta:Add("mensagem",cMensagem).
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE carregarHistorico:
    DEFINE VARIABLE cChave AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cHash AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iFormato AS INTEGER NO-UNDO.
    DEFINE VARIABLE iSeq AS INTEGER NO-UNDO.
    DEFINE VARIABLE iCandidatos AS INTEGER NO-UNDO.
    DEFINE VARIABLE iEventos AS INTEGER NO-UNDO.
    DEFINE VARIABLE iPartes AS INTEGER NO-UNDO.
    DEFINE VARIABLE iAtivos AS INTEGER NO-UNDO.
    DEFINE VARIABLE cMovimento AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lLinhaValida AS LOGICAL NO-UNDO.
    EMPTY TEMP-TABLE ttCiclo.
    EMPTY TEMP-TABLE ttParticipacao.
    ASSIGN iSelecionado = 0 iAtual = 0 iUltimo = 0.
    /* DT119-R2: formatos existentes dos produtores, sem alterar fatos gravados.
       Compra: contr-emb-rastreio; chegadas: transferencia/emprestimo-entrada. */
    DO iFormato = 1 TO 2:
        IF iFormato = 1 THEN
            cChave = "ENTRADA|" + parte(bDoc.cod-estabel) + parte(STRING(bDoc.cod-emitente)) +
                parte(bDoc.serie-docto) + parte(bDoc.nro-docto) + parte(CAPS(TRIM(bDoc.nat-operacao))).
        ELSE
            cChave = "ENTRADA|" + STRING(LENGTH(bDoc.cod-estabel)) + ":" + bDoc.cod-estabel
                + "|" + STRING(bDoc.cod-emitente)
                + "|" + STRING(LENGTH(bDoc.serie-docto)) + ":" + bDoc.serie-docto
                + "|" + STRING(LENGTH(bDoc.nro-docto)) + ":" + bDoc.nro-docto
                + "|" + bDoc.nat-operacao.
        cHash = HEX-ENCODE(MESSAGE-DIGEST("SHA-256",cChave)).
    FOR EACH bEvento NO-LOCK WHERE bEvento.hash-docto = cHash:
        IF bEvento.tipo-docto <> "ENTRADA" OR bEvento.cod-estabel <> bDoc.cod-estabel OR
            bEvento.cod-emitente <> bDoc.cod-emitente OR bEvento.serie <> bDoc.serie-docto OR
            bEvento.nro-docto <> bDoc.nro-docto OR bEvento.nat-operacao <> bDoc.nat-operacao OR
            bEvento.chave-docto <> cChave THEN
            UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
        IF LOOKUP(bEvento.tipo-evento,cTipos) = 0 THEN NEXT.
        iEventos = iEventos + 1.
        IF iEventos > 1000 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA",0).
        CREATE ttCiclo.
        ASSIGN ttCiclo.idEvento = bEvento.id-evento ttCiclo.ciclo = bEvento.seq-ciclo
            ttCiclo.tipo = bEvento.tipo-evento ttCiclo.situacao = bEvento.situacao
            ttCiclo.dataEvento = bEvento.dt-evento.
        FOR EACH bRev NO-LOCK WHERE bRev.hash-docto = cHash
            AND bRev.id-evento-origem = bEvento.id-evento AND bRev.situacao = "CONCLUIDO"
            AND (bRev.tipo-evento = "DESATUALIZACAO_COMPRA" OR bRev.tipo-evento = "DESATUALIZACAO_ENTRADA"):
            IF bRev.chave-docto <> cChave THEN UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
            ASSIGN ttCiclo.compensado = YES ttCiclo.idCompensacao = bRev.id-evento.
        END.
        IF bEvento.situacao <> "CONCLUIDO" THEN NEXT.
        iUltimo = MAXIMUM(iUltimo,bEvento.id-evento).
        IF NOT ttCiclo.compensado THEN DO:
            ASSIGN iAtual = MAXIMUM(iAtual,bEvento.id-evento) iAtivos = iAtivos + 1.
            IF iAtivos > 1 THEN UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
        END.
        cMovimento = ENTRY(LOOKUP(bEvento.tipo-evento,cTipos),
            "NASCIMENTO_RECEBIMENTO,ENTRADA_TRANSFERENCIA,ENTRADA_EMPRESTIMO,ENTRADA_RETORNO_EMPRESTIMO,ENTRADA_RETORNO_TERCEIROS").
        FOR EACH bMov NO-LOCK WHERE bMov.id-evento = bEvento.id-evento:
            iPartes = iPartes + 1.
            IF iPartes > 50000 THEN UNDO, THROW NEW Progress.Lang.AppError("CONSULTA_AMPLA",0).
            FIND FIRST bEt NO-LOCK WHERE bEt.id-etiqueta = bMov.id-etiqueta NO-ERROR.
            IF NOT AVAILABLE bEt THEN UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
            IF bEt.tipo-controle <> "EMBALAGEM" OR bMov.un <> bEt.un OR
                bMov.tipo-movto <> cMovimento OR bMov.cod-estabel-dest <> bDoc.cod-estabel OR
                bMov.tipo-local-dest <> "ESTAB" OR bEt.capacidade-emb = ? OR bEt.capacidade-emb <= 0 OR
                bMov.quantidade = ? OR bMov.quantidade <= 0 OR
                CAN-FIND(FIRST ttParticipacao WHERE ttParticipacao.idEvento = bEvento.id-evento
                    AND ttParticipacao.idEtiqueta = bMov.id-etiqueta) THEN
                UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
            ASSIGN iSeq = ? iCandidatos = 0.
            IF bMov.id-item-evento <> ? AND bMov.id-item-evento > 0 THEN DO:
                FIND FIRST bEI NO-LOCK WHERE bEI.id-item-evento = bMov.id-item-evento NO-ERROR.
                IF NOT AVAILABLE bEI THEN UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
                IF bEI.id-evento <> bEvento.id-evento OR bEI.it-codigo <> bEt.it-codigo OR
                    bEI.lote <> bEt.lote OR bEI.dt-vali-lote <> bEt.dt-vali-lote OR bEI.un <> bEt.un THEN
                    UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
                iSeq = bEI.sequencia.
            END.
            ELSE DO:
                IF bEvento.tipo-evento = "RECEBIMENTO_COMPRA" THEN
                    UNDO, THROW NEW Progress.Lang.AppError("HISTORICO_INCONSISTENTE",0).
                /* E12 comprova grupo unico item/lote/validade/unidade; jamais escolher FIRST. */
                FOR EACH bLinha OF bDoc NO-LOCK WHERE bLinha.it-codigo = bEt.it-codigo AND bLinha.un = bEt.un:
                    lLinhaValida = NO.
                    FOR EACH bRat OF bLinha NO-LOCK WHERE bRat.it-codigo = bEt.it-codigo
                        AND bRat.lote = bEt.lote AND bRat.dt-vali-lote = bEt.dt-vali-lote:
                        lLinhaValida = YES.
                    END.
                    IF lLinhaValida THEN ASSIGN iCandidatos = iCandidatos + 1 iSeq = bLinha.sequencia.
                END.
                IF iCandidatos <> 1 THEN iSeq = ?.
            END.
            CREATE ttParticipacao.
            ASSIGN ttParticipacao.idEvento = bEvento.id-evento ttParticipacao.idEtiqueta = bEt.id-etiqueta
                ttParticipacao.sequencia = iSeq ttParticipacao.codigo = bEt.cod-etiqueta
                ttParticipacao.item = bEt.it-codigo ttParticipacao.un = bEt.un
                ttParticipacao.codTipo = bEt.cod-tipo ttParticipacao.lote = bEt.lote
                ttParticipacao.validade = bEt.dt-vali-lote ttParticipacao.capacidade = bEt.capacidade-emb
                ttParticipacao.quantidade = bMov.quantidade.
        END.
    END.
    END. /* formatos historicos */
    iSelecionado = IF iAtual > 0 THEN iAtual ELSE iUltimo.
END PROCEDURE.

FUNCTION parte RETURNS CHARACTER (INPUT valor AS CHARACTER):
    IF valor = ? THEN RETURN "-1:".
    valor = TRIM(valor," ").
    RETURN STRING(LENGTH(valor,"CHARACTER")) + ":" + valor.
END FUNCTION.
FUNCTION chaveDocumento RETURNS CHARACTER ():
    RETURN parte(bDoc.cod-estabel) + parte(STRING(bDoc.cod-emitente)) +
        parte(bDoc.serie-docto) + parte(bDoc.nro-docto) + parte(bDoc.nat-operacao).
END FUNCTION.
FUNCTION texto RETURNS CHARACTER (INPUT p AS JsonObject, INPUT nome AS CHARACTER, INPUT padrao AS CHARACTER):
    DEFINE VARIABLE valor AS CHARACTER NO-UNDO.
    IF NOT p:Has(nome) THEN RETURN padrao.
    valor = p:GetCharacter(nome).
    IF valor = ? OR LENGTH(valor) > 512 THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
    RETURN TRIM(valor).
END FUNCTION.
FUNCTION inteiro RETURNS INTEGER (INPUT valor AS CHARACTER):
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    IF valor = "" THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
    DO i = 1 TO LENGTH(valor):
        IF INDEX("0123456789",SUBSTRING(valor,i,1)) = 0 THEN
            UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
    END.
    n = INTEGER(valor).
    IF n < 0 THEN UNDO, THROW NEW Progress.Lang.AppError("FILTRO_INVALIDO",0).
    RETURN n.
END FUNCTION.
FUNCTION dataIso RETURNS DATE (INPUT valor AS CHARACTER):
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE d AS DATE NO-UNDO.
    IF LENGTH(valor) <> 10 OR SUBSTRING(valor,5,1) <> "-" OR SUBSTRING(valor,8,1) <> "-" THEN RETURN ?.
    DO i = 1 TO 10:
        IF i <> 5 AND i <> 8 AND INDEX("0123456789",SUBSTRING(valor,i,1)) = 0 THEN RETURN ?.
    END.
    d = DATE(INTEGER(SUBSTRING(valor,6,2)),INTEGER(SUBSTRING(valor,9,2)),INTEGER(SUBSTRING(valor,1,4))) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN RETURN ?.
    RETURN d.
END FUNCTION.
FUNCTION corresponde RETURNS LOGICAL (INPUT pItem AS CHARACTER, INPUT pEtiqueta AS CHARACTER):
    RETURN CAN-FIND(FIRST ttParticipacao WHERE (pItem = "" OR ttParticipacao.item = pItem)
        AND (pEtiqueta = "" OR ttParticipacao.codigo = pEtiqueta)).
END FUNCTION.
FUNCTION cabecalho RETURNS JsonObject ():
    DEFINE VARIABLE o AS JsonObject NO-UNDO.
    DEFINE VARIABLE nomeEmitente AS CHARACTER NO-UNDO.
    DEFINE VARIABLE nomeEstabel AS CHARACTER NO-UNDO.
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE lErro AS LOGICAL NO-UNDO.
    ASSIGN o = NEW JsonObject() nomeEmitente = ? nomeEstabel = ?.
    FOR FIRST bEmit NO-LOCK WHERE bEmit.cod-emitente = bDoc.cod-emitente:
        nomeEmitente = bEmit.nome-emit.
    END.
    FOR FIRST bEst NO-LOCK WHERE bEst.cod-estabel = bDoc.cod-estabel:
        nomeEstabel = bEst.nome.
    END.
    FOR EACH ttParticipacao WHERE ttParticipacao.idEvento = iSelecionado: n = n + 1. END.
    lErro = CAN-FIND(FIRST ttCiclo WHERE ttCiclo.situacao <> "CONCLUIDO").
    o:Add("codEstabel",bDoc.cod-estabel). o:Add("descricaoEstabelecimento",nomeEstabel).
    o:Add("emitente",STRING(bDoc.cod-emitente)). o:Add("descricaoEmitente",nomeEmitente).
    o:Add("serie",bDoc.serie-docto). o:Add("numero",bDoc.nro-docto).
    o:Add("natureza",bDoc.nat-operacao). o:Add("dataEmissao",bDoc.dt-emissao).
    o:Add("dataTransacao",bDoc.dt-trans). o:Add("estoqueAtualizado",bDoc.ce-atual).
    o:Add("idEvento",IF iSelecionado > 0 THEN STRING(iSelecionado) ELSE "").
    o:Add("ultimoCicloValido",IF iAtual > 0 THEN STRING(iAtual) ELSE "").
    o:Add("qtdEmbalagens",n).
    o:Add("situacaoControle",IF lErro THEN "PROCESSAMENTO_PENDENTE" ELSE
        IF iSelecionado = 0 THEN "SEM_RECEBIMENTO_RASTREADO" ELSE "RECEBIMENTO_RASTREADO").
    FIND FIRST ttCiclo WHERE ttCiclo.idEvento = iSelecionado NO-ERROR.
    o:Add("compensado",IF AVAILABLE ttCiclo THEN ttCiclo.compensado ELSE NO).
    RETURN o.
END FUNCTION.
FUNCTION ciclos RETURNS JsonArray ():
    DEFINE VARIABLE a AS JsonArray NO-UNDO.
    DEFINE VARIABLE o AS JsonObject NO-UNDO.
    a = NEW JsonArray().
    FOR EACH ttCiclo BY ttCiclo.idEvento:
        o = NEW JsonObject().
        o:Add("idEvento",STRING(ttCiclo.idEvento)). o:Add("ciclo",ttCiclo.ciclo).
        o:Add("tipoEvento",ttCiclo.tipo). o:Add("situacao",ttCiclo.situacao).
        o:Add("dataEvento",ttCiclo.dataEvento). o:Add("compensado",ttCiclo.compensado).
        o:Add("idCompensacao",IF ttCiclo.idCompensacao > 0 THEN STRING(ttCiclo.idCompensacao) ELSE "").
        o:Add("selecionado",ttCiclo.idEvento = iSelecionado).
        a:Add(o).
    END.
    RETURN a.
END FUNCTION.

{fontes/progress/includes/contr-emb-manutencao-consulta.i}
