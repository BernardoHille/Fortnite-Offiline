'use strict';
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),cp=require('node:child_process');
const root=path.resolve(__dirname,'..'),out=path.join(root,'runtime/phase2/pak-audit');
const cfg=JSON.parse(fs.readFileSync(path.join(root,'configs/local.json'),'utf8').replace(/^\uFEFF/,''));
const report=JSON.parse(fs.readFileSync(path.join(out,'pak-audit.json'))),before=JSON.parse(fs.readFileSync(path.join(out,'pak-footers.json')));
const keyMap=JSON.parse(fs.readFileSync(path.join(root,'configs/aes-keys.local.json'))).keys;
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const findings=[];
for(const f of before){const file=path.join(cfg.buildPath,'FortniteGame/Content/Paks',f.pak),st=fs.statSync(file),fd=fs.openSync(file,'r');try{const tail=Buffer.alloc(221);fs.readSync(fd,tail,0,221,st.size-221);if(st.size!==f.bytes||st.mtime.toISOString()!==f.lastWriteTime||sha(tail)!==f.footerSha256)throw Error('Original PAK metadata/footer changed: '+f.pak);const encrypted=Buffer.alloc(f.indexSize);fs.readSync(fd,encrypted,0,encrypted.length,f.indexOffset);const label=/^pakchunk10\d\d-/.test(f.pak)?f.pak.split('-')[0]:'MAIN_KEY';function accepted(value){const d=crypto.createDecipheriv('aes-256-ecb',Buffer.from(value.slice(2),'hex'),null);d.setAutoPadding(false);return crypto.createHash('sha1').update(Buffer.concat([d.update(encrypted),d.final()])).digest('hex')===f.indexSha1;}if(!accepted(keyMap[label]))throw Error('Current key file failed index verification: '+label);if(label!=='MAIN_KEY'&&accepted(keyMap.MAIN_KEY))throw Error('Unexpected shared-key result: '+label);}finally{fs.closeSync(fd);}}
findings.push('All 43 original PAK sizes, modification times and footer hashes unchanged; no whole-PAK rehash claimed.');
findings.push('Current keys accepted for all game indices; MAIN_KEY rejected for all 15 dynamic chunk indices.');
if(report.paks.length!==43||!report.paks.every(p=>p.repakVerified&&p.keyResult==='accepted-index-SHA1'))throw Error('PAK index audit incomplete');
for(const p of report.paks)for(const e of p.extracted){if(!e.sha1Verified||sha(fs.readFileSync(path.join(out,'selected',p.pak,e.path)))!==e.sha256)throw Error('Selected config integrity failed');}
findings.push('43 independent repak lists and 20 selected entry hashes verified.');
const original=JSON.parse(fs.readFileSync(path.join(out,'shipping-original-integrity.json'))),shipping=path.join(cfg.buildPath,'FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping.exe');
if(!original.matchesOriginalArchiveEntry||sha(fs.readFileSync(shipping))!==original.sha256)throw Error('Shipping original integrity failed');
findings.push('Shipping hash matches original ZIP entry and remains unchanged.');
const crash=JSON.parse(fs.readFileSync(path.join(out,'crash-pak-audit.json')));
if(!crash.unchangedAfter||sha(fs.readFileSync(path.join(cfg.buildPath,crash.pak)))!==crash.sha256Before||sha(fs.readFileSync(path.join(out,'selected/CrashReportClient.pak',crash.selectedFile)))!==crash.selectedSha256)throw Error('CrashReportClient PAK/config changed');
findings.push('CrashReportClient unencrypted PAK and selected config hashes verified.');
const keys=Object.values(JSON.parse(fs.readFileSync(path.join(root,'configs/aes-keys.local.json'))).keys);
if(keys.length!==16||keys.some(k=>!/^0x[\da-f]{64}$/i.test(k)))throw Error('Invalid AES key format');
const git=cp.spawnSync('git',['ls-files','--cached','--others','--exclude-standard','-z'],{cwd:root,encoding:'utf8',windowsHide:true});if(git.status!==0)throw Error('Git inventory failed');
for(const file of git.stdout.split('\0').filter(Boolean)){if(/^runtime\/|^configs\/aes-keys\.local\.json$/.test(file))throw Error('Private audit data visible to Git: '+file);const full=path.join(root,file);if(!fs.statSync(full).isFile())continue;const data=fs.readFileSync(full);if(data.length>8*1024*1024)continue;const s=data.toString('utf8').toUpperCase();if(keys.some(k=>s.includes(k.slice(2).toUpperCase())))throw Error('AES key value in public file: '+file);}
for(const file of ['configs/aes-keys.local.json','runtime/phase2/pak-audit/pak-audit.json','runtime/phase2/pak-audit/selected/pakchunk0-WindowsClient.pak/FortniteGame/Config/DefaultEngine.ini']){if(cp.spawnSync('git',['check-ignore','-q',file],{cwd:root,windowsHide:true}).status!==0)throw Error('Required private file is not ignored: '+file);}
findings.push('16 AES entries stay private; public text scan found no key value; extracted content and temporary audit data ignored.');
const final={timestamp:new Date().toISOString(),checksPassed:true,scope:'Local file/index/hash/Git checks only; no client runtime claim',findings,clientExecuted:false,gameServerExecuted:false};
fs.writeFileSync(path.join(out,'verification.json'),JSON.stringify(final,null,2));findings.forEach(s=>console.log('[OK] '+s));
