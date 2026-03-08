@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

final class FeatureModelAndBadgeTests: XCTestCase {
    func testLibraryModelSignalsAndEquipmentStatusArchiveRoundTrip() throws {
        let date = Date(timeIntervalSince1970: 1000)
        let status = EquipmentStatus(isAvailable: true, referenceNo: "R1", date: date, note: "Ready")
        let equipment = Equipment(type: .Mac1, name: "MacBook", location: "IKB", total: "2", details: [status])
        let model = LibraryModel()
        model.iphones1 = [equipment]
        model.macs1 = [equipment]

        let data = try NSKeyedArchiver.archivedData(withRootObject: model, requiringSecureCoding: false)
        let decoded = try XCTUnwrap(NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? LibraryModel)
        XCTAssertEqual(decoded.iphones1.first?.name, "MacBook")
        XCTAssertEqual(decoded.macs1.first?.details.first?.referenceNo, "R1")
    }

    func testFeatureFlagsLoadFromBundleAndDefaultsFallback() throws {
        let tempRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let bundleURL = tempRoot.appendingPathComponent("Flags.bundle", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let infoPlist: [String: Any] = [
            "CFBundleIdentifier": "myubc.tests.flags",
            "CFBundleName": "Flags",
            "CFBundlePackageType": "BNDL",
            "CFBundleVersion": "1",
            "CFBundleShortVersionString": "1.0"
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: infoPlist, format: .xml, options: 0)
        try plistData.write(to: bundleURL.appendingPathComponent("Info.plist"))

        let flags: [String: Any] = [
            "showFood": false,
            "showCharger": true,
            "showCalendar": false,
            "showParking": true,
            "showUpass": false,
            "showInfo": true,
            "enableWidgets": false
        ]
        let flagsData = try PropertyListSerialization.data(fromPropertyList: flags, format: .xml, options: 0)
        try flagsData.write(to: bundleURL.appendingPathComponent("FeatureFlags.plist"))

        let customBundle = try XCTUnwrap(Bundle(url: bundleURL))
        let loaded = FeatureFlags.load(bundle: customBundle)
        XCTAssertFalse(loaded.showFood)
        XCTAssertFalse(loaded.showCalendar)
        XCTAssertFalse(loaded.enableWidgets)

        let fallback = FeatureFlags.load(bundle: Bundle(for: Self.self))
        XCTAssertEqual(fallback.showFood, true)
        XCTAssertEqual(fallback.enableWidgets, true)
    }
}
