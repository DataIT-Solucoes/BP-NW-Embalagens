// Testes locais com dublês: não conectam ao Fluig, PASOE nem banco.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
// Confere o contrato REST esperado, sem depender da copia de referencia nao versionada.
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'datasets/dsNwEmbalagens.js'), 'utf8');
let total = 0;
const test = (name, fn) => { fn(); total++; console.log('OK ' + name); };
const page = (dados = [], more = false, cursor = '', codigo = false) => ({
    sucesso:true,codigoErro:'',mensagem:'',dados,total:dados.length,temMais:more,
    [codigo?'proximoCodigo':'proximoId']:cursor
});
function setup(result = page(), status = '200') {
    const calls = [], logs = [];
    const state = { result, status, fail:false, user:'usuario-teste', company:'empresa-teste', group:'grupo-teste', groupUser:null };
    const context = { JSON, Object, Math, Number, String, Error, isFinite, encodeURIComponent,
        getValue: k => k==='WKUser'?state.user:k==='WKCompany'?state.company:'',
        log: { warn:s=>logs.push(s) }, ConstraintType:{MUST:1},
        DatasetBuilder:{newDataset:()=>({columns:[],values:[],addColumn(n){this.columns.push(n);},addRow(row){this.values.push(row);}})},
        DatasetFactory:{ createConstraint:(name,initial,final,type)=>({name,initial,final,type}),
            getDataset(name, fields, cs) {
                assert.equal(name, 'colleagueGroup');
                assert.equal(cs.length, 2);
                return {rowsCount:1,getValue(i,k) {
                    if(k==='colleagueGroupPK.companyId')return state.company;
                    if(k==='colleagueGroupPK.colleagueId')return state.groupUser || state.user;
                    return state.group;
                }};
            }},
        fluigAPI:{getAuthorizeClientService:()=>({invoke(raw) {
            calls.push(JSON.parse(raw)); if(state.fail)throw Error('Authorization: Bearer SEGREDO');
            return {getHttpStatusResult:()=>state.status,getResult:()=>typeof state.result==='string'?state.result:JSON.stringify(state.result)};
        }})}
    };
    vm.createContext(context);vm.runInContext(source,context);
    context.NW_CONFIG.regras=[{grupo:state.group,acoes:Object.keys(context.NW_ACOES),estabelecimentos:['ORIGEM','DESTINO']}];
    const run = (acao, p = {}, extra = []) => {
        const constraint = (name,value)=>({getFieldName:()=>name,getInitialValue:()=>value,getFinalValue:()=>value});
        const ds = context.createDataset(null,[constraint('acao',acao),constraint('parametros',typeof p==='string'?p:JSON.stringify(p)),...extra],null);
        assert.equal(ds.values.length,1);
        const row=Object.fromEntries(ds.columns.map((k,i)=>[k,ds.values[0][i]]));
        return { row, result:JSON.parse(row.resultadoJson) };
    };
    return {context,state,calls,logs,run};
}
test('acoes cobrem o contrato REST e preservam alias apoiarTipos',()=>{
    const h=setup();
    // Contrato central: 42 rotas, mais o alias de apoio (apoiarTipos).
    const native = [
        'get /tipos', 'post /tipos', 'patch /tipos',
        'get /parametros', 'post /parametros', 'patch /parametros',
        'get /etiquetas', 'get /etiquetas/situacao', 'get /etiquetas/historico',
        'post /etiquetas/confirmacoes', 'post /etiquetas/estorno',
        'post /etiquetas/inutilizacao', 'post /etiquetas/perda-extravio',
        'get /apoios/estabelecimentos', 'get /apoios/itens',
        'get /apoios/depositos', 'get /apoios/lotes', 'get /apoios/documentos-entrada',
        'get /apoios/tipos', 'get /apoios/familias',
        'get /bags', 'get /bags/elegiveis', 'get /bags/historico',
        'post /bags', 'patch /bags', 'post /bags/conteudo', 'post /bags/eventos',
        'get /conteudo-bag', 'get /dados-impressao', 'get /geracoes',
        'get /recebimentos', 'get /recebimentos/embalagens', 'get /recebimentos/itens',
        'get /operacoes/natureza', 'get /operacoes/embalagens-origem',
        'get /operacoes', 'get /operacoes/resultado', 'get /operacoes/itens',
        'get /operacoes/eventos', 'post /operacoes/transferencias',
        'post /operacoes/remessas', 'post /operacoes/devolucoes'
    ].sort();
    assert.equal(Object.keys(h.context.NW_ACOES).length,43);
    assert.deepEqual(JSON.parse(JSON.stringify(h.context.NW_ACOES.consultarTiposApoio)), JSON.parse(JSON.stringify(h.context.NW_ACOES.apoiarTipos)));
    assert.deepEqual(Object.entries(h.context.NW_ACOES).filter(([nome]) => nome !== 'apoiarTipos').map(([, a])=>a.metodo+' '+a.rota).sort(),native);
});
test('apoio de tipos: alias autorizado usa GET e aceita todos somente em apoios/tipos',()=>{
    const h=setup(page([{codigo:'CX',descricao:'CAIXA',ativo:false,versao:3}],false,'',true));
    const r=h.run('consultarTiposApoio',{filtro:'ca',ativo:'todos',limite:20});
    assert.equal(r.result.sucesso,true); assert.equal(h.calls.length,1);
    assert.equal(h.calls[0].method,'get');
    assert.match(h.calls[0].endpoint,/\/apoios\/tipos\?/);
    assert.match(h.calls[0].endpoint,/ativo=todos/); assert.match(h.calls[0].endpoint,/filtro=ca/);
    assert.equal(r.result.dados[0].codigo,'CX');
    assert.equal(h.run('consultarTipos',{ativo:'todos'}).result.codigoErro,'PARAMETROS_INVALIDOS');
    assert.equal(h.calls.length,1);
});
test('constraints escalares sem final aceitas, faixas e repeticoes recusadas',()=>{
    const h=setup(page([],false,'',true));
    const c=(name,initial,final)=>({getFieldName:()=>name,getInitialValue:()=>initial,getFinalValue:()=>final});
    let ds=h.context.createDataset(null,[c('acao','consultarTipos',null),c('parametros','{}',null)],null);
    assert.equal(ds.values[0][1],'true');
    ds=h.context.createDataset(null,[c('acao','consultarTipos','consultarEtiquetas')],null);assert.equal(ds.values[0][1],'false');
    ds=h.context.createDataset(null,[c('acao','consultarTipos',null),c('acao','consultarTipos',null)],null);assert.equal(ds.values[0][1],'false');
});
test('tipos consulta uma pagina, preserva cursor, usuario e servico funcionais',()=>{
    const h=setup(page([{codTipo:'PL',versao:1}],true,'PL',true));
    const r=h.run('consultarTipos',{limite:1,descricao:'a&b'});
    assert.equal(r.result.temMais,true);assert.equal(r.row.proximoCursor,'PL');
    assert.equal(h.calls.length,1);assert.equal(h.calls[0].serviceCode,'DATASUL_REST_HOMOLOG');
    assert.match(h.calls[0].endpoint,/descricao=a%26b/);assert.match(h.calls[0].endpoint,/usuario=usuario-teste/);
});
test('vazio valido conserva uma linha de sucesso com dados vazios',()=>{
    const h=setup(page([],false,'',true));const r=h.run('consultarTipos');
    assert.equal(r.row.sucesso,'true');assert.deepEqual(r.result.dados,[]);
});
test('sem politica, contexto ou grupo correspondente nega sem chamar REST',()=>{
    let h=setup();h.context.NW_CONFIG.regras=[];assert.equal(h.run('consultarTipos').result.codigoErro,'AUTORIZACAO_NAO_CONFIGURADA');assert.equal(h.calls.length,0);
    h=setup();h.state.company='';assert.equal(h.run('consultarTipos').result.codigoErro,'CONTEXTO_INVALIDO');assert.equal(h.calls.length,0);
    h=setup();h.state.groupUser='outra-pessoa';assert.equal(h.run('consultarTipos').result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,0);
});
test('identidade, lista de permitidos e endpoint do cliente sao recusados',()=>{
    for(const name of ['usuario','WKUser','companyId','estabelecimentosPermitidos','endpoint','method','headers','__proto__']) {
        const h=setup();const p=JSON.parse('{"'+name+'":"forjado"}');
        assert.equal(h.run('consultarTipos',p).result.codigoErro,'CAMPO_NAO_PERMITIDO');assert.equal(h.calls.length,0);
    }
    const h=setup();assert.equal(h.run('constructor').result.codigoErro,'ACAO_INVALIDA');
});
test('permissoes de outra acao nao ampliam os estabelecimentos desta',()=>{
    const h=setup();h.context.NW_CONFIG.regras=[
        {grupo:'grupo-teste',acoes:['consultarOperacoes'],estabelecimentos:['ORIGEM']},
        {grupo:'grupo-teste',acoes:['apoiarItens'],estabelecimentos:['DESTINO']}
    ];
    assert.equal(h.run('consultarOperacoes',{codEstabel:'DESTINO'}).result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,0);
    assert.equal(h.run('consultarOperacoes',{codEstabel:'ORIGEM'}).result.sucesso,true);
    assert.doesNotMatch(h.calls[0].endpoint,/estabelecimentoPermitido=DESTINO/);
});
test('apoios limitados a20 e filtro de pelo menos dois caracteres',()=>{
    const h=setup();assert.equal(h.run('apoiarItens',{codEstabel:'ORIGEM',filtro:'ab',limite:21}).result.codigoErro,'LIMITE_INVALIDO');
    assert.equal(h.run('apoiarTipos',{filtro:'a'}).result.codigoErro,'FILTRO_INVALIDO');assert.equal(h.calls.length,0);
});
test('IDs e zeros documentais chegam intactos a query',()=>{
    const h=setup();h.run('consultarEmbalagensOrigem',{codEstabel:'ORIGEM',natureza:'NAT',emitenteOrigem:'123',serieOrigem:'001',numeroOrigem:'000123',naturezaOrigem:'ORIG',limite:20});
    assert.match(h.calls[0].endpoint,/numeroOrigem=000123/);assert.match(h.calls[0].endpoint,/serieOrigem=001/);
});
test('geracoes preserva geracao/itens/etiquetas em vez de presumir dados',()=>{
    const h=setup({sucesso:true,codigoErro:'',mensagem:'',geracao:{idEvento:'123'},itens:[{item:'001'}],etiquetas:[],total:0,temMais:false,proximoId:''});
    const r=h.run('consultarGeracao',{idEvento:'123'});assert.equal(r.result.geracao.idEvento,'123');assert.ok(!('dados' in r.result));
});
test('natureza preserva classificacao na colecao dados sem exigir limite',()=>{
    const h=setup(page([{natureza:'NAT',codEstabel:'ORIGEM',fluxo:'TRANSFERENCIA',ramoPadrao:'DIRETO',exigeOrigem:false,editaQuantidade:false,editaPreco:true}],false,'',true));
    assert.equal(h.run('classificarNatureza',{codEstabel:'ORIGEM',natureza:'NAT'}).result.dados[0].ramoPadrao,'DIRETO');
});
test('parametros: codTipo vai na query e a pagina da API volta sem filtro local (DT118)',()=>{
    const h=setup(page([{idParam:'53',codTipo:'PL'},{idParam:'54',codTipo:'PL'}],true,'54'));
    const r=h.run('consultarParametros',{codTipo:'PL',limite:2});
    assert.match(h.calls[0].endpoint,/codTipo=PL/);assert.equal(r.result.total,2);assert.equal(r.result.dados.length,2);assert.equal(r.result.temMais,true);
});
test('situacao da etiqueta (DT121): GET com estabelecimento e etiqueta obrigatorios, sem limite',()=>{
    let h=setup({sucesso:true,codigoErro:'',mensagem:'',idEtiqueta:'121',situacaoApresentada:'EM_ESTOQUE',versao:8});
    const r=h.run('consultarSituacaoEtiqueta',{codEstabel:'ORIGEM',idEtiqueta:'121'});
    assert.equal(r.result.sucesso,true);assert.equal(h.calls.length,1);assert.equal(h.calls[0].method,'get');
    assert.match(h.calls[0].endpoint,/\/etiquetas\/situacao\?/);assert.match(h.calls[0].endpoint,/codEstabel=ORIGEM/);
    assert.match(h.calls[0].endpoint,/idEtiqueta=121/);assert.doesNotMatch(h.calls[0].endpoint,/limite=/);
    h=setup();assert.equal(h.run('consultarSituacaoEtiqueta',{codEstabel:'ORIGEM'}).result.codigoErro,'PARAMETRO_OBRIGATORIO');assert.equal(h.calls.length,0);
    h=setup();assert.equal(h.run('consultarSituacaoEtiqueta',{codEstabel:'OUTRO',idEtiqueta:'121'}).result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,0);
});
test('temMais sem cursor, cursor repetido/regressivo e total divergente recusados',()=>{
    const cases=[page([{idOperacao:'20'}],true,''),page([{idOperacao:'20'}],true,'10'),page([{idOperacao:'20'}],true,'9'),{...page([]),total:3}];
    for(const r of cases){const h=setup(r);assert.equal(h.run('consultarOperacoes',{codEstabel:'ORIGEM',aposId:'10'}).result.sucesso,false);}
});
test('HTTP falho, status ausente, JSON invalido e corpo vazio nao viram sucesso',()=>{
    for(const [result,status] of [[page(),'500'],[page(),''],['{','200'],['','200']]) {
        const h=setup(result,status);assert.equal(h.run('consultarTipos').result.sucesso,false);assert.equal(h.calls.length,1);
    }
});
test('erro de negocio preserva codigo sem vazar detalhes sensiveis',()=>{
    const h=setup({sucesso:false,codigoErro:'SEM_PERMISSAO',mensagem:'Authorization: Bearer segredo'});
    const r=h.run('consultarTipos');assert.equal(r.result.codigoErro,'SEM_PERMISSAO');assert.doesNotMatch(JSON.stringify(r),/segredo|Bearer/);
});
test('escritas desabilitadas por configuracao, sem tocar Dataset tipos existente',()=>{
    const h=setup();h.context.NW_CONFIG.escritasHabilitadas=false;assert.equal(h.run('incluirTipo',{codTipo:'PL',descricao:'PLASTICO',ativo:true,chaveIdempotente:'intencao-1'}).result.codigoErro,'ESCRITA_DESABILITADA');assert.equal(h.calls.length,0);
});
test('POST tipo, PATCH tipo e parametros usam corpo JSON e preservam versao numerica',()=>{
    for(const [acao,p,method] of [
        ['incluirTipo',{codTipo:'PL',descricao:'PLASTICO',ativo:true,versao:0,chaveIdempotente:'chave'},'post'],
        ['alterarTipo',{codTipo:'PL',descricao:'PLASTICO',ativo:false,versao:3,acao:'INATIVAR',chaveIdempotente:'chave'},'patch'],
        ['alterarParametro',{idParam:10,codEstabel:'ORIGEM',item:'001',codTipo:'PL',capacidade:20,unidade:'LT',ativo:false,versao:3,acao:'INATIVAR',chaveIdempotente:'chave'},'patch']
    ]) {
        const h=setup({sucesso:true,codigoErro:'',mensagem:'',repeticao:false,versao:4});h.context.NW_CONFIG.escritasHabilitadas=true;
        assert.equal(h.run(acao,p).result.sucesso,true);assert.equal(h.calls[0].method,method);assert.equal(h.calls[0].params.usuario,'usuario-teste');
        assert.equal(h.calls[0].params.versao,p.versao);assert.ok(h.calls[0].options.mediaType==='application/json');
        if(p.codEstabel)assert.deepEqual(h.calls[0].params.estabelecimentosPermitidos,['DESTINO','ORIGEM']);
    }
});
const command={codEstabel:'ORIGEM',codEstabelDestino:'DESTINO',natureza:'NAT',serie:'001',valorItem:1,chaveIdempotente:'mesma-intencao',selecao:[{idEtiqueta:'123',versao:'2',quantidade:10}]};
test('comando preserva chave/IDs, devolve WT e repeticao sem retry',()=>{
    const h=setup({sucesso:true,codigoErro:'',mensagem:'',wt:'456',idOperacao:'789',repeticao:true,dados:[],total:0});h.context.NW_CONFIG.escritasHabilitadas=true;
    const r=h.run('criarTransferencia',command);assert.equal(r.result.wt,'456');assert.equal(r.result.repeticao,true);assert.equal(h.calls.length,1);
    assert.equal(h.calls[0].params.selecao[0].idEtiqueta,'123');assert.equal(h.calls[0].params.chaveIdempotente,'mesma-intencao');
});
test('timeout apos comando nao repete e nao expoe excecao',()=>{
    const h=setup();h.context.NW_CONFIG.escritasHabilitadas=true;h.state.fail=true;
    const r=h.run('criarTransferencia',command);assert.equal(h.calls.length,1);assert.equal(r.result.sucesso,false);
    assert.match(r.result.mensagem,/nao gere chave nova/);assert.doesNotMatch(JSON.stringify(r)+h.logs.join(''),/SEGREDO|Bearer/);
});
test('destino nao autorizado, selecao duplicada/numerica e campos extras negam antes do POST',()=>{
    for(const c of [{...command,codEstabelDestino:'FORA'}, {...command,selecao:[command.selecao[0],command.selecao[0]]},
        {...command,selecao:[{idEtiqueta:123,versao:'2',quantidade:10}]}, {...command,selecao:[{...command.selecao[0],usuario:'forjado'}]}]) {
        const h=setup();h.context.NW_CONFIG.escritasHabilitadas=true;assert.equal(h.run('criarTransferencia',c).result.sucesso,false);assert.equal(h.calls.length,0);
    }
});
test('resultado de devolucao exige origem completa e conserva a chave',()=>{
    const h=setup();assert.equal(h.run('consultarResultadoOperacao',{codEstabel:'ORIGEM',ramo:'DEVOLUCAO',chaveIdempotente:'chave'}).result.codigoErro,'PARAMETRO_OBRIGATORIO');
    assert.equal(h.calls.length,0);
});
test('resposta com campos sensiveis e profundidade excessiva e recusada',()=>{
    for(const r of [{...page(),token:'segredo'},{...page(),dados:[{headers:{Authorization:'segredo'}}],total:1}]) {
        const h=setup(r);const out=h.run('consultarTipos');assert.equal(out.result.codigoErro,'RESPOSTA_INVALIDA');assert.doesNotMatch(JSON.stringify(out),/segredo/);
    }
});
// --- Configuracao TESTE do projeto ---
test('projeto: configuracao existente preservada e consultas DT120 no mesmo contexto TESTE',()=>{
    const ctx={};vm.createContext(ctx);vm.runInContext(source,ctx);
    assert.equal(ctx.NW_CONFIG.regras.length,5);assert.equal(ctx.NW_CONFIG.regras[0].grupo,'DefaultGroup-1');
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[0].acoes),['consultarTipos','consultarTiposApoio','incluirTipo','alterarTipo']);
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[0].estabelecimentos),[]);
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[1].acoes),['consultarParametros','apoiarEstabelecimentos','apoiarItens','incluirParametro','alterarParametro']);
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[1].estabelecimentos),['10904','11301']);
    assert.equal(ctx.NW_CONFIG.regras[2].grupo,'DefaultGroup-1');
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[2].acoes),['consultarEtiquetas','apoiarFamilias','apoiarDepositos','apoiarLotes','apoiarDocumentosEntrada']);
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[2].estabelecimentos),['10904','11301']);
    assert.equal(ctx.NW_CONFIG.regras[3].grupo,'DefaultGroup-1');
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[3].acoes),['classificarNatureza','consultarEmbalagensOrigem','consultarResultadoOperacao','obterDadosImpressao','consultarSituacaoEtiqueta','consultarBags','consultarConteudoBag','criarTransferencia','criarRemessa','criarDevolucao']);
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[3].estabelecimentos),['10904','11301']);
    assert.equal(ctx.NW_CONFIG.regras[4].grupo,'DefaultGroup-1');
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[4].acoes),['apoiarTipos','consultarGeracao','consultarOperacoes','consultarItensOperacao','consultarEventosOperacao','confirmarEtiqueta','estornarEtiqueta','inutilizarEtiqueta','registrarPerdaExtravio','consultarHistoricoEtiqueta','abrirBag','alterarBag','comandarConteudoBag','executarEventoBag','consultarElegiveisBag','consultarHistoricoBag','consultarRecebimentos','consultarItensRecebimento','consultarEmbalagensRecebimento']);
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[4].estabelecimentos),['10904','11301']);
    assert.deepEqual(Array.from(ctx.NW_CONFIG.escritasHabilitadas),['incluirTipo','alterarTipo','incluirParametro','alterarParametro','criarTransferencia','criarRemessa','criarDevolucao','confirmarEtiqueta','estornarEtiqueta','inutilizarEtiqueta','registrarPerdaExtravio','abrirBag','alterarBag','comandarConteudoBag','executarEventoBag']);
    assert.equal(ctx.NW_CONFIG.serviceCode,'DATASUL_REST_HOMOLOG');
});
test('projeto: comando fora da lista habilitada nega sem chamar REST, mesmo com grupo autorizado',()=>{
    for(const [acao,p] of [['criarTransferencia',command]]) {
        // Todos os comandos atuais estao habilitados no TESTE; a lista reduzida aqui prova que ela e respeitada.
        const h=setup();h.context.NW_CONFIG.escritasHabilitadas=['incluirTipo','alterarTipo','incluirParametro','alterarParametro'];
        assert.equal(h.run(acao,p).result.codigoErro,'ESCRITA_DESABILITADA');assert.equal(h.calls.length,0);
    }
    const h=setup({sucesso:true,codigoErro:'',mensagem:'',repeticao:false,codTipo:'PL',descricao:'PLASTICO',ativo:true,versao:1,idEvento:'1'});
    assert.equal(h.run('incluirTipo',{codTipo:'PL',descricao:'PLASTICO',ativo:true,versao:0,chaveIdempotente:'k'}).result.sucesso,true);assert.equal(h.calls.length,1);
});
test('projeto: lista habilitada nao substitui permissao por grupo/acao',()=>{
    const h=setup();h.context.NW_CONFIG.regras=[{grupo:'grupo-teste',acoes:['consultarTipos'],estabelecimentos:[]}];
    assert.equal(h.run('incluirTipo',{codTipo:'PL',descricao:'PLASTICO',ativo:true,versao:0,chaveIdempotente:'k'}).result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,0);
});
test('projeto: colleagueGroup com colunas curtas (como na API REST do TESTE) autoriza; identidade divergente nega',()=>{
    let h=setup(page([],false,'',true));
    h.context.DatasetFactory.getDataset=()=>({rowsCount:2,getValue(i,k){
        const linha=[{companyId:'empresa-teste',colleagueId:'usuario-teste',groupId:'grupo-teste'},{companyId:'empresa-teste',colleagueId:'outra-pessoa',groupId:'grupo-admin'}][i];
        return k.indexOf('colleagueGroupPK.')===0?null:linha[k];
    }});
    assert.equal(h.run('consultarTipos').result.sucesso,true);assert.equal(h.calls.length,1);
    h.context.NW_CONFIG.regras=[{grupo:'grupo-admin',acoes:['consultarTipos'],estabelecimentos:[]}];
    assert.equal(h.run('consultarTipos').result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,1);
});
test('projeto: constraint sqlLimit do Fluig e ignorada; outra desconhecida e recusada com o nome',()=>{
    const h=setup(page([],false,'',true));
    const c=(name,value)=>({getFieldName:()=>name,getInitialValue:()=>value,getFinalValue:()=>value});
    let ds=h.context.createDataset(null,[c('acao','consultarTipos'),c('parametros','{}'),c('sqlLimit','1')],null);
    assert.equal(ds.values[0][1],'true');assert.equal(h.calls.length,1);assert.doesNotMatch(h.calls[0].endpoint,/sqlLimit/);
    ds=h.context.createDataset(null,[c('acao','consultarTipos'),c('parametros','{}'),c('outraCoisa','x')],null);
    assert.equal(ds.values[0][1],'false');assert.match(ds.values[0][3],/outraCoisa/);assert.equal(h.calls.length,1);
});
// --- Ampliacao DT120: servico simulado; identidades fiscais opacas. ---
test('DT120: consulta antiga de etiquetas preserva filtros exatos e IDs textuais',()=>{
    const p={codEstabel:'ORIGEM',codEtiqueta:'0000123',item:'000123',lote:'001',codTipo:'CX',tipoControle:'EMBALAGEM',tipoLocal:'ESTAB',situacao:'ATIVA',idBag:'0007',aposId:'12',limite:1};
    const h=setup(page([{idEtiqueta:'13',quantidadeInicial:10,quantidadeAtual:5,versao:'2'}],true,'13'));
    const r=h.run('consultarEtiquetas',p);
    assert.equal(r.result.sucesso,true);assert.equal(r.result.dados[0].idEtiqueta,'13');assert.equal(r.row.proximoCursor,'13');
    const q=new URL('https://teste'+h.calls[0].endpoint).searchParams;
    for(const [k,v] of Object.entries(p))assert.equal(q.get(k),String(v));
    assert.equal(q.has('modoNotas'),false);assert.equal(q.has('documento'),false);
});
test('DT120: faixas e exatos coexistem sem perder zeros ou datas ISO',()=>{
    const p={codEstabel:'ORIGEM',item:'000123',estabelDe:'00001',estabelAte:'99999',itemDe:'000100',itemAte:'000200',depositoDe:'001',depositoAte:'INS',etiquetaDe:'000001',etiquetaAte:'000999',loteDe:'01',loteAte:'09',validadeDe:'2032-01-01',validadeAte:'2033-12-31',familiaDe:'0001',familiaAte:'0009',modoNotas:'INTERVALO',notaDe:'0009999801',notaAte:'0009999805',aposId:'10',limite:20};
    const h=setup();assert.equal(h.run('consultarEtiquetas',p).result.sucesso,true);
    const q=new URL('https://teste'+h.calls[0].endpoint).searchParams;
    for(const [k,v] of Object.entries(p))assert.equal(q.get(k),String(v));
    assert.deepEqual(q.getAll('estabelecimentoPermitido'),['DESTINO','ORIGEM']);
    assert.equal(q.get('usuario'),'usuario-teste');assert.equal(h.calls.length,1);
});
test('DT120: tres novos apoios usam GET, contexto autorizado e cursor por codigo',()=>{
    for(const [acao,rota] of [['apoiarDepositos','depositos'],['apoiarLotes','lotes'],['apoiarDocumentosEntrada','documentos-entrada']]) {
        const h=setup(page([{codigo:'001',descricao:'Apoio'}],true,'001',true));
        const r=h.run(acao,{codEstabel:'ORIGEM',filtro:'in&%',limite:20});
        assert.equal(r.result.sucesso,true);assert.equal(r.row.campoCursor,'proximoCodigo');assert.equal(r.row.proximoCursor,'001');
        const req=h.calls[0];assert.equal(req.method,'get');assert.equal(req.serviceCode,'DATASUL_REST_HOMOLOG');
        const url=new URL('https://teste'+req.endpoint);assert.ok(url.pathname.endsWith('/apoios/'+rota));
        assert.equal(url.searchParams.get('filtro'),'in&%');assert.equal(url.searchParams.get('codEstabel'),'ORIGEM');
        assert.deepEqual(url.searchParams.getAll('estabelecimentoPermitido'),['DESTINO','ORIGEM']);
    }
});
test('DT120: lotes aceitam recortes de estabelecimento, item e deposito',()=>{
    const p={filtro:'01',estabelDe:'A',estabelAte:'Z',item:'000123',itemDe:'000100',itemAte:'000200',depositoDe:'001',depositoAte:'INS',aposCodigo:'L001'};
    const h=setup(page([],false,'',true));assert.equal(h.run('apoiarLotes',p).result.sucesso,true);
    const q=new URL('https://teste'+h.calls[0].endpoint).searchParams;
    for(const [k,v] of Object.entries(p))assert.equal(q.get(k),v);
    assert.equal(q.get('limite'),'20');
});
test('DT120: documento e cursor fiscal opacos sao preservados acima de100 caracteres',()=>{
    const codigo='0001|000001|001|0009999801|COMPRA & A+B/ç?=#'+'.'.repeat(120);
    const h=setup(page([{codigo,numero:'0009999801',serie:'001'}],true,codigo,true));
    const r=h.run('apoiarDocumentosEntrada',{filtro:'999980',estabelDe:'A',estabelAte:'Z'});
    assert.equal(r.result.sucesso,true);assert.equal(r.row.proximoCursor,codigo);assert.equal(r.result.dados[0].codigo,codigo);
    h.state.result=page([],false,'',true);
    assert.equal(h.run('apoiarDocumentosEntrada',{filtro:'999980',aposCodigo:codigo}).result.sucesso,true);
    assert.equal(new URL('https://teste'+h.calls[1].endpoint).searchParams.get('aposCodigo'),codigo);
    h.state.result=page();assert.equal(h.run('consultarEtiquetas',{modoNotas:'ESPECIFICAS',documento:codigo}).result.sucesso,true);
    assert.deepEqual(new URL('https://teste'+h.calls[2].endpoint).searchParams.getAll('documento'),[codigo]);
});
test('DT120: notas especificas geram parametros documento repetidos e codificados separadamente',()=>{
    const docs=['000001|001|NF&A=1+ç','000002|002|NF,2 /?#'];
    const h=setup();assert.equal(h.run('consultarEtiquetas',{modoNotas:'ESPECIFICAS',documento:docs}).result.sucesso,true);
    const q=new URL('https://teste'+h.calls[0].endpoint).searchParams;
    assert.deepEqual(q.getAll('documento'),docs);assert.equal(q.get('modoNotas'),'ESPECIFICAS');assert.equal(q.has('notaDe'),false);
    assert.equal(h.calls.length,1);
});
test('DT120: selecao aceita uma nota, vinte notas e duplicatas sem reconstruir identidade',()=>{
    for(const docs of ['0001|001|NF',Array.from({length:20},(_,i)=>'opaco-'+i),['mesma-chave','mesma-chave']]) {
        const h=setup();assert.equal(h.run('consultarEtiquetas',{modoNotas:'ESPECIFICAS',documento:docs}).result.sucesso,true);
        assert.deepEqual(new URL('https://teste'+h.calls[0].endpoint).searchParams.getAll('documento'),typeof docs==='string'?[docs]:docs);
    }
});
test('DT120: listas invalidas de documentos sao recusadas antes de chamar REST',()=>{
    for(const documento of [[],Array(21).fill('nota'),null,{},1,true,[''],['   '],[1],[null],[{}],[['nota']],['nota\nquebrada'],'']) {
        const h=setup();assert.equal(h.run('consultarEtiquetas',{modoNotas:'ESPECIFICAS',documento}).result.codigoErro,'PARAMETROS_INVALIDOS');assert.equal(h.calls.length,0);
    }
});
test('DT120: modos invalidos, selecao ausente e mistura de notas sao recusados',()=>{
    for(const p of [{modoNotas:'especificas',documento:'nota'},{modoNotas:'OUTRO'},{modoNotas:'ESPECIFICAS'},{documento:'nota'},{modoNotas:'INTERVALO',documento:'nota'},{modoNotas:'ESPECIFICAS',documento:'nota',notaDe:'1'},{modoNotas:'ESPECIFICAS',documento:'nota',notaAte:'9'}]) {
        const h=setup();assert.equal(h.run('consultarEtiquetas',p).result.codigoErro,'FILTRO_INVALIDO');assert.equal(h.calls.length,0);
    }
});
test('DT120: novos apoios mantem limites, filtro obrigatorio e cursor textual',()=>{
    for(const acao of ['apoiarDepositos','apoiarLotes','apoiarDocumentosEntrada']) {
        for(const p of [{},{filtro:'a'},{filtro:'ab',limite:21},{filtro:'ab',limite:0},{filtro:'ab',aposCodigo:3}]) {
            const h=setup();assert.equal(h.run(acao,p).result.sucesso,false);assert.equal(h.calls.length,0);
        }
    }
    const h=setup();assert.equal(h.run('consultarEtiquetas',{itemDe:'0001',limite:101}).result.codigoErro,'LIMITE_INVALIDO');assert.equal(h.calls.length,0);
});
test('DT120: listas continuam proibidas nos filtros comuns e nas demais acoes',()=>{
    for(const [acao,p] of [['consultarEtiquetas',{itemDe:['001']}],['apoiarLotes',{filtro:['01']}],['consultarTipos',{documento:['nota']}],['apoiarDocumentosEntrada',{filtro:'ab',documento:['nota']}],['apoiarDepositos',{filtro:'ab',itemDe:'1'}]]) {
        const h=setup();assert.equal(h.run(acao,p).result.sucesso,false);assert.equal(h.calls.length,0);
    }
});
test('DT120: dados de identidade e autorizacao do navegador continuam recusados',()=>{
    for(const acao of ['consultarEtiquetas','apoiarDepositos','apoiarLotes','apoiarDocumentosEntrada']) {
        for(const campo of ['usuario','empresa','estabelecimentoPermitido','estabelecimentosPermitidos','endpoint']) {
            const h=setup();assert.equal(h.run(acao,{filtro:'ab',[campo]:'FORJADO'}).result.sucesso,false);assert.equal(h.calls.length,0);
        }
    }
});
test('DT120: falta de permissao e estabelecimento exato proibido nao chamam REST',()=>{
    for(const acao of ['consultarEtiquetas','apoiarFamilias','apoiarDepositos','apoiarLotes','apoiarDocumentosEntrada']) {
        let h=setup();h.context.NW_CONFIG.regras=[{grupo:'grupo-teste',acoes:['consultarTipos'],estabelecimentos:['ORIGEM']}];
        const p=acao==='consultarEtiquetas'?{}:{filtro:'ab'};
        assert.equal(h.run(acao,p).result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,0);
        if(acao==='apoiarFamilias')continue; // Este apoio existente nao recebe codEstabel.
        h=setup();assert.equal(h.run(acao,{...p,codEstabel:'FORA'}).result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,0);
    }
});
test('DT120: recusa funcional do backend nao vira lista vazia ou sucesso',()=>{
    for(const codigoErro of ['DOCUMENTO_INDISPONIVEL','HISTORICO_INCONSISTENTE','CONSULTA_AMPLA','FILTRO_INVALIDO','SEM_PERMISSAO']) {
        const h=setup({sucesso:false,codigoErro,mensagem:'Consulta recusada.'});
        const r=h.run('consultarEtiquetas',{modoNotas:'ESPECIFICAS',documento:'identidade-opaca'});
        assert.equal(r.result.sucesso,false);assert.equal(r.result.codigoErro,codigoErro);assert.equal('dados' in r.result,false);assert.equal(h.calls.length,1);
    }
});
test('DT120: cursor repetido dos novos apoios e envelope fiscal invalido sao recusados',()=>{
    for(const acao of ['apoiarDepositos','apoiarLotes','apoiarDocumentosEntrada']) {
        const h=setup(page([{codigo:'001'}],true,'001',true));
        assert.equal(h.run(acao,{filtro:'ab',aposCodigo:'001'}).result.codigoErro,'CURSOR_INVALIDO');
    }
    const h=setup(page([],false,'',true));assert.equal(h.run('apoiarDocumentosEntrada',{filtro:'ab',aposCodigo:'a\nb'}).result.codigoErro,'PARAMETROS_INVALIDOS');assert.equal(h.calls.length,0);
});
test('DT120: limite global de entrada tambem protege identidades fiscais opacas',()=>{
    const h=setup();assert.equal(h.run('consultarEtiquetas',{modoNotas:'ESPECIFICAS',documento:'x'.repeat(h.context.NW_CONFIG.maxEntrada)}).result.codigoErro,'ENTRADA_INVALIDA');assert.equal(h.calls.length,0);
});
test('DT120: inclusao de parametro ja habilitada permanece disponivel',()=>{
    const h=setup({sucesso:true,codigoErro:'',mensagem:'',repeticao:false,idParam:1,versao:1});
    assert.equal(h.run('incluirParametro',{codEstabel:'ORIGEM',item:'001',codTipo:'PL',capacidade:20,unidade:'LT',ativo:true,chaveIdempotente:'k'}).result.sucesso,true);
    assert.equal(h.calls[0].method,'post');assert.equal(h.calls[0].params.capacidade,20);
});

// --- Rotas 28 a 42: comandos de etiqueta e Bag, historicos e recebimentos (servico simulado) ---
const okCmd={sucesso:true,codigoErro:'',mensagem:'',repeticao:false,versao:3};
const recusaAntesDoRest=(acao,p,codigo)=>{
    const h=setup(okCmd);const r=h.run(acao,p);
    assert.equal(r.result.sucesso,false,acao+' '+JSON.stringify(p));
    if(codigo)assert.equal(r.result.codigoErro,codigo,acao+' '+JSON.stringify(p));
    assert.equal(h.calls.length,0);
};
const etiquetaCmd={codEstabel:'ORIGEM',idEtiqueta:'123',versao:2,chaveIdempotente:'chave-1'};
const comandosEtiqueta=[
    ['confirmarEtiqueta','/etiquetas/confirmacoes',{...etiquetaCmd,acao:'CONFIRMAR_IMPRESSAO'}],
    ['estornarEtiqueta','/etiquetas/estorno',{...etiquetaCmd,quantidadeAtual:7.5,justificativa:'Contagem fisica'}],
    ['inutilizarEtiqueta','/etiquetas/inutilizacao',{...etiquetaCmd,acao:'INUTILIZAR',justificativa:'Etiqueta rasgada'}],
    ['registrarPerdaExtravio','/etiquetas/perda-extravio',{...etiquetaCmd,acao:'REGISTRAR_PERDA_EXTRAVIO',justificativa:'Nao localizada'}]
];
const bagCmd={codEstabel:'ORIGEM',idBag:'77',versao:4,chaveIdempotente:'chave-bag'};
const comandosBag=[
    ['abrirBag','post','/bags',{codEstabel:'ORIGEM',codTipo:'BG',destino:'DESTINO',motorista:'JOAO',chaveIdempotente:'chave-bag'}],
    ['alterarBag','patch','/bags',{...bagCmd,acao:'EDITAR',nroLacre:'L-001'}],
    ['comandarConteudoBag','post','/bags/conteudo',{...bagCmd,acao:'INCLUIR',etiquetas:[{idEtiqueta:'10',versao:1},{idEtiqueta:'11',versao:2}]}],
    ['executarEventoBag','post','/bags/eventos',{...bagCmd,acao:'LACRAR',nroLacre:'L-001'}]
];
test('rotas 28-42: comandos de etiqueta e Bag usam o metodo da rota, corpo JSON e identidade do servidor',()=>{
    for(const [acao,method,rota,p] of [...comandosEtiqueta.map(([a,r,p])=>[a,'post',r,p]),...comandosBag]) {
        const h=setup(okCmd);const r=h.run(acao,p);
        assert.equal(r.result.sucesso,true,acao);assert.equal(r.row.acao,acao);assert.equal(h.calls.length,1);
        const req=h.calls[0];
        assert.equal(req.method,method);assert.ok(req.endpoint.endsWith('/controle-embalagens'+rota),acao);
        assert.doesNotMatch(req.endpoint,/\?/);assert.equal(req.headers['Content-Type'],'application/json');
        assert.equal(req.options.mediaType,'application/json');
        assert.deepEqual(req.params,{...p,usuario:'usuario-teste',estabelecimentosPermitidos:['DESTINO','ORIGEM']});
    }
});
test('rotas 28-42: comandos novos fora da lista habilitada ou sem grupo nao chamam REST',()=>{
    for(const [acao,p] of [...comandosEtiqueta.map(([a,,p])=>[a,p]),...comandosBag.map(([a,,,p])=>[a,p])]) {
        let h=setup(okCmd);h.context.NW_CONFIG.escritasHabilitadas=['incluirTipo','alterarTipo'];
        assert.equal(h.run(acao,p).result.codigoErro,'ESCRITA_DESABILITADA');assert.equal(h.calls.length,0);
        h=setup(okCmd);h.context.NW_CONFIG.regras=[{grupo:'grupo-teste',acoes:['consultarBags'],estabelecimentos:['ORIGEM']}];
        assert.equal(h.run(acao,p).result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,0);
        recusaAntesDoRest(acao,{...p,codEstabel:'FORA'},'SEM_PERMISSAO');
        for(const campo of ['usuario','estabelecimentosPermitidos','endpoint','headers'])
            recusaAntesDoRest(acao,{...p,[campo]:'FORJADO'},'CAMPO_NAO_PERMITIDO');
    }
});
test('rotas 28-42: falha apos enviar comando novo pede a mesma chave e nao repete',()=>{
    for(const [acao,p] of [...comandosEtiqueta.map(([a,,p])=>[a,p]),...comandosBag.map(([a,,,p])=>[a,p])]) {
        const h=setup(okCmd);h.state.fail=true;const r=h.run(acao,p);
        assert.equal(r.result.sucesso,false);assert.equal(h.calls.length,1);assert.match(r.result.mensagem,/nao gere chave nova/);
        assert.doesNotMatch(JSON.stringify(r)+h.logs.join(''),/SEGREDO|Bearer/);
    }
    const h=setup({sucesso:false,codigoErro:'CONFLITO_VERSAO',mensagem:'Etiqueta alterada por outro usuario.'});
    const r=h.run('confirmarEtiqueta',comandosEtiqueta[0][2]);
    assert.equal(r.result.codigoErro,'CONFLITO_VERSAO');assert.doesNotMatch(r.result.mensagem,/chave nova/);
});
test('rotas 28-42: etiqueta exige ID textual positivo, versao inteira positiva e chave sem espacos',()=>{
    const [acao,,p]=comandosEtiqueta[0];
    for(const idEtiqueta of [123,'0','-1','12a','',' 1','99999999999'])recusaAntesDoRest(acao,{...p,idEtiqueta});
    for(const versao of [0,-1,1.5,'2',null,true])recusaAntesDoRest(acao,{...p,versao},'PARAMETROS_INVALIDOS');
    for(const chaveIdempotente of ['com espaco','k'.repeat(65),'acentuação','',1])recusaAntesDoRest(acao,{...p,chaveIdempotente});
    for(const campo of ['codEstabel','idEtiqueta','versao','acao','chaveIdempotente']) {
        const q={...p};delete q[campo];recusaAntesDoRest(acao,q,'PARAMETRO_OBRIGATORIO');
    }
    const h=setup(okCmd);assert.equal(h.run(acao,{...p,chaveIdempotente:'A-z_0'.padEnd(64,'9')}).result.sucesso,true);
});
test('rotas 28-42: confirmacao, inutilizacao e perda aceitam somente a acao da propria rota',()=>{
    const [,,conf]=comandosEtiqueta[0],[,,inut]=comandosEtiqueta[2],[,,perda]=comandosEtiqueta[3];
    for(const acao of ['confirmar_impressao','INUTILIZAR','OUTRA',''])recusaAntesDoRest('confirmarEtiqueta',{...conf,acao});
    recusaAntesDoRest('confirmarEtiqueta',{...conf,acao:'RECEBER_FISICO'},'PARAMETRO_OBRIGATORIO');
    recusaAntesDoRest('confirmarEtiqueta',{...conf,acao:'RECEBER_FISICO',justificativa:'   '},'PARAMETRO_OBRIGATORIO');
    const h=setup(okCmd);assert.equal(h.run('confirmarEtiqueta',{...conf,acao:'RECEBER_FISICO',justificativa:'Chegou sem NF'}).result.sucesso,true);
    recusaAntesDoRest('inutilizarEtiqueta',{...inut,acao:'REGISTRAR_PERDA_EXTRAVIO'},'PARAMETROS_INVALIDOS');
    recusaAntesDoRest('registrarPerdaExtravio',{...perda,acao:'INUTILIZAR'},'PARAMETROS_INVALIDOS');
    for(const [acao,p] of [['inutilizarEtiqueta',inut],['registrarPerdaExtravio',perda]]) {
        const q={...p};delete q.justificativa;recusaAntesDoRest(acao,q,'PARAMETRO_OBRIGATORIO');
    }
});
test('rotas 28-42: estorno aceita quantidade nao negativa com ate quatro casas e exige justificativa',()=>{
    const [acao,,p]=comandosEtiqueta[1];
    for(const quantidadeAtual of [0,1,1.2345,999999.9999]) {
        const h=setup(okCmd);assert.equal(h.run(acao,{...p,quantidadeAtual}).result.sucesso,true,String(quantidadeAtual));
        assert.equal(h.calls[0].params.quantidadeAtual,quantidadeAtual);
    }
    for(const quantidadeAtual of [-1,1.23456,'1',null,true])recusaAntesDoRest(acao,{...p,quantidadeAtual},'PARAMETROS_INVALIDOS');
    const q={...p};delete q.quantidadeAtual;recusaAntesDoRest(acao,q,'PARAMETRO_OBRIGATORIO');
    recusaAntesDoRest(acao,{...p,justificativa:''},'PARAMETRO_OBRIGATORIO');
});
test('rotas 28-42: justificativa aceita varias linhas ate 1000 caracteres, sem outros controles',()=>{
    const [acao,,p]=comandosEtiqueta[2];
    const h=setup(okCmd);const texto='Linha 1\r\nLinha\t2\n'+'x'.repeat(980);
    assert.equal(h.run(acao,{...p,justificativa:texto}).result.sucesso,true);assert.equal(h.calls[0].params.justificativa,texto);
    for(const justificativa of ['x'.repeat(1001),'antes\u0000depois','sino\u0007','esc\u001b',5])recusaAntesDoRest(acao,{...p,justificativa},'PARAMETROS_INVALIDOS');
});
test('rotas 28-42: abrir Bag exige tipo de 2 ou 3 letras/numeros e limita destino',()=>{
    const [acao,,,p]=comandosBag[0];
    for(const codTipo of ['BG','Z9R']){const h=setup(okCmd);assert.equal(h.run(acao,{...p,codTipo}).result.sucesso,true);}
    for(const codTipo of ['B','ABCD','B-G','B G'])recusaAntesDoRest(acao,{...p,codTipo},'PARAMETROS_INVALIDOS');
    recusaAntesDoRest(acao,{...p,destino:'d'.repeat(81)},'PARAMETROS_INVALIDOS');
    const h=setup(okCmd);assert.equal(h.run(acao,{...p,destino:'d'.repeat(80)}).result.sucesso,true);
    for(const campo of ['codEstabel','codTipo','chaveIdempotente']){const q={...p};delete q[campo];recusaAntesDoRest(acao,q,'PARAMETRO_OBRIGATORIO');}
    recusaAntesDoRest(acao,{...p,idBag:'1'},'CAMPO_NAO_PERMITIDO');
});
test('rotas 28-42: alterar Bag exige ao menos um campo editavel, acao EDITAR e lacre preenchido',()=>{
    const [acao,,,p]=comandosBag[1];
    for(const extra of [{destino:'CD'},{motorista:'ANA'},{nroLacre:'L-9'}]) {
        const q={...bagCmd,...extra};const h=setup(okCmd);assert.equal(h.run(acao,q).result.sucesso,true,JSON.stringify(extra));
        assert.equal(h.calls[0].method,'patch');
    }
    recusaAntesDoRest(acao,{...bagCmd},'PARAMETRO_OBRIGATORIO');
    recusaAntesDoRest(acao,{...bagCmd,acao:'EDITAR'},'PARAMETRO_OBRIGATORIO');
    recusaAntesDoRest(acao,{...p,acao:'LACRAR'},'PARAMETROS_INVALIDOS');
    for(const nroLacre of ['','   ','l'.repeat(41)])recusaAntesDoRest(acao,{...p,nroLacre},'PARAMETROS_INVALIDOS');
    for(const idBag of ['0','7a',77])recusaAntesDoRest(acao,{...p,idBag},'PARAMETROS_INVALIDOS');
});
test('rotas 28-42: conteudo do Bag aceita de 1 a 100 etiquetas com versao numerica e exige justificativa para retirar',()=>{
    const [acao,,,p]=comandosBag[2];
    const cem=Array.from({length:100},(_,i)=>({idEtiqueta:String(i+1),versao:1}));
    let h=setup(okCmd);assert.equal(h.run(acao,{...p,etiquetas:cem}).result.sucesso,true);assert.equal(h.calls[0].params.etiquetas.length,100);
    h=setup(okCmd);assert.equal(h.run(acao,{...p,acao:'RETIRAR',justificativa:'Etiqueta errada'}).result.sucesso,true);
    recusaAntesDoRest(acao,{...p,acao:'RETIRAR'},'PARAMETRO_OBRIGATORIO');
    for(const a of ['incluir','MOVER'])recusaAntesDoRest(acao,{...p,acao:a},'PARAMETROS_INVALIDOS');
    recusaAntesDoRest(acao,{...p,acao:''},'PARAMETRO_OBRIGATORIO');
    for(const etiquetas of [[],[...cem,{idEtiqueta:'101',versao:1}],'10',{idEtiqueta:'10',versao:1},[null],['10'],
        [{idEtiqueta:'10',versao:'1'}],[{idEtiqueta:10,versao:1}],[{idEtiqueta:'0',versao:1}],[{idEtiqueta:'10',versao:0}],
        [{idEtiqueta:'10',versao:1,quantidade:5}],[{idEtiqueta:'10',versao:1},{idEtiqueta:'10',versao:2}]])
        recusaAntesDoRest(acao,{...p,etiquetas},'SELECAO_INVALIDA');
    const q={...p};delete q.etiquetas;recusaAntesDoRest(acao,q,'PARAMETRO_OBRIGATORIO');
});
test('rotas 28-42: eventos do Bag exigem os dados de cada evento e cancelar/reabrir nao mudam metadados',()=>{
    const acao='executarEventoBag';
    for(const p of [{acao:'LACRAR',nroLacre:'L-1'},{acao:'ENVIAR',destino:'CD',motorista:'ANA'},{acao:'ENVIAR',destino:'CD',motorista:'ANA',nroLacre:'L-1'},
        {acao:'CANCELAR',justificativa:'Bag vazio'},{acao:'REABRIR',justificativa:'Faltou etiqueta'}]) {
        const h=setup(okCmd);assert.equal(h.run(acao,{...bagCmd,...p}).result.sucesso,true,p.acao);assert.equal(h.calls[0].params.acao,p.acao);
    }
    for(const p of [{acao:'LACRAR'},{acao:'ENVIAR',destino:'CD'},{acao:'ENVIAR',motorista:'ANA'},{acao:'ENVIAR',destino:' ',motorista:'ANA'},
        {acao:'CANCELAR'},{acao:'REABRIR',justificativa:''}])
        recusaAntesDoRest(acao,{...bagCmd,...p},'PARAMETRO_OBRIGATORIO');
    for(const extra of [{nroLacre:'L-1'},{destino:'CD'},{motorista:'ANA'}]) {
        recusaAntesDoRest(acao,{...bagCmd,acao:'CANCELAR',justificativa:'x',...extra},'CAMPO_NAO_PERMITIDO');
        recusaAntesDoRest(acao,{...bagCmd,acao:'REABRIR',justificativa:'x',...extra},'CAMPO_NAO_PERMITIDO');
    }
    for(const a of ['lacrar','FECHAR','EDITAR'])recusaAntesDoRest(acao,{...bagCmd,acao:a,nroLacre:'L-1'},'PARAMETROS_INVALIDOS');
    recusaAntesDoRest(acao,{...bagCmd,acao:'',nroLacre:'L-1'},'PARAMETRO_OBRIGATORIO');
});
const consultasNovas=[
    ['consultarHistoricoEtiqueta','/etiquetas/historico',{codEstabel:'ORIGEM',idEtiqueta:'123'},'proximoRegistro','aposRegistro',100],
    ['consultarElegiveisBag','/bags/elegiveis',{idBag:'77'},'proximoId','aposId',20],
    ['consultarHistoricoBag','/bags/historico',{idBag:'77'},'proximoId','aposId',20],
    ['consultarRecebimentos','/recebimentos',{codEstabel:'ORIGEM',dataIni:'2026-10-01',dataFim:'2026-10-23'},'proximoDocumento','aposDocumento',100],
    ['consultarItensRecebimento','/recebimentos/itens',{codEstabel:'ORIGEM',emitente:'000123',serie:'001',numero:'0009999801',natureza:'1.102'},'proximaSequencia','aposSequencia',100],
    ['consultarEmbalagensRecebimento','/recebimentos/embalagens',{codEstabel:'ORIGEM',emitente:'000123',serie:'001',numero:'0009999801',natureza:'1.102'},'proximoId','aposId',100]
];
test('rotas 28-42: consultas novas usam GET com filtros na query, limite padrao 20 e cursor proprio',()=>{
    for(const [acao,rota,p,cursor] of consultasNovas) {
        const h=setup({...page([{id:'1'}],true,''),[cursor]:'50'});const r=h.run(acao,p);
        assert.equal(r.result.sucesso,true,acao);assert.equal(r.row.campoCursor,cursor);assert.equal(r.row.proximoCursor,'50');
        const req=h.calls[0];assert.equal(req.method,'get');assert.equal(req.params,undefined);
        const url=new URL('https://teste'+req.endpoint);assert.ok(url.pathname.endsWith('/controle-embalagens'+rota),acao);
        const q=url.searchParams;
        for(const [k,v] of Object.entries(p))assert.equal(q.get(k),v,acao+' '+k);
        assert.equal(q.get('limite'),'20');assert.equal(q.get('usuario'),'usuario-teste');
        assert.deepEqual(q.getAll('estabelecimentoPermitido'),['DESTINO','ORIGEM']);
    }
});
test('rotas 28-42: consultas novas exigem filtros obrigatorios e respeitam o teto de cada rota',()=>{
    for(const [acao,,p,,,teto] of consultasNovas) {
        for(const campo of Object.keys(p)){const q={...p};delete q[campo];recusaAntesDoRest(acao,q,'PARAMETRO_OBRIGATORIO');}
        for(const campo of Object.keys(p).filter(c=>!/^(idEtiqueta|idBag|emitente)$/.test(c)))recusaAntesDoRest(acao,{...p,[campo]:'  '},'PARAMETRO_OBRIGATORIO');
        for(const limite of [0,teto+1,'abc',true,-1,1.5])recusaAntesDoRest(acao,{...p,limite},'LIMITE_INVALIDO');
        for(const limite of [teto,String(teto)]){const h=setup(page());assert.equal(h.run(acao,{...p,limite}).result.sucesso,true,acao+' '+limite);}
        recusaAntesDoRest(acao,{...p,usuario:'forjado'},'CAMPO_NAO_PERMITIDO');
        recusaAntesDoRest(acao,{...p,estabelecimentoPermitido:'FORA'},'CAMPO_NAO_PERMITIDO');
        if(p.codEstabel)recusaAntesDoRest(acao,{...p,codEstabel:'FORA'},'SEM_PERMISSAO');
    }
});
test('rotas 28-42: IDs, emitente e cursores numericos das consultas novas sao inteiros em texto',()=>{
    const porAcao=Object.fromEntries(consultasNovas.map(c=>[c[0],c[2]]));
    for(const [acao,campo,valores] of [
        ['consultarHistoricoEtiqueta','idEtiqueta',['0','12a',123,'99999999999']],
        ['consultarElegiveisBag','idBag',['0','-7',77,'7.0']],
        ['consultarHistoricoBag','aposId',['','x',10]],
        ['consultarItensRecebimento','emitente',['ABC','12 3',123]],
        ['consultarItensRecebimento','aposSequencia',['x','1.5']],
        ['consultarItensRecebimento','idEvento',['evento','']],
        ['consultarEmbalagensRecebimento','sequencia',['a']]
    ]) for(const v of valores)recusaAntesDoRest(acao,{...porAcao[acao],[campo]:v},'PARAMETROS_INVALIDOS');
    const h=setup(page());
    assert.equal(h.run('consultarEmbalagensRecebimento',{...porAcao.consultarEmbalagensRecebimento,idEvento:'0',sequencia:'0010',aposId:'0'}).result.sucesso,true);
    const q=new URL('https://teste'+h.calls[0].endpoint).searchParams;assert.equal(q.get('sequencia'),'0010');assert.equal(q.get('emitente'),'000123');
});
test('rotas 28-42: cursores textuais de historico e recebimentos chegam intactos; longos so no aposDocumento',()=>{
    const registro='2026-10-23T10:00:00.000|000045';
    let h=setup(page());assert.equal(h.run('consultarHistoricoEtiqueta',{codEstabel:'ORIGEM',idEtiqueta:'123',aposRegistro:registro}).result.sucesso,true);
    assert.equal(new URL('https://teste'+h.calls[0].endpoint).searchParams.get('aposRegistro'),registro);
    recusaAntesDoRest('consultarHistoricoEtiqueta',{codEstabel:'ORIGEM',idEtiqueta:'123',aposRegistro:'r'.repeat(101)},'PARAMETROS_INVALIDOS');
    const documento='0001|000123|001|0009999801|1.102 & A+B/ç?=#'+'.'.repeat(300);
    const base={codEstabel:'ORIGEM',dataIni:'2026-10-01',dataFim:'2026-10-23'};
    h=setup(page([],false,''));assert.equal(h.run('consultarRecebimentos',{...base,aposDocumento:documento}).result.sucesso,true);
    assert.equal(new URL('https://teste'+h.calls[0].endpoint).searchParams.get('aposDocumento'),documento);
    for(const aposDocumento of ['a\nb','\u0000',7])recusaAntesDoRest('consultarRecebimentos',{...base,aposDocumento},'PARAMETROS_INVALIDOS');
    recusaAntesDoRest('consultarRecebimentos',{...base,emitente:'e'.repeat(101)},'PARAMETROS_INVALIDOS');
});
test('rotas 28-42: envelope das consultas novas exige pagina coerente e cursor que avance',()=>{
    for(const [acao,,p,cursor,entrada] of consultasNovas) {
        const anterior=entrada==='aposRegistro'?'R-10':entrada==='aposDocumento'?'DOC-10':'10';
        for(const r of [{...page([{id:'1'}],true,''),[cursor]:''},{...page([{id:'1'}],true,''),[cursor]:anterior},
            {...page([],true,''),[cursor]:'99'},{...page([{id:'1'}]),total:2},{...page(),dados:{}}]) {
            const h=setup(r);const out=h.run(acao,{...p,[entrada]:anterior});
            assert.equal(out.result.sucesso,false,acao+' '+JSON.stringify(r));assert.equal(h.calls.length,1);
        }
        const h=setup({...page([{id:'1'},{id:'2'}],false,'')});assert.equal(h.run(acao,{...p,limite:1}).result.codigoErro,'RESPOSTA_INVALIDA');
    }
    for(const acao of ['consultarElegiveisBag','consultarHistoricoBag','consultarEmbalagensRecebimento']) {
        const [,,p]=consultasNovas.find(c=>c[0]===acao);
        for(const proximoId of ['9','abc','0']) {
            const h=setup(page([{id:'1'}],true,proximoId));assert.equal(h.run(acao,{...p,aposId:'10'}).result.codigoErro,'CURSOR_INVALIDO',acao+' '+proximoId);
        }
    }
});
test('rotas 28-42: recusa funcional e campos sensiveis nas consultas novas nao viram sucesso',()=>{
    for(const [acao,,p] of consultasNovas) {
        let h=setup({sucesso:false,codigoErro:'RECEBIMENTO_INDISPONIVEL',mensagem:'Bearer segredo'});let r=h.run(acao,p);
        assert.equal(r.result.codigoErro,'RECEBIMENTO_INDISPONIVEL');assert.doesNotMatch(JSON.stringify(r),/segredo/);assert.equal('dados' in r.result,false);
        h=setup({...page([{idEtiqueta:'1',observacao:'interna'}])});r=h.run(acao,p);
        assert.equal(r.result.codigoErro,'RESPOSTA_INVALIDA');assert.doesNotMatch(JSON.stringify(r),/interna/);
    }
});

console.log('DATASET_UNICO|CENARIOS='+total+'|FALHAS=0|FLUIG_REAL=nao');
