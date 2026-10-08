'use strict';
// Read-only AES/index adapter. The independent repak list parser validates compact
// index-only copies. Original PAKs are opened only with 'r'. No game code is loaded.
// Layout reference: trumank/repak (MIT OR Apache-2.0), pinned in local tool provenance.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),zlib=require('node:zlib'),cp=require('node:child_process');
const root=path.resolve(__dirname,'..'),out=path.join(root,'runtime/phase2/pak-audit');
const config=JSON.parse(fs.readFileSync(path.join(root,'configs/local.json'),'utf8').replace(/^\uFEFF/,''));
const keys=JSON.parse(fs.readFileSync(path.join(root,'configs/aes-keys.local.json'),'utf8')).keys;
const footers=JSON.parse(fs.readFileSync(path.join(out,'pak-footers.json'),'utf8'));
const repak=path.join(out,'tools/repak-cli/repak.exe');
const wanted=new Set(['Engine/Config/BaseEngine.ini','Engine/Config/Windows/WindowsEngine.ini',
 'FortniteGame/Config/DefaultEngine.ini','FortniteGame/Config/DefaultGame.ini','FortniteGame/Config/DefaultRuntimeOptions.ini',
 'FortniteGame/Config/Windows/WindowsEngine.ini','FortniteGame/Config/WindowsClient/WindowsClientEngine.ini',
 'FortniteGame/Config/WindowsClient/WindowsClientRuntimeOptions.ini',
 'FortniteGame/Plugins/Runtime/FortniteEarlyStartupPatcher/Config/DefaultFortniteEarlyStartupPatcher.ini',
 'FortniteGame/Plugins/Runtime/FortniteEarlyStartupPatcher/Config/Game.ini']);
for(const dir of ['indexes','listings','selected'])fs.mkdirSync(path.join(out,dir),{recursive:true});
const sha1=b=>crypto.createHash('sha1').update(b).digest('hex');
const sha256=b=>crypto.createHash('sha256').update(b).digest('hex');
const align=n=>Math.ceil(n/16)*16;
class Cursor{
 constructor(b,o=0){this.b=b;this.o=o;}
 bytes(n){if(!Number.isSafeInteger(n)||n<0||this.o+n>this.b.length)throw Error('Bounded index read failed');const v=this.b.subarray(this.o,this.o+n);this.o+=n;return v;}
 u32(){return this.bytes(4).readUInt32LE();} i32(){return this.bytes(4).readInt32LE();}
 u64(){const n=Number(this.bytes(8).readBigUInt64LE());if(!Number.isSafeInteger(n))throw Error('Invalid offset');return n;}
 str(){const n=this.i32();if(Math.abs(n)>100000)throw Error('Invalid FString');return this.bytes(Math.abs(n)*(n<0?2:1)).toString(n<0?'utf16le':'utf8').replace(/\0$/,'');}
}
function decrypt(b,key){if(b.length%16)throw Error('Unaligned AES data');const d=crypto.createDecipheriv('aes-256-ecb',key,null);d.setAutoPadding(false);return Buffer.concat([d.update(b),d.final()]);}
function fullEntry(c){const offset=c.u64(),compressed=c.u64(),uncompressed=c.u64(),method=c.u32(),hash=c.bytes(20).toString('hex');const blocks=[];if(method){const n=c.u32();if(n>8192)throw Error('Too many blocks');for(let i=0;i<n;i++)blocks.push({start:c.u64(),end:c.u64()});}const flags=c.bytes(1)[0],blockSize=c.u32();return {offset,compressed,uncompressed,method,hash,blocks,flags,blockSize,headerSize:53+(method?4+16*blocks.length:0)};}
function encodedEntry(c){const bits=c.u32(),method=(bits>>>23)&63,encrypted=!!(bits&(1<<22)),count=(bits>>>6)&65535;let blockSize=bits&63;blockSize=blockSize===63?c.u32():blockSize*2048;const v=bit=>(bits&(1<<bit))?c.u32():c.u64();const offset=v(31),uncompressed=v(30),compressed=method?v(29):uncompressed;const headerSize=53+(method?4+16*count:0);const blocks=[];let at=headerSize;for(let i=0;i<count;i++){const size=count===1&&!encrypted?compressed:c.u32();blocks.push({start:at,end:at+size});at+=encrypted?align(size):size;}return {offset,uncompressed,compressed,method,flags:encrypted?1:0,blocks,blockSize,headerSize};}
let totalExtracted=0;const reports=[];
for(const f of footers){const file=path.join(config.buildPath,'FortniteGame/Content/Paks',f.pak),fd=fs.openSync(file,'r');const record={pak:f.pak,version:f.version,indexEncrypted:f.indexEncrypted,keyLabel:/^pakchunk10\d\d-/.test(f.pak)?f.pak.split('-')[0]:'MAIN_KEY',indexSize:f.indexSize,extracted:[]};
 const read=(offset,size)=>{if(!Number.isSafeInteger(offset)||!Number.isSafeInteger(size)||offset<0||size<0||size>16*1024*1024||offset+size>f.bytes)throw Error('Read outside bounded PAK range');const b=Buffer.alloc(size);if(fs.readSync(fd,b,0,size,offset)!==size)throw Error('Short read');return b;};
 try{
  if(f.version!==11)throw Error('Unsupported version; no speculative parsing');
  const value=keys[record.keyLabel];if(!/^0x[\da-f]{64}$/i.test(value))throw Error('Unconfirmed key transcription');
  const key=Buffer.from(value.slice(2),'hex');const main=f.indexEncrypted?decrypt(read(f.indexOffset,f.indexSize),key):read(f.indexOffset,f.indexSize);
  if(sha1(main)!==f.indexSha1)throw Error('Key rejected by index SHA-1');
  record.keyResult='accepted-index-SHA1';const c=new Cursor(main),mount=c.str(),count=c.u32();c.u64();const aux=[];
  for(const type of ['path-hash','full-directory']){if(c.u32()){const pointer=c.o,offset=c.u64(),size=c.u64(),hash=c.bytes(20).toString('hex');const data=f.indexEncrypted?decrypt(read(offset,size),key):read(offset,size);if(sha1(data)!==hash)throw Error('Auxiliary index SHA-1 mismatch');aux.push({type,pointer,data});}}
  const encoded=c.bytes(c.u32()),nonCount=c.u32(),non=[];if(nonCount>count)throw Error('Non-encoded entry count invalid');for(let i=0;i<nonCount;i++)non.push(fullEntry(c));
  const dirs=aux.find(a=>a.type==='full-directory');if(!dirs)throw Error('Full directory index unavailable');const dc=new Cursor(dirs.data),dirCount=dc.u32(),entries=[];if(dirCount>1000000)throw Error('Too many directories');
  for(let i=0;i<dirCount;i++){const dir=dc.str(),n=dc.u32();if(n>1000000)throw Error('Too many files');for(let j=0;j<n;j++){const name=dir.replace(/^\//,'')+dc.str(),pos=dc.i32();if(pos===-2147483648)continue;const entry=pos>=0?encodedEntry(new Cursor(encoded,pos)):non[-pos-1];if(!entry)throw Error('Missing entry');entries.push({name,...entry});}}
  if(entries.length!==count)throw Error('Directory entry count mismatch');
  const rewritten=Buffer.from(main);let offset=rewritten.length;for(const a of aux){rewritten.writeBigUInt64LE(BigInt(offset),a.pointer);offset+=a.data.length;}
  const footer=read(f.bytes-221,221);if(footer.readUInt32LE(17)!==0x5a6f12e1||footer.readUInt32LE(21)!==11)throw Error('Unexpected footer size');footer[16]=0;footer.writeBigUInt64LE(0n,25);Buffer.from(sha1(rewritten),'hex').copy(footer,41);
  const compact=path.join(out,'indexes',f.pak+'.index-only.bin');fs.writeFileSync(compact,Buffer.concat([rewritten,...aux.map(a=>a.data),footer]));
  const check=cp.spawnSync(repak,['list',compact],{encoding:'utf8',windowsHide:true,maxBuffer:32*1024*1024});
  if(check.status!==0)throw Error('Independent repak list validation failed');
  const prefix=mount.replace(/^(?:\.\.\/){3}/,'');const expected=entries.map(e=>(prefix+e.name).replace(/\\/g,'/')).sort(),actual=check.stdout.trim().split(/\r?\n/).filter(Boolean).sort();
  if(JSON.stringify(actual)!==JSON.stringify(expected))throw Error('Independent repak file list mismatch');
  fs.writeFileSync(path.join(out,'listings',f.pak+'.txt'),check.stdout);
  record.entries=entries.length;record.mountPoint=mount;record.repakVerified=true;record.indexBytesRead=main.length+aux.reduce((s,a)=>s+a.data.length,0);
  record.encryptedDataEntries=entries.filter(e=>e.flags&1).length;
  const selected=entries.filter(e=>/\.(ini|json|xml|cfg|txt|manifest)$/i.test(e.name)&&(/(^|\/)Config\//i.test(e.name)||/(DefaultEngine|DefaultGame|RuntimeOptions|GameUserSettings|OnlineSubsystem|Mcp)/i.test(e.name)));
  record.configCandidates=selected.map(e=>({path:prefix+e.name,bytes:e.uncompressed,encrypted:!!(e.flags&1),method:e.method}));
  for(const e of selected.filter(e=>wanted.has(prefix+e.name))){if(e.uncompressed>2*1024*1024||totalExtracted+e.uncompressed>2*1024*1024)throw Error('Selective extraction budget exceeded');if(e.flags&2)continue;
   const header=fullEntry(new Cursor(read(e.offset,e.headerSize)));
   if(header.compressed!==e.compressed||header.uncompressed!==e.uncompressed||header.method!==e.method||header.flags!==e.flags)throw Error('Entry header does not match index');
   const data=[];let hashMode=null;
   if(e.method===0){const raw=read(e.offset+header.headerSize,e.flags&1?align(e.compressed):e.compressed);const decoded=e.flags&1?decrypt(raw,key):raw;data.push(decoded.subarray(0,e.uncompressed));hashMode=[['plaintext',decoded.subarray(0,e.uncompressed)],['stored-bytes',raw],['plaintext-padded',decoded],['stored-unpadded',raw.subarray(0,e.compressed)]].find(([,b])=>sha1(b)===header.hash)?.[0];}
   else{const names=f.compression,stored=[],padded=[];if(!['Zlib','Gzip'].includes(names[e.method-1]))throw Error('Unsupported compression; no proprietary DLL will be loaded');for(const block of header.blocks){const raw=read(e.offset+block.start,e.flags&1?align(block.end-block.start):block.end-block.start);stored.push(raw.subarray(0,block.end-block.start));padded.push(raw);const payload=(e.flags&1?decrypt(raw,key):raw).subarray(0,block.end-block.start);data.push(names[e.method-1]==='Zlib'?zlib.inflateSync(payload,{maxOutputLength:2*1024*1024}):zlib.gunzipSync(payload,{maxOutputLength:2*1024*1024}));}hashMode=[['stored-compressed-unpadded',Buffer.concat(stored)],['stored-compressed-padded',Buffer.concat(padded)]].find(([,b])=>sha1(b)===header.hash)?.[0];}
   const payload=Buffer.concat(data);if(payload.length!==e.uncompressed)throw Error('Extracted length mismatch');
   // Record which bounded representation matches the FPakEntry hash. This build's
   // selected encrypted INIs match stored ciphertext excluding AES padding.
   if(!hashMode)throw Error('Selected entry SHA-1 mismatch: '+e.name);
   const relative=(prefix+e.name).replace(/\\/g,'/');if(relative.split('/').some(x=>x==='..')||path.isAbsolute(relative)||relative.includes(':'))throw Error('Unsafe selected path');
   const dest=path.join(out,'selected',f.pak,relative);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.writeFileSync(dest,payload);totalExtracted+=payload.length;
   record.extracted.push({path:relative,bytes:payload.length,sha256:sha256(payload),sha1Verified:true,hashMode,encrypted:!!(e.flags&1)});
  }
  record.result='read-only audit passed';
 }catch(err){record.result=err.message;record.keyResult??='unconfirmed/rejected';}
 finally{fs.closeSync(fd);reports.push(record);console.log(f.pak+' -> '+record.keyResult+'; '+record.result+'; configs '+record.extracted.length);}
}
fs.writeFileSync(path.join(out,'pak-audit.json'),JSON.stringify({timestamp:new Date().toISOString(),component:'read-only-pak-audit',originalFilesOpenedReadOnly:true,clientExecuted:false,totalExtractedBytes:totalExtracted,paks:reports},null,2));
