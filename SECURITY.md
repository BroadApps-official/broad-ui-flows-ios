# Security policy

Не публикуйте Adapty keys, backend URLs/tokens, product/placement IDs конкретного
app, receipts/JWS, user/payment data и raw SDK errors. Для уязвимости без
безопасного public reproduction используйте GitHub Security Advisory.

UI не подтверждает purchase, entitlement или balance самостоятельно. Pending
financial state не превращается в success/failure и не повторяет operation без
authoritative результата из BroadMonetization/app backend.
