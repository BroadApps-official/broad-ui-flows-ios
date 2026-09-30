# BroadUIFlows guide

BroadUIFlows предоставляет готовый UI поверх public contracts BroadCore и
BroadMonetization. Host подключает модуль только когда готовые сценарии полезнее
собственной верстки.

Реальные визуальные проходы находятся на сайте:

- [весь BroadUIFlows и границы ответственности](https://broadapps-ios-docs.nkhsnv.chatgpt.site/docs/broad-ui-flows);
- [онбординг](https://broadapps-ios-docs.nkhsnv.chatgpt.site/docs/ui-flows-onboarding);
- [paywall и Special Offer](https://broadapps-ios-docs.nkhsnv.chatgpt.site/docs/ui-flows-paywall);
- [settings и support](https://broadapps-ios-docs.nkhsnv.chatgpt.site/docs/ui-flows-settings-support).

Paywall находится в UIFlows только как пользовательский интерфейс. Загрузка
products, purchase, restore и подтверждение Premium принадлежат
BroadMonetization.

## Onboarding и ATT

Pages задаются только массивом `OnboardingConfiguration.pages`. Стандартный
`BroadOnboardingView` и custom `BroadOnboardingFlowHost` используют общий
lifecycle boundary. ATT разрешён после появления первого слайда, актуальной
видимости окна и foreground-active scene. Disabled/invalid onboarding ничего не
планирует; loader ATT не вызывает.

## Loadable UI

Loadable surfaces покрывают loader, empty, error/retry, refresh и stale content.
App передаёт тексты, theme и действия через public configuration values.

## Paywall и Special Offer

`BroadPaywallPlan.name` и готовые subscription/Special Offer экраны со встроенными
`.standard`/`.english` показывают `Weekly`, `Monthly`, `Yearly`; с `.russian` —
`Неделя`, `Месяц`, `Год`. Другие периоды дают «3 Months»/«3 месяца», неизвестный —
`fallbackTitle`. Встроенные copy включают названия на своём языке.

Старый трёхстрочный initializer `Products` у своего copy оставляет `planNames` /
`tokenName` равными `nil`: модели и готовые экраны показывают `title ?? fallbackTitle`,
как в 6.5.0. Чтобы включить названия, задайте локализованные поля явно:

```swift
let products = BroadPaywallCopy.Products(
    fallbackTitle: "Премиум-доступ",
    unavailablePriceTitle: "Цена недоступна",
    selectedAccessibilityValue: "Выбрано",
    planNames: .russian
)
let tokenProducts = BroadTokenPaywallCopy.Products(
    fallbackTitle: "Пакет токенов",
    unavailablePriceTitle: "Цена недоступна",
    selectedAccessibilityValue: "Выбрано",
    tokenName: BroadCountedNameCopy(
        one: "токен", few: "токена", many: "токенов", usesRussianPluralRules: true
    )
)
```

Используйте эти `products` в соответствующем copy. `planNames: nil` / `tokenName: nil`
сохраняет заголовки. Локаль форматтера цены не выбирает язык названий.

`BroadPaywallPreloader` preloads a subscription or token paywall before its
sheet opens. The app calls `preload(placementID)` while the presenting screen is
visible, then passes `take(placementID)` as the view model's `initialPayload`
when opening the sheet. For token packages use `.tokens` and
`BroadTokenPaywallViewModel`; accepted catalogs are ready immediately.
Acceptance matches 6.5.0: a direct `.tokens` payload keeps every product, including
non-consumables; the existing `.main` fallback requires `usedFallback = true` and
consumables only, without a `fallbackReason` requirement. The preloader does not
create a fallback. Invalid origins trigger a regular load. Order, duplicate products
and presentation IDs remain intact; only consumables with a price can be purchased. The default freshness window is
ten minutes. `discardAll()` releases unused payloads after a confirmed purchase
or restore. A preload never reports a paywall impression; the visible view model
does. Special Offer uses its own BroadMonetization preparation flow. See
[Preloading a paywall](../Sources/BroadUIFlows/BroadUIFlows.docc/PreloadingAPaywall.md).

SemVer intent for `BroadTokenPaywallViewModel.initialPayload`: MINOR, additive
public API. The token placement validation also applies to ordinary loads.

`BroadPaywallScreen.dismissNotice()` clears the current typed notice. A Special
Offer may receive `referenceProducts` in `BroadPaywallConfiguration` from the
closed regular paywall. Its plans expose `regularPrice` and `discountPercent`
only for a higher regular price with the same period and currency; the lowest
eligible reference is used. The default empty reference list leaves these
fields empty.

For a custom Special Offer, draw only `screen.specialOfferPlan` as one card
without selection. It is the first plan in display order and the selected
purchase plan, even when `productOrder` is `.provider` or `defaultSelection`
points elsewhere. Keep the discount heading and crossed price tied to its
`discountPercent` and `regularPrice`; `screen.plans` still contains every
provider product. The `special_offer` placement should contain one product.
SemVer intent for `specialOfferPlan`: MINOR, additive public API.

`BroadTokenPaywallHost` supplies a verified `priceAmount` and per-token saving
for each package when all displayed token counts and same-currency prices are
known. Only the strongest positive saving gets `isBestValue`. A custom app flow
can set `transition: .slide` on `BroadAppFlowView`; Reduce Motion uses a fade.

SemVer intent: MINOR. These public fields, actions and overloads preserve the
previous initializers and the default route behavior.

`PaywallViewModel` получает готовые use cases BroadMonetization. Presentation не
импортирует provider SDK, не меняет порядок products и использует provider
display price. Special Offer UI показывается вторым paywall после закрытия
первого только при strict `special_offer = true` из main Remote Config.
Отдельный offer placement владеет products. Countdown считает до конца
persisted 24-часового окна, на нуле блокирует покупку и закрывает
экран. Значение не зацикливается в 24:00:00.

## Token UI и optional billing

Для пакета токенов показывайте `BroadTokenPackage.name`: например, `2000 Tokens`
или `2000 токенов`. При включённом `tokenName` сначала используется количество из backend `tokenAmount`;
если его нет, ведущее число ID служит только для надписи в
`displayTokenCount`. `package.tokens`, расчёт выгоды, зачисление и баланс не
получают число из ID. При `tokenName == nil` заголовок — `title ?? fallbackTitle`,
число из ID не читается, а `displayTokenCount` содержит только backend-количество.

Token paywall работает через public BroadMonetization protocols.
`BroadTokenPaywallCopy.english` и `.standard` дают одинаковый нейтральный
английский набор; `.russian` сохранён. `BroadTokenPaywallConfiguration(closeDelay:)`
задаёт задержку крестика от появления экрана (по умолчанию 0). Host отдаёт
`screen.canClose = false` до истечения задержки и во время операции; готовый
`BroadTokenPaywallView` скрывает крестик до истечения задержки. При исчезновении
экрана таймер отменяется, повторное появление начинает его заново. Reduce Motion
на таймер не влияет. Автоматическая сверка обновляет баланс без notice; ручное
`refreshBalance()` показывает результат. Для английского preview передайте
`copy: .english`.

SemVer intent: MINOR для добавленных preset, параметра конфигурации и параметра
preview; исправление автоматического notice
совместимо с PATCH. Текущая версия модуля не меняется до релиза.

RU subscription management и payment sheet перенесены в отдельный продукт
BroadRUBillingUI. Он подключается только в нужных target; базовый UI от него не зависит.
Любой network/payment result остаётся типизированным;
UI не считает timeout успехом и не повторяет financial action автоматически.

## Аналитика и поддержка

В 4.1.0 токенный пейвол принимает общий `trackEvent` для событий показа/закрытия.
Support email принимает необязательный баланс, device ID и список
`BroadSupportEmailIdentifier` для остальных ID текущего аккаунта, включая ID
начисления токенов. Gallery показывает письмо с токенами и без них.
Подробности — [README](../README.md#письмо-поддержки).

Согласие ИИ и правила Rate Us принадлежат приложению; Rate Us в onboarding запрещён.

## Настройки и обновление приложения

`BroadSettingsHost` принимает `BroadSettingsConfiguration` и существующий
`RestorePurchasesUseCaseProtocol` из BroadMonetization. Миграция на 7.0.0 в одну строку:
`showPaywall: { /* present the settings-placement paywall */ }`. Приложение рисует
`BroadSettingsScreen` и вызывает его действия: restore, пейвол подписки,
юридические ссылки, письмо поддержки, копирование ID, Rate и Share.
Покупки идут через Adapty: `showPaywall()` и `manageSubscription()` открывают
пейвол приложения через обязательный обработчик `showPaywall` хоста. Экран не
отменяет подписку и не открывает страницу подписок App Store; «Cancel subscription»
из макета не рисуется. Unreleased: в 6.5.0 обработчика нет, а
`manageSubscription()` открывает App Store. Host открывает
юридические ссылки через `BroadInAppSafariView`, письмо через
`BroadSupportEmailComposer` и собирает его существующим request builder.
Каждое действие проходит через один gate: после первого касания все действия
закрыты на 400 мс. Результат restore — `BroadSettingsRestoreResult`; подтверждённый
snapshot поступает в `onRestored`. `BroadSettingsScreen.preview(_:)` даёт состояния
для Preview и Gallery без SDK и сети.

На главном табе создайте `BroadAppUpdateChecker` один раз и подключите
`.broadAppUpdateAlert(checker)`. Клиент Data запрашивает iTunes lookup по bundle ID
сначала в сторе региона устройства, без кеша;
адаптер UserDefaults хранит базовую и последнюю установленную версии. При первом успешном ответе сохраняется
большая из установленной версии и версии App Store, без алерта. После установки
новой версии базой становится установленная версия. Затем алерт показывается,
только если версия App Store выше базы. `BroadAppVersion` сравнивает числовые
компоненты, поэтому `1.0.10` выше `1.0.9`. Ошибки сети и отсутствующая карточка
пропускают алерт. Тексты — `BroadAppUpdateAlertCopy`, по умолчанию русские.
`BroadAppUpdateChecker.preview(_:)` не делает запрос и не пишет UserDefaults.

## Проверка

```bash
bash Scripts/module_gate.sh
```

Gate не создаёт test targets и не запускает реальные внешние операции.
