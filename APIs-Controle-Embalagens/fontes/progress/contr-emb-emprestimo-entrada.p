{fontes/progress/contr-emb-caminhos.i}
/* E12/E13: chegada integral do emprestimo e de seu retorno.
   O RE1001 atualiza a entrada e o estoque consolidado. Este servico apenas
   move as identidades individuais da saida confirmada ao estabelecimento
   de destino. DT-100: origem documental unica e continuidade por snapshot,
   compartilhadas com a transferencia. */
{fontes/progress/contr-emb.i}
DEFINE TEMP-TABLE ttRecVinculoCmd NO-UNDO LIKE ttEmbEventoComando.
DEFINE STREAM sE05Diag.
DEFINE TEMP-TABLE ttE12Grupo NO-UNDO
    FIELD it-codigo LIKE mgcad.item.it-codigo
    FIELD lote LIKE mgmov.rat-lote.lote
    FIELD validade AS DATE
    FIELD un LIKE mgcad.item.un
    FIELD r-linha AS ROWID
    FIELD r-rateio AS ROWID
    FIELD quantidade AS DECIMAL DECIMALS 4
    FIELD selecionada AS DECIMAL DECIMALS 4
    INDEX grupo IS UNIQUE it-codigo lote validade un.


PROCEDURE processarEntradaEmprestimo:
DEFINE INPUT PARAMETER prDocumEst AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER phRastreio AS HANDLE NO-UNDO.
DEFINE OUTPUT PARAMETER plAplicavel AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piIdEvento AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piQtdEtiquetas AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.

DEFINE BUFFER bNatureza FOR mgcad.natur-oper.
DEFINE BUFFER bNaturezaSaida FOR mgcad.natur-oper.
DEFINE BUFFER bEntrada FOR mgmov.docum-est.
DEFINE BUFFER bLinhaEntrada FOR mgmov.item-doc-est.
DEFINE BUFFER bRateioEntrada FOR mgmov.rat-lote.
DEFINE BUFFER bOrigem FOR mgcad.estabelec.
DEFINE BUFFER bDestino FOR mgcad.estabelec.
DEFINE BUFFER bNotaSaida FOR mgmov.nota-fiscal.
DEFINE BUFFER bDocumentoSaida FOR mgesp.contr_emb_evento.
DEFINE BUFFER bOperacao FOR mgesp.contr_emb_oper.
DEFINE BUFFER bOperacaoLock FOR mgesp.contr_emb_oper.
DEFINE BUFFER bSaida FOR mgesp.contr_emb_evento.
DEFINE BUFFER bReversao FOR mgesp.contr_emb_evento.
DEFINE BUFFER bEntradaAnterior FOR mgesp.contr_emb_evento.
DEFINE BUFFER bReversaoEntrada FOR mgesp.contr_emb_evento.
DEFINE BUFFER bNovoEvento FOR mgesp.contr_emb_evento.
DEFINE BUFFER bSelecao FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bEtiqueta FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bMovtoSaida FOR mgesp.contr_emb_movto.
DEFINE BUFFER bMovtoUltimo FOR mgesp.contr_emb_movto.

DEFINE VARIABLE cTipoOperacao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipoEvento AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipoMovimento AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipoSaida AS CHARACTER NO-UNDO.
DEFINE VARIABLE cPosicaoOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE lRetorno AS LOGICAL NO-UNDO.
DEFINE VARIABLE lArmazenagem AS LOGICAL NO-UNDO.
DEFINE VARIABLE cTipoResolucao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSerieSaida AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNumeroSaida AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChaveDocto AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChaveEvento AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConteudo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSituacao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErroNucleo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMsgNucleo AS CHARACTER NO-UNDO.
DEFINE VARIABLE iLinhasEntrada AS INTEGER NO-UNDO.
DEFINE VARIABLE iRateiosEntrada AS INTEGER NO-UNDO.
DEFINE VARIABLE iOrigens AS INTEGER NO-UNDO.
DEFINE VARIABLE iNotas AS INTEGER NO-UNDO.
DEFINE VARIABLE iDocumentos AS INTEGER NO-UNDO.
DEFINE VARIABLE iSaidasAtivas AS INTEGER NO-UNDO.
DEFINE VARIABLE iEntradasAnteriores AS INTEGER NO-UNDO.
DEFINE VARIABLE iEntradasAtivas AS INTEGER NO-UNDO.
DEFINE VARIABLE iReversoesEntrada AS INTEGER NO-UNDO.
DEFINE VARIABLE iCicloUltimo AS INTEGER NO-UNDO.
DEFINE VARIABLE iCicloNovo AS INTEGER NO-UNDO.
DEFINE VARIABLE iUltimaReversao AS INTEGER NO-UNDO.
DEFINE VARIABLE iCicloEntradaAtiva AS INTEGER NO-UNDO.
DEFINE VARIABLE iOperacao AS INTEGER NO-UNDO.
DEFINE VARIABLE iDocumentoSaida AS INTEGER NO-UNDO.
DEFINE VARIABLE iSaidaAtiva AS INTEGER NO-UNDO.
DEFINE VARIABLE iSeq AS INTEGER NO-UNDO.
DEFINE VARIABLE iMovto AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersao AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersaoEvento AS INTEGER NO-UNDO.
DEFINE VARIABLE rNotaSaida AS ROWID NO-UNDO.
DEFINE VARIABLE deQuantidade AS DECIMAL NO-UNDO.
DEFINE VARIABLE lNucleo AS LOGICAL NO-UNDO.
DEFINE VARIABLE lRepNucleo AS LOGICAL NO-UNDO.
DEFINE VARIABLE lOrigemResolvida AS LOGICAL NO-UNDO.
DEFINE VARIABLE lContinuidade AS LOGICAL NO-UNDO.
DEFINE VARIABLE iVinculo AS INTEGER NO-UNDO.
DEFINE VARIABLE dtAgora AS DATETIME-TZ NO-UNDO.

EMPTY TEMP-TABLE ttEmbEventoComando.
EMPTY TEMP-TABLE ttEmbMovimentoComando.
ASSIGN plAplicavel = NO plSucesso = NO plRepeticao = NO
       piIdEvento = 0 piQtdEtiquetas = 0
       pcErro = "E12_ENTRADA_INVALIDA"
       pcMensagem = "Documento ou nucleo de rastreio invalido.".
IF prDocumEst = ? OR NOT VALID-HANDLE(phRastreio) THEN RETURN.
IF NOT CONNECTED("mgmov") OR NOT CONNECTED("mgcad") OR
   NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "E12_BANCO_NAO_CONECTADO"
           pcMensagem = "Bancos necessarios nao conectados.".
    RETURN.
END.
FIND FIRST bEntrada NO-LOCK WHERE ROWID(bEntrada) = prDocumEst NO-ERROR.
IF NOT AVAILABLE bEntrada THEN RETURN.

FIND FIRST bNatureza NO-LOCK
    WHERE bNatureza.nat-operacao = bEntrada.nat-operacao NO-ERROR.
IF NOT AVAILABLE bNatureza THEN DO:
    ASSIGN pcErro = "E12_NATUREZA_AUSENTE" pcMensagem = "Natureza da entrada nao cadastrada.".
    RETURN.
END.
IF bNatureza.especie-doc = ? OR CAPS(TRIM(bNatureza.especie-doc)) <> "NFE" OR
   bNatureza.terceiros = ? OR bNatureza.terceiros <> YES OR
   bNatureza.tp-oper-terc = ? OR LOOKUP(STRING(bNatureza.tp-oper-terc), "3,5") = 0 THEN DO:
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "Natureza fora da entrada de emprestimo.".
    RETURN.
END.
ASSIGN lRetorno = bNatureza.tp-oper-terc = 5
       cTipoOperacao = IF lRetorno THEN "RETORNO_TERCEIROS" ELSE "REMESSA_TERCEIROS"
       cTipoEvento = IF lRetorno THEN "RECEBIMENTO_RETORNO_EMPRESTIMO" ELSE "RECEBIMENTO_EMPRESTIMO"
       cTipoMovimento = IF lRetorno THEN "ENTRADA_RETORNO_EMPRESTIMO" ELSE "ENTRADA_EMPRESTIMO"
       cTipoSaida = IF lRetorno THEN "SAIDA_RETORNO_TERCEIROS" ELSE "SAIDA_REMESSA_TERCEIROS"
       cPosicaoOrigem = IF lRetorno THEN "TRANSITO" ELSE "TERCEIRO".
cTipoResolucao = cTipoOperacao.
RUN resolverOrigemRecebimento(INPUT prDocumEst, INPUT cTipoResolucao, INPUT 0,
    OUTPUT iDocumentoSaida, OUTPUT iOperacao, OUTPUT cOrigem,
    OUTPUT cSerieSaida, OUTPUT cNumeroSaida, OUTPUT cChaveDocto,
    OUTPUT plAplicavel, OUTPUT lOrigemResolvida, OUTPUT pcErro, OUTPUT pcMensagem).
/* Retorno externo nao possui nota de saida do terceiro na estrutura. */
IF lRetorno AND NOT plAplicavel AND lOrigemResolvida THEN DO:
    RUN resolverOrigemRecebimento(INPUT prDocumEst, INPUT "RETORNO_ARMAZENAGEM", INPUT 0,
        OUTPUT iDocumentoSaida, OUTPUT iOperacao, OUTPUT cOrigem,
        OUTPUT cSerieSaida, OUTPUT cNumeroSaida, OUTPUT cChaveDocto,
        OUTPUT plAplicavel, OUTPUT lOrigemResolvida, OUTPUT pcErro, OUTPUT pcMensagem).
    IF plAplicavel THEN ASSIGN lArmazenagem = YES
        cTipoResolucao = "RETORNO_ARMAZENAGEM" cTipoOperacao = "REMESSA_TERCEIROS"
        cTipoEvento = "RECEBIMENTO_RETORNO_TERCEIROS" cTipoMovimento = "ENTRADA_RETORNO_TERCEIROS"
        cTipoSaida = "SAIDA_REMESSA_TERCEIROS" cPosicaoOrigem = "TERCEIRO".
END.
IF NOT lOrigemResolvida OR NOT plAplicavel THEN DO:
    plSucesso = lOrigemResolvida.
    RETURN.
END.
ASSIGN plAplicavel = YES
       pcErro = "E12_ENTRADA_NAO_CONFIRMADA"
       pcMensagem = "A entrada ainda nao foi atualizada pelo RE1001.".
IF bEntrada.ce-atual = ? OR bEntrada.ce-atual <> YES THEN RETURN.

/* Todas as linhas pertencem a uma mesma nota; cada grupo tem rateio unico.
   A criacao do documento pertence ao ANFe; este servico apenas recebe identidades. */
EMPTY TEMP-TABLE ttE12Grupo.
FOR EACH bLinhaEntrada OF bEntrada NO-LOCK:
    iLinhasEntrada = iLinhasEntrada + 1.
    IF bLinhaEntrada.un = ? OR TRIM(bLinhaEntrada.un) = "" OR
       bLinhaEntrada.quantidade = ? OR bLinhaEntrada.quantidade <= 0 THEN DO:
        ASSIGN pcErro = "E12_ORIGEM_INCOMPLETA" pcMensagem = "Origem parcial ou linha sem unidade/quantidade.".
        RETURN.
    END.
    deQuantidade = 0.
    iRateiosEntrada = 0.
    FOR EACH bRateioEntrada OF bLinhaEntrada NO-LOCK:
        iRateiosEntrada = iRateiosEntrada + 1.
        IF bRateioEntrada.it-codigo <> bLinhaEntrada.it-codigo OR
           bRateioEntrada.quantidade = ? OR bRateioEntrada.quantidade <= 0 OR
           bRateioEntrada.cod-depos = ? OR TRIM(bRateioEntrada.cod-depos) = "" OR
           bRateioEntrada.lote = ? OR TRIM(bRateioEntrada.lote) = "" OR
           bRateioEntrada.dt-vali-lote = ? THEN DO:
            ASSIGN pcErro = "E12_RATEIO_INCOMPLETO" pcMensagem = "Rateio sem dimensoes completas.".
            RETURN.
        END.
        IF CAN-FIND(FIRST ttE12Grupo WHERE
            ttE12Grupo.it-codigo = bLinhaEntrada.it-codigo AND
            ttE12Grupo.lote = bRateioEntrada.lote AND
            ttE12Grupo.validade = bRateioEntrada.dt-vali-lote AND
            ttE12Grupo.un = bLinhaEntrada.un) THEN DO:
            ASSIGN pcErro = "E12_GRUPO_AMBIGUO"
                pcMensagem = "Grupo repetido em linhas ou rateios distintos; nao deduzir etiquetas.".
            RETURN.
        END.
        CREATE ttE12Grupo.
        ASSIGN ttE12Grupo.it-codigo = bLinhaEntrada.it-codigo
            ttE12Grupo.lote = bRateioEntrada.lote
            ttE12Grupo.validade = bRateioEntrada.dt-vali-lote
            ttE12Grupo.un = bLinhaEntrada.un
            ttE12Grupo.r-linha = ROWID(bLinhaEntrada)
            ttE12Grupo.r-rateio = ROWID(bRateioEntrada)
            ttE12Grupo.quantidade = bRateioEntrada.quantidade.
        deQuantidade = deQuantidade + bRateioEntrada.quantidade.
    END.
    IF iRateiosEntrada = 0 OR deQuantidade <> bLinhaEntrada.quantidade THEN DO:
        ASSIGN pcErro = "E12_QUANTIDADE_RATEIO_DIVERGENTE"
            pcMensagem = "Soma dos rateios difere da quantidade da linha.".
        RETURN.
    END.
END.
IF iLinhasEntrada = 0 THEN DO:
    ASSIGN pcErro = "E12_SEM_LINHAS" pcMensagem = "Entrada sem itens.".
    RETURN.
END.

IF lArmazenagem THEN DO:
    FIND FIRST bDestino NO-LOCK WHERE bDestino.cod-estabel = bEntrada.cod-estabel NO-ERROR.
    FOR EACH bNotaSaida NO-LOCK WHERE bNotaSaida.cod-estabel = cOrigem
        AND bNotaSaida.serie = cSerieSaida AND bNotaSaida.nr-nota-fis = cNumeroSaida
        AND bNotaSaida.cod-emitente = bEntrada.cod-emitente:
        ASSIGN iNotas = iNotas + 1 rNotaSaida = ROWID(bNotaSaida).
    END.
END.
ELSE
FOR EACH bOrigem NO-LOCK
    WHERE bOrigem.cod-emitente = bEntrada.cod-emitente:
    /* A nota de saida e ao estabelecimento destinatario da entrada. */
    FIND FIRST bDestino NO-LOCK
        WHERE bDestino.cod-estabel = bEntrada.cod-estabel NO-ERROR.
    IF NOT AVAILABLE bDestino THEN NEXT.
    FOR EACH bNotaSaida NO-LOCK
        WHERE bNotaSaida.cod-estabel = bOrigem.cod-estabel
          AND bNotaSaida.serie = cSerieSaida
          AND bNotaSaida.nr-nota-fis = cNumeroSaida
          AND bNotaSaida.cod-emitente = bDestino.cod-emitente:
        ASSIGN iNotas = iNotas + 1
               cOrigem = bOrigem.cod-estabel
               rNotaSaida = ROWID(bNotaSaida).
    END.
END.
ASSIGN pcErro = "E12_SAIDA_NAO_UNICA"
       pcMensagem = "Nota de saida nao encontrada ou correlacao ambigua.".
IF iNotas <> 1 THEN RETURN.

FOR EACH bDocumentoSaida NO-LOCK
    WHERE bDocumentoSaida.tipo-evento = "DOCUMENTO_SAIDA_FLUIG"
      AND bDocumentoSaida.tipo-docto = "SAIDA"
      AND bDocumentoSaida.cod-estabel = cOrigem
      AND bDocumentoSaida.serie = cSerieSaida
      AND bDocumentoSaida.nro-docto = cNumeroSaida:
    ASSIGN iDocumentos = iDocumentos + 1
           iDocumentoSaida = bDocumentoSaida.id-evento
           iOperacao = bDocumentoSaida.id-operacao.
END.
ASSIGN pcErro = "E12_OPERACAO_NAO_UNICA"
       pcMensagem = "A saida nao possui um unico vinculo especifico.".
IF iDocumentos <> 1 OR iOperacao = ? OR iOperacao <= 0 THEN RETURN.
FIND FIRST bDocumentoSaida NO-LOCK
    WHERE bDocumentoSaida.id-evento = iDocumentoSaida NO-ERROR.
IF NOT AVAILABLE bDocumentoSaida OR
   bDocumentoSaida.situacao <> "CONCLUIDO" THEN DO:
    ASSIGN pcErro = "E12_SAIDA_DOCUMENTAL_PENDENTE"
           pcMensagem = "O vinculo documental da saida nao esta concluido.".
    RETURN.
END.
FIND FIRST bOperacao NO-LOCK
    WHERE bOperacao.id-operacao = iOperacao NO-ERROR.
IF NOT AVAILABLE bOperacao OR
   bOperacao.tipo-operacao <> cTipoOperacao OR
   bOperacao.cod-estabel-orig <> cOrigem OR
   (NOT lRetorno AND bOperacao.cod-estabel-dest <> bEntrada.cod-estabel) THEN DO:
    ASSIGN pcErro = "E12_DESTINO_DIVERGENTE"
           pcMensagem = "Operacao nao corresponde aos estabelecimentos da entrada.".
    RETURN.
END.
FIND FIRST bNotaSaida NO-LOCK
    WHERE ROWID(bNotaSaida) = rNotaSaida NO-ERROR.
IF NOT AVAILABLE bNotaSaida OR
   bNotaSaida.nat-operacao <> bDocumentoSaida.nat-operacao OR
   bOperacao.seq-wt-docto = ? OR bOperacao.seq-wt-docto <= 0 OR
   bNotaSaida.char-2 = ? OR
   TRIM(SUBSTRING(bNotaSaida.char-2, 1500, 20)) <>
       "CEWT1:" + STRING(bOperacao.seq-wt-docto) THEN DO:
    ASSIGN pcErro = "E12_WT_SAIDA_DIVERGENTE"
           pcMensagem = "A nota de saida nao confirma o WT da operacao.".
    RETURN.
END.

FIND FIRST bNaturezaSaida NO-LOCK
    WHERE bNaturezaSaida.nat-operacao = bNotaSaida.nat-operacao NO-ERROR.
IF NOT AVAILABLE bNaturezaSaida THEN DO:
    ASSIGN pcErro = "E12_NATUREZA_SAIDA_AUSENTE" pcMensagem = "Natureza da remessa nao cadastrada.".
    RETURN.
END.
IF bNaturezaSaida.especie-doc = ? OR
   LOOKUP(CAPS(TRIM(bNaturezaSaida.especie-doc)), "NFS,NFT") = 0 OR
   bNaturezaSaida.terceiros = ? OR bNaturezaSaida.terceiros <> YES OR
   bNaturezaSaida.tp-oper-terc = ? OR bNaturezaSaida.tp-oper-terc <> (IF lRetorno AND NOT lArmazenagem THEN 5 ELSE 3) THEN DO:
    ASSIGN pcErro = "E12_NATUREZA_SAIDA_DIVERGENTE" pcMensagem = "Natureza da saida difere do ramo de emprestimo/retorno.".
    RETURN.
END.
ASSIGN cChaveDocto = "ENTRADA|"
        + STRING(LENGTH(bEntrada.cod-estabel)) + ":" + bEntrada.cod-estabel
        + "|" + STRING(bEntrada.cod-emitente)
        + "|" + STRING(LENGTH(bEntrada.serie-docto)) + ":" + bEntrada.serie-docto
        + "|" + STRING(LENGTH(bEntrada.nro-docto)) + ":" + bEntrada.nro-docto
        + "|" + bEntrada.nat-operacao
       cChaveEvento = "RE1005RP|" + cTipoMovimento + "|" + cChaveDocto
       cUsuario = IF bEntrada.usuario = ? THEN "" ELSE TRIM(bEntrada.usuario, " ").
IF cUsuario = "" THEN cUsuario = USERID("mgcad").
IF cUsuario = ? OR cUsuario = "" THEN DO:
    ASSIGN pcErro = "E12_USUARIO_AUSENTE"
           pcMensagem = "Usuario da entrada nao identificado.".
    RETURN.
END.

FOR EACH bSaida NO-LOCK
    WHERE bSaida.id-operacao = iOperacao
      AND bSaida.id-evento-origem = iDocumentoSaida
      AND bSaida.tipo-evento = "SAIDA_ESTOQUE":
    IF bSaida.situacao <> "CONCLUIDO" THEN DO:
        ASSIGN pcErro = "E12_SAIDA_PENDENTE"
               pcMensagem = "A saida individual ainda nao esta concluida.".
        RETURN.
    END.
    IF NOT CAN-FIND(FIRST bReversao NO-LOCK
        WHERE bReversao.tipo-evento = "DESATUALIZACAO_SAIDA"
          AND bReversao.id-evento-origem = bSaida.id-evento) THEN
        ASSIGN iSaidasAtivas = iSaidasAtivas + 1
               iSaidaAtiva = bSaida.id-evento.
END.
ASSIGN pcErro = "E12_SAIDA_ATIVA_NAO_UNICA"
       pcMensagem = "E necessario exatamente um ciclo de saida ativo.".
IF iSaidasAtivas <> 1 THEN RETURN.

RUN validarRecebimentosOrigem(INPUT iDocumentoSaida, INPUT iSaidaAtiva,
    INPUT cChaveDocto, OUTPUT lNucleo, OUTPUT pcErro, OUTPUT pcMensagem).
IF NOT lNucleo THEN RETURN.

/* Cada reatualizacao da mesma entrada forma novo ciclo historico. */
FOR EACH bEntradaAnterior NO-LOCK
    WHERE bEntradaAnterior.tipo-evento = cTipoEvento
      AND bEntradaAnterior.chave-docto = cChaveDocto:
    IF bEntradaAnterior.id-operacao <> iOperacao OR
       bEntradaAnterior.id-evento-origem <> iSaidaAtiva OR
       bEntradaAnterior.situacao <> "CONCLUIDO" OR
       bEntradaAnterior.seq-ciclo = ? OR
       bEntradaAnterior.seq-ciclo <= 0 OR
       bEntradaAnterior.seq-ciclo MODULO 2 = 0 THEN DO:
        ASSIGN pcErro = "E12_HISTORICO_ENTRADA_INVALIDO"
               pcMensagem = "Ciclo anterior da entrada inconsistente.".
        RETURN.
    END.
    ASSIGN iEntradasAnteriores = iEntradasAnteriores + 1
           iCicloUltimo = MAXIMUM(iCicloUltimo, bEntradaAnterior.seq-ciclo)
           iReversoesEntrada = 0.
    FOR EACH bReversaoEntrada NO-LOCK
        WHERE bReversaoEntrada.id-evento-origem = bEntradaAnterior.id-evento
          AND bReversaoEntrada.tipo-evento = "DESATUALIZACAO_ENTRADA":
        ASSIGN iReversoesEntrada = iReversoesEntrada + 1.
        IF bReversaoEntrada.id-operacao <> iOperacao OR
           bReversaoEntrada.situacao <> "CONCLUIDO" OR
           bReversaoEntrada.seq-ciclo <> bEntradaAnterior.seq-ciclo + 1 THEN DO:
            ASSIGN pcErro = "E12_HISTORICO_REVERSAO_INVALIDO"
                   pcMensagem = "Reversao anterior da entrada inconsistente.".
            RETURN.
        END.
        IF bReversaoEntrada.seq-ciclo > iCicloUltimo THEN
            ASSIGN iCicloUltimo = bReversaoEntrada.seq-ciclo
                   iUltimaReversao = bReversaoEntrada.id-evento.
    END.
    IF iReversoesEntrada > 1 THEN DO:
        ASSIGN pcErro = "E12_REVERSAO_AMBIGUA"
               pcMensagem = "Mais de uma reversao para a mesma entrada.".
        RETURN.
    END.
    IF iReversoesEntrada = 0 THEN
        ASSIGN iEntradasAtivas = iEntradasAtivas + 1
               piIdEvento = bEntradaAnterior.id-evento
               iCicloEntradaAtiva = bEntradaAnterior.seq-ciclo.
END.
IF iEntradasAtivas > 1 OR
   (iEntradasAtivas = 1 AND iCicloEntradaAtiva <> iCicloUltimo) OR
   iCicloUltimo <> iEntradasAnteriores * 2 - iEntradasAtivas THEN DO:
    ASSIGN pcErro = "E12_CICLOS_AMBIGUOS"
           pcMensagem = "Historico da entrada inconsistente.".
    RETURN.
END.
IF iEntradasAtivas = 1 THEN DO:
    repeticaoTransacao:
    DO TRANSACTION ON ERROR UNDO, THROW:
        FIND FIRST bOperacaoLock WHERE bOperacaoLock.id-operacao = iOperacao
            EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF LOCKED bOperacaoLock OR NOT AVAILABLE bOperacaoLock THEN DO:
            ASSIGN pcErro = "REC_OPERACAO_BLOQUEADA" pcMensagem = "Operacao em uso; tentar novamente.".
            UNDO repeticaoTransacao, LEAVE repeticaoTransacao.
        END.
        RUN validarRecebimentosOrigem(INPUT iDocumentoSaida, INPUT iSaidaAtiva,
            INPUT cChaveDocto, OUTPUT lNucleo, OUTPUT pcErro, OUTPUT pcMensagem).
        IF NOT lNucleo THEN UNDO repeticaoTransacao, LEAVE repeticaoTransacao.
        RUN registrarVinculoRecebimento(INPUT prDocumEst, INPUT iDocumentoSaida,
            INPUT phRastreio, OUTPUT lNucleo, OUTPUT iVinculo, OUTPUT pcErro, OUTPUT pcMensagem).
        IF NOT lNucleo THEN UNDO repeticaoTransacao, LEAVE repeticaoTransacao.
        ASSIGN plSucesso = YES plRepeticao = YES pcErro = "" pcMensagem = "".
    END.
    RETURN.
END.
ASSIGN piIdEvento = 0
       iCicloNovo = iCicloUltimo + 1.
IF iCicloNovo > 1 THEN
    cChaveEvento = cChaveEvento + "|CICLO=" + STRING(iCicloNovo).
ASSIGN cConteudo = cChaveEvento + "|SAIDA=" + STRING(iSaidaAtiva).

FOR EACH bSelecao NO-LOCK
    WHERE bSelecao.id-operacao = iOperacao
      AND bSelecao.tipo-item = "SOLICITACAO":
    FIND FIRST bEtiqueta NO-LOCK
        WHERE bEtiqueta.id-etiqueta = bSelecao.id-etiqueta NO-ERROR.
    IF NOT AVAILABLE bEtiqueta THEN DO:
        ASSIGN pcErro = "E12_ETIQUETA_AUSENTE"
               pcMensagem = "Etiqueta selecionada na origem nao encontrada.".
        RETURN.
    END.
    FIND FIRST ttE12Grupo WHERE
        ttE12Grupo.it-codigo = bEtiqueta.it-codigo AND
        ttE12Grupo.lote = bEtiqueta.lote AND
        ttE12Grupo.validade = bEtiqueta.dt-vali-lote AND
        ttE12Grupo.un = bEtiqueta.un NO-ERROR.
    IF NOT AVAILABLE ttE12Grupo THEN DO:
        ASSIGN pcErro = "E12_ETIQUETA_SEM_RATEIO" pcMensagem = "Etiqueta nao pertence aos grupos da entrada.".
        RETURN.
    END.
    FIND FIRST bLinhaEntrada NO-LOCK WHERE ROWID(bLinhaEntrada) = ttE12Grupo.r-linha NO-ERROR.
    FIND FIRST bRateioEntrada NO-LOCK WHERE ROWID(bRateioEntrada) = ttE12Grupo.r-rateio NO-ERROR.
    IF NOT AVAILABLE bLinhaEntrada OR NOT AVAILABLE bRateioEntrada THEN DO:
        ASSIGN pcErro = "E12_RATEIO_ALTERADO" pcMensagem = "Linha ou rateio nao encontrado.".
        RETURN.
    END.
    FIND FIRST bMovtoSaida NO-LOCK
        WHERE bMovtoSaida.id-evento = iSaidaAtiva
          AND bMovtoSaida.id-etiqueta = bEtiqueta.id-etiqueta NO-ERROR.
    FIND FIRST bMovtoUltimo NO-LOCK
        WHERE bMovtoUltimo.id-movto = bEtiqueta.id-movto-ult NO-ERROR.
    IF NOT AVAILABLE bMovtoSaida THEN DO:
        ASSIGN pcErro = "E12_MOVIMENTO_SAIDA_AUSENTE"
               pcMensagem = "Etiqueta sem movimento da saida ativa.".
        RETURN.
    END.
    RUN validarContinuidadeRecebimento(INPUT bMovtoSaida.id-movto,
        INPUT bEtiqueta.id-etiqueta, INPUT cTipoMovimento,
        OUTPUT lContinuidade, OUTPUT pcErro, OUTPUT pcMensagem).
    IF NOT lContinuidade THEN RETURN.
    IF NOT AVAILABLE bMovtoSaida OR
       bMovtoSaida.id-etiqueta <> bEtiqueta.id-etiqueta OR
       bMovtoSaida.tipo-movto <> cTipoSaida OR
       NOT AVAILABLE bMovtoUltimo OR
       bEtiqueta.tipo-controle <> "EMBALAGEM" OR
       bEtiqueta.situacao <> "ATIVA" OR
       bEtiqueta.tipo-local <> cPosicaoOrigem OR
       bEtiqueta.cod-emitente-posse <> bOperacao.cod-emitente OR
       bEtiqueta.cod-estabel <> cOrigem OR
       bEtiqueta.id-bag <> ? OR
       bEtiqueta.it-codigo <> bLinhaEntrada.it-codigo OR
       bEtiqueta.lote <> bRateioEntrada.lote OR
       bEtiqueta.dt-vali-lote <> bRateioEntrada.dt-vali-lote OR
       bEtiqueta.un <> bLinhaEntrada.un OR
       bEtiqueta.qtidade-atu <> bSelecao.quantidade THEN DO:
        ASSIGN pcErro = "E12_ETIQUETA_DIVERGENTE"
               pcMensagem = "Etiqueta da saida possui estado posterior ou dimensoes divergentes.".
        RETURN.
    END.
    ASSIGN piQtdEtiquetas = piQtdEtiquetas + 1
           ttE12Grupo.selecionada = ttE12Grupo.selecionada + bSelecao.quantidade.
END.
IF piQtdEtiquetas = 0 THEN DO:
    ASSIGN pcErro = "E12_SELECAO_VAZIA" pcMensagem = "Remessa sem etiquetas.".
    RETURN.
END.
FOR EACH ttE12Grupo:
    IF ttE12Grupo.selecionada <> ttE12Grupo.quantidade THEN DO:
        ASSIGN pcErro = "E12_QUANTIDADE_DIVERGENTE"
            pcMensagem = "Quantidade do grupo de entrada difere das etiquetas da remessa.".
        RETURN.
    END.
    cConteudo = cConteudo + "|GRUPO=" + STRING(ttE12Grupo.r-linha)
        + "/" + STRING(ttE12Grupo.r-rateio) + "/" + STRING(ttE12Grupo.quantidade).
END.
ASSIGN dtAgora = NOW.
CREATE ttEmbEventoComando.
ASSIGN ttEmbEventoComando.origem = "RE1005RP"
       ttEmbEventoComando.chave-evento = cChaveEvento
       ttEmbEventoComando.hash-chave = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cChaveEvento))
       ttEmbEventoComando.hash-conteudo = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cConteudo))
       ttEmbEventoComando.tipo-evento = cTipoEvento
       ttEmbEventoComando.id-operacao = iOperacao
       ttEmbEventoComando.id-evento-origem = iSaidaAtiva
       ttEmbEventoComando.seq-ciclo = iCicloNovo
       ttEmbEventoComando.dt-evento = dtAgora
       ttEmbEventoComando.versao-contrato = 1
       ttEmbEventoComando.tipo-docto = "ENTRADA"
       ttEmbEventoComando.chave-docto = cChaveDocto
       ttEmbEventoComando.hash-docto = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cChaveDocto))
       ttEmbEventoComando.cod-estabel = bEntrada.cod-estabel
       ttEmbEventoComando.cod-emitente = bEntrada.cod-emitente
       ttEmbEventoComando.serie = bEntrada.serie-docto
       ttEmbEventoComando.nro-docto = bEntrada.nro-docto
       ttEmbEventoComando.nat-operacao = bEntrada.nat-operacao
       ttEmbEventoComando.dt-emissao = bEntrada.dt-emissao
       ttEmbEventoComando.dados-evento = "RE1005RP fim-atualizacao; saida=" +
                                         cOrigem + "/" + cSerieSaida + "/" + cNumeroSaida +
                                         "; vinculo-documental=" + STRING(iDocumentoSaida)
       ttEmbEventoComando.usuario = cUsuario.

entradaTransacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    FIND FIRST bOperacaoLock WHERE bOperacaoLock.id-operacao = iOperacao
        EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
    IF LOCKED bOperacaoLock OR NOT AVAILABLE bOperacaoLock THEN DO:
        ASSIGN pcErro = "REC_OPERACAO_BLOQUEADA" pcMensagem = "Operacao em uso; tentar novamente.".
        UNDO entradaTransacao, LEAVE entradaTransacao.
    END.
    RUN resolverOrigemRecebimento(INPUT prDocumEst, INPUT cTipoResolucao, INPUT iDocumentoSaida,
        OUTPUT iDocumentoSaida, OUTPUT iOperacao, OUTPUT cOrigem,
        OUTPUT cSerieSaida, OUTPUT cNumeroSaida, OUTPUT cChaveDocto,
        OUTPUT plAplicavel, OUTPUT lOrigemResolvida, OUTPUT pcErro, OUTPUT pcMensagem).
    IF NOT lOrigemResolvida OR NOT plAplicavel OR
       cChaveDocto <> ttEmbEventoComando.chave-docto OR
       iOperacao <> bOperacaoLock.id-operacao THEN DO:
        IF lOrigemResolvida THEN ASSIGN pcErro = "REC_DOCUMENTO_ALTERADO"
            pcMensagem = "Documento mudou durante a validacao.".
        UNDO entradaTransacao, LEAVE entradaTransacao.
    END.
    RUN validarRecebimentosOrigem(INPUT iDocumentoSaida, INPUT iSaidaAtiva,
        INPUT cChaveDocto, OUTPUT lNucleo, OUTPUT pcErro, OUTPUT pcMensagem).
    IF NOT lNucleo THEN UNDO entradaTransacao, LEAVE entradaTransacao.
    RUN registrarVinculoRecebimento(INPUT prDocumEst, INPUT iDocumentoSaida,
        INPUT phRastreio, OUTPUT lNucleo, OUTPUT iVinculo, OUTPUT pcErro, OUTPUT pcMensagem).
    IF NOT lNucleo THEN UNDO entradaTransacao, LEAVE entradaTransacao.
    RUN registrarEvento IN phRastreio(INPUT TABLE ttEmbEventoComando, INPUT YES,
        OUTPUT lNucleo, OUTPUT lRepNucleo, OUTPUT piIdEvento,
        OUTPUT cSituacao, OUTPUT iVersaoEvento, OUTPUT cErroNucleo, OUTPUT cMsgNucleo).
    IF NOT lNucleo OR lRepNucleo THEN DO:
        ASSIGN pcErro = IF NOT lNucleo THEN cErroNucleo ELSE "E12_CONCORRENCIA"
               pcMensagem = IF NOT lNucleo THEN cMsgNucleo ELSE "Repeticao concorrente; reexecute a consulta."
               piIdEvento = 0.
        UNDO entradaTransacao, LEAVE entradaTransacao.
    END.
    ASSIGN iSeq = 0.
    FOR EACH bSelecao NO-LOCK
        WHERE bSelecao.id-operacao = iOperacao
          AND bSelecao.tipo-item = "SOLICITACAO"
        BY bSelecao.id-etiqueta:
        FIND FIRST bEtiqueta NO-LOCK
            WHERE bEtiqueta.id-etiqueta = bSelecao.id-etiqueta NO-ERROR.
        IF NOT AVAILABLE bEtiqueta THEN DO:
            ASSIGN pcErro = "E12_ETIQUETA_AUSENTE"
                   pcMensagem = "Etiqueta indisponivel durante a entrada.".
            UNDO entradaTransacao, LEAVE entradaTransacao.
        END.
    FIND FIRST ttE12Grupo WHERE
        ttE12Grupo.it-codigo = bEtiqueta.it-codigo AND
        ttE12Grupo.lote = bEtiqueta.lote AND
        ttE12Grupo.validade = bEtiqueta.dt-vali-lote AND
        ttE12Grupo.un = bEtiqueta.un NO-ERROR.
    IF NOT AVAILABLE ttE12Grupo THEN DO:
        ASSIGN pcErro = "E12_ETIQUETA_SEM_RATEIO" pcMensagem = "Etiqueta nao pertence aos grupos da entrada.".
        UNDO entradaTransacao, LEAVE entradaTransacao.
    END.
    FIND FIRST bLinhaEntrada NO-LOCK WHERE ROWID(bLinhaEntrada) = ttE12Grupo.r-linha NO-ERROR.
    FIND FIRST bRateioEntrada NO-LOCK WHERE ROWID(bRateioEntrada) = ttE12Grupo.r-rateio NO-ERROR.
    IF NOT AVAILABLE bLinhaEntrada OR NOT AVAILABLE bRateioEntrada THEN DO:
        ASSIGN pcErro = "E12_RATEIO_ALTERADO" pcMensagem = "Linha ou rateio nao encontrado.".
        UNDO entradaTransacao, LEAVE entradaTransacao.
    END.
        FIND FIRST bMovtoSaida NO-LOCK
            WHERE bMovtoSaida.id-evento = iSaidaAtiva
              AND bMovtoSaida.id-etiqueta = bEtiqueta.id-etiqueta NO-ERROR.
        FIND FIRST bMovtoUltimo NO-LOCK
            WHERE bMovtoUltimo.id-movto = bEtiqueta.id-movto-ult NO-ERROR.
        IF NOT AVAILABLE bMovtoSaida THEN DO:
            ASSIGN pcErro = "E12_MOVIMENTO_SAIDA_AUSENTE"
                   pcMensagem = "Etiqueta sem movimento da saida ativa.".
            UNDO entradaTransacao, LEAVE entradaTransacao.
        END.
        RUN validarContinuidadeRecebimento(INPUT bMovtoSaida.id-movto,
            INPUT bEtiqueta.id-etiqueta, INPUT cTipoMovimento,
            OUTPUT lContinuidade, OUTPUT pcErro, OUTPUT pcMensagem).
        IF NOT lContinuidade THEN UNDO entradaTransacao, LEAVE entradaTransacao.
        IF NOT AVAILABLE bMovtoSaida OR
           NOT AVAILABLE bMovtoUltimo OR
           bMovtoSaida.tipo-movto <> cTipoSaida OR
           bMovtoSaida.quantidade <> bSelecao.quantidade OR
           bEtiqueta.tipo-controle <> "EMBALAGEM" OR bEtiqueta.situacao <> "ATIVA" OR
           bEtiqueta.tipo-local <> cPosicaoOrigem OR bEtiqueta.id-bag <> ? OR
           bEtiqueta.cod-estabel <> cOrigem OR
           bEtiqueta.cod-emitente-posse <> bOperacaoLock.cod-emitente OR
           bEtiqueta.it-codigo <> bLinhaEntrada.it-codigo OR
           bEtiqueta.lote <> bRateioEntrada.lote OR
           bEtiqueta.dt-vali-lote <> bRateioEntrada.dt-vali-lote OR
           bEtiqueta.un <> bLinhaEntrada.un OR
           bEtiqueta.qtidade-atu <> bSelecao.quantidade OR
           bRateioEntrada.quantidade <> ttE12Grupo.quantidade OR
           bRateioEntrada.cod-depos = ? OR TRIM(bRateioEntrada.cod-depos) = "" THEN DO:
            ASSIGN pcErro = "E12_ESTADO_ALTERADO"
                   pcMensagem = "Etiqueta deixou a custodia de terceiro antes do recebimento.".
            UNDO entradaTransacao, LEAVE entradaTransacao.
        END.
        ASSIGN iSeq = iSeq + 1.
        EMPTY TEMP-TABLE ttEmbMovimentoComando.
        CREATE ttEmbMovimentoComando.
        ASSIGN ttEmbMovimentoComando.id-evento = piIdEvento
               ttEmbMovimentoComando.sequencia = iSeq
               ttEmbMovimentoComando.id-etiqueta = bEtiqueta.id-etiqueta
               ttEmbMovimentoComando.id-item-oper = bSelecao.id-item-oper
               ttEmbMovimentoComando.versao-etiqueta-esperada = bEtiqueta.versao
               ttEmbMovimentoComando.id-movto-ant-esperado = bEtiqueta.id-movto-ult
               ttEmbMovimentoComando.id-movto-origem = bMovtoSaida.id-movto
               ttEmbMovimentoComando.tipo-movto = cTipoMovimento
               ttEmbMovimentoComando.dt-movto = dtAgora
               ttEmbMovimentoComando.un = bEtiqueta.un
               ttEmbMovimentoComando.quantidade = bSelecao.quantidade
               ttEmbMovimentoComando.qtidade-atu = bEtiqueta.qtidade-atu
               ttEmbMovimentoComando.situacao-atu = bEtiqueta.situacao
               ttEmbMovimentoComando.cod-estabel-dest = bEntrada.cod-estabel
               ttEmbMovimentoComando.cod-depos-dest = bRateioEntrada.cod-depos
               ttEmbMovimentoComando.cod-localiz-dest = bRateioEntrada.cod-localiz
               ttEmbMovimentoComando.cod-emitente-dest = bDestino.cod-emitente
               ttEmbMovimentoComando.tipo-local-dest = "ESTAB"
               ttEmbMovimentoComando.origem-movto-erp = "RE1005RP"
               ttEmbMovimentoComando.chave-movto-erp = cChaveDocto
               ttEmbMovimentoComando.justificativa = (IF lArmazenagem THEN "Retorno confirmado de terceiro " ELSE IF lRetorno THEN "Retorno confirmado do emprestimo " ELSE "Entrada confirmada do emprestimo ") +
                                                    cSerieSaida + "/" + cNumeroSaida
               ttEmbMovimentoComando.usuario = cUsuario.
        RUN aplicarMovimento IN phRastreio(INPUT TABLE ttEmbMovimentoComando, INPUT YES,
            OUTPUT lNucleo, OUTPUT lRepNucleo, OUTPUT iMovto, OUTPUT iVersao,
            OUTPUT cErroNucleo, OUTPUT cMsgNucleo).
        IF NOT lNucleo OR lRepNucleo THEN DO:
            ASSIGN pcErro = IF NOT lNucleo THEN cErroNucleo ELSE "E12_MOVIMENTO_REPETIDO"
                   pcMensagem = IF NOT lNucleo THEN cMsgNucleo ELSE "Movimento ja existente na nova entrada.".
            UNDO entradaTransacao, LEAVE entradaTransacao.
        END.
    END.
    FIND FIRST bNovoEvento EXCLUSIVE-LOCK
        WHERE bNovoEvento.id-evento = piIdEvento NO-ERROR.
    IF NOT AVAILABLE bNovoEvento OR iSeq <> piQtdEtiquetas THEN DO:
        ASSIGN pcErro = "E12_EVENTO_INCOMPLETO"
               pcMensagem = "Evento ou quantidade de movimentos incompleta.".
        UNDO entradaTransacao, LEAVE entradaTransacao.
    END.
    ASSIGN bNovoEvento.situacao = "CONCLUIDO"
           bNovoEvento.dt-conclusao = NOW
           bNovoEvento.resultado = "etiquetas=" + STRING(iSeq)
           bNovoEvento.dt-alteracao = NOW
           bNovoEvento.versao = bNovoEvento.versao + 1
           plSucesso = YES pcErro = "" pcMensagem = "".
END.
END PROCEDURE.

PROCEDURE reverterEntradaEmprestimo:
/* RE0402RP: compensa a chegada confirmada, mantendo evento e movimentos.
   O estoque consolidado e a desatualizacao fiscal pertencem ao Datasul. */
DEFINE INPUT PARAMETER prDocumEst AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER phRastreio AS HANDLE NO-UNDO.
DEFINE OUTPUT PARAMETER plAplicavel AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piIdEvento AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piQtdEtiquetas AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.

DEFINE BUFFER bNatureza FOR mgcad.natur-oper.
DEFINE BUFFER bDoc FOR mgmov.docum-est.
DEFINE BUFFER bReceb FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRecebAtivo FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRev FOR mgesp.contr_emb_evento.
DEFINE BUFFER bOrigem FOR mgesp.contr_emb_evento.
DEFINE BUFFER bOper FOR mgesp.contr_emb_oper.
DEFINE BUFFER bOperacaoLock FOR mgesp.contr_emb_oper.
DEFINE BUFFER bSelecao FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bMovtoEntrada FOR mgesp.contr_emb_movto.
DEFINE BUFFER bEtiqueta FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bNovoEvento FOR mgesp.contr_emb_evento.
DEFINE VARIABLE cTipoOperacao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipoEvento AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipoMovimento AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipoSaida AS CHARACTER NO-UNDO.
DEFINE VARIABLE cPosicaoOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE lRetorno AS LOGICAL NO-UNDO.
DEFINE VARIABLE lArmazenagem AS LOGICAL NO-UNDO.
DEFINE VARIABLE cTipoResolucao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChaveDoc AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChaveRev AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConteudo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSituacao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErroNucleo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMsgNucleo AS CHARACTER NO-UNDO.
DEFINE VARIABLE iOperacao AS INTEGER NO-UNDO.
DEFINE VARIABLE iRecebimentos AS INTEGER NO-UNDO.
DEFINE VARIABLE iRecebimentosAtivos AS INTEGER NO-UNDO.
DEFINE VARIABLE iRecebimentoAtivo AS INTEGER NO-UNDO.
DEFINE VARIABLE iCicloAtivo AS INTEGER NO-UNDO.
DEFINE VARIABLE iCicloUltimo AS INTEGER NO-UNDO.
DEFINE VARIABLE iReversoes AS INTEGER NO-UNDO.
DEFINE VARIABLE iUltimaReversao AS INTEGER NO-UNDO.
DEFINE VARIABLE iMovimentos AS INTEGER NO-UNDO.
DEFINE VARIABLE iSelecionadas AS INTEGER NO-UNDO.
DEFINE VARIABLE iSeq AS INTEGER NO-UNDO.
DEFINE VARIABLE iMovto AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersao AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersaoEvento AS INTEGER NO-UNDO.
DEFINE VARIABLE lNucleo AS LOGICAL NO-UNDO.
DEFINE VARIABLE lRepNucleo AS LOGICAL NO-UNDO.
DEFINE VARIABLE lControlada AS LOGICAL NO-UNDO.
DEFINE VARIABLE dtAgora AS DATETIME-TZ NO-UNDO.

EMPTY TEMP-TABLE ttEmbEventoComando.
EMPTY TEMP-TABLE ttEmbMovimentoComando.
ASSIGN plAplicavel = NO plSucesso = NO plRepeticao = NO
       piIdEvento = 0 piQtdEtiquetas = 0
       pcErro = "E12_REVERSAO_INVALIDA"
       pcMensagem = "Documento ou nucleo de rastreio invalido.".
IF prDocumEst = ? OR NOT VALID-HANDLE(phRastreio) THEN RETURN.
RUN registrarE12Diagnostico ("SERVICO_ENTRADA").
IF NOT CONNECTED("mgmov") OR NOT CONNECTED("mgesp") OR NOT CONNECTED("mgcad") THEN DO:
    ASSIGN pcErro = "E12_BANCO_NAO_CONECTADO"
           pcMensagem = "Bancos necessarios nao conectados.".
    RETURN.
END.
FIND FIRST bDoc NO-LOCK WHERE ROWID(bDoc) = prDocumEst NO-ERROR.
IF NOT AVAILABLE bDoc THEN DO:
    ASSIGN pcErro = "E12_DOCUMENTO_AUSENTE"
           pcMensagem = "Documento da desatualizacao nao encontrado.".
    RETURN.
END.
FIND FIRST bNatureza NO-LOCK
    WHERE bNatureza.nat-operacao = bDoc.nat-operacao NO-ERROR.
IF NOT AVAILABLE bNatureza THEN DO:
    ASSIGN pcErro = "E12_NATUREZA_AUSENTE" pcMensagem = "Natureza da entrada nao cadastrada.".
    RETURN.
END.
IF bNatureza.especie-doc = ? OR CAPS(TRIM(bNatureza.especie-doc)) <> "NFE" OR
   bNatureza.terceiros = ? OR bNatureza.terceiros <> YES OR
   bNatureza.tp-oper-terc = ? OR LOOKUP(STRING(bNatureza.tp-oper-terc), "3,5") = 0 THEN DO:
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "Natureza fora da entrada de emprestimo.".
    RETURN.
END.
ASSIGN lRetorno = bNatureza.tp-oper-terc = 5
       cTipoOperacao = IF lRetorno THEN "RETORNO_TERCEIROS" ELSE "REMESSA_TERCEIROS"
       cTipoEvento = IF lRetorno THEN "RECEBIMENTO_RETORNO_EMPRESTIMO" ELSE "RECEBIMENTO_EMPRESTIMO"
       cTipoMovimento = IF lRetorno THEN "ENTRADA_RETORNO_EMPRESTIMO" ELSE "ENTRADA_EMPRESTIMO"
       cTipoSaida = IF lRetorno THEN "SAIDA_RETORNO_TERCEIROS" ELSE "SAIDA_REMESSA_TERCEIROS"
       cPosicaoOrigem = IF lRetorno THEN "TRANSITO" ELSE "TERCEIRO".
IF lRetorno AND CAN-FIND(FIRST bReceb WHERE
    bReceb.tipo-evento = "RECEBIMENTO_RETORNO_TERCEIROS"
    AND bReceb.cod-estabel = bDoc.cod-estabel AND bReceb.cod-emitente = bDoc.cod-emitente
    AND bReceb.serie = bDoc.serie-docto AND bReceb.nro-docto = bDoc.nro-docto
    AND bReceb.nat-operacao = bDoc.nat-operacao) THEN ASSIGN lArmazenagem = YES
    cTipoOperacao = "REMESSA_TERCEIROS" cTipoEvento = "RECEBIMENTO_RETORNO_TERCEIROS"
    cTipoMovimento = "ENTRADA_RETORNO_TERCEIROS" cTipoSaida = "SAIDA_REMESSA_TERCEIROS"
    cPosicaoOrigem = "TERCEIRO".
ASSIGN plAplicavel = YES
       pcErro = "E12_DOCUMENTO_AINDA_ATUALIZADO"
       pcMensagem = "A desatualizacao da entrada nao foi confirmada.".
IF bDoc.ce-atual = ? OR bDoc.ce-atual <> NO THEN RETURN.
RUN registrarE12Diagnostico ("SERVICO_CE_ATUAL_NO").

ASSIGN cChaveDoc = "ENTRADA|"
       + STRING(LENGTH(bDoc.cod-estabel)) + ":" + bDoc.cod-estabel
       + "|" + STRING(bDoc.cod-emitente)
       + "|" + STRING(LENGTH(bDoc.serie-docto)) + ":" + bDoc.serie-docto
       + "|" + STRING(LENGTH(bDoc.nro-docto)) + ":" + bDoc.nro-docto
       + "|" + bDoc.nat-operacao.
RUN registrarE12Diagnostico ("SERVICO_ANTES_HISTORICO").
FOR EACH bReceb NO-LOCK
    WHERE bReceb.tipo-evento = cTipoEvento
      AND bReceb.chave-docto = cChaveDoc:
    IF bReceb.situacao <> "CONCLUIDO" OR
       bReceb.id-operacao = ? OR bReceb.id-operacao <= 0 OR
       bReceb.seq-ciclo = ? OR bReceb.seq-ciclo <= 0 OR
       bReceb.seq-ciclo MODULO 2 = 0 OR
       (iOperacao > 0 AND bReceb.id-operacao <> iOperacao) THEN DO:
        ASSIGN pcErro = "E12_HISTORICO_ENTRADA_INVALIDO"
               pcMensagem = "Ciclo de recebimento anterior inconsistente.".
        RETURN.
    END.
    ASSIGN iOperacao = bReceb.id-operacao
           iRecebimentos = iRecebimentos + 1
           iCicloUltimo = MAXIMUM(iCicloUltimo, bReceb.seq-ciclo)
           iReversoes = 0.
    FOR EACH bRev NO-LOCK
        WHERE bRev.id-evento-origem = bReceb.id-evento
          AND bRev.tipo-evento = "DESATUALIZACAO_ENTRADA":
        ASSIGN iReversoes = iReversoes + 1.
        IF bRev.situacao <> "CONCLUIDO" OR
           bRev.id-operacao <> iOperacao OR
           bRev.seq-ciclo <> bReceb.seq-ciclo + 1 THEN DO:
            ASSIGN pcErro = "E12_HISTORICO_REVERSAO_INVALIDO"
                   pcMensagem = "Ciclo de desatualizacao anterior inconsistente.".
            RETURN.
        END.
        IF bRev.seq-ciclo > iCicloUltimo THEN
            ASSIGN iCicloUltimo = bRev.seq-ciclo
                   iUltimaReversao = bRev.id-evento.
    END.
    IF iReversoes > 1 THEN DO:
        ASSIGN pcErro = "E12_REVERSAO_AMBIGUA"
               pcMensagem = "Mais de uma reversao para o mesmo recebimento.".
        RETURN.
    END.
    IF iReversoes = 0 THEN
        ASSIGN iRecebimentosAtivos = iRecebimentosAtivos + 1
               iRecebimentoAtivo = bReceb.id-evento
               iCicloAtivo = bReceb.seq-ciclo.
END.
RUN registrarE12Diagnostico ("SERVICO_DEPOIS_HISTORICO").
IF iRecebimentos = 0 THEN DO:
    ASSIGN plAplicavel = NO plSucesso = YES pcErro = ""
           pcMensagem = "Entrada sem chegada individual a compensar.".
    RETURN.
END.
IF iRecebimentosAtivos > 1 OR
   (iRecebimentosAtivos = 1 AND iCicloAtivo <> iCicloUltimo) OR
   iCicloUltimo <> iRecebimentos * 2 - iRecebimentosAtivos THEN DO:
    ASSIGN pcErro = "E12_CICLOS_AMBIGUOS"
           pcMensagem = "Historico da entrada inconsistente.".
    RETURN.
END.
IF iRecebimentosAtivos = 0 THEN DO:
    ASSIGN plSucesso = YES plRepeticao = YES piIdEvento = iUltimaReversao
           pcErro = "" pcMensagem = "".
    RETURN.
END.
FIND FIRST bRecebAtivo NO-LOCK
    WHERE bRecebAtivo.id-evento = iRecebimentoAtivo NO-ERROR.
IF NOT AVAILABLE bRecebAtivo OR
   bRecebAtivo.cod-estabel <> bDoc.cod-estabel OR
   bRecebAtivo.cod-emitente <> bDoc.cod-emitente OR
   bRecebAtivo.serie <> bDoc.serie-docto OR
   bRecebAtivo.nro-docto <> bDoc.nro-docto OR
   bRecebAtivo.nat-operacao <> bDoc.nat-operacao THEN DO:
    ASSIGN pcErro = "E12_DOCUMENTO_DIVERGENTE"
           pcMensagem = "Evento de chegada difere do documento desatualizado.".
    RETURN.
END.
FIND FIRST bOrigem NO-LOCK
    WHERE bOrigem.id-evento = bRecebAtivo.id-evento-origem NO-ERROR.
FIND FIRST bOper NO-LOCK
    WHERE bOper.id-operacao = iOperacao NO-ERROR.
RUN registrarE12Diagnostico ("SERVICO_DEPOIS_ORIGEM_OPERACAO").
IF NOT AVAILABLE bOrigem OR NOT AVAILABLE bOper OR
   bOrigem.tipo-evento <> "SAIDA_ESTOQUE" OR
   bOrigem.situacao <> "CONCLUIDO" OR
   bOrigem.id-operacao <> iOperacao OR
   bOper.tipo-operacao <> cTipoOperacao OR
   (NOT lRetorno AND bOper.cod-estabel-dest <> bDoc.cod-estabel) THEN DO:
    ASSIGN pcErro = "E12_ORIGEM_INVALIDA"
           pcMensagem = "Saida e operacao da chegada nao conferem.".
    RETURN.
END.
IF lRetorno AND NOT lArmazenagem THEN DO:
    RUN validarDocumentoRetorno(INPUT prDocumEst, INPUT bOrigem.id-evento-origem,
        INPUT YES, OUTPUT lNucleo, OUTPUT pcErro, OUTPUT pcMensagem).
    IF NOT lNucleo THEN RETURN.
END.
IF lArmazenagem THEN DO:
    RUN validarOrigemArmazenagem(INPUT prDocumEst, INPUT bOrigem.id-evento-origem,
        OUTPUT lNucleo, OUTPUT pcErro, OUTPUT pcMensagem).
    IF NOT lNucleo THEN RETURN.
END.
FOR EACH bSelecao NO-LOCK
    WHERE bSelecao.id-operacao = iOperacao
      AND bSelecao.tipo-item = "SOLICITACAO":
    iSelecionadas = iSelecionadas + 1.
END.
RUN registrarE12Diagnostico ("SERVICO_DEPOIS_SELECAO").
ASSIGN pcErro = "E12_ETIQUETA_COM_DEPENDENCIA"
       pcMensagem = "Embalagem recebida possui movimento posterior ou estado divergente.".
FOR EACH bMovtoEntrada NO-LOCK
    WHERE bMovtoEntrada.id-evento = iRecebimentoAtivo:
    IF bMovtoEntrada.tipo-movto <> cTipoMovimento OR
       bMovtoEntrada.cod-estabel-orig <> bOper.cod-estabel-orig OR
       bMovtoEntrada.tipo-local-orig <> cPosicaoOrigem OR
       bMovtoEntrada.cod-estabel-dest <> bDoc.cod-estabel OR
       bMovtoEntrada.tipo-local-dest <> "ESTAB" THEN RETURN.
    FIND FIRST bEtiqueta NO-LOCK
        WHERE bEtiqueta.id-etiqueta = bMovtoEntrada.id-etiqueta NO-ERROR.
    IF NOT AVAILABLE bEtiqueta OR
       bEtiqueta.id-movto-ult <> bMovtoEntrada.id-movto OR
       bEtiqueta.tipo-controle <> "EMBALAGEM" OR
       bEtiqueta.situacao <> "ATIVA" OR
       bEtiqueta.id-bag <> ? OR
       bEtiqueta.tipo-local <> "ESTAB" OR
       bEtiqueta.cod-estabel <> bDoc.cod-estabel OR
       bEtiqueta.cod-depos <> bMovtoEntrada.cod-depos-dest OR
       bEtiqueta.cod-localiz <>
           (IF bMovtoEntrada.cod-localiz-dest = ? THEN ""
            ELSE bMovtoEntrada.cod-localiz-dest) OR
       bEtiqueta.qtidade-atu <> bMovtoEntrada.qtidade-atu THEN RETURN.
    iMovimentos = iMovimentos + 1.
END.
RUN registrarE12Diagnostico ("SERVICO_DEPOIS_MOVIMENTOS_ENTRADA").
IF iMovimentos = 0 OR iMovimentos <> iSelecionadas THEN DO:
    ASSIGN pcErro = "E12_MOVIMENTOS_INCOMPLETOS"
           pcMensagem = "Chegada nao contem todas as etiquetas selecionadas.".
    RETURN.
END.
ASSIGN piQtdEtiquetas = iMovimentos
       cUsuario = IF bDoc.usuario = ? THEN "" ELSE TRIM(bDoc.usuario, " ").
IF cUsuario = "" THEN cUsuario = USERID("mgmov").
IF cUsuario = ? OR cUsuario = "" THEN DO:
    ASSIGN pcErro = "E12_USUARIO_AUSENTE"
           pcMensagem = "Usuario da desatualizacao nao identificado.".
    RETURN.
END.
ASSIGN cChaveRev = "RE0402RP|" + cTipoMovimento + "|ORIGEM|" +
                    STRING(iRecebimentoAtivo)
       cConteudo = cChaveRev + "|" + bRecebAtivo.hash-conteudo
       dtAgora = NOW.
CREATE ttEmbEventoComando.
ASSIGN ttEmbEventoComando.origem = "RE0402RP"
       ttEmbEventoComando.chave-evento = cChaveRev
       ttEmbEventoComando.hash-chave = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cChaveRev))
       ttEmbEventoComando.hash-conteudo = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cConteudo))
       ttEmbEventoComando.tipo-evento = "DESATUALIZACAO_ENTRADA"
       ttEmbEventoComando.id-operacao = iOperacao
       ttEmbEventoComando.id-evento-origem = iRecebimentoAtivo
       ttEmbEventoComando.seq-ciclo = iCicloAtivo + 1
       ttEmbEventoComando.dt-evento = dtAgora
       ttEmbEventoComando.versao-contrato = 1
       ttEmbEventoComando.tipo-docto = bRecebAtivo.tipo-docto
       ttEmbEventoComando.chave-docto = bRecebAtivo.chave-docto
       ttEmbEventoComando.hash-docto = bRecebAtivo.hash-docto
       ttEmbEventoComando.cod-estabel = bRecebAtivo.cod-estabel
       ttEmbEventoComando.cod-emitente = bRecebAtivo.cod-emitente
       ttEmbEventoComando.serie = bRecebAtivo.serie
       ttEmbEventoComando.nro-docto = bRecebAtivo.nro-docto
       ttEmbEventoComando.nat-operacao = bRecebAtivo.nat-operacao
       ttEmbEventoComando.dt-emissao = bRecebAtivo.dt-emissao
       ttEmbEventoComando.dados-evento =
           "RE0402RP; entrada desatualizada; origem=" + STRING(iRecebimentoAtivo)
       ttEmbEventoComando.usuario = cUsuario.

reversaoTransacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    FIND FIRST bOperacaoLock WHERE bOperacaoLock.id-operacao = bOper.id-operacao
        EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
    IF LOCKED bOperacaoLock OR NOT AVAILABLE bOperacaoLock THEN DO:
        ASSIGN pcErro = "REC_OPERACAO_BLOQUEADA" pcMensagem = "Operacao em uso; tentar novamente.".
        UNDO reversaoTransacao, LEAVE reversaoTransacao.
    END.
    IF lRetorno AND NOT lArmazenagem THEN DO:
        RUN validarDocumentoRetorno(INPUT prDocumEst, INPUT bOrigem.id-evento-origem,
            INPUT YES, OUTPUT lNucleo, OUTPUT pcErro, OUTPUT pcMensagem).
        IF NOT lNucleo THEN UNDO reversaoTransacao, LEAVE reversaoTransacao.
    END.
    IF lArmazenagem THEN DO:
        RUN validarOrigemArmazenagem(INPUT prDocumEst, INPUT bOrigem.id-evento-origem,
            OUTPUT lNucleo, OUTPUT pcErro, OUTPUT pcMensagem).
        IF NOT lNucleo THEN UNDO reversaoTransacao, LEAVE reversaoTransacao.
    END.
    RUN registrarE12Diagnostico ("SERVICO_ANTES_REGISTRAR_EVENTO").
    RUN registrarEvento IN phRastreio(INPUT TABLE ttEmbEventoComando, INPUT YES,
        OUTPUT lNucleo, OUTPUT lRepNucleo, OUTPUT piIdEvento,
        OUTPUT cSituacao, OUTPUT iVersaoEvento, OUTPUT cErroNucleo, OUTPUT cMsgNucleo).
    IF NOT lNucleo OR lRepNucleo THEN DO:
        ASSIGN pcErro = IF NOT lNucleo THEN cErroNucleo ELSE "E12_REVERSAO_REPETIDA"
               pcMensagem = IF NOT lNucleo THEN cMsgNucleo ELSE "Reversao concorrente."
               piIdEvento = 0.
        UNDO reversaoTransacao, LEAVE reversaoTransacao.
    END.
    RUN registrarE12Diagnostico ("SERVICO_DEPOIS_REGISTRAR_EVENTO").
    ASSIGN iSeq = 0.
    FOR EACH bMovtoEntrada NO-LOCK
        WHERE bMovtoEntrada.id-evento = iRecebimentoAtivo
        BY bMovtoEntrada.id-etiqueta:
        FIND FIRST bEtiqueta NO-LOCK
            WHERE bEtiqueta.id-etiqueta = bMovtoEntrada.id-etiqueta NO-ERROR.
        IF NOT AVAILABLE bEtiqueta OR
           bEtiqueta.id-movto-ult <> bMovtoEntrada.id-movto OR
           bEtiqueta.tipo-local <> "ESTAB" THEN DO:
            ASSIGN pcErro = "E12_ETIQUETA_COM_DEPENDENCIA"
                   pcMensagem = "Embalagem mudou durante a desatualizacao.".
            UNDO reversaoTransacao, LEAVE reversaoTransacao.
        END.
        ASSIGN iSeq = iSeq + 1.
        RUN registrarE12Diagnostico
            ("SERVICO_ANTES_MOVIMENTO_" + STRING(bEtiqueta.id-etiqueta)).
        EMPTY TEMP-TABLE ttEmbMovimentoComando.
        CREATE ttEmbMovimentoComando.
        ASSIGN ttEmbMovimentoComando.id-evento = piIdEvento
               ttEmbMovimentoComando.sequencia = iSeq
               ttEmbMovimentoComando.id-etiqueta = bEtiqueta.id-etiqueta
               ttEmbMovimentoComando.id-item-oper = bMovtoEntrada.id-item-oper
               ttEmbMovimentoComando.versao-etiqueta-esperada = bEtiqueta.versao
               ttEmbMovimentoComando.id-movto-ant-esperado = bEtiqueta.id-movto-ult
               ttEmbMovimentoComando.id-movto-origem = bMovtoEntrada.id-movto
               ttEmbMovimentoComando.tipo-movto = "DESATUALIZACAO_ENTRADA"
               ttEmbMovimentoComando.dt-movto = dtAgora
               ttEmbMovimentoComando.un = bEtiqueta.un
               ttEmbMovimentoComando.quantidade = bMovtoEntrada.quantidade
               ttEmbMovimentoComando.qtidade-atu = bMovtoEntrada.qtidade-ant
               ttEmbMovimentoComando.situacao-atu = bMovtoEntrada.situacao-ant
               ttEmbMovimentoComando.cod-estabel-dest = bMovtoEntrada.cod-estabel-orig
               ttEmbMovimentoComando.cod-depos-dest = bMovtoEntrada.cod-depos-orig
               ttEmbMovimentoComando.cod-localiz-dest = bMovtoEntrada.cod-localiz-orig
               ttEmbMovimentoComando.tipo-local-dest = bMovtoEntrada.tipo-local-orig
               ttEmbMovimentoComando.cod-emitente-dest = bMovtoEntrada.cod-emitente-orig
               ttEmbMovimentoComando.origem-movto-erp = "RE0402RP"
               ttEmbMovimentoComando.chave-movto-erp = cChaveDoc
               ttEmbMovimentoComando.justificativa =
                   "Entrada desatualizada no RE0402; serie=" + bDoc.serie-docto
                   + "; documento=" + bDoc.nro-docto
                   + "; emitente=" + STRING(bDoc.cod-emitente)
               ttEmbMovimentoComando.usuario = cUsuario.
        RUN aplicarMovimento IN phRastreio(INPUT TABLE ttEmbMovimentoComando, INPUT YES,
            OUTPUT lNucleo, OUTPUT lRepNucleo, OUTPUT iMovto, OUTPUT iVersao,
            OUTPUT cErroNucleo, OUTPUT cMsgNucleo).
        IF NOT lNucleo OR lRepNucleo THEN DO:
            ASSIGN pcErro = IF NOT lNucleo THEN cErroNucleo ELSE "E12_MOVIMENTO_REPETIDO"
                   pcMensagem = IF NOT lNucleo THEN cMsgNucleo ELSE "Reversao concorrente.".
            UNDO reversaoTransacao, LEAVE reversaoTransacao.
        END.
        RUN registrarE12Diagnostico
            ("SERVICO_DEPOIS_MOVIMENTO_" + STRING(bEtiqueta.id-etiqueta)).
    END.
    FIND FIRST bNovoEvento EXCLUSIVE-LOCK
        WHERE bNovoEvento.id-evento = piIdEvento NO-ERROR.
    IF NOT AVAILABLE bNovoEvento OR iSeq <> piQtdEtiquetas THEN DO:
        ASSIGN pcErro = "E12_EVENTO_INCOMPLETO"
               pcMensagem = "Movimentos da desatualizacao incompletos.".
        UNDO reversaoTransacao, LEAVE reversaoTransacao.
    END.
    ASSIGN bNovoEvento.situacao = "CONCLUIDO"
           bNovoEvento.dt-conclusao = NOW
           bNovoEvento.resultado = "etiquetas=" + STRING(iSeq)
           bNovoEvento.dt-alteracao = NOW
           bNovoEvento.versao = bNovoEvento.versao + 1
           plSucesso = YES pcErro = "" pcMensagem = "".
    RUN registrarE12Diagnostico ("SERVICO_EVENTO_CONCLUIDO").
END.
END PROCEDURE.

PROCEDURE registrarE12Diagnostico:
DEFINE INPUT PARAMETER pcEtapa AS CHARACTER NO-UNDO.
OUTPUT STREAM sE05Diag TO
    VALUE(ceArquivoPacote("diagnostico-entrada-emprestimo-e12.txt"))
    APPEND.
PUT STREAM sE05Diag UNFORMATTED STRING(NOW) "|" pcEtapa SKIP.
OUTPUT STREAM sE05Diag CLOSE.
END PROCEDURE.

{fontes/progress/includes/contr-emb-recebimento-origem.i}

