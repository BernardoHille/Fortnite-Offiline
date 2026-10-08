'use strict';
// Metadata only; never opens a game file for writing or loads game code.
const fs=require('node:fs'), path=require('node:path'), crypto=require('node:crypto');
const root=path.resolve(__dirname,'..');
const config=JSON.parse(fs.readFileSync(path.join(root,'configs/local.json'),'utf8').replace(/^\uFEFF/,''));
const paks=path.join(config.buildPath,'FortniteGame/Content/Paks');
const report=[];
for(const name of fs.readdirSync(paks).filter(n=>n.endsWith('.pak'))){
 const file=path.join(paks,name), stat=fs.statSync(file), fd=fs.openSync(file,'r');
 try{
  const tail=Buffer.alloc(Math.min(stat.size,4096)); fs.readSync(fd,tail,0,tail.length,stat.size-tail.length);
  let i=tail.lastIndexOf(Buffer.from([0xe1,0x12,0x6f,0x5a]));
  if(i<17)throw new Error('Unsupported or missing footer');
  const version=tail.readUInt32LE(i+4), indexOffset=Number(tail.readBigUInt64LE(i+8)), indexSize=Number(tail.readBigUInt64LE(i+16));
  const compressionStart=i+44+(version===9?1:0), names=[];
  for(let n=compressionStart;n+32<=tail.length;n+=32){const s=tail.subarray(n,n+32).toString('ascii').split('\0')[0];if(s)names.push(s);}
  const guidBytes=tail.subarray(i-17,i-1);
  const guidUE=[0,4,8,12].map(n=>guidBytes.readUInt32LE(n).toString(16).padStart(8,'0')).join('').toUpperCase();
  report.push({pak:name,bytes:stat.size,lastWriteTime:stat.mtime.toISOString(),version,indexEncrypted:!!tail[i-1],encryptionGuid:guidUE,indexOffset,indexSize,indexSha1:tail.subarray(i+24,i+44).toString('hex'),footerSha256:crypto.createHash('sha256').update(tail.subarray(i-17)).digest('hex'),compression:names,frozen:version===9?!!tail[i+44]:false});
 }finally{fs.closeSync(fd);}
}
fs.mkdirSync(path.join(root,'runtime/phase2/pak-audit'),{recursive:true});
fs.writeFileSync(path.join(root,'runtime/phase2/pak-audit/pak-footers.json'),JSON.stringify(report,null,2));
console.log(JSON.stringify(report.map(({pak,version,indexEncrypted,indexSize,compression,frozen})=>({pak,version,indexEncrypted,indexSize,compression,frozen})),null,2));
