# Changelog

Все заметные изменения BroadUIFlows фиксируются здесь с объяснением: что изменилось и почему.

## Unreleased

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
