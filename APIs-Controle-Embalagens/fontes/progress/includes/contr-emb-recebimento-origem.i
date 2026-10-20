/* DT-100: origem documental e continuidade compartilhadas pelos recebimentos.
   Campos padrao comprovados; nenhuma escrita em estoque/documentos Datasul.
   O modulo chamador declara ttRecVinculoCmd LIKE ttEmbEventoComando. */

FUNCTION fRecTexto RETURNS CHARACTER (pcValor AS CHARACTER):
    RETURN IF pcValor = ? THEN "" ELSE TRIM(pcValor).
END FUNCTION.

PROCEDURE resolverOrigemRecebimento:
DEFINE INPUT PARAMETER prDocumento AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER pcTipoOperacao AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piDocumentoInformado AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piDocumentoSaida AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piOperacao AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcOrigem AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcSerie AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcNumero AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcChaveEntrada AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plAplicavel AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bRecDoc FOR mgmov.docum-est.
DEFINE BUFFER bRecLinha FOR mgmov.item-doc-est.
DEFINE BUFFER bRecOrig FOR mgcad.estabelec.
DEFINE BUFFER bRecDest FOR mgcad.estabelec.
DEFINE BUFFER bRecNota FOR mgmov.nota-fiscal.
DEFINE BUFFER bRecEvento FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRecSaida FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRecDocumento FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRecOper FOR mgesp.contr_emb_oper.
DEFINE VARIABLE cSerieRef AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNumeroRef AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChaveNfe AS CHARACTER NO-UNDO.
DEFINE VARIABLE iVinculos AS INTEGER NO-UNDO.
DEFINE VARIABLE iOrigemHistorico AS INTEGER NO-UNDO.
DEFINE VARIABLE iPorItem AS INTEGER NO-UNDO.
DEFINE VARIABLE iPorChave AS INTEGER NO-UNDO.
DEFINE VARIABLE iPorCabecalho AS INTEGER NO-UNDO.
DEFINE VARIABLE iItem AS INTEGER NO-UNDO.
DEFINE VARIABLE iChave AS INTEGER NO-UNDO.
DEFINE VARIABLE iCabecalho AS INTEGER NO-UNDO.
DEFINE VARIABLE iPotenciais AS INTEGER NO-UNDO.
DEFINE VARIABLE iNotas AS INTEGER NO-UNDO.
DEFINE VARIABLE iOperVinculo AS INTEGER NO-UNDO.
DEFINE VARIABLE lRetornoValido AS LOGICAL NO-UNDO.
DEFINE VARIABLE cErroRetorno AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagemRetorno AS CHARACTER NO-UNDO.

IF pcTipoOperacao = "RETORNO_ARMAZENAGEM" THEN DO:
    RUN resolverOrigemArmazenagem(INPUT prDocumento, INPUT piDocumentoInformado,
        OUTPUT piDocumentoSaida, OUTPUT piOperacao, OUTPUT pcOrigem, OUTPUT pcSerie,
        OUTPUT pcNumero, OUTPUT pcChaveEntrada, OUTPUT plAplicavel, OUTPUT plSucesso,
        OUTPUT pcErro, OUTPUT pcMensagem).
    RETURN.
END.
ASSIGN piDocumentoSaida = 0 piOperacao = 0 pcOrigem = ""
       pcSerie = "" pcNumero = "" pcChaveEntrada = ""
       plAplicavel = NO plSucesso = NO pcErro = "REC_DOCUMENTO_INVALIDO"
       pcMensagem = "Documento de entrada ou tipo de operacao invalido.".
IF prDocumento = ? OR LOOKUP(pcTipoOperacao, "TRANSFERENCIA,REMESSA_TERCEIROS,RETORNO_TERCEIROS") = 0 OR
   piDocumentoInformado = ? OR piDocumentoInformado < 0 THEN RETURN.
FIND FIRST bRecDoc NO-LOCK WHERE ROWID(bRecDoc) = prDocumento NO-ERROR.
IF NOT AVAILABLE bRecDoc THEN RETURN.
ASSIGN pcChaveEntrada = "ENTRADA|"
       + STRING(LENGTH(bRecDoc.cod-estabel)) + ":" + bRecDoc.cod-estabel
       + "|" + STRING(bRecDoc.cod-emitente)
       + "|" + STRING(LENGTH(bRecDoc.serie-docto)) + ":" + bRecDoc.serie-docto
       + "|" + STRING(LENGTH(bRecDoc.nro-docto)) + ":" + bRecDoc.nro-docto
       + "|" + bRecDoc.nat-operacao.

/* Primeiro a associacao persistida. Historico anterior tambem e autoridade. */
FOR EACH bRecEvento NO-LOCK
    WHERE bRecEvento.chave-docto = pcChaveEntrada
      AND bRecEvento.tipo-evento = "VINCULO_ENTRADA_SAIDA":
    ASSIGN iVinculos = iVinculos + 1 plAplicavel = YES.
    IF bRecEvento.situacao <> "CONCLUIDO" OR
       bRecEvento.id-evento-origem = ? OR bRecEvento.id-evento-origem <= 0 THEN DO:
        ASSIGN pcErro = "REC_VINCULO_INVALIDO" pcMensagem = "Vinculo documental pendente ou incompleto.".
        RETURN.
    END.
    ASSIGN piDocumentoSaida = bRecEvento.id-evento-origem
           iOperVinculo = bRecEvento.id-operacao.
END.
IF iVinculos > 1 THEN DO:
    ASSIGN pcErro = "REC_VINCULO_AMBIGUO" pcMensagem = "Mais de um vinculo para a entrada.".
    RETURN.
END.
/* Vinculo de retorno externo pertence a remessa da propria fazenda. */
IF pcTipoOperacao = "RETORNO_TERCEIROS" AND piDocumentoSaida > 0 THEN DO:
    FIND FIRST bRecDocumento NO-LOCK WHERE bRecDocumento.id-evento = piDocumentoSaida NO-ERROR.
    IF AVAILABLE bRecDocumento THEN DO:
        FIND FIRST bRecOper NO-LOCK WHERE bRecOper.id-operacao = bRecDocumento.id-operacao NO-ERROR.
        IF AVAILABLE bRecOper AND bRecOper.tipo-operacao = "REMESSA_TERCEIROS"
           AND bRecOper.cod-estabel-orig = bRecDoc.cod-estabel THEN DO:
            ASSIGN plAplicavel = NO plSucesso = YES pcErro = "" pcMensagem = "Retorno externo vinculado a remessa.".
            RETURN.
        END.
    END.
END.
FOR EACH bRecEvento NO-LOCK WHERE bRecEvento.chave-docto = pcChaveEntrada:
    IF LOOKUP(bRecEvento.tipo-evento, "RECEBIMENTO_TRANSFERENCIA,RECEBIMENTO_EMPRESTIMO,RECEBIMENTO_RETORNO_EMPRESTIMO,RECEBIMENTO_RETORNO_TERCEIROS") = 0 THEN NEXT.
    plAplicavel = YES.
    FIND FIRST bRecSaida NO-LOCK WHERE bRecSaida.id-evento = bRecEvento.id-evento-origem NO-ERROR.
    IF NOT AVAILABLE bRecSaida OR bRecSaida.tipo-evento <> "SAIDA_ESTOQUE" OR
       bRecSaida.situacao <> "CONCLUIDO" OR bRecEvento.situacao <> "CONCLUIDO" THEN DO:
        ASSIGN pcErro = "REC_HISTORICO_INVALIDO" pcMensagem = "Historico da entrada sem saida confirmada.".
        RETURN.
    END.
    iOrigemHistorico = bRecSaida.id-evento-origem.
    IF iOrigemHistorico = ? OR iOrigemHistorico <= 0 OR
       (piDocumentoSaida > 0 AND piDocumentoSaida <> iOrigemHistorico) THEN DO:
        ASSIGN pcErro = "REC_ORIGENS_DIVERGENTES" pcMensagem = "Historico aponta documentos de saida diferentes.".
        RETURN.
    END.
    piDocumentoSaida = iOrigemHistorico.
END.
IF piDocumentoInformado > 0 THEN DO:
    plAplicavel = YES.
    IF piDocumentoSaida > 0 AND piDocumentoSaida <> piDocumentoInformado THEN DO:
        ASSIGN pcErro = "REC_VINCULO_DIVERGENTE" pcMensagem = "A entrada ja possui outra origem registrada.".
        RETURN.
    END.
    piDocumentoSaida = piDocumentoInformado.
END.
FOR EACH bRecLinha OF bRecDoc NO-LOCK:
    IF (fRecTexto(bRecLinha.serie-comp) = "") <> (fRecTexto(bRecLinha.nro-comp) = "") THEN DO:
        ASSIGN plAplicavel = YES pcErro = "REC_ORIGEM_PARCIAL"
               pcMensagem = "Serie e numero de origem devem estar ambos completos ou vazios.".
        RETURN.
    END.
    IF fRecTexto(bRecLinha.nro-comp) = "" THEN NEXT.
    IF cNumeroRef <> "" AND
       (cNumeroRef <> fRecTexto(bRecLinha.nro-comp) OR cSerieRef <> fRecTexto(bRecLinha.serie-comp)) THEN DO:
        ASSIGN plAplicavel = YES pcErro = "REC_MULTIPLAS_ORIGENS"
               pcMensagem = "Os itens apontam para documentos de origem diferentes.".
        RETURN.
    END.
    ASSIGN cNumeroRef = fRecTexto(bRecLinha.nro-comp) cSerieRef = fRecTexto(bRecLinha.serie-comp).
END.
FIND FIRST bRecDest NO-LOCK WHERE bRecDest.cod-estabel = bRecDoc.cod-estabel NO-ERROR.
IF NOT AVAILABLE bRecDest THEN RETURN.
cChaveNfe = fRecTexto(bRecDoc.cod-chave-aces-nf-eletro).
/* Comparacao exata de identidade fiscal, nunca saldo/item/data aproximados. */
FOR EACH bRecDocumento NO-LOCK WHERE bRecDocumento.tipo-evento = "DOCUMENTO_SAIDA_FLUIG"
    AND bRecDocumento.tipo-docto = "SAIDA":
    FIND FIRST bRecOper NO-LOCK WHERE bRecOper.id-operacao = bRecDocumento.id-operacao NO-ERROR.
    IF NOT AVAILABLE bRecOper OR bRecOper.tipo-operacao <> pcTipoOperacao THEN NEXT.
    FIND FIRST bRecOrig NO-LOCK WHERE bRecOrig.cod-estabel = bRecDocumento.cod-estabel
        AND bRecOrig.cod-emitente = bRecDoc.cod-emitente NO-ERROR.
    IF NOT AVAILABLE bRecOrig THEN NEXT.
    IF pcTipoOperacao = "RETORNO_TERCEIROS" AND
       bRecOper.cod-emitente <> bRecDest.cod-emitente THEN NEXT.
    IF pcTipoOperacao = "RETORNO_TERCEIROS" THEN DO:
        RUN validarDocumentoRetorno(INPUT prDocumento, INPUT bRecDocumento.id-evento,
            INPUT NO,
            OUTPUT lRetornoValido, OUTPUT cErroRetorno, OUTPUT cMensagemRetorno).
        IF NOT lRetornoValido THEN DO:
            IF bRecDocumento.id-evento = piDocumentoSaida OR
               (bRecDocumento.serie = bRecDoc.serie-docto AND bRecDocumento.nro-docto = bRecDoc.nro-docto) THEN DO:
                ASSIGN plAplicavel = YES pcErro = cErroRetorno pcMensagem = cMensagemRetorno.
                RETURN.
            END.
            NEXT.
        END.
    END.
    ELSE IF bRecOper.cod-estabel-dest <> bRecDoc.cod-estabel THEN NEXT.
    iPotenciais = iPotenciais + 1.
    IF pcTipoOperacao <> "RETORNO_TERCEIROS" AND cNumeroRef <> "" AND
       bRecDocumento.serie = cSerieRef AND bRecDocumento.nro-docto = cNumeroRef THEN
        ASSIGN iPorItem = iPorItem + 1 iItem = bRecDocumento.id-evento.
    IF bRecDocumento.serie = bRecDoc.serie-docto AND bRecDocumento.nro-docto = bRecDoc.nro-docto THEN
        ASSIGN iPorCabecalho = iPorCabecalho + 1 iCabecalho = bRecDocumento.id-evento.
    IF LENGTH(cChaveNfe) = 44 AND cChaveNfe <> FILL("0", 44) THEN DO:
        FIND FIRST bRecNota NO-LOCK WHERE bRecNota.cod-estabel = bRecDocumento.cod-estabel
            AND bRecNota.serie = bRecDocumento.serie AND bRecNota.nr-nota-fis = bRecDocumento.nro-docto NO-ERROR.
        IF AVAILABLE bRecNota AND fRecTexto(bRecNota.cod-chave-aces-nf-eletro) = cChaveNfe THEN
            ASSIGN iPorChave = iPorChave + 1 iChave = bRecDocumento.id-evento.
    END.
END.
IF iPotenciais > 0 OR piDocumentoSaida > 0 THEN plAplicavel = YES.
IF iPorItem > 1 OR iPorChave > 1 OR
   (piDocumentoSaida = 0 AND (cNumeroRef = "" OR pcTipoOperacao = "RETORNO_TERCEIROS") AND
    iPorChave = 0 AND iPorCabecalho > 1) THEN DO:
    ASSIGN pcErro = "REC_ORIGEM_AMBIGUA" pcMensagem = "A identidade documental corresponde a mais de uma saida.".
    RETURN.
END.
IF cNumeroRef <> "" AND pcTipoOperacao <> "RETORNO_TERCEIROS" THEN DO:
    IF iPorItem <> 1 THEN DO:
        ASSIGN pcErro = "REC_REFERENCIA_NAO_ENCONTRADA" pcMensagem = "A referencia dos itens nao identifica uma saida rastreada unica.".
        RETURN.
    END.
    IF piDocumentoSaida > 0 AND piDocumentoSaida <> iItem THEN DO:
        ASSIGN pcErro = "REC_REFERENCIA_DIVERGENTE" pcMensagem = "A referencia dos itens diverge do vinculo registrado.".
        RETURN.
    END.
    piDocumentoSaida = iItem.
END.
ELSE IF iPorChave = 1 THEN DO:
    IF piDocumentoSaida > 0 AND piDocumentoSaida <> iChave THEN DO:
        ASSIGN pcErro = "REC_CHAVE_DIVERGENTE" pcMensagem = "A chave da NF-e diverge do vinculo registrado.".
        RETURN.
    END.
    piDocumentoSaida = iChave.
END.
ELSE IF piDocumentoSaida = 0 AND iPorCabecalho = 1 THEN piDocumentoSaida = iCabecalho.
IF piDocumentoSaida = 0 THEN DO:
    IF NOT plAplicavel THEN ASSIGN plSucesso = YES pcErro = "" pcMensagem = "Entrada sem origem do projeto.".
    ELSE ASSIGN pcErro = "REC_ORIGEM_NECESSARIA" pcMensagem = "Existe remessa para este destino; informar a origem documental, sem escolher por quantidade.".
    RETURN.
END.
FIND FIRST bRecDocumento NO-LOCK WHERE bRecDocumento.id-evento = piDocumentoSaida NO-ERROR.
IF NOT AVAILABLE bRecDocumento OR bRecDocumento.tipo-evento <> "DOCUMENTO_SAIDA_FLUIG" OR
   bRecDocumento.situacao <> "CONCLUIDO" OR bRecDocumento.tipo-docto <> "SAIDA" THEN RETURN.
FIND FIRST bRecOper NO-LOCK WHERE bRecOper.id-operacao = bRecDocumento.id-operacao NO-ERROR.
FIND FIRST bRecOrig NO-LOCK WHERE bRecOrig.cod-estabel = bRecDocumento.cod-estabel NO-ERROR.
IF NOT AVAILABLE bRecOper OR NOT AVAILABLE bRecOrig OR
   bRecOper.tipo-operacao <> pcTipoOperacao OR bRecOper.cod-estabel-orig <> bRecOrig.cod-estabel OR
   (pcTipoOperacao <> "RETORNO_TERCEIROS" AND bRecOper.cod-estabel-dest <> bRecDoc.cod-estabel) OR
   bRecOrig.cod-emitente <> bRecDoc.cod-emitente THEN RETURN.
IF pcTipoOperacao = "RETORNO_TERCEIROS" THEN DO:
    RUN validarDocumentoRetorno(INPUT prDocumento, INPUT piDocumentoSaida,
        INPUT YES,
        OUTPUT lRetornoValido, OUTPUT pcErro, OUTPUT pcMensagem).
    IF NOT lRetornoValido THEN RETURN.
END.
IF iVinculos = 1 AND iOperVinculo <> bRecOper.id-operacao THEN DO:
    ASSIGN pcErro = "REC_OPERACAO_DIVERGENTE" pcMensagem = "Vinculo aponta outra operacao.".
    RETURN.
END.
FOR EACH bRecNota NO-LOCK WHERE bRecNota.cod-estabel = bRecDocumento.cod-estabel
    AND bRecNota.serie = bRecDocumento.serie AND bRecNota.nr-nota-fis = bRecDocumento.nro-docto:
    iNotas = iNotas + 1.
END.
IF iNotas <> 1 THEN DO:
    ASSIGN pcErro = "REC_NOTA_NAO_UNICA" pcMensagem = "Nota fiscal de saida ausente ou ambigua.".
    RETURN.
END.
FIND FIRST bRecNota NO-LOCK WHERE bRecNota.cod-estabel = bRecDocumento.cod-estabel
    AND bRecNota.serie = bRecDocumento.serie AND bRecNota.nr-nota-fis = bRecDocumento.nro-docto NO-ERROR.
IF NOT AVAILABLE bRecNota OR bRecNota.cod-emitente <> bRecDest.cod-emitente OR
   bRecNota.nat-operacao <> bRecDocumento.nat-operacao OR
   bRecOper.seq-wt-docto = ? OR bRecOper.seq-wt-docto <= 0 OR
   fRecTexto(SUBSTRING(bRecNota.char-2, 1500, 20)) <> "CEWT1:" + STRING(bRecOper.seq-wt-docto) THEN RETURN.
ASSIGN piOperacao = bRecOper.id-operacao pcOrigem = bRecDocumento.cod-estabel
       pcSerie = bRecDocumento.serie pcNumero = bRecDocumento.nro-docto
       plAplicavel = YES plSucesso = YES pcErro = "" pcMensagem = "".
END PROCEDURE.

PROCEDURE validarRecebimentosOrigem:
DEFINE INPUT PARAMETER piDocumentoSaida AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piSaidaAtiva AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcChaveEntrada AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bRecDocumento FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRecSaida FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRecEntrada FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRecRev FOR mgesp.contr_emb_evento.
DEFINE VARIABLE iReversoes AS INTEGER NO-UNDO.
ASSIGN plSucesso = NO pcErro = "REC_HISTORICO_INVALIDO" pcMensagem = "Historico da origem inconsistente.".
FIND FIRST bRecDocumento NO-LOCK WHERE bRecDocumento.id-evento = piDocumentoSaida NO-ERROR.
IF NOT AVAILABLE bRecDocumento THEN RETURN.
FIND FIRST bRecSaida NO-LOCK WHERE bRecSaida.id-evento = piSaidaAtiva NO-ERROR.
IF NOT AVAILABLE bRecSaida OR bRecSaida.tipo-evento <> "SAIDA_ESTOQUE" OR
   bRecSaida.id-evento-origem <> piDocumentoSaida OR
   bRecSaida.id-operacao <> bRecDocumento.id-operacao OR
   bRecSaida.situacao <> "CONCLUIDO" THEN RETURN.
IF CAN-FIND(FIRST bRecRev NO-LOCK WHERE bRecRev.tipo-evento = "DESATUALIZACAO_SAIDA"
    AND bRecRev.id-evento-origem = piSaidaAtiva) THEN DO:
    ASSIGN pcErro = "REC_SAIDA_REVERTIDA" pcMensagem = "O ciclo de saida foi revertido; nao receber.".
    RETURN.
END.
FOR EACH bRecEntrada NO-LOCK WHERE bRecEntrada.id-operacao = bRecDocumento.id-operacao:
    IF LOOKUP(bRecEntrada.tipo-evento, "RECEBIMENTO_TRANSFERENCIA,RECEBIMENTO_EMPRESTIMO,RECEBIMENTO_RETORNO_EMPRESTIMO,RECEBIMENTO_RETORNO_TERCEIROS") = 0 THEN NEXT.
    FIND FIRST bRecSaida NO-LOCK WHERE bRecSaida.id-evento = bRecEntrada.id-evento-origem NO-ERROR.
    IF NOT AVAILABLE bRecSaida OR bRecSaida.tipo-evento <> "SAIDA_ESTOQUE" THEN RETURN.
    IF bRecSaida.id-evento-origem <> piDocumentoSaida THEN NEXT.
    IF bRecEntrada.situacao <> "CONCLUIDO" OR bRecSaida.situacao <> "CONCLUIDO" THEN RETURN.
    iReversoes = 0.
    FOR EACH bRecRev NO-LOCK WHERE bRecRev.id-evento-origem = bRecEntrada.id-evento
        AND bRecRev.tipo-evento = "DESATUALIZACAO_ENTRADA":
        iReversoes = iReversoes + 1.
        IF bRecRev.situacao <> "CONCLUIDO" OR bRecRev.id-operacao <> bRecEntrada.id-operacao OR
           bRecRev.chave-docto <> bRecEntrada.chave-docto OR bRecRev.seq-ciclo <> bRecEntrada.seq-ciclo + 1 THEN RETURN.
    END.
    IF iReversoes > 1 THEN RETURN.
    IF iReversoes = 0 AND (bRecEntrada.chave-docto <> pcChaveEntrada OR bRecSaida.id-evento <> piSaidaAtiva) THEN DO:
        ASSIGN pcErro = "REC_ORIGEM_JA_RECEBIDA" pcMensagem = "A remessa possui chegada ativa em outro documento ou ciclo.".
        RETURN.
    END.
END.
ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
END PROCEDURE.

PROCEDURE validarContinuidadeRecebimento:
DEFINE INPUT PARAMETER piMovtoSaida AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piEtiqueta AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcTipoChegada AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bRecEtiqueta FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bRecSaida FOR mgesp.contr_emb_movto.
DEFINE BUFFER bRecUlt FOR mgesp.contr_emb_movto.
DEFINE BUFFER bRecChegada FOR mgesp.contr_emb_movto.
DEFINE BUFFER bRecEventoSaida FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRecEventoChegada FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRecEventoRev FOR mgesp.contr_emb_evento.
ASSIGN plSucesso = NO pcErro = "REC_ESTADO_POSTERIOR" pcMensagem = "Ultimo movimento nao confirma a saida pendente desta origem.".
FIND FIRST bRecEtiqueta NO-LOCK WHERE bRecEtiqueta.id-etiqueta = piEtiqueta NO-ERROR.
FIND FIRST bRecSaida NO-LOCK WHERE bRecSaida.id-movto = piMovtoSaida NO-ERROR.
IF NOT AVAILABLE bRecEtiqueta OR NOT AVAILABLE bRecSaida OR bRecSaida.id-etiqueta <> piEtiqueta THEN RETURN.
FIND FIRST bRecUlt NO-LOCK WHERE bRecUlt.id-movto = bRecEtiqueta.id-movto-ult NO-ERROR.
FIND FIRST bRecEventoSaida NO-LOCK WHERE bRecEventoSaida.id-evento = bRecSaida.id-evento NO-ERROR.
IF NOT AVAILABLE bRecUlt OR bRecUlt.id-etiqueta <> piEtiqueta OR NOT AVAILABLE bRecEventoSaida OR
   bRecEventoSaida.tipo-evento <> "SAIDA_ESTOQUE" OR bRecEventoSaida.situacao <> "CONCLUIDO" THEN RETURN.
IF bRecUlt.id-movto <> piMovtoSaida THEN DO:
    IF bRecUlt.tipo-movto <> "DESATUALIZACAO_ENTRADA" THEN RETURN.
    FIND FIRST bRecChegada NO-LOCK WHERE bRecChegada.id-movto = bRecUlt.id-movto-origem NO-ERROR.
    IF NOT AVAILABLE bRecChegada OR bRecChegada.id-etiqueta <> piEtiqueta OR
       bRecChegada.tipo-movto <> pcTipoChegada OR bRecChegada.id-movto-origem <> piMovtoSaida OR
       bRecUlt.id-movto-ant <> bRecChegada.id-movto THEN RETURN.
    FIND FIRST bRecEventoChegada NO-LOCK WHERE bRecEventoChegada.id-evento = bRecChegada.id-evento NO-ERROR.
    FIND FIRST bRecEventoRev NO-LOCK WHERE bRecEventoRev.id-evento = bRecUlt.id-evento NO-ERROR.
    IF NOT AVAILABLE bRecEventoChegada OR NOT AVAILABLE bRecEventoRev OR
       bRecEventoChegada.situacao <> "CONCLUIDO" OR bRecEventoRev.situacao <> "CONCLUIDO" OR
       bRecEventoChegada.tipo-evento <>
           (IF pcTipoChegada = "ENTRADA_RETORNO_TERCEIROS" THEN "RECEBIMENTO_RETORNO_TERCEIROS"
            ELSE IF pcTipoChegada = "ENTRADA_RETORNO_EMPRESTIMO" THEN "RECEBIMENTO_RETORNO_EMPRESTIMO"
            ELSE IF pcTipoChegada = "ENTRADA_EMPRESTIMO" THEN "RECEBIMENTO_EMPRESTIMO"
            ELSE "RECEBIMENTO_TRANSFERENCIA") OR
       bRecEventoChegada.id-evento-origem <> bRecEventoSaida.id-evento OR
       bRecEventoRev.tipo-evento <> "DESATUALIZACAO_ENTRADA" OR
       bRecEventoRev.id-evento-origem <> bRecEventoChegada.id-evento OR
       bRecEventoRev.id-operacao <> bRecEventoSaida.id-operacao OR
       bRecEventoChegada.id-operacao <> bRecEventoSaida.id-operacao OR
       bRecEventoRev.chave-docto <> bRecEventoChegada.chave-docto OR
       bRecEventoRev.seq-ciclo <> bRecEventoChegada.seq-ciclo + 1 THEN RETURN.
END.
IF bRecEtiqueta.qtidade-atu <> bRecUlt.qtidade-atu OR
   bRecEtiqueta.un <> bRecUlt.un OR bRecEtiqueta.situacao <> bRecUlt.situacao-atu OR
   bRecEtiqueta.tipo-local <> bRecUlt.tipo-local-dest OR
   bRecEtiqueta.cod-estabel <> bRecUlt.cod-estabel-dest OR
   fRecTexto(bRecEtiqueta.cod-depos) <> fRecTexto(bRecUlt.cod-depos-dest) OR
   fRecTexto(bRecEtiqueta.cod-localiz) <> fRecTexto(bRecUlt.cod-localiz-dest) OR
   (IF bRecEtiqueta.cod-emitente-posse = ? THEN 0 ELSE bRecEtiqueta.cod-emitente-posse) <>
   (IF bRecUlt.cod-emitente-dest = ? THEN 0 ELSE bRecUlt.cod-emitente-dest) THEN RETURN.
IF bRecUlt.qtidade-atu <> bRecSaida.qtidade-atu OR bRecUlt.situacao-atu <> bRecSaida.situacao-atu OR
   bRecUlt.tipo-local-dest <> bRecSaida.tipo-local-dest OR
   bRecUlt.cod-estabel-dest <> bRecSaida.cod-estabel-dest OR
   fRecTexto(bRecUlt.cod-depos-dest) <> fRecTexto(bRecSaida.cod-depos-dest) OR
   fRecTexto(bRecUlt.cod-localiz-dest) <> fRecTexto(bRecSaida.cod-localiz-dest) OR
   (IF bRecUlt.cod-emitente-dest = ? THEN 0 ELSE bRecUlt.cod-emitente-dest) <>
   (IF bRecSaida.cod-emitente-dest = ? THEN 0 ELSE bRecSaida.cod-emitente-dest) THEN RETURN.
ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
END PROCEDURE.

PROCEDURE conciliarEntradaComOrigem:
/* Associacao dirigida/integracao confiavel: origem explicitamente identificada.
   O vinculo so persiste se toda a chegada passar nas mesmas guardas do hook. */
DEFINE INPUT PARAMETER prDocumento AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER piDocumentoSaida AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER phRastreio AS HANDLE NO-UNDO.
DEFINE OUTPUT PARAMETER plAplicavel AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piEvento AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piEtiquetas AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bRecDoc FOR mgmov.docum-est.
DEFINE BUFFER bRecOrigem FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRecOper FOR mgesp.contr_emb_oper.
DEFINE VARIABLE iDocumento AS INTEGER NO-UNDO.
DEFINE VARIABLE iOperacao AS INTEGER NO-UNDO.
DEFINE VARIABLE iVinculo AS INTEGER NO-UNDO.
DEFINE VARIABLE cOrigem AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSerie AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNumero AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChave AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cProcedimento AS CHARACTER NO-UNDO.
DEFINE VARIABLE lResolvido AS LOGICAL NO-UNDO.
ASSIGN plAplicavel = YES plSucesso = NO plRepeticao = NO piEvento = 0 piEtiquetas = 0
    pcErro = "REC_ORIGEM_INVALIDA" pcMensagem = "Informar documento de saida rastreado.".
IF prDocumento = ? OR piDocumentoSaida = ? OR piDocumentoSaida <= 0 OR NOT VALID-HANDLE(phRastreio) THEN RETURN.
FIND FIRST bRecOrigem NO-LOCK WHERE bRecOrigem.id-evento = piDocumentoSaida NO-ERROR.
IF NOT AVAILABLE bRecOrigem THEN RETURN.
FIND FIRST bRecOper NO-LOCK WHERE bRecOper.id-operacao = bRecOrigem.id-operacao NO-ERROR.
IF NOT AVAILABLE bRecOper THEN RETURN.
ASSIGN cTipo = bRecOper.tipo-operacao
    cProcedimento = IF LOOKUP(cTipo, "REMESSA_TERCEIROS,RETORNO_TERCEIROS") > 0
        THEN "processarEntradaEmprestimo" ELSE "processarEntradaTransferencia".
IF LOOKUP(cTipo, "TRANSFERENCIA,REMESSA_TERCEIROS,RETORNO_TERCEIROS") = 0 OR
   LOOKUP(cProcedimento, THIS-PROCEDURE:INTERNAL-ENTRIES) = 0 THEN RETURN.
associacaoTransacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    FIND FIRST bRecDoc WHERE ROWID(bRecDoc) = prDocumento EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
    IF LOCKED bRecDoc OR NOT AVAILABLE bRecDoc THEN DO:
        ASSIGN pcErro = "REC_DOCUMENTO_BLOQUEADO" pcMensagem = "Documento indisponivel; tentar novamente.".
        UNDO associacaoTransacao, LEAVE associacaoTransacao.
    END.
    FIND FIRST bRecOper WHERE bRecOper.id-operacao = bRecOrigem.id-operacao
        EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
    IF LOCKED bRecOper OR NOT AVAILABLE bRecOper THEN DO:
        ASSIGN pcErro = "REC_OPERACAO_BLOQUEADA" pcMensagem = "Operacao em uso; tentar novamente.".
        UNDO associacaoTransacao, LEAVE associacaoTransacao.
    END.
    RUN resolverOrigemRecebimento(INPUT prDocumento, INPUT cTipo, INPUT piDocumentoSaida,
        OUTPUT iDocumento, OUTPUT iOperacao, OUTPUT cOrigem, OUTPUT cSerie, OUTPUT cNumero,
        OUTPUT cChave, OUTPUT plAplicavel, OUTPUT lResolvido, OUTPUT pcErro, OUTPUT pcMensagem).
    IF NOT lResolvido OR NOT plAplicavel THEN UNDO associacaoTransacao, LEAVE associacaoTransacao.
    RUN registrarVinculoRecebimento(INPUT prDocumento, INPUT iDocumento, INPUT phRastreio,
        OUTPUT lResolvido, OUTPUT iVinculo, OUTPUT pcErro, OUTPUT pcMensagem).
    IF NOT lResolvido THEN UNDO associacaoTransacao, LEAVE associacaoTransacao.
    RUN VALUE(cProcedimento) IN THIS-PROCEDURE(INPUT prDocumento, INPUT phRastreio,
        OUTPUT plAplicavel, OUTPUT plSucesso, OUTPUT plRepeticao, OUTPUT piEvento,
        OUTPUT piEtiquetas, OUTPUT pcErro, OUTPUT pcMensagem).
    IF NOT plSucesso OR NOT plAplicavel THEN DO:
        IF NOT plAplicavel THEN ASSIGN pcErro = "REC_NATUREZA_NAO_SUPORTADA"
            pcMensagem = "O servico nao processa a natureza desta entrada.".
        plSucesso = NO.
        UNDO associacaoTransacao, LEAVE associacaoTransacao.
    END.
END.
END PROCEDURE.

{fontes/progress/includes/contr-emb-retorno-origem.i}

PROCEDURE registrarVinculoRecebimento:
DEFINE INPUT PARAMETER prDocumento AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER piDocumentoSaida AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER phRastreio AS HANDLE NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piVinculo AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bRecDoc FOR mgmov.docum-est.
DEFINE BUFFER bRecOrigem FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRecNovo FOR mgesp.contr_emb_evento.
DEFINE VARIABLE cChaveDoc AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChave AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConteudo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSituacao AS CHARACTER NO-UNDO.
DEFINE VARIABLE iVersao AS INTEGER NO-UNDO.
DEFINE VARIABLE lRepeticao AS LOGICAL NO-UNDO.
ASSIGN plSucesso = NO piVinculo = 0 pcErro = "REC_VINCULO_INVALIDO" pcMensagem = "Origem do vinculo invalida.".
IF NOT VALID-HANDLE(phRastreio) OR NOT TRANSACTION THEN RETURN.
FIND FIRST bRecDoc NO-LOCK WHERE ROWID(bRecDoc) = prDocumento NO-ERROR.
FIND FIRST bRecOrigem NO-LOCK WHERE bRecOrigem.id-evento = piDocumentoSaida NO-ERROR.
IF NOT AVAILABLE bRecDoc OR NOT AVAILABLE bRecOrigem OR bRecOrigem.situacao <> "CONCLUIDO" THEN RETURN.
ASSIGN cChaveDoc = "ENTRADA|"
       + STRING(LENGTH(bRecDoc.cod-estabel)) + ":" + bRecDoc.cod-estabel
       + "|" + STRING(bRecDoc.cod-emitente)
       + "|" + STRING(LENGTH(bRecDoc.serie-docto)) + ":" + bRecDoc.serie-docto
       + "|" + STRING(LENGTH(bRecDoc.nro-docto)) + ":" + bRecDoc.nro-docto
       + "|" + bRecDoc.nat-operacao
       cChave = "VINCULO_ENTRADA_SAIDA|" + cChaveDoc
       cConteudo = cChave + "|DOCUMENTO_SAIDA=" + STRING(piDocumentoSaida)
       cUsuario = fRecTexto(bRecDoc.usuario).
IF cUsuario = "" THEN cUsuario = USERID("mgmov").
EMPTY TEMP-TABLE ttRecVinculoCmd.
CREATE ttRecVinculoCmd.
ASSIGN ttRecVinculoCmd.origem = "RECEBIMENTO"
       ttRecVinculoCmd.tipo-evento = "VINCULO_ENTRADA_SAIDA"
       ttRecVinculoCmd.chave-evento = cChave
       ttRecVinculoCmd.hash-chave = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cChave))
       ttRecVinculoCmd.hash-conteudo = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cConteudo))
       ttRecVinculoCmd.id-operacao = bRecOrigem.id-operacao
       ttRecVinculoCmd.id-evento-origem = piDocumentoSaida
       ttRecVinculoCmd.seq-ciclo = 1 ttRecVinculoCmd.dt-evento = NOW ttRecVinculoCmd.versao-contrato = 1
       ttRecVinculoCmd.tipo-docto = "ENTRADA" ttRecVinculoCmd.chave-docto = cChaveDoc
       ttRecVinculoCmd.hash-docto = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cChaveDoc))
       ttRecVinculoCmd.cod-estabel = bRecDoc.cod-estabel ttRecVinculoCmd.cod-emitente = bRecDoc.cod-emitente
       ttRecVinculoCmd.serie = bRecDoc.serie-docto ttRecVinculoCmd.nro-docto = bRecDoc.nro-docto
       ttRecVinculoCmd.nat-operacao = bRecDoc.nat-operacao ttRecVinculoCmd.dt-emissao = bRecDoc.dt-emissao
       ttRecVinculoCmd.chave-acesso = fRecTexto(bRecDoc.cod-chave-aces-nf-eletro)
       ttRecVinculoCmd.dados-evento = "v=1; documento-saida=" + STRING(piDocumentoSaida)
       ttRecVinculoCmd.usuario = cUsuario.
RUN registrarEvento IN phRastreio(INPUT TABLE ttRecVinculoCmd, INPUT YES,
    OUTPUT plSucesso, OUTPUT lRepeticao, OUTPUT piVinculo, OUTPUT cSituacao,
    OUTPUT iVersao, OUTPUT pcErro, OUTPUT pcMensagem).
IF NOT plSucesso THEN RETURN.
FIND FIRST bRecNovo EXCLUSIVE-LOCK WHERE bRecNovo.id-evento = piVinculo NO-ERROR.
IF NOT AVAILABLE bRecNovo OR bRecNovo.id-evento-origem <> piDocumentoSaida OR
   bRecNovo.id-operacao <> bRecOrigem.id-operacao THEN DO:
    ASSIGN plSucesso = NO pcErro = "REC_VINCULO_DIVERGENTE" pcMensagem = "Registro de vinculo inconsistente.".
    RETURN.
END.
IF NOT lRepeticao THEN ASSIGN bRecNovo.situacao = "CONCLUIDO" bRecNovo.dt-conclusao = NOW
    bRecNovo.resultado = "documento-saida=" + STRING(piDocumentoSaida)
    bRecNovo.dt-alteracao = NOW bRecNovo.versao = bRecNovo.versao + 1.
ELSE IF bRecNovo.situacao <> "CONCLUIDO" THEN ASSIGN plSucesso = NO
    pcErro = "REC_VINCULO_PENDENTE" pcMensagem = "O vinculo existente nao esta concluido.".
END PROCEDURE.

{fontes/progress/includes/contr-emb-armazenagem-origem.i}

