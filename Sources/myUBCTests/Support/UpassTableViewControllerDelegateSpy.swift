@testable import myUBC
import Foundation

@MainActor
final class UpassTableViewControllerDelegateSpy: UpassTableViewControllerProtocol {
    var authorizationResult = true
    var showAlertCalled = false
    var capturedDateComponents: DateComponents?

    func showLegal() {}
    func showRenew() {}
    func showPrivacy() {}

    func checkNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        completion(authorizationResult)
    }

    func showAlert() {
        showAlertCalled = true
    }

    func setupNotification(forDay: DateComponents) {
        capturedDateComponents = forDay
    }

    func removeNotification(callback: @escaping (Bool) -> Void) {
        callback(true)
    }
}
