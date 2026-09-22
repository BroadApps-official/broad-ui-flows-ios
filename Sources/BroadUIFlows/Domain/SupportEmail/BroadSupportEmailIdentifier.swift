/// An additional account identifier supplied by the host for support diagnostics.
///
/// Include the identifier used to credit tokens when it differs from the standard
/// backend, Adapty or device IDs. Pass identifiers for the current account only.
public struct BroadSupportEmailIdentifier: Equatable, Sendable {
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}
