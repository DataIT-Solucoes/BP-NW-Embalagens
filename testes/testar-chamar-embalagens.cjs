const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const source=fs.readFileSync(path.join(__dirname,'../src/main/webapp/resources/js/chamar-embalagens.js'),'utf8');
async function main(){
 let casos=0;
 function harness(result, options={}){
  const calls=[];
  const sandbox={fetch:async(url,request)=>{calls.push({url,request});return {ok:!options.httpError,status:503,json:async()=>options.transport || {content:[{acao:'consultarTipos',sucesso:String(result.sucesso),resultadoJson:JSON.stringify(result)}]}};}};
  vm.createContext(sandbox);vm.runInContext(source,sandbox);return {sandbox,calls};
 }
 let h=harness({sucesso:true,dados:[],total:0,temMais:false,proximoCodigo:''});
 let r=await h.sandbox.chamarEmbalagens('consultarTipos',{});assert.equal(r.sucesso,true);
 let body=JSON.parse(h.calls[0].request.body);assert.equal(body.datasetId,'dsNwEmbalagens');assert.equal(body.limit,'1');assert.deepEqual(body.filterFields,['acao','consultarTipos','parametros','{}']);casos++;
 h=harness({sucesso:false,codigoErro:'SEM_PERMISSAO',mensagem:'Recusado'});r=await h.sandbox.chamarEmbalagens('consultarTipos',{});assert.equal(r.codigoErro,'SEM_PERMISSAO');casos++;
 h=harness({sucesso:true},{httpError:true});await assert.rejects(h.sandbox.chamarEmbalagens('consultarTipos',{}),/503/);assert.equal(h.calls.length,1);casos++;
 for(const transport of [{content:[]},{content:[{},{}]},{content:[{acao:'consultarTipos',sucesso:'true',resultadoJson:'{'}]},{content:[{acao:'outra',sucesso:'true',resultadoJson:'{"sucesso":true}'}]}]){
  h=harness({sucesso:true},{transport});await assert.rejects(h.sandbox.chamarEmbalagens('consultarTipos',{}));casos++;
 }
 console.log('WIDGET_DATASET_UNICO|CENARIOS='+casos+'|FALHAS=0|FLUIG_REAL=nao');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
