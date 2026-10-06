# Entrega ao Dev Fluig — Controle de Embalagens

16/09/2026 · Datasul 12.1.2511.15 / OE 12.2 / Oracle; Fluig Silver Mist 1.8.1-230530 build 137. Upgrade fora do escopo. Ambiente de implementação: TESTE.

1. Abra **mockups/index.html** no Chrome. Navegue nas três telas e nos formulários. Digite `109` no estabelecimento para conferir 20 opções e próxima página; selecione antes de buscar item `365` ou `361`. São dados demonstrativos, sem ligação com servidor.
2. Leia **MATRIZ_TELAS_CAMPOS_ACOES.md**: cada campo/botão tem ID, procedure, método/rota, arquivo, estado e entrada/dependência. O mapa também pode ser expandido dentro do protótipo. Use esses IDs para dúvidas, tarefas, testes e manutenção.
3. Preserve o agrupamento de **MAPA_TELAS_FLUIG.md**: parametrização nova, manutenção de etiquetas existente e Bags existente. Conversão é interna ao salvar/inativar. Operações fiscais são modais da manutenção. Recebimento no ANFE; Monitor XML em espera pela demonstração AED.
4. Feche o Dataset do novo recurso: obter WKUser/grupos, autorizar tela/ação e reconstruir estabelecimentos. Nenhum campo livre do Widget define usuário/permissão. O Dataset pioneiro cd-ressuprimento é referência de transporte, não o contrato das telas novas.
5. Reutilize **autocomplete-limitado.js** com transporte injetado, mínimo 2, debounce 350 ms, limite 20, abort por campo e respostas antigas ignoradas. Exigir código selecionado, limpar dependentes na troca do pai, unidade somente leitura. Não baixar cadastro inteiro. Teto e autorização também no servidor.
6. Integre por contrato: tipos e parâmetros em ET-01G, etiquetas em ET-02A, estabelecimento/item em ET-01I. Apoios novos aguardam compilação/publicação/TESTE. Depósito/local/lote/família/grupo/contraparte/motorista e operações têm pendências; não criar payload por suposição nem enviar filtros que o servidor ignora.
7. Valide sucesso, vazio, carregando, erro com texto preservado, autorização, limite, paginação, resposta antiga e repetição. Comandos: desabilitar duplo envio, mesma chave para retry, versão e consulta de resultado incerto. PRE_SALDO não recebe operação individual/Bag.

**Calendário oficial:** interface da nova estrutura 21–25/09; APIs/telas 07–19/10; realização 22/10; testes 23–29/10; usuários 30/10–06/11. Cronograma fonte: CRONOGRAMA_PLANNER_GESTAO.md. Teams Fase 2 50%; XLSX local 51% não sincronizado. Layout aceito não representa integração aceita nem encerra atividade.

**Primeira revisão:** confirmar filtros/colunas e o formulário de parametrização; fechar grupos/contexto e instalar consultas contratadas. Etapas fiscais/Bag exigem seus contratos e inversos antes de habilitar ações reais. Botão Criar Bag abre formulário e só confirma depois: abrirBag/BAG-05 é proposta POST /bags, não PUT nem fonte executável pronto.
