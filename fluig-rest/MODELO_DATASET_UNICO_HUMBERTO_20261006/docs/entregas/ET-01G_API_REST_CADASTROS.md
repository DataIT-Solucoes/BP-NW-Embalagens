# ET-01G — API REST de tipos e parametrização

## Situação

Adaptador ABL implementado em `fontes/progress/esp/api/v1/controle-embalagens.p`, sobre as seis procedures existentes em `contr-emb.p`. A revisão cadastral inicial foi publicada no PASOE e exercitada pela rota externa autenticada; o ciclo REST de tipos foi comprovado. Depois dela, o adaptador evoluiu para 14 ações e incorporou etiquetas, apoios, Bags/conteúdo, famílias, dados de impressão e a parametrização com conversão integrada. O lote backend vigente compilou no OpenEdge 12.2 de TESTE com `FONTES=13 FALHAS=0`; ET-01F passou `32/0`, ET-01I passou `30/0` e os positivos de consulta com massa DT-074 foram aprovados. Essa revisão atual ainda não foi publicada no PASOE; Dataset/serviço autorizado e cadeia Fluig permanecem em validação.

O adaptador é transporte. Validação, consulta, persistência, versão, idempotência e auditoria permanecem no módulo `contr-emb.p`.

Em execução no PASOE, `EMS2` é uma raiz do `PROPATH`; por isso, o adaptador procura exclusivamente `esp/api/v1/contr-emb.r`, correspondente ao arquivo publicado em `EMS2/esp/api/v1`. O adaptador não procura a árvore de desenvolvimento e não executa fonte `.p` em runtime. O `.r` do núcleo e o `.r` do adaptador devem ser publicados a partir da mesma revisão; os testes e o `.i` permanecem no pacote de desenvolvimento.

Para o diagnóstico no ambiente, o adaptador devolve códigos distintos quando a sessão do PASOE não possui conexão lógica `mgesp`, quando `contr-emb.r` não está no `PROPATH`, quando o núcleo é localizado mas não carrega, quando `consultarTipos` falha e quando a resposta JSON não pode ser montada. O detalhe técnico ABL fica somente no log do agente, identificado pelo prefixo `CONTROLE_EMBALAGENS`; não são registrados requisição, usuário, credenciais ou contexto de autenticação.

### Diagnóstico resolvido durante a publicação

A primeira tentativa em memória acusou erro 468 porque havia `.r` dentro da árvore de desenvolvimento usada por `COMPILE` sem `SAVE`; removidos somente esses artefatos locais, a compilação passou. Depois da publicação, agentes diferentes do PASOE mantiveram revisões distintas em memória: um ainda executava o caminho antigo e outro já carregava `esp/api/v1/contr-emb.r`. A reinicialização do PASOE de TESTE uniformizou os agentes. A leitura seguinte recuperou `Z9R` e comprovou o caminho lógico definitivo. Este histórico serve como diagnóstico; não representa pendência atual.

Resultados REST já comprovados em TESTE:

| Rota/cenário | Resultado |
|---|---|
| `GET /tipos`, usuário `totvsrp`, limite 20, cadastro vazio | `sucesso=true`, `total=0`, `dados=[]` |
| `GET /tipos`, limite 101 | `sucesso=false`, `LIMITE_INVALIDO` |
| `GET /tipos`, sem usuário | `sucesso=false`, `USUARIO_NAO_INFORMADO` |
| `GET /parametros`, sem estabelecimento permitido | `sucesso=false`, `SEM_PERMISSAO` |
| `GET /parametros`, estabelecimento permitido `10901`, cadastro vazio | `sucesso=true`, `total=0`, `dados=[]`, `proximoId="0"` |
| `POST /tipos`, inclusão controlada de `Z9R` | HTTP 200, tipo ativo criado na versão 1, evento 23, `repeticao=false`, sem erro |
| Repetição idêntica do `POST /tipos` de `Z9R` | HTTP 200, `repeticao=true`, versão 1 e mesmo evento 23 |
| `GET /tipos`, faixa exata `Z9R`, após reinício dos agentes | `sucesso=true`, `total=1`, fotografia completa da versão 1 |
| `POST /tipos`, mesma chave e conteúdo diferente | HTTP 200, `sucesso=false`, `CONFLITO_IDEMPOTENCIA`, sem evento resultante |
| `POST /tipos`, código `Z9R` com chave nova | HTTP 200, `sucesso=false`, `TIPO_JA_EXISTE`, sem evento resultante |
| `PATCH /tipos`, alteração de `Z9R` com versão esperada 1 | HTTP 200, `sucesso=true`, descrição alterada, versão 2 e evento 41 |
| Repetição idêntica do `PATCH /tipos` de `Z9R` | HTTP 200, `sucesso=true`, `repeticao=true`, mesma versão 2 e evento 41 |
| `PATCH /tipos`, nova alteração de `Z9R` ainda com versão 1 | HTTP 200, `sucesso=false`, `CONFLITO_VERSAO`, sem evento resultante |
| `PATCH /tipos`, inativação de `Z9R` com versão esperada 2 | HTTP 200, `sucesso=true`, inativo, versão 3 e evento 43 |
| Repetição idêntica da inativação de `Z9R` | HTTP 200, `sucesso=true`, `repeticao=true`, mesma versão 3 e evento 43 |
| `GET /tipos`, fotografia final de `Z9R` | `sucesso=true`, `total=1`, inativo, versão 3 e descrição preservada |
| `POST /parametros`, sem estabelecimentos permitidos | HTTP 200, `sucesso=false`, `SEM_PERMISSAO`, sem alcançar mutação |
| `POST /parametros`, `10901/365131`, unidade informada `L` | HTTP 200, `sucesso=false`, `UNIDADE_DIVERGENTE`, sem evento; unidade real ainda deve ser lida do `mgcad.item` |
| `POST /parametros`, `10901/365131`, unidade real `LT` | HTTP 200, `sucesso=false`, `ITEM_SEM_CONTROLE_LOTE`, sem parâmetro ou evento; `tipo-con-est` atual é 1 |
| `PATCH /tipos`, reativação de `Z9R` com versão esperada 3 | HTTP 200, `sucesso=true`, ativo, versão 4 e evento 45 |

O ciclo de comandos REST de tipo está comprovado e `Z9R` foi reativado na versão 4 para a prova de parâmetros. Nos parâmetros, passaram a autorização negativa, a unidade divergente e a recusa do item sem controle por lote. Pelas DT-055/057/058/059, a prova positiva depende de executar e comprovar `contr-emb-conversao.p`, que já compilou e combina CDAPIITEM com o tratamento backend equivalente ao CE0111. Depois do ET-01H, o conversor será integrado para ativar em Lote e reverter a Serial quando for retirado o último parâmetro ativo. A alteração manual em TESTE serve para investigar o padrão e criar massa, mas não homologa o fluxo final. Os filtros, a paginação com maior massa e os demais comandos continuam pendentes.

## Endereço-base validado em TESTE

```text
/dts/datasul-rest/resources/prg/esp/v1/controle-embalagens
```

## Rotas

| Método | Recurso | Operação |
|---|---|---|
| `GET` | `/tipos` | Consulta paginada de tipos. |
| `POST` | `/tipos` | Inclusão de tipo. |
| `PATCH` | `/tipos` | Alteração ou inativação de tipo. |
| `GET` | `/parametros` | Consulta paginada limitada aos estabelecimentos autorizados. |
| `POST` | `/parametros` | Inclusão de parametrização. |
| `PATCH` | `/parametros` | Alteração, inativação ou exclusão de parametrização. |

O mesmo adaptador declara `GET /etiquetas`, pertencente à ET-02A. A ação e o núcleo compilaram, e o teste ABL passou em `7/0`; ainda faltam publicação e execução pela rota REST.

Não há um arquivo `.p` por rota. Todas são ações do mesmo adaptador e chamam o mesmo módulo de negócio.

## Contexto confiável vindo do Fluig

O Fluig controla acesso e exibição por grupos. O Widget informa somente dados funcionais e filtros visíveis. O Dataset deve reconstruir a chamada e injetar:

- `usuario`: usuário real obtido da sessão Fluig;
- `estabelecimentoPermitido`, repetido na query da consulta de parâmetros;
- `estabelecimentosPermitidos`, lista JSON nos comandos de parâmetros;
- `chaveIdempotente`, preservada nas repetições da mesma intenção de comando.

O Dataset não pode copiar do Widget campos com esses nomes. A lista deve resultar da regra de grupos configurada no Fluig. Lista vazia nega a operação de parâmetros; o ABL também confere se o estabelecimento do comando pertence à lista. Tipos não possuem dimensão de estabelecimento e dependem do grupo funcional validado pelo Dataset e do serviço autorizado. Enquanto esse Dataset/serviço não estiver homologado, os campos recebidos pelo adaptador podem ser forjados por outro cliente autenticado; portanto, os testes diretos de hoje não autorizam uso produtivo.

Os códigos dos grupos e sua correspondência com os estabelecimentos ainda serão definidos com o desenvolvedor Fluig. O ABL não interpreta nomes de grupos nem consulta `usuar-depos` para substituir essa definição.

## Consulta de tipos

Parâmetros de query:

| Campo | Obrigatório | Regra |
|---|---:|---|
| `usuario` | Sim, injetado | Identidade para o contexto da chamada. |
| `codigoDe` | Não | Início inclusivo. |
| `codigoAte` | Não | Fim inclusivo. |
| `descricao` | Não | Filtro literal. |
| `ativo` | Não | `true` ou `false`; ausente consulta ambos. |
| `aposCodigo` | Não | Cursor exclusivo. |
| `limite` | Não | Padrão 20; máximo 100. |

Exemplo de resposta:

```json
{
  "sucesso": true,
  "codigoErro": "",
  "mensagem": "",
  "total": 1,
  "temMais": false,
  "proximoCodigo": "PL",
  "dados": [
    {
      "codTipo": "PL",
      "descricao": "PLASTICA",
      "ativo": true,
      "versao": 1
    }
  ]
}
```

## Comandos de tipo

Inclusão:

```json
{
  "codTipo": "PL",
  "descricao": "PLASTICA",
  "ativo": true,
  "versao": 0,
  "chaveIdempotente": "valor-estavel-da-intencao",
  "usuario": "usuario-da-sessao"
}
```

Alteração ou inativação usa `PATCH`, envia `acao` como `ALTERAR` ou `INATIVAR` e informa a versão lida. Código permanece imutável. O adaptador calcula os hashes; o Widget e o Dataset não os enviam.

## Consulta de parâmetros

Além dos filtros `estabelDe`, `estabelAte`, `itemDe`, `itemAte`, `ativo`, `aposId` e `limite`, o Dataset repete a query confiável para cada código permitido:

```text
?usuario=wallison&estabelecimentoPermitido=10901&estabelecimentoPermitido=10902&limite=20
```

O retorno contém `idParam` e `proximoId` como texto, evitando conversão indevida em clientes JavaScript, e os demais campos da fotografia cadastral.

## Comandos de parâmetros

Inclusão:

```json
{
  "idParam": 0,
  "codEstabel": "10901",
  "item": "365131",
  "codTipo": "PL",
  "capacidade": 20.0000,
  "unidade": "UN",
  "ativo": true,
  "versao": 0,
  "chaveIdempotente": "valor-estavel-da-intencao",
  "usuario": "usuario-da-sessao",
  "estabelecimentosPermitidos": ["10901"]
}
```

Alteração, inativação ou exclusão usa `PATCH`, informa respectivamente `ALTERAR`, `INATIVAR` ou `EXCLUIR` em `acao`, envia a fotografia exigida pelo núcleo e a versão lida. A exclusão é ação histórica e não depende de corpo em `DELETE`.

## Resposta de comando

Todos os comandos devolvem `sucesso`, `repeticao`, `codigoErro`, `mensagem`, a identidade/fotografia resultante, `versao` e `idEvento`. Parâmetros também devolvem `excluido`. Falhas internas são sanitizadas; durante a homologação, o código indica a etapa técnica sem devolver a mensagem ABL. A requisição, credenciais e dados de sessão não aparecem na resposta nem no log.

## Aceite em TESTE

1. **Concluído para a revisão atual:** `controle-embalagens.p`, ET-02A, conversor e testes ET-01H compilaram com `FONTES=9 FALHAS=0`.
2. **Concluído:** publicar os `.r` no caminho correto do PASOE de TESTE, reiniciar o PASOE e comprovar o resolvedor lógico.
3. **Parcial:** `GET /tipos` passou com vazio, faixa exata, limite inválido e usuário ausente; `GET /parametros` passou com vazio autorizado e lista vazia negada. Filtros/paginação com massa permanecem pendentes.
4. **Parcial:** o ciclo de comandos de tipo passou por completo. Em parâmetros, passaram as recusas por permissão, unidade e controle do item; sucesso, repetição, conflitos, alteração, inativação e exclusão dependem da DT-055.
5. **Parcial:** ET-01E passou em 13/0; ET-01F antigo registrou a falta de item por lote e será refeito após a integração padrão da conversão.
6. **Pendente:** homologar Widget → Dataset → serviço autorizado → API depois de fechar códigos de grupos e regra de estabelecimentos.
