/* E09 / DT-095: prepara WT pelo padrao, sem efetivar nota/estoque.
   FT4011 usa include nativo. DT-101: FT4012 recebe o schema da BO instalada. */
{fontes/progress/contr-emb.i}
{fontes/progress/includes/native/bodi317sd.i1}

DEFINE TEMP-TABLE ttValidada NO-UNDO LIKE ttEmbOrigemDevolucao.
DEFINE TEMP-TABLE ttTotalLinha NO-UNDO
    FIELD sequencia AS INTEGER
    FIELD quantidade AS DECIMAL
    FIELD disponivel AS DECIMAL
    INDEX pk IS PRIMARY UNIQUE sequencia.
DEFINE TEMP-TABLE RowErrors NO-UNDO
    FIELD errorsequence AS INTEGER
    FIELD errornumber AS INTEGER
    FIELD errordescription AS CHARACTER
    FIELD errorparameters AS CHARACTER
    FIELD errortype AS CHARACTER
    FIELD errorhelp AS CHARACTER
    FIELD errorsubtype AS CHARACTER.

FUNCTION fParte RETURNS CHARACTER (INPUT pcValor AS CHARACTER):
    RETURN STRING(LENGTH(pcValor)) + ":" + pcValor.
END FUNCTION.

/* Capturar imediatamente depois do RUN NO-ERROR, antes de outro RUN/UNDO. */
FUNCTION fErroExecucao RETURNS CHARACTER (INPUT pcRetorno AS CHARACTER):
    DEFINE VARIABLE cDetalhe AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iErro AS INTEGER NO-UNDO.
    DO iErro = 1 TO ERROR-STATUS:NUM-MESSAGES:
        IF iErro > 3 THEN LEAVE.
        cDetalhe = cDetalhe + (IF cDetalhe = "" THEN "" ELSE "; ")
            + "ABL " + STRING(ERROR-STATUS:GET-NUMBER(iErro)) + ": "
            + ERROR-STATUS:GET-MESSAGE(iErro).
    END.
    IF pcRetorno <> ? AND TRIM(pcRetorno) <> "" THEN
        cDetalhe = cDetalhe + (IF cDetalhe = "" THEN "" ELSE "; ")
            + "RETORNO_BO=" + pcRetorno.
    RETURN SUBSTRING(REPLACE(REPLACE(REPLACE(cDetalhe, "~r", " "),
        "~n", " "), "|", "/"), 1, 500).
END FUNCTION.

PROCEDURE detalharFalhaBo:
    DEFINE INPUT PARAMETER phSd AS HANDLE NO-UNDO.
    DEFINE INPUT PARAMETER pcExecucao AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcDetalhe AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cMetodoBo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cTexto AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iErro AS INTEGER NO-UNDO.
    pcDetalhe = pcExecucao.
    IF NOT VALID-HANDLE(phSd) THEN RETURN.
    /* RowErrors precisa ser obtida antes de desfazer a preparacao. */
    RUN devolveErrosbodi317sd IN phSd
        (OUTPUT cMetodoBo, OUTPUT TABLE RowErrors) NO-ERROR.
    FOR EACH RowErrors BY RowErrors.errorsequence:
        IF RowErrors.errordescription = ? OR TRIM(RowErrors.errordescription) = "" THEN NEXT.
        iErro = iErro + 1.
        IF iErro > 3 THEN LEAVE.
        cTexto = "BO " + STRING(RowErrors.errornumber)
            + ": " + RowErrors.errordescription.
        pcDetalhe = pcDetalhe + (IF pcDetalhe = "" THEN "" ELSE "; ") + cTexto.
    END.
    IF pcDetalhe = "" THEN
        pcDetalhe = "BO retornou insucesso sem mensagem ABL/RowErrors.".
    pcDetalhe = SUBSTRING(REPLACE(REPLACE(REPLACE(pcDetalhe, "~r", " "),
        "~n", " "), "|", "/"), 1, 500).
END PROCEDURE.

PROCEDURE criarWtDevolucao:
DEFINE INPUT PARAMETER phOper AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT PARAMETER pcEstabel AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcNatureza AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcSerie AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piEmitente AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcSerieOrigem AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcNumeroOrigem AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcNatOrigem AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcUsuario AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcChave AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER TABLE FOR ttEmbDevolucaoSelecao.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbDevolucaoLinha.
DEFINE OUTPUT PARAMETER piWt AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piOperacao AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.

DEFINE BUFFER bDoc FOR mgmov.docum-est.
DEFINE BUFFER bEmit FOR mgcad.emitente.
DEFINE BUFFER bEtiqueta FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bOper FOR mgesp.contr_emb_oper.
DEFINE BUFFER bSolicitacao FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bEvento FOR mgesp.contr_emb_evento.
DEFINE BUFFER bMovto FOR mgesp.contr_emb_movto.
DEFINE BUFFER bWtItem FOR mgcad.wt-it-docto.
DEFINE BUFFER bWtLote FOR mgcad.wt-fat-ser-lote.
DEFINE BUFFER bSaldo FOR mgmov.saldo-estoq.
DEFINE BUFFER bTerc FOR mgmov.saldo-terc.
DEFINE VARIABLE hInit AS HANDLE NO-UNDO.
DEFINE VARIABLE hSd AS HANDLE NO-UNDO.
DEFINE VARIABLE hPr AS HANDLE NO-UNDO.
DEFINE VARIABLE hIm AS HANDLE NO-UNDO.
DEFINE VARIABLE hVa AS HANDLE NO-UNDO.
DEFINE VARIABLE hTerc AS HANDLE NO-UNDO.
DEFINE VARIABLE hTtTerc AS HANDLE NO-UNDO.
DEFINE VARIABLE hBufTerc AS HANDLE NO-UNDO.
DEFINE VARIABLE hQryTerc AS HANDLE NO-UNDO.
DEFINE VARIABLE hSeqTerc AS HANDLE NO-UNDO.
DEFINE VARIABLE hRowTerc AS HANDLE NO-UNDO.
DEFINE VARIABLE hSelTerc AS HANDLE NO-UNDO.
DEFINE VARIABLE hDispTerc AS HANDLE NO-UNDO.
DEFINE VARIABLE hInfTerc AS HANDLE NO-UNDO.
DEFINE VARIABLE cFluxo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cRamo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cIdentidade AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConteudo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cHash AS CHARACTER NO-UNDO.
DEFINE VARIABLE cHashConteudo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMarca AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMetodo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErroExecucao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDetalheFalha AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMetodoBo AS CHARACTER NO-UNDO.
DEFINE VARIABLE lOk AS LOGICAL NO-UNDO.
DEFINE VARIABLE lOrigem AS LOGICAL NO-UNDO.
DEFINE VARIABLE lQuantidade AS LOGICAL NO-UNDO.
DEFINE VARIABLE lPreco AS LOGICAL NO-UNDO.
DEFINE VARIABLE lMais AS LOGICAL NO-UNDO.
DEFINE VARIABLE iEvento AS INTEGER NO-UNDO.
DEFINE VARIABLE iProximo AS INTEGER NO-UNDO.
DEFINE VARIABLE iUltimo AS INTEGER NO-UNDO.
DEFINE VARIABLE iContagem AS INTEGER NO-UNDO.
DEFINE VARIABLE iLinhas AS INTEGER NO-UNDO.
DEFINE VARIABLE iLotes AS INTEGER NO-UNDO.
DEFINE VARIABLE iSequencia AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE dSaldo AS DECIMAL NO-UNDO.
DEFINE VARIABLE dEstoque AS DECIMAL NO-UNDO.
DEFINE VARIABLE dtAgora AS DATETIME-TZ NO-UNDO.

EMPTY TEMP-TABLE ttEmbDevolucaoLinha.
EMPTY TEMP-TABLE ttValidada.
EMPTY TEMP-TABLE ttTotalLinha.
EMPTY TEMP-TABLE RowErrors.
EMPTY TEMP-TABLE tt-itens-devol.
ASSIGN piWt = 0 piOperacao = 0 plSucesso = NO plRepeticao = NO
       pcErro = "PARAMETRO_INVALIDO" pcMensagem = "Origem, selecao e contexto obrigatorios."
       iUltimo = 0 iContagem = 0 iSequencia = 0
       hInit = ? hSd = ? hPr = ? hIm = ? hVa = ? hTerc = ?.
ASSIGN cDetalheFalha = "" cErroExecucao = "".
ASSIGN hTtTerc = ? hBufTerc = ? hQryTerc = ?
       hSeqTerc = ? hRowTerc = ? hSelTerc = ? hDispTerc = ? hInfTerc = ?.
IF NOT VALID-HANDLE(phOper) OR pcEstabel = ? OR TRIM(pcEstabel) = "" OR
   pcNatureza = ? OR TRIM(pcNatureza) = "" OR pcSerie = ? OR TRIM(pcSerie) = "" OR
   piEmitente = ? OR piEmitente <= 0 OR
   pcSerieOrigem = ? OR TRIM(pcSerieOrigem) = "" OR
   pcNumeroOrigem = ? OR TRIM(pcNumeroOrigem) = "" OR
   pcNatOrigem = ? OR TRIM(pcNatOrigem) = "" OR
   pcUsuario = ? OR TRIM(pcUsuario) = "" OR LENGTH(pcUsuario) > 128 OR
   pcChave = ? OR LENGTH(pcChave) < 1 OR LENGTH(pcChave) > 64 THEN RETURN.
DO i = 1 TO LENGTH(pcChave):
    IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-",
             SUBSTRING(pcChave, i, 1)) = 0 THEN RETURN.
END.
IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido
    WHERE ttEmbEstabelPermitido.cod-estabel = TRIM(pcEstabel)) THEN DO:
    ASSIGN pcErro = "SEM_PERMISSAO" pcMensagem = "Estabelecimento nao autorizado.".
    RETURN.
END.
IF NOT CONNECTED("mgcad") OR NOT CONNECTED("mgmov") OR NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_NAO_CONECTADO" pcMensagem = "Bancos necessarios nao conectados.".
    RETURN.
END.
FOR EACH ttEmbDevolucaoSelecao BY ttEmbDevolucaoSelecao.id-etiqueta:
    IF ttEmbDevolucaoSelecao.id-etiqueta = ? OR ttEmbDevolucaoSelecao.id-etiqueta <= 0 OR
       ttEmbDevolucaoSelecao.versao = ? OR ttEmbDevolucaoSelecao.versao <= 0 OR
       ttEmbDevolucaoSelecao.quantidade = ? OR ttEmbDevolucaoSelecao.quantidade <= 0 OR
       ROUND(ttEmbDevolucaoSelecao.quantidade, 4) <> ttEmbDevolucaoSelecao.quantidade THEN RETURN.
    IF ttEmbDevolucaoSelecao.id-etiqueta = iUltimo THEN DO:
        ASSIGN pcErro = "ETIQUETA_DUPLICADA" pcMensagem = "Selecao contem identidade repetida.".
        RETURN.
    END.
    ASSIGN iUltimo = ttEmbDevolucaoSelecao.id-etiqueta iContagem = iContagem + 1.
END.
IF iContagem < 1 OR iContagem > 100 THEN DO:
    ASSIGN pcErro = "LIMITE_SELECAO_INVALIDO" pcMensagem = "Selecione de 1 a 100 embalagens.".
    RETURN.
END.
/* Chave idempotente escopada pela entrada completa e usuario autorizado. */
ASSIGN pcEstabel = TRIM(pcEstabel) pcNatureza = TRIM(pcNatureza)
       pcSerie = TRIM(pcSerie) pcSerieOrigem = TRIM(pcSerieOrigem)
       pcNumeroOrigem = TRIM(pcNumeroOrigem) pcNatOrigem = TRIM(pcNatOrigem)
       pcUsuario = TRIM(pcUsuario)
       cIdentidade = "E09|" + fParte(pcEstabel) + "|" + STRING(piEmitente)
          + "|" + fParte(pcSerieOrigem) + "|" + fParte(pcNumeroOrigem)
          + "|" + fParte(CAPS(pcNatOrigem)) + "|" + fParte(pcUsuario) + "|" + fParte(pcChave)
       cHash = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cIdentidade))
       cConteudo = cIdentidade + "|" + CAPS(TRIM(pcNatureza)) + "|" + TRIM(pcSerie)
          + "|" + STRING(piEmitente) + "|" + TRIM(pcSerieOrigem) + "|"
          + TRIM(pcNumeroOrigem) + "|" + CAPS(TRIM(pcNatOrigem)).
FOR EACH ttEmbDevolucaoSelecao BY ttEmbDevolucaoSelecao.id-etiqueta:
    cConteudo = cConteudo + "|" + STRING(ttEmbDevolucaoSelecao.id-etiqueta) + ":"
        + STRING(ttEmbDevolucaoSelecao.versao) + ":" + STRING(ttEmbDevolucaoSelecao.quantidade).
END.
ASSIGN cHashConteudo = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cConteudo))
       cMarca = "E09|" + cHash + "|".

criacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    /* Coordena comandos especificos da mesma entrada; estoque continua validado pela BO. */
    FIND FIRST bDoc
        WHERE bDoc.cod-estabel = TRIM(pcEstabel)
          AND bDoc.cod-emitente = piEmitente
          AND bDoc.serie-docto = TRIM(pcSerieOrigem)
          AND bDoc.nro-docto = TRIM(pcNumeroOrigem)
          AND bDoc.nat-operacao = TRIM(pcNatOrigem)
        EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
    IF LOCKED bDoc THEN UNDO criacao, THROW NEW Progress.Lang.AppError("ORIGEM_BLOQUEADA", 0).
    IF NOT AVAILABLE bDoc THEN UNDO criacao, THROW NEW Progress.Lang.AppError("ORIGEM_NAO_ENCONTRADA", 0).
    iContagem = 0.
    FOR EACH bOper NO-LOCK WHERE bOper.cod-estabel-orig = TRIM(pcEstabel)
        USE-INDEX pk:
        IF bOper.observacao = ? OR NOT bOper.observacao BEGINS cMarca THEN NEXT.
        iContagem = iContagem + 1.
        IF ENTRY(3, bOper.observacao, "|") <> cHashConteudo THEN DO:
            /* Recusa antes de qualquer escrita: nao desfazer o comando anterior
               da mesma transacao do chamador nem depender da extracao de excecao. */
            ASSIGN piWt = 0 piOperacao = 0 plSucesso = NO plRepeticao = NO
                pcErro = "CHAVE_IDEMPOTENTE_DIVERGENTE"
                pcMensagem = "A chave ja foi usada com outra selecao ou parametros.".
            RETURN.
        END.
        IF bOper.situacao = "CANCELADA" THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("OPERACAO_CANCELADA", 0).
        ASSIGN piWt = bOper.seq-wt-docto piOperacao = bOper.id-operacao.
    END.
    IF iContagem > 1 THEN UNDO criacao, THROW NEW Progress.Lang.AppError("CHAVE_IDEMPOTENTE_AMBIGUA", 0).
    IF iContagem = 1 THEN DO:
        ASSIGN plSucesso = YES plRepeticao = YES pcErro = ""
               pcMensagem = "Preparacao ja registrada; nao foi criado outro WT.".
        LEAVE criacao.
    END.
    RUN classificarNaturezaOperacao IN phOper (INPUT pcNatureza,
        OUTPUT cFluxo, OUTPUT cRamo, OUTPUT lOrigem, OUTPUT lQuantidade,
        OUTPUT lPreco, OUTPUT lOk, OUTPUT pcErro) NO-ERROR.
    IF ERROR-STATUS:ERROR OR (lOk = ? OR lOk = NO) OR
       (cFluxo <> "DEVOLUCAO_COMPRA" AND cFluxo <> "RETORNO_TERCEIROS") THEN
        UNDO criacao, THROW NEW Progress.Lang.AppError("NATUREZA_FORA_DA_DEVOLUCAO", 0).
    /* Locks em ordem deterministica; consulta de elegibilidade refeita sob esses locks. */
    FOR EACH ttEmbDevolucaoSelecao BY ttEmbDevolucaoSelecao.id-etiqueta:
        FIND FIRST bEtiqueta
            WHERE bEtiqueta.id-etiqueta = ttEmbDevolucaoSelecao.id-etiqueta
            EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF LOCKED bEtiqueta THEN UNDO criacao, THROW NEW Progress.Lang.AppError("ETIQUETA_BLOQUEADA", 0).
        IF NOT AVAILABLE bEtiqueta THEN UNDO criacao, THROW NEW Progress.Lang.AppError("ETIQUETA_NAO_ENCONTRADA", 0).
        IF bEtiqueta.versao <> ttEmbDevolucaoSelecao.versao THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("VERSAO_ETIQUETA_DIVERGENTE", 0).
        RUN consultarEmbalagensOrigem IN phOper (INPUT TABLE ttEmbEstabelPermitido,
            INPUT pcEstabel, INPUT pcNatureza, INPUT piEmitente, INPUT pcSerieOrigem,
            INPUT pcNumeroOrigem, INPUT pcNatOrigem,
            INPUT ttEmbDevolucaoSelecao.id-etiqueta - 1, INPUT 1,
            OUTPUT TABLE ttEmbOrigemDevolucao, OUTPUT iEvento, OUTPUT lMais,
            OUTPUT iProximo, OUTPUT lOk, OUTPUT pcErro, OUTPUT pcMensagem) NO-ERROR.
        IF ERROR-STATUS:ERROR OR (lOk = ? OR lOk = NO) THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("ORIGEM_NAO_ELEGIVEL", 0).
        FIND FIRST ttEmbOrigemDevolucao
            WHERE ttEmbOrigemDevolucao.id-etiqueta = ttEmbDevolucaoSelecao.id-etiqueta NO-ERROR.
        IF NOT AVAILABLE ttEmbOrigemDevolucao THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("ETIQUETA_FORA_DA_ORIGEM", 0).
        IF ttEmbOrigemDevolucao.pode-selecionar <> YES THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError(ttEmbOrigemDevolucao.motivo, 0).
        IF ttEmbOrigemDevolucao.versao-etiqueta <> ttEmbDevolucaoSelecao.versao OR
           ttEmbOrigemDevolucao.quantidade-atual <> ttEmbDevolucaoSelecao.quantidade THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("QUANTIDADE_OU_VERSAO_DIVERGENTE", 0).
        CREATE ttValidada.
        BUFFER-COPY ttEmbOrigemDevolucao TO ttValidada.
        FIND ttTotalLinha WHERE ttTotalLinha.sequencia = ttValidada.sequencia-origem NO-ERROR.
        IF NOT AVAILABLE ttTotalLinha THEN DO:
            CREATE ttTotalLinha.
            ASSIGN ttTotalLinha.sequencia = ttValidada.sequencia-origem
                   ttTotalLinha.disponivel = ttValidada.disponivel-linha.
        END.
        ttTotalLinha.quantidade = ttTotalLinha.quantidade + ttValidada.quantidade-atual.
        FIND ttEmbDevolucaoLinha WHERE
            ttEmbDevolucaoLinha.sequencia-origem = ttValidada.sequencia-origem
            AND ttEmbDevolucaoLinha.it-codigo = ttValidada.it-codigo
            AND ttEmbDevolucaoLinha.lote = ttValidada.lote
            AND ttEmbDevolucaoLinha.dt-vali-lote = ttValidada.dt-vali-lote
            AND ttEmbDevolucaoLinha.un = ttValidada.un
            AND ttEmbDevolucaoLinha.cod-depos = ttValidada.cod-depos
            AND ttEmbDevolucaoLinha.cod-localiz = ttValidada.cod-localiz NO-ERROR.
        IF NOT AVAILABLE ttEmbDevolucaoLinha THEN DO:
            CREATE ttEmbDevolucaoLinha.
            ASSIGN ttEmbDevolucaoLinha.sequencia-origem = ttValidada.sequencia-origem
                ttEmbDevolucaoLinha.it-codigo = ttValidada.it-codigo
                ttEmbDevolucaoLinha.lote = ttValidada.lote
                ttEmbDevolucaoLinha.dt-vali-lote = ttValidada.dt-vali-lote
                ttEmbDevolucaoLinha.un = ttValidada.un
                ttEmbDevolucaoLinha.cod-depos = ttValidada.cod-depos
                ttEmbDevolucaoLinha.cod-localiz = ttValidada.cod-localiz.
        END.
        ttEmbDevolucaoLinha.quantidade = ttEmbDevolucaoLinha.quantidade + ttValidada.quantidade-atual.
    END.
    FOR EACH ttTotalLinha:
        IF ttTotalLinha.quantidade > ttTotalLinha.disponivel THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("SALDO_DOCUMENTAL_INSUFICIENTE", 0).
    END.
    /* Soma por posicao em todas as linhas: mesma posicao nao multiplica saldo. */
    FOR EACH ttEmbDevolucaoLinha BREAK BY ttEmbDevolucaoLinha.it-codigo
        BY ttEmbDevolucaoLinha.lote BY ttEmbDevolucaoLinha.dt-vali-lote
        BY ttEmbDevolucaoLinha.un BY ttEmbDevolucaoLinha.cod-depos
        BY ttEmbDevolucaoLinha.cod-localiz:
        IF FIRST-OF(ttEmbDevolucaoLinha.cod-localiz) THEN dSaldo = 0.
        dSaldo = dSaldo + ttEmbDevolucaoLinha.quantidade.
        IF LAST-OF(ttEmbDevolucaoLinha.cod-localiz) THEN DO:
            dEstoque = 0.
            FOR EACH bSaldo NO-LOCK WHERE bSaldo.cod-estab = TRIM(pcEstabel)
                AND bSaldo.it-codigo = ttEmbDevolucaoLinha.it-codigo
                AND bSaldo.lote = ttEmbDevolucaoLinha.lote
                AND bSaldo.dt-vali-lote = ttEmbDevolucaoLinha.dt-vali-lote
                AND bSaldo.cod-depos = ttEmbDevolucaoLinha.cod-depos
                AND bSaldo.cod-localiz = ttEmbDevolucaoLinha.cod-localiz:
                dEstoque = dEstoque + bSaldo.qtidade-atu.
            END.
            IF dEstoque = ? OR dEstoque < dSaldo THEN
                UNDO criacao, THROW NEW Progress.Lang.AppError("SALDO_ESTOQUE_INSUFICIENTE", 0).
        END.
    END.
    FIND FIRST bEmit NO-LOCK WHERE bEmit.cod-emitente = piEmitente NO-ERROR.
    IF NOT AVAILABLE bEmit THEN UNDO criacao, THROW NEW Progress.Lang.AppError("EMITENTE_NAO_ENCONTRADO", 0).
    cMetodo = "INICIALIZAR_BODI317".
    RUN dibo/bodi317in.p PERSISTENT SET hInit NO-ERROR.
    IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hInit) THEN
        UNDO criacao, THROW NEW Progress.Lang.AppError("BODI317_INICIALIZACAO_FALHOU", 0).
    RUN inicializaBOS IN hInit (OUTPUT hPr, OUTPUT hSd, OUTPUT hIm, OUTPUT hVa) NO-ERROR.
    IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hSd) OR NOT VALID-HANDLE(hPr) OR
       NOT VALID-HANDLE(hVa) THEN UNDO criacao, THROW NEW Progress.Lang.AppError("BODI317_BOS_INDISPONIVEIS", 0).
    cMetodo = "criaWtDocto".
    RUN criaWtDocto IN hSd (INPUT pcUsuario, INPUT pcEstabel, INPUT pcSerie,
        INPUT "", INPUT bEmit.nome-abrev, INPUT ?, INPUT 4, INPUT 4003,
        INPUT TODAY, INPUT 0, INPUT pcNatureza, INPUT bEmit.cod-canal-venda,
        OUTPUT piWt, OUTPUT lOk) NO-ERROR.
    IF ERROR-STATUS:ERROR OR (lOk = ? OR lOk = NO) OR piWt <= 0 THEN DO:
        cErroExecucao = fErroExecucao(RETURN-VALUE).
        RUN detalharFalhaBo (INPUT hSd, INPUT cErroExecucao, OUTPUT cDetalheFalha).
        UNDO criacao, THROW NEW Progress.Lang.AppError("CRIAR_WT_FALHOU", 0).
    END.
    IF cRamo = "FT4011" THEN DO:
        cMetodo = "geraItensDevolucaoTtItensDevol".
        RUN geraItensDevolucaoTtItensDevol IN hSd (INPUT piWt,
            INPUT pcSerieOrigem, INPUT pcNumeroOrigem, INPUT pcNatOrigem,
            OUTPUT TABLE tt-itens-devol, OUTPUT lOk) NO-ERROR.
        IF ERROR-STATUS:ERROR OR (lOk = ? OR lOk = NO) THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("CONSULTAR_ITENS_BO_FALHOU", 0).
        FOR EACH tt-itens-devol: tt-itens-devol.selecionado = NO. END.
        FOR EACH ttTotalLinha:
            FIND FIRST tt-itens-devol WHERE tt-itens-devol.sequencia = ttTotalLinha.sequencia NO-ERROR.
            IF NOT AVAILABLE tt-itens-devol THEN
                UNDO criacao, THROW NEW Progress.Lang.AppError("LINHA_ORIGEM_NAO_ENCONTRADA_BO", 0).
            IF tt-itens-devol.qt-a-devolver = ? OR tt-itens-devol.qt-a-devolver < ttTotalLinha.quantidade THEN
                UNDO criacao, THROW NEW Progress.Lang.AppError("SALDO_BO_INSUFICIENTE", 0).
            ASSIGN tt-itens-devol.selecionado = YES
                   tt-itens-devol.qt-a-devolver-inf = ttTotalLinha.quantidade.
        END.
        cMetodo = "geraWtItDoctoPartindoDoTtItensDevol".
        RUN geraWtItDoctoPartindoDoTtItensDevol IN hSd
            (INPUT piWt, INPUT TABLE tt-itens-devol, OUTPUT lOk) NO-ERROR.
    END.
    ELSE DO:
        cMetodo = "geraItensTerceirosTtItTercNf".
        RUN geraItensTerceirosTtItTercNf IN hSd (INPUT piWt,
            INPUT pcSerieOrigem, INPUT pcNumeroOrigem, INPUT pcNatOrigem,
            INPUT 100, INPUT 0, OUTPUT TABLE-HANDLE hTtTerc, OUTPUT lOk) NO-ERROR.
        IF ERROR-STATUS:ERROR OR (lOk = ? OR lOk = NO) THEN DO:
            cErroExecucao = fErroExecucao(RETURN-VALUE).
            RUN detalharFalhaBo (INPUT hSd, INPUT cErroExecucao, OUTPUT cDetalheFalha).
            UNDO criacao, THROW NEW Progress.Lang.AppError("CONSULTAR_TERCEIROS_BO_FALHOU", 0).
        END.
        /* A BO devolve seu schema completo: nao depender da copia historica da TT.
           A copia dinamica pertence ao chamador, enviada de volta por valor. */
        cMetodo = "validarTabelaTerceirosBo".
        IF NOT VALID-HANDLE(hTtTerc) THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("TABELA_TERCEIROS_BO_AUSENTE", 0).
        hBufTerc = hTtTerc:DEFAULT-BUFFER-HANDLE.
        ASSIGN hSeqTerc = hBufTerc:BUFFER-FIELD("sequencia")
               hRowTerc = hBufTerc:BUFFER-FIELD("rw-saldo-terc")
               hSelTerc = hBufTerc:BUFFER-FIELD("selecionado")
               hDispTerc = hBufTerc:BUFFER-FIELD("qt-disponivel")
               hInfTerc = hBufTerc:BUFFER-FIELD("qt-disponivel-inf") NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hSeqTerc) OR
           NOT VALID-HANDLE(hRowTerc) OR NOT VALID-HANDLE(hSelTerc) OR
           NOT VALID-HANDLE(hDispTerc) OR NOT VALID-HANDLE(hInfTerc) THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("TABELA_TERCEIROS_BO_CAMPOS_INCOMPATIVEIS", 0).
        IF (hSeqTerc:DATA-TYPE <> "INTEGER" AND hSeqTerc:DATA-TYPE <> "INT64") OR
           hRowTerc:DATA-TYPE <> "ROWID" OR hSelTerc:DATA-TYPE <> "LOGICAL" OR
           hDispTerc:DATA-TYPE <> "DECIMAL" OR hInfTerc:DATA-TYPE <> "DECIMAL" OR
           hSeqTerc:EXTENT <> 0 OR hRowTerc:EXTENT <> 0 OR hSelTerc:EXTENT <> 0 OR
           hDispTerc:EXTENT <> 0 OR hInfTerc:EXTENT <> 0 THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("TABELA_TERCEIROS_BO_TIPOS_INCOMPATIVEIS", 0).
        CREATE QUERY hQryTerc.
        IF NOT hQryTerc:SET-BUFFERS(hBufTerc) THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("CONSULTA_TABELA_TERCEIROS_FALHOU", 0).
        IF NOT hQryTerc:QUERY-PREPARE("FOR EACH " + hBufTerc:NAME
            + " BY " + hBufTerc:NAME + ".sequencia") THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("CONSULTA_TABELA_TERCEIROS_FALHOU", 0).
        IF NOT hQryTerc:QUERY-OPEN() THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("CONSULTA_TABELA_TERCEIROS_FALHOU", 0).
        hQryTerc:GET-FIRST().
        DO WHILE NOT hQryTerc:QUERY-OFF-END:
            hSelTerc:BUFFER-VALUE = NO.
            hQryTerc:GET-NEXT().
        END.
        FOR EACH ttTotalLinha:
            iLinhas = 0.
            hQryTerc:GET-FIRST().
            DO WHILE NOT hQryTerc:QUERY-OFF-END:
                IF hSeqTerc:BUFFER-VALUE <> ttTotalLinha.sequencia THEN DO:
                    hQryTerc:GET-NEXT().
                    NEXT.
                END.
                FIND FIRST bTerc NO-LOCK WHERE ROWID(bTerc) = hRowTerc:BUFFER-VALUE NO-ERROR.
                IF NOT AVAILABLE bTerc THEN DO:
                    hQryTerc:GET-NEXT().
                    NEXT.
                END.
                IF bTerc.cod-estabel <> pcEstabel OR bTerc.cod-emitente <> piEmitente OR
                   bTerc.serie-docto <> pcSerieOrigem OR bTerc.nro-docto <> pcNumeroOrigem OR
                   bTerc.nat-operacao <> pcNatOrigem OR bTerc.sequencia <> ttTotalLinha.sequencia THEN DO:
                    hQryTerc:GET-NEXT().
                    NEXT.
                END.
                iLinhas = iLinhas + 1.
                IF hDispTerc:BUFFER-VALUE = ? OR hDispTerc:BUFFER-VALUE < ttTotalLinha.quantidade THEN
                    UNDO criacao, THROW NEW Progress.Lang.AppError("SALDO_BO_INSUFICIENTE", 0).
                ASSIGN hSelTerc:BUFFER-VALUE = YES
                       hInfTerc:BUFFER-VALUE = ttTotalLinha.quantidade.
                hQryTerc:GET-NEXT().
            END.
            IF iLinhas <> 1 THEN UNDO criacao, THROW NEW Progress.Lang.AppError("LINHA_TERCEIROS_AMBIGUA_BO", 0).
        END.
        hQryTerc:QUERY-CLOSE().
        RUN inbo/boin404te.p PERSISTENT SET hTerc NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hTerc) THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("BOIN404TE_INDISPONIVEL", 0).
        RUN setaHandleBoin404te IN hSd (INPUT hTerc) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN UNDO criacao, THROW NEW Progress.Lang.AppError("BOIN404TE_VINCULO_FALHOU", 0).
        cMetodo = "geraWtItDoctoPartindoDoTtItTercNf".
        RUN geraWtItDoctoPartindoDoTtItTercNf IN hSd
            (INPUT piWt, INPUT 10, INPUT 10, INPUT TABLE-HANDLE hTtTerc, OUTPUT lOk) NO-ERROR.
    END.
    IF ERROR-STATUS:ERROR OR (lOk = ? OR lOk = NO) THEN DO:
        cErroExecucao = fErroExecucao(RETURN-VALUE).
        RUN detalharFalhaBo (INPUT hSd, INPUT cErroExecucao, OUTPUT cDetalheFalha).
        UNDO criacao, THROW NEW Progress.Lang.AppError("GERAR_ITENS_WT_FALHOU", 0).
    END.
    /* Conferencia estrita do resultado. Nao troca origem/lote sugerido pelo padrao. */
    iLinhas = 0.
    FOR EACH bWtItem NO-LOCK WHERE bWtItem.seq-wt-docto = piWt:
        iLinhas = iLinhas + 1.
        FIND ttTotalLinha WHERE ttTotalLinha.sequencia = bWtItem.seq-comp NO-ERROR.
        IF NOT AVAILABLE ttTotalLinha THEN UNDO criacao, THROW NEW Progress.Lang.AppError("WT_LINHA_NAO_SELECIONADA", 0).
        IF bWtItem.serie-comp <> pcSerieOrigem OR bWtItem.nro-comp <> pcNumeroOrigem OR
           bWtItem.nat-comp <> pcNatOrigem OR bWtItem.quantidade[1] <> ttTotalLinha.quantidade THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("WT_ORIGEM_OU_QUANTIDADE_DIVERGENTE", 0).
        iLotes = 0.
        FOR EACH bWtLote NO-LOCK WHERE bWtLote.seq-wt-docto = piWt
            AND bWtLote.seq-wt-it-docto = bWtItem.seq-wt-it-docto:
            iLotes = iLotes + 1.
            FIND FIRST ttEmbDevolucaoLinha WHERE
                ttEmbDevolucaoLinha.sequencia-origem = bWtItem.seq-comp
                AND ttEmbDevolucaoLinha.it-codigo = bWtLote.it-codigo
                AND ttEmbDevolucaoLinha.lote = bWtLote.lote
                AND ttEmbDevolucaoLinha.cod-depos = bWtLote.cod-depos
                AND ttEmbDevolucaoLinha.cod-localiz = bWtLote.cod-localiz NO-ERROR.
            IF NOT AVAILABLE ttEmbDevolucaoLinha THEN
                UNDO criacao, THROW NEW Progress.Lang.AppError("RATEIO_BO_FORA_DA_SELECAO", 0).
            IF bWtItem.it-codigo <> ttEmbDevolucaoLinha.it-codigo OR
               bWtItem.un[1] <> ttEmbDevolucaoLinha.un OR
               bWtLote.quantidade[1] <> ttEmbDevolucaoLinha.quantidade OR
               (bWtLote.dt-vali-lote <> ? AND bWtLote.dt-vali-lote <> ttEmbDevolucaoLinha.dt-vali-lote) OR
               ttEmbDevolucaoLinha.seq-wt-it-docto <> 0 THEN
                UNDO criacao, THROW NEW Progress.Lang.AppError("RATEIO_BO_DIVERGENTE", 0).
            ttEmbDevolucaoLinha.seq-wt-it-docto = bWtItem.seq-wt-it-docto.
            cMetodo = "criaAlteraWtFatSerLote".
            RUN criaAlteraWtFatSerLote IN hSd (INPUT NO, INPUT piWt,
                INPUT bWtItem.seq-wt-it-docto, INPUT ttEmbDevolucaoLinha.it-codigo,
                INPUT ttEmbDevolucaoLinha.cod-depos, INPUT ttEmbDevolucaoLinha.cod-localiz,
                INPUT ttEmbDevolucaoLinha.lote, INPUT ttEmbDevolucaoLinha.quantidade,
                INPUT 0, INPUT ttEmbDevolucaoLinha.dt-vali-lote, OUTPUT lOk) NO-ERROR.
            IF ERROR-STATUS:ERROR OR (lOk = ? OR lOk = NO) THEN
                UNDO criacao, THROW NEW Progress.Lang.AppError("VALIDADE_RATEIO_BO_FALHOU", 0).
        END.
        IF iLotes = 0 THEN UNDO criacao, THROW NEW Progress.Lang.AppError("WT_SEM_RATEIO_ESTOQUE", 0).
        cMetodo = "validaItemDaNota".
        RUN validaItemDaNota IN hVa (INPUT piWt, INPUT bWtItem.seq-wt-it-docto, OUTPUT lOk) NO-ERROR.
        IF ERROR-STATUS:ERROR OR (lOk = ? OR lOk = NO) THEN
            UNDO criacao, THROW NEW Progress.Lang.AppError("VALIDAR_ITEM_WT_FALHOU", 0).
    END.
    iContagem = 0.
    FOR EACH ttTotalLinha: iContagem = iContagem + 1. END.
    IF iLinhas <> iContagem OR CAN-FIND(FIRST ttEmbDevolucaoLinha
        WHERE ttEmbDevolucaoLinha.seq-wt-it-docto = 0) THEN
        UNDO criacao, THROW NEW Progress.Lang.AppError("WT_SELECAO_INCOMPLETA", 0).
    FIND FIRST bEvento NO-LOCK WHERE bEvento.id-evento = iEvento NO-ERROR.
    IF NOT AVAILABLE bEvento THEN UNDO criacao, THROW NEW Progress.Lang.AppError("EVENTO_ORIGEM_AUSENTE", 0).
    ASSIGN dtAgora = NOW piOperacao = NEXT-VALUE(CONTR_EMB_OPER_SEQ, mgesp).
    CREATE bOper.
    ASSIGN bOper.id-operacao = piOperacao bOper.seq-wt-docto = piWt
        bOper.tipo-operacao = cFluxo bOper.cod-estabel-orig = TRIM(pcEstabel)
        bOper.cod-emitente = piEmitente bOper.situacao = "SOLICITADA"
        bOper.id-oper-origem = bEvento.id-operacao
        bOper.observacao = cMarca + cHashConteudo + "|EVENTO=" + STRING(iEvento)
        bOper.dt-operacao = dtAgora bOper.dt-inclusao = dtAgora
        bOper.usuario-inclusao = TRIM(pcUsuario) bOper.dt-alteracao = dtAgora
        bOper.usuario-alteracao = TRIM(pcUsuario) bOper.versao = 1.
    FOR EACH ttValidada BY ttValidada.id-etiqueta:
        FIND FIRST bEtiqueta NO-LOCK WHERE bEtiqueta.id-etiqueta = ttValidada.id-etiqueta NO-ERROR.
        FIND FIRST bMovto NO-LOCK WHERE bMovto.id-movto = ttValidada.id-movto-origem NO-ERROR.
        IF NOT AVAILABLE bMovto THEN UNDO criacao, THROW NEW Progress.Lang.AppError("MOVIMENTO_ORIGEM_AUSENTE", 0).
        iSequencia = iSequencia + 1.
        CREATE bSolicitacao.
        ASSIGN bSolicitacao.id-item-oper = NEXT-VALUE(CONTR_EMB_OPER_ITEM_SEQ, mgesp)
            bSolicitacao.id-operacao = piOperacao bSolicitacao.sequencia = iSequencia
            bSolicitacao.id-etiqueta = ttValidada.id-etiqueta
            bSolicitacao.tipo-item = "SOLICITACAO"
            bSolicitacao.it-codigo = ttValidada.it-codigo bSolicitacao.un = ttValidada.un
            bSolicitacao.lote = ttValidada.lote bSolicitacao.dt-vali-lote = ttValidada.dt-vali-lote
            bSolicitacao.quantidade = ttValidada.quantidade-atual bSolicitacao.cod-tipo = bEtiqueta.cod-tipo
            bSolicitacao.id-item-origem = bMovto.id-item-oper
            bSolicitacao.justificativa = "E09|EVENTO=" + STRING(iEvento)
                + "|MOVTO=" + STRING(ttValidada.id-movto-origem)
                + "|SEQ_ORIGEM=" + STRING(ttValidada.sequencia-origem)
            bSolicitacao.dt-inclusao = dtAgora bSolicitacao.usuario-inclusao = TRIM(pcUsuario)
            bSolicitacao.dt-alteracao = dtAgora bSolicitacao.usuario-alteracao = TRIM(pcUsuario)
            bSolicitacao.versao = 1.
    END.
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "WT preparado com origem e embalagens; nota nao efetivada.".
    CATCH eFalha AS Progress.Lang.Error:
        /* Somente codigos funcionais gerados neste modulo podem atravessar a fronteira. */
        ASSIGN piWt = 0 piOperacao = 0 plSucesso = NO plRepeticao = NO.
        IF TYPE-OF(eFalha, Progress.Lang.AppError) THEN pcErro = eFalha:GetMessage(1).
        ELSE pcErro = "FALHA_CRIACAO_DEVOLUCAO".
        pcMensagem = "Preparacao desfeita; etapa=" + cMetodo + ".".
        IF cDetalheFalha <> "" THEN
            pcMensagem = "etapa=" + cMetodo + "; " + cDetalheFalha.
        ELSE IF VALID-HANDLE(hSd) THEN DO:
            RUN devolveErrosbodi317sd IN hSd (OUTPUT cMetodoBo, OUTPUT TABLE RowErrors) NO-ERROR.
            FOR FIRST RowErrors WHERE RowErrors.errorsubtype = "ERROR" OR RowErrors.errortype = "ERROR":
                pcMensagem = "BO " + STRING(RowErrors.errornumber) + ": " + SUBSTRING(RowErrors.errordescription, 1, 500).
            END.
        END.
        EMPTY TEMP-TABLE ttEmbDevolucaoLinha.
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hQryTerc) THEN DELETE OBJECT hQryTerc NO-ERROR.
        IF VALID-HANDLE(hTtTerc) THEN DELETE OBJECT hTtTerc NO-ERROR.
        IF VALID-HANDLE(hTerc) THEN DELETE PROCEDURE hTerc NO-ERROR.
        IF VALID-HANDLE(hVa) THEN DELETE PROCEDURE hVa NO-ERROR.
        IF VALID-HANDLE(hIm) THEN DELETE PROCEDURE hIm NO-ERROR.
        IF VALID-HANDLE(hSd) THEN DELETE PROCEDURE hSd NO-ERROR.
        IF VALID-HANDLE(hPr) THEN DELETE PROCEDURE hPr NO-ERROR.
        IF VALID-HANDLE(hInit) THEN DELETE PROCEDURE hInit NO-ERROR.
    END FINALLY.
END.
END PROCEDURE.
