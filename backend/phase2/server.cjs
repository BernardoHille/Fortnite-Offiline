'use strict';
// Selective adapter of LawinServer schemas, not a general upstream route loader.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const { AsyncLocalStorage }=require('node:async_hooks');
const root=path.resolve(__dirname,'../..');
const guard=require('../offline-guard.cjs');
const express=require('../vendor/LawinServer/node_modules/express');
const {loadProfiles,envelope}=require('./profiles.cjs');
const file=process.env.FORTNITE_LOCAL_CONFIG || path.join(root,'configs/local.json');
const config=JSON.parse(fs.readFileSync(file,'utf8').replace(/^\uFEFF/,''));
if(config.environment!=='local'||config.phase!==2||config.backendHost!=='127.0.0.1'||config.gameServerHost!=='127.0.0.1'||config.accountId!=='local-player') throw new Error('Only local Phase 2 with local-player and loopback hosts is allowed');
if(!Number.isInteger(config.backendPort)||config.backendPort<1024||config.backendPort>65535||typeof config.displayName!=='string'||!/^[\p{L}\p{N} _-]{1,24}$/u.test(config.displayName)) throw new Error('Invalid local port/displayName');
if(!process.env.FORTNITE_LOCAL_CONTROL_KEY) throw new Error('Start through the local coordinator');
const logFile=path.join(root,'logs/phase2-backend.log');
const log=(data)=>fs.appendFileSync(logFile,JSON.stringify({timestamp:new Date().toISOString(),pid:process.pid,component:'phase2-backend',...data})+'\n');
guard.configure(log);
const profiles=loadProfiles(config,path.join(root,'runtime/phase2'));
const tokens=new Map();
const sessionId=crypto.randomUUID();
const app=express();
app.disable('x-powered-by'); app.set('query parser',false); app.set('etag',false);
let server;
const safeRoute=value=>{
  // Exclude query values and arbitrary unknown path content from logs.
  const route=String(value).split('?')[0];
  if(route.startsWith('/fortnite/api/game/v2/profile/')) return '/fortnite/api/game/v2/profile/:accountId/client/'+(route.endsWith('/QueryProfile')?'QueryProfile':'[unimplemented]');
  const known=['/health','/__local/shutdown','/local/phase2/config','/local/phase2/presence','/local/phase2/lobby-bootstrap','/local/phase2/network-report',
    '/account/api/oauth/token','/account/api/oauth/verify','/fortnite/api/version','/fortnite/api/v2/versioncheck','/lightswitch/api/service/bulk/status',
    '/fortnite/api/calendar/v1/timeline','/fortnite/api/cloudstorage/system'];
  if(known.includes(route)) return route;
  if(route.startsWith('/account/api/public/account')) return '/account/api/public/account/:accountId';
  return '[unimplemented path redacted]';
};
app.use((req,res,next)=>{
  const route=safeRoute(req.url);
  const host=req.headers.host || '';
  const expected='127.0.0.1:'+config.backendPort;
  guard.run({route},()=>{
    res.on('finish',()=>log({kind:'request',method:req.method,host:host===expected?'127.0.0.1':'[rejected host]',route,
      status:res.statusCode,payloadType:res.getHeader('content-type')||'none',requestPayloadType:['application/json','application/x-www-form-urlencoded'].includes(req.headers['content-type']?.split(';')[0])?req.headers['content-type'].split(';')[0]:'other-or-none',
      result:res.statusCode<400?'local-response':'controlled-error',errorCode:res.locals.localError}));
    if(host!==expected) return res.status(421).json({error:'local.invalid_host'});
    if(!['127.0.0.1','::ffff:127.0.0.1'].includes(req.socket.remoteAddress)) return res.status(403).json({error:'local.non_loopback'});
    next();
  });
});
const error=(res,status,code)=>{res.locals.localError='errors.local.'+code;return res.status(status).json({errorCode:res.locals.localError,numericErrorCode:status,originatingService:'local-phase2',intent:'local'});};
const auth=(req,res,next)=>{
  const match=/^Bearer (local-[a-f0-9]{64})$/.exec(req.headers.authorization||'');
  const token=match&&tokens.get(match[1]);
  if(!token||token.until<Date.now()) return error(res,401,'invalid_local_session');
  req.localSession=token; next();
};
const identity=(req,res,next)=>req.params.accountId===config.accountId?next():error(res,404,'unknown_local_account');
const query=req=>new URL(req.url,'http://127.0.0.1').searchParams;
const account=()=>({id:config.accountId,displayName:config.displayName,externalAuths:{},preferredLanguage:'pt-BR',headless:false});
const timeline=()=>({channels:{'client-matchmaking':{states:[],cacheExpire:'9999-01-01T00:00:00Z'},'client-events':{
  states:[{validFrom:'2020-06-17T00:00:00Z',activeEvents:[{eventType:'EventFlag.Season13',activeSince:'2020-06-17T00:00:00Z',activeUntil:'9999-01-01T00:00:00Z'},
    {eventType:'EventFlag.LobbySeason13',activeSince:'2020-06-17T00:00:00Z',activeUntil:'9999-01-01T00:00:00Z'}],
    state:{seasonNumber:13,seasonTemplateId:'AthenaSeason:athenaseason13',seasonBegin:'2020-06-17T00:00:00Z',seasonEnd:'9999-01-01T00:00:00Z',
      seasonDisplayedEnd:'9999-01-01T00:00:00Z',activeStorefronts:[],eventNamedWeights:{},matchXpBonusPoints:0}}],cacheExpire:'9999-01-01T00:00:00Z'}},
  eventsTimeOffsetHrs:0,cacheIntervalMins:10,currentTime:new Date().toISOString()});
app.get('/health',(req,res)=>res.json({status:'ok',backend:'LawinServer-minimal-adapter',phase:2,environment:'local',accountId:config.accountId,
  clientStarted:false,xmppEnabled:false,matchmakingEnabled:false,realCredentialsUsed:false}));
app.post('/__local/shutdown',(req,res)=>{
  if(req.headers['x-local-control']!==process.env.FORTNITE_LOCAL_CONTROL_KEY) return error(res,403,'invalid_local_control');
  res.json({status:'stopping'}); server.close(()=>process.exit(0));
});
// Every incoming body is bounded; no qs/extended form parsing and no body/header logging.
app.post('/account/api/oauth/token',express.text({type:()=>true,limit:'4kb'}),(req,res)=>{
  if(req.headers.authorization) return error(res,400,'official_credentials_not_accepted');
  if(!String(req.headers['content-type']||'').startsWith('application/x-www-form-urlencoded')) return error(res,415,'form_required');
  const form=new URLSearchParams(req.body);
  if([...form.keys()].some(key=>!['grant_type','username','password'].includes(key))||form.getAll('grant_type').length!==1||form.getAll('username').length!==1||form.getAll('password').length!==1||
     form.get('grant_type')!=='password'||form.get('username')!==config.accountId||form.get('password')!=='local-only-not-epic') return error(res,400,'only_synthetic_local_credentials_supported');
  // Only this fictional local pair is accepted; no Epic passwords or exchange codes.
  const accessToken='local-'+crypto.randomBytes(32).toString('hex');
  const until=Date.now()+3600000; tokens.set(accessToken,{until,accountId:config.accountId});
  res.set('cache-control','no-store').json({access_token:accessToken,token_type:'bearer',expires_in:3600,expires_at:new Date(until).toISOString(),
    account_id:config.accountId,displayName:config.displayName,client_id:'local-coordinator',client_service:'fortnite-local',internal_client:true,app:'fortnite-local',in_app_id:config.accountId});
});
app.get('/account/api/oauth/verify',auth,(req,res)=>res.json({account_id:config.accountId,display_name:config.displayName,session_id:sessionId,token_type:'bearer',
  expires_at:new Date(req.localSession.until).toISOString(),expires_in:Math.max(0,Math.floor((req.localSession.until-Date.now())/1000)),auth_method:'local_synthetic_password',app:'fortnite-local'}));
app.get('/account/api/public/account/:accountId',auth,identity,(req,res)=>res.json(account()));
app.get('/account/api/public/account',auth,(req,res)=>{
  if(query(req).getAll('accountId').length!==1||query(req).get('accountId')!==config.accountId) return error(res,404,'unknown_local_account');
  res.json([account()]);
});
app.post('/fortnite/api/game/v2/profile/:accountId/client/QueryProfile',auth,identity,express.json({limit:'4kb'}),(req,res)=>{
  const params=query(req); const id=params.get('profileId'); const profile=profiles[id];
  if(!Object.hasOwn(profiles,id)||!profile) return error(res,404,'unsupported_local_profile');
  if(Object.keys(req.body||{}).length) return error(res,400,'query_profile_body_must_be_empty');
  const revision=params.get('rvn');
  if(revision!==null&&!/^-?\d{1,9}$/.test(revision)) return error(res,400,'invalid_revision');
  res.json(envelope(profile,revision===null?-1:Number(revision)));
});
app.get('/fortnite/api/version',(req,res)=>res.json({app:'fortnite',version:'13.40',branch:'Release-13.40',cln:'14113327',serverDate:new Date().toISOString(),modules:{}}));
app.get('/fortnite/api/v2/versioncheck',(req,res)=>res.json({type:'NO_UPDATE'}));
app.get('/lightswitch/api/service/bulk/status',(req,res)=>res.json([{serviceInstanceId:'fortnite',status:'UP',message:'Local infrastructure only',maintenanceUri:null,
  allowedActions:['PLAY'],banned:false,launcherInfoDTO:{appName:'Fortnite',namespace:'fn'}}]));
app.get('/fortnite/api/calendar/v1/timeline',auth,(req,res)=>res.json(timeline()));
app.get('/fortnite/api/cloudstorage/system',auth,(req,res)=>res.json([]));
app.get('/local/phase2/config',auth,(req,res)=>res.json({environment:'local',phase:2,season:13,build:'13.40',changelist:14113327,
  backendHost:'127.0.0.1',externalServices:false,shopEnabled:false,xmppEnabled:false,matchmakingEnabled:false}));
app.get('/local/phase2/presence',auth,(req,res)=>res.json({accountId:config.accountId,displayName:config.displayName,status:'local-only',friends:[]}));
app.get('/local/phase2/network-report',auth,(req,res)=>res.json({guard:guard.report(),scope:'audited-node-process-only',clientCoverage:false}));
app.get('/local/phase2/lobby-bootstrap',auth,(req,res)=>res.json({account:account(),profiles:Object.values(profiles).map(p=>envelope(p,-1)),timeline:timeline(),
  presence:{accountId:config.accountId,status:'local-only'},localSimulationReady:true,realClientLobbyVerified:false,playButtonVerified:false,matchmakingEnabled:false}));
app.use((req,res)=>error(res,503,'phase2_route_not_implemented'));
app.use((err,req,res,next)=>{log({kind:'handler-error',host:'127.0.0.1',route:safeRoute(req.url),result:'controlled-error',errorType:err.type||err.name});
  error(res,err.status===413?413:400,'invalid_request');});
server=app.listen(config.backendPort,'127.0.0.1',()=>log({kind:'lifecycle',host:'127.0.0.1',route:'(startup)',result:'listening',port:config.backendPort}));
server.on('error',()=>{log({kind:'lifecycle',host:'127.0.0.1',route:'(startup)',result:'listen-error'});process.exit(1);});
for(const signal of ['SIGINT','SIGTERM']) process.on(signal,()=>server.close(()=>process.exit(0)));
