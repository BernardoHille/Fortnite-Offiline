'use strict';
// Bounded, read-only PML v9 metadata inspection. Decode filesystem path/length
// metadata only for Shipping; no captured file contents, command lines,
// usernames, modules, registry values, stacks, symbols or DNS lookups.
// Layout reference: eronnen/procmon-parser d32f1ddd109054cab4be6f727ba9944a7992bd73
// (MIT; accompanying procmon-parser-LICENSE-MIT.txt). No upstream code executed.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const includePaths = process.argv.includes('--paths');
const root = path.resolve(__dirname, '..', 'runtime', 'phase2', 'runtime-observation');
const input = path.resolve(process.argv.slice(2).find(arg => arg !== '--paths') || path.join(root, 'user-capture.original.pml'));
if (!input.toLowerCase().startsWith((root + path.sep).toLowerCase())) throw new Error('PML must be inside the private observation directory.');
const fd = fs.openSync(input, 'r');
try {
  const size = fs.fstatSync(fd).size;
  if (size < 0x3a8 || size > 64 * 1024 * 1024) throw new Error('Capture outside the bounded metadata reader limit.');
  const b = Buffer.alloc(size);
  let filled = 0;
  while (filled < size) { const n = fs.readSync(fd, b, filled, size - filled, filled); if (!n) throw new Error('Truncated PML.'); filled += n; }
  const check = (offset, length) => { if (!Number.isSafeInteger(offset) || !Number.isSafeInteger(length) || offset < 0 || length < 0 || offset + length > size) throw new Error('PML field outside file bounds.'); };
  const u16 = offset => { check(offset, 2); return b.readUInt16LE(offset); };
  const u32 = offset => { check(offset, 4); return b.readUInt32LE(offset); };
  const u64 = offset => { check(offset, 8); return b.readBigUInt64LE(offset); };
  const pointer = offset => { const n = u64(offset); if (n > BigInt(size) || n === 0n) throw new Error('Invalid/unfinished PML table pointer.'); return Number(n); };
  if (b.subarray(0, 4).toString('ascii') !== 'PML_' || u32(4) !== 9) throw new Error('Only PML v9 is supported.');
  if (Number(u64(0x398)) !== 0x3a8) throw new Error('Unexpected PML header layout.');
  const eventCount = u32(0x234), eventBase = pointer(0x240), eventOffsets = pointer(0x248);
  const processTable = pointer(0x250), stringsTable = pointer(0x258);
  pointer(0x260); pointer(0x3a0); // Require a finalized icon/host-port table, without decoding it.
  if (eventCount > 500000) throw new Error('Event count exceeds bound.');
  check(eventOffsets, eventCount * 5);
  const stringCount = u32(stringsTable);
  if (stringCount > 1000000) throw new Error('String count exceeds bound.');
  check(stringsTable + 4, stringCount * 4);
  function processNameAt(index) {
    if (index >= stringCount) throw new Error('Invalid process-name string index.');
    const offset = stringsTable + u32(stringsTable + 4 + index * 4);
    const length = u32(offset);
    if (length > 65536 || length % 2) throw new Error('Invalid process-name string length.');
    check(offset + 4, length);
    return b.subarray(offset + 4, offset + 4 + length).toString('utf16le').split('\0')[0];
  }
  const processCount = u32(processTable);
  if (processCount > 100000) throw new Error('Process table exceeds bound.');
  check(processTable + 4, processCount * 8);
  const indexes = new Map(), targets = [];
  for (let i = 0; i < processCount; i++) {
    const record = processTable + u32(processTable + 4 + processCount * 4 + i * 4);
    check(record, 0x48);
    const index = u32(record), pid = u32(record + 4);
    if (indexes.has(index) || index !== u32(processTable + 4 + i * 4)) throw new Error('Inconsistent process table indexes.');
    const target = processNameAt(u32(record + 0x40)).toLowerCase() === 'fortniteclient-win64-shipping.exe';
    indexes.set(index, target);
    if (target) targets.push({index, pid, imagePath: processNameAt(u32(record + 0x44))});
  }
  let matching = 0, minimumTime = null, maximumTime = null;
  const classes = {}, operations = {}, fileEvents = [];
  const pointerBytes = u32(8) === 1 ? 8 : 4;
  const filetimeUtc = value => new Date(Number((value - 116444736000000000n) / 10000n)).toISOString();
  for (let i = 0; i < eventCount; i++) {
    const offset = u32(eventOffsets + i * 5);
    check(offset, 52);
    if (offset < eventBase || offset >= eventOffsets) throw new Error('Event offset outside event region.');
    const index = u32(offset);
    if (!indexes.has(index)) throw new Error('Event references unknown process.');
    const timestamp = u64(offset + 28);
    if (minimumTime === null || timestamp < minimumTime) minimumTime = timestamp;
    if (maximumTime === null || timestamp > maximumTime) maximumTime = timestamp;
    if (!indexes.get(index)) continue; // Never decode other processes' paths/details.
    matching++;
    const eventClass = u32(offset + 8), operation = u16(offset + 12);
    classes[eventClass] = (classes[eventClass] || 0) + 1;
    const key = `${eventClass}:${operation}`;
    operations[key] = (operations[key] || 0) + 1;
    if (includePaths && eventClass === 3) {
      const stackBytes = u16(offset + 40) * pointerBytes;
      const detailSize = u32(offset + 44), detailStart = offset + 52 + stackBytes;
      check(detailStart, detailSize);
      const prefix = 4 + pointerBytes * 5 + 0x14;
      if (detailSize < prefix + 4) throw new Error('Truncated filesystem metadata.');
      const flags = u16(detailStart + prefix), characters = flags & 0x7fff;
      const pathBytes = characters * ((flags & 0x8000) ? 1 : 2), pathStart = detailStart + prefix + 4;
      if (pathStart + pathBytes > detailStart + detailSize) throw new Error('Filesystem path outside event details.');
      const filePath = b.subarray(pathStart, pathStart + pathBytes).toString((flags & 0x8000) ? 'ascii' : 'utf16le').split('\0')[0];
      const target = targets.find(t => t.index === index);
      const event = {sequence: i, timestampUtc: filetimeUtc(timestamp), pid: target.pid, operationCode: operation,
        operation: ({6: 'QueryOpen', 19: 'CreateFileMapping', 20: 'CreateFile', 23: 'ReadFile', 25: 'QueryInformationFile',
          27: 'QueryEAFile', 30: 'QueryVolumeInformation', 38: 'CloseFile', 40: 'QuerySecurityFile'})[operation] || `Filesystem:${operation}`,
        path: filePath, resultCode: u32(offset + 36)};
      // Length/offset are operation metadata, never file contents.
      if (operation === 23 && detailSize >= 44) {
        event.length = u32(detailStart + 4 + 12);
        event.fileOffset = Number(u64(detailStart + 4 + (pointerBytes === 8 ? 32 : 24)));
      }
      fileEvents.push(event);
    }
  }
  const summary = {
    schema: 1, format: 'PML v9', bytes: size, sha256: crypto.createHash('sha256').update(b).digest('hex'),
    totalEvents: eventCount, totalProcessRecords: processCount, shippingProcessRecords: targets,
    shippingEvents: matching, otherProcessEvents: eventCount - matching,
    firstEventUtc: minimumTime === null ? null : filetimeUtc(minimumTime),
    lastEventUtc: maximumTime === null ? null : filetimeUtc(maximumTime),
    shippingEventClasses: classes, shippingOperationCodes: operations,
    eventDetailsDecoded: false, filesystemPathMetadataDecoded: includePaths,
    commandLinesDecoded: false, symbolsResolved: false, dnsQueriesMade: false,
    layoutSource: 'https://github.com/eronnen/procmon-parser/blob/d32f1ddd109054cab4be6f727ba9944a7992bd73/procmon_parser/stream_logs_format.py'
  };
  if (includePaths) {
    summary.configurationEvents = fileEvents.filter(e => /\.ini$|[\\/]Saved(?:[\\/]|$)|McpConfig|OnlineSubsystem/i.test(e.path));
    summary.shippingFileEvents = fileEvents;
  }
  fs.writeFileSync(path.join(root, includePaths ? 'pml-files-summary.local.json' : 'pml-summary.local.json'), JSON.stringify(summary, null, 2) + '\n', {flag: 'wx'});
  const {shippingFileEvents, configurationEvents, ...publicSummary} = summary;
  console.log(JSON.stringify({...publicSummary, shippingProcessRecords: targets.map(t => ({index: t.index, pid: t.pid})),
    configurationEventsCount: configurationEvents?.length ?? null,
    iniReadEvents: configurationEvents?.filter(e => /\.ini$/i.test(e.path) && e.operation === 'ReadFile' && e.resultCode === 0).length ?? null}, null, 2));
} finally { fs.closeSync(fd); }
