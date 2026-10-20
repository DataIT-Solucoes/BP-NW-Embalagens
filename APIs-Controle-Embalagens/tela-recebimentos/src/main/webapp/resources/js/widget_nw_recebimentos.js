var widget_nw_recebimentos = SuperWidget.extend({
    init: function () {
        var tela = this;
        this.$raiz = $('#widget_nw_recebimentos_' + this.instanceId);
        this.versaoConsulta = 0;
        this.versaoDetalhe = 0;
        this.versaoFazendas = 0;
        this.paginas = {};
        this.fazendas = [];
        this.fazenda = '';
        this.documento = null;
        this.aba = 'itens';
        this.definirPeriodo();
        this.$raiz.on('submit', '[data-filtros]', function (evento) { evento.preventDefault(); tela.buscar(); });
        this.$raiz.on('click', '[data-buscar-fazendas]', function () { tela.buscarFazendas(''); });
        this.$raiz.on('input', '[data-termo-fazenda]', function () { tela.limparFazenda(); });
        this.$raiz.on('change', '[data-fazenda]', function () { tela.selecionarFazenda(); });
        this.$raiz.on('input change', '[data-campo]', function () { tela.invalidarConsulta(); });
        this.$raiz.on('click', '[data-limpar]', function () { tela.limpar(); });
        ['documentos', 'itens', 'embalagens'].forEach(function (nome) {
            tela.$raiz.on('click', '[data-anterior-' + nome + ']', function () { tela.paginar(nome, -1); });
            tela.$raiz.on('click', '[data-proxima-' + nome + ']', function () { tela.paginar(nome, 1); });
        });
        this.$raiz.on('click', '[data-fazendas-anterior]', function () { tela.paginarFazendas(-1); });
        this.$raiz.on('click', '[data-fazendas-proxima]', function () { tela.paginarFazendas(1); });
        this.$raiz.on('click', '[data-detalhar]', function () { tela.abrirDetalhe(Number($(this).attr('data-detalhar'))); });
        this.$raiz.on('click', '[data-fechar]', function () { tela.fecharDetalhe(); });
        this.$raiz.on('click', '[data-aba]', function () { tela.trocarAba($(this).attr('data-aba')); });
        this.$raiz.on('keydown', '[data-aba]', function (e) {
            if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
                e.preventDefault(); tela.trocarAba(tela.aba === 'itens' ? 'embalagens' : 'itens');
                tela.$raiz.find('[data-aba="' + tela.aba + '"]').trigger('focus');
            }
        });
        this.$raiz.on('change', '[data-ciclo]', function () { tela.trocarCiclo(); });
        this.$raiz.on('click', '[data-filtrar-embalagens]', function () { tela.filtrarEmbalagens(); });
        this.$raiz.on('input', '[data-sequencia]', function () { tela.limparPagina('embalagens'); });
        this.$raiz.on('keydown', '[data-modal]', function (evento) { tela.teclaModal(evento); });
        this.invalidarConsulta();
    },

    bindings: { local: {}, global: {} },

    chamar: function (acao, parametros) {
        var permitido = ['apoiarEstabelecimentos', 'consultarRecebimentos', 'consultarItensRecebimento', 'consultarEmbalagensRecebimento'];
        if (permitido.indexOf(acao) < 0) return $.Deferred().reject('Consulta indisponível.').promise();
        return $.ajax({
            url: '/api/public/ecm/dataset/search', type: 'POST', contentType: 'application/json', dataType: 'json', timeout: 60000,
            data: JSON.stringify({ datasetId: 'dsNwEmbalagens', filterFields: ['acao', acao, 'parametros', JSON.stringify(parametros)], resultFields: [], limit: '1', orderBy: '' })
        }).then(function (transporte) {
            try {
                if (!transporte || !Array.isArray(transporte.content) || transporte.content.length !== 1) throw new Error();
                var resposta = JSON.parse(transporte.content[0].resultadoJson);
                if (!resposta || typeof resposta.sucesso !== 'boolean') throw new Error();
                if (!resposta.sucesso) return $.Deferred().reject(resposta.codigoErro || 'RECUSA_API').promise();
                if (!Array.isArray(resposta.dados) || typeof resposta.temMais !== 'boolean' || resposta.total !== resposta.dados.length) throw new Error();
                return resposta;
            } catch (erro) { return $.Deferred().reject('RESPOSTA_INVALIDA').promise(); }
        }, function () { return $.Deferred().reject('FALHA_TRANSPORTE').promise(); });
    },

    erro: function (codigo) {
        var textos = {
            SEM_PERMISSAO: 'Você não tem permissão para esta consulta.',
            DOCUMENTO_INDISPONIVEL: 'Documento indisponível para consulta.',
            CONSULTA_AMPLA: 'O período contém muitos documentos. Reduza o período e pesquise novamente.',
            FILTRO_INVALIDO: 'Confira os filtros e o período informado.',
            VINCULO_LINHA_NAO_COMPROVADO: 'O vínculo histórico com a linha não foi comprovado. Consulte todas as embalagens do documento, sem filtrar a sequência.',
            HISTORICO_INCONSISTENTE: 'O histórico exige verificação. Este resultado não significa ausência de embalagens.',
            CICLO_NAO_CONCLUIDO: 'Este ciclo não está concluído e não pode fornecer quantidades confirmadas.',
            CICLO_INDISPONIVEL: 'O ciclo mudou ou está indisponível. Pesquise o documento novamente.',
            RESPOSTA_INVALIDA: 'A consulta retornou um resultado incompatível. Tente uma nova pesquisa.',
            FALHA_TRANSPORTE: 'Não foi possível consultar. Verifique sua sessão e tente novamente.'
        };
        return textos[codigo] || 'Não foi possível concluir a consulta. Verifique os filtros e a disponibilidade do serviço.';
    },

    mensagem: function (nome, texto, falha) {
        this.$raiz.find('[data-mensagem-' + nome + ']').text(texto).toggleClass('nwr-erro', !!falha);
    },

    definirPeriodo: function () {
        var hoje = new Date(), ano = hoje.getFullYear(), mes = ('0' + (hoje.getMonth() + 1)).slice(-2);
        this.$raiz.find('[data-campo="dataIni"]').val(ano + '-' + mes + '-01');
        this.$raiz.find('[data-campo="dataFim"]').val(ano + '-' + mes + '-' + ('0' + hoje.getDate()).slice(-2));
    },

    limparPagina: function (nome) {
        var anterior = this.paginas[nome];
        this.paginas[nome] = { cursores: [''], indice: 0, proximo: '', dados: [], carregada: false, ocupada: false, pedido: anterior ? anterior.pedido + 1 : 1 };
        this.$raiz.find('[data-grade-' + nome + '],[data-resumo-' + nome + ']').empty();
        this.$raiz.find('[data-anterior-' + nome + '],[data-proxima-' + nome + ']').prop('disabled', true);
    },

    invalidarConsulta: function () {
        this.versaoConsulta++;
        this.filtros = null;
        this.limparPagina('documentos');
        this.$raiz.find('[data-buscar]').prop('disabled', false);
        this.fecharDetalhe();
        this.mensagem('documentos', 'Defina os filtros e clique em Buscar documentos.');
    },

    limparFazenda: function () {
        this.versaoFazendas++;
        this.fazenda = '';
        this.fazendas = [];
        this.paginaFazendas = null;
        this.$raiz.find('[data-fazenda]').empty().append($('<option>').val('').text('Selecione uma fazenda consultada'));
        this.$raiz.find('[data-fazendas-anterior],[data-fazendas-proxima]').prop('disabled', true);
        this.$raiz.find('[data-buscar-fazendas]').prop('disabled', false);
        this.mensagem('fazendas', '');
        this.invalidarConsulta();
    },

    selecionarFazenda: function () {
        var codigo = this.$raiz.find('[data-fazenda]').val();
        this.fazenda = this.fazendas.some(function (f) { return f.codigo === codigo; }) ? codigo : '';
        this.invalidarConsulta();
    },

    buscarFazendas: function (cursor, indice) {
        var tela = this, termo = this.$raiz.find('[data-termo-fazenda]').val().trim();
        if (termo.length < 2) { this.mensagem('fazendas', 'Digite ao menos dois caracteres.', true); return; }
        if (this.paginaFazendas && this.paginaFazendas.ocupada) return;
        if (indice === undefined) this.paginaFazendas = { cursores: [''], indice: 0 };
        var pagina = this.paginaFazendas, versao = ++this.versaoFazendas;
        pagina.ocupada = true;
        this.fazenda = '';
        this.fazendas = [];
        this.invalidarConsulta();
        this.$raiz.find('[data-fazenda]').empty();
        this.$raiz.find('[data-buscar-fazendas],[data-fazendas-anterior],[data-fazendas-proxima]').prop('disabled', true);
        this.mensagem('fazendas', 'Consultando fazendas autorizadas…');
        var filtros = { filtro: termo, limite: 20 };
        if (cursor) filtros.aposCodigo = cursor;
        this.chamar('apoiarEstabelecimentos', filtros).done(function (r) {
            if (versao !== tela.versaoFazendas) return;
            if (r.temMais && (typeof r.proximoCodigo !== 'string' || !r.proximoCodigo || r.proximoCodigo === cursor)) {
                tela.mensagem('fazendas', tela.erro('RESPOSTA_INVALIDA'), true); return;
            }
            tela.fazendas = r.dados;
            pagina.indice = indice || 0;
            pagina.proximo = r.temMais ? r.proximoCodigo : '';
            var $lista = tela.$raiz.find('[data-fazenda]').append($('<option>').val('').text('Selecione uma fazenda'));
            r.dados.forEach(function (f) { $lista.append($('<option>').val(f.codigo).text(f.codigo + ' — ' + (f.descricao || ''))); });
            tela.mensagem('fazendas', r.dados.length ? r.dados.length + ' fazenda(s) nesta página.' : 'Nenhuma fazenda autorizada encontrada.');
        }).fail(function (codigo) {
            if (versao === tela.versaoFazendas) { pagina.proximo = ''; tela.mensagem('fazendas', tela.erro(codigo), true); }
        }).always(function () {
            if (versao !== tela.versaoFazendas) return;
            pagina.ocupada = false;
            tela.$raiz.find('[data-buscar-fazendas]').prop('disabled', false);
            tela.$raiz.find('[data-fazendas-anterior]').prop('disabled', pagina.indice === 0);
            tela.$raiz.find('[data-fazendas-proxima]').prop('disabled', !pagina.proximo);
        });
    },

    paginarFazendas: function (direcao) {
        var p = this.paginaFazendas;
        if (!p || p.ocupada || (direcao > 0 && !p.proximo) || (direcao < 0 && !p.indice)) return;
        var indice = p.indice + direcao;
        if (direcao > 0) p.cursores[indice] = p.proximo;
        this.buscarFazendas(p.cursores[indice], indice);
    },

    limpar: function () {
        this.$raiz.find('[data-filtros]')[0].reset();
        this.definirPeriodo();
        this.limparFazenda();
    },

    buscar: function () {
        if (this.paginas.documentos.ocupada) return;
        var tela = this, filtros = { codEstabel: this.fazenda, limite: 20 };
        this.$raiz.find('[data-campo]').each(function () { var valor = $(this).val().trim(); if (valor) filtros[$(this).attr('data-campo')] = valor; });
        var ini = Date.parse(filtros.dataIni), fim = Date.parse(filtros.dataFim);
        this.invalidarConsulta();
        if (!filtros.codEstabel) { this.mensagem('documentos', 'Selecione uma fazenda autorizada na consulta.', true); return; }
        if (!isFinite(ini) || !isFinite(fim) || ini > fim || (fim - ini) / 86400000 > 365) {
            this.mensagem('documentos', 'Informe um período válido de até 366 dias, incluindo início e fim.', true); return;
        }
        if (filtros.emitente && (!/^[0-9]+$/.test(filtros.emitente) || Number(filtros.emitente) > 2147483647)) {
            this.mensagem('documentos', 'Informe um código numérico válido para o emitente.', true); return;
        }
        tela.filtros = filtros;
        tela.carregar('documentos', '', 0);
    },

    paginar: function (nome, direcao) {
        var p = this.paginas[nome];
        if (!p || p.ocupada || (direcao > 0 && !p.proximo) || (direcao < 0 && !p.indice)) return;
        var indice = p.indice + direcao;
        if (direcao > 0) p.cursores[indice] = p.proximo;
        this.carregar(nome, p.cursores[indice], indice);
    },

    chave: function (documento) {
        var chave = {};
        ['codEstabel', 'emitente', 'serie', 'numero', 'natureza'].forEach(function (campo) { chave[campo] = documento[campo]; });
        return chave;
    },

    mesmaChave: function (a, b) {
        return a && b && ['codEstabel', 'emitente', 'serie', 'numero', 'natureza'].every(function (campo) { return typeof a[campo] === 'string' && a[campo] === b[campo]; });
    },

    carregar: function (nome, cursor, indice) {
        var tela = this, p = this.paginas[nome], detalhe = nome !== 'documentos';
        if (!p || p.ocupada || !this.filtros || (detalhe && !this.documento)) return;
        var parametros = detalhe ? this.chave(this.documento) : $.extend({}, this.filtros);
        var camposCursor = { documentos: 'aposDocumento', itens: 'aposSequencia', embalagens: 'aposId' };
        var proximos = { documentos: 'proximoDocumento', itens: 'proximaSequencia', embalagens: 'proximoId' };
        var acoes = { documentos: 'consultarRecebimentos', itens: 'consultarItensRecebimento', embalagens: 'consultarEmbalagensRecebimento' };
        var versao = this.versaoConsulta, versaoDetalhe = this.versaoDetalhe, pedido = ++p.pedido;
        parametros.limite = 20;
        if (cursor) parametros[camposCursor[nome]] = cursor;
        if (detalhe && this.idEvento) parametros.idEvento = this.idEvento;
        if (nome === 'embalagens' && this.sequencia) parametros.sequencia = this.sequencia;
        p.ocupada = true; p.carregada = false; p.dados = []; p.proximo = '';
        this.$raiz.find('[data-grade-' + nome + '],[data-resumo-' + nome + ']').empty();
        this.$raiz.find('[data-anterior-' + nome + '],[data-proxima-' + nome + ']').prop('disabled', true);
        if (!detalhe) this.$raiz.find('[data-buscar]').prop('disabled', true);
        this.mensagem(nome, 'Carregando…');
        this.chamar(acoes[nome], parametros).done(function (r) {
            if (versao !== tela.versaoConsulta || pedido !== tela.paginas[nome].pedido || (detalhe && versaoDetalhe !== tela.versaoDetalhe)) return;
            var proximo = r.temMais ? r[proximos[nome]] : '';
            var invalida = r.temMais && (typeof proximo !== 'string' || !proximo || proximo === cursor);
            if (!detalhe) invalida = invalida || r.dados.some(function (doc) { return doc.codEstabel !== parametros.codEstabel; });
            if (detalhe) invalida = invalida || !tela.mesmaChave(r.cabecalho, parametros) || !Array.isArray(r.ciclos) ||
                (parametros.idEvento && r.cabecalho.idEvento !== parametros.idEvento) ||
                (tela.idEvento && r.cabecalho.idEvento !== tela.idEvento);
            if (invalida) { tela.mensagem(nome, tela.erro('RESPOSTA_INVALIDA'), true); return; }
            p.indice = indice; p.proximo = proximo; p.dados = r.dados; p.carregada = true;
            if (detalhe) tela.mostrarCabecalho(r);
            tela.renderizar(nome, r.dados);
            var vazio = nome === 'documentos' ? 'Nenhum documento encontrado neste recorte.' : nome === 'itens' ? 'Nenhum item nesta página.' : tela.textoSemEmbalagens(r.cabecalho);
            tela.mensagem(nome, r.dados.length ? '' : vazio);
            tela.$raiz.find('[data-resumo-' + nome + ']').text('Página ' + (indice + 1) + ' · ' + r.dados.length + ' registro(s) nesta página');
        }).fail(function (codigo) {
            if (versao !== tela.versaoConsulta || pedido !== tela.paginas[nome].pedido || (detalhe && versaoDetalhe !== tela.versaoDetalhe)) return;
            tela.mensagem(nome, tela.erro(codigo), true);
            if (codigo === 'SEM_PERMISSAO' || codigo === 'DOCUMENTO_INDISPONIVEL') tela.ocultarDadosDetalhe();
        }).always(function () {
            if (versao !== tela.versaoConsulta || pedido !== tela.paginas[nome].pedido || (detalhe && versaoDetalhe !== tela.versaoDetalhe)) return;
            p.ocupada = false;
            if (!detalhe) tela.$raiz.find('[data-buscar]').prop('disabled', false);
            tela.$raiz.find('[data-anterior-' + nome + ']').prop('disabled', !p.carregada || p.indice === 0);
            tela.$raiz.find('[data-proxima-' + nome + ']').prop('disabled', !p.carregada || !p.proximo);
        });
    },

    textoSemEmbalagens: function (cabecalho) {
        if (cabecalho.situacaoControle === 'PROCESSAMENTO_PENDENTE') return 'Há processamento não concluído no histórico. Esta consulta não comprova ausência de embalagens.';
        if (!cabecalho.idEvento) return 'Nenhum recebimento rastreado confirmado para este documento.';
        return 'Nenhuma embalagem neste recorte do ciclo selecionado.';
    },

    abrirDetalhe: function (indice) {
        var doc = this.paginas.documentos.dados[indice];
        if (!doc || !this.filtros || doc.codEstabel !== this.fazenda) return;
        this.fecharDetalhe();
        this.documento = this.chave(doc);
        this.focoAnterior = this.$raiz.find('[data-detalhar="' + indice + '"]');
        this.idEvento = ''; this.sequencia = '';
        this.$raiz.find('[data-sequencia]').val('');
        this.$raiz.find('[data-modal]').prop('hidden', false);
        this.$raiz.find('.nwr-modal').trigger('focus');
        this.trocarAba('itens');
    },

    ocultarDadosDetalhe: function () {
        var tela = this;
        ['itens', 'embalagens'].forEach(function (nome) {
            if (tela.paginas[nome]) {
                tela.paginas[nome].ocupada = false;
                tela.paginas[nome].carregada = false;
                tela.paginas[nome].dados = [];
                tela.paginas[nome].proximo = '';
            }
        });
        this.$raiz.find('[data-cabecalho],[data-ciclos],[data-resumo-ciclo],[data-grade-itens],[data-grade-embalagens],[data-resumo-itens],[data-resumo-embalagens]').empty();
        this.$raiz.find('[data-ciclo]').empty().prop('disabled', true);
        this.$raiz.find('[data-anterior-itens],[data-proxima-itens],[data-anterior-embalagens],[data-proxima-embalagens]').prop('disabled', true);
        this.documento = null;
        this.versaoDetalhe++;
    },

    fecharDetalhe: function () {
        this.versaoDetalhe++;
        this.documento = null;
        this.idEvento = '';
        this.$raiz.find('[data-modal]').prop('hidden', true);
        this.ocultarDadosDetalhe();
        this.limparPagina('itens'); this.limparPagina('embalagens');
        this.mensagem('itens', ''); this.mensagem('embalagens', '');
        if (this.focoAnterior && this.focoAnterior.length) this.focoAnterior.trigger('focus');
    },

    trocarAba: function (aba) {
        if (['itens', 'embalagens'].indexOf(aba) < 0 || !this.documento) return;
        this.aba = aba;
        this.$raiz.find('[data-aba]').each(function () { var ativa = $(this).attr('data-aba') === aba; $(this).toggleClass('ativa', ativa).attr('aria-selected', String(ativa)).attr('tabindex', ativa ? '0' : '-1'); });
        this.$raiz.find('[data-painel]').each(function () { $(this).prop('hidden', $(this).attr('data-painel') !== aba); });
        if (!this.paginas[aba].carregada) this.carregar(aba, '', 0);
    },

    trocarCiclo: function () {
        this.versaoDetalhe++;
        this.idEvento = this.$raiz.find('[data-ciclo]').val() || '';
        this.$raiz.find('[data-resumo-ciclo]').empty();
        this.limparPagina('itens'); this.limparPagina('embalagens');
        this.sequencia = ''; this.$raiz.find('[data-sequencia]').val('');
        this.carregar(this.aba, '', 0);
    },

    filtrarEmbalagens: function () {
        var sequencia = this.$raiz.find('[data-sequencia]').val().trim();
        if (sequencia && (!/^[1-9][0-9]*$/.test(sequencia) || Number(sequencia) > 2147483647)) { this.mensagem('embalagens', 'Informe uma sequência positiva válida.', true); return; }
        this.sequencia = sequencia;
        this.limparPagina('embalagens');
        this.carregar('embalagens', '', 0);
    },

    teclaModal: function (evento) {
        if (evento.key === 'Escape') { this.fecharDetalhe(); return; }
        if (evento.key !== 'Tab') return;
        var $focos = this.$raiz.find('[data-modal]').find('button:visible:not(:disabled),select:visible:not(:disabled),input:visible:not(:disabled),summary:visible');
        var primeiro = $focos[0], ultimo = $focos[$focos.length - 1];
        if (evento.shiftKey && (evento.target === primeiro || $(evento.target).is('.nwr-modal'))) { evento.preventDefault(); $(ultimo).trigger('focus'); }
        else if (!evento.shiftKey && evento.target === ultimo) { evento.preventDefault(); $(primeiro).trigger('focus'); }
    },

    numero: function (valor) { return typeof valor === 'number' && isFinite(valor) ? valor.toLocaleString('pt-BR', { maximumFractionDigits: 4 }) : 'Não informado'; },
    data: function (valor) { return typeof valor === 'string' && /^\d{4}-\d{2}-\d{2}/.test(valor) ? valor.slice(8, 10) + '/' + valor.slice(5, 7) + '/' + valor.slice(0, 4) : 'Não informada'; },
    estoque: function (valor) { return valor === true ? 'Estoque atualizado' : valor === false ? 'Estoque não atualizado' : 'Atualização não informada'; },
    controle: function (valor) {
        return { RECEBIMENTO_RASTREADO: 'Recebimento rastreado', SEM_RECEBIMENTO_RASTREADO: 'Sem recebimento rastreado', PROCESSAMENTO_PENDENTE: 'Processamento não concluído no histórico' }[valor] || 'Controle não informado';
    },

    tipoCiclo: function (tipo) {
        return { RECEBIMENTO_COMPRA: 'Compra', RECEBIMENTO_TRANSFERENCIA: 'Transferência', RECEBIMENTO_EMPRESTIMO: 'Empréstimo',
            RECEBIMENTO_RETORNO_EMPRESTIMO: 'Retorno de empréstimo', RECEBIMENTO_RETORNO_TERCEIROS: 'Retorno de terceiros' }[tipo] || tipo;
    },

    situacaoCiclo: function (situacao) { return { CONCLUIDO: 'Concluído', ERRO: 'Erro no processamento', PROCESSANDO: 'Em processamento' }[situacao] || situacao; },

    tabela: function ($destino, colunas, linhas) {
        var $tabela = $('<table>'), $cabecalho = $('<tr>'), $corpo = $('<tbody>');
        colunas.forEach(function (coluna) { $cabecalho.append($('<th>').attr('scope', 'col').text(coluna.titulo)); });
        linhas.forEach(function (linha, indice) {
            var $linha = $('<tr>');
            colunas.forEach(function (coluna) { var $celula = $('<td>'); if (coluna.renderizar) coluna.renderizar($celula, linha, indice); else $celula.text(linha[coluna.campo] == null ? 'Não informado' : linha[coluna.campo]); $linha.append($celula); });
            $corpo.append($linha);
        });
        $destino.empty().append($tabela.append($('<thead>').append($cabecalho)).append($corpo));
    },

    mostrarCabecalho: function (r) {
        var tela = this, c = r.cabecalho;
        this.idEvento = c.idEvento || '';
        this.$raiz.find('[data-cabecalho]').text('Fazenda ' + c.codEstabel + ' — ' + (c.descricaoEstabelecimento || '') + ' | Emitente ' + c.emitente + ' — ' + (c.descricaoEmitente || '') + ' | Documento ' + c.numero + ' / série ' + c.serie + ' / natureza ' + c.natureza + ' | ' + this.estoque(c.estoqueAtualizado));
        var $ciclos = this.$raiz.find('[data-ciclo]').empty();
        if (!r.ciclos.length) $ciclos.append($('<option>').val('').text('Sem ciclo rastreado'));
        r.ciclos.forEach(function (ciclo) {
            $ciclos.append($('<option>').val(ciclo.idEvento).text('Ciclo ' + ciclo.ciclo + ' · evento ' + ciclo.idEvento + ' · ' + tela.tipoCiclo(ciclo.tipoEvento) + (ciclo.compensado ? ' · Compensado' : '') + ' · ' + tela.situacaoCiclo(ciclo.situacao)).prop('disabled', ciclo.situacao !== 'CONCLUIDO'));
        });
        $ciclos.val(this.idEvento).prop('disabled', !r.ciclos.some(function (ciclo) { return ciclo.situacao === 'CONCLUIDO'; }));
        this.$raiz.find('[data-resumo-ciclo]').text(this.controle(c.situacaoControle) + (this.idEvento ? ' · Evento consultado ' + this.idEvento : '') + (c.compensado ? ' · Ciclo compensado: participação histórica, sem somar ao ciclo vigente.' : '') + ' · Quantidades de ciclos diferentes não são somadas.');
        this.tabela(this.$raiz.find('[data-ciclos]'), [
            { campo: 'ciclo', titulo: 'Ciclo' }, { campo: 'idEvento', titulo: 'Evento' },
            { titulo: 'Tipo', renderizar: function ($c, l) { $c.text(tela.tipoCiclo(l.tipoEvento)); } },
            { titulo: 'Situação', renderizar: function ($c, l) { $c.text(tela.situacaoCiclo(l.situacao)); } },
            { titulo: 'Data', renderizar: function ($c, l) { $c.text(tela.data(l.dataEvento)); } },
            { titulo: 'Compensação', renderizar: function ($c, l) { $c.text(l.compensado ? 'Compensado pelo evento ' + l.idCompensacao : 'Sem compensação confirmada'); } }
        ], r.ciclos);
    },

    renderizar: function (nome, linhas) {
        var tela = this, colunas;
        if (nome === 'documentos') colunas = [
            { campo: 'codEstabel', titulo: 'Fazenda' }, { titulo: 'Emitente', renderizar: function ($c, l) { $c.text(l.emitente + ' — ' + (l.descricaoEmitente || '')); } },
            { campo: 'numero', titulo: 'Documento' }, { campo: 'serie', titulo: 'Série' }, { campo: 'natureza', titulo: 'Natureza' },
            { titulo: 'Emissão', renderizar: function ($c, l) { $c.text(tela.data(l.dataEmissao)); } }, { titulo: 'Transação', renderizar: function ($c, l) { $c.text(tela.data(l.dataTransacao)); } },
            { titulo: 'Estoque', renderizar: function ($c, l) { $c.text(tela.estoque(l.estoqueAtualizado)); } }, { titulo: 'Controle', renderizar: function ($c, l) { $c.text(tela.controle(l.situacaoControle)); } },
            { titulo: 'Embalagens no ciclo', renderizar: function ($c, l) { $c.text(tela.numero(l.qtdEmbalagens) + (l.compensado ? ' · Compensado' : '')); } },
            { titulo: 'Consulta', renderizar: function ($c, l, i) { $c.append($('<button type="button" class="nwr-botao">').attr('data-detalhar', i).text('Detalhar')); } }
        ];
        if (nome === 'itens') colunas = [
            { campo: 'sequencia', titulo: 'Sequência' }, { campo: 'item', titulo: 'Item' }, { campo: 'descricaoItem', titulo: 'Descrição' },
            { titulo: 'Quantidade documental', renderizar: function ($c, l) { $c.text(tela.numero(l.quantidadeDocumento)); } }, { campo: 'unidadeDocumento', titulo: 'Unidade documental' },
            { titulo: 'Embalagens no ciclo', renderizar: function ($c, l) { $c.text(l.qtdEmbalagens == null ? 'Vínculo de linha não comprovado' : tela.numero(l.qtdEmbalagens)); } },
            { titulo: 'Lotes, validades e rateios', renderizar: function ($c, l) {
                $c.append($('<span>').text('Linha: ' + (l.loteDocumento || 'Lote não informado') + ' · ' + tela.data(l.validadeDocumento)));
                if (!Array.isArray(l.rateios) || !l.rateios.length) { $c.append($('<p>').text('Sem rateios informados.')); return; }
                var $rateios = $('<div>'); $c.append($rateios);
                tela.tabela($rateios, [{ campo: 'lote', titulo: 'Lote' }, { titulo: 'Validade', renderizar: function ($r, rat) { $r.text(tela.data(rat.validade)); } },
                    { titulo: 'Quantidade do rateio', renderizar: function ($r, rat) { $r.text(tela.numero(rat.quantidade)); } }, { campo: 'deposito', titulo: 'Depósito' }, { campo: 'localizacao', titulo: 'Localização' }], l.rateios);
            } }
        ];
        if (nome === 'embalagens') colunas = [
            { campo: 'sequencia', titulo: 'Sequência' }, { campo: 'item', titulo: 'Item' }, { campo: 'unidade', titulo: 'Unidade' }, { campo: 'codTipo', titulo: 'Tipo' }, { campo: 'etiqueta', titulo: 'Etiqueta' },
            { titulo: 'Capacidade', renderizar: function ($c, l) { $c.text(tela.numero(l.capacidade)); } },
            { titulo: 'Quantidade recebida (histórica)', renderizar: function ($c, l) { $c.text(tela.numero(l.quantidadeRecebida)); } },
            { campo: 'lote', titulo: 'Lote' }, { titulo: 'Validade', renderizar: function ($c, l) { $c.text(tela.data(l.validade)); } },
            { titulo: 'Vínculo com a linha', renderizar: function ($c, l) { $c.text(l.vinculoLinha === 'COMPROVADO' ? 'Comprovado' : 'Não comprovado'); } }
        ];
        this.tabela(this.$raiz.find('[data-grade-' + nome + ']'), colunas, linhas);
    }
});
