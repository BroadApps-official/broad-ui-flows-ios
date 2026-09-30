# Naming paywall products

Use ``BroadPaywallPlan/name`` for a custom subscription screen and
``BroadTokenPackage/name`` for a custom token store. The ready views use the
same names. ``BroadPaywallPlan/title`` and ``BroadTokenPackage/title`` retain
the raw App Store product name for compatibility. Built-in `.standard`, `.english`
and `.russian` copy enables the new names in its own language.

Custom copy created with the original three-string `Products` initializer leaves
`planNames` / `tokenName` as `nil`. Both models and ready views then display
`title ?? fallbackTitle`, exactly as in 6.5.0. Custom Russian copy never receives
English names implicitly. To opt in, supply localized fields when constructing
your copy's products:

```swift
let products = BroadPaywallCopy.Products(
    fallbackTitle: "Премиум-доступ",
    unavailablePriceTitle: "Цена недоступна",
    selectedAccessibilityValue: "Выбрано",
    planNames: .russian
)
let tokenProducts = BroadTokenPaywallCopy.Products(
    fallbackTitle: "Пакет токенов",
    unavailablePriceTitle: "Цена недоступна",
    selectedAccessibilityValue: "Выбрано",
    tokenName: BroadCountedNameCopy(
        one: "токен", few: "токена", many: "токенов", usesRussianPluralRules: true
    )
)
```

Pass these products to the corresponding copy. You can provide your own
``BroadPaywallPlanNameCopy`` / ``BroadCountedNameCopy`` instead. An explicit
`planNames: nil` or `tokenName: nil` preserves title-based presentation.
The price formatter's locale does not choose the language of names.

When enabled, subscription names come only from `subscriptionPeriod` and
``BroadPaywallCopy/Products/planNames``. One day, week, month, and year use
Daily, Weekly, Monthly, and Yearly in English. Other positive counts use
localized noun forms, such as `3 Months` or `2 Weeks`.
``BroadPaywallCopy/english`` and ``BroadPaywallCopy/standard`` are equivalent;
``BroadPaywallCopy/russian`` supplies the Russian names.
Unknown periods and products without a subscription period use
``BroadPaywallCopy/Products/fallbackTitle``. Product IDs never determine a
subscription name.

When enabled, token names come from the backend `tokenAmount` supplied to
``BroadTokenPaywallHost`` or ``BroadTokenPaywallView``, or from a leading decimal quantity in the product
ID when that amount is absent. For example, `50_Tokens_9.99`, `2000_tokens`,
and `100tokens` display 50, 2000, and 100 tokens. The ID-derived quantity is
available as ``BroadTokenPackage/displayTokenCount`` only for display.
``BroadTokenPackage/tokens`` remains the backend quantity and is the only
quantity used for package value comparisons. An ID without a leading quantity
uses ``BroadTokenPaywallCopy/Products/fallbackTitle``. Copy supplies the token
noun forms, including Russian `токен`, `токена`, and `токенов`.

With `tokenName == nil`, the ID is not parsed and `displayTokenCount` contains
only a supplied backend quantity. Backend zero or an unknown quantity uses the
fallback name when names are enabled; zero never falls back to the ID.
