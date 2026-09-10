# Changelog

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
