import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";

async function run(body: string) {
  const lua = await Lua.create();
  try {
    lua.doStringSync(await readFile(new URL("lua/sync-setup.lua", import.meta.url), "utf8"));
    for (const module of ["PlayerHistory", "PlayerHistoryStore", "PlayerRecords", "CharacterLinks", "PlayerRecordBridge", "PlayerRecordLinks"]) {
      lua.doStringSync(await readFile(new URL("../Raidwise/" + module + ".lua", import.meta.url), "utf8"));
    }
    lua.doStringSync(`
      Raidwise:InitializeHistoryStore()
      for _,key in ipairs({'A','B','C','D'}) do Raidwise:EnsureHistoryEntryForGuid(key,{name=key,realm='Realm'}) end
    `);
    lua.doStringSync(body);
  } finally { lua.global.close(); }
}

test("associations preserve opposite opinions and authors, never create filled profiles", async () => {
  await run(`
    local a=Raidwise;local s=a:GetPlayerRecordStore()
    assert(a:SavePersonalRatingForGuid('A',nil,'positive',{},{}))
    assert(a:SavePersonalRatingForGuid('B',nil,'negative',{},{}))
    local revisionA=s.profiles.A.revision;local revisionB=s.profiles.B.revision
    assert(a:LinkPlayerCharacters('A','B'))
    assert(s.profiles.A.opinion=='positive' and s.profiles.B.opinion=='negative')
    assert(s.profiles.A.revision==revisionA and s.profiles.B.revision==revisionB)
    assert(s.profiles.A.author.guid=='SELF' and s.profiles.B.author.guid=='SELF')
    assert(a:LinkPlayerCharacters('B','C'))
    assert(not a:IsPlayerRecordFilled('C') and s.profiles.C==nil and #s.changes.C>0)
    assert(a.db.characterGroups==nil and a.db.localCharacterMains==nil)
    assert(#a:GetLinkedCharacters('A')==3 and a:GetLinkedCharacters('A')[1].guid=='A')
    assert(a:SetLinkedCharacterRole('C','B','main'))
    assert(a:GetLinkedCharacters('A')[1].guid=='B' and s.profiles.A.revision==revisionA)
    assert(not a:UnlinkPlayerCharacter('A','B'))
    assert(a:UnlinkPlayerCharacter('A','C'))
    assert(#a:GetLinkedCharacters('C')==1 and not a:IsPlayerRecordFilled('C'))
    assert(not a:LinkPlayerCharacters('D','A'))
    assert(not a:LinkPlayerCharacters('D',123))
    a:InitializeHistoryStore();assert(a:GetLinkedCharacters('A')[1].guid=='B')
    assert(a:UnlinkPlayerCharacter('B','A'))
    assert(not next(s.groups) and s.profiles.A.opinion=='positive')
    local named=a:EnsureHistoryEntryForGuid('name:realm:typed',{name='Typed',realm='Realm'})
    local ok,reason=a:LinkPlayerCharacters(named.guid,'REAL',{name='Typed',realm='Realm'})
    assert(not ok and reason=='CHAR_LINK_SELF' and not next(s.groups))
  `);
});

test("delete invalidates drafts, clears only requested profiles and links, preserves encounters", async () => {
  await run(`
    local a=Raidwise;local s=a:GetPlayerRecordStore()
    for _,key in ipairs({'A','B','C'}) do assert(a:SaveProfileNotesForGuid(key,nil,'private '..key)) end
    assert(a:LinkPlayerCharacters('A','B'));assert(a:LinkPlayerCharacters('A','C'))
    local stale=a:CreatePlayerRecordDraft('A');stale.note='must not return'
    s.meetingStats.SELF={A={count=7}};s.encounters.SELF={A={{id='meeting'}}}
    local hidden=false
    a.raidDetailFrame={profileMember={guid='A'},profileDraft={dirty=true},pendingCharacterLink={},Hide=function() hidden=true end}
    local refreshes=0;a.RefreshRatingViews=function() refreshes=refreshes+1 end
    assert(a:DeleteCharacterDatabaseRecords({'A','A'})==1)
    assert(hidden and not a.raidDetailFrame.profileMember and not a.raidDetailFrame.profileDraft)
    assert(s.profiles.A==nil and s.notes.A==nil and s.changes.A==nil)
    assert(s.meetingStats.SELF.A.count==7 and s.encounters.SELF.A[1].id=='meeting' and s.identities.A)
    assert(s.notes.B.text=='private B' and s.notes.C.text=='private C')
    assert(a:GetLinkedCharacters('B')[1].guid=='B' and #a:GetLinkedCharacters('B')==2)
    local ok,err=a:CommitPlayerRecordDraft(stale);assert(not ok and err=='STALE_DRAFT')
    local fresh=a:CreatePlayerRecordDraft('A');fresh.note='new';assert(a:CommitPlayerRecordDraft(fresh))
    assert(not a:CommitPlayerRecordDraft(stale))
    assert(a:DeleteCharacterDatabaseRecords({'C'})==1 and not next(s.groups))
    assert(a:GetProfileNotes({guid='B'})=='private B' and refreshes==2)
  `);
});

test("link-only deletion and deleting every filled profile leave no residual groups or journal", async () => {
  await run(`
    local a=Raidwise;local s=a:GetPlayerRecordStore()
    assert(a:LinkPlayerCharacters('A','B'))
    assert(not a:IsPlayerRecordFilled('A'))
    assert(a:DeleteCharacterDatabaseRecords({'A'})==1)
    assert(s.changes.A==nil and not next(s.groups) and not a:IsPlayerRecordFilled('B'))
    assert(a:SaveProfileNotesForGuid('C',nil,'keep until delete'))
    assert(a:SaveProfileNotesForGuid('D',nil,'also delete'))
    assert(a:LinkPlayerCharacters('C','D'))
    assert(a:DeleteCharacterDatabaseRecords()==2)
    assert(not next(s.groups) and s.notes.C==nil and s.changes.D==nil)
    assert(a:DeleteCharacterDatabaseRecords({'C'})==0)
  `);
});
