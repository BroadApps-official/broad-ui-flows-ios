# BroadUIFlows

Готовые SwiftUI-сценарии BroadApps для AppFlow, onboarding, loadable states,
subscription/token paywalls, Special Offer и RU Billing UI.

[Документация BroadApps iOS](https://broadapps-ios-docs.nkhsnv.chatgpt.site) ·
[Changelog](CHANGELOG.md) ·
[Публичный API](Documentation/PublicAPI.md) ·
[Как предложить правку](CONTRIBUTING.md)

## Что делает модуль

- ведёт AppFlow между onboarding, paywall и основным приложением;
- даёт стандартный onboarding и logic-only host для уникального дизайна;
- показывает loader, empty, error, retry, refresh и stale states;
- отображает subscription/token paywall на моделях `BroadMonetization`;
- показывает Special Offer, выбор способа оплаты и RU subscription management;
- регистрирует UI dependencies через `BroadUIFlowsAssembly`.

## Что модуль не делает

- не активирует Adapty/StoreKit и не импортирует их из Presentation;
- не загружает paywall/products напрямую и не решает entitlement authority;
- не содержит app-owned тексты, product/placement IDs, URLs или credentials;
- не требует `BroadExtensions` и не является обязательным umbrella package;
- не запускает реальные purchase, restore, RU checkout и cancellation в gate.

## Product и dependencies

| Product | Platform | BroadApps dependencies | External dependency |
|---|---|---|---|
| `BroadUIFlows` | iOS 17+, iPhone | compatible `BroadCore` и `BroadMonetization` from `1.0.0` | Swinject `2.10.0` |

Host app подключает этот repository только по надобности. Обязательного
`BroadPlatform` для приложения нет: оно может выбрать Core, Extensions,
Monetization, UIFlows или нужную комбинацию. Транзитивные dependencies
разрешает SwiftPM.

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/BroadApps-official/broad-ui-flows-ios.git",
        from: "1.0.0"
    )
]
```

Добавьте product `BroadUIFlows` только в тот app target, которому нужны готовые
экраны.

## Основные public entry points

- `BroadOnboardingView` — стандартный renderer;
- `BroadOnboardingFlowHost` — lifecycle/ATT boundary без навязанной верстки;
- `BroadLoadableView`, `BroadLoaderView`, `BroadErrorView`, `BroadEmptyView`;
- `BroadPaywallView` и `PaywallViewModel`;
- `BroadTokenPaywallView` и `BroadTokenPaywallViewModel`;
- `BroadRUSubscriptionManagementView`;
- `BroadAppFlowView` и `AppFlowCoordinator`.

## Критические UI-контракты

Onboarding не имеет скрытого числа страниц: единственный источник —
`OnboardingConfiguration.pages`. ATT планируется только когда первый слайд
фактически видим, окно foreground-active и delay остаётся валидным. Loader ATT
не вызывает; Rate Us в onboarding запрещён.

Paywall использует массив products, уже полученный от BroadMonetization, без
filter/sort/dedup. Special Offer может появиться только после закрытия первого
paywall. Его `24:00:00 → 00:00:00 → 24:00:00` — визуальный цикл: ноль не
отключает offer и не блокирует действие.

## Gallery

```bash
bash Scripts/generate_sandbox.sh
open Examples/BroadUIFlowsGallery/BroadUIFlowsGallery.xcodeproj
```

Gallery показывает fixture-only onboarding и библиотеку loadable/UI states.
Financial SDK не активируется, внешние операции не выполняются.

## Проверка

```bash
bash Scripts/check_ui_contracts.sh
bash Scripts/module_gate.sh
```

Gate проверяет структуру/dependencies, docs, format/lint, Swift package,
onboarding/paywall/Special Offer UI-контракты, public API report, Debug/Release
gallery и DocC. `Tests/`, XCTest/Swift Testing и настоящие операции отсутствуют.

## Versioning

Модуль выпускается независимо по SemVer. Additive API — MINOR, совместимое
исправление — PATCH, breaking contract — MAJOR. Проверенная точная комбинация
версий публикуется integration repository и compatibility matrix.

## Documentation

- [Module guide](Documentation/BroadUIFlows.md);
- [DocC landing](Sources/BroadUIFlows/BroadUIFlows.docc/BroadUIFlows.md);
- [Public searchable docs](https://broadapps-ios-docs.nkhsnv.chatgpt.site/docs/broad-ui-flows).

Документы публичны и принимают правки через pull request / `Edit this page`.
