# Протокол аудита — 2026-11-06

Связан с [основным отчётом](Audit-2026-11-06.md). Рабочий каталог:
`C:\Users\ififo\repos\Raidwise-addon`.

После первой очереди исправлений F01 больше не воспроизводится. Сценарий ниже
сохранён для исходного commit аудита; его последний assertion на исправленном
коде должен падать. Актуальная регрессия находится в `tests/architecture.test.mts`
(`active TOC bootstrap...`): реальный список модулей TOC, инициализация активного
хранилища, повторное чтение сохранённого мнения и обработка отсутствующих API.
После исправлений `npm run check` прошёл: **78/78**, typecheck успешен.
GitHub CI и игровой клиент в этой проверке не запускались.

## Среда и штатная проверка

```text
git rev-parse HEAD
de9cd9d9c4f501008c210dc017f268807a751b10

node --version
v24.15.0

npm run check
typecheck: exit 0
tests 77; pass 77; fail 0; cancelled 0; skipped 0; todo 0
156 Lua rule checks passed
```

Установленные зависимости использованы без переустановки. Исходный `git status
--short` и `git diff --stat` были пусты. Отдельные пробы выполнялись в изолированной
WASM Lua VM, без записи настоящей БД. Ниже приведён воспроизводимый сценарий.
Он проверяет текущие дефекты, поэтому его assertions намеренно перестанут
проходить после соответствующих исправлений; это не предлагаемый regression suite.

## Запуск дополнительных проб

Из корня репозитория передать следующий JavaScript в `node --input-type=module`
через stdin (в PowerShell — literal here-string `@' ... '@ | node --input-type=module`).

```javascript
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { Lua } from 'wasmoon-lua5.1';

const lua = await Lua.create();
const run = source => lua.doStringSync(source);
const load = name => run(readFileSync('Raidwise/' + name, 'utf8'));
try {
  assert.equal(run('return _VERSION'), 'Lua 5.1');
  run(`
    Raidwise={db={}}
    function GetRealmName() return 'Realm' end
    function UnitGUID() return 'SELF' end
    function UnitName() return 'Me' end
    function time() return 1000 end
  `);
  load('PlayerRecords.lua');

  // F03: валидатор принимает вложенную запись, которую reader не читает.
  const corrupt = run(`
    local a=Raidwise; local s=a:InitializePlayerRecords()
    a:UpsertPlayerRecordIdentity({guid='X',name='Other'})
    s.profiles.X={}
    assert(a:InitializePlayerRecords()==s)
    local ok,err=pcall(a.IsPlayerRecordFilled,a,'X')
    assert(not ok)
    return tostring(err)
  `);
  console.log('F03', corrupt);

  // R01: предпосылка совпадения GUID задана синтетически.
  const collision = run(`
    Raidwise.db={}; local a=Raidwise; a:InitializePlayerRecords()
    a:UpsertPlayerRecordIdentity({guid='X',name='Alice',realm='RealmA'})
    local d=a:CreatePlayerRecordDraft('X'); d.opinion='negative'
    assert(a:CommitPlayerRecordDraft(d))
    a:UpsertPlayerRecordIdentity({guid='X',name='Bob',realm='RealmB'})
    local r=a:GetPlayerRecord('X')
    return r.identity.name..'|'..r.identity.realm..'|'..r.profile.opinion
  `);
  assert.equal(collision, 'Bob|RealmB|negative');
  console.log('R01', collision);

  const copies = run(`
    Raidwise.db={}; local a=Raidwise; a:InitializePlayerRecords()
    a:UpsertPlayerRecordIdentity({guid='X',name='Other'})
    local d=a:CreatePlayerRecordDraft('X')
    for i=1,100 do
      assert(a:AddPlayerRecordDraftEvent(d,'afk'))
      assert(a:CommitPlayerRecordDraft(d))
    end
    local count=0
    for _,change in ipairs(a.db.playerRecords.changes.X) do
      if change.kind=='events' then count=count+#change.before+#change.after end
    end
    assert(#d.events==100)
    return count
  `);
  assert.equal(copies, 10000);
  console.log('F02 journal event copies', copies);

  load('CharacterExport.lua');
  run(`
    function Raidwise:CollectCharacterInfo()
      return {name='Alice',class='Mage',spec='Arcane'}
    end
    function Raidwise:CollectCurrentGearScore() end
    function Raidwise:CollectEquippedGear()
      return {ids={1},names={'item'..string.char(1)..'name'}}
    end
    function Raidwise:CollectBagItems() return {ids={},names={}} end
    function Raidwise:CollectInstanceLockouts() return {} end
  `);
  const json = run('return Raidwise:FormatEquippedGearExport()');
  assert.throws(() => JSON.parse(json), SyntaxError);
  console.log('F04 JSON parser rejected raw control character');
} finally { lua.global.close(); }

const toc = readFileSync('Raidwise/Raidwise.toc','utf8')
  .split(/\r?\n/).filter(name => name.endsWith('.lua'));
const definitions = toc.filter(name =>
  /function Addon:RatingTagGroups|Addon\.RatingTagGroups\s*=/
    .test(readFileSync('Raidwise/' + name,'utf8')));
assert.equal(toc.length, 50); // Инвентаризация этого среза, не вечный контракт.
assert.equal(definitions.length, 0);
console.log('F01 active RatingTagGroups definitions', definitions.length);

const startup = await Lua.create();
try {
  startup.doStringSync(`
    SlashCmdList={}
    function CreateFrame()
      return setmetatable({},{__index=function() return function() end end})
    end
    function GetAddOnMetadata() return '' end
    function GetLocale() return 'enUS' end
  `);
  startup.doStringSync(readFileSync('Raidwise/Raidwise.lua','utf8'));
  const messages = startup.doStringSync(`
    local messages={}
    function Raidwise:Print(message) messages[#messages+1]=message end
    Raidwise:OnInitialize()
    return table.concat(messages,' | ')
  `);
  assert.match(messages, /Player rating module failed to load/);
  console.log('F01 startup', messages);
} finally { startup.global.close(); }
```

Проба startup — узкий unit harness bootstrap; она не загружает весь UI.
Отсутствие определения метода в активном аддоне дополнительно установлено по TOC.

## Зафиксированные результаты

```text
F03 ...:96: attempt to get length of field 'facts' (a nil value)
R01 Bob|RealmB|negative
F02 journal event copies 10000
F04 JSON parser rejected raw control character
F01 active RatingTagGroups definitions 0
F01 startup Player rating module failed to load. Update PlayerHistory.lua and /reload.
            | loaded (v2.0.0). Type /raidwise to open.
```

Первоначальная проба JSON передавала `{}` вместо требуемых `{ids={},names={}}`
и завершалась ошибкой фикстуры. После исправления структуры получен именно отказ
JSON parser из-за control character; первоначальная ошибка не включена в findings.

## Статические наблюдения

- Retired-файлы: CharacterLinks, CharacterProfile, KarmaData, PageReputation,
  PageSync, PageSyncExport, PlayerHistory, PlayerHistoryStore, ProfileDraft,
  ProfilePanels, SyncData, SyncJSON, SyncTransport (все `.lua`).
- Повторные определения публичных методов в TOC: `T` (bootstrap → Locale),
  `HistoryProfileForMember` (Support → Encounters), `PruneHistory` (Bridge → Encounters).
  Замена `T` ожидаема; две последние зависимости отражены как долг D07.
- Runtime transport `SendAddonMessage`/`CHAT_MSG_ADDON` найден только в
  `SyncTransport.lua`, отсутствующем в TOC.
- tests workflow имеет только manual trigger; release workflow проверяет tag,
  запускает tests и архивирует всю tracked папку `Raidwise/`.
- В `UI-Views.md` profile 37, в `ProfileWindow.lua` 38. Исторические 74/75 в
  `Character-System-Verification.md` явно пояснены более новым результатом в
  начале этого документа и не объявлены текущим падением тестов.

Номера строк относятся к указанному commit. Нагрузочные измерения клиента,
визуальная приёмка и проверка данных серверов остаются отдельной работой.
