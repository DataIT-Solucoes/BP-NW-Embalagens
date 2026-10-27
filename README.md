# widget_nw_embalagens — Tipos de Embalagens

Widget WCM do Fluig da Branco Peres para consultar, cadastrar, editar e inativar/reativar tipos de embalagem do Datasul. O código atual também oferece exclusão com confirmação; sua execução no ambiente não foi confirmada nesta revisão documental.

Instruções para agentes: [AGENTS.md](AGENTS.md). Decisões, pendências, referências e mapa do código: [docs/](docs/decisoes.md).

## Estrutura principal

| Arquivo / pasta | Responsabilidade |
|---|---|
| src/main/resources/view.ftl | Cabeçalho, filtro, tabela e modais nativos dialog |
| src/main/webapp/resources/js/widget_nw_embalagens.js | SuperWidget cadastroEmbalagens, transporte chamarEmbalagens, autocomplete e comandos |
| src/main/webapp/resources/css/widget_nw_embalagens.css | Estilos em .fluig-style-guide.cadastro-embalagens |
| src/main/resources/application.info | Identificação e recursos: JS (1), CSS (2) |
| src/main/webapp/WEB-INF/jboss-web.xml | Context-root /widget_nw_embalagens |
| testes/*.cjs e package.json | Testes locais com Fluig/Datasul simulados |
| fluig-rest/docs/ | Documentação técnica e matrizes da integração |
| docs/*.md | Decisões, pendências, referências e mapa do código (contexto para IA) |
| scripts/entregar.ps1 | Conferências, .war, commit e push de uma entrega |

O transporte está no JS principal; não há recurso separado chamar-embalagens.js registrado. O Dataset dsNwEmbalagens fica no repositório DataIT-Solucoes/BP-NW-DATASET (sem cópia local). Modelos recebidos são referências somente leitura.

## Dependências

O ambiente registrado fornece jQuery 3.6.3, Bootstrap 3.4.1 e Fluig Style Guide 2.5.0. A tela usa SuperWidget, FLUIGC.autocomplete e FLUIGC.toast. Não incluir novamente as bibliotecas fornecidas pelo Fluig.

| Dependência externa | Carregamento |
|---|---|
| Bootstrap Icons 1.11.3 | jsDelivr, pelo view.ftl |
| Mulish | Google Fonts, pelo view.ftl |
| Tabulator 6.4.0 | CSS pelo view.ftl; JS via $.ajax no JS principal |

Acesso às CDNs é necessário para esses recursos. Credenciais ficam no serviço do Fluig, nunca no widget.

## Integração e configuração

```text
Widget → chamarEmbalagens(acao, parametros)
       → POST /api/public/ecm/dataset/search (dsNwEmbalagens)
       → serviço DATASUL_REST_HOMOLOG
       → /dts/datasul-rest/resources/prg/esp/v1/controle-embalagens
```

O transporte envia filterFields com acao e parametros JSON e recebe uma linha cujo resultadoJson contém o envelope funcional. O limit de transporte é "1"; o limite de negócio é outro parâmetro.

| Operação | Contrato usado pela tela |
|---|---|
| Autocomplete de tipo | consultarTiposApoio, filtro, ativo: "todos", limite: 20 |
| Buscar selecionado | consultarTipos, codigoDe e codigoAte iguais ao código, limite: 1 |
| Buscar todos / carregar mais | consultarTipos, limite: 20, cursor aposCodigo quando houver |
| Cadastrar | incluirTipo, código, descrição, ativo, versão e chave idempotente |
| Editar / inativar / reativar | alterarTipo, versão e chave idempotente; ALTERAR ou INATIVAR |
| Excluir no fonte atual | alterarTipo, acao: "excluir", versão e chave idempotente; homologação não confirmada |

O filtro pede ao menos 2 caracteres para sugerir tipos e permite buscar todos com o campo vazio. O cadastro limita sigla a 3 caracteres e descrição a 100; o código não muda na edição. A tabela usa paginação por cursor e ordenação local dos dados carregados.

A tabela abre vazia: os tipos só são consultados ao clicar em Buscar. Enquanto a biblioteca da tabela carrega e ao Buscar, um overlay com spinner cobre a widget e o toast info “Carregando...” acompanha a espera. O filtro, Buscar e Novo ficam desabilitados até todas as páginas da consulta e a renderização da tabela terminarem. Falhas retiram o bloqueio e exibem o erro. O toast começa a desaparecer 100 ms após o fim, com animação de 200 ms; buscas próximas reutilizam o aviso e cancelam a remoção pendente.

Ao ativar/inativar, o interruptor da linha fica bloqueado e é substituído visualmente por um spinner no mesmo espaço enquanto o comando e a atualização da linha estão pendentes. A situação muda após confirmação do servidor; recusa ou falha restauram o interruptor anterior e mostram o erro.

Antes de mudar integrações, conferir NW_CONFIG, NW_ACOES e NW_COLUNAS no Dataset atual. Existem regras para DefaultGroup-1 e escritas habilitadas; isso não comprova homologação ou autorização para produção. O Dataset resolve identidade e permissões no servidor.

## Verificação local

Com Node.js e npm disponíveis:

```text
npm test
```

Executa testar-dataset-unico.cjs, testar-chamar-embalagens.cjs e testar-tela-tipos.cjs, usando jquery-falso.cjs. São testes simulados, sem Fluig/Datasul reais. Em 2026-10-20 passaram 46 cenários de Dataset, 11 de transporte e 33 de tela, todos sem falhas.

Autorização permanente: sempre fazer commit, push e compilar ao concluir tarefas, mostrando antes o conteúdo do commit e preservando alterações alheias e referências.

Build: empacotar src/main/webapp/ na raiz do WAR e src/main/resources/ em WEB-INF/classes/. Não há fontes Java nesta widget. Artefato: target/widget_nw_embalagens.war, ignorado pelo Git. Em 2026-10-20 foi gerado com Python zipfile/ZIP_DEFLATED; estrutura igual ao WAR anterior, ZIP íntegro e 12 arquivos idênticos aos fontes. package.json declara apenas test, sem script de build npm. Publicação no Fluig não realizada. Página de TESTE registrada anteriormente: /portal/p/1/cadastro_de_embalagens; publicação atual deve ser confirmada no ambiente.
