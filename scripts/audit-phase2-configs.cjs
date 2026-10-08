'use strict';
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..'),out=path.join(root,'runtime/phase2/pak-audit');
const cfg=JSON.parse(fs.readFileSync(path.join(root,'configs/local.json'),'utf8').replace(/^\uFEFF/,''));
const terms=/OnlineSubsystemMcp|McpConfig|AccountServiceMcp|BaseServiceMcp|OnlineAccessMcp|OnlineDiscoveryMcp|McpProfile|ClientBaseUrl|BaseUrl|Domain|QueryEndpointsUrl|QueryServiceStatusUrl|McpClientCommandUrl|ClientUrlContext/i;
const safeNames=/^(ClientBaseUrl|BaseUrl|Domain|ClientUrl|McpClientCommandUrl|QueryEndpointsUrl|QueryServiceStatusUrl|ClientUrlContext|McpConfig|DefaultPlatformService|NativePlatformService|bUseSSL|bVerifyPeer|bUseHttps|Protocol|Enabled|bEnabled|ServiceName|ConfigName)$/i;
function files(dir){if(!fs.existsSync(dir))return [];return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?files(path.join(dir,e.name)):[path.join(dir,e.name)]);}
function text(file){const b=fs.readFileSync(file);return b[0]===255&&b[1]===254?b.subarray(2).toString('utf16le'):b.toString('utf8').replace(/^\uFEFF/,'');}
function sanitize(value){const v=value.trim();if(v.length>500)return '[complex value omitted]';if(/[A-Fa-f0-9]{32,}|client_secret|password|token|credential/i.test(v))return '[sensitive/identifier value omitted]';if(/https?:\/\//i.test(v)){try{const u=new URL(v.replace(/^"|"$/g,''));if(u.username||u.password)return '[URL contains credentials, omitted]';u.search='';u.hash='';return u.toString();}catch{return '[URL template; value inspected privately]';}}return v;}
const external=files(cfg.buildPath).filter(f=>/\.(ini|json|xml|txt|cfg|manifest)$/i.test(f)||/manifest/i.test(path.basename(f)));
const records=[],sections=[];
for(const [scope,list] of [['external',external],['pak-selected',files(path.join(out,'selected')).filter(f=>/\.ini$/i.test(f))]]){
 for(const file of list){const stat=fs.statSync(file);if(stat.size>4*1024*1024)continue;let section='';const relative=path.relative(scope==='external'?cfg.buildPath:path.join(out,'selected'),file).replace(/\\/g,'/');const lines=text(file).split(/\r?\n/);
  for(let i=0;i<lines.length;i++){const s=lines[i].trim();if(!s||s.startsWith(';')||s.startsWith('#'))continue;if(/^\[.*\]$/.test(s)){section=s.slice(1,-1);if(terms.test(section))sections.push({scope,file:relative,line:i+1,section});continue;}const eq=s.indexOf('=');if(eq<0)continue;const key=s.slice(0,eq).trim(),value=s.slice(eq+1);if(terms.test(section)||terms.test(key)||terms.test(value)){records.push({scope,file:relative,line:i+1,section,key,value:safeNames.test(key)?sanitize(value):'[non-routing value omitted]',runtimeConfigurable:'not established by INI alone'});}}
 }
}
const report={timestamp:new Date().toISOString(),externalDirectories:{engineConfig:fs.existsSync(path.join(cfg.buildPath,'Engine/Config')),gameConfig:fs.existsSync(path.join(cfg.buildPath,'FortniteGame/Config'))},externalReadableFiles:external.map(f=>({file:path.relative(cfg.buildPath,f).replace(/\\/g,'/'),bytes:fs.statSync(f).size})),sections,records};
fs.writeFileSync(path.join(out,'config-findings.json'),JSON.stringify(report,null,2));
console.log(JSON.stringify({externalDirectories:report.externalDirectories,externalFileCount:external.length,externalMatches:records.filter(r=>r.scope==='external').length,routingSections:sections.length,routingRecords:records.length,privateReport:'runtime/phase2/pak-audit/config-findings.json'},null,2));
