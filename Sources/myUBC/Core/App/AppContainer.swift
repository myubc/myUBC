//
//  AppContainer.swift
//  myUBC
//
//  Created by myUBC on 2020-03-07.
//

import UIKit

final class AppContainer {
    let networkClient: NetworkClient
    let cacheStore: CacheStore
    let pendingRouteStore: PendingAppRouteStore
    let foodService: FoodServicing
    let dataHub: DataHub
    let foodDetailService: FoodDetailServicing
    let parkingService: ParkingServicing
    let infoService: InfoServicing
    let calendarService: CalendarServicing
    let libraryService: LibraryServicing
    let sanityCheckService: SanityCheckServicing

    init(
        networkClient: NetworkClient = NetworkClient(),
        cacheStore: CacheStore = CacheStore(),
        pendingRouteStore: PendingAppRouteStore = PendingAppRouteStore(),
        foodService: FoodServicing? = nil,
        foodDetailService: FoodDetailServicing? = nil,
        parkingService: ParkingServicing? = nil,
        infoService: InfoServicing? = nil,
        calendarService: CalendarServicing? = nil,
        libraryService: LibraryServicing? = nil,
        sanityCheckService: SanityCheckServicing? = nil
    ) {
        self.networkClient = networkClient
        self.cacheStore = cacheStore
        self.pendingRouteStore = pendingRouteStore
        self.foodService = foodService ?? FoodService(client: networkClient, cache: cacheStore)
        self.foodDetailService = foodDetailService ?? FoodDetailService(client: networkClient, cache: cacheStore)
        self.parkingService = parkingService ?? ParkingService(client: networkClient, cache: cacheStore)
        self.infoService = infoService ?? InfoService(client: networkClient, cache: cacheStore)
        self.calendarService = calendarService ?? CalendarService(client: networkClient, cache: cacheStore)
        self.libraryService = libraryService ?? LibraryService(client: networkClient, cache: cacheStore)
        self.sanityCheckService = sanityCheckService ?? SanityCheckService(client: networkClient)
        dataHub = DataHub(
            food: self.foodService,
            parking: self.parkingService,
            info: self.infoService,
            library: self.libraryService,
            calendar: self.calendarService
        )
    }
}

@MainActor
protocol AppContainerInjectable: AnyObject {
    var container: AppContainer? { get set }
}

@MainActor
enum AppContainerInjector {
    static func inject(_ container: AppContainer, into root: UIViewController) {
        if let injectable = root as? AppContainerInjectable {
            injectable.container = container
        }

        if let nav = root as? UINavigationController {
            nav.viewControllers.forEach { inject(container, into: $0) }
        }

        if let tab = root as? UITabBarController {
            tab.viewControllers?.forEach { inject(container, into: $0) }
        }

        root.children.forEach { inject(container, into: $0) }
    }
}
