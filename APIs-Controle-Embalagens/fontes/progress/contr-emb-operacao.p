/* Operacoes de saida do Controle de Embalagens.
   O recorte de transferencia simples confirmou WT, nota, saida e reversao
   em TESTE; ciclos posteriores da mesma nota ainda exigem ensaio dirigido.
   E04: cada chamada do FT2100 representa UMA nota, mesmo quando o programa
   processa uma faixa. A nota deve ter sido criada pelo fluxo Fluig e ligada
   previamente a uma operacao/selecoes individuais. Nao altera estoque ERP. */
USING Progress.Json.ObjectModel.*.
{fontes/progress/contr-emb.i}
{fontes/progress/includes/contr-emb-confirmacao-comum.i}

/* Cache privado do modulo; limpo no inicio de cada consulta de origem. */
DEFINE TEMP-TABLE ttLimiteOrigem NO-UNDO
    FIELD sequencia AS INTEGER
    FIELD disponivel AS DECIMAL
    FIELD motivo AS CHARACTER
    INDEX pk IS PRIMARY UNIQUE sequencia.

/* DT115: transporte das capacidades existentes, sem executar hooks. */
{fontes/progress/includes/contr-emb-operacao-rest.i}

/* Direcionamento do modal pelo cadastro atual, sem codigos de natureza fixos.
   FT4011/FT4012 sao identificadores do ramo; nenhuma tela e aberta aqui.
   Sucesso significa classificacao, nao autorizacao ou criacao de documento.
   Revalidar no comando; natureza amigavel e validadores BO continuam exigidos. */
PROCEDURE classificarNaturezaOperacao:
DEFINE INPUT PARAMETER pcNatureza AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcFluxo AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcRamoPadrao AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plExigeOrigem AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plEditaQuantidade AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plEditaPreco AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.

DEFINE BUFFER bNaturezaFluxo FOR mgcad.natur-oper.
DEFINE VARIABLE cEspecie AS CHARACTER NO-UNDO.

ASSIGN pcFluxo = "" pcRamoPadrao = ""
       plExigeOrigem = NO plEditaQuantidade = NO plEditaPreco = NO
       plSucesso = NO pcErro = "PARAMETRO_INVALIDO".
IF pcNatureza = ? OR TRIM(pcNatureza) = "" THEN RETURN.
IF NOT CONNECTED("mgcad") THEN DO:
    pcErro = "BANCO_NAO_CONECTADO".
    RETURN.
END.
FIND FIRST bNaturezaFluxo
    WHERE bNaturezaFluxo.nat-operacao = TRIM(pcNatureza)
    NO-LOCK NO-ERROR.
IF NOT AVAILABLE bNaturezaFluxo THEN DO:
    pcErro = "NATUREZA_NAO_ENCONTRADA".
    RETURN.
END.
cEspecie = CAPS(TRIM(bNaturezaFluxo.especie-doc)).
pcErro = "NATUREZA_FORA_DOS_RAMOS_SUPORTADOS".
IF cEspecie = ? THEN RETURN.

/* A especie NFD tem prioridade, como esp-docto=20 no FT4003. */
IF cEspecie = "NFD" THEN
    ASSIGN pcFluxo = "DEVOLUCAO_COMPRA"
           pcRamoPadrao = "FT4011" plExigeOrigem = YES
           plEditaQuantidade = YES.
ELSE IF cEspecie = "NFS" OR cEspecie = "NFT" THEN DO:
    IF bNaturezaFluxo.terceiros = YES THEN DO:
        CASE bNaturezaFluxo.tp-oper-terc:
            WHEN 3 THEN
                ASSIGN pcFluxo = "REMESSA_TERCEIROS"
                       pcRamoPadrao = "DIRETO" plEditaQuantidade = YES.
            WHEN 2 THEN
                ASSIGN pcFluxo = "RETORNO_TERCEIROS"
                       pcRamoPadrao = "FT4012" plExigeOrigem = YES
                       plEditaQuantidade = YES.
            WHEN 4 THEN
                ASSIGN pcFluxo = "FATURAMENTO_CONSIGNACAO"
                       pcRamoPadrao = "FT4012" plExigeOrigem = YES
                       plEditaQuantidade = YES.
            WHEN 5 THEN
                ASSIGN pcFluxo = "RETORNO_TERCEIROS"
                       pcRamoPadrao = "FT4012" plExigeOrigem = YES
                       plEditaQuantidade = YES.
            WHEN 6 THEN
                ASSIGN pcFluxo = "REAJUSTE_TERCEIROS"
                       pcRamoPadrao = "FT4012" plExigeOrigem = YES
                       plEditaPreco = YES.
        END CASE.
    END.
    ELSE IF bNaturezaFluxo.terceiros = NO
        AND cEspecie = "NFT" AND bNaturezaFluxo.transf = YES THEN
        ASSIGN pcFluxo = "TRANSFERENCIA"
               pcRamoPadrao = "DIRETO" plEditaQuantidade = YES.
END.
IF pcRamoPadrao <> "" THEN
    ASSIGN plSucesso = YES pcErro = "".
END PROCEDURE.

/* Origem exata de entrada. Nao cria WT nem modifica dados funcionais. */
PROCEDURE consultarEmbalagensOrigem:
DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT PARAMETER pcEstabel AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcNatureza AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piEmitente AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcSerie AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcNumero AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcNaturezaOrigem AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piAposEtiqueta AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piLimite AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbOrigemDevolucao.
DEFINE OUTPUT PARAMETER piEventoOrigem AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plTemMais AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piProximaEtiqueta AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bOrigDoc FOR mgmov.docum-est.
DEFINE BUFFER bOrigLinha FOR mgmov.item-doc-est.
DEFINE BUFFER bOrigRateio FOR mgmov.rat-lote.
DEFINE BUFFER bOrigEvento FOR mgesp.contr_emb_evento.
DEFINE BUFFER bOrigMovto FOR mgesp.contr_emb_movto.
DEFINE BUFFER bOrigOutroMovto FOR mgesp.contr_emb_movto.
DEFINE BUFFER bOrigEtiqueta FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bOrigItemEvento FOR mgesp.contr_emb_evento_item.
DEFINE BUFFER bOrigNatureza FOR mgcad.natur-oper.
DEFINE BUFFER bOrigTerc FOR mgmov.saldo-terc.
DEFINE BUFFER bOrigComponente FOR mgmov.componente.
DEFINE BUFFER bOrigSaldo FOR mgmov.saldo-estoq.
DEFINE BUFFER bOrigReserva FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bOrigOper FOR mgesp.contr_emb_oper.
DEFINE VARIABLE cFluxo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cRamo AS CHARACTER NO-UNDO.
DEFINE VARIABLE lOrigem AS LOGICAL NO-UNDO.
DEFINE VARIABLE lQuantidade AS LOGICAL NO-UNDO.
DEFINE VARIABLE lPreco AS LOGICAL NO-UNDO.
DEFINE VARIABLE lOk AS LOGICAL NO-UNDO.
DEFINE VARIABLE lCompativel AS LOGICAL NO-UNDO.
DEFINE VARIABLE iSequencia AS INTEGER NO-UNDO.
DEFINE VARIABLE iVinculos AS INTEGER NO-UNDO.
DEFINE VARIABLE iLinhas AS INTEGER NO-UNDO.
DEFINE VARIABLE iSaldos AS INTEGER NO-UNDO.
DEFINE VARIABLE iTotal AS INTEGER NO-UNDO.
DEFINE VARIABLE dSaldo AS DECIMAL NO-UNDO.
DEFINE VARIABLE dLimite AS DECIMAL NO-UNDO.
DEFINE VARIABLE hSaldoCompra AS HANDLE NO-UNDO.

EMPTY TEMP-TABLE ttEmbOrigemDevolucao.
EMPTY TEMP-TABLE ttLimiteOrigem.
ASSIGN iTotal = 0 hSaldoCompra = ? piEventoOrigem = 0 plTemMais = NO piProximaEtiqueta = 0
       plSucesso = NO pcErro = "PARAMETRO_INVALIDO"
       pcMensagem = "Informe a chave completa da entrada e paginacao valida.".
IF pcEstabel = ? OR TRIM(pcEstabel) = "" OR
   piEmitente = ? OR piEmitente <= 0 OR
   pcSerie = ? OR TRIM(pcSerie) = "" OR
   pcNumero = ? OR TRIM(pcNumero) = "" OR
   pcNaturezaOrigem = ? OR TRIM(pcNaturezaOrigem) = "" OR
   piAposEtiqueta = ? OR piAposEtiqueta < 0 OR
   piLimite = ? OR piLimite < 1 OR piLimite > 100 THEN RETURN.
IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido
    WHERE ttEmbEstabelPermitido.cod-estabel = TRIM(pcEstabel)) THEN DO:
    ASSIGN pcErro = "SEM_PERMISSAO" pcMensagem = "Estabelecimento nao autorizado.".
    RETURN.
END.
IF NOT CONNECTED("mgcad") OR NOT CONNECTED("mgmov") OR NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_NAO_CONECTADO" pcMensagem = "Bancos necessarios nao conectados.".
    RETURN.
END.
RUN classificarNaturezaOperacao(INPUT pcNatureza, OUTPUT cFluxo, OUTPUT cRamo,
    OUTPUT lOrigem, OUTPUT lQuantidade, OUTPUT lPreco, OUTPUT lOk, OUTPUT pcErro).
IF NOT lOk THEN DO:
    pcMensagem = "Natureza de saida nao suportada para esta consulta.".
    RETURN.
END.
IF cFluxo <> "DEVOLUCAO_COMPRA" AND cFluxo <> "RETORNO_TERCEIROS" THEN DO:
    ASSIGN pcErro = "FLUXO_NAO_EXIGE_ESTA_ORIGEM"
           pcMensagem = "Esta consulta atende devolucao de compra e retorno com origem de entrada.".
    RETURN.
END.

DO ON ERROR UNDO, THROW:
    FIND FIRST bOrigDoc NO-LOCK
        WHERE bOrigDoc.cod-estabel = TRIM(pcEstabel)
          AND bOrigDoc.cod-emitente = piEmitente
          AND bOrigDoc.serie-docto = TRIM(pcSerie)
          AND bOrigDoc.nro-docto = TRIM(pcNumero)
          AND bOrigDoc.nat-operacao = TRIM(pcNaturezaOrigem) NO-ERROR.
    IF NOT AVAILABLE bOrigDoc THEN DO:
        ASSIGN pcErro = "ORIGEM_NAO_ENCONTRADA" pcMensagem = "Entrada de origem nao encontrada.".
        RETURN.
    END.
    IF bOrigDoc.ce-atual <> YES OR bOrigDoc.ce-atual = ? THEN DO:
        ASSIGN pcErro = "ORIGEM_NAO_ATUALIZADA" pcMensagem = "Entrada de origem nao esta atualizada.".
        RETURN.
    END.
    IF cRamo = "FT4012" THEN DO:
        FIND FIRST bOrigNatureza NO-LOCK
            WHERE bOrigNatureza.nat-operacao = bOrigDoc.nat-operacao NO-ERROR.
        IF NOT AVAILABLE bOrigNatureza THEN DO:
            ASSIGN pcErro = "NATUREZA_ORIGEM_NAO_ENCONTRADA" pcMensagem = "Natureza da origem nao cadastrada.".
            RETURN.
        END.
        IF bOrigNatureza.terceiros <> YES OR bOrigNatureza.terceiros = ?
            OR bOrigNatureza.tp-oper-terc <> 3 OR bOrigNatureza.tp-oper-terc = ? THEN DO:
            ASSIGN pcErro = "ORIGEM_FORA_DO_RECORTE"
                   pcMensagem = "Retorno exige entrada de terceiros do recorte de emprestimo.".
            RETURN.
        END.
    END.
    FOR EACH bOrigEvento NO-LOCK
        WHERE bOrigEvento.tipo-docto = "ENTRADA"
          AND bOrigEvento.tipo-evento <> "VINCULO_ENTRADA_SAIDA"
          AND bOrigEvento.cod-estabel = bOrigDoc.cod-estabel
          AND bOrigEvento.cod-emitente = bOrigDoc.cod-emitente
          AND bOrigEvento.serie = bOrigDoc.serie-docto
          AND bOrigEvento.nro-docto = bOrigDoc.nro-docto
          AND bOrigEvento.nat-operacao = bOrigDoc.nat-operacao
        BY bOrigEvento.seq-ciclo DESCENDING BY bOrigEvento.id-evento DESCENDING:
        piEventoOrigem = bOrigEvento.id-evento.
        LEAVE.
    END.
    IF piEventoOrigem = 0 THEN DO:
        ASSIGN pcErro = "ORIGEM_SEM_RASTREIO" pcMensagem = "Entrada sem evento de embalagens vinculado.".
        RETURN.
    END.
    FIND FIRST bOrigEvento NO-LOCK WHERE bOrigEvento.id-evento = piEventoOrigem NO-ERROR.
    IF bOrigEvento.situacao <> "CONCLUIDO"
        OR NOT (bOrigEvento.tipo-evento BEGINS "RECEBIMENTO_") THEN DO:
        ASSIGN pcErro = "ORIGEM_SEM_ENTRADA_CONFIRMADA"
               pcMensagem = "Ultimo ciclo da origem nao e um recebimento concluido.".
        RETURN.
    END.
    IF cRamo = "FT4011" AND bOrigEvento.tipo-evento <> "RECEBIMENTO_COMPRA" THEN DO:
        ASSIGN pcErro = "ORIGEM_NAO_E_COMPRA" pcMensagem = "Origem nao corresponde a recebimento de compra.".
        RETURN.
    END.
    FOR EACH bOrigMovto NO-LOCK
        WHERE bOrigMovto.id-evento = piEventoOrigem
          AND bOrigMovto.id-etiqueta > piAposEtiqueta
          AND bOrigMovto.cod-estabel-dest = bOrigDoc.cod-estabel
          AND bOrigMovto.tipo-local-dest = "ESTAB"
        BY bOrigMovto.id-etiqueta:
        IF iTotal >= piLimite THEN DO:
            plTemMais = YES.
            LEAVE.
        END.
        IF CAN-FIND(FIRST bOrigOutroMovto NO-LOCK
            WHERE bOrigOutroMovto.id-evento = piEventoOrigem
              AND bOrigOutroMovto.id-etiqueta = bOrigMovto.id-etiqueta
              AND bOrigOutroMovto.id-movto <> bOrigMovto.id-movto) THEN
            UNDO, THROW NEW Progress.Lang.AppError("Vinculo ambiguo na origem.",0).
        FIND FIRST bOrigEtiqueta NO-LOCK
            WHERE bOrigEtiqueta.id-etiqueta = bOrigMovto.id-etiqueta NO-ERROR.
        IF NOT AVAILABLE bOrigEtiqueta THEN
            UNDO, THROW NEW Progress.Lang.AppError("Etiqueta de origem ausente.",0).
        CREATE ttEmbOrigemDevolucao.
        ASSIGN ttEmbOrigemDevolucao.id-etiqueta = bOrigEtiqueta.id-etiqueta
               ttEmbOrigemDevolucao.cod-etiqueta = bOrigEtiqueta.cod-etiqueta
               ttEmbOrigemDevolucao.id-evento-origem = piEventoOrigem
               ttEmbOrigemDevolucao.id-movto-origem = bOrigMovto.id-movto
               ttEmbOrigemDevolucao.it-codigo = bOrigEtiqueta.it-codigo
               ttEmbOrigemDevolucao.lote = bOrigEtiqueta.lote
               ttEmbOrigemDevolucao.dt-vali-lote = bOrigEtiqueta.dt-vali-lote
               ttEmbOrigemDevolucao.un = bOrigEtiqueta.un
               ttEmbOrigemDevolucao.cod-depos = bOrigMovto.cod-depos-dest
               ttEmbOrigemDevolucao.cod-localiz = bOrigMovto.cod-localiz-dest
               ttEmbOrigemDevolucao.quantidade-origem = bOrigMovto.quantidade
               ttEmbOrigemDevolucao.quantidade-atual = ?
               ttEmbOrigemDevolucao.versao-etiqueta = ?
               ttEmbOrigemDevolucao.pode-selecionar = NO
               ttEmbOrigemDevolucao.motivo = "LINHA_ORIGEM_NAO_IDENTIFICADA"
               iLinhas = 0 iSequencia = 0 iVinculos = 0.
        /* O item do evento e o elo preferencial; nao usar o item de nascimento
           para identificar automaticamente uma entrada posterior. */
        IF bOrigMovto.id-item-evento <> ? AND bOrigMovto.id-item-evento > 0 THEN DO:
            FIND FIRST bOrigItemEvento NO-LOCK
                WHERE bOrigItemEvento.id-item-evento = bOrigMovto.id-item-evento
                  AND bOrigItemEvento.id-evento = piEventoOrigem NO-ERROR.
            iVinculos = IF AVAILABLE bOrigItemEvento THEN bOrigItemEvento.sequencia ELSE -1.
        END.
        FOR EACH bOrigLinha OF bOrigDoc NO-LOCK
            WHERE bOrigLinha.it-codigo = bOrigEtiqueta.it-codigo
              AND (iVinculos = 0 OR bOrigLinha.sequencia = iVinculos):
            lCompativel = NO.
            FOR EACH bOrigRateio OF bOrigLinha NO-LOCK
                WHERE bOrigRateio.lote = bOrigEtiqueta.lote
                  AND bOrigRateio.dt-vali-lote = bOrigEtiqueta.dt-vali-lote:
                lCompativel = YES.
                LEAVE.
            END.
            IF NOT CAN-FIND(FIRST bOrigRateio OF bOrigLinha NO-LOCK) THEN
                lCompativel = bOrigLinha.lote = bOrigEtiqueta.lote
                    AND bOrigLinha.dt-vali-lote = bOrigEtiqueta.dt-vali-lote.
            IF lCompativel THEN
                ASSIGN iLinhas = iLinhas + 1 iSequencia = bOrigLinha.sequencia.
        END.
        IF iLinhas <> 1 THEN DO:
            IF iLinhas > 1 THEN ttEmbOrigemDevolucao.motivo = "LINHA_ORIGEM_AMBIGUA".
        END.
        ELSE DO:
            ttEmbOrigemDevolucao.sequencia-origem = iSequencia.
            FIND FIRST bOrigLinha OF bOrigDoc NO-LOCK
                WHERE bOrigLinha.sequencia = iSequencia NO-ERROR.
            FIND FIRST ttLimiteOrigem WHERE ttLimiteOrigem.sequencia = iSequencia NO-ERROR.
            IF NOT AVAILABLE ttLimiteOrigem THEN DO:
                CREATE ttLimiteOrigem.
                ttLimiteOrigem.sequencia = iSequencia.
                IF bOrigLinha.un <> bOrigEtiqueta.un OR bOrigLinha.un = ? THEN
                    ttLimiteOrigem.motivo = "UNIDADE_ORIGEM_DIVERGENTE".
                ELSE IF cRamo = "FT4011" THEN DO:
                    IF NOT VALID-HANDLE(hSaldoCompra) THEN
                        RUN inbo/boin672.p PERSISTENT SET hSaldoCompra.
                    dLimite = ?.
                    RUN calculaSaldoDevolver IN hSaldoCompra
                        (INPUT bOrigLinha.serie-docto, INPUT bOrigLinha.nro-docto,
                         INPUT bOrigLinha.cod-emitente, INPUT bOrigLinha.nat-operacao,
                         INPUT bOrigLinha.sequencia, OUTPUT dLimite).
                    IF dLimite = ? OR dLimite < 0 THEN
                        UNDO, THROW NEW Progress.Lang.AppError("Saldo documental invalido.",0).
                    ttLimiteOrigem.disponivel = dLimite.
                END.
                ELSE DO:
                    iSaldos = 0.
                    FOR EACH bOrigTerc NO-LOCK
                        WHERE bOrigTerc.cod-estabel = bOrigDoc.cod-estabel
                          AND bOrigTerc.cod-emitente = bOrigDoc.cod-emitente
                          AND bOrigTerc.serie-docto = bOrigDoc.serie-docto
                          AND bOrigTerc.nro-docto = bOrigDoc.nro-docto
                          AND bOrigTerc.nat-operacao = bOrigDoc.nat-operacao
                          AND bOrigTerc.sequencia = iSequencia
                          AND bOrigTerc.it-codigo = bOrigEtiqueta.it-codigo:
                        iSaldos = iSaldos + 1.
                        IF bOrigTerc.quantidade = ? OR bOrigTerc.dec-1 = ? THEN
                            ttLimiteOrigem.motivo = "SALDO_TERCEIROS_DESCONHECIDO".
                        ELSE ttLimiteOrigem.disponivel = bOrigTerc.quantidade - bOrigTerc.dec-1.
                    END.
                    IF iSaldos > 1 THEN ttLimiteOrigem.motivo = "SALDO_TERCEIROS_AMBIGUO".
                    IF NOT CAN-FIND(FIRST bOrigComponente NO-LOCK
                        WHERE bOrigComponente.cod-emitente = bOrigDoc.cod-emitente
                          AND bOrigComponente.serie-docto = bOrigDoc.serie-docto
                          AND bOrigComponente.nro-docto = bOrigDoc.nro-docto
                          AND bOrigComponente.nat-operacao = bOrigDoc.nat-operacao
                          AND bOrigComponente.sequencia = iSequencia
                          AND bOrigComponente.it-codigo = bOrigEtiqueta.it-codigo) THEN
                        ttLimiteOrigem.motivo = "COMPONENTE_ORIGEM_NAO_ENCONTRADO".
                END.
            END.
            ASSIGN ttEmbOrigemDevolucao.disponivel-linha = ttLimiteOrigem.disponivel
                   ttEmbOrigemDevolucao.motivo = ttLimiteOrigem.motivo.
            IF bOrigEtiqueta.cod-estabel = ? OR bOrigEtiqueta.cod-estabel <> bOrigDoc.cod-estabel THEN
                ttEmbOrigemDevolucao.motivo = "ETIQUETA_FORA_DO_ESTABELECIMENTO".
            ELSE DO:
                ASSIGN ttEmbOrigemDevolucao.quantidade-atual = bOrigEtiqueta.qtidade-atu
                       ttEmbOrigemDevolucao.versao-etiqueta = bOrigEtiqueta.versao
                       ttEmbOrigemDevolucao.cod-depos = bOrigEtiqueta.cod-depos
                       ttEmbOrigemDevolucao.cod-localiz = bOrigEtiqueta.cod-localiz.
                IF ttEmbOrigemDevolucao.motivo = "" THEN DO:
                    IF bOrigEtiqueta.tipo-controle = ? OR bOrigEtiqueta.tipo-controle <> "EMBALAGEM"
                       OR bOrigEtiqueta.situacao = ? OR bOrigEtiqueta.situacao <> "ATIVA"
                       OR bOrigEtiqueta.tipo-local = ? OR bOrigEtiqueta.tipo-local <> "ESTAB"
                       OR bOrigEtiqueta.un = ? OR bOrigEtiqueta.un <> bOrigLinha.un
                       OR bOrigMovto.quantidade = ? OR bOrigMovto.quantidade <= 0
                       OR bOrigEtiqueta.id-bag <> ? OR bOrigEtiqueta.qtidade-atu = ?
                       OR bOrigEtiqueta.qtidade-atu <= 0
                       OR bOrigEtiqueta.qtidade-atu > bOrigMovto.quantidade THEN
                        ttEmbOrigemDevolucao.motivo = "ETIQUETA_INDISPONIVEL".
                    ELSE IF ttLimiteOrigem.disponivel < bOrigEtiqueta.qtidade-atu THEN
                        ttEmbOrigemDevolucao.motivo = "SALDO_DOCUMENTAL_INSUFICIENTE".
                    ELSE DO:
                        dSaldo = 0.
                        FOR EACH bOrigSaldo NO-LOCK
                            WHERE bOrigSaldo.cod-estab = bOrigDoc.cod-estabel
                              AND bOrigSaldo.it-codigo = bOrigEtiqueta.it-codigo
                              AND bOrigSaldo.lote = bOrigEtiqueta.lote
                              AND bOrigSaldo.dt-vali-lote = bOrigEtiqueta.dt-vali-lote
                              AND bOrigSaldo.cod-depos = bOrigEtiqueta.cod-depos
                              AND bOrigSaldo.cod-localiz = bOrigEtiqueta.cod-localiz:
                            dSaldo = dSaldo + bOrigSaldo.qtidade-atu.
                        END.
                        IF dSaldo = ? OR dSaldo < bOrigEtiqueta.qtidade-atu THEN
                            ttEmbOrigemDevolucao.motivo = "SALDO_ESTOQUE_INSUFICIENTE".
                        FOR EACH bOrigReserva NO-LOCK
                            WHERE bOrigReserva.id-etiqueta = bOrigEtiqueta.id-etiqueta
                              AND bOrigReserva.tipo-item = "SOLICITACAO":
                            FIND FIRST bOrigOper NO-LOCK
                                WHERE bOrigOper.id-operacao = bOrigReserva.id-operacao NO-ERROR.
                            IF AVAILABLE bOrigOper AND
                                LOOKUP(bOrigOper.situacao,"RASCUNHO,SOLICITADA,EM_EXECUCAO") > 0 THEN
                                ttEmbOrigemDevolucao.motivo = "ETIQUETA_RESERVADA".
                        END.
                    END.
                END.
                ttEmbOrigemDevolucao.pode-selecionar = ttEmbOrigemDevolucao.motivo = "".
            END.
        END.
        ASSIGN iTotal = iTotal + 1 piProximaEtiqueta = bOrigEtiqueta.id-etiqueta.
    END.
    IF NOT plTemMais THEN piProximaEtiqueta = 0.
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    CATCH eOrigem AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbOrigemDevolucao.
        ASSIGN plSucesso = NO plTemMais = NO piProximaEtiqueta = 0
               pcErro = "FALHA_CONSULTA_ORIGEM"
               pcMensagem = "Nao foi possivel conferir os vinculos ou o saldo padrao da origem.".
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hSaldoCompra) THEN DELETE PROCEDURE hSaldoCompra NO-ERROR.
    END FINALLY.
END.
END PROCEDURE.

/* Gravar na nota gerada o documento de trabalho que a originou.
   Chamar no fluxo que ainda possui i-seq-wt-docto e ROWID da nota.
   O slot versionado ocupa apenas char-2[1500..1519]. */
PROCEDURE gravarWtDoctoNaNota:
DEFINE INPUT PARAMETER prNota AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER piSeqWtDocto AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.

DEFINE BUFFER bNotaWt FOR mgmov.nota-fiscal.
DEFINE VARIABLE cAtual AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMarca AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSlot AS CHARACTER NO-UNDO.

ASSIGN plSucesso = NO plRepeticao = NO pcErro = "PARAMETRO_INVALIDO".
IF prNota = ? OR piSeqWtDocto = ? OR piSeqWtDocto <= 0 THEN RETURN.
IF NOT CONNECTED("mgmov") THEN DO:
    pcErro = "BANCO_NAO_CONECTADO".
    RETURN.
END.

ASSIGN cMarca = "CEWT1:" + STRING(piSeqWtDocto).
IF LENGTH(cMarca) > 20 THEN DO:
    pcErro = "WT_DOCTO_FORA_DA_FAIXA".
    RETURN.
END.
cMarca = cMarca + FILL(" ", 20 - LENGTH(cMarca)).

DO TRANSACTION ON ERROR UNDO, THROW:
    FIND FIRST bNotaWt WHERE ROWID(bNotaWt) = prNota
        EXCLUSIVE-LOCK NO-ERROR.
    IF NOT AVAILABLE bNotaWt THEN DO:
        pcErro = "NOTA_NAO_ENCONTRADA".
        RETURN.
    END.

    cAtual = IF bNotaWt.char-2 = ? THEN "" ELSE bNotaWt.char-2.
    IF LENGTH(cAtual) < 1519 THEN
        cAtual = cAtual + FILL(" ", 1519 - LENGTH(cAtual)).
    cSlot = SUBSTRING(cAtual, 1500, 20).

    IF cSlot = cMarca THEN DO:
        ASSIGN plSucesso = YES plRepeticao = YES pcErro = "".
        RETURN.
    END.
    IF TRIM(cSlot) <> "" THEN DO:
        pcErro = "FAIXA_NOTA_OCUPADA".
        RETURN.
    END.

    bNotaWt.char-2 = SUBSTRING(cAtual, 1, 1499)
                     + cMarca
                     + SUBSTRING(cAtual, 1520).
    ASSIGN plSucesso = YES pcErro = "".
END.
END PROCEDURE.

/* Associar a operacao ao WT somente depois do retorno positivo da BODI317. */
PROCEDURE vincularWtDoctoOperacao:
DEFINE INPUT PARAMETER piOperacao AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piSeqWtDocto AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcUsuario AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.

DEFINE BUFFER bOperWt FOR mgesp.contr_emb_oper.
DEFINE BUFFER bOutraOperWt FOR mgesp.contr_emb_oper.

ASSIGN plSucesso = NO plRepeticao = NO pcErro = "PARAMETRO_INVALIDO".
IF piOperacao = ? OR piOperacao <= 0 OR piSeqWtDocto = ? OR
   piSeqWtDocto <= 0 OR pcUsuario = ? OR TRIM(pcUsuario) = "" THEN RETURN.
IF NOT CONNECTED("mgesp") THEN DO:
    pcErro = "BANCO_NAO_CONECTADO".
    RETURN.
END.

DO TRANSACTION ON ERROR UNDO, THROW:
    FIND FIRST bOperWt WHERE bOperWt.id-operacao = piOperacao
        EXCLUSIVE-LOCK NO-ERROR.
    IF NOT AVAILABLE bOperWt THEN DO:
        pcErro = "OPERACAO_NAO_ENCONTRADA".
        RETURN.
    END.
    IF bOperWt.seq-wt-docto = piSeqWtDocto THEN DO:
        ASSIGN plSucesso = YES plRepeticao = YES pcErro = "".
        RETURN.
    END.
    IF bOperWt.seq-wt-docto <> ? THEN DO:
        pcErro = "OPERACAO_JA_POSSUI_WT".
        RETURN.
    END.
    IF CAN-FIND(FIRST bOutraOperWt NO-LOCK
        WHERE bOutraOperWt.seq-wt-docto = piSeqWtDocto
          AND bOutraOperWt.id-operacao <> piOperacao
        USE-INDEX pk) THEN DO:
        pcErro = "WT_JA_VINCULADO".
        RETURN.
    END.
    ASSIGN bOperWt.seq-wt-docto = piSeqWtDocto
           bOperWt.dt-alteracao = NOW
           bOperWt.usuario-alteracao = TRIM(pcUsuario)
           bOperWt.versao = bOperWt.versao + 1
           plSucesso = YES pcErro = "".
END.
END PROCEDURE.

/* Chamar na PI que criou o documento, depois de criaWtDocto confirmar o WT.
   A PI deve manter a mesma transacao da BO ate esta procedure retornar.
   Nenhuma linha e persistida se a selecao ou o WT forem invalidos. */
PROCEDURE registrarSelecaoAposWt:
DEFINE INPUT PARAMETER piSeqWtDocto AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcEstabelOrig AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcEstabelDest AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piEmitente AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcUsuario AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER TABLE FOR ttEmbSelecaoSaida.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piOperacao AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.

DEFINE BUFFER bWtSelecao FOR mgcad.wt-docto.
DEFINE BUFFER bEstabelOrig FOR mgcad.estabelec.
DEFINE BUFFER bEstabelDest FOR mgcad.estabelec.
DEFINE BUFFER bOperSelecao FOR mgesp.contr_emb_oper.
DEFINE BUFFER bOperAnterior FOR mgesp.contr_emb_oper.
DEFINE BUFFER bLinhaSelecao FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bLinhaAnterior FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bEtiquetaSelecao FOR mgesp.contr_emb_etiqueta.
DEFINE VARIABLE iLinhas AS INTEGER NO-UNDO.
DEFINE VARIABLE iLinhasGravadas AS INTEGER NO-UNDO.
DEFINE VARIABLE iUltimaEtiqueta AS INTEGER NO-UNDO.
DEFINE VARIABLE iSequencia AS INTEGER NO-UNDO.
DEFINE VARIABLE dtAgora AS DATETIME-TZ NO-UNDO.

ASSIGN plSucesso = NO plRepeticao = NO piOperacao = 0
       pcErro = "PARAMETRO_INVALIDO".
IF piSeqWtDocto = ? OR piSeqWtDocto <= 0 OR
   pcEstabelOrig = ? OR TRIM(pcEstabelOrig) = "" OR
   pcEstabelDest = ? OR TRIM(pcEstabelDest) = "" OR
   pcEstabelOrig = pcEstabelDest OR
   pcUsuario = ? OR TRIM(pcUsuario) = "" THEN RETURN.
IF NOT CONNECTED("mgmov") OR NOT CONNECTED("mgesp") OR
   NOT CONNECTED("mgcad") THEN DO:
    pcErro = "BANCO_NAO_CONECTADO".
    RETURN.
END.
FIND FIRST bWtSelecao NO-LOCK
    WHERE bWtSelecao.seq-wt-docto = piSeqWtDocto NO-ERROR.
IF NOT AVAILABLE bWtSelecao THEN DO:
    pcErro = "WT_NAO_ENCONTRADO".
    RETURN.
END.
FIND FIRST bEstabelOrig NO-LOCK
    WHERE bEstabelOrig.cod-estabel = pcEstabelOrig NO-ERROR.
FIND FIRST bEstabelDest NO-LOCK
    WHERE bEstabelDest.cod-estabel = pcEstabelDest NO-ERROR.
IF NOT AVAILABLE bEstabelOrig OR NOT AVAILABLE bEstabelDest THEN DO:
    pcErro = "ESTABELECIMENTO_NAO_ENCONTRADO".
    RETURN.
END.

/* A tabela de entrada nao e unica: duplicacao deve ser recusada explicitamente. */
ASSIGN iUltimaEtiqueta = 0 pcErro = "SELECAO_INVALIDA".
FOR EACH ttEmbSelecaoSaida BY ttEmbSelecaoSaida.id-etiqueta:
    IF ttEmbSelecaoSaida.id-etiqueta = ? OR
       ttEmbSelecaoSaida.id-etiqueta <= 0 OR
       ttEmbSelecaoSaida.quantidade = ? OR
       ttEmbSelecaoSaida.quantidade <= 0 THEN RETURN.
    IF ttEmbSelecaoSaida.id-etiqueta = iUltimaEtiqueta THEN DO:
        pcErro = "ETIQUETA_DUPLICADA".
        RETURN.
    END.
    ASSIGN iUltimaEtiqueta = ttEmbSelecaoSaida.id-etiqueta
           iLinhas = iLinhas + 1.
END.
IF iLinhas = 0 THEN DO:
    pcErro = "SELECAO_VAZIA".
    RETURN.
END.

/* Uma resposta perdida pode repetir o mesmo WT; comparar a selecao inteira. */
FIND FIRST bOperSelecao NO-LOCK
    WHERE bOperSelecao.seq-wt-docto = piSeqWtDocto
    USE-INDEX pk NO-ERROR.
IF AVAILABLE bOperSelecao THEN DO:
    ASSIGN pcErro = "WT_JA_VINCULADO"
           piOperacao = bOperSelecao.id-operacao.
    IF bOperSelecao.tipo-operacao <> "TRANSFERENCIA" OR
       bOperSelecao.situacao = "CANCELADA" OR
       bOperSelecao.cod-estabel-orig <> pcEstabelOrig OR
       bOperSelecao.cod-estabel-dest <> pcEstabelDest OR
       bOperSelecao.cod-emitente <> piEmitente THEN RETURN.
    FOR EACH bLinhaSelecao NO-LOCK
        WHERE bLinhaSelecao.id-operacao = piOperacao
          AND bLinhaSelecao.tipo-item = "SOLICITACAO":
        iLinhasGravadas = iLinhasGravadas + 1.
        FIND FIRST ttEmbSelecaoSaida
            WHERE ttEmbSelecaoSaida.id-etiqueta = bLinhaSelecao.id-etiqueta
              AND ttEmbSelecaoSaida.quantidade = bLinhaSelecao.quantidade
            NO-ERROR.
        IF NOT AVAILABLE ttEmbSelecaoSaida THEN RETURN.
    END.
    IF iLinhasGravadas <> iLinhas THEN RETURN.
    ASSIGN plSucesso = YES plRepeticao = YES pcErro = "".
    RETURN.
END.

selecaoTransacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    /* Bloqueio das etiquetas serializa duas selecoes concorrentes. */
    FOR EACH ttEmbSelecaoSaida BY ttEmbSelecaoSaida.id-etiqueta:
        FIND FIRST bEtiquetaSelecao EXCLUSIVE-LOCK
            WHERE bEtiquetaSelecao.id-etiqueta = ttEmbSelecaoSaida.id-etiqueta
            NO-WAIT NO-ERROR.
        IF LOCKED bEtiquetaSelecao THEN DO:
            pcErro = "ETIQUETA_BLOQUEADA".
            UNDO selecaoTransacao, LEAVE selecaoTransacao.
        END.
        IF NOT AVAILABLE bEtiquetaSelecao THEN DO:
            pcErro = "ETIQUETA_NAO_ENCONTRADA".
            UNDO selecaoTransacao, LEAVE selecaoTransacao.
        END.
        IF bEtiquetaSelecao.tipo-controle <> "EMBALAGEM" OR
           bEtiquetaSelecao.situacao <> "ATIVA" OR
           bEtiquetaSelecao.tipo-local <> "ESTAB" OR
           bEtiquetaSelecao.cod-estabel <> pcEstabelOrig OR
           bEtiquetaSelecao.id-bag <> ? OR
           bEtiquetaSelecao.qtidade-atu <> ttEmbSelecaoSaida.quantidade THEN DO:
            pcErro = "ETIQUETA_INDISPONIVEL".
            UNDO selecaoTransacao, LEAVE selecaoTransacao.
        END.
        IF fEmReservaAtiva(ttEmbSelecaoSaida.id-etiqueta) THEN DO:
            pcErro = "ETIQUETA_JA_SELECIONADA".
            UNDO selecaoTransacao, LEAVE selecaoTransacao.
        END.
    END.

    ASSIGN dtAgora = NOW
           piOperacao = NEXT-VALUE(CONTR_EMB_OPER_ID_SEQ, mgesp).
    CREATE bOperSelecao.
    ASSIGN bOperSelecao.id-operacao = piOperacao
           bOperSelecao.seq-wt-docto = piSeqWtDocto
           bOperSelecao.tipo-operacao = "TRANSFERENCIA"
           bOperSelecao.cod-estabel-orig = pcEstabelOrig
           bOperSelecao.cod-estabel-dest = pcEstabelDest
           bOperSelecao.cod-emitente = piEmitente
           bOperSelecao.situacao = "SOLICITADA"
           bOperSelecao.dt-operacao = dtAgora
           bOperSelecao.dt-inclusao = dtAgora
           bOperSelecao.usuario-inclusao = TRIM(pcUsuario)
           bOperSelecao.dt-alteracao = dtAgora
           bOperSelecao.usuario-alteracao = TRIM(pcUsuario)
           bOperSelecao.versao = 1.
    FOR EACH ttEmbSelecaoSaida BY ttEmbSelecaoSaida.id-etiqueta:
        FIND FIRST bEtiquetaSelecao NO-LOCK
            WHERE bEtiquetaSelecao.id-etiqueta = ttEmbSelecaoSaida.id-etiqueta
            NO-ERROR.
        ASSIGN iSequencia = iSequencia + 1.
        CREATE bLinhaSelecao.
        ASSIGN bLinhaSelecao.id-item-oper =
                   NEXT-VALUE(CONTR_EMB_OPER_ITEM_ID_SEQ, mgesp)
               bLinhaSelecao.id-operacao = piOperacao
               bLinhaSelecao.sequencia = iSequencia
               bLinhaSelecao.id-etiqueta = ttEmbSelecaoSaida.id-etiqueta
               bLinhaSelecao.it-codigo = bEtiquetaSelecao.it-codigo
               bLinhaSelecao.un = bEtiquetaSelecao.un
               bLinhaSelecao.quantidade = ttEmbSelecaoSaida.quantidade
               bLinhaSelecao.lote = bEtiquetaSelecao.lote
               bLinhaSelecao.dt-vali-lote = bEtiquetaSelecao.dt-vali-lote
               bLinhaSelecao.cod-tipo = bEtiquetaSelecao.cod-tipo
               bLinhaSelecao.tipo-item = "SOLICITACAO"
               bLinhaSelecao.dt-inclusao = dtAgora
               bLinhaSelecao.usuario-inclusao = TRIM(pcUsuario)
               bLinhaSelecao.dt-alteracao = dtAgora
               bLinhaSelecao.usuario-alteracao = TRIM(pcUsuario)
               bLinhaSelecao.versao = 1.
    END.
    ASSIGN plSucesso = YES pcErro = "".
END.
IF NOT plSucesso THEN piOperacao = 0.
END PROCEDURE.

/* Entrada para o ponto de efetivacao que entrega WT e ROWID da nota. */
PROCEDURE vincularNotaPorWt:
DEFINE INPUT PARAMETER piSeqWtDocto AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER prNota AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER pcUsuario AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER phRastreio AS HANDLE NO-UNDO.
DEFINE OUTPUT PARAMETER plAplicavel AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piIdEvento AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.

DEFINE BUFFER bOperPorWt FOR mgesp.contr_emb_oper.
DEFINE VARIABLE iOperacoes AS INTEGER NO-UNDO.
DEFINE VARIABLE iOperacao AS INTEGER NO-UNDO.

ASSIGN plAplicavel = NO plSucesso = NO plRepeticao = NO
       piIdEvento = 0 pcErro = "PARAMETRO_INVALIDO" pcMensagem = "".
IF piSeqWtDocto = ? OR piSeqWtDocto <= 0 OR prNota = ? OR
   pcUsuario = ? OR TRIM(pcUsuario) = "" OR
   NOT VALID-HANDLE(phRastreio) THEN RETURN.
IF NOT CONNECTED("mgesp") THEN DO:
    pcErro = "BANCO_NAO_CONECTADO".
    RETURN.
END.
FOR EACH bOperPorWt NO-LOCK
    WHERE bOperPorWt.seq-wt-docto = piSeqWtDocto
    USE-INDEX pk:
    ASSIGN iOperacoes = iOperacoes + 1
           iOperacao = bOperPorWt.id-operacao.
END.
IF iOperacoes = 0 THEN DO:
    ASSIGN plSucesso = YES pcErro = "".
    RETURN.
END.
ASSIGN plAplicavel = YES pcErro = "WT_AMBIGUO".
IF iOperacoes <> 1 THEN RETURN.
RUN vincularNotaSaidaFluig (INPUT iOperacao, INPUT prNota,
    INPUT pcUsuario, INPUT phRastreio,
    OUTPUT plSucesso, OUTPUT plRepeticao, OUTPUT piIdEvento,
    OUTPUT pcErro, OUTPUT pcMensagem).
END PROCEDURE.

PROCEDURE vincularNotaSaidaFluig:
/* Chamar pelo produtor da nota DEPOIS que a BO disponibilizar a identidade
   e ANTES de qualquer atualizacao automatica de estoque. Nao cria nota. */
DEFINE INPUT PARAMETER piOperacao AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER prNota AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER pcUsuario AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER phRastreio AS HANDLE NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piIdEvento AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.

DEFINE BUFFER bNota FOR mgmov.nota-fiscal.
DEFINE BUFFER bOper FOR mgesp.contr_emb_oper.
DEFINE BUFFER bItem FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bItemDuplicado FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bEtiqueta FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bDocumento FOR mgesp.contr_emb_evento.
DEFINE VARIABLE cDocumento AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChave AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDigest AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSerie AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSituacao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErroNucleo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMsgNucleo AS CHARACTER NO-UNDO.
DEFINE VARIABLE iLinhas AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersao AS INTEGER NO-UNDO.
DEFINE VARIABLE lNucleo AS LOGICAL NO-UNDO.
DEFINE VARIABLE lRepNucleo AS LOGICAL NO-UNDO.
DEFINE VARIABLE lMarca AS LOGICAL NO-UNDO.
DEFINE VARIABLE lMarcaRepetida AS LOGICAL NO-UNDO.
DEFINE VARIABLE cErroMarca AS CHARACTER NO-UNDO.
DEFINE BUFFER bNaturezaDev FOR mgcad.natur-oper.

EMPTY TEMP-TABLE ttEmbEventoComando.
ASSIGN plSucesso = NO plRepeticao = NO piIdEvento = 0
       pcErro = "DOCUMENTO_INVALIDO"
       pcMensagem = "Operacao, nota, usuario ou nucleo invalidos.".
IF piOperacao = ? OR piOperacao <= 0 OR prNota = ? OR
   pcUsuario = ? OR TRIM(pcUsuario, " ") = "" OR
   NOT VALID-HANDLE(phRastreio) THEN RETURN.
IF NOT CONNECTED("mgmov") OR NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_NAO_CONECTADO"
           pcMensagem = "Bancos necessarios nao conectados.".
    RETURN.
END.
FIND FIRST bNota NO-LOCK WHERE ROWID(bNota) = prNota NO-ERROR.
FIND FIRST bOper NO-LOCK WHERE bOper.id-operacao = piOperacao NO-ERROR.
IF NOT AVAILABLE bNota OR NOT AVAILABLE bOper THEN RETURN.
IF LOOKUP(bOper.tipo-operacao, "DEVOLUCAO_COMPRA,REMESSA_TERCEIROS,RETORNO_TERCEIROS") > 0 THEN DO:
    FIND FIRST bNaturezaDev NO-LOCK
        WHERE bNaturezaDev.nat-operacao = bNota.nat-operacao NO-ERROR.
    IF NOT AVAILABLE bNaturezaDev THEN DO:
        ASSIGN pcErro = "NATUREZA_NOTA_AUSENTE" pcMensagem = "Natureza da nota nao encontrada.".
        RETURN.
    END.
    IF bNaturezaDev.especie-doc = ? THEN DO:
        ASSIGN pcErro = "NATUREZA_NOTA_DIVERGENTE" pcMensagem = "Especie da natureza nao informada.".
        RETURN.
    END.
    IF bOper.tipo-operacao = "DEVOLUCAO_COMPRA" AND
       CAPS(TRIM(bNaturezaDev.especie-doc)) <> "NFD" THEN DO:
        ASSIGN pcErro = "NATUREZA_NOTA_DIVERGENTE" pcMensagem = "Devolucao de compra exige natureza NFD.".
        RETURN.
    END.
    IF bOper.tipo-operacao = "REMESSA_TERCEIROS" AND
       (LOOKUP(CAPS(TRIM(bNaturezaDev.especie-doc)), "NFS,NFT") = 0 OR
        bNaturezaDev.terceiros = ? OR bNaturezaDev.terceiros <> YES OR
        bNaturezaDev.tp-oper-terc = ? OR bNaturezaDev.tp-oper-terc <> 3) THEN DO:
        ASSIGN pcErro = "NATUREZA_NOTA_DIVERGENTE"
            pcMensagem = "Remessa exige natureza de terceiros tipo 3.".
        RETURN.
    END.
    IF bOper.tipo-operacao = "RETORNO_TERCEIROS" AND
       (LOOKUP(CAPS(TRIM(bNaturezaDev.especie-doc)), "NFS,NFT") = 0 OR
        bNaturezaDev.terceiros = ? OR bNaturezaDev.terceiros <> YES OR
        bNaturezaDev.tp-oper-terc = ? OR
        (bNaturezaDev.tp-oper-terc <> 2 AND bNaturezaDev.tp-oper-terc <> 5)) THEN DO:
        ASSIGN pcErro = "NATUREZA_NOTA_DIVERGENTE"
            pcMensagem = "Retorno exige natureza de terceiros tipo 2 ou 5.".
        RETURN.
    END.
END.
IF bOper.seq-wt-docto = ? OR bOper.seq-wt-docto <= 0 THEN DO:
    ASSIGN pcErro = "WT_NAO_VINCULADO"
           pcMensagem = "A operacao ainda nao possui documento de trabalho.".
    RETURN.
END.
IF bOper.cod-estabel-orig <> bNota.cod-estabel OR
   (bOper.cod-emitente <> ? AND
    bOper.cod-emitente <> bNota.cod-emitente) THEN DO:
    ASSIGN pcErro = "DOCUMENTO_DIVERGENTE"
           pcMensagem = "Nota e operacao possuem estabelecimento ou emitente diferente.".
    RETURN.
END.
ASSIGN cDigest = "".
FOR EACH bItem NO-LOCK
    WHERE bItem.id-operacao = piOperacao
      AND (bItem.tipo-item = "SOLICITACAO" OR bItem.tipo-item = "LIBERADA")
    BY bItem.sequencia:
    IF bItem.tipo-item = "LIBERADA" THEN DO:
        ASSIGN pcErro = "RESERVA_LIBERADA" pcMensagem = "Selecao liberada por perda; documento padrao permanece inalterado.".
        RETURN.
    END.
    IF bItem.id-etiqueta = ? OR bItem.id-etiqueta <= 0 OR
       bItem.quantidade = ? OR bItem.quantidade <= 0 THEN DO:
        ASSIGN pcErro = "SELECAO_INCOMPLETA"
               pcMensagem = "Linha sem etiqueta ou quantidade positiva.".
        RETURN.
    END.
    IF CAN-FIND(FIRST bItemDuplicado NO-LOCK
        WHERE bItemDuplicado.id-operacao = piOperacao
          AND bItemDuplicado.tipo-item = "SOLICITACAO"
          AND bItemDuplicado.id-etiqueta = bItem.id-etiqueta
          AND bItemDuplicado.sequencia < bItem.sequencia) THEN DO:
        ASSIGN pcErro = "ETIQUETA_DUPLICADA"
               pcMensagem = "A mesma etiqueta foi selecionada mais de uma vez.".
        RETURN.
    END.
    FIND FIRST bEtiqueta NO-LOCK
        WHERE bEtiqueta.id-etiqueta = bItem.id-etiqueta NO-ERROR.
    IF NOT AVAILABLE bEtiqueta THEN DO:
        ASSIGN pcErro = "ETIQUETA_AUSENTE"
               pcMensagem = "Etiqueta selecionada nao encontrada.".
        RETURN.
    END.
    IF bEtiqueta.tipo-controle <> "EMBALAGEM" OR
       bEtiqueta.it-codigo <> bItem.it-codigo OR
       bEtiqueta.lote <> bItem.lote OR
       bEtiqueta.dt-vali-lote <> bItem.dt-vali-lote OR
       bEtiqueta.un <> bItem.un OR
       bEtiqueta.qtidade-atu <> bItem.quantidade OR
       bEtiqueta.cod-estabel <> bOper.cod-estabel-orig OR
       bEtiqueta.tipo-local <> "ESTAB" OR
       bEtiqueta.situacao <> "ATIVA" OR
       bEtiqueta.id-bag <> ? THEN DO:
        ASSIGN pcErro = "ETIQUETA_DIVERGENTE"
               pcMensagem = "Selecao e estado individual divergem.".
        RETURN.
    END.
    ASSIGN iLinhas = iLinhas + 1
           cDigest = HEX-ENCODE(MESSAGE-DIGEST("SHA-256",
               cDigest + "|" + STRING(bItem.sequencia) + "|" +
               STRING(bItem.id-etiqueta) + "|" + STRING(bItem.quantidade) +
               "|" + STRING(bItem.versao))).
END.
IF iLinhas = 0 THEN DO:
    ASSIGN pcErro = "SELECAO_VAZIA"
           pcMensagem = "Selecione ao menos uma embalagem.".
    RETURN.
END.
ASSIGN cSerie = IF bNota.serie = ? THEN "" ELSE bNota.serie
       cDocumento = "SAIDA|" + STRING(LENGTH(bNota.cod-estabel)) + ":" +
                   bNota.cod-estabel + "|" + STRING(LENGTH(cSerie)) + ":" +
                   cSerie + "|" + STRING(LENGTH(bNota.nr-nota-fis)) + ":" +
                   bNota.nr-nota-fis + "|" + STRING(bNota.cod-emitente)
       cChave = "FLUIG|" + cDocumento.
FOR EACH bDocumento NO-LOCK
    WHERE bDocumento.tipo-evento = "DOCUMENTO_SAIDA_FLUIG"
      AND bDocumento.cod-estabel = bNota.cod-estabel
      AND bDocumento.serie = bNota.serie
      AND bDocumento.nro-docto = bNota.nr-nota-fis
      AND bDocumento.cod-emitente = bNota.cod-emitente:
    IF bDocumento.id-operacao <> piOperacao THEN DO:
        ASSIGN pcErro = "DOCUMENTO_JA_VINCULADO"
               pcMensagem = "A nota ja esta vinculada a outra operacao.".
        RETURN.
    END.
END.
CREATE ttEmbEventoComando.
ASSIGN ttEmbEventoComando.origem = "FLUIG"
       ttEmbEventoComando.chave-evento = cChave
       ttEmbEventoComando.hash-chave = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cChave))
       ttEmbEventoComando.hash-conteudo = HEX-ENCODE(MESSAGE-DIGEST("SHA-256",
            cChave + "|" + STRING(piOperacao) + "|" + cDigest))
       ttEmbEventoComando.tipo-evento = "DOCUMENTO_SAIDA_FLUIG"
       ttEmbEventoComando.id-operacao = piOperacao
       ttEmbEventoComando.seq-ciclo = 1
       ttEmbEventoComando.dt-evento = NOW
       ttEmbEventoComando.versao-contrato = 1
       ttEmbEventoComando.tipo-docto = "SAIDA"
       ttEmbEventoComando.chave-docto = cDocumento
       ttEmbEventoComando.hash-docto = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cDocumento))
       ttEmbEventoComando.cod-estabel = bNota.cod-estabel
       ttEmbEventoComando.cod-emitente = bNota.cod-emitente
       ttEmbEventoComando.serie = bNota.serie
       ttEmbEventoComando.nro-docto = bNota.nr-nota-fis
       ttEmbEventoComando.dt-emissao = bNota.dt-emis-nota
       ttEmbEventoComando.dados-evento = "Documento criado pelo Fluig; operacao=" +
                                        STRING(piOperacao) + ";etiquetas=" + STRING(iLinhas)
       ttEmbEventoComando.usuario = TRIM(pcUsuario, " ").

vinculoTransacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    IF bNota.nat-operacao = ? OR TRIM(bNota.nat-operacao) = "" THEN DO:
        ASSIGN pcErro = "NATUREZA_NOTA_AUSENTE"
            pcMensagem = "A nota precisa de natureza conhecida para o vinculo documental.".
        UNDO vinculoTransacao, LEAVE vinculoTransacao.
    END.
    ttEmbEventoComando.nat-operacao = bNota.nat-operacao.
    RUN gravarWtDoctoNaNota (INPUT prNota, INPUT bOper.seq-wt-docto,
        OUTPUT lMarca, OUTPUT lMarcaRepetida, OUTPUT cErroMarca).
    IF NOT lMarca THEN DO:
        ASSIGN pcErro = cErroMarca
               pcMensagem = "Nao foi possivel gravar o WT na nota.".
        UNDO vinculoTransacao, LEAVE vinculoTransacao.
    END.
    RUN registrarEvento IN phRastreio(INPUT TABLE ttEmbEventoComando, INPUT YES,
        OUTPUT lNucleo, OUTPUT lRepNucleo, OUTPUT piIdEvento,
        OUTPUT cSituacao, OUTPUT iVersao, OUTPUT cErroNucleo, OUTPUT cMsgNucleo).
    IF NOT lNucleo THEN DO:
        ASSIGN pcErro = cErroNucleo pcMensagem = cMsgNucleo piIdEvento = 0.
        UNDO vinculoTransacao, LEAVE vinculoTransacao.
    END.
    IF lRepNucleo THEN DO:
        IF cSituacao <> "CONCLUIDO" THEN DO:
            ASSIGN pcErro = "DOCUMENTO_PENDENTE"
                   pcMensagem = "Vinculo documental anterior ainda nao concluido.".
            UNDO vinculoTransacao, LEAVE vinculoTransacao.
        END.
        ASSIGN plSucesso = YES plRepeticao = YES pcErro = "" pcMensagem = "".
        LEAVE vinculoTransacao.
    END.
    FIND FIRST bDocumento EXCLUSIVE-LOCK
        WHERE bDocumento.id-evento = piIdEvento NO-ERROR.
    IF NOT AVAILABLE bDocumento THEN DO:
        ASSIGN pcErro = "DOCUMENTO_NAO_PERSISTIDO"
               pcMensagem = "Evento documental nao encontrado apos inclusao.".
        UNDO vinculoTransacao, LEAVE vinculoTransacao.
    END.
    ASSIGN bDocumento.situacao = "CONCLUIDO"
           bDocumento.dt-conclusao = NOW
           bDocumento.resultado = "operacao=" + STRING(piOperacao)
           bDocumento.dt-alteracao = NOW
           bDocumento.versao = bDocumento.versao + 1
           plSucesso = YES pcErro = "" pcMensagem = "".
END.
END PROCEDURE.

PROCEDURE processarNotaFt2100:
DEFINE INPUT PARAMETER prNota AS ROWID NO-UNDO.
DEFINE INPUT PARAMETER piTipoAtual AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER phRastreio AS HANDLE NO-UNDO.
DEFINE OUTPUT PARAMETER plAplicavel AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piIdEvento AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piQtdEtiquetas AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.

DEFINE BUFFER bNota FOR mgmov.nota-fiscal.
DEFINE BUFFER bDocumento FOR mgesp.contr_emb_evento.
DEFINE BUFFER bOper FOR mgesp.contr_emb_oper.
DEFINE BUFFER bItem FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bEtiqueta FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bSaida FOR mgesp.contr_emb_evento.
DEFINE BUFFER bReversaoSaida FOR mgesp.contr_emb_evento.
DEFINE BUFFER bMovtoSaida FOR mgesp.contr_emb_movto.
DEFINE BUFFER bNovoEvento FOR mgesp.contr_emb_evento.
DEFINE VARIABLE iDocumentos AS INTEGER NO-UNDO.
DEFINE VARIABLE iOrigem AS INTEGER NO-UNDO.
DEFINE VARIABLE iSaida AS INTEGER NO-UNDO.
DEFINE VARIABLE iSaidas AS INTEGER NO-UNDO.
DEFINE VARIABLE iSaidasAtivas AS INTEGER NO-UNDO.
DEFINE VARIABLE iCicloSaidaAtiva AS INTEGER NO-UNDO.
DEFINE VARIABLE iCicloUltimo AS INTEGER NO-UNDO.
DEFINE VARIABLE iCicloNovo AS INTEGER NO-UNDO.
DEFINE VARIABLE iReversoes AS INTEGER NO-UNDO.
DEFINE VARIABLE iReversaoUltima AS INTEGER NO-UNDO.
DEFINE VARIABLE iSeq AS INTEGER NO-UNDO.
DEFINE VARIABLE iIdMovto AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersao AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersaoEvento AS INTEGER NO-UNDO.
DEFINE VARIABLE cUsuario AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChave AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConteudo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSituacao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErroNucleo AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMsgNucleo AS CHARACTER NO-UNDO.
DEFINE VARIABLE lNucleo AS LOGICAL NO-UNDO.
DEFINE VARIABLE lRepNucleo AS LOGICAL NO-UNDO.
DEFINE VARIABLE dtAgora AS DATETIME-TZ NO-UNDO.
DEFINE VARIABLE cWtNota AS CHARACTER NO-UNDO.
DEFINE VARIABLE lDevolucaoCompra AS LOGICAL NO-UNDO.
DEFINE VARIABLE lRemessaTerceiros AS LOGICAL NO-UNDO.
DEFINE VARIABLE lRetornoTerceiros AS LOGICAL NO-UNDO.
DEFINE BUFFER bNaturezaDevFt FOR mgcad.natur-oper.

EMPTY TEMP-TABLE ttEmbEventoComando.
EMPTY TEMP-TABLE ttEmbMovimentoComando.
ASSIGN plAplicavel = NO plSucesso = NO plRepeticao = NO
       piIdEvento = 0 piQtdEtiquetas = 0
       pcErro = "E04_ENTRADA_INVALIDA"
       pcMensagem = "Nota, sentido ou nucleo de movimento invalido.".
IF prNota = ? OR piTipoAtual = ? OR
   LOOKUP(STRING(piTipoAtual), "1,2") = 0 OR
   NOT VALID-HANDLE(phRastreio) THEN RETURN.
IF NOT CONNECTED("mgmov") OR NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "E04_BANCO_NAO_CONECTADO"
           pcMensagem = "Bancos necessarios nao conectados.".
    RETURN.
END.
FIND FIRST bNota NO-LOCK WHERE ROWID(bNota) = prNota NO-ERROR.
IF NOT AVAILABLE bNota THEN DO:
    ASSIGN pcErro = "E04_NOTA_NAO_ENCONTRADA"
           pcMensagem = "A nota informada pelo FT2100 nao foi encontrada.".
    RETURN.
END.

/* Um documento criado pelo Fluig tem uma origem especifica concluida.
   Ausencia significa nota direta no Datasul: nenhum efeito individual. */
FOR EACH bDocumento NO-LOCK
    WHERE bDocumento.tipo-evento = "DOCUMENTO_SAIDA_FLUIG"
      AND bDocumento.tipo-docto = "SAIDA"
      AND bDocumento.cod-estabel = bNota.cod-estabel
      AND bDocumento.serie = bNota.serie
      AND bDocumento.nro-docto = bNota.nr-nota-fis
      AND bDocumento.cod-emitente = bNota.cod-emitente:
    ASSIGN iDocumentos = iDocumentos + 1
           iOrigem = bDocumento.id-evento.
END.
IF iDocumentos = 0 THEN DO:
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "Nota sem selecao Fluig.".
    RETURN.
END.
ASSIGN plAplicavel = YES
       pcErro = "E04_ORIGEM_AMBIGUA"
       pcMensagem = "A nota possui mais de uma origem especifica.".
IF iDocumentos <> 1 THEN RETURN.
FIND FIRST bDocumento NO-LOCK WHERE bDocumento.id-evento = iOrigem NO-ERROR.
IF NOT AVAILABLE bDocumento OR bDocumento.situacao <> "CONCLUIDO" OR
   bDocumento.id-operacao = ? OR bDocumento.id-operacao <= 0 THEN DO:
    ASSIGN pcErro = "E04_ORIGEM_INVALIDA"
           pcMensagem = "Documento Fluig nao concluido ou sem operacao.".
    RETURN.
END.
FIND FIRST bOper NO-LOCK
    WHERE bOper.id-operacao = bDocumento.id-operacao NO-ERROR.
IF NOT AVAILABLE bOper THEN DO:
    ASSIGN pcErro = "E04_OPERACAO_AUSENTE"
           pcMensagem = "Operacao vinculada a nota nao encontrada.".
    RETURN.
END.
IF bOper.seq-wt-docto = ? OR bOper.seq-wt-docto <= 0 THEN DO:
    ASSIGN pcErro = "E04_WT_AUSENTE"
           pcMensagem = "Operacao sem documento de trabalho vinculado.".
    RETURN.
END.
cWtNota = IF bNota.char-2 = ? THEN ""
          ELSE TRIM(SUBSTRING(bNota.char-2, 1500, 20)).
IF cWtNota <> "CEWT1:" + STRING(bOper.seq-wt-docto) THEN DO:
    ASSIGN pcErro = "E04_WT_DIVERGENTE"
           pcMensagem = "Vinculo WT da nota difere da operacao.".
    RETURN.
END.
/* E11 acrescenta remessa de terceiros tipo 3; retorno continua em recorte proprio.
   Transferencia e devolucao de compra mantem seus ciclos ja validados. */
ASSIGN lDevolucaoCompra = bOper.tipo-operacao = "DEVOLUCAO_COMPRA"
       lRemessaTerceiros = bOper.tipo-operacao = "REMESSA_TERCEIROS"
       lRetornoTerceiros = bOper.tipo-operacao = "RETORNO_TERCEIROS".
IF (NOT lDevolucaoCompra AND NOT lRemessaTerceiros AND NOT lRetornoTerceiros AND
    CAPS(TRIM(bOper.tipo-operacao, " ")) <> "TRANSFERENCIA") OR
   (NOT lDevolucaoCompra AND NOT lRetornoTerceiros AND NOT lRemessaTerceiros AND
    (bOper.cod-estabel-dest = ? OR bOper.cod-estabel-dest = "")) THEN DO:
    ASSIGN pcErro = "E04_TIPO_SEM_REGRA"
           pcMensagem = "A natureza da operacao ainda nao possui efeito individual contratado.".
    RETURN.
END.
IF lDevolucaoCompra OR lRemessaTerceiros OR lRetornoTerceiros THEN DO:
    FIND FIRST bNaturezaDevFt NO-LOCK
        WHERE bNaturezaDevFt.nat-operacao = bNota.nat-operacao NO-ERROR.
    IF NOT AVAILABLE bNaturezaDevFt THEN DO:
        ASSIGN pcErro = "E10_NATUREZA_AUSENTE" pcMensagem = "Natureza da nota nao encontrada.".
        RETURN.
    END.
    IF bNaturezaDevFt.especie-doc = ? OR
       (lDevolucaoCompra AND CAPS(TRIM(bNaturezaDevFt.especie-doc)) <> "NFD") OR
       (lRemessaTerceiros AND
        (LOOKUP(CAPS(TRIM(bNaturezaDevFt.especie-doc)), "NFS,NFT") = 0 OR
         bNaturezaDevFt.terceiros = ? OR bNaturezaDevFt.terceiros <> YES OR
         bNaturezaDevFt.tp-oper-terc = ? OR bNaturezaDevFt.tp-oper-terc <> 3)) OR
       (lRetornoTerceiros AND
        (LOOKUP(CAPS(TRIM(bNaturezaDevFt.especie-doc)), "NFS,NFT") = 0 OR
         bNaturezaDevFt.terceiros = ? OR bNaturezaDevFt.terceiros <> YES OR
         bNaturezaDevFt.tp-oper-terc = ? OR
         (bNaturezaDevFt.tp-oper-terc <> 2 AND bNaturezaDevFt.tp-oper-terc <> 5))) OR
       bOper.cod-emitente = ? OR bOper.cod-emitente <> bNota.cod-emitente OR
       bDocumento.nat-operacao <> bNota.nat-operacao THEN DO:
        ASSIGN pcErro = "E10_NATUREZA_OU_FORNECEDOR_DIVERGENTE"
            pcMensagem = "Nota diverge da natureza ou contraparte do vinculo documental.".
        RETURN.
    END.
END.
IF bOper.cod-estabel-orig <> bNota.cod-estabel THEN DO:
    ASSIGN pcErro = "E04_ESTAB_DIVERGENTE"
           pcMensagem = "Estabelecimento da nota difere da operacao.".
    RETURN.
END.
ASSIGN cUsuario = IF bDocumento.usuario-inclusao = ? THEN ""
                  ELSE TRIM(bDocumento.usuario-inclusao, " ").
IF cUsuario = "" THEN DO:
    ASSIGN pcErro = "E04_USUARIO_AUSENTE"
           pcMensagem = "Operacao sem usuario confiavel.".
    RETURN.
END.
FOR EACH bItem NO-LOCK
    WHERE bItem.id-operacao = bOper.id-operacao
      AND (bItem.tipo-item = "SOLICITACAO" OR bItem.tipo-item = "LIBERADA"):
    IF bItem.tipo-item = "LIBERADA" THEN DO:
        ASSIGN pcErro = "RESERVA_LIBERADA" pcMensagem = "Selecao liberada por perda; documento padrao permanece inalterado.".
        RETURN.
    END.
    IF bItem.id-etiqueta = ? OR bItem.id-etiqueta <= 0 OR
       bItem.quantidade = ? OR bItem.quantidade <= 0 THEN DO:
        ASSIGN pcErro = "E04_SELECAO_INCOMPLETA"
               pcMensagem = "A selecao da operacao nao identifica todas as etiquetas.".
        RETURN.
    END.
    piQtdEtiquetas = piQtdEtiquetas + 1.
END.
IF piQtdEtiquetas = 0 THEN DO:
    ASSIGN pcErro = "E04_SELECAO_VAZIA"
           pcMensagem = "Operacao Fluig sem embalagens selecionadas.".
    RETURN.
END.

FOR EACH bSaida NO-LOCK
    WHERE bSaida.id-operacao = bOper.id-operacao
      AND bSaida.id-evento-origem = iOrigem
      AND bSaida.tipo-evento = "SAIDA_ESTOQUE":
    iSaidas = iSaidas + 1.
    IF bSaida.situacao <> "CONCLUIDO" THEN DO:
        ASSIGN pcErro = "E04_SAIDA_PENDENTE"
               pcMensagem = "Existe fato de saida ainda nao concluido.".
        RETURN.
    END.
    IF bSaida.seq-ciclo = ? OR bSaida.seq-ciclo <= 0 OR
       bSaida.seq-ciclo MODULO 2 = 0 THEN DO:
        ASSIGN pcErro = "E04_CICLO_INVALIDO"
               pcMensagem = "Sequencia da saida individual invalida.".
        RETURN.
    END.
    iCicloUltimo = MAXIMUM(iCicloUltimo, bSaida.seq-ciclo).
    iReversoes = 0.
    FOR EACH bReversaoSaida NO-LOCK
        WHERE bReversaoSaida.id-operacao = bOper.id-operacao
          AND bReversaoSaida.id-evento-origem = bSaida.id-evento
          AND bReversaoSaida.tipo-evento = "DESATUALIZACAO_SAIDA":
        iReversoes = iReversoes + 1.
        IF bReversaoSaida.situacao <> "CONCLUIDO" THEN DO:
            ASSIGN pcErro = "E04_REVERSAO_PENDENTE"
                   pcMensagem = "Existe reversao individual ainda nao concluida.".
            RETURN.
        END.
        IF bReversaoSaida.seq-ciclo <> bSaida.seq-ciclo + 1 THEN DO:
            ASSIGN pcErro = "E04_CICLO_INVALIDO"
                   pcMensagem = "Sequencia da reversao individual invalida.".
            RETURN.
        END.
        IF bReversaoSaida.seq-ciclo > iCicloUltimo THEN
            ASSIGN iCicloUltimo = bReversaoSaida.seq-ciclo
                   iReversaoUltima = bReversaoSaida.id-evento.
    END.
    IF iReversoes > 1 THEN DO:
        ASSIGN pcErro = "E04_REVERSAO_AMBIGUA"
               pcMensagem = "Mais de uma reversao para a mesma saida.".
        RETURN.
    END.
    IF iReversoes = 0 THEN
        ASSIGN iSaidasAtivas = iSaidasAtivas + 1
               iSaida = bSaida.id-evento
               iCicloSaidaAtiva = bSaida.seq-ciclo.
END.
IF iSaidasAtivas > 1 OR
   (iSaidasAtivas = 1 AND iCicloSaidaAtiva <> iCicloUltimo) OR
   iCicloUltimo <> (iSaidas * 2 - iSaidasAtivas) THEN DO:
    ASSIGN pcErro = "E04_SAIDA_AMBIGUA"
           pcMensagem = "Historico de saidas da nota inconsistente.".
    RETURN.
END.
IF piTipoAtual = 1 AND iSaidasAtivas = 1 THEN DO:
    ASSIGN plSucesso = YES plRepeticao = YES piIdEvento = iSaida
           pcErro = "" pcMensagem = "".
    RETURN.
END.
IF piTipoAtual = 2 AND iSaidasAtivas = 0 AND iSaidas > 0 THEN DO:
    ASSIGN plSucesso = YES plRepeticao = YES
           piIdEvento = iReversaoUltima pcErro = "" pcMensagem = "".
    RETURN.
END.
IF piTipoAtual = 2 AND iSaidasAtivas = 0 THEN DO:
    ASSIGN pcErro = "E04_SAIDA_NAO_REGISTRADA"
           pcMensagem = "Nao ha saida individual confirmada para compensar.".
    RETURN.
END.
/* Cada efeito confirmado da mesma nota recebe um ciclo proprio. As duas
   chaves do primeiro ciclo permanecem iguais as ja gravadas em TESTE. */
iCicloNovo = iCicloUltimo + 1.
ASSIGN cChave = "FT2100|" + STRING(iOrigem) + "|" +
                (IF piTipoAtual = 1 THEN "ATUALIZA" ELSE "DESATUALIZA") +
                (IF iCicloNovo <= 2 THEN "" ELSE "|CICLO=" + STRING(iCicloNovo))
       cConteudo = cChave + "|" + bDocumento.hash-conteudo + "|" +
                   STRING(piQtdEtiquetas)
       dtAgora = NOW.
CREATE ttEmbEventoComando.
ASSIGN ttEmbEventoComando.origem = "FT2100RP"
       ttEmbEventoComando.chave-evento = cChave
       ttEmbEventoComando.hash-chave = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cChave))
       ttEmbEventoComando.hash-conteudo = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cConteudo))
       ttEmbEventoComando.tipo-evento = IF piTipoAtual = 1 THEN "SAIDA_ESTOQUE"
                                        ELSE "DESATUALIZACAO_SAIDA"
       ttEmbEventoComando.id-operacao = bOper.id-operacao
       ttEmbEventoComando.id-evento-origem = IF piTipoAtual = 1 THEN iOrigem ELSE iSaida
       ttEmbEventoComando.seq-ciclo = iCicloNovo
       ttEmbEventoComando.dt-evento = dtAgora
       ttEmbEventoComando.versao-contrato = 1
       ttEmbEventoComando.tipo-docto = bDocumento.tipo-docto
       ttEmbEventoComando.chave-docto = bDocumento.chave-docto
       ttEmbEventoComando.hash-docto = bDocumento.hash-docto
       ttEmbEventoComando.cod-estabel = bDocumento.cod-estabel
       ttEmbEventoComando.cod-emitente = bDocumento.cod-emitente
       ttEmbEventoComando.serie = bDocumento.serie
       ttEmbEventoComando.nro-docto = bDocumento.nro-docto
       ttEmbEventoComando.nat-operacao = bNota.nat-operacao
       ttEmbEventoComando.dt-emissao = bDocumento.dt-emissao
       ttEmbEventoComando.dados-evento = "FT2100RP end-ft2100; nota Fluig; origem=" + STRING(iOrigem)
       ttEmbEventoComando.usuario = cUsuario.

e04Transacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    RUN registrarEvento IN phRastreio(INPUT TABLE ttEmbEventoComando, INPUT YES,
        OUTPUT lNucleo, OUTPUT lRepNucleo, OUTPUT piIdEvento,
        OUTPUT cSituacao, OUTPUT iVersaoEvento, OUTPUT cErroNucleo, OUTPUT cMsgNucleo).
    IF NOT lNucleo THEN DO:
        ASSIGN pcErro = cErroNucleo pcMensagem = cMsgNucleo piIdEvento = 0.
        UNDO e04Transacao, LEAVE e04Transacao.
    END.
    IF lRepNucleo THEN DO:
        IF cSituacao <> "CONCLUIDO" THEN DO:
            ASSIGN pcErro = "E04_EVENTO_PENDENTE"
                   pcMensagem = "Fato anterior ainda nao concluido." piIdEvento = 0.
            UNDO e04Transacao, LEAVE e04Transacao.
        END.
        ASSIGN plSucesso = YES plRepeticao = YES pcErro = "" pcMensagem = "".
        LEAVE e04Transacao.
    END.
    ASSIGN iSeq = 0.
    FOR EACH bItem NO-LOCK
        WHERE bItem.id-operacao = bOper.id-operacao
          AND bItem.tipo-item = "SOLICITACAO"
        BY bItem.sequencia:
        FIND FIRST bEtiqueta NO-LOCK
            WHERE bEtiqueta.id-etiqueta = bItem.id-etiqueta NO-ERROR.
        IF NOT AVAILABLE bEtiqueta THEN DO:
            ASSIGN pcErro = "E04_ETIQUETA_AUSENTE"
                   pcMensagem = "Etiqueta selecionada nao encontrada.".
            UNDO e04Transacao, LEAVE e04Transacao.
        END.
        IF bEtiqueta.tipo-controle <> "EMBALAGEM" OR
           bEtiqueta.it-codigo <> bItem.it-codigo OR
           bEtiqueta.lote <> bItem.lote OR
           bEtiqueta.dt-vali-lote <> bItem.dt-vali-lote OR
           bEtiqueta.un <> bItem.un OR
           bEtiqueta.qtidade-atu <> bItem.quantidade OR
           bEtiqueta.situacao <> "ATIVA" OR
           bEtiqueta.id-bag <> ? THEN DO:
            ASSIGN pcErro = "E04_ETIQUETA_DIVERGENTE"
                   pcMensagem = "Selecao e estado atual da embalagem divergem.".
            UNDO e04Transacao, LEAVE e04Transacao.
        END.
        IF piTipoAtual = 1 THEN DO:
            IF bEtiqueta.tipo-local <> "ESTAB" OR
               bEtiqueta.cod-estabel <> bOper.cod-estabel-orig THEN DO:
                ASSIGN pcErro = "E04_ORIGEM_DIVERGENTE"
                       pcMensagem = "Embalagem nao esta na origem da nota.".
                UNDO e04Transacao, LEAVE e04Transacao.
            END.
        END.
        ELSE DO:
            FIND FIRST bMovtoSaida NO-LOCK
                WHERE bMovtoSaida.id-evento = iSaida
                  AND bMovtoSaida.id-etiqueta = bEtiqueta.id-etiqueta NO-ERROR.
            IF NOT AVAILABLE bMovtoSaida THEN DO:
                ASSIGN pcErro = "E04_SAIDA_ETIQUETA_AUSENTE"
                       pcMensagem = "Movimento original da embalagem nao encontrado.".
                UNDO e04Transacao, LEAVE e04Transacao.
            END.
            IF bEtiqueta.id-movto-ult <> bMovtoSaida.id-movto OR
               bEtiqueta.tipo-local <> (IF lRemessaTerceiros THEN "TERCEIRO" ELSE "TRANSITO") THEN DO:
                ASSIGN pcErro = "E04_DEPENDENCIA_POSTERIOR"
                       pcMensagem = "Embalagem possui fato posterior; reversao automatica bloqueada.".
                UNDO e04Transacao, LEAVE e04Transacao.
            END.
        END.
        ASSIGN iSeq = iSeq + 1.
        EMPTY TEMP-TABLE ttEmbMovimentoComando.
        CREATE ttEmbMovimentoComando.
        ASSIGN ttEmbMovimentoComando.id-evento = piIdEvento
               ttEmbMovimentoComando.sequencia = iSeq
               ttEmbMovimentoComando.id-etiqueta = bEtiqueta.id-etiqueta
               ttEmbMovimentoComando.id-item-oper = bItem.id-item-oper
               ttEmbMovimentoComando.versao-etiqueta-esperada = bEtiqueta.versao
               ttEmbMovimentoComando.id-movto-ant-esperado = bEtiqueta.id-movto-ult
               ttEmbMovimentoComando.id-movto-origem = IF piTipoAtual = 1 THEN 0
                                                       ELSE bMovtoSaida.id-movto
               ttEmbMovimentoComando.tipo-movto = IF piTipoAtual = 1 THEN
                   (IF lDevolucaoCompra THEN "SAIDA_DEVOLUCAO_COMPRA"
                    ELSE IF lRemessaTerceiros THEN "SAIDA_REMESSA_TERCEIROS"
                    ELSE IF lRetornoTerceiros THEN "SAIDA_RETORNO_TERCEIROS" ELSE "SAIDA_TRANSFERENCIA")
                                                   ELSE "DESATUALIZACAO_SAIDA"
               ttEmbMovimentoComando.dt-movto = dtAgora
               ttEmbMovimentoComando.un = bEtiqueta.un
               ttEmbMovimentoComando.quantidade = bItem.quantidade
               ttEmbMovimentoComando.qtidade-atu = bEtiqueta.qtidade-atu
               ttEmbMovimentoComando.situacao-atu = bEtiqueta.situacao
               ttEmbMovimentoComando.cod-estabel-dest = bOper.cod-estabel-orig
               ttEmbMovimentoComando.cod-depos-dest = IF piTipoAtual = 1 THEN ?
                                                      ELSE bMovtoSaida.cod-depos-orig
               ttEmbMovimentoComando.cod-localiz-dest = IF piTipoAtual = 1 THEN ?
                                                        ELSE bMovtoSaida.cod-localiz-orig
               ttEmbMovimentoComando.tipo-local-dest = IF piTipoAtual = 1 THEN
                   (IF lRemessaTerceiros THEN "TERCEIRO" ELSE "TRANSITO")
                                                       ELSE "ESTAB"
               ttEmbMovimentoComando.origem-movto-erp = "FT2100RP"
               ttEmbMovimentoComando.chave-movto-erp = bDocumento.chave-docto
               ttEmbMovimentoComando.justificativa = IF piTipoAtual = 1 THEN ?
                                                     ELSE "Documento desatualizado no FT2100"
               ttEmbMovimentoComando.usuario = cUsuario.
        IF lDevolucaoCompra OR lRemessaTerceiros OR lRetornoTerceiros THEN DO:
            ttEmbMovimentoComando.cod-emitente-dest = IF piTipoAtual = 1
                THEN bOper.cod-emitente ELSE bMovtoSaida.cod-emitente-orig.
            IF piTipoAtual = 2 THEN
                ASSIGN ttEmbMovimentoComando.qtidade-atu = bMovtoSaida.qtidade-ant
                    ttEmbMovimentoComando.situacao-atu = bMovtoSaida.situacao-ant
                    ttEmbMovimentoComando.tipo-local-dest = bMovtoSaida.tipo-local-orig
                    ttEmbMovimentoComando.cod-estabel-dest = bMovtoSaida.cod-estabel-orig.
        END.
        RUN aplicarMovimento IN phRastreio(INPUT TABLE ttEmbMovimentoComando, INPUT YES,
            OUTPUT lNucleo, OUTPUT lRepNucleo, OUTPUT iIdMovto, OUTPUT iVersao,
            OUTPUT cErroNucleo, OUTPUT cMsgNucleo).
        IF NOT lNucleo THEN DO:
            ASSIGN pcErro = cErroNucleo pcMensagem = cMsgNucleo.
            UNDO e04Transacao, LEAVE e04Transacao.
        END.
    END.
    FIND FIRST bNovoEvento EXCLUSIVE-LOCK
        WHERE bNovoEvento.id-evento = piIdEvento NO-ERROR.
    IF NOT AVAILABLE bNovoEvento OR iSeq <> piQtdEtiquetas THEN DO:
        ASSIGN pcErro = "E04_EVENTO_INCOMPLETO"
               pcMensagem = "Quantidade de movimentos difere da selecao.".
        UNDO e04Transacao, LEAVE e04Transacao.
    END.
    IF lRemessaTerceiros OR lRetornoTerceiros OR
        CAPS(TRIM(bOper.tipo-operacao)) = "TRANSFERENCIA" THEN DO:
        FIND FIRST bOper WHERE bOper.id-operacao = bDocumento.id-operacao
            EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF LOCKED bOper OR NOT AVAILABLE bOper THEN DO:
            ASSIGN pcErro = "E11_OPERACAO_BLOQUEADA"
                pcMensagem = "Nao foi possivel concluir o estado da remessa.".
            UNDO e04Transacao, LEAVE e04Transacao.
        END.
        ASSIGN bOper.situacao = IF piTipoAtual = 1 THEN "EXECUTADA" ELSE "SOLICITADA"
            bOper.dt-alteracao = NOW bOper.usuario-alteracao = cUsuario
            bOper.versao = bOper.versao + 1.
    END.
    ASSIGN bNovoEvento.situacao = "CONCLUIDO"
           bNovoEvento.dt-conclusao = NOW
           bNovoEvento.resultado = "etiquetas=" + STRING(iSeq)
           bNovoEvento.dt-alteracao = NOW
           bNovoEvento.versao = bNovoEvento.versao + 1
           plSucesso = YES pcErro = "" pcMensagem = "".
END.
END PROCEDURE.


/* E09: selecao de remessa classificada pelo cadastro, sem aplicar efeito fisico. */
PROCEDURE registrarSelecaoRemessaAposWt:
DEFINE INPUT PARAMETER piSeqWtDocto AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcEstabelOrig AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcEstabelDest AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piEmitente AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcUsuario AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER TABLE FOR ttEmbSelecaoSaida.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piOperacao AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.

DEFINE BUFFER bWtSelecao FOR mgcad.wt-docto.
DEFINE BUFFER bEstabelOrig FOR mgcad.estabelec.
DEFINE BUFFER bEstabelDest FOR mgcad.estabelec.
DEFINE BUFFER bEmitenteRemessa FOR mgcad.emitente.
DEFINE BUFFER bOperSelecao FOR mgesp.contr_emb_oper.
DEFINE BUFFER bOperAnterior FOR mgesp.contr_emb_oper.
DEFINE BUFFER bLinhaSelecao FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bLinhaAnterior FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bEtiquetaSelecao FOR mgesp.contr_emb_etiqueta.
DEFINE VARIABLE cFluxoRemessa AS CHARACTER NO-UNDO.
DEFINE VARIABLE cRamoRemessa AS CHARACTER NO-UNDO.
DEFINE VARIABLE lOrigemRemessa AS LOGICAL NO-UNDO.
DEFINE VARIABLE lQuantidadeRemessa AS LOGICAL NO-UNDO.
DEFINE VARIABLE lPrecoRemessa AS LOGICAL NO-UNDO.
DEFINE VARIABLE lOkRemessa AS LOGICAL NO-UNDO.
DEFINE VARIABLE iLinhas AS INTEGER NO-UNDO.
DEFINE VARIABLE iLinhasGravadas AS INTEGER NO-UNDO.
DEFINE VARIABLE iUltimaEtiqueta AS INTEGER NO-UNDO.
DEFINE VARIABLE iSequencia AS INTEGER NO-UNDO.
DEFINE VARIABLE dtAgora AS DATETIME-TZ NO-UNDO.

ASSIGN plSucesso = NO plRepeticao = NO piOperacao = 0
       pcErro = "PARAMETRO_INVALIDO".
IF piSeqWtDocto = ? OR piSeqWtDocto <= 0 OR
   pcEstabelOrig = ? OR TRIM(pcEstabelOrig) = "" OR
   pcEstabelDest = ? OR
   pcEstabelOrig = pcEstabelDest OR
   pcUsuario = ? OR TRIM(pcUsuario) = "" THEN RETURN.
IF NOT CONNECTED("mgmov") OR NOT CONNECTED("mgesp") OR
   NOT CONNECTED("mgcad") THEN DO:
    pcErro = "BANCO_NAO_CONECTADO".
    RETURN.
END.
FIND FIRST bWtSelecao NO-LOCK
    WHERE bWtSelecao.seq-wt-docto = piSeqWtDocto NO-ERROR.
IF NOT AVAILABLE bWtSelecao THEN DO:
    pcErro = "WT_NAO_ENCONTRADO".
    RETURN.
END.
RUN classificarNaturezaOperacao (INPUT bWtSelecao.nat-operacao,
    OUTPUT cFluxoRemessa, OUTPUT cRamoRemessa, OUTPUT lOrigemRemessa,
    OUTPUT lQuantidadeRemessa, OUTPUT lPrecoRemessa, OUTPUT lOkRemessa, OUTPUT pcErro).
IF lOkRemessa <> YES OR cFluxoRemessa <> "REMESSA_TERCEIROS" THEN DO:
    pcErro = "NATUREZA_FORA_DA_REMESSA".
    RETURN.
END.
IF bWtSelecao.cod-estabel <> pcEstabelOrig OR bWtSelecao.cod-emitente <> piEmitente THEN DO:
    pcErro = "WT_DIVERGENTE_DA_REMESSA".
    RETURN.
END.
FIND FIRST bEstabelOrig NO-LOCK
    WHERE bEstabelOrig.cod-estabel = pcEstabelOrig NO-ERROR.
IF NOT AVAILABLE bEstabelOrig THEN DO:
    pcErro = "ESTABELECIMENTO_NAO_ENCONTRADO".
    RETURN.
END.
IF piEmitente = ? OR piEmitente <= 0 THEN DO:
    pcErro = "EMITENTE_DESTINO_DIVERGENTE".
    RETURN.
END.
FIND FIRST bEmitenteRemessa NO-LOCK WHERE bEmitenteRemessa.cod-emitente = piEmitente NO-ERROR.
IF NOT AVAILABLE bEmitenteRemessa THEN DO:
    pcErro = "EMITENTE_NAO_ENCONTRADO".
    RETURN.
END.
/* Armazenador externo nao precisa existir como estabelecimento nosso. */
IF pcEstabelDest <> "" THEN DO:
    FIND FIRST bEstabelDest NO-LOCK WHERE bEstabelDest.cod-estabel = pcEstabelDest NO-ERROR.
    IF NOT AVAILABLE bEstabelDest OR bEstabelDest.cod-emitente <> piEmitente THEN DO:
        pcErro = "EMITENTE_DESTINO_DIVERGENTE".
        RETURN.
    END.
END.
/* A tabela de entrada nao e unica: duplicacao deve ser recusada explicitamente. */
ASSIGN iUltimaEtiqueta = 0 pcErro = "SELECAO_INVALIDA".
FOR EACH ttEmbSelecaoSaida BY ttEmbSelecaoSaida.id-etiqueta:
    IF ttEmbSelecaoSaida.id-etiqueta = ? OR
       ttEmbSelecaoSaida.id-etiqueta <= 0 OR
       ttEmbSelecaoSaida.quantidade = ? OR
       ttEmbSelecaoSaida.quantidade <= 0 THEN RETURN.
    IF ttEmbSelecaoSaida.id-etiqueta = iUltimaEtiqueta THEN DO:
        pcErro = "ETIQUETA_DUPLICADA".
        RETURN.
    END.
    ASSIGN iUltimaEtiqueta = ttEmbSelecaoSaida.id-etiqueta
           iLinhas = iLinhas + 1.
END.
IF iLinhas = 0 THEN DO:
    pcErro = "SELECAO_VAZIA".
    RETURN.
END.

/* Uma resposta perdida pode repetir o mesmo WT; comparar a selecao inteira. */
FIND FIRST bOperSelecao NO-LOCK
    WHERE bOperSelecao.seq-wt-docto = piSeqWtDocto
    USE-INDEX pk NO-ERROR.
IF AVAILABLE bOperSelecao THEN DO:
    ASSIGN pcErro = "WT_JA_VINCULADO"
           piOperacao = bOperSelecao.id-operacao.
    IF bOperSelecao.tipo-operacao <> "REMESSA_TERCEIROS" OR
       bOperSelecao.situacao = "CANCELADA" OR
       bOperSelecao.cod-estabel-orig <> pcEstabelOrig OR
       bOperSelecao.cod-estabel-dest <> pcEstabelDest OR
       bOperSelecao.cod-emitente <> piEmitente THEN RETURN.
    FOR EACH bLinhaSelecao NO-LOCK
        WHERE bLinhaSelecao.id-operacao = piOperacao
          AND bLinhaSelecao.tipo-item = "SOLICITACAO":
        iLinhasGravadas = iLinhasGravadas + 1.
        FIND FIRST ttEmbSelecaoSaida
            WHERE ttEmbSelecaoSaida.id-etiqueta = bLinhaSelecao.id-etiqueta
              AND ttEmbSelecaoSaida.quantidade = bLinhaSelecao.quantidade
            NO-ERROR.
        IF NOT AVAILABLE ttEmbSelecaoSaida THEN RETURN.
    END.
    IF iLinhasGravadas <> iLinhas THEN RETURN.
    ASSIGN plSucesso = YES plRepeticao = YES pcErro = "".
    RETURN.
END.

selecaoTransacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    /* Bloqueio das etiquetas serializa duas selecoes concorrentes. */
    FOR EACH ttEmbSelecaoSaida BY ttEmbSelecaoSaida.id-etiqueta:
        FIND FIRST bEtiquetaSelecao EXCLUSIVE-LOCK
            WHERE bEtiquetaSelecao.id-etiqueta = ttEmbSelecaoSaida.id-etiqueta
            NO-WAIT NO-ERROR.
        IF LOCKED bEtiquetaSelecao THEN DO:
            pcErro = "ETIQUETA_BLOQUEADA".
            UNDO selecaoTransacao, LEAVE selecaoTransacao.
        END.
        IF NOT AVAILABLE bEtiquetaSelecao THEN DO:
            pcErro = "ETIQUETA_NAO_ENCONTRADA".
            UNDO selecaoTransacao, LEAVE selecaoTransacao.
        END.
        IF bEtiquetaSelecao.tipo-controle <> "EMBALAGEM" OR
           bEtiquetaSelecao.situacao <> "ATIVA" OR
           bEtiquetaSelecao.tipo-local <> "ESTAB" OR
           bEtiquetaSelecao.cod-estabel <> pcEstabelOrig OR
           bEtiquetaSelecao.id-bag <> ? OR
           bEtiquetaSelecao.qtidade-atu <> ttEmbSelecaoSaida.quantidade THEN DO:
            pcErro = "ETIQUETA_INDISPONIVEL".
            UNDO selecaoTransacao, LEAVE selecaoTransacao.
        END.
        FOR EACH bLinhaAnterior NO-LOCK
            WHERE bLinhaAnterior.id-etiqueta = ttEmbSelecaoSaida.id-etiqueta
              AND bLinhaAnterior.tipo-item = "SOLICITACAO":
            FIND FIRST bOperAnterior NO-LOCK
                WHERE bOperAnterior.id-operacao = bLinhaAnterior.id-operacao
                NO-ERROR.
            IF AVAILABLE bOperAnterior AND
               LOOKUP(bOperAnterior.situacao, "RASCUNHO,SOLICITADA,EM_EXECUCAO") > 0 THEN DO:
                pcErro = "ETIQUETA_JA_SELECIONADA".
                UNDO selecaoTransacao, LEAVE selecaoTransacao.
            END.
        END.
    END.

    ASSIGN dtAgora = NOW
           piOperacao = NEXT-VALUE(CONTR_EMB_OPER_ID_SEQ, mgesp).
    CREATE bOperSelecao.
    ASSIGN bOperSelecao.id-operacao = piOperacao
           bOperSelecao.seq-wt-docto = piSeqWtDocto
           bOperSelecao.tipo-operacao = "REMESSA_TERCEIROS"
           bOperSelecao.cod-estabel-orig = pcEstabelOrig
           bOperSelecao.cod-estabel-dest = pcEstabelDest
           bOperSelecao.cod-emitente = piEmitente
           bOperSelecao.situacao = "SOLICITADA"
           bOperSelecao.dt-operacao = dtAgora
           bOperSelecao.dt-inclusao = dtAgora
           bOperSelecao.usuario-inclusao = TRIM(pcUsuario)
           bOperSelecao.dt-alteracao = dtAgora
           bOperSelecao.usuario-alteracao = TRIM(pcUsuario)
           bOperSelecao.versao = 1.
    FOR EACH ttEmbSelecaoSaida BY ttEmbSelecaoSaida.id-etiqueta:
        FIND FIRST bEtiquetaSelecao NO-LOCK
            WHERE bEtiquetaSelecao.id-etiqueta = ttEmbSelecaoSaida.id-etiqueta
            NO-ERROR.
        ASSIGN iSequencia = iSequencia + 1.
        CREATE bLinhaSelecao.
        ASSIGN bLinhaSelecao.id-item-oper =
                   NEXT-VALUE(CONTR_EMB_OPER_ITEM_ID_SEQ, mgesp)
               bLinhaSelecao.id-operacao = piOperacao
               bLinhaSelecao.sequencia = iSequencia
               bLinhaSelecao.id-etiqueta = ttEmbSelecaoSaida.id-etiqueta
               bLinhaSelecao.it-codigo = bEtiquetaSelecao.it-codigo
               bLinhaSelecao.un = bEtiquetaSelecao.un
               bLinhaSelecao.quantidade = ttEmbSelecaoSaida.quantidade
               bLinhaSelecao.lote = bEtiquetaSelecao.lote
               bLinhaSelecao.dt-vali-lote = bEtiquetaSelecao.dt-vali-lote
               bLinhaSelecao.cod-tipo = bEtiquetaSelecao.cod-tipo
               bLinhaSelecao.tipo-item = "SOLICITACAO"
               bLinhaSelecao.dt-inclusao = dtAgora
               bLinhaSelecao.usuario-inclusao = TRIM(pcUsuario)
               bLinhaSelecao.dt-alteracao = dtAgora
               bLinhaSelecao.usuario-alteracao = TRIM(pcUsuario)
               bLinhaSelecao.versao = 1.
    END.
    ASSIGN plSucesso = YES pcErro = "".
END.
IF NOT plSucesso THEN piOperacao = 0.
END PROCEDURE.



