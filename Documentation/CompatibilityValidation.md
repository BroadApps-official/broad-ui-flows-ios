# Проверка совместимости кандидата 7.0.0

`Examples/BroadUIFlowsGallery/Sources/CompatibilityProbe.swift` только компилируется:
Gallery его не вызывает. Gate шаги 8–9 включают файл через `sources: Sources`,
с warnings-as-errors и `SWIFT_STRICT_CONCURRENCY = complete`. Probe проверяет старые
вызовы, пропущенные defaults, trailing closures и точные типы фабрик `init`.

`Scripts/run_contract_probes.py` собирает два небольших macOS executable из
production-исходников Core, Monetization и UIFlows вместе с локальными fixtures.
Шаг 6/10 `Scripts/module_gate.sh` запускает их после сборки пакета. Нет сети,
активации provider SDK, платежей, XCTest, Swift Testing или test targets.
Каждый сценарий печатает PASS; ошибка компиляции или контракта даёт FAIL и ненулевой
exit code. Strict concurrency и warnings-as-errors включены также для probes.

Запуск из корня модуля:

```bash
python3 Scripts/run_contract_probes.py
```

По умолчанию зависимости берутся из `.build/checkouts/broad-core-ios` и
`.build/checkouts/broad-monetization-ios`. Для существующих локальных checkout-копий
можно задать `BROAD_CORE_ROOT` и `BROAD_MONETIZATION_ROOT` — пути к корням репозиториев.
Runner не скачивает и не изменяет зависимости; временные dylib, executable и module
cache удаляются после запуска. Временные копии UIFlows получают только `import Combine`,
нужный для ObservableObject/@Published без полного SwiftPM-модуля; тела production-кода
не заменяются фикстурами.

`TokenCatalogProbe.swift` исполняет валидатор, настоящий `BroadTokenPaywallViewModel`
(обычная загрузка, `initialPayload`, выбор, purchase gate, screen mapping) и настоящий
`BroadPaywallPreloader`. `ProductNamesProbe.swift` исполняет встроенный и legacy copy,
формирование token screen/packages, plural rules и сравнения Equatable.

`Scripts/check_ui_contracts.sh` остаётся статической проверкой исходников; его
self-test проверяет синтетические нарушения. Probes не монтируют SwiftUI host и
не доказывают визуальное поведение. Ниже указаны автоматические и ручные проверки.

## Settings

**Ручная проверка:** Gallery → **Settings (real host)** использует настоящий
`BroadSettingsHost(configuration:showPaywall:restorePurchases:onRestored:content:)`.
Restore use case `FixtureRestore` возвращает `.nothingFound` локально. Presenter
открывает sheet **Paywall · settings** и увеличивает видимый `Presenter calls`.
Gallery → **Settings (preview fixtures)** сохраняет прежнюю preview-страницу;
её пустые actions не доказывают работу host.

`BroadSettingsState.perform` находится в private SwiftUI/UIKit-файле, поэтому
macOS probes его не собирают. Settings gate покрывает этот Gallery-сценарий;
его ещё нужно выполнить на устройстве или последовательно на одном симуляторе.

- В старом вызове без `showPaywall` с явно переданным `content:` компилятор
  сообщает `missing argument for parameter 'showPaywall' in call`.
  Текущий порядок параметров: configuration, showPaywall, restorePurchases,
  onRestored, content. Диагностику legacy-вызовов и мигрированный trailing closure
  отдельно проверяет compiler compatibility matrix, а не runtime probes.
- Миграция: `showPaywall: { /* present the settings-placement paywall */ }`.
- `screen.showPaywall()` и `screen.manageSubscription()` по отдельности открывают
  один и тот же paywall. Каждая кнопка вызывает callback ровно один раз.
- Нажать обе кнопки подряд в пределах 400 мс, в обоих порядках: один callback.
  Кнопки `Get Pro + Manage (same tap)` и `Manage + Get Pro (same tap)` вызывают
  оба метода в одном обработчике: счётчик увеличивается ровно на один, sheet один.
  После открытия gate второе действие снова разрешено. Другие действия Settings
  разделяют этот gate, включая restore.
- Страница подписок App Store и системный экран управления подпиской не открываются.

## Токен-каталог и preloading

**Автоматически:** каждый представимый payload из таблицы проверяется тремя путями:
обычный `loadIfNeeded()`, `initialPayload`, `preload(.tokens)` → `take(.tokens)`.
Fixture loader возвращает payload без преобразования массива. Проверяются равенство
всего payload, порядок screen packages, SKU и presentation IDs. Purchase repository
только записывает вызовы и возвращает `.cancelled`; повторный тап вызывает его один раз.

| Payload | Ожидаемый результат |
|---|---|
| `.tokens` → `.tokens`, 0 продуктов | `.empty`, пустой массив сохранён |
| `.tokens` → `.tokens`, 1 consumable с ценой | `.content`, исходный ID, можно выбрать и купить |
| `.tokens` → `.tokens`, N продуктов | Исходное количество, порядок и presentation IDs |
| Два одинаковых product IDs с разными presentation IDs | Обе строки, отдельный выбор каждой occurrence |
| Смешанные consumable / non-consumable / subscription | Все строки на месте; допустимый consumable доступен |
| Consumable без цены | Строка на месте, недоступна для выбора и покупки |
| Только non-consumable | `.content`, строки на месте, `canPurchase == false` |
| `.tokens` → `.main`, `usedFallback = true`, все consumable, `fallbackReason = nil` | Предикат UIFlows принимает; ограничение создания payload описано ниже |
| Такой fallback со смешанными продуктами | Обычная загрузка: failure; prepared payload: отклонён, обычная загрузка |
| Другой requested/resolved placement или `.main` без `usedFallback` | Отклонён |

При принятом `initialPayload` каталог готов до appearance, повторной загрузки нет;
shown/impression отправляется только после appearance. `take` передаёт payload один
раз. Автоматически проверяются nil/invalid/empty `initialPayload`, отсутствие повторной
загрузки, один shown после appearance для content, отсутствие shown для empty,
close после disappearance, отсутствие параллельных preload, истечение freshness
lifetime, `discardAll` и освобождение rejected/expired/discarded presentations.
Принятый payload не получает новые IDs и не фильтруется, не сортируется, не дедуплицируется.
UIFlows не создаёт подмену token placement подписочным `main`.

**Граница зависимости:** Monetization 5.2.1 вычисляет `PaywallOrigin.usedFallback`
из requested/resolved placement и требует `fallbackReason` при их различии.
Поэтому legacy origin `.tokens` → `.main` без причины и вариант с `usedFallback = false`
не представимы как настоящий payload. Их проверяет внутренний production-предикат
`BroadTokenPaywallPayloadValidator.accepts`, которому делегирует
`PaywallPayload.isValidTokenPaywallPayload`. В предикате нет условия по причине.
Три пути загрузки проверяют fallback с `.unavailable`; исходники зависимости и её
preconditions не меняются. Это доказательство политики UIFlows, а не возможности
создать такой legacy payload в текущей Monetization.

**Вручную осталось:** отрисовка длинного/смешанного каталога, доступность строк,
выбор каждой duplicate occurrence жестом/VoiceOver, retry/close, освобождение
неиспользованного preload при уходе с реального presenting screen.

## Названия и количество

**Автоматически:** встроенные EN/RU названия `Weekly`/`Monthly`/`Yearly`/`3 Months`
и `Неделя`/`Месяц`/`Год`/`3 месяца`, unknown/custom period fallback, собственный
legacy copy из трёх аргументов, явный nil и локализованный opt-in. Token package
проверяется через production screen mapping, включая backend/ID/nil/zero и русские
формы `1 токен`, `2 токена`, `5 токенов`, `11 токенов`, `21 токен`.

**Вручную:** одинаковый payload отрисовать готовым subscription view, Special Offer,
token view и через `screen.plans` / `screen.packages`; проверить длинные имена,
Dynamic Type, положение цены и элементов управления.

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
Автоматически проверяются одинаковые legacy copy/packages на `Equatable`;
новые поля участвуют в сравнении, чтобы смена отображаемого имени обновляла интерфейс. Встроенный copy
с включёнными названиями отличается от ручного legacy copy с теми же старыми
строками: это теперь разные настройки отображения.

## Что не закрывается этими probes

- Настоящий SwiftUI Settings host, два физических тапа/мультитач и повтор после
  окна gate: ручная Gallery-проверка выше. В этой задаче симулятор не запускался.
- Полный module gate, сборки Gallery и неизменённых production-потребителей,
  compiler compatibility matrix и актуальность PublicAPI: отдельные проверки.
- Обновление поверх сохранённых данных приложения: account ID, pending purchase,
  balance, onboarding progress, Special Offer state и отсутствие повторной покупки.
- Сеть, provider SDK, настоящий restore/fulfillment, backend и платежи: fixtures
  не являются проверкой этих интеграций.
