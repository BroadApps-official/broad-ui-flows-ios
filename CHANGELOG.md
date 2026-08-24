# Changelog

Все заметные изменения BroadUIFlows фиксируются здесь с объяснением: что изменилось и почему.

## Unreleased

Пока нет изменений.

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
