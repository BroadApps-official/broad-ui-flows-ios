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
первого только при strict `special_offer = true` из main Remote Config.
Отдельный offer placement владеет products. Countdown считает до конца
persisted 24-часового окна, на нуле блокирует покупку и закрывает
экран. Значение не зацикливается в 24:00:00.

## Token UI и optional billing

Token paywall работает через public BroadMonetization protocols.
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

## Проверка

```bash
bash Scripts/module_gate.sh
```

Gate не создаёт test targets и не запускает реальные внешние операции.
