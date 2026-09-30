import BroadMonetization

public extension BroadPaywallConfiguration {
    /// Preserves the initializer from releases before configurable product ordering.
    init(
        placementID: PlacementID,
        defaultSelection: BroadPaywallDefaultSelection? = nil,
        access: BroadPaywallAccessConfiguration = BroadPaywallAccessConfiguration(),
        copy: BroadPaywallCopy = .standard,
        legalLinks: [BroadPaywallLegalLink] = [],
        specialOfferCopy: BroadPaywallSpecialOfferCopy = .english,
        specialOfferAuthorization: SpecialOfferPresentationAuthorization? = nil
    ) {
        self.init(
            placementID: placementID, defaultSelection: defaultSelection, access: access,
            copy: copy, legalLinks: legalLinks, specialOfferCopy: specialOfferCopy,
            specialOfferAuthorization: specialOfferAuthorization, productOrder: .longestPeriodFirst
        )
    }
}
