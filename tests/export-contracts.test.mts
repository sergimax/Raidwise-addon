import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Lua } from "wasmoon-lua5.1";
import type { CharacterExport, InstanceLockout, ItemIdList } from "../types/CharacterExport.ts";
import type { CooldownsExport, CooldownCharacterExport, CharacterCurrencyEntry } from "../types/CooldownsExport.ts";

function object(value: unknown): Record<string, unknown> {
  assert(value !== null && typeof value === "object" && !Array.isArray(value));
  return value as Record<string, unknown>;
}
function string(value: unknown): string { assert.equal(typeof value, "string"); return value as string; }
function number(value: unknown): number { assert.equal(typeof value, "number"); assert(Number.isFinite(value)); return value as number; }
function boolean(value: unknown): boolean { assert.equal(typeof value, "boolean"); return value as boolean; }
function list<T>(value: unknown, parse: (value: unknown) => T): T[] {
  assert(Array.isArray(value)); return value.map(parse);
}
function items(value: unknown): ItemIdList {
  const row = object(value);
  const ids = list(row.ids, number);
  if (row.names === undefined) return { ids };
  const names = list(row.names, string);
  assert.equal(names.length, ids.length);
  return { ids, names };
}
function lockout(value: unknown): InstanceLockout {
  const row = object(value);
  return {
    name: string(row.name), id: number(row.id), reset: number(row.reset), resetAt: number(row.resetAt),
    difficulty: number(row.difficulty), difficultyName: string(row.difficultyName),
    locked: boolean(row.locked), extended: boolean(row.extended), isRaid: boolean(row.isRaid), maxPlayers: number(row.maxPlayers),
  };
}
function character(value: unknown): CharacterExport {
  const row = object(value); assert.equal(row.reportVersion, 1);
  return {
    reportVersion: 1, name: string(row.name), class: string(row.class), spec: string(row.spec),
    ...(row.gearScore === undefined ? {} : { gearScore: number(row.gearScore) }),
    gear: items(row.gear), bags: items(row.bags), lockouts: list(row.lockouts, lockout),
  };
}
function currency(value: unknown): CharacterCurrencyEntry {
  const row = object(value);
  return { id: string(row.id), label: string(row.label), icon: string(row.icon), count: number(row.count) };
}
function cooldownCharacter(value: unknown): CooldownCharacterExport {
  const row = object(value);
  return {
    key: string(row.key), name: string(row.name), realm: string(row.realm), class: string(row.class), spec: string(row.spec),
    updatedAt: number(row.updatedAt), lockouts: list(row.lockouts, lockout),
    ...(row.currency === undefined ? {} : { currency: { entries: list(object(row.currency).entries, currency) } }),
  };
}
function cooldowns(value: unknown): CooldownsExport {
  const row = object(value); assert.equal(row.reportVersion, 1);
  return { reportVersion: 1, exportedAt: number(row.exportedAt), characters: list(row.characters, cooldownCharacter) };
}

test("real Lua JSON exports satisfy typed contracts and round-trip every control byte", async () => {
  const lua = await Lua.create();
  try {
    lua.doStringSync('Raidwise={db={}}; function time() return 1000 end');
    for (const module of ["CharacterExport", "CharacterLockouts"]) {
      lua.doStringSync(await readFile(new URL(`../Raidwise/${module}.lua`, import.meta.url), "utf8"));
    }
    const text = Array.from({ length: 32 }, (_, index) => String.fromCharCode(index)).join("") + 'Привет "quoted" \\ Ω 😀';
    // Build NUL-containing data in Lua; do not rely on bridge string conversion.
    lua.global.set("suffix", text.slice(32));
    lua.doStringSync(`
      local controls={};for index=0,31 do controls[#controls+1]=string.char(index) end
      sample=table.concat(controls)..suffix
      function Raidwise:CollectCharacterInfo() return {name=sample,class='MAGE',spec=sample} end
      function Raidwise:CollectCurrentGearScore() return score end
      function Raidwise:CollectEquippedGear() return {ids={123},names={sample}} end
      function Raidwise:CollectBagItems() return {ids={456},names={sample}} end
      function GetNumSavedInstances() return 1 end
      function GetSavedInstanceInfo() return sample,12345,3600,4,1,nil,0,1,25,sample end
      function Raidwise:SaveCurrentCharacterLockouts() end
      Raidwise.db.characters={
        [sample]={name=sample,realm=sample,class='MAGE',spec=sample,updatedAt=1000,
          currency={entries={{id=42,label=sample,icon=sample,count=5}}},lockouts=Raidwise:CollectInstanceLockouts()},
        legacy={name='Legacy',realm='Realm',class='WARRIOR',spec='',updatedAt=0,lockouts={}}
      }
    `);
    let lastCharacter: CharacterExport | undefined;
    for (const includeNames of [true, false]) {
      for (const score of [undefined, 6000]) {
        lua.doStringSync(`Raidwise.db.includeGearNames=${includeNames};score=${score ?? "nil"}`);
        const raw: unknown = JSON.parse(lua.doStringSync("return Raidwise:FormatEquippedGearExport()") as string);
        const parsed = character(raw);
        lastCharacter = parsed;
        assert.deepEqual(raw, parsed);
        assert.equal(parsed.name, text); assert.equal(parsed.spec, text);
        assert.equal(parsed.gearScore, score);
        if ("names" in parsed.gear) assert.deepEqual(parsed.gear.names, [text]);
        assert.equal("names" in parsed.gear, includeNames);
        assert.equal("names" in parsed.bags, includeNames);
        assert.equal(parsed.lockouts[0].name, text); assert.equal(parsed.lockouts[0].difficultyName, text);
        assert.equal(parsed.lockouts[0].locked, true); assert.equal(parsed.lockouts[0].extended, false);
      }
    }
    const raw: unknown = JSON.parse(lua.doStringSync("return Raidwise:FormatCooldownsExport()") as string);
    const parsed = cooldowns(raw); assert.deepEqual(raw, parsed);
    const saved = parsed.characters.find(row => row.key === text)!;
    assert(saved); assert.equal(saved.name, text); assert.equal(saved.realm, text); assert.equal(saved.spec, text);
    assert.equal(saved.currency!.entries[0].label, text); assert.equal(saved.currency!.entries[0].icon, text);
    assert.equal(saved.lockouts[0].name, text); assert.equal(saved.lockouts[0].difficultyName, text);
    assert.equal(parsed.characters.find(row => row.key === "legacy")!.currency, undefined);
    // The validators reject incompatible payloads instead of relying on a cast from JSON.parse.
    assert(lastCharacter);
    assert.throws(() => character({ ...lastCharacter, reportVersion: 2 }));
    assert.throws(() => character({ ...lastCharacter, gear: { ids: ["wrong"] } }));
    assert.throws(() => character({ ...lastCharacter, lockouts: [{ ...lastCharacter.lockouts[0], locked: 1 }] }));
    assert.throws(() => cooldowns({ ...object(raw), exportedAt: "wrong" }));
  } finally { lua.global.close(); }
});
