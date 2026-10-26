# widget_nw_embalagens — Tipos de Embalagens

Widget WCM do Fluig (Branco Peres) para cadastrar, editar, inativar/reativar e consultar tipos de embalagem.
Publicado no servidor de teste em `/portal/p/1/cadastro_de_embalagens`.

> **Estado atual (07/10/2026):** a tela usa o Dataset central **`dsNwEmbalagens`** (ações `consultarTipos`,
> `incluirTipo`, `alterarTipo`) pela função `chamarEmbalagens`. O Dataset **ainda não está publicado** no Fluig
> de TESTE e os **grupos de acesso ainda não foram definidos** (DT-054): até lá toda chamada volta
> `AUTORIZACAO_NAO_CONFIGURADA`. O `dsNwEmbalagensTipos` antigo continua publicado e intacto.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `src/main/resources/view.ftl` | HTML da tela: cabeçalho, aba, filtro, container da tabela e os dois modais (`<dialog>`) |
| `src/main/webapp/resources/js/widget_nw_embalagens.js` | SuperWidget: tabela, busca, "Carregar mais", cadastro/edição, inativar/reativar |
| `src/main/webapp/resources/js/chamar-embalagens.js` | Transporte do Widget para o `dsNwEmbalagens` (cópia do modelo, sem alteração de conteúdo) |
| `src/main/webapp/resources/css/widget_nw_embalagens.css` | Estilos e paleta de cores |
| `src/main/resources/application.info` | Registra JS (1), CSS (2) e `chamar-embalagens.js` (3) |
| `datasets/dsNwEmbalagens.js` | Dataset central (24 ações fechadas). Publicar como Dataset customizado **dsNwEmbalagens** |
| `datasets/dsNwEmbalagensTipos.js` | Dataset antigo de tipos (uma linha por tipo). Não usado pela tela; não alterar |
| `testes/*.cjs` + `package.json` | Testes locais (`npm test`), sem Fluig/Datasul reais. Não entram no `.war` |
| `fluig-rest/MODELO_DATASET_UNICO_HUMBERTO_20261006/` | Modelo recebido (referência, mantido como veio) |

## Dependências externas (CDN)

O Fluig já carrega jQuery 3.6.3, Bootstrap 3.4.1 e o Style Guide. Além disso, a tela usa:

| Biblioteca | Onde é carregada | Para quê |
|---|---|---|
| Bootstrap Icons 1.11.3 (jsDelivr) | `<link>` no `view.ftl` | Todos os ícones (`bi bi-*`) |
| Mulish (Google Fonts) | `<link>` no `view.ftl` | Fonte da tela |
| Tabulator 6.4.0 — CSS (cdnjs) | `<link>` no `view.ftl` | Tema base da tabela |
| Tabulator 6.4.0 — JS (cdnjs) | carregado pelo JS em `carregarTabulator()` | Tabela (ordenação, linhas) |

Sem acesso à internet: ícones e fonte não aparecem, e no lugar da tabela surge a mensagem
"Não foi possível carregar a tabela...".

## Como a tela chama o Fluig

```
Widget ── chamarEmbalagens(acao, parametros)
        └► POST /api/public/ecm/dataset/search  { datasetId: "dsNwEmbalagens",
                                                  filterFields: ["acao", acao, "parametros", JSON], limit: "1" }
           └► dsNwEmbalagens (WKUser/WKCompany, grupos do colleagueGroup, regras por ação)
              └► serviço DATASUL_REST_HOMOLOG ─► /dts/datasul-rest/.../controle-embalagens/tipos
```

- O Dataset devolve **uma linha**; `chamarEmbalagens` devolve o envelope da API (`JSON.parse(resultadoJson)`).
  `sucesso = false` nunca vira lista vazia.
- `limit: "1"` é do transporte (uma linha de envelope). O limite de negócio é `parametros.limite` (20 na tela).
- O Widget nunca envia usuário, empresa, grupo, endpoint, método nem estabelecimentos: o Dataset injeta/recusa.

| Ação da tela | Ação do Dataset | Parâmetros enviados |
|---|---|---|
| Abrir / Buscar | `consultarTipos` | `descricao` (se houver texto), `limite: 20`; texto de até 3 caracteres também gera uma 2ª consulta `codigoDe = codigoAte = texto`, `limite: 1` (a API não tem filtro "código OU descrição") |
| Carregar mais | `consultarTipos` | mesmo filtro + `aposCodigo` = `proximoCodigo` da página anterior |
| Novo → Salvar | `incluirTipo` | `codTipo`, `descricao`, `ativo: true`, `versao: 0`, `chaveIdempotente` |
| Editar → Salvar | `alterarTipo` | `codTipo`, `descricao`, `ativo` atual, `versao` lida (número), `acao: "ALTERAR"`, `chaveIdempotente` |
| Inativar | `alterarTipo` | `acao: "INATIVAR"`, `ativo: false`, `versao` lida |
| Reativar | `alterarTipo` | `acao: "ALTERAR"`, `ativo: true`, `versao` lida |

## Fluxo da tela

```
Página abre
  └─ init()
       ├─ posiciona a barrinha da aba (de novo quando a fonte Mulish termina de carregar)
       ├─ carregarTabulator() ──► montarTabela() ──► carregarTipos(false): 1ª página
       ├─ prepararModalNovo()      (eventos do modal de cadastro/edição)
       └─ prepararModalSituacao()  (eventos da confirmação de inativar/reativar)

Usuário ─┬─ texto + Buscar (ou Enter) ─► carregarTipos(false) ─► nova consulta no Datasul
         ├─ Carregar mais ────────────► carregarTipos(true)  ─► próxima página pelo cursor
         ├─ Novo ─────────────► abrirModalNovo() ─┐
         ├─ lápis da linha ───► abrirModalEditar() ┴► abrirModalCadastro() ─► Salvar ─► salvarCadastro()
         └─ botão de situação ► abrirModalSituacao() ─► Inativar/Reativar ─► confirmarSituacao()
```

### 1. Carregamento
- O Fluig instancia o widget a partir de `data-params="widget_nw_embalagens.instance()"` e chama `init()`.
- `this.DOM` é o jQuery da div do widget (confirmado no servidor de teste). Todo seletor é feito dentro dele,
  então duas instâncias na mesma página não se misturam.
- O script do Tabulator é baixado uma única vez por página (`nweTabulatorPromise`), mesmo com várias instâncias.

### 2. Tabela
- Colunas: **Descrição**, **Sigla** (código do tipo, como etiqueta), **Situação** (Ativo/Inativo) e **Ações**.
- **Uma página por consulta** (20 tipos), na ordem da API (por código). Não há paginação local: o rodapé mostra
  "Mostrando N tipos · há mais resultados" e o botão **Carregar mais** enquanto a API indicar `temMais`.
- A ordenação pelo cabeçalho reordena só o que já foi carregado.
- Erro na consulta aparece sobre a tabela (texto puro) e a tela pede para clicar em Buscar de novo.
  Uma busca nova cancela a anterior; a resposta antiga é ignorada.

### 3. Filtro
- Um campo **Tipo/Sigla Embalagem**. A busca vai ao Datasul (não filtra só a tela): descrição contém o texto e,
  com até 3 caracteres, também o código exato (que aparece primeiro). Maiúsculas/acentos seguem a regra da API.

### 4. Cadastro e edição (mesmo modal)
- **Novo** abre o modal vazio; o **lápis** abre preenchido, com a **sigla somente leitura** (o código não muda).
- Validação na tela: descrição obrigatória; sigla obrigatória com 2 ou 3 letras/números no cadastro; na edição a descrição
  precisa mudar. O resto (duplicidade, versão, permissão) é do Datasul/Dataset.
- **Salvar** faz **uma** chamada e desabilita o botão até a resposta; o modal não fecha enquanto grava.
  Sucesso: fecha, avisa por toast (cadastrado/editado), aplica na tabela a fotografia devolvida (`codTipo`, `descricao`,
  `ativo`, `versao`) e destaca a linha.
  Recusa: `TIPO_JA_EXISTE`, `CODIGO_TIPO_RESERVADO` e `CODIGO_INVALIDO` aparecem na sigla; as demais no alerta do modal.

### 5. Inativar / reativar / excluir
- O **interruptor** da linha inativa (`INATIVAR`) ou reativa (`ALTERAR` com `ativo: true`).
- A **lixeira** pede confirmação e manda `alterarTipo` com `acao: 'excluir'`. A exclusão é lógica: o tipo some das consultas e
  a sigla não pode ser reutilizada (`CODIGO_TIPO_RESERVADO`).

### 6. Chave idempotente e falha incerta
- Cada intenção (ação + conteúdo) recebe uma `chaveIdempotente` (UUID v4 via `crypto.getRandomValues`, porque o
  Fluig de teste é HTTP e não tem `crypto.randomUUID`). Clicar de novo com o **mesmo conteúdo reaproveita a chave**;
  conteúdo diferente gera chave nova; a chave é descartada quando o comando é confirmado.
- Falha de rede/HTTP/resposta ilegível = **resultado incerto**: a tela **não repete sozinha** e orienta clicar em
  Buscar para conferir antes de tentar de novo. `repeticao: true` na resposta gera um aviso.

## Testes locais

```
npm test
```
Roda `testes/testar-dataset-unico.cjs` (Dataset), `testes/testar-chamar-embalagens.cjs` (transporte) e
`testes/testar-tela-tipos.cjs` (funções da tela → transporte → Dataset → serviço simulado), com um jQuery mínimo
simulado (`testes/jquery-falso.cjs`), porque o Node não tem DOM. Não conectam ao
Fluig nem ao Datasul; não substituem a homologação no servidor.

## Visual

- **Paleta oficial Branco Peres** (variáveis no topo do CSS): verde institucional `#006B35` (ação principal,
  foco, seleção, situação Ativo), verde névoa `#E5EDE3` (fundo de seleção), marfim `#F7F5EE` (superfícies),
  carvão `#20201E` (texto), vermelho `#ED1C24` (só ação destrutiva/inativar; erros em `#C4161C` por contraste) e
  amarelo solar `#FFD200` (brilho da linha gravada). Não usar cores fora dela.
- Modais são `<dialog>` nativos, **não** o `FLUIGC.modal`. Avisos rápidos usam `FLUIGC.toast`.

## Pegadinhas para quem for mexer

- **jQuery 3.6.3 (o do Fluig), não JS puro:** DOM, eventos e requisições são feitos com jQuery (`$.ajax`, `$('<tag>', {...})`,
  `.text()`, `.attr()`, `$.when`, `$.Deferred`). Ficam nativos só o que o jQuery não cobre: `showModal()`/`close()` do
  `<dialog>`, `document.fonts`, `crypto.getRandomValues` e as promises que o próprio Tabulator devolve. Nada de `fetch`,
  `async/await` ou `document.createElement`. `$.trim`/`$.isArray` estão obsoletos no 3.5+: usar `.trim()`/`Array.isArray`.
- **`chamarEmbalagens` devolve promise jQuery** com `.abort()` (uma busca nova cancela a anterior).

- **Especificidade:** todo seletor do CSS começa com `.fluig-style-guide.nwe`. Sem isso, regras do Style Guide
  como `.fluig-style-guide header` e `.fluig-style-guide h2` vencem e desmontam o layout.
- **Tabulator:** a classe `.tabulator` vai na **própria** div `.nwe-tabela`; por isso os seletores são
  `.nwe-tabela.tabulator` (sem espaço). As setas inativas precisam de `[aria-sort="none"] .tabulator-col-content`
  no seletor para vencer o tema do Tabulator. O rodapé é um `footerElement` próprio (`.nwe-rodape`).
- **`tabela.alert(texto)` vira HTML** no Tabulator: mensagem vinda da API vai como elemento com `textContent`.
- **Tipos de dado:** `versao` vai como **número** no corpo de tipos (contrato cadastral vigente, GetInteger no ABL).
  Não converter códigos em número.
- **Encoding:** `.js`, `.ftl`, `.css` em UTF-8 sem BOM e CRLF (`application.info` está em LF desde a geração).
  No Git Bash, `awk` esconde o `\r`; conferir CRLF com `grep -c $'\r'` ou Python.
