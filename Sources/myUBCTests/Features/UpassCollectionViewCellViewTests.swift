@testable import myUBC
import XCTest

@MainActor
final class UpassCollectionViewCellViewTests: XCTestCase, ViewFixtureLoading {
    override func tearDown() {
        ReminderStateStore.clearUpassReminder()
        super.tearDown()
    }

    func testReminderLabelDefaultState() throws {
        let cell: UpassCollectionViewCell = try loadViewFromNib(named: UpassCollectionViewCell.nib)
        cell.reminderLabelDefault()

        XCTAssertTrue(cell.reminderStatusLabel.attributedText?.string.contains("Reminder Not Set Up") == true)
    }

    func testReminderLabelOnState() throws {
        ReminderStateStore.setUpassReminder(DateComponents(timeZone: .current, day: 16, hour: 9, minute: 0))

        let cell: UpassCollectionViewCell = try loadViewFromNib(named: UpassCollectionViewCell.nib)
        cell.reminderLabel()

        XCTAssertTrue(cell.reminderStatusLabel.attributedText?.string.contains("Reminder On") == true)
    }
}
