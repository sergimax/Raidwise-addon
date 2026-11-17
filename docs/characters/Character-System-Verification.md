# Character-system manual checks and dated evidence

For current automated checks use the [task map](Reputation.md) and
[tests/README.md](../../tests/README.md). Test results come from a current run;
historical totals and resolved failures are not a live status report.

## Manual checks still requiring current evidence

The 2026-11-15 profile redesign recorded outstanding v40 readability checks.
Check long names/text/events/links and pagination in both locales and themes,
including supported UI scales. Layout references: [UI views](../ui/UI-Views.md)
and [sizes](../ui/UI-Sizes.md).

When claiming current in-client acceptance, also check the affected scenarios:

- Fresh construction after a full restart for TOC changes and after `/reload`;
  existing-window diagnostics alone cannot prove construction.
- Overview, Events, Meetings and Characters; the separate change journal;
  idle/manual save, close/switch, retained failed drafts, reload and deletion.
- Quiet groups, reconnects, roster/zone and party-to-raid transitions with real
  server events; verify observers' independent meeting counts.
- Filled-profile opinion marks and refreshing tooltips/native lists with the
  actual skin/addons. Notes alone must not produce a marker.
- Gear Check, composition and gear/currency/lockout export smoke checks if
  cross-feature acceptance is claimed.

These are evidence gaps, not confirmed defects. Previously uncompleted checks
need not block documentation cleanup that leaves their scenarios unchanged.
Offline mocks do not establish real rendering, server timing or disk persistence.

## Historical acceptance boundary

The following user evidence concerns 2026-10-31. It predates the November profile
redesign and subsequent fixes; it does not certify today's implementation.

## Проверка в WoW — результаты пользователя

Источник: сообщение пользователя от **2026-10-31**, а не автоматическое
наблюдение агента за клиентом. Таблица ниже передаёт результаты по пунктам прежнего чеклиста.

| Пункт | Результат |
|---|---|
| 1. Установка, запуск, диагностика | Предоставлен отчёт: 4 passed, 0 failed, 0 skipped |
| 2. Сохранность данных и разные собственные персонажи | Подтверждено: «есть» |
| 3. Вкладки и отображение Профиля | Подтверждено: «есть» |
| 4. Редактирование, сохранение, удаление | Предварительно подтверждено: «вроде всё есть» |
| 5. Групповые встречи и счётчики | Предварительно подтверждено: «вроде всё есть» |
| 6. База/История | Предварительно подтверждено: «вроде всё работает» |
| 7. Нативные маркеры и подсказки | Подтверждено: «всё ок» |
| 8. Отсутствие обмена/Репутации/Кармы | Подтверждено: «да, отсутствуют»; отдельного результата smoke-проверки Gear Check, состава и экспорта в этом ответе нет |

Пункты 4–6 приняты как пользовательская предварительная проверка без отдельных
трасс каждого сценария. Приложенный отчёт подтверждает открытие окна и встроенные
gear rule self-tests, но не заменяет все сценарии Gear Check и экспорта.
Новых ошибок пользователь не сообщил. Повторный прогон нужен при обнаружении
проблем или изменениях соответствующих функций.

### Отчёт `/rw diagnose` (дословно)

```text
Raidwise diagnostics v2
Addon: 1.27.0
Lua: Lua 5.1
Client: 3.3.5 / 12340
Time: 2026-10-31 10:02:34
Shell existed before test: true
Native markers revision: 3; initialized=true; ElvUI=true
Guild hook=true; refreshes=192
History records=15; saved opinions=0; current realm opinions=0
GuildFrameButton: rows=13 visible=13 identities=0 matches=0 overlays=0
GuildFrameGuildStatusButton: rows=13 visible=13 identities=0 matches=0 overlays=0
PASS native opinion markers module
Character store: schema=1; legacy exchange disabled
PASS local character system
PASS main window opening
Rules: 165/165
PASS gear rule self-tests
Summary: 4 passed, 0 failed, 0 skipped
Run immediately after /reload to test fresh window construction.
Scope: opening and gear rules; not every tab, profile interaction or live inspect timing.
```

Окно существовало до запуска диагностики (`Shell existed before test: true`),
поэтому отчёт сам по себе не доказывает создание окна с нуля после `/reload`.
Нулевое число сохранённых мнений также не доказывает работу маркеров с заполненным
Профилем; по маркерам отдельно принято ручное подтверждение пользователя (п. 7).
