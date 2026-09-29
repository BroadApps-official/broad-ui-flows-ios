import Foundation

extension BroadTokenPaywallViewModel {
    func startCloseDelay() {
        let delay = configuration.closeDelay
        guard delay > 0 else {
            isCloseAvailable = true
            return
        }

        isCloseAvailable = false
        closeAvailabilityTask?.cancel()
        closeAvailabilityTask = Task { @MainActor [weak self] in
            do {
                try await ContinuousClock().sleep(for: .seconds(delay))
            } catch {
                return
            }
            guard let self, !Task.isCancelled, isVisible else {
                return
            }
            closeAvailabilityTask = nil
            isCloseAvailable = true
        }
    }

    func cancelCloseDelay() {
        closeAvailabilityTask?.cancel()
        closeAvailabilityTask = nil
        isCloseAvailable = configuration.closeDelay == 0
    }
}
