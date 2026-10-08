'use strict';
// Minimal LawinServer-compatible MCP schema adapter (GPL-3.0).
// Upstream profile envelopes were audited; the inventory here is new local data.
const fs = require('node:fs');
const path = require('node:path');
function createProfiles(config) {
  const now = new Date().toISOString();
  const base = id => ({_id:config.accountId, accountId:config.accountId, profileId:id, created:now, updated:now,
    rvn:1, commandRevision:1, wipeNumber:1, version:'no_version', items:{}, stats:{attributes:{}}});
  const athena = base('athena');
  athena.items['local-loadout'] = {templateId:'CosmeticLocker:cosmeticlocker_athena', quantity:1,
    attributes:{locker_name:'', banner_icon_template:'StandardBanner1', banner_color_template:'DefaultColor1',
      locker_slots_data:{slots:{Character:{items:[''],activeVariants:[null]}, Backpack:{items:[''],activeVariants:[null]},
        Pickaxe:{items:['AthenaPickaxe:DefaultPickaxe'],activeVariants:[null]},Glider:{items:['AthenaGlider:DefaultGlider'],activeVariants:[null]},
        Dance:{items:['AthenaDance:eid_dancemoves','','','','','']},LoadingScreen:{items:['']},MusicPack:{items:['']},
        SkyDiveContrail:{items:['']},ItemWrap:{items:['','','','','','','']}}}}};
  for(const [id,template] of [['local-pickaxe','AthenaPickaxe:DefaultPickaxe'],['local-glider','AthenaGlider:DefaultGlider'],['local-dance','AthenaDance:eid_dancemoves']]) {
    athena.items[id]={templateId:template,quantity:1,attributes:{item_seen:true,favorite:false,variants:[]}};
  }
  athena.stats.attributes = {season_num:13,level:1,accountLevel:1,xp:0,book_purchased:false,book_level:0,book_xp:0,
    battlestars:0,season_match_boost:0,season_friend_match_boost:0,past_seasons:[],
    loadouts:['local-loadout'],active_loadout_index:0,last_applied_loadout:'local-loadout',
    favorite_character:'',favorite_backpack:'',favorite_pickaxe:'AthenaPickaxe:DefaultPickaxe',favorite_glider:'AthenaGlider:DefaultGlider',
    favorite_dance:['AthenaDance:eid_dancemoves','','','','',''],favorite_itemwraps:['','','','','','',''],
    banner_icon:'StandardBanner1',banner_color:'DefaultColor1',favorite_loadingscreen:'',favorite_musicpack:'',favorite_skydivecontrail:''};
  const core=base('common_core');
  core.stats.attributes={current_mtx_platform:'EpicPC',permissions:[],allowed_to_send_gifts:false,allowed_to_receive_gifts:false,
    mtx_purchase_history:{purchases:[],refundsUsed:0,refundCredits:0}};
  const pub=base('common_public');
  pub.stats.attributes={displayName:config.displayName};
  return {athena, common_core:core, common_public:pub};
}
function loadProfiles(config, directory) {
  fs.mkdirSync(directory,{recursive:true});
  const file=path.join(directory,'profiles.json');
  let profiles;
  if(fs.existsSync(file)){
    profiles=JSON.parse(fs.readFileSync(file,'utf8'));
    for(const id of ['athena','common_core','common_public']){
      if(profiles[id]?.accountId!==config.accountId || profiles[id]?.profileId!==id || !profiles[id]?.stats?.attributes) throw new Error('Local persisted profile schema/identity mismatch');
    }
    if(profiles.common_public.stats.attributes.displayName!==config.displayName) throw new Error('Local persisted displayName differs from configuration');
  }else{
    profiles=createProfiles(config);
    fs.writeFileSync(file,JSON.stringify(profiles,null,2),{flag:'wx'});
  }
  return profiles;
}
function envelope(profile, requestedRevision) {
  return {profileRevision:profile.rvn, profileId:profile.profileId,
    profileChangesBaseRevision:profile.rvn, profileChanges:requestedRevision===profile.rvn?[]:[{changeType:'fullProfileUpdate',profile}],
    profileCommandRevision:profile.commandRevision,serverTime:new Date().toISOString(),responseVersion:1};
}
module.exports={createProfiles,loadProfiles,envelope};
