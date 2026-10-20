# widget_nw_embalagens

## Leitura inicial
- Ler este arquivo e os quatro arquivos `contexto-ia/AI_*.md` no início da sessão.
- Visão geral para desenvolvedores: `README.md`.
- Conferir o estado real do Git e dos fontes antes de usar o contexto.
- Ao concluir uma tarefa, atualizar o contexto afetado e manter o README coerente.
- Este é o ponto de entrada para qualquer ferramenta de IA; não manter CLAUDE.md local duplicado.

## Objetivo
Tela **Tipos de Embalagens** do Controle de Embalagens (Datasul): consulta, cadastro, edição da descrição e inativação/reativação. O fonte atual também oferece exclusão; a aprovação dessa mudança e sua homologação não foram confirmadas nesta revisão documental.

## Identificação
- application.code e título: `widget_nw_embalagens`.
- Versão: `0.1.0`; categoria: `SYSTEM`; uiwidget=true; mobileapp=false.
- Context-root: `/widget_nw_embalagens`.
- SuperWidget atual: `cadastroEmbalagens`; container: `cadastro-embalagens_${instanceId}`.
- Escopo CSS atual: `.fluig-style-guide.cadastro-embalagens`; classes `embalagens-*`.
- Repositório próprio: https://github.com/DataIT-Solucoes/BP-NW-Embalagens.git.
- Página de TESTE registrada anteriormente: `/portal/p/1/cadastro_de_embalagens`; publicação atual não confirmada.

## Arquitetura e integrações
- `src/main/resources/view.ftl`: interface; `src/main/webapp/resources/js/widget_nw_embalagens.js`: SuperWidget e função global chamarEmbalagens.
- Widget → POST /api/public/ecm/dataset/search → dsNwEmbalagens → serviço DATASUL_REST_HOMOLOG → REST Datasul.
- `datasets/dsNwEmbalagens.js` é a fonte da verdade do contrato, permissões e escritas habilitadas. Por orientação anterior do usuário registrada na skill, representa o Dataset do Fluig; conferir o arquivo atual antes de tocar dados.
- Entrada: filterFields com acao e parametros JSON. Saída: uma linha com envelope em resultadoJson.
- A tela usa consultarTipos, consultarTiposApoio, incluirTipo e alterarTipo. Não inventar ações, campos, rotas ou regras.
- Identidade, empresa, grupos e estabelecimentos autorizados são resolvidos no Dataset, nunca pelo navegador.
- Recursos declarados: JS (1), CSS (2); próximo índice livre: 3. Conferir application.info antes de adicionar recursos.

## Regras de trabalho
- Português do Brasil, direto. O usuário define o escopo; pendência registrada não autoriza execução.
- Respeitar instruções gerais do projeto e atuais do usuário. Usar a skill fluig-branco-peres; se divergir dos fontes atuais, registrar a diferença.
- SEMPRE fazer commit, push e compilar ao concluir as tarefas desta widget, conforme autorização permanente do usuário em 2026-10-20. Mostrar antes o conteúdo do commit e incluir somente o escopo da entrega, preservando alterações alheias. Esta decisão substitui a exigência anterior de pedido pontual. Publicação no Fluig depende de autorização específica.
- Pastas de servidor, homologação e modelos recebidos são somente leitura. Nunca ler compilados .r nem incluir pastas de referência em commits.
- Não editar o Dataset sem pedido; alterações exigem republicação no Fluig e manutenção da correspondência com o servidor.
- Não gravar credenciais no projeto, inclusive em .vscode/servers.json. Informação desconhecida: “a definir”; resultado não visto: “não confirmado”.
- Não fazer varreduras amplas fora do projeto. Se faltar arquivo necessário, pedir ao usuário.
- Progress (.w/.p/.i/.cls): usar a skill progress-datasul e ler references/manutencao-e-contexto.md antes de editar; CP850 + CRLF, nunca Write/Edit nesses fontes.
- Medir e preservar encoding e quebras de linha; conferir CRLF depois de editar fontes.
- Usar jQuery 3.6.3 para DOM, eventos e requisições novos ou alterados. Não incluir novamente jQuery, Bootstrap 3.4.1 ou Style Guide 2.5.0 fornecidos pelo Fluig. Não usar classes Bootstrap 4/5 ou glyphicon.
- Escopar seletores por this.DOM/instanceId e CSS por .fluig-style-guide.cadastro-embalagens. Preservar paleta Branco Peres e isolamento entre instâncias.
- Modais atuais são dialog; notificações usam FLUIGC.toast; filtro atual usa FLUIGC.autocomplete. Conferir fontes antes de aplicar resumos antigos.
- Não converter códigos em número; versao de tipos é enviada como número. Sigla é imutável na edição. Limite atual: 3 caracteres; a origem de aprovação da mudança do limite histórico de 2 não foi confirmada.
- Preservar idempotência: falha incerta exige conferência antes de nova tentativa; não repetir comandos automaticamente nem gerar chave nova para a mesma intenção.
- Distinguir verificação local de validação no Fluig. Testes simulados não comprovam publicação ou homologação.

## Continuidade
- Estado e retomada: `contexto-ia/AI_HANDOFF.md`.
- Decisões aprovadas: `contexto-ia/AI_DECISIONS.md`.
- Pendências: `contexto-ia/AI_TODO.md`.
- Referências: `contexto-ia/AI_REFERENCES.md`.
