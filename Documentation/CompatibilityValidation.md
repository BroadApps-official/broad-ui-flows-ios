# Проверка совместимости кандидата 7.0.0

`Examples/BroadUIFlowsGallery/Sources/CompatibilityProbe.swift` только компилируется:
Gallery его не вызывает. Gate шаги 7–8 включают файл через `sources: Sources`,
с warnings-as-errors и `SWIFT_STRICT_CONCURRENCY = complete`. Probe проверяет старые
вызовы, пропущенные defaults, trailing closures и точные типы фабрик `init`.

В репозитории нет исполняемого runtime probe. `Scripts/check_ui_contracts.sh` —
статические source contracts; его self-test проверяет синтетические нарушения
исходников. Эти проверки не изменены и не доказывают поведение ViewModel или
смонтированного SwiftUI host. Ниже — сценарии для ручной проверки на fixtures
после сборки вне песочницы. Настоящие финансовые операции не нужны.

## Settings

Использовать настоящий `BroadSettingsHost`, fixture restore use case и обработчик
`showPaywall`, который открывает fixture paywall и увеличивает счётчик вызовов.
`BroadSettingsScreen.preview` для этой проверки не подходит: его actions пустые.

- В старом вызове без `showPaywall` с явно переданным `content:` компилятор
  сообщает `missing argument for parameter 'showPaywall' in call`.
  В Swift 6.4 старый unlabeled trailing closure при текущем порядке параметров
  привязывается к `showPaywall`: диагностика содержит `missing argument 'content'`
  и несовпадение числа аргументов closure. Добавление обязательного `showPaywall`
  исправляет оба случая; порядок параметров оставлен как в main.
- Миграция: `showPaywall: { /* present the settings-placement paywall */ }`.
- `screen.showPaywall()` и `screen.manageSubscription()` по отдельности открывают
  один и тот же paywall. Каждая кнопка вызывает callback ровно один раз.
- Нажать обе кнопки подряд в пределах 400 мс, в обоих порядках: один callback.
  После открытия gate второе действие снова разрешено. Другие действия Settings
  разделяют этот gate, включая restore.
- Страница подписок App Store и системный экран управления подпиской не открываются.

## Токен-каталог и preloading

Каждый допустимый payload проверить тремя путями: обычный `loadIfNeeded()`,
`initialPayload`, `preload(.tokens)` → дождаться загрузки → `take(.tokens)`.
Fixture loader возвращает payload без преобразования массива.

| Payload | Ожидаемый результат |
|---|---|
| `.tokens` → `.tokens`, 0 продуктов | `.empty`, пустой массив сохранён |
| `.tokens` → `.tokens`, 1 consumable с ценой | `.content`, исходный ID, можно выбрать и купить |
| `.tokens` → `.tokens`, N продуктов | Исходное количество, порядок и presentation IDs |
| Два одинаковых product IDs с разными presentation IDs | Обе строки, отдельный выбор каждой occurrence |
| Смешанные consumable / non-consumable / subscription | Все строки на месте; допустимый consumable доступен |
| Consumable без цены | Строка на месте, недоступна для выбора и покупки |
| Только non-consumable | `.content`, строки на месте, `canPurchase == false` |
| `.tokens` → `.main`, `usedFallback = true`, все consumable, `fallbackReason = nil` | Принимается как в 6.5.0 |
| Такой fallback со смешанными продуктами | Обычная загрузка: failure; prepared payload: отклонён, обычная загрузка |
| Другой requested/resolved placement или `.main` без `usedFallback` | Отклонён |

При принятом `initialPayload` каталог готов до appearance, повторной загрузки нет;
shown/impression отправляется только после appearance. `take` передаёт payload один
раз. Проверить nil, истечение freshness lifetime и `discardAll`: просроченные и
неиспользованные payload освобождаются через presentation lifecycle. Принятый
payload не получает новые IDs и не фильтруется, не сортируется, не дедуплицируется.
UIFlows не создаёт подмену token placement подписочным `main`.

## Названия и количество

Одинаковый payload отрисовать готовым subscription view, Special Offer,
token view и через `screen.plans` / `screen.packages`.

| Copy / данные | Ожидаемый результат |
|---|---|
| Встроенный `.standard` / `.english`, период 1 год | `Yearly` |
| Встроенный `.russian`, период 1 год / 3 месяца | `Год` / `3 месяца` |
| Названия включены, неизвестный/нестандартный период | Локализованный `fallbackTitle` |
| Свой copy со старым трёхстрочным `Products` | `title ?? fallbackTitle`, без английских названий |
| Явные `planNames: nil` / `tokenName: nil` | Тот же старый заголовок |
| Свой copy с локализованным `planNames` / `tokenName` | Названия на явно выбранном языке |
| Token ID `50_Tokens_9.99`, backend 2000, названия включены | `2000 Tokens` / `2000 токенов`, `tokens == 2000` |
| Тот же ID, backend nil, названия включены | `50 Tokens` / `50 токенов`, `displayTokenCount == 50`, `tokens == nil` |
| Тот же ID, backend nil, названия выключены | Старый `title ?? fallbackTitle`, `displayTokenCount == nil`, `tokens == nil` |
| Тот же ID, backend 0 | Ноль сохраняется; при включённых названиях — fallback, число 50 не подставляется |
| ID без ведущего числа, backend nil, названия включены | `fallbackTitle`, никакого выдуманного количества |

Цена, выбранный presentation ID и purchase routing не зависят от режима названий.
Баланс, зачисление и savings/best-value считают только backend-количество.
Проверить одинаковые legacy модели/copy на `Equatable`; новые поля участвуют в
сравнении, чтобы смена отображаемого имени обновляла интерфейс. Встроенный copy
с включёнными названиями отличается от ручного legacy copy с теми же старыми
строками: это теперь разные настройки отображения.
