# Contributor guide

## Boundary

BroadUIFlows зависит только от compatible `BroadCore`, `BroadMonetization` и
declared Swinject. UI не импортирует Adapty/StoreKit и не решает финансовую
authority самостоятельно.

## Layout

```text
Sources/BroadUIFlows/Domain         UI-flow models and protocols
Sources/BroadUIFlows/Application    coordinators, DI and app-facing services
Sources/BroadUIFlows/Data           UI-owned persistence adapters
Sources/BroadUIFlows/Presentation   SwiftUI screens and view models
Examples/BroadUIFlowsGallery        fixture-only iPhone gallery
Scripts                             structural and executable source contracts
```

## Invariants

- `OnboardingConfiguration.pages` — единственный источник числа слайдов.
- ATT только после visible first slide и foreground-active window; loader не ATT.
- Стандартный и custom onboarding используют общий lifecycle host.
- Rate Us не находится в onboarding.
- Presentation не импортирует provider SDK и не получает resolver.
- Paywall не фильтрует, не сортирует и не схлопывает products.
- UI не содержит app-owned price/SKU/placement и не создаёт raw product.
- Special Offer countdown не является eligibility/expiration boundary.
- Product/primary actions не имеют pressed visual effect; hit target ≥ 44 points.

## Public API

Additive API — minor, compatible fix — patch, breaking API/behavior — major.

```bash
bash Scripts/generate_public_api_report.sh --update
```

## Contract checks

Source contract checks работают с production-файлами и возвращают nonzero при
регрессии. XCTest/Swift Testing, `Tests/` и реальные operations не добавляются.

## Release

Release notes отвечают: **Что изменилось и почему?**

1. Обновите changelog/docs/gallery/API report.
2. Пройдите clean `bash Scripts/module_gate.sh`.
3. Создайте tag `x.y.z` и дождитесь release workflow.
4. Обновите integration repository на новый tag.
5. После integration PASS обновите compatibility matrix и public docs.
