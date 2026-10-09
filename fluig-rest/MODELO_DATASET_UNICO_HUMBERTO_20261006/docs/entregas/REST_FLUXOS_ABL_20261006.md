# REST dos fluxos ABL — DT115 / TESTE / 06/10/2026

Interfaces compiladas em OpenEdge12.2 em06/10 às17:28, FONTES=7 FALHAS=0. Sonda readonly aprovada às17:33/FALHAS=0 (evidencias/consulta-rest-dt115-20261006-173311.txt). Publicação/ensaios PASOE desta revisão ainda pendentes. Evidência: evidencias/compilacao-rest-dt115-20261006-172840.txt. Recurso /dts/datasul-rest/resources/prg/esp/v1/controle-embalagens. Preservar r-code existente. Usuário e estabelecimentos permitidos vêm do Dataset autorizado, nunca de campos livres do Widget. Identidade funcional e autorização de ação também são conferidas no Dataset.

## Comandos

POST /operacoes/transferencias e POST /operacoes/remessas: corpo codEstabel, codEstabelDestino (obrigatório para transferência; opcional para armazenador externo), emitenteDestino (inteiro canônico em texto; pode ser omitido quando derivado de estabelecimento), natureza, serie, valorItem (decimal JSON, valor aplicado a cada linha WT), chaveIdempotente e selecao. Contexto injetado usuario e estabelecimentosPermitidos (array de texto). Cada seleção contém idEtiqueta e versao em texto canônico e quantidade decimal positiva de até quatro casas. De 1 a 100 embalagens inteiras nesta primeira interface; lista não duplicada. Transferência exige mesma empresa e ambos os estabelecimentos autorizados. Remessa exige natureza de terceiros tipo3 e contraparte coerente; destino interno, quando informado, também autorizado.

POST /operacoes/devolucoes: corpo codEstabel, natureza, serie, emitenteOrigem (inteiro canônico em texto), serieOrigem, numeroOrigem, naturezaOrigem, chaveIdempotente, selecao e contexto confiável igual acima. Delega a criarWtDevolucao; FT4011/FT4012 revalidam origem, saldo por linha, etiquetas/versão e rateios. Retorno de empréstimo segue o mesmo comando conforme natureza/origem. Retorno de armazenagem recebido permanece criação padrão ANFe/Datasul, não este comando.

Os comandos retornam sucesso, repeticao, codigoErro, mensagem, wt e idOperacao textuais, dados (linhas WT na primeira criação quando disponíveis), total. Mesmo corpo/chave repete o resultado sem novo WT; conteúdo diferente conflita. Erro técnico sanitizado; não devolver diagnóstico bruto BO. Nunca calcular/efetivar NF, atualizar estoque ou executar hook por REST. valorItem não é total do documento; preço específico por linha ainda não contratado nesta interface. Quantidade parcial da embalagem permanece recusada.

## Consultas

Todas GET exigem usuario e estabelecimentoPermitido repetido de contexto confiável. Filtros de negócio são adicionais. Paginação crescente por ID com aposId exclusivo, limite padrão20/teto100; IDs textuais na saída.

- /operacoes: codEstabel obrigatório, idOperacao ou wt opcionais, situacao/tipoOperacao opcionais, aposId/limite. Retorna cabeçalhos de operações da origem autorizada. WT é o identificador original de preparação, não afirma que ainda existe após efetivação.
- /operacoes/resultado: codEstabel, chaveIdempotente e ramo DIRETO ou DEVOLUCAO; para DEVOLUCAO também emitenteOrigem/serieOrigem/numeroOrigem/naturezaOrigem. Recupera operação pelo mesmo contexto de idempotência dos comandos e usuário da sessão; lista vazia significa nenhum resultado persistido localizado, não prova que uma chamada concorrente não esteja em execução. Repetir POST com mesma chave e conteúdo é o caminho seguro; nunca trocar a chave por timeout.
- /operacoes/itens: codEstabel, idOperacao, aposId/limite. Retorna SOLICITACAO e suas identidades/quantidades históricas; não utiliza saldo corrente como quantidade selecionada.
- /operacoes/eventos: codEstabel, idOperacao, aposId/limite. Retorna metadados documentais/ciclos/situação dos fatos autorizados. Não expõe hashes, observacao, dados-evento, resultado técnico, token ou mensagens internas. Documento em estabelecimento não autorizado fica fora da consulta mesmo pertencendo à operação autorizada.

Operação não autorizada/inexistente não revela existência. Envelope sucesso/codigoErro/mensagem/dados/total/temMais/proximoId. Resultado vazio é sucesso; erro de carga/consulta não vira vazio. Consulta é fotografia paginada; não promete snapshot entre páginas durante concorrência.

## Limites de aceite

ABL comprovado nos candidatos anteriores: cadeia BODI317 de transferência/remessa/armazenagem, DT101 devolução/retorno, vínculos e fatos posteriores, E15 automático. As novas listas variáveis, idempotência de saída direta e transporte REST exigem SAVE e testes. Não declarar tudo homologado por reutilização de BO. Não repetir os documentos aprovados para validar transporte.

Ainda faltam T04/consultas de recebimentos recém-definidas, mutações de Bags, apoios não implementados, impressão física, autorização/Datasets e testes PASOE. GATEC/anulação aguardam levantamento. Cadastro ativo de parâmetros possui pendência própria PASOE/CDAPIITEM. Não entregar operação de consignação/reajuste só porque classificador reconhece essas naturezas.


