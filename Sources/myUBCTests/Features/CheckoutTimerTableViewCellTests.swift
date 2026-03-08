@testable import myUBC
import XCTest

@MainActor
final class CheckoutTimerTableViewCellTests: XCTestCase, ViewFixtureLoading {
    func testSwitchDisablesReminderAndShowsAlertWhenNotificationPermissionIsDenied() throws {
        let cell: CheckoutTimerTableViewCell = try loadViewFromNib(named: Constants.chargerCheckoutNib_timerCell)
        let delegate = CheckoutProtocolSpy()
        delegate.isGrantedNotificationAccess = false
        cell.timerProtocol = delegate
        cell.switchBtn.isOn = true

        cell.didSwitchBtn(cell.switchBtn as Any)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertFalse(cell.switchBtn.isOn)
        XCTAssertTrue(delegate.showAlertCalled)
    }

    func testSwitchEnablesControlsWhenNotificationPermissionIsGranted() throws {
        let cell: CheckoutTimerTableViewCell = try loadViewFromNib(named: Constants.chargerCheckoutNib_timerCell)
        let delegate = CheckoutProtocolSpy()
        delegate.isGrantedNotificationAccess = true
        cell.timerProtocol = delegate
        cell.switchBtn.isOn = true

        cell.didSwitchBtn(cell.switchBtn as Any)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertTrue(cell.timerPicker.isEnabled)
        XCTAssertTrue(cell.startBtn.isEnabled)
    }
}
