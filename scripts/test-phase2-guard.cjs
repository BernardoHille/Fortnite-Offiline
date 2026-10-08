'use strict';
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const guard=require('../backend/offline-guard.cjs');
const events=[];
guard.configure(data=>events.push({timestamp:new Date().toISOString(),pid:process.pid,component:'phase2-guard-negative-test',...data}));
async function main(){
  const error=/external networking and child processes are disabled/;
  guard.run({route:'/synthetic/guard-probe'},()=>{
    assert.throws(()=>require('node:net').connect({host:'example.invalid',port:443}),error);
    assert.throws(()=>require('node:http').get('http://example.invalid/not-a-live-service'),error);
    assert.throws(()=>require('node:dns').lookup('example.invalid',()=>{}),error);
    assert.throws(()=>require('node:dgram').createSocket('udp4'),error);
    assert.throws(()=>require('node:child_process').spawn('unused'),error);
    assert.throws(()=>fetch('https://example.invalid'),error);
  });
  await guard.run({route:'/synthetic/promise-dns-probe'},()=>assert.rejects(require('node:dns').promises.lookup('example.invalid'),error));
  await guard.run({route:'/synthetic/promise-dns-probe'},()=>assert.rejects(require('node:dns').promises.resolve4('example.invalid'),error));
  assert.equal(events.length,8);assert.equal(guard.report().externalAllowed,0);
  assert(events.every(e=>e.route.startsWith('/synthetic/')&&e.result==='blocked-before-access'));
  fs.writeFileSync(path.join(__dirname,'../logs/phase2-guard-test.log'),events.map(e=>JSON.stringify(e)).join('\n')+'\n');
  console.log('[OK] 8 synthetic external/child-process attempts blocked; no Epic hosts or credentials used.');
}
main().catch(()=>{console.error('Guard negative test failed');process.exitCode=1;});
