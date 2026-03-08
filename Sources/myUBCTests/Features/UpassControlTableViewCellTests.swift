@testable import myUBC
import XCTest

@MainActor
final class UpassControlTableViewCellTests: XCTestCase, ViewFixtureLoading {
    func testDidSwitchShowsAlertWhenNotificationPermissionIsDenied() throws {
        let cell: UpassControlTableViewCell = try loadViewFromNib(named: UpassControlTableViewCell.nib)
        let delegate = UpassTableViewControllerDelegateSpy()
        delegate.authorizationResult = false
        cell.tableViewDelegate = delegate
        cell.reminderSwitch.isOn = true

        cell.didSwitch(cell.reminderSwitch as Any)

        XCTAssertFalse(cell.reminderSwitch.isOn)
        XCTAssertTrue(delegate.showAlertCalled)
    }

    func testDidSetupReminderPassesSelectedScheduleToDelegate() throws {
        let cell: UpassControlTableViewCell = try loadViewFromNib(named: UpassControlTableViewCell.nib)
        let delegate = UpassTableViewControllerDelegateSpy()
        cell.tableViewDelegate = delegate
        cell.advanceStepper.value = 18
        cell.timePicker.selectedSegmentIndex = 2

        cell.didSetupReminder(cell.setupBtn as Any)

        XCTAssertEqual(delegate.capturedDateComponents?.day, 18)
        XCTAssertEqual(delegate.capturedDateComponents?.hour, 15)
        XCTAssertEqual(delegate.capturedDateComponents?.minute, 0)
    }
}
