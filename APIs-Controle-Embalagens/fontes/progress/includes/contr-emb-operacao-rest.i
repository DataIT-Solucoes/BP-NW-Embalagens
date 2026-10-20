/* DT115. Incluido somente em contr-emb-operacao.p. Nenhum schema novo.
   Cadeia BO dos executores E04/E11/E14; selecao variavel e idempotencia novas. */
DEFINE TEMP-TABLE ttRestWtLinha NO-UNDO
    FIELD sequencia AS INTEGER
    FIELD it-codigo AS CHARACTER
    FIELD un AS CHARACTER
    FIELD lote AS CHARACTER
    FIELD dt-vali-lote AS DATE
    FIELD cod-depos AS CHARACTER
    FIELD cod-localiz AS CHARACTER
    FIELD quantidade AS DECIMAL
    INDEX grupo IS PRIMARY UNIQUE it-codigo un lote dt-vali-lote cod-depos cod-localiz.

FUNCTION fRestParte RETURNS CHARACTER (INPUT pcValor AS CHARACTER):
    RETURN STRING(LENGTH(pcValor)) + ":" + pcValor.
END FUNCTION.

FUNCTION fRestChaveValida RETURNS LOGICAL (INPUT pcChave AS CHARACTER):
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    IF pcChave = ? OR LENGTH(pcChave) < 1 OR LENGTH(pcChave) > 64 THEN RETURN NO.
    DO i = 1 TO LENGTH(pcChave):
        IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-",
                 SUBSTRING(pcChave,i,1)) = 0 THEN RETURN NO.
    END.
    RETURN YES.
END FUNCTION.

PROCEDURE criarWtSaidaDireta:
DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT PARAMETER pcFluxoEsperado AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcEstabel AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcDestino AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piEmitente AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcNatureza AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcSerie AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pdValorItem AS DECIMAL NO-UNDO.
DEFINE INPUT PARAMETER pcUsuario AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcChave AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER TABLE FOR ttEmbDevolucaoSelecao.
DEFINE OUTPUT PARAMETER piWt AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piOperacao AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bOrigem FOR mgcad.estabelec.
DEFINE BUFFER bDestino FOR mgcad.estabelec.
DEFINE BUFFER bEmitente FOR mgcad.emitente.
DEFINE BUFFER bEtiqueta FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bItem FOR mgcad.item.
DEFINE BUFFER bSaldo FOR mgmov.saldo-estoq.
DEFINE BUFFER bOper FOR mgesp.contr_emb_oper.
DEFINE BUFFER bWt FOR mgcad.wt-docto.
DEFINE VARIABLE hInit AS HANDLE NO-UNDO.
DEFINE VARIABLE hSd AS HANDLE NO-UNDO.
DEFINE VARIABLE hPr AS HANDLE NO-UNDO.
DEFINE VARIABLE hIm AS HANDLE NO-UNDO.
DEFINE VARIABLE hVa AS HANDLE NO-UNDO.
DEFINE VARIABLE cFluxo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cRamo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cIdentidade AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConteudo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMarca AS CHARACTER NO-UNDO.
DEFINE VARIABLE cHash AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMetodo AS CHARACTER NO-UNDO.
DEFINE VARIABLE lOrigem AS LOGICAL NO-UNDO.
DEFINE VARIABLE lQtd AS LOGICAL NO-UNDO.
DEFINE VARIABLE lPreco AS LOGICAL NO-UNDO.
DEFINE VARIABLE lOk AS LOGICAL NO-UNDO.
DEFINE VARIABLE lSelecao AS LOGICAL NO-UNDO.
DEFINE VARIABLE lRepSelecao AS LOGICAL NO-UNDO.
DEFINE VARIABLE iUltimo AS INTEGER NO-UNDO.
DEFINE VARIABLE iContagem AS INTEGER NO-UNDO.
DEFINE VARIABLE iSequencia AS INTEGER NO-UNDO.
DEFINE VARIABLE iWtItem AS INTEGER NO-UNDO.
DEFINE VARIABLE dSaldo AS DECIMAL NO-UNDO.
DEFINE VARIABLE dQuantidade AS DECIMAL NO-UNDO.

EMPTY TEMP-TABLE ttRestWtLinha.
EMPTY TEMP-TABLE ttEmbSelecaoSaida.
ASSIGN piWt = 0 piOperacao = 0 plSucesso = NO plRepeticao = NO
       pcErro = "PARAMETRO_INVALIDO" pcMensagem = "Confira contexto, selecao e parametros da saida.".
IF pcEstabel = ? OR TRIM(pcEstabel) = "" OR pcDestino = ? OR
   pcNatureza = ? OR TRIM(pcNatureza) = "" OR pcSerie = ? OR TRIM(pcSerie) = "" OR
   pcUsuario = ? OR TRIM(pcUsuario) = "" OR LENGTH(pcUsuario) > 128 OR
   piEmitente = ? OR piEmitente < 0 OR pdValorItem = ? OR pdValorItem < 0 OR
   NOT fRestChaveValida(pcChave) OR
   LOOKUP(pcFluxoEsperado,"TRANSFERENCIA,REMESSA_TERCEIROS") = 0 THEN RETURN.
ASSIGN pcEstabel = TRIM(pcEstabel) pcDestino = TRIM(pcDestino)
       pcNatureza = TRIM(pcNatureza) pcSerie = TRIM(pcSerie) pcUsuario = TRIM(pcUsuario).
IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = pcEstabel)
   OR (pcDestino <> "" AND NOT CAN-FIND(FIRST ttEmbEstabelPermitido
       WHERE ttEmbEstabelPermitido.cod-estabel = pcDestino)) THEN DO:
    ASSIGN pcErro = "SEM_PERMISSAO" pcMensagem = "Estabelecimento fora do contexto autorizado.".
    RETURN.
END.
IF NOT CONNECTED("mgcad") OR NOT CONNECTED("mgmov") OR NOT CONNECTED("mgesp") THEN DO:
    pcErro = "BANCO_NAO_CONECTADO".
    RETURN.
END.
FOR EACH ttEmbDevolucaoSelecao BY ttEmbDevolucaoSelecao.id-etiqueta:
    IF ttEmbDevolucaoSelecao.id-etiqueta = ? OR ttEmbDevolucaoSelecao.id-etiqueta <= 0 OR
       ttEmbDevolucaoSelecao.versao = ? OR ttEmbDevolucaoSelecao.versao <= 0 OR
       ttEmbDevolucaoSelecao.quantidade = ? OR ttEmbDevolucaoSelecao.quantidade <= 0 OR
       ROUND(ttEmbDevolucaoSelecao.quantidade,4) <> ttEmbDevolucaoSelecao.quantidade THEN RETURN.
    IF ttEmbDevolucaoSelecao.id-etiqueta = iUltimo THEN DO:
        pcErro = "ETIQUETA_DUPLICADA".
        RETURN.
    END.
    ASSIGN iUltimo = ttEmbDevolucaoSelecao.id-etiqueta iContagem = iContagem + 1.
END.
IF iContagem < 1 OR iContagem > 100 THEN DO:
    pcErro = "LIMITE_SELECAO_INVALIDO".
    RETURN.
END.
cIdentidade = "DTS1|" + fRestParte(pcEstabel) + "|" + fRestParte(pcUsuario) + "|" + fRestParte(pcChave).
cMarca = "DTS1|" + HEX-ENCODE(MESSAGE-DIGEST("SHA-256",cIdentidade)) + "|".
cConteudo = cIdentidade + "|" + pcFluxoEsperado + "|" + fRestParte(pcDestino) + "|"
    + STRING(piEmitente) + "|" + fRestParte(CAPS(pcNatureza)) + "|"
    + fRestParte(pcSerie) + "|" + STRING(pdValorItem).
FOR EACH ttEmbDevolucaoSelecao BY ttEmbDevolucaoSelecao.id-etiqueta:
    cConteudo = cConteudo + "|" + STRING(ttEmbDevolucaoSelecao.id-etiqueta) + ":"
        + STRING(ttEmbDevolucaoSelecao.versao) + ":" + STRING(ttEmbDevolucaoSelecao.quantidade).
END.
cHash = HEX-ENCODE(MESSAGE-DIGEST("SHA-256",cConteudo)).

criacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    /* Serializa a chave de criacao por origem, inclusive selecoes diferentes.
       Nao depende de WT transitorio nem de etiqueta disponivel para repetir. */
    FIND FIRST bOrigem WHERE bOrigem.cod-estabel = pcEstabel EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
    IF LOCKED bOrigem THEN UNDO criacao, THROW NEW Progress.Lang.AppError("ORIGEM_BLOQUEADA",0).
    IF NOT AVAILABLE bOrigem THEN UNDO criacao, THROW NEW Progress.Lang.AppError("ESTABELECIMENTO_NAO_ENCONTRADO",0).
    iContagem = 0.
    FOR EACH bOper NO-LOCK WHERE bOper.cod-estabel-orig = pcEstabel USE-INDEX pk:
        IF bOper.observacao = ? OR NOT bOper.observacao BEGINS cMarca THEN NEXT.
        IF NUM-ENTRIES(bOper.observacao,"|") < 3 THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("CHAVE_IDEMPOTENTE_AMBIGUA",0).
        IF ENTRY(3,bOper.observacao,"|") <> cHash THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("CHAVE_IDEMPOTENTE_DIVERGENTE",0).
        IF bOper.observacao <> cMarca + cHash + "|" + cIdentidade THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("CHAVE_IDEMPOTENTE_AMBIGUA",0).
        ASSIGN iContagem = iContagem + 1 piWt = bOper.seq-wt-docto piOperacao = bOper.id-operacao.
    END.
    IF iContagem > 1 THEN UNDO criacao, THROW NEW Progress.Lang.AppError("CHAVE_IDEMPOTENTE_AMBIGUA",0).
    IF iContagem = 1 THEN DO:
        IF piWt = ? OR piWt <= 0 OR piOperacao = ? OR piOperacao <= 0 THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("CHAVE_IDEMPOTENTE_AMBIGUA",0).
        ASSIGN plSucesso = YES plRepeticao = YES pcErro = ""
               pcMensagem = "Preparacao ja registrada; consulte a situacao da operacao.".
        LEAVE criacao.
    END.
    RUN classificarNaturezaOperacao (INPUT pcNatureza, OUTPUT cFluxo, OUTPUT cRamo,
        OUTPUT lOrigem, OUTPUT lQtd, OUTPUT lPreco, OUTPUT lOk, OUTPUT pcErro).
    IF (lOk = ? OR lOk = NO) OR cFluxo <> pcFluxoEsperado OR cRamo <> "DIRETO" THEN
        UNDO criacao, THROW NEW Progress.Lang.AppError("NATUREZA_FORA_DO_FLUXO",0).
    IF pcDestino <> "" THEN DO:
        FIND FIRST bDestino NO-LOCK WHERE bDestino.cod-estabel = pcDestino NO-ERROR.
        IF NOT AVAILABLE bDestino OR pcDestino = pcEstabel THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("DESTINO_INVALIDO",0).
        IF pcFluxoEsperado = "TRANSFERENCIA" AND
            (bOrigem.ep-codigo = ? OR bDestino.ep-codigo = ? OR bOrigem.ep-codigo <> bDestino.ep-codigo) THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("EMPRESAS_DIFERENTES",0).
        IF piEmitente > 0 AND piEmitente <> bDestino.cod-emitente THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("EMITENTE_DESTINO_DIVERGENTE",0).
        piEmitente = bDestino.cod-emitente.
    END.
    ELSE IF pcFluxoEsperado = "TRANSFERENCIA" THEN
        UNDO criacao, THROW NEW Progress.Lang.AppError("DESTINO_OBRIGATORIO",0).
    IF piEmitente = ? OR piEmitente <= 0 THEN UNDO criacao, THROW NEW Progress.Lang.AppError("EMITENTE_DESTINO_INVALIDO",0).
    FIND FIRST bEmitente NO-LOCK WHERE bEmitente.cod-emitente = piEmitente NO-ERROR.
    IF NOT AVAILABLE bEmitente THEN UNDO criacao, THROW NEW Progress.Lang.AppError("EMITENTE_NAO_ENCONTRADO",0).
    FOR EACH ttEmbDevolucaoSelecao BY ttEmbDevolucaoSelecao.id-etiqueta:
        FIND FIRST bEtiqueta WHERE bEtiqueta.id-etiqueta = ttEmbDevolucaoSelecao.id-etiqueta
            AND bEtiqueta.cod-estabel = pcEstabel
            EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF LOCKED bEtiqueta THEN UNDO criacao, THROW NEW Progress.Lang.AppError("ETIQUETA_BLOQUEADA",0).
        IF NOT AVAILABLE bEtiqueta THEN UNDO criacao, THROW NEW Progress.Lang.AppError("ETIQUETA_NAO_ENCONTRADA",0).
        IF bEtiqueta.versao = ? OR bEtiqueta.versao <> ttEmbDevolucaoSelecao.versao THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("VERSAO_ETIQUETA_DIVERGENTE",0).
        IF bEtiqueta.tipo-controle = ? OR bEtiqueta.tipo-controle <> "EMBALAGEM" OR
           bEtiqueta.situacao = ? OR bEtiqueta.situacao <> "ATIVA" OR
           bEtiqueta.tipo-local = ? OR bEtiqueta.tipo-local <> "ESTAB" OR
           bEtiqueta.cod-estabel = ? OR bEtiqueta.cod-estabel <> pcEstabel OR
           bEtiqueta.id-bag <> ? OR bEtiqueta.qtidade-atu = ? OR
           bEtiqueta.qtidade-atu <> ttEmbDevolucaoSelecao.quantidade THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("ETIQUETA_INDISPONIVEL",0).
        IF NOT fEmConfirmada(bEtiqueta.id-etiqueta,"CONFIRMACAO_IMPRESSAO","") THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("ETIQUETA_NAO_IMPRESSA",0).
        FIND FIRST bItem NO-LOCK WHERE bItem.it-codigo = bEtiqueta.it-codigo NO-ERROR.
        IF NOT AVAILABLE bItem OR bItem.un <> bEtiqueta.un THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("ITEM_OU_UNIDADE_INVALIDA",0).
        FIND FIRST ttRestWtLinha WHERE ttRestWtLinha.it-codigo = bEtiqueta.it-codigo
            AND ttRestWtLinha.un = bEtiqueta.un AND ttRestWtLinha.lote = bEtiqueta.lote
            AND ttRestWtLinha.dt-vali-lote = bEtiqueta.dt-vali-lote
            AND ttRestWtLinha.cod-depos = bEtiqueta.cod-depos
            AND ttRestWtLinha.cod-localiz = (IF bEtiqueta.cod-localiz = ? THEN "" ELSE TRIM(bEtiqueta.cod-localiz)) NO-ERROR.
        IF NOT AVAILABLE ttRestWtLinha THEN DO:
            CREATE ttRestWtLinha.
            ASSIGN iSequencia = iSequencia + 10 ttRestWtLinha.sequencia = iSequencia
                ttRestWtLinha.it-codigo = bEtiqueta.it-codigo ttRestWtLinha.un = bEtiqueta.un
                ttRestWtLinha.lote = bEtiqueta.lote ttRestWtLinha.dt-vali-lote = bEtiqueta.dt-vali-lote
                ttRestWtLinha.cod-depos = bEtiqueta.cod-depos
                ttRestWtLinha.cod-localiz = IF bEtiqueta.cod-localiz = ? THEN "" ELSE TRIM(bEtiqueta.cod-localiz).
        END.
        ttRestWtLinha.quantidade = ttRestWtLinha.quantidade + bEtiqueta.qtidade-atu.
        CREATE ttEmbSelecaoSaida.
        ASSIGN ttEmbSelecaoSaida.id-etiqueta = bEtiqueta.id-etiqueta
            ttEmbSelecaoSaida.quantidade = bEtiqueta.qtidade-atu.
    END.
    FOR EACH ttRestWtLinha:
        dSaldo = 0.
        FOR EACH bSaldo NO-LOCK WHERE bSaldo.cod-estab = pcEstabel
            AND bSaldo.it-codigo = ttRestWtLinha.it-codigo AND bSaldo.cod-depos = ttRestWtLinha.cod-depos
            AND bSaldo.lote = ttRestWtLinha.lote AND bSaldo.dt-vali-lote = ttRestWtLinha.dt-vali-lote:
            IF (IF bSaldo.cod-localiz = ? THEN "" ELSE TRIM(bSaldo.cod-localiz)) <> ttRestWtLinha.cod-localiz THEN NEXT.
            dSaldo = dSaldo + bSaldo.qtidade-atu.
        END.
        IF dSaldo < ttRestWtLinha.quantidade THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("SALDO_ESTOQ_INSUFICIENTE_PARA_SELECAO",0).
    END.
    cMetodo = "BODI317_INIT".
    RUN dibo/bodi317in.p PERSISTENT SET hInit.
    RUN inicializaBOS IN hInit (OUTPUT hPr, OUTPUT hSd, OUTPUT hIm, OUTPUT hVa).
    IF NOT VALID-HANDLE(hPr) OR NOT VALID-HANDLE(hSd) OR NOT VALID-HANDLE(hVa) THEN
        UNDO criacao, THROW NEW Progress.Lang.AppError("BODI317_BOS_NAO_DISPONIVEIS",0).
    cMetodo = "CRIAR_WT".
    RUN criaWtDocto IN hSd (INPUT pcUsuario, INPUT pcEstabel, INPUT pcSerie,
        INPUT "", INPUT bEmitente.nome-abrev, INPUT ?, INPUT 4, INPUT 4003,
        INPUT TODAY, INPUT 0, INPUT pcNatureza, INPUT bEmitente.cod-canal-venda,
        OUTPUT piWt, OUTPUT lOk).
    IF (lOk = ? OR lOk = NO) OR piWt <= 0 THEN UNDO criacao, THROW NEW Progress.Lang.AppError("CRIAR_WT_FALHOU",0).
    FIND FIRST bWt NO-LOCK WHERE bWt.seq-wt-docto = piWt NO-ERROR.
    IF NOT AVAILABLE bWt THEN UNDO criacao, THROW NEW Progress.Lang.AppError("CRIAR_WT_FALHOU",0).
    IF bWt.cod-estabel <> pcEstabel OR bWt.cod-emitente <> piEmitente OR bWt.nat-operacao <> pcNatureza THEN
        UNDO criacao, THROW NEW Progress.Lang.AppError("CRIAR_WT_FALHOU",0).
    RUN localizaWtDocto IN hSd (INPUT piWt, OUTPUT lOk).
    IF (lOk = ? OR lOk = NO) THEN UNDO criacao, THROW NEW Progress.Lang.AppError("LOCALIZAR_WT_FALHOU",0).
    FOR EACH ttRestWtLinha BY ttRestWtLinha.sequencia:
        cMetodo = "CRIAR_ITEM_WT".
        RUN criaWtItDocto IN hSd (INPUT ?, INPUT "", INPUT ttRestWtLinha.sequencia,
            INPUT ttRestWtLinha.it-codigo, INPUT "", INPUT pcNatureza, OUTPUT iWtItem, OUTPUT lOk).
        IF (lOk = ? OR lOk = NO) OR iWtItem <= 0 THEN UNDO criacao, THROW NEW Progress.Lang.AppError("CRIAR_ITEM_WT_FALHOU",0).
        RUN WriteUomQuantity IN hSd (INPUT piWt, INPUT iWtItem, INPUT ttRestWtLinha.quantidade,
            INPUT ttRestWtLinha.un, OUTPUT dQuantidade, OUTPUT lOk).
        IF (lOk = ? OR lOk = NO) OR dQuantidade <> ttRestWtLinha.quantidade THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("GRAVAR_QUANTIDADE_WT_FALHOU",0).
        RUN gravaInfGeraisWtItDocto IN hSd (INPUT piWt, INPUT iWtItem, INPUT dQuantidade,
            INPUT pdValorItem, INPUT 0, INPUT 0).
        RUN criaAlteraWtFatSerLote IN hSd (INPUT YES, INPUT piWt, INPUT iWtItem,
            INPUT ttRestWtLinha.it-codigo, INPUT ttRestWtLinha.cod-depos, INPUT ttRestWtLinha.cod-localiz,
            INPUT ttRestWtLinha.lote, INPUT dQuantidade, INPUT 0, INPUT ttRestWtLinha.dt-vali-lote, OUTPUT lOk).
        IF (lOk = ? OR lOk = NO) THEN UNDO criacao, THROW NEW Progress.Lang.AppError("GRAVAR_LOTE_WT_FALHOU",0).
        RUN localizaWtDocto IN hPr (INPUT piWt, OUTPUT lOk).
        IF (lOk = ? OR lOk = NO) THEN UNDO criacao, THROW NEW Progress.Lang.AppError("PR_LOCALIZAR_WT_FALHOU",0).
        RUN localizaWtItDocto IN hPr (INPUT piWt, INPUT iWtItem, OUTPUT lOk).
        IF (lOk = ? OR lOk = NO) THEN UNDO criacao, THROW NEW Progress.Lang.AppError("PR_LOCALIZAR_ITEM_FALHOU",0).
        RUN localizaWtItImposto IN hPr (INPUT piWt, INPUT iWtItem, OUTPUT lOk).
        IF (lOk = ? OR lOk = NO) THEN UNDO criacao, THROW NEW Progress.Lang.AppError("PR_LOCALIZAR_IMPOSTO_FALHOU",0).
        RUN atualizaDadosItemNota IN hPr (OUTPUT lOk).
        IF (lOk = ? OR lOk = NO) THEN UNDO criacao, THROW NEW Progress.Lang.AppError("ATUALIZAR_ITEM_WT_FALHOU",0).
        RUN validaItemDaNota IN hVa (INPUT piWt, INPUT iWtItem, OUTPUT lOk).
        IF (lOk = ? OR lOk = NO) THEN UNDO criacao, THROW NEW Progress.Lang.AppError("VALIDAR_ITEM_WT_FALHOU",0).
    END.
    cMetodo = "REGISTRAR_SELECAO".
    IF pcFluxoEsperado = "TRANSFERENCIA" THEN
        RUN registrarSelecaoAposWt (INPUT piWt, INPUT pcEstabel, INPUT pcDestino,
            INPUT piEmitente, INPUT pcUsuario, INPUT TABLE ttEmbSelecaoSaida,
            OUTPUT lSelecao, OUTPUT lRepSelecao, OUTPUT piOperacao, OUTPUT pcErro).
    ELSE
        RUN registrarSelecaoRemessaAposWt (INPUT piWt, INPUT pcEstabel, INPUT pcDestino,
            INPUT piEmitente, INPUT pcUsuario, INPUT TABLE ttEmbSelecaoSaida,
            OUTPUT lSelecao, OUTPUT lRepSelecao, OUTPUT piOperacao, OUTPUT pcErro).
    IF (lSelecao = ? OR lSelecao = NO) OR (lRepSelecao = ? OR lRepSelecao = YES) THEN
        UNDO criacao, THROW NEW Progress.Lang.AppError("SELECAO_APOS_WT_FALHOU",0).
    FIND FIRST bOper WHERE bOper.id-operacao = piOperacao EXCLUSIVE-LOCK NO-ERROR.
    IF NOT AVAILABLE bOper THEN UNDO criacao, THROW NEW Progress.Lang.AppError("OPERACAO_NAO_ENCONTRADA",0).
    bOper.observacao = cMarca + cHash + "|" + cIdentidade.
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "WT e selecao preparados; nota ainda nao efetivada.".
    CATCH eCriacao AS Progress.Lang.Error:
        ASSIGN piWt = 0 piOperacao = 0 plSucesso = NO plRepeticao = NO pcErro = "FALHA_CRIACAO_WT".
        IF TYPE-OF(eCriacao,Progress.Lang.AppError) AND eCriacao:NumMessages > 0 THEN DO:
            /* Erros AppError de bibliotecas BO nao sao automaticamente publicos. */
            IF LOOKUP(eCriacao:GetMessage(1),"ORIGEM_BLOQUEADA,ESTABELECIMENTO_NAO_ENCONTRADO,CHAVE_IDEMPOTENTE_AMBIGUA,CHAVE_IDEMPOTENTE_DIVERGENTE,NATUREZA_FORA_DO_FLUXO,DESTINO_INVALIDO,EMPRESAS_DIFERENTES,EMITENTE_DESTINO_DIVERGENTE,DESTINO_OBRIGATORIO,EMITENTE_DESTINO_INVALIDO,EMITENTE_NAO_ENCONTRADO,ETIQUETA_BLOQUEADA,ETIQUETA_NAO_ENCONTRADA,VERSAO_ETIQUETA_DIVERGENTE,ETIQUETA_INDISPONIVEL,ETIQUETA_NAO_IMPRESSA,ITEM_OU_UNIDADE_INVALIDA,SALDO_ESTOQ_INSUFICIENTE_PARA_SELECAO,BODI317_BOS_NAO_DISPONIVEIS,CRIAR_WT_FALHOU,LOCALIZAR_WT_FALHOU,CRIAR_ITEM_WT_FALHOU,GRAVAR_QUANTIDADE_WT_FALHOU,GRAVAR_LOTE_WT_FALHOU,PR_LOCALIZAR_WT_FALHOU,PR_LOCALIZAR_ITEM_FALHOU,PR_LOCALIZAR_IMPOSTO_FALHOU,ATUALIZAR_ITEM_WT_FALHOU,VALIDAR_ITEM_WT_FALHOU,SELECAO_APOS_WT_FALHOU,OPERACAO_NAO_ENCONTRADA") > 0 THEN
                pcErro = eCriacao:GetMessage(1).
        END.
        pcMensagem = "Preparacao desfeita; confira a selecao e os parametros. Etapa: " + cMetodo + ".".
        LOG-MANAGER:WRITE-MESSAGE("CONTROLE_EMBALAGENS|CRIAR_WT|CODIGO=" + pcErro
            + "|ETAPA=" + cMetodo + "|ABL="
            + (IF eCriacao:NumMessages > 0 THEN STRING(eCriacao:GetMessageNum(1)) ELSE "0")) NO-ERROR.
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hVa) THEN DELETE PROCEDURE hVa NO-ERROR.
        IF VALID-HANDLE(hIm) THEN DELETE PROCEDURE hIm NO-ERROR.
        IF VALID-HANDLE(hSd) THEN DELETE PROCEDURE hSd NO-ERROR.
        IF VALID-HANDLE(hPr) THEN DELETE PROCEDURE hPr NO-ERROR.
        IF VALID-HANDLE(hInit) THEN DELETE PROCEDURE hInit NO-ERROR.
        EMPTY TEMP-TABLE ttRestWtLinha.
        EMPTY TEMP-TABLE ttEmbSelecaoSaida.
    END FINALLY.
END.
END PROCEDURE.

/* Projecao publica de operacoes; nunca devolver observacao/dados internos. */
PROCEDURE consultarOperacoesRest:
DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT PARAMETER pcModo AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcEstabel AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piOperacao AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piWt AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcSituacao AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcTipo AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcUsuario AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcChave AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcRamo AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piEmitente AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcSerieOrigem AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcNumeroOrigem AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcNatOrigem AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piApos AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piLimite AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER poSaida AS JsonObject NO-UNDO.
DEFINE BUFFER bOper FOR mgesp.contr_emb_oper.
DEFINE BUFFER bLinha FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bEvento FOR mgesp.contr_emb_evento.
DEFINE VARIABLE aDados AS JsonArray NO-UNDO.
DEFINE VARIABLE oLinha AS JsonObject NO-UNDO.
DEFINE VARIABLE cMarca AS CHARACTER NO-UNDO.
DEFINE VARIABLE cIdentidade AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErro AS CHARACTER NO-UNDO.
DEFINE VARIABLE iProximo AS INTEGER NO-UNDO.
DEFINE VARIABLE lMais AS LOGICAL NO-UNDO.

ASSIGN poSaida = NEW JsonObject() aDados = NEW JsonArray() cErro = "PARAMETRO_INVALIDO".
validacao:
DO:
    IF pcEstabel = ? OR TRIM(pcEstabel) = "" OR pcUsuario = ? OR TRIM(pcUsuario) = "" OR
        piApos = ? OR piApos < 0 OR piLimite = ? OR piLimite < 1 OR piLimite > 100 OR
        piOperacao = ? OR piOperacao < 0 OR piWt = ? OR piWt < 0 OR
        LOOKUP(pcModo,"LISTA,RESULTADO,ITENS,EVENTOS") = 0 THEN LEAVE validacao.
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = TRIM(pcEstabel)) THEN DO:
        cErro = "SEM_PERMISSAO".
        LEAVE validacao.
    END.
    IF NOT CONNECTED("mgesp") THEN DO:
        cErro = "BANCO_NAO_CONECTADO".
        LEAVE validacao.
    END.
    IF LOOKUP(pcModo,"ITENS,EVENTOS") > 0 THEN DO:
        IF piOperacao <= 0 THEN LEAVE validacao.
        FIND FIRST bOper NO-LOCK WHERE bOper.id-operacao = piOperacao
            AND bOper.cod-estabel-orig = TRIM(pcEstabel) NO-ERROR.
        IF NOT AVAILABLE bOper THEN DO:
            cErro = "OPERACAO_INDISPONIVEL".
            LEAVE validacao.
        END.
    END.
    IF pcModo = "RESULTADO" THEN DO:
        /* A busca por chave nao admite filtros que ocultem outra correspondencia. */
        IF piOperacao <> 0 OR piWt <> 0 OR piApos <> 0 OR pcSituacao <> "" OR pcTipo <> "" THEN LEAVE validacao.
        IF NOT fRestChaveValida(pcChave) THEN LEAVE validacao.
        IF pcRamo = "DIRETO" THEN
            cIdentidade = "DTS1|" + fRestParte(TRIM(pcEstabel)) + "|" + fRestParte(TRIM(pcUsuario)) + "|" + fRestParte(pcChave).
        ELSE IF pcRamo = "DEVOLUCAO" THEN DO:
            IF piEmitente = ? OR piEmitente <= 0 OR pcSerieOrigem = ? OR TRIM(pcSerieOrigem) = "" OR
                pcNumeroOrigem = ? OR TRIM(pcNumeroOrigem) = "" OR pcNatOrigem = ? OR TRIM(pcNatOrigem) = "" THEN LEAVE validacao.
            cIdentidade = "E09|" + fRestParte(TRIM(pcEstabel)) + "|" + STRING(piEmitente) + "|"
                + fRestParte(TRIM(pcSerieOrigem)) + "|" + fRestParte(TRIM(pcNumeroOrigem)) + "|"
                + fRestParte(CAPS(TRIM(pcNatOrigem))) + "|" + fRestParte(TRIM(pcUsuario)) + "|" + fRestParte(pcChave).
        END.
        ELSE LEAVE validacao.
        cMarca = (IF pcRamo = "DIRETO" THEN "DTS1|" ELSE "E09|")
            + HEX-ENCODE(MESSAGE-DIGEST("SHA-256",cIdentidade)) + "|".
    END.
    cErro = "".
END.
IF cErro = "" THEN DO ON ERROR UNDO, THROW:
    IF pcModo = "LISTA" OR pcModo = "RESULTADO" THEN DO:
        FOR EACH bOper NO-LOCK WHERE bOper.cod-estabel-orig = TRIM(pcEstabel)
            AND bOper.id-operacao > piApos USE-INDEX pk BY bOper.id-operacao:
            IF piOperacao > 0 AND bOper.id-operacao <> piOperacao THEN NEXT.
            IF piWt > 0 AND bOper.seq-wt-docto <> piWt THEN NEXT.
            IF pcSituacao <> "" AND bOper.situacao <> pcSituacao THEN NEXT.
            IF pcTipo <> "" AND bOper.tipo-operacao <> pcTipo THEN NEXT.
            IF pcModo = "RESULTADO" AND (bOper.observacao = ? OR NOT bOper.observacao BEGINS cMarca) THEN NEXT.
            IF pcModo = "RESULTADO" AND pcRamo = "DIRETO" THEN DO:
                IF NUM-ENTRIES(bOper.observacao,"|") < 4 OR
                    bOper.observacao <> cMarca + ENTRY(3,bOper.observacao,"|") + "|" + cIdentidade THEN DO:
                    ASSIGN cErro = "CHAVE_IDEMPOTENTE_AMBIGUA" aDados = NEW JsonArray() lMais = NO.
                    LEAVE.
                END.
            END.
            IF aDados:Length >= (IF pcModo = "RESULTADO" THEN 2 ELSE piLimite) THEN DO:
                lMais = YES.
                LEAVE.
            END.
            oLinha = NEW JsonObject().
            oLinha:Add("idOperacao",STRING(bOper.id-operacao)).
            oLinha:Add("wt",IF bOper.seq-wt-docto = ? THEN "" ELSE STRING(bOper.seq-wt-docto)).
            oLinha:Add("codEstabel",bOper.cod-estabel-orig).
            /* Destino fora do recorte autorizado nao expoe dados de outra fazenda. */
            oLinha:Add("codEstabelDestino",IF CAN-FIND(FIRST ttEmbEstabelPermitido
                WHERE ttEmbEstabelPermitido.cod-estabel = bOper.cod-estabel-dest) THEN bOper.cod-estabel-dest ELSE "").
            oLinha:Add("emitente",IF bOper.cod-emitente = ? THEN "" ELSE STRING(bOper.cod-emitente)).
            oLinha:Add("tipoOperacao",bOper.tipo-operacao).
            oLinha:Add("situacao",bOper.situacao).
            oLinha:Add("dataOperacao",bOper.dt-operacao).
            oLinha:Add("versao",STRING(bOper.versao)).
            aDados:Add(oLinha).
            iProximo = bOper.id-operacao.
        END.
        IF pcModo = "RESULTADO" AND (aDados:Length > 1 OR lMais) THEN DO:
            ASSIGN cErro = "CHAVE_IDEMPOTENTE_AMBIGUA" aDados = NEW JsonArray() lMais = NO.
        END.
    END.
    ELSE IF pcModo = "ITENS" THEN DO:
        FOR EACH bLinha NO-LOCK WHERE bLinha.id-operacao = piOperacao
            AND (bLinha.tipo-item = "SOLICITACAO" OR bLinha.tipo-item = "LIBERADA") AND bLinha.id-item-oper > piApos BY bLinha.id-item-oper:
            IF aDados:Length >= piLimite THEN DO:
                lMais = YES.
                LEAVE.
            END.
            oLinha = NEW JsonObject().
            oLinha:Add("idItemOperacao",STRING(bLinha.id-item-oper)).
            oLinha:Add("tipoItem",bLinha.tipo-item).
            oLinha:Add("idEtiqueta",IF bLinha.id-etiqueta = ? THEN "" ELSE STRING(bLinha.id-etiqueta)).
            oLinha:Add("sequencia",bLinha.sequencia).
            oLinha:Add("item",bLinha.it-codigo).
            oLinha:Add("unidade",bLinha.un).
            oLinha:Add("quantidade",bLinha.quantidade).
            oLinha:Add("lote",bLinha.lote).
            oLinha:Add("validadeLote",bLinha.dt-vali-lote).
            oLinha:Add("codTipo",bLinha.cod-tipo).
            aDados:Add(oLinha).
            iProximo = bLinha.id-item-oper.
        END.
    END.
    ELSE DO:
        FOR EACH bEvento NO-LOCK WHERE bEvento.id-operacao = piOperacao
            AND bEvento.id-evento > piApos BY bEvento.id-evento:
            IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido WHERE ttEmbEstabelPermitido.cod-estabel = bEvento.cod-estabel) THEN NEXT.
            IF aDados:Length >= piLimite THEN DO:
                lMais = YES.
                LEAVE.
            END.
            oLinha = NEW JsonObject().
            oLinha:Add("idEvento",STRING(bEvento.id-evento)).
            oLinha:Add("idEventoOrigem",IF bEvento.id-evento-origem = ? THEN "" ELSE STRING(bEvento.id-evento-origem)).
            oLinha:Add("tipoEvento",bEvento.tipo-evento).
            oLinha:Add("situacao",bEvento.situacao).
            oLinha:Add("ciclo",bEvento.seq-ciclo).
            oLinha:Add("codEstabel",bEvento.cod-estabel).
            oLinha:Add("emitente",IF bEvento.cod-emitente = ? THEN "" ELSE STRING(bEvento.cod-emitente)).
            oLinha:Add("serie",bEvento.serie).
            oLinha:Add("numero",bEvento.nro-docto).
            oLinha:Add("natureza",bEvento.nat-operacao).
            oLinha:Add("dataEmissao",bEvento.dt-emissao).
            oLinha:Add("dataConclusao",bEvento.dt-conclusao).
            aDados:Add(oLinha).
            iProximo = bEvento.id-evento.
        END.
    END.
    CATCH eConsulta AS Progress.Lang.Error:
        ASSIGN cErro = "FALHA_CONSULTA_OPERACAO" aDados = NEW JsonArray() lMais = NO.
    END CATCH.
END.
poSaida:Add("sucesso",cErro = "").
poSaida:Add("codigoErro",cErro).
poSaida:Add("mensagem",IF cErro = "" THEN "" ELSE "Nao foi possivel consultar a operacao com os parametros e permissoes informados.").
poSaida:Add("dados",aDados).
poSaida:Add("total",aDados:Length).
poSaida:Add("temMais",lMais).
poSaida:Add("proximoId",IF lMais THEN STRING(iProximo) ELSE "").
END PROCEDURE.

