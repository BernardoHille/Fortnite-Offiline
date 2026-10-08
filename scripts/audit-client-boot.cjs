'use strict';
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const config = JSON.parse(fs.readFileSync(path.join(root, 'configs/local.json'), 'utf8').replace(/^\uFEFF/, ''));
const file = path.join(config.buildPath, 'FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping.exe');
const data = fs.readFileSync(file); // Read only: never loads the PE image as executable code.
const names = ['AUTH_LOGIN=', 'AUTH_PASSWORD=', 'AUTH_TYPE=', 'epicapp=', 'epicenv=', 'epicportal', 'epiclocale=',
  'OnlineSubsystemMcp', 'McpConfig', 'BaseUrl', 'ServiceUrl', 'OverrideMcp', '127.0.0.1',
  'account-public-service', 'fortnite-public-service', 'lightswitch-public-service', 'xmpp-service',
  '/account/api/oauth/token', '/fortnite/api/game/v2/profile/', '/fortnite/api/calendar/v1/timeline',
  'QueryProfile', 'ClientQuestLogin', 'SetCosmeticLockerSlot', 'LobbySeason13', 'NO_UPDATE'];
const patterns = names.map(name => ({name, asciiOffset:data.indexOf(Buffer.from(name)), utf16Offset:data.indexOf(Buffer.from(name, 'utf16le'))}));
const report = {time:new Date().toISOString(),component:'phase2-static-client-audit',bytes:data.length,
  method:'literal search of ASCII and UTF-16 strings; no execution, loading, patching or extraction', patterns,
  limitations:['A string is evidence of a reference, not proof of supported flags or endpoint routing.',
    'Absence from this search is not proof that a feature is absent.', 'No client requests or boot order were observed.']};
fs.writeFileSync(path.join(root, 'logs/phase2-client-static-audit.json'), JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
