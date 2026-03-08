@testable import myUBC
import Foundation
import UIKit
import WebKit
import XCTest

@MainActor
final class ViewModelTests: XCTestCase {
    func testFoodListViewModelSuccessAndFailure() async {
        let location = FoodLocation(name: "A", isOpen: true, statusText: "Open")
        let success = CachedValue(
            value: [location],
            isStale: false,
            isFromCache: true,
            hadNetworkError: false,
            lastUpdated: Date(),
            networkError: nil
        )
        let service = TestDoubles.MockFoodService(result: .success(success))
        let viewModel = FoodListViewModel(service: service)

        let ok = await viewModel.load()
        guard case .success = ok else { return XCTFail("Expected success") }
        XCTAssertEqual(viewModel.foods.count, 1)
        XCTAssertTrue(viewModel.lastResultWasCached)
        XCTAssertNotNil(viewModel.banner)

        let failed = FoodListViewModel(service: TestDoubles.MockFoodService(result: .failure(.offline)))
        let bad = await failed.load()
        guard case .failure = bad else { return XCTFail("Expected failure") }
        XCTAssertEqual(failed.banner?.style, .offline)
    }

    func testFoodDetailViewModelSuccessAndFailure() async {
        let detail = FoodDetailItem(description: "Summary", carryover: false, ubccard: true, mealplan: true, images: [])
        let cached = CachedValue(
            value: detail,
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: Date(),
            networkError: nil
        )
        let vm = FoodDetailViewModel(service: TestDoubles.MockFoodDetailService(result: .success(cached)))
        let success = await vm.load(url: "https://food.ubc.ca/places/sample/")
        guard case .success = success else { return XCTFail("Expected success") }
        XCTAssertEqual(vm.detail?.description, "Summary")

        let failing = FoodDetailViewModel(service: TestDoubles.MockFoodDetailService(result: .failure(.invalidResponse)))
        let failure = await failing.load(url: "https://food.ubc.ca/places/sample/")
        guard case .failure = failure else { return XCTFail("Expected failure") }
        XCTAssertNil(failing.detail)
    }

    func testCalendarNoticeParkingAndChargerViewModels() async {
        let date = Date()
        let event = CampusCalendarEvent(date: date, events: [CampusEventDetail(isImportant: true, eventDescription: "A")])
        let calendarValue = CachedValue(
            value: [event],
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: date,
            networkError: nil
        )
        let calendarVM = CalendarViewModel(service: TestDoubles.MockCalendarService(result: .success(calendarValue)))
        _ = await calendarVM.load(visibleMonth: date)
        XCTAssertEqual(calendarVM.events.count, 1)

        let notice = CampusNotification(title: "t", time: "now", content: "c", notificationID: "id")
        let noticeValue = CachedValue(
            value: [notice],
            isStale: true,
            isFromCache: true,
            hadNetworkError: true,
            lastUpdated: date,
            networkError: .offline
        )
        let noticeVM = NoticeViewModel(service: TestDoubles.MockInfoService(result: .success(noticeValue)))
        _ = await noticeVM.load(forceRefresh: true)
        XCTAssertEqual(noticeVM.notifications.first?.notificationID, "id")
        XCTAssertEqual(noticeVM.banner?.style, .offline)

        let lot = ParkingAnnotation(lotName: .north, status: [.good, .limited])
        let parkingValue = CachedValue(
            value: [lot],
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: date,
            networkError: nil
        )
        let parkingVM = ParkingViewModel(service: TestDoubles.MockParkingService(result: .success(parkingValue)))
        _ = await parkingVM.load()
        XCTAssertEqual(parkingVM.lots.first?.lotName, .north)

        let model = LibraryModel()
        model.iphones1 = [Equipment(type: .IPhone1, name: "iPhone 15", location: "IKB", total: "1", details: [])]
        let chargerValue = CachedValue(
            value: model,
            isStale: false,
            isFromCache: false,
            hadNetworkError: false,
            lastUpdated: date,
            networkError: nil
        )
        let chargerVM = ChargerViewModel(service: TestDoubles.MockLibraryService(result: .success(chargerValue)))
        _ = await chargerVM.load()
        XCTAssertEqual(chargerVM.model.iphones1.first?.name, "iPhone 15")
    }
}
