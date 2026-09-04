# BroadUIFlows agent rules

- Меняйте только этот repository.
- Модуль может импортировать `BroadCore` и `BroadMonetization`, но не
  `BroadExtensions`, Adapty или StoreKit.
- Domain/Data не импортируют SwiftUI; Presentation не импортирует provider SDK.
- View не получает зависимости через resolver и не создаёт use case/repository.
- Onboarding берёт количество страниц только из `OnboardingConfiguration.pages`.
- ATT разрешён только после реального появления первого onboarding-слайда;
  loader не запрашивает ATT, отключённый onboarding не планирует запрос.
- Rate Us и native review API запрещены внутри onboarding.
- Paywall показывает products в полученном порядке и не содержит product IDs или
  цен конкретного приложения.
- Product rows и primary actions не получают opacity/scale/pressed effect.
- Special Offer — только второй paywall; countdown идёт до конца
  активного окна, закрывает offer на нуле и не запускается по кругу.
- Интерактивные цели имеют общий минимум 44 points.
- Не добавляйте `Tests/`, test targets, XCTest, Swift Testing или UI tests.
- Gallery использует fixtures, не активирует SDK и не запускает purchase,
  restore, RU checkout или cancellation.
- Не добавляйте secrets, real IDs и raw error/URL/receipt/token/user/payment data.
- Public API меняется вместе с DocC, gallery, report, changelog и SemVer intent.
- Перед сдачей выполните `bash Scripts/module_gate.sh` и не заявляйте PASS иначе.
