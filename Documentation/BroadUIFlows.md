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

## Token и RU UI

Token paywall и RU subscription management работают через public
BroadMonetization protocols. Любой network/payment result остаётся типизированным;
UI не считает timeout успехом и не повторяет financial action автоматически.

## Письмо в поддержку

`BroadSupportEmailConfiguration` перечисляет всё, что письмо сообщает о сборке и
телефоне. Семь из этих полей — не продуктовое решение: версия, build, bundle ID,
версия системы, модель устройства, локаль и часовой пояс читаются у системы.
`BroadSupportEmailEnvironment.current()` читает их сам:

```swift
let configuration = BroadSupportEmailConfiguration(
    recipient: AppConfiguration.supportEmail,
    subject: AppTexts.supportSubject,
    greeting: .standard,
    appName: AppTexts.appName,
    appStoreVersion: appStoreVersion,
    environment: .current(),
    adaptyProfileID: profileID,
    backendUserID: userID,
    subscriptionStatus: status.supportSubscriptionValue,
    supportLogData: supportLogRecorder.makeSupportLogData()
)
```

Модель устройства — аппаратный идентификатор (`iPhone17,1`), а не маркетинговое
имя: только он надёжно отличает один телефон от другого, публичного
маркетингового имени в рантайме iOS нет. На симуляторе `uname` отвечает про
хостовый Mac, поэтому там берётся `SIMULATOR_MODEL_IDENTIFIER` — иначе каждое
письмо из debug-сборки приходит с «arm64».

Значение, которого система не сообщает, читается как
`BroadSupportEmailEnvironment.unavailableValue`, а не пустой строкой: пустое поле
в письме выглядит так, будто отправитель его стёр.

`adaptyProfileID`, `backendUserID` и `subscriptionStatus` остаются явными
параметрами — они приходят из монетизации, и письмо, тихо назвавшее чужой
аккаунт, хуже письма с «unavailable». Полный init со всеми полями остаётся: он
нужен, когда приложение сообщает не то, что читается у системы.

## Проверка

```bash
bash Scripts/module_gate.sh
```

Gate не создаёт test targets и не запускает реальные внешние операции.
