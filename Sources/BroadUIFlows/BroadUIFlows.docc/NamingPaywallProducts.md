# Naming paywall products

Use ``BroadPaywallPlan/name`` for a custom subscription screen and
``BroadTokenPackage/name`` for a custom token store. The ready views use the
same names. ``BroadPaywallPlan/title`` and ``BroadTokenPackage/title`` retain
the raw App Store product name for compatibility; it may be an internal ID and
must not appear in user-facing UI.

Subscription names come only from `subscriptionPeriod` and
``BroadPaywallCopy/Products/planNames``. One day, week, month, and year use
Daily, Weekly, Monthly, and Yearly in English. Other positive counts use
localized noun forms, such as `3 Months` or `2 Weeks`.
``BroadPaywallCopy/english`` and ``BroadPaywallCopy/standard`` are equivalent;
``BroadPaywallCopy/russian`` supplies the Russian names.
Unknown periods and products without a subscription period use
``BroadPaywallCopy/Products/fallbackTitle``. Product IDs never determine a
subscription name.

Token names come from the backend `tokenAmount` supplied to
``BroadTokenPaywallHost`` or ``BroadTokenPaywallView``, or from a leading decimal quantity in the product
ID when that amount is absent. For example, `50_Tokens_9.99`, `2000_tokens`,
and `100tokens` display 50, 2000, and 100 tokens. The ID-derived quantity is
available as ``BroadTokenPackage/displayTokenCount`` only for display.
``BroadTokenPackage/tokens`` remains the backend quantity and is the only
quantity used for package value comparisons. An ID without a leading quantity
uses ``BroadTokenPaywallCopy/Products/fallbackTitle``. Copy supplies the token
noun forms, including Russian `токен`, `токена`, and `токенов`.
