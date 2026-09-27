#!/usr/bin/env bash

set -euo pipefail

module_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_root="$module_root/Sources/BroadUIFlows"
gallery_root="$module_root/Examples/BroadUIFlowsGallery"
violation_count=0
fixed_length_pattern='(pages\.count[[:space:]]*(==|!=|<=|>=|<|>)[[:space:]]*3\b|currentIndex[[:space:]]*(==|!=|<=|>=|<|>)[[:space:]]*2\b|pages[[:space:]]*\[[[:space:]]*2[[:space:]]*\]|0[[:space:]]*\.\.\.?[[:space:]]*2\b|0[[:space:]]*\.<[[:space:]]*3\b|ForEach[[:space:]]*\([[:space:]]*0[[:space:]]*\.<[[:space:]]*3\b)'

record_violation() {
    printf '%s\n' "$1"
    if [[ -n "$2" ]]; then
        printf '%s\n' "$2"
    fi
    violation_count=$((violation_count + 1))
}

scan_forbidden() {
    local title="$1"
    local pattern="$2"
    shift 2
    local output=""
    local status=0
    output="$(rg -n --pcre2 "$pattern" "$@")" || status=$?
    case "$status" in
        0) record_violation "$title" "$output" ;;
        1) ;;
        *) echo "UI contract scan could not run: $title"; exit "$status" ;;
    esac
}

require_pattern() {
    local title="$1"
    local file="$2"
    local pattern="$3"
    local status=0
    rg -q --pcre2 --multiline "$pattern" "$file" || status=$?
    case "$status" in
        0) ;;
        1) record_violation "$title" "${file#$module_root/}" ;;
        *) echo "UI contract requirement could not run: $title"; exit "$status" ;;
    esac
}

run_self_test() {
    local bad_source='if pages.count == 3 { currentIndex = 2 }'
    local bad_press='configuration.isPressed ? 0.8 : 1'
    if ! printf '%s\n' "$bad_source" | rg -q --pcre2 "$fixed_length_pattern"; then
        echo "SELF-TEST FAILED: fixed three-page source was not rejected."
        exit 1
    fi
    if ! printf '%s\n' "$bad_press" | rg -q --pcre2 '(configuration\.isPressed|\.(opacity|scaleEffect)[[:space:]]*\()'; then
        echo "SELF-TEST FAILED: synthetic press effect was not rejected."
        exit 1
    fi
    echo "UI contract self-test passed: synthetic regressions are rejected."
}

if [[ "${1:-}" == "--self-test" ]]; then
    run_self_test
    exit 0
fi

if ! command -v rg >/dev/null 2>&1; then
    echo "ripgrep is required for UI contract validation."
    exit 1
fi

scan_forbidden \
    "Domain/Data must not import SwiftUI:" \
    '^[[:space:]]*import[[:space:]]+SwiftUI' \
    "$source_root/Domain" "$source_root/Data" --glob '*.swift'

scan_forbidden \
    "Domain must not import UI, commerce, tracking or vendor frameworks:" \
    '^[[:space:]]*import[[:space:]]+(Adapty|AppKit|AppTrackingTransparency|StoreKit|StoreKitTest|SwiftUI|UIKit|WebKit)' \
    "$source_root/Domain" --glob '*.swift'

scan_forbidden \
    "Presentation must not import provider SDKs:" \
    '^[[:space:]]*import[[:space:]]+(Adapty|StoreKit)' \
    "$source_root/Presentation" --glob '*.swift'

scan_forbidden \
    "Views must not resolve dependencies:" \
    'resolver\.resolve[[:space:]]*\(' \
    "$source_root" --glob '*View*.swift'

scan_forbidden \
    "System fonts must be defined only in token files:" \
    '\.system[[:space:]]*\(' \
    "$source_root" --glob '*.swift' --glob '!*Tokens.swift'

scan_forbidden \
    "Onboarding must not hardcode a three-page boundary:" \
    "$fixed_length_pattern" \
    "$source_root/Domain/Onboarding" "$source_root/Presentation/Onboarding" --glob '*.swift'

scan_forbidden \
    "Onboarding must not contain Rate Us or native review requests:" \
    '(?i)\b(rate[[:space:]_-]*us|request[[:space:]_-]*review|SKStoreReviewController|AppStore\.requestReview|оценить|отзыв)\b' \
    "$source_root/Domain/Onboarding" "$source_root/Presentation/Onboarding" --glob '*.swift'

scan_forbidden \
    "Loader must not request or schedule ATT:" \
    '(AppTrackingTransparency|ATTrackingManager|TrackingAuthorization|requestTrackingAuthorization|firstSlideDidAppear)' \
    "$source_root/Presentation/Loadable" --glob '*.swift'

scan_forbidden \
    "Paywall UI must not contain hardcoded prices:" \
    '(?i)["\x27][^"\x27\r\n]{0,80}((\$|€|£|₽|USD|EUR|RUB)[[:space:]]*[0-9]|[0-9][[:space:]]*(€|£|₽|USD|EUR|RUB))' \
    "$source_root/Presentation/Paywall" "$source_root/Presentation/TokenPaywall" --glob '*.swift'

scan_forbidden \
    "Paywall UI must not contain hardcoded product identifiers:" \
    '(?i)(weekly|monthly|yearly|lifetime)[._-][A-Za-z0-9._-]+' \
    "$source_root/Presentation/Paywall" "$source_root/Presentation/TokenPaywall" --glob '*.swift'

scan_forbidden \
    "Paywall presentation must not filter, sort or truncate products; display order comes only from BroadPaywallProductOrder:" \
    '(?s)\b(products|paywall\.products|payload\.products)\b.{0,120}\.(filter|compactMap|sorted|prefix|suffix|dropFirst|dropLast)[[:space:]]*\(' \
    "$source_root/Presentation/Paywall" "$source_root/Presentation/TokenPaywall" --glob '*.swift'

scan_forbidden \
    "Product and primary actions must not react with opacity, scale or pressed effects:" \
    '(configuration\.isPressed|\.(opacity|scaleEffect|brightness|contrast|saturation|blur)[[:space:]]*\()' \
    "$source_root/Presentation/Paywall/BroadNoPressEffectButtonStyle.swift" \
    "$source_root/Presentation/Paywall/BroadSelectableProductRow.swift" \
    "$source_root/Presentation/Paywall/BroadPaywallPrimaryButton.swift"

require_pattern \
    "Paywall products must be shown longest subscription period first by default:" \
    "$source_root/Presentation/Paywall/BroadPaywallConfiguration.swift" \
    'productOrder:[[:space:]]*BroadPaywallProductOrder[[:space:]]*=[[:space:]]*\.longestPeriodFirst'

token_retry_body="$(awk '/public func retrySafely\(\)/,/^    }$/' "$source_root/Presentation/TokenPaywall/BroadTokenPaywallViewModel.swift")"
if [[ -z "$token_retry_body" ]]; then
    record_violation "Token paywall must keep retrySafely():" ""
elif grep -v '^[[:space:]]*//' <<<"$token_retry_body" | grep -q "purchaseSelectedProduct()"; then
    record_violation "Token retrySafely() must never start a new purchase:" "$token_retry_body"
fi

require_pattern \
    "OnboardingConfiguration.pages must remain the single page source:" \
    "$source_root/Domain/Onboarding/OnboardingConfiguration.swift" \
    'public[[:space:]]+let[[:space:]]+pages:[[:space:]]*\[OnboardingPageConfiguration\]'

require_pattern \
    "Last onboarding page must be derived from pages.count:" \
    "$source_root/Presentation/Onboarding/OnboardingViewModel.swift" \
    'currentIndex[[:space:]]*==[[:space:]]*configuration\.pages\.count[[:space:]]*-[[:space:]]*1'

require_pattern \
    "ATT eligibility must require the visible first page:" \
    "$source_root/Presentation/Onboarding/OnboardingViewModel.swift" \
    '(?s)isEligibleForTrackingAuthorization.*isFirstSlideVisible.*currentIndex[[:space:]]*==[[:space:]]*configuration\.pages\.startIndex'

require_pattern \
    "Invalid ATT delay must fail closed:" \
    "$source_root/Domain/Onboarding/OnboardingTrackingAuthorizationPolicy.swift" \
    'guard[[:space:]]+delay[[:space:]]*>[[:space:]]*\.zero[[:space:]]+else'

require_pattern \
    "ATT must revalidate current window visibility after the delay:" \
    "$source_root/Presentation/Onboarding/OnboardingViewModel.swift" \
    'validateCurrentWindowVisibility\?\(\)[[:space:]]*==[[:space:]]*true'

require_pattern \
    "Live window validation must require foreground active:" \
    "$source_root/Presentation/Onboarding/OnboardingWindowVisibilityView.swift" \
    'window\.windowScene\?\.activationState[[:space:]]*==[[:space:]]*\.foregroundActive'

require_pattern \
    "Standard onboarding must use the shared logic host:" \
    "$source_root/Presentation/Onboarding/BroadOnboardingView.swift" \
    'BroadOnboardingFlowHost\('

require_pattern \
    "Standard onboarding progress must iterate over configured pages:" \
    "$source_root/Presentation/Onboarding/BroadOnboardingView.swift" \
    'ForEach\(viewModel\.configuration\.pages\)'

require_pattern \
    "Interactive targets must share the 44-point minimum:" \
    "$source_root/Presentation/Shared/BroadInteractiveMetrics.swift" \
    'minimumHitDimension:[[:space:]]*CGFloat[[:space:]]*=[[:space:]]*44'

require_pattern \
    "Product rows must use the no-press button style:" \
    "$source_root/Presentation/Paywall/BroadSelectableProductRow.swift" \
    '\.buttonStyle\([[:space:]]*BroadNoPressEffectButtonStyle\(\)[[:space:]]*\)'

require_pattern \
    "Primary paywall actions must use the no-press button style:" \
    "$source_root/Presentation/Paywall/BroadPaywallPrimaryButton.swift" \
    '\.buttonStyle\([[:space:]]*BroadNoPressEffectButtonStyle\(\)[[:space:]]*\)'

require_pattern \
    "Shared in-flight action must show ProgressView:" \
    "$source_root/Presentation/Loadable/BroadActionButton.swift" \
    '(?s)configuration\.isInFlight.{0,180}ProgressView\([[:space:]]*\)'

require_pattern \
    "Product selection must honor busy and durable-pending guards:" \
    "$source_root/Presentation/Paywall/BroadPaywallView+Content.swift" \
    'viewModel\.canSelectProducts'

require_pattern \
    "Subscription paywall must render the complete products array in display order:" \
    "$source_root/Presentation/Paywall/BroadPaywallView+Content.swift" \
    'ForEach\(viewModel\.displayedProducts\(in:[[:space:]]*payload\),[[:space:]]*id:[[:space:]]*\\\.presentationID\)'

scan_forbidden \
    "Product order must keep every product:" \
    '\.(filter|compactMap|prefix|suffix|dropFirst|dropLast)[[:space:]]*\(' \
    "$source_root/Domain/Paywall" --glob '*.swift'

require_pattern \
    "Special Offer countdown must use a periodic visual timeline:" \
    "$source_root/Presentation/Paywall/BroadSpecialOfferMetadataView.swift" \
    '(?s)TimelineView\(\.periodic.*countdownAuthorization\.remainingTimeInterval'

require_pattern \
    "Special Offer screen waits for the authorized window end:" \
    "$source_root/Presentation/Paywall/BroadPaywallLifecycle.swift" \
    'countdown\.sleepUntilExpiration\(\)(?s:.*?)requestSpecialOfferExpirationClose\(\)(?s:.*?)onClose\(\)'

require_pattern \
    "Ready paywall must use the shared paywall lifecycle:" \
    "$source_root/Presentation/Paywall/BroadPaywallView.swift" \
    'BroadPaywallLifecycle\('

require_pattern \
    "Paywall host must use the shared paywall lifecycle:" \
    "$source_root/Presentation/Paywall/BroadPaywallHost.swift" \
    'BroadPaywallLifecycle\('

require_pattern \
    "Special Offer expiration blocks product selection and purchase:" \
    "$source_root/Presentation/Paywall/PaywallViewModel.swift" \
    'canPurchase(?s:.*?)countdown\.isExpired[[:space:]]*!=[[:space:]]*true(?s:.*?)canSelectProducts(?s:.*?)countdown\.isExpired[[:space:]]*!=[[:space:]]*true'

require_pattern \
    "Special Offer checkout reads the main paywall remote configuration:" \
    "$source_root/Presentation/Paywall/PaywallViewModel+Checkout.swift" \
    'authorization\.gateRemoteConfiguration'

require_pattern \
    "Every settings action must use the shared tap gate:" \
    "$source_root/Presentation/Settings/BroadSettingsHost.swift" \
    '(?s)restore: \{ state\.restore\(\).*manageSubscription: \{[[:space:]]*state\.perform.*openPrivacyPolicy: \{[[:space:]]*state\.perform.*openTerms: \{[[:space:]]*state\.perform.*contactSupport: \{[[:space:]]*state\.perform.*copyUserID: \{[[:space:]]*state\.perform.*rateApp: \{[[:space:]]*state\.perform.*shareApp: \{[[:space:]]*state\.perform'

require_pattern \
    "Settings restore must enter the shared tap gate:" \
    "$source_root/Presentation/Settings/BroadSettingsHost.swift" \
    '(?s)func restore\(\) \{[[:space:]]*perform \{'

require_pattern \
    "Settings tap gate must lock for 400 milliseconds:" \
    "$source_root/Presentation/Settings/BroadSettingsHost.swift" \
    'nextActionAt = Date\(\)\.addingTimeInterval\(0\.4\)'

require_pattern \
    "Update versions must parse numeric components:" \
    "$source_root/Domain/AppUpdate/BroadAppVersion.swift" \
    '(?s)let number = Int\(part\).*if left != right \{[[:space:]]*return left < right'

require_pattern \
    "First successful update lookup must store the larger baseline:" \
    "$source_root/Application/AppUpdate/BroadAppUpdateChecker.swift" \
    '(?s)initialBaseline\(installed: installed, store: listing\.version\).*baselineStore\.save\(baseline\.rawValue, for: bundleID\)'

require_pattern \
    "A changed installed version must reset the update baseline:" \
    "$source_root/Domain/AppUpdate/BroadAppUpdateContracts.swift" \
    '(?s)previousInstall != installed \{[[:space:]]*return installed'

require_pattern \
    "The update checker must remember the installed version:" \
    "$source_root/Application/AppUpdate/BroadAppUpdateChecker.swift" \
    'baselineStore\.saveInstalledVersion\(installed\.rawValue, for: bundleID\)'

require_pattern \
    "Update lookup must query the bundle ID:" \
    "$source_root/Data/AppUpdate/BroadAppStoreLookupClient.swift" \
    'URLQueryItem\(name: "bundleId", value: bundleID\)'



for gallery_contract in \
    'Onboarding' \
    'Loadable states' \
    'Subscription paywall' \
    'Special Offer paywall' \
    'Token paywall' \
    'Settings' \
    'App update alert' \
    'INFOPLIST_KEY_BroadAppsFixtureOnly:[[:space:]]+YES'
do
    if ! rg -q -- "$gallery_contract" "$gallery_root"; then
        record_violation "Gallery scenario is missing: $gallery_contract" "Examples/BroadUIFlowsGallery"
    fi
done

if ((violation_count > 0)); then
    echo "UI contract validation failed: $violation_count violation(s)."
    exit 1
fi

echo "BroadUIFlows source and gallery contracts passed."
