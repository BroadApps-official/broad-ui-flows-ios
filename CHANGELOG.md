# Changelog

## Unreleased

### Added

- `BroadSettingsConfiguration.appStoreLink: URL?` и отдельный init с обязательным
  `appStoreLink`, включая `nil`; `BroadSettingsScreen.canShareApp` / `canRateApp`.
- Локализованные тексты fallback поддержки в `BroadSettingsCopy`, отдельный
  расширенный init, preview-overload с признаками Share/Rate и host-overload с
  обязательным `canSendMail` для Gallery.
- Gallery-режимы без App Store ссылки/почты, пустой адрес и ATT transition fixture;
  executable contracts для ссылок, почтовых действий, стабилизации frame и ATT lifecycle.

### Fixed

- Невалидная App Store ссылка в старом init больше не вызывает crash: трактуется
  как отсутствие ссылки. Share и Rate без ссылки безопасно ничего не делают.
- Без системной почты Settings host показывает alert с адресом, «Скопировать адрес»
  и «Закрыть»; «Открыть почту» появляется только после успешного canOpenURL.
  Пустой адрес получает отдельный alert. Native compose не получает второй fallback.
- ATT delay считается после стабилизации входящего перехода первого слайда,
  включая fade Reduce Motion; ожидание ограничено и при таймауте не запрашивает ATT.
  Loader/сплеш и отключённый onboarding по-прежнему не запрашивают разрешение.

### Compatibility

- Все существующие public сигнатуры baseline 7.0.0 сохранены, включая точные
  ссылки на initializer как функцию. Новые overload требуют новые параметры;
  deprecated-аннотаций и новых cases в существующих public enum нет.
- `appStoreURL: URL` сохраняется для чтения: ссылка или `https://apps.apple.com`;
  для проверки наличия используется `appStoreLink`. Legal preconditions не изменены.
- Старый двухстрочный `BroadSettingsCopy` сохраняет restore-тексты, новые тексты
  берёт из `.russian`. Основные действия Settings остаются под общим tap gate.
- Приложения со своим почтовым fallback не получают двойного окна, если вызывают
  `contactSupport()` только при доступной системной почте. Увеличенный вручную
  ATT delay остаётся допустимым, но компенсация длительности перехода больше не нужна.
- Исторический MAJOR-контракт Settings 7.0.0 (`showPaywall`) не меняется:
  уже требовавшаяся миграция с 6.x остаётся той же; этот MINOR новых правок не требует.

### SemVer intent

7.1.0: MINOR — API добавлен совместимыми overload, три исправления не требуют
правок существующего кода baseline 7.0.0. Версии и теги в этой worktree не меняются.

## 7.0.0

### Breaking

- `BroadSettingsHost` has one initializer and requires the app's `showPaywall`
  presenter, usually for the `settings` placement. Both `screen.showPaywall()`
  and `screen.manageSubscription()` call it through the shared tap gate; settings
  no longer open App Store subscription management.
  One-line migration: `showPaywall: { /* present the settings-placement paywall */ }`.

### Added

- `BroadPaywallPlan.name`, `BroadTokenPackage.name` and display-only
  `BroadTokenPackage.displayTokenCount` for custom screens.
- `BroadPaywallPlanNameCopy`, `BroadCountedNameCopy`, optional
  `BroadPaywallCopy.Products.planNames` and `BroadTokenPaywallCopy.Products.tokenName`.
- `BroadPaywallCopy.english`, equivalent to `.standard`.
- `BroadSettingsScreen.showPaywall()` for subscription rows.
- `BroadTokenPaywallViewModel.init(configuration:dependencies:initialPayload:)`
  and token preloading through `BroadPaywallPreloader.take(.tokens)`.
- `BroadTokenPaywallView(tokenAmount:)` accepts backend package quantities.
- A compile-only Gallery compatibility probe covers legacy calls and precisely
  typed initializer references without deprecation warnings.

### Changed

- Built-in `.standard`, `.english` and `.russian` copy enables localized product
  names in ready subscription, Special Offer and token screens. Subscription
  names use the product's period; token names prefer the backend quantity.
- Custom copy created with the old three-string `Products` initializer keeps
  `title ?? fallbackTitle`. Opt in with explicitly localized `planNames` or
  `tokenName`; passing `nil` also keeps the legacy titles.
- A leading quantity in a token product ID is used only for display, only with
  token names enabled, and only without a backend quantity. Crediting, balance,
  `package.tokens` and value comparisons always use backend data.

### Compatibility

- Executable production-source contract probes cover token catalogs, preloading and product names; Gallery adds a real Settings host with a shared fixture paywall.

- All other initializer signatures from 6.5.0 are retained as exact overloads,
  including references to `init` as a function. Expanded initializers require
  their newly added argument. Existing defaults and trailing closures remain usable.
- Historical exact signatures for configurable product order, token analytics,
  confirmation copy, discount copy, token close delay and token previews are restored.
- Ordinary `.tokens` loads, prepared payloads and `take(.tokens)` use the 6.5.0
  acceptance rules. The full catalog, order, duplicates and presentation IDs are
  preserved, including mixed catalogs. Only consumables with a price are purchasable.
- The existing consumable-only `.main` fallback is accepted with `usedFallback = true`
  without requiring `fallbackReason`. UIFlows does not create a fallback from tokens
  to a subscription `main` placement.

### SemVer intent

7.0.0: MAJOR only because of Settings (the required `showPaywall` presenter and
routing both subscription actions to it). All other changes retain the 6.5.0
source contract; built-in copy deliberately enables the new localized names.
Verified by the module gate (compile probe for every 6.x signature, executable
contract probes) and by building real 6.5.0 apps: without changes they fail only on
the missing `showPaywall`, and build after the one-line migration.

## 6.5.0

### Added

- `BroadTokenPaywallCopy.english` and `.standard` provide the same English token
  paywall text while `.russian` stays unchanged.
- `BroadTokenPaywallConfiguration.closeDelay` defaults to zero. The host screen's
  `canClose` and the ready view respect the delay after appearance, and closing
  remains blocked while busy. The cancellable timer restarts on a later
  appearance and is independent of Reduce Motion.
- `BroadTokenPaywallScreen.preview(_:formatter:copy:)` accepts copy for fixture
  notices while preserving the Russian default.
- Gallery token paywalls demonstrate English copy and a three-second close delay.

### Fixed

- Automatic balance recovery still updates the confirmed balance but no longer
  sets a success or failure notice. An explicit refresh reports its result.

### SemVer intent

MINOR for the additive public API; the automatic notice fix is PATCH-compatible.

## 6.4.0

### Added

- `BroadPaywallScreen.specialOfferPlan`: a Special Offer sells one product, so
  the screen gets the one plan to draw — the first in display order; `plans`
  still holds every product. The view model selects that plan (whatever the
  product order or default selection) and ignores other selections, so the
  purchase is what the card shows. The ready `BroadPaywallView` draws one offer
  card and the discount headline from the same plan; Remote Config crossed
  values stay a fallback when no regular plan is comparable.
- `BroadPaywallSpecialOfferCopy.discountFormat` ("%d%% OFF", Russian "Скидка %d%%").

### Fixed

- Module gate: parallel xcodebuild output can cut the path off a dependency's
  DocC warning. Such a fragment now fails the gate only when it names a file of
  this module; lines with a full path are filtered as before.

### Why

A Special Offer sells one product. App 5153 drew two plans from temporary data;
choosing the one without a discount removed the "% OFF" headline and the art
jumped. The screen now draws the one plan the purchase uses.

## 6.3.0

### Added

- `BroadPaywallPreloader`: `preload(_:)`, `take(_:)` and `discardAll()` load a
  regular paywall while the main screen is idle and hand it to
  `PaywallViewModel(initialPayload:)`, so a PRO cover slides in with its plans.
  Payloads stay fresh for ten minutes; unused ones are released through the
  presentation lifecycle, and preloading never reports a view. DocC article
  "Preloading a paywall", a Gallery page and contract checks.
- `BroadPaywallPlan.price` / `weeklyPrice` docs state the App Review rule: the
  billed amount with its period is the prominent price, the weekly equivalent
  only a small hint under the title.

- `BroadPaywallScreen.dismissNotice()` / `PaywallViewModel.dismissNotice()`: the
  screen hides a notice without keeping its own alert state.
- `BroadPaywallPlan.regularPrice` and `discountPercent` for a Special Offer, from
  `BroadPaywallConfiguration(referenceProducts:)` — the regular plan with the same
  period and currency and a higher price (the cheapest such); 1…99 % or `nil`.
- `BroadAppFlowView(route:transition:)` with `BroadAppFlowTransition.slide`: routes
  slide like onboarding pages (fade with Reduce Motion). Default stays `.none`.
- `BroadTokenPackage.priceAmount`, `savingsPercent`, `isBestValue`: per-token saving
  against the most expensive package when every package has tokens and a price in
  one currency.
- `AppFlowRoute` is `Hashable`.

### Why

Building app 5153 on the hosts showed what screens still computed themselves: the
crossed-out Special Offer price, the token "SAVE %" badge, closing a notice and the
paywall entrance animation the company QA checklist requires. Its PRO paywall also
jumped: the cover slid in while products loaded, then the panel grew and the art
moved.

## 6.2.0

### Added

- `BroadSettingsHost` and `BroadSettingsScreen`: a custom settings screen gets
  restore with a typed `BroadSettingsRestoreResult`, manage subscription, Privacy
  Policy and Terms in the app, support email, copy user ID with an
  `isUserIDCopied` confirmation, rate and share. The first tap closes every
  action for 400 ms. `BroadSettingsCopy` holds the restore notices.
- `BroadAppUpdateChecker` and `.broadAppUpdateAlert(_:copy:)` for the main tab:
  App Store lookup by bundle ID (device region storefront first, no URL cache),
  a UserDefaults baseline — the first launch stores the larger of the installed
  and store versions without an alert, an update resets it to the installed
  version — and numeric version comparison (`BroadAppVersion`). Network errors
  show nothing. `BroadAppUpdateAlertCopy` holds the texts.
- Previews without network for both, Gallery pages and contract checks.

- `BroadTokenPaywallHost`: runs a token paywall for a screen drawn by the app.
  The host owns loading, selection, the purchase and its server credit, the
  safe check of a saved purchase, the balance and closing while busy; the screen
  receives `BroadTokenPaywallScreen`.
- `BroadTokenPaywallScreen` and `BroadTokenPackage`: packages ready to draw —
  price, token amount from the app's `tokenAmount`, selection — plus the phase
  (`purchasing`, `confirming`, `refreshingBalance`), the balance as a locale
  number, `needsConfirmation`, a typed notice and actions. `confirm()` runs
  `retrySafely()` and never charges again.
- `BroadTokenPaywallScreen.preview(_:)`: every state for Xcode Previews.
- `BroadTokenPaywallViewModel.dismissFeedback()` and `message(for:)`.
- `BroadTokenPaywallCopy.Actions.confirmTitle` / `confirmingTitle` (defaulted):
  the main action while a purchase waits for its credit.
- `BroadTokenPaywallConfiguration.showsAnalytics` (default `false`).
- Gallery: a custom token store on the host, live on fixtures and in every
  preview state.

### Changed

- `BroadTokenPaywallView` hides the event log panel unless `showsAnalytics` is on;
  it was a demo panel visible to users.
- `BroadTokenPaywallCopy.russian` speaks to users: no "backend", "fixture" or
  "token placement". The load retry reads «Повторить», the pending check
  «Проверить покупку».
- The ready token view shows the balance as a number without a hard-coded
  «токенов», and notices without an appended «Баланс:»; a contract check keeps
  such words in the copy.

### Why

Apps wrapped the token view model in their own purchase logic and hard-coded
words the module had fixed in Russian. None of the reviewed apps had an update
alert, and each built settings from scratch without a multi-tap guard. The hosts
give a Figma screen everything it draws, so the screen is layout only.

## 6.1.0

### Added

- `BroadPaywallHost`: runs a subscription paywall or Special Offer for a screen
  drawn by the app. The host owns loading, plan order and selection, the close
  delay, purchase, restore, completion events, the Special Offer window, legal
  links and the checkout sheet; the screen receives `BroadPaywallScreen`.
- `BroadPaywallScreen` and `BroadPaywallPlan`: plans ready to draw — price, period,
  price per week, saving, best-value badge, selection — plus the purchase activity,
  a typed notice and actions.
- `BroadPaywallNotice` and `PaywallViewModel.notice` / `message(for:)`: purchase and
  restore outcomes as cases instead of message strings.
- `BroadPaywallScreen.preview(_:)`: every screen state for Xcode Previews without
  Adapty. `BroadPaywallProductFormatter.amount(_:)` formats a money amount.
- Gallery: a custom paywall built only from `BroadPaywallScreen`.

### Fixed

- `BroadTokenPaywallViewModel.retrySafely()` no longer starts a new purchase when
  nothing is pending; it reloads the confirmed balance instead. Buying again is
  `purchaseSelectedProduct()`. A contract check keeps retry free of purchases.
- Gate exports a UTF-8 locale before invoking Ruby so checks work in checkout
  paths containing Cyrillic characters, even when the caller uses the C locale.

### Changed

- `BroadPaywallView` uses the same lifecycle as the host; behavior is unchanged.

### Why

Apps drew their own paywalls on `PaywallViewModel` and each rebuilt plan rows,
purchase states and Special Offer wiring, copying it from other apps; one app
matched notice strings to detect "nothing to restore". The host moves that work
into the module so a Figma screen is layout only. The token retry could open a
second payment where the person asked only to check the first one.

## 6.0.0

### Breaking

- Paywall shows subscriptions from the longest period to the shortest and selects
  the longest eligible one on open. Equal periods and products without a known
  period keep the provider order; the payload itself is unchanged. Pass
  `productOrder: .provider` to keep the previous order.

### Added

- `BroadPaywallProductOrder` and `BroadPaywallConfiguration.productOrder`.
- `PaywallViewModel.displayedProducts` and `displayedProducts(in:)` for custom
  paywall screens: products in display order without sorting in the view.

### Why

Company rule: subscriptions go from the longest period to the shortest, and the
longest one is selected when the paywall opens. Apps sorted products on their own
screens and reordered payloads to preselect a plan; the order now lives in one place.

## 5.0.1

### Changed

- Support email body no longer contains the `Bundle:` line in `--- App info ---`.
  `bundleIdentifier` stays in `BroadSupportEmailConfiguration` for source
  compatibility and is not written to the email.

### Why

Platform owner decision: the support email no longer carries the Bundle ID.
Existing calls compile without changes; only the generated body loses one line.

## 5.0.0

### Breaking

- RU payment sheets, receipt storage and subscription management move to BroadRUBillingUI. Core paywalls expose a provider checkout-content builder and a generic checkout resolution. RU support greeting moves to the optional UI product.
- Requires BroadCore 3.0.0 and BroadMonetization 5.0.0. Token analytics and optional support identifiers from the unreleased 4.1.0 remain included.

## 4.1.0

### Added

- Optional `trackEvent` dependency for `BroadTokenPaywallViewModel`: reports
  `paywallShown` once per loaded presentation when visible, and
  `paywallClosed` when it disappears. Events use the existing
  `TrackPaywallEventUseCaseProtocol` and retain emission order.
- Optional `tokenBalance`, `deviceID` and `additionalIdentifiers` in
  `BroadSupportEmailConfiguration`, with `BroadSupportEmailIdentifier` for
  named account IDs. Include the account used to credit tokens; omit unknown
  balances and empty optional fields. Existing calls and base email stay unchanged.
- Gallery demonstrates support email with and without tokens and connects the
  token paywall to a fixture analytics tracker.

### Why

Token paywalls need the same view/close analytics as subscription paywalls.
Support needs the available account identifiers, particularly the account credited
with tokens, and the confirmed balance when the app uses tokens.
These additive APIs keep the 4.1.0 minor-version intent.

## 4.0.0

### Breaking

- Минимальные зависимости: BroadCore `2.0.0` и BroadMonetization `4.0.0`.
  Обновляйте ограничения версий вместе. Собственные UI-сигнатуры не менялись;
  host обрабатывает новые cases `BroadLogEvent.host` и
  `TokenFulfillmentOutcome.rejected` в exhaustive switches, если они есть.

### Почему

Новый диапазон подключает исправление восстановления token purchase:
временная ошибка сохраняет прежнюю попытку, и Retry подтверждает начисление
без новой покупки. Gallery и документация используют тот же набор зависимостей.

## 3.0.0

### Breaking

- Зависимость BroadMonetization обновлена до 3.0.0: optional payment-status
  endpoint и отдельный результат `tokensCredited` требуют нового публичного
  контракта. UI-сигнатуры не менялись; host обновляет exhaustive return switches.

### Почему

Общие экраны должны подключаться вместе с новым RU account-policy режимом,
без конфликта диапазона зависимости 2.x. README и DocC также исправляют старое
правило main: текущий placement приоритетен, main заполняет отсутствующие поля.

## 2.0.1

### Fixed

- Fixture Special Offer в Gallery передаёт общий main config с offer payload,
  как требует BroadMonetization 2.0.0. Открытие демонстрационного экрана больше
  не нарушает precondition авторизации. Products остаются у offer placement.

## 2.0.0

### Breaking

- Minimum BroadMonetization поднят до `2.0.0`: все ключи Remote Config,
  включая RU gate и A/B-коды, теперь приходят только из `main`.
- UI использует общий main config с продуктами собственного placement;
  Special Offer получает последние настройки `main` из authorization.
  Перенесите флаги в варианты/локали `main` перед обновлением с 1.x.

### Почему

Зависимость закрепляет командный контракт единого источника настроек
и предотвращает случайное подключение адаптера 1.x с другим поведением.

Все заметные изменения BroadUIFlows фиксируются здесь с объяснением: что изменилось и почему.

## 1.1.0

### Changed

- Special Offer countdown завершается на нуле, блокирует новую
  покупку и закрывает экран; визуальный цикл 24 → 0 → 24 удалён.
- Special Offer UI использует gate Remote Config основного paywall,
  а products — из отдельного offer payload.
- RU payment sheet показывает price, currency и period из точной
  backend-строки `isSpecialOffer`, выбранной BroadMonetization.

### Dependency

- Minimum BroadMonetization поднят до `1.3.0`.

## 1.0.1

### Changed

- Special Offer UI закреплён за единственным gate `special_offer = true`; его
  локальный countdown идёт по циклу `24 → 0 → 24`, продолжается между
  открытиями и не управляет показом или покупкой;
- README и owner guide теперь прямо объясняют, почему paywall находится в
  UIFlows: модуль владеет экраном и нажатиями, а Monetization — продуктами,
  purchase/restore и подтверждением Premium;
- добавлены прямые маршруты к отдельным визуальным страницам onboarding,
  paywall/Special Offer и settings/support на публичном сайте;
- публичная галерея расширена до пяти реально запущенных Simulator-референсов
  с разными onboarding, наборами paywall-продуктов, main и settings;
- верх README теперь ведёт в актуальную cross-module карту создания
  приложения, не смешивая её с UI-specific flow и gallery;
- README получил визуальный справочник AppFlow, onboarding, adaptive paywall,
  loader, Special Offer, token paywall и RU Billing UI;
- восстановлены GIF и обезличенные reference/screenshots из последней полной
  platform-инструкции с явным разделением platform behavior и app-owned design;
- все financial decisions по-прежнему делегированы BroadMonetization/backend,
  а Gallery остаётся fixture-only.

### Почему

После разделения repository public API был описан, но разработчик потерял
наглядную библиотеку состояний и последовательностей. Теперь UI owner снова
показывает ожидаемое поведение рядом с кодом без возврата к монолиту.

## 1.0.0

### Added

- AppFlow, configurable onboarding и shared ATT/window lifecycle boundary;
- reusable loader, empty, error, retry, refresh и stale UI states;
- subscription paywall, Special Offer UI и payment-method presentation;
- token paywall и RU subscription-management UI;
- standalone iPhone gallery, source contract checks, DocC/API report и gates.

### Почему

Готовые UI-сценарии вынесены в независимый public repository, чтобы приложения
могли подключать их по необходимости, а layout/lifecycle behavior можно было
ревьюить и выпускать отдельно от Core и monetization domain.
