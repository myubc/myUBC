@testable import myUBC
import Foundation

@MainActor
final class CheckoutProtocolSpy: CheckoutProtocol {
    var isGrantedNotificationAccess = false
    var showAlertCalled = false

    func accessCheck(completion: @escaping () -> Void) {
        completion()
    }

    func startTimer(timeInterval _: Double) {}
    func showAlert() {
        showAlertCalled = true
    }

    func stopTimer() {}
    func updateTable() {}
    func showLoanPolicy() {}
}
