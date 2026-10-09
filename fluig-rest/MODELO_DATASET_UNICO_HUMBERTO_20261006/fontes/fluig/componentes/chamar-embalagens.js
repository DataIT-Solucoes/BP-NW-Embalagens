/* DT-116: transporte para o NOVO contrato dsNwEmbalagens (uma linha JSON).
   Nao substituir consultar-dataset-rest.js usado por Datasets tabulares antigos.
   Sem retry automatico, inclusive para comandos. */
async function chamarEmbalagens(acao, parametros, opcoes) {
    opcoes = opcoes || {};
    if (typeof acao !== "string" || !acao || !parametros ||
        Object.prototype.toString.call(parametros) !== "[object Object]") {
        throw new Error("Informe acao e parametros de negocio.");
    }
    const resposta = await fetch("/api/public/ecm/dataset/search", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json" },
        signal: opcoes.signal,
        body: JSON.stringify({
            datasetId: "dsNwEmbalagens",
            filterFields: ["acao", acao, "parametros", JSON.stringify(parametros)],
            resultFields: [], limit: "1", orderBy: ""
        })
    });
    if (!resposta.ok) throw new Error("Falha HTTP " + resposta.status + " no transporte Fluig.");
    let transporte;
    try { transporte = await resposta.json(); }
    catch (erro) { throw new Error("O Fluig nao retornou JSON valido."); }
    if (!transporte || !Array.isArray(transporte.content) || transporte.content.length !== 1) {
        throw new Error("Dataset fora do contrato de uma linha de envelope.");
    }
    const linha = transporte.content[0];
    if (linha.acao && linha.acao !== acao) throw new Error("Acao da resposta divergente.");
    let resultado;
    try { resultado = JSON.parse(linha.resultadoJson); }
    catch (erro) { throw new Error("Envelope JSON do Dataset invalido."); }
    if (!resultado || typeof resultado.sucesso !== "boolean" ||
        String(resultado.sucesso) !== String(linha.sucesso)) {
        throw new Error("Resultado funcional do Dataset invalido.");
    }
    // Recusas funcionais retornam sucesso=false/codigoErro; nao viram lista vazia.
    // Preserva geracao/itens/etiquetas, classificacao de natureza, WT e repeticao.
    return resultado;
}
