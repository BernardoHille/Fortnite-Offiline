'use strict';
// Process-local guard; this is not a complete operating-system sandbox.
const net = require('node:net');
const dgram = require('node:dgram');
const dns = require('node:dns');
const child = require('node:child_process');
const { AsyncLocalStorage } = require('node:async_hooks');
const context = new AsyncLocalStorage();
let logger = () => {};
const stats = { attempted:0, externalAllowed:0, blocked:0 };
const cleanHost = value => /^[a-zA-Z0-9.:[\]-]{1,200}$/.test(String(value))?String(value):'[invalid host redacted]';
function blocked(host='unavailable', api='restricted') {
  stats.attempted++; stats.blocked++;
  logger({kind:'network-guard', host:cleanHost(host), route:context.getStore()?.route || '(no request)', api, result:'blocked-before-access'});
  throw new Error('Local phases: external networking and child processes are disabled');
}
const connect = net.Socket.prototype.connect;
net.Socket.prototype.connect = function (...args) {
  const first = args[0];
  const options = Array.isArray(first) ? first[0] : first;
  const host = typeof options === 'object' ? options.host : (typeof args[1] === 'string' ? args[1] : 'localhost');
  if (options && typeof options === 'object' && options.path) return blocked('local-pipe', 'net.Socket.connect');
  if (!['127.0.0.1', '::1', 'localhost'].includes(host || 'localhost')) return blocked(host, 'net.Socket.connect');
  return connect.apply(this, args);
};
dgram.createSocket = () => blocked('udp', 'dgram.createSocket');
for (const name of ['resolve','resolve4','resolve6','resolveAny','reverse','resolveCname','resolveMx','resolveNs','resolveTxt','resolveSrv','resolveNaptr','resolvePtr','resolveSoa']) {
  dns[name] = host => blocked(host, 'dns.' + name);
  if (dns.promises[name]) dns.promises[name] = async host => blocked(host, 'dns.promises.' + name);
}
const lookup = dns.lookup;
dns.lookup = function (host, ...args) { if (!['127.0.0.1','::1','localhost'].includes(host)) return blocked(host,'dns.lookup'); return lookup.call(this, host, ...args); };
const promiseLookup = dns.promises.lookup;
dns.promises.lookup = async function(host,...args){ if(!['127.0.0.1','::1','localhost'].includes(host)) return blocked(host,'dns.promises.lookup'); return promiseLookup.call(this,host,...args); };
for (const name of ['exec','execFile','spawn','fork','execSync','execFileSync','spawnSync']) child[name] = () => blocked('child-process', 'child_process.' + name);
global.fetch = input => { let host='unavailable'; try{host=new URL(typeof input==='string'?input:input.url).hostname}catch{} return blocked(host,'fetch'); };
module.exports = {configure(fn){logger=fn;}, run(value,fn){return context.run(value,fn);}, report(){return {...stats};}};
