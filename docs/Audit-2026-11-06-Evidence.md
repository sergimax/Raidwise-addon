# Протокол аудита — 2026-11-06

Связан с [основным отчётом](Audit-2026-11-06.md). Рабочий каталог:
`C:\Users\ififo\repos\Raidwise-addon`.

После первых трёх очередей F01, F02 и F03 исправлены. Сценарий ниже сохранён
для исходного commit аудита: его обращения к старым `changes.before/after` и
проверки ложного предупреждения и падения на повреждённом профиле неприменимы
к исправленному коду.
После очереди 4 историческая проба R01 также не проходит: второй upsert теперь
отклоняется с `IDENTITY_CONFLICT`, исходная identity остаётся Alice/RealmA.
Регрессия загрузки находится в `tests/architecture.test.mts`
(`active TOC bootstrap...`): реальный список модулей TOC, инициализация активного
хранилища, повторное чтение сохранённого мнения и обработка отсутствующих API.
После исправлений `npm run check` прошёл: **78/78**, typecheck успешен.
GitHub CI и игровой клиент в этой проверке не запускались.

## Проверка четвёртой очереди

Основание области: ответ пользователя 2026-11-06 «Использую только один реалм».
Миграция GUID-ключей в этой очереди не выполняется.

- `player-records.test.mts`: конфликт X/Alice/Realm → X/Bob/OtherRealm отклоняется
  до переноса алиаса; сохраняются ссылки, профили, заметки, журнал, группы,
  счётчики и черновики. Rename внутри нормализованного realm принимается.
- `encounters.test.mts`: конфликт observer/subject не обновляет прежнюю встречу
  или счётчик; после возврата правильного realm наблюдения продолжаются.
- `opinion-display.test.mts`: заданный GUID не обходит проверку realm отправителя.
- `npm run check`: **86/86**, typecheck успешен, 156 внутренних Lua rule checks.

Это офлайн-проверка защитных отказов в однореалмовом контракте, не тест полной
изоляции нескольких realm или миграции отчётов. WoW и данные пользователя
не использовались.

## Проверка третьей очереди

`npm run check`: **84/84**, typecheck успешен, 156 внутренних Lua rule checks.
Дополнены `player-records.test.mts` и загрузочный тест `architecture.test.mts`.
Сценарии: отсутствующие/неверные facts/events/revision/text/context; повреждённые
identity, groups, generations, journal deltas; неверные observer containers,
encounters без counters; неизвестные версии и сломанные корневые разделы.

Проверки утверждают сохранность оригиналов, работоспособность здоровых профилей,
идемпотентность изоляции, восстановление без перезаписи, конвертацию восстановленного
журнала v1 и недействительность старых drafts. Интеграция выполняет реальные
BuildHistoryRoster/PruneHistory/RecordCurrentGroupHistory/RunDiagnostics после
изоляции. Текст `SENSITIVE NOTE` присутствует в оригинале, но отсутствует в отчёте.
Реальные файлы SavedVariables, GitHub CI и WoW в этих проверках не использовались.

## Проверка второй очереди

Текущие проверки: `node --test tests/player-records.test.mts
tests/profile-window.test.mts`, затем общий `npm run check`.
Общий результат: **81/81**, typecheck успешен, 156 внутренних Lua rule checks.

Новые пробы используют реальный Lua core: 100/1 000 добавлений дают 100/1 000
копий событий в журнале; каждый append добавляет одну операцию. Старые snapshots
восстанавливаются из baseline и операций, включая изменение типа и автора,
перестановку, удаление всех событий и разрыв истории. Проверяются сохранность
не-событийных строк, исходной БД при ошибке, идемпотентность, последующее
редактирование и неизменность stale-draft защиты.

Отдельные проверки чтения используют страницу в 25 записей и независимые копии.
UI-тест запрещает вызов полного `GetPlayerRecord` и проверяет первую/вторую
страницы и ограничение номера после выхода за диапазон. Geometry не менялась.
Время всей нагрузки 100/1 000 событий в последнем прогоне: около 12,75 секунды
в WASM; это не измерение производительности в WoW.

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
