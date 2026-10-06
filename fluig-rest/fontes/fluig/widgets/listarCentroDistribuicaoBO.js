var consultaCdController = null;

async function listarCentroDistribuicaoBO(filtroDigitado = "") {
    const filtro = String(filtroDigitado || "").trim();
    const limite = "20";
    const filterFields = ["limit", limite];

    if (filtro !== "") {
        filterFields.unshift("filtro", filtro);
    }

    if (consultaCdController) {
        consultaCdController.abort();
    }

    consultaCdController = new AbortController();
    const controllerAtual = consultaCdController;

    try {
        const res = await fetch("/api/public/ecm/dataset/search", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            credentials: "same-origin",
            signal: controllerAtual.signal,
            body: JSON.stringify({
                datasetId: "dsControleEmbalagensAPI",
                filterFields: filterFields,
                resultFields: [],
                limit: limite,
                orderBy: ""
            })
        });

        if (!res.ok) {
            throw new Error("Erro HTTP " + res.status + " - " + res.statusText);
        }

        const json = await res.json();

        if (controllerAtual !== consultaCdController) {
            return null;
        }

        const linhas = Array.isArray(json.content) ? json.content : [];
        const erroDataset = linhas.find(function (linha) {
            return String(linha.sucesso) !== "true";
        });

        if (erroDataset) {
            throw new Error(
                erroDataset.mensagem || "O dataset retornou uma falha."
            );
        }

        return linhas
            .filter(function (linha) {
                return linha.codEstabel;
            })
            .map(function (linha) {
                return {
                    "cod-estabel": linha.codEstabel,
                    "nome": linha.nomeEstabel
                };
            });

    } catch (erro) {
        if (erro.name === "AbortError") {
            return null;
        }

        console.error("Erro ao consultar CDs:", erro);
        return [];
    }
}

/*
 * Quem chama deve ignorar null, pois representa uma consulta cancelada:
 *
 * const cds = await listarCentroDistribuicaoBO(valorDigitado);
 * if (cds === null) return;
 * atualizarAutocomplete(cds);
 */
