<div id="widget_nw_recebimentos_${instanceId}" class="super-widget wcm-widget-class fluig-style-guide nwr" data-params="widget_nw_recebimentos.instance()">
    <header class="nwr-cabecalho">
        <span class="nwr-selo" aria-hidden="true">▤</span>
        <div><h2>Documentos de recebimento</h2><p>Acompanhe documentos, itens e embalagens das fazendas.</p></div>
        <span class="nwr-etiqueta">Somente consulta</span>
    </header>
    <form data-filtros class="nwr-filtros" novalidate>
        <div class="nwr-fazenda">
            <label for="nwr-termo-${instanceId}">Fazenda autorizada</label>
            <div class="nwr-linha"><input id="nwr-termo-${instanceId}" data-termo-fazenda class="form-control" maxlength="100" placeholder="Código ou nome (mínimo 2 caracteres)" autocomplete="off"><button type="button" data-buscar-fazendas class="nwr-botao">Consultar fazendas</button></div>
            <select id="nwr-fazenda-${instanceId}" data-fazenda class="form-control" aria-label="Selecione a fazenda autorizada"><option value="">Selecione uma fazenda consultada</option></select>
            <div class="nwr-linha nwr-apoio"><span data-mensagem-fazendas role="status"></span><button type="button" data-fazendas-anterior class="nwr-botao" disabled>Anterior</button><button type="button" data-fazendas-proxima class="nwr-botao" disabled>Próxima</button></div>
        </div>
        <div class="nwr-periodo">
        <div><label for="nwr-tipo-data-${instanceId}">Período por</label><select id="nwr-tipo-data-${instanceId}" data-campo="tipoData" class="form-control"><option value="EMISSAO">Emissão</option><option value="TRANSACAO">Transação</option></select></div>
        <div><label for="nwr-inicio-${instanceId}">De</label><input type="date" id="nwr-inicio-${instanceId}" data-campo="dataIni" class="form-control" required></div>
        <div><label for="nwr-fim-${instanceId}">Até</label><input type="date" id="nwr-fim-${instanceId}" data-campo="dataFim" class="form-control" required></div>
        </div>
        <div><label for="nwr-emitente-${instanceId}">Emitente (código exato)</label><input id="nwr-emitente-${instanceId}" data-campo="emitente" class="form-control" maxlength="10" inputmode="numeric"></div>
        <div><label for="nwr-serie-${instanceId}">Série</label><input id="nwr-serie-${instanceId}" data-campo="serie" class="form-control" maxlength="100"></div>
        <div><label for="nwr-numero-${instanceId}">Documento</label><input id="nwr-numero-${instanceId}" data-campo="numero" class="form-control" maxlength="100"></div>
        <div><label for="nwr-natureza-${instanceId}">Natureza</label><input id="nwr-natureza-${instanceId}" data-campo="natureza" class="form-control" maxlength="100"></div>
        <div><label for="nwr-item-${instanceId}">Item (código exato)</label><input id="nwr-item-${instanceId}" data-campo="item" class="form-control" maxlength="100"></div>
        <div><label for="nwr-etiqueta-${instanceId}">Etiqueta histórica</label><input id="nwr-etiqueta-${instanceId}" data-campo="etiqueta" class="form-control" maxlength="100"></div>
        <div><label for="nwr-atualizado-${instanceId}">Estoque</label><select id="nwr-atualizado-${instanceId}" data-campo="atualizado" class="form-control"><option value="todos">Todos</option><option value="true">Atualizado</option><option value="false">Não atualizado</option></select></div>
        <div><label for="nwr-embalagens-${instanceId}">Embalagens</label><select id="nwr-embalagens-${instanceId}" data-campo="somenteComEmbalagens" class="form-control"><option value="false">Todos os documentos</option><option value="true">Somente com participação histórica</option></select></div>
        <div class="nwr-acoes"><button type="button" class="nwr-botao" data-limpar>Limpar</button><button type="submit" class="nwr-botao nwr-principal" data-buscar>Buscar documentos</button></div>
    </form>
    <p class="nwr-nota">Estoque não atualizado indica que o documento ainda não atualizou o estoque ou foi desatualizado. Não significa automaticamente cancelamento ou erro.</p>
    <p data-mensagem-documentos class="nwr-mensagem" role="status" aria-live="polite">Selecione a fazenda e o período para consultar.</p>
    <div class="nwr-grade" data-grade-documentos></div>
    <div class="nwr-rodape"><span data-resumo-documentos></span><div><button type="button" data-anterior-documentos class="nwr-botao" disabled>Anterior</button><button type="button" data-proxima-documentos class="nwr-botao" disabled>Próxima</button></div></div>
    <div data-modal class="nwr-fundo" hidden>
        <section class="nwr-modal" role="dialog" aria-modal="true" aria-labelledby="nwr-titulo-detalhe-${instanceId}" tabindex="-1">
            <header class="nwr-linha"><h3 id="nwr-titulo-detalhe-${instanceId}">Detalhe do recebimento</h3><button type="button" data-fechar class="nwr-botao" aria-label="Fechar detalhe">Fechar</button></header>
            <div data-cabecalho class="nwr-cabecalho-documento"></div>
            <p class="nwr-nota">As quantidades das embalagens pertencem ao recebimento selecionado, mesmo que elas já tenham sido movimentadas depois. Não representam saldo atual.</p>
            <label for="nwr-ciclo-${instanceId}">Ciclo do recebimento</label><select id="nwr-ciclo-${instanceId}" data-ciclo class="form-control"></select>
            <p data-resumo-ciclo class="nwr-nota"></p>
            <details><summary>Ciclos e compensações</summary><div data-ciclos class="nwr-grade"></div></details>
            <nav class="nwr-abas" role="tablist" aria-label="Detalhes do documento">
                <button type="button" id="nwr-aba-itens-${instanceId}" data-aba="itens" role="tab" aria-controls="nwr-painel-itens-${instanceId}" aria-selected="true" class="nwr-aba ativa">Itens</button>
                <button type="button" id="nwr-aba-embalagens-${instanceId}" data-aba="embalagens" role="tab" aria-controls="nwr-painel-embalagens-${instanceId}" aria-selected="false" class="nwr-aba" tabindex="-1">Embalagens</button>
            </nav>
            <div id="nwr-painel-itens-${instanceId}" data-painel="itens" role="tabpanel" aria-labelledby="nwr-aba-itens-${instanceId}">
                <p data-mensagem-itens class="nwr-mensagem" role="status"></p><div data-grade-itens class="nwr-grade"></div>
                <div class="nwr-rodape"><span data-resumo-itens></span><div><button type="button" data-anterior-itens class="nwr-botao" disabled>Anterior</button><button type="button" data-proxima-itens class="nwr-botao" disabled>Próxima</button></div></div>
            </div>
            <div id="nwr-painel-embalagens-${instanceId}" data-painel="embalagens" role="tabpanel" aria-labelledby="nwr-aba-embalagens-${instanceId}" hidden>
                <label for="nwr-sequencia-${instanceId}">Sequência da linha (opcional)</label><div class="nwr-linha"><input id="nwr-sequencia-${instanceId}" data-sequencia class="form-control nwr-curto" inputmode="numeric" maxlength="10"><button type="button" data-filtrar-embalagens class="nwr-botao">Consultar linha</button></div>
                <p data-mensagem-embalagens class="nwr-mensagem" role="status"></p><div data-grade-embalagens class="nwr-grade"></div>
                <div class="nwr-rodape"><span data-resumo-embalagens></span><div><button type="button" data-anterior-embalagens class="nwr-botao" disabled>Anterior</button><button type="button" data-proxima-embalagens class="nwr-botao" disabled>Próxima</button></div></div>
            </div>
        </section>
    </div>
</div>
