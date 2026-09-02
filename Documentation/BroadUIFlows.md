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

`PaywallViewModel` получает готовые use cases BroadMonetization. Presentation не
импортирует provider SDK, не меняет порядок products и использует provider
display price. Special Offer UI показывается вторым paywall после закрытия
первого только при `special_offer = true`; это единственный gate, и любое
другое значение не показывает экран. Countdown локально идёт
`24:00:00 → 00:00:00 → 24:00:00`, продолжается между открытиями и не является
сроком действия предложения.

## Token и RU UI

Token paywall и RU subscription management работают через public
BroadMonetization protocols. Любой network/payment result остаётся типизированным;
UI не считает timeout успехом и не повторяет financial action автоматически.

## Проверка

```bash
bash Scripts/module_gate.sh
```

Gate не создаёт test targets и не запускает реальные внешние операции.
