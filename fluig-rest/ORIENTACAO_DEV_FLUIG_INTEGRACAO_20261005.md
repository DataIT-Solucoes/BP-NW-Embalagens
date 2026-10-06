# Repasse ao desenvolvedor Fluig — 05/10/2026

Este documento aplica os contratos existentes; não cria rotas nem libera produção. Referências prioritárias: baseline REST, catálogo de procedures, matriz REST e fonte do adaptador. Registros históricos devem ser interpretados conforme as decisões posteriores.

## 1. Como chamar

Fluxo aprovado: Widget → Dataset Fluig → serviço autorizado → REST Datasul/ut-api → ABL/PASOE.

O exemplo `PROGRAM = "_bp/api/cd-ressuprimento.p"` pertence à chamada de programa do outro projeto. Ele demonstra localização lógica no ambiente servidor, mas não é o endereço REST deste projeto. Não montar uma URL HTTP com esse nome de arquivo nem colocar `D:/...` na requisição do navegador.

Base REST validada em TESTE:

`/dts/datasul-rest/resources/prg/esp/v1/controle-embalagens`

Serviço da baseline: `DATASUL_REST_BP`, cadastrado como REST, com autenticação Basic mantida no cadastro protegido do Fluig. Host de referência da baseline: `http://fluig-web-teste.brancoperes.com.br:8190`. Conferir destino e cadastro ativos antes de testar, principalmente após o fix/cópia de base. Não enviar credenciais ao Widget ou às ferramentas de IA.

## 2. Exemplo do Widget

A baseline validada usa POST em `/api/public/ecm/dataset/search`, com `filterFields` como lista alternada de nome e valor. Não trocar essa propriedade por `constraints` no corpo HTTP. O Dataset recebe constraints na sua função `createDataset` internamente.

Exemplo de corpo para um Dataset NOVO de consulta de tipos (o nome abaixo é proposto e deve ser registrado/publicado pelo dev):

```json
{
  "datasetId": "dsControleEmbalagensTipos",
  "filterFields": ["limite", "20"],
  "resultFields": [],
  "limit": "20",
  "orderBy": ""
}
```

`limit` externo pertence à consulta do Dataset. `limite` interno é o parâmetro da API atual de embalagens; o exemplo antigo de CD usa `limit` também no REST, portanto não basta substituir a URL no código antigo.

O Widget envia filtros de negócio e dados da ação. Identidade, grupos e estabelecimentos autorizados devem ser reconstruídos no Dataset. Filtros e ações aceitos devem ter uma lista explícita; não permitir ao navegador escolher qualquer URL, método ou programa servidor.

## 3. Exemplo do Dataset / serviço autorizado

Usar o exemplo validado `dsControleEmbalagensAPI.js` como base do transporte, adaptando o contrato de resposta. Obter `WKUser` e empresa no contexto confiável do Fluig; resolver grupos e estabelecimentos no servidor. Os códigos dos grupos e seu mapeamento ainda precisam ser fechados com o responsável. Não aceitar esses valores livres do Widget.

Trecho ilustrativo dentro do Dataset, após autorização e validação dos filtros:

```javascript
var requisicao = {
  companyId: String(empresaDaSessao),
  serviceCode: "DATASUL_REST_BP",
  endpoint: "/dts/datasul-rest/resources/prg/esp/v1/controle-embalagens/tipos"
    + "?usuario=" + encodeURIComponent(usuarioDaSessao)
    + "&limite=20",
  method: "get",
  timeoutService: "60",
  headers: { "Accept": "application/json" }
};
var cliente = fluigAPI.getAuthorizeClientService();
var resposta = cliente.invoke(JSON.stringify(requisicao));
var status = resposta.getHttpStatusResult();
var corpo = resposta.getResult();
```

As variáveis de sessão acima devem ser obtidas na instalação atual, não são funções novas já fornecidas pelo projeto. O trecho é referência de transporte, não Dataset completo para publicar sem adaptação. Para POST/PATCH, seguir o mecanismo de envio de corpo JSON do serviço autorizado instalado e conferir o corpo recebido pelo adaptador em TESTE; não presumir assinatura não comprovada pela baseline GET.

Para operações por estabelecimento, GET usa `estabelecimentoPermitido` repetido na query; comandos usam `estabelecimentosPermitidos` como lista no JSON, conforme ET-01G. `usuario` sempre vem do contexto confiável. Tipos são globais e exigem permissão funcional, mesmo sem dimensão de estabelecimento.

O ut-api apresenta valores de query como arrays no `oInput`, por exemplo `{"queryParams":{"limite":["20"]}}`. Esse objeto é adaptação interna do Datasul; não é o corpo do Widget.

## 4. Rotas que existem no fonte atual

Todas as rotas abaixo são relativas à base REST indicada. Existência no fonte não significa homologação integrada; conferir estado e evidência na matriz REST.

| Método | Caminho | Uso |
|---|---|---|
| GET / POST / PATCH | `/tipos` | Consultar, incluir e manter tipos |
| GET / POST / PATCH | `/parametros` | Consultar e manter parâmetros |
| GET | `/etiquetas` | Projeção atual das embalagens |
| GET | `/apoios/estabelecimentos` | Estabelecimentos autorizados |
| GET | `/apoios/itens` | Catálogo de itens |
| GET | `/apoios/tipos` | Apoio de tipos |
| GET | `/apoios/familias` | Apoio de famílias |
| GET | `/bags` | Consulta de Bags |
| GET | `/conteudo-bag` | Conteúdo atual |
| GET | `/dados-impressao` | Fotografia persistida para impressão |
| GET | `/geracoes` | Evento de geração e suas embalagens |
| GET | `/operacoes/natureza` | Classificação da natureza selecionada |
| GET | `/operacoes/embalagens-origem` | Embalagens elegíveis da origem |

São 17 combinações método/rota. Não existem ainda rotas POST declaradas para criar WT de transferência, devolução, empréstimo ou armazenagem. Os testes ABL dessas operações não autorizam o dev a inventar esses endpoints. Cadastro ativo de parâmetro também tem pendência específica no contexto REST/PASOE; não tratá-lo como integralmente homologado pelo sucesso ABL.

Natureza deve ser classificada pelo backend, sem códigos fiscais fixos na tela. Consulta de origem utiliza `codEstabel`, `natureza`, `emitenteOrigem`, `serieOrigem`, `numeroOrigem`, `naturezaOrigem`, `aposIdEtiqueta` e `limite`, além do contexto confiável. Conferir tipos e campos completos no adaptador/catalogo. Esta consulta não reserva saldo nem garante execução posterior; o comando deve revalidar.

Recebimentos são criados pelo ANFe/Datasul. O Fluig não deve recriar a entrada porque uma consulta falhou. Os hooks tratam fatos fiscais no servidor, sem chamada HTTP para si mesmos.

## 5. Respostas, repetição e interface

- Conferir tanto HTTP quanto `sucesso`, `codigoErro` e `mensagem`. HTTP 200 pode conter recusa de negócio.
- Fazer parse JSON protegido; erro SOAP/texto/HTML não pode virar erro silencioso ou lista vazia. Nunca concatenar manualmente JSON com mensagens que contenham aspas.
- Conservar o envelope de negócio: dados, paginação/cursor, versões e indicadores de repetição pertinentes. A resposta achatada do exemplo de CD não preserva todos esses controles; definir o retorno do novo Dataset antes da integração das telas.
- IDs INTEGER do contrato atravessam JSON como texto. Não converter indiscriminadamente IDs/códigos em números.
- Comandos usam `chaveIdempotente`: mesma intenção e conteúdo mantêm a chave em retries; alteração do conteúdo exige nova intenção. Resultado incerto exige conciliação antes de repetir emissão. Não gerar nova chave automaticamente a cada tentativa de rede.
- Alterações usam `versao` esperada. Em conflito, reler e mostrar o estado atual, sem sobrepor silenciosamente.
- Paginar pelo cursor retornado e respeitar o limite específico de cada rota. Autocomplete: mínimo 2 caracteres, debounce, teto 20 e cancelamento/descarte de resposta antiga conforme componente existente.
- Distinguir carregando, vazio válido, erro de negócio, erro técnico e falta de permissão. Não expor cookies, tokens, senha, headers de autenticação ou `oInput` completo em logs.

## 6. Publicação no Datasul e aceite

O adaptador publicado e seus módulos são resolvidos por `esp/api/v1` no PROPATH de EMS2. O adaptador carrega os núcleos compilados por SEARCH; não depende do drive físico da estação do dev. Já os hooks dos ensaios seguem o pacote TESTE/DT109, com sonda local E16 ainda pendente. Não misturar essas duas instalações.

Antes do aceite: conferir revisão/hash dos fontes e `.r`, compilação sem falhas, publicação no PASOE de TESTE, contexto autorizado do Dataset e acesso real pelo Widget. Exercitar sucesso, vazio, negócio recusado, corpo inválido, falta de permissão, tentativa de falsificar usuário/estabelecimento, paginação, repetição e versão conflitante. Só renovar PASOE de TESTE quando necessário à publicação; produção requer roteiro próprio.

## 7. Arquivos a enviar e ordem de leitura

Enviar este documento e estes arquivos, preservando os caminhos relativos:

1. `docs/00_BASELINE_REST_FLUIG_DATASUL_v1.0.docx` e `docs/00_BASELINE_REST_FLUIG_DATASUL_v1.0_codigo.zip` (ZIP existente, exemplo de transporte de CD; não contrato completo do projeto).
2. `docs/entregas/ET-01G_API_REST_CADASTROS.md` e `docs/entregas/MATRIZ_APIS_REST.md` (payloads e estado por rota).
3. `fontes/progress/esp/api/v1/controle-embalagens.p` e `fontes/progress/contr-emb.i` (contrato executável atual; consultas adicionais nos módulos referenciados pelo adaptador).
4. `docs/06_CATALOGO_PROCEDURES.md`, `docs/01_ESCOPO_TECNICO.md`, `docs/02_DECISOES_TECNICAS.md` e `docs/03_PENDENCIAS.md` (regras e limites; decisões posteriores prevalecem sobre histórico).
5. `docs/entregas/GUIA_DEV_FLUIG.md`, `docs/entregas/MATRIZ_TELAS_CAMPOS_ACOES.md` e `docs/entregas/MAPA_TELAS_FLUIG.md`, com os mockups/componentes referidos nesses documentos (interface e dependências).

Para GPT/Claude: começar por este repasse, informar que baseline de CD é exemplo, exigir confronto com o fonte atual e matriz, não inventar endpoints/assinaturas nem considerar pendência uma regra vigente. Não enviar configurações privadas do servidor ou credenciais. Resultado esperado do dev: Dataset(s), grupos/mapeamento, contrato do retorno ao Widget, telas e evidências da cadeia integrada. O nome e desenho finais dos novos Datasets ainda precisam ser definidos; não há Dataset novo completo já homologado neste repasse.
