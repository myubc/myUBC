import UIKit

@MainActor
enum AppScreenFactory {
    struct ChargerDetailContext {
        let title: String
        let selectedIndex: Int
        let content: [Equipment]
        let isInIKB: Bool
    }

    static func makeRoot(container: AppContainer) -> UIViewController {
        let splash = SplashViewController()
        splash.container = container
        return splash
    }

    static func makeCharger(
        container: AppContainer?,
        preloadedLibraryModel: LibraryModel?,
        preloadedLastUpdated: Date?,
        presentationDelegate: UIAdaptivePresentationControllerDelegate?
    )
        -> UINavigationController
    {
        let charger = ChargerTableViewController()
        charger.container = container
        charger.preloadedLibraryModel = preloadedLibraryModel
        charger.preloadedLastUpdated = preloadedLastUpdated

        let navController = UINavigationController(rootViewController: charger)
        navController.navigationBar.prefersLargeTitles = true
        navController.navigationBar.topItem?.title = "Charger Status"
        navController.navigationBar.isTranslucent = true
        navController.presentationController?.delegate = presentationDelegate
        return navController
    }

    static func makeInfo(container: AppContainer?) -> UINavigationController {
        let notice = NoticeTableViewController()
        notice.container = container

        let navController = UINavigationController(rootViewController: notice)
        navController.navigationBar.prefersLargeTitles = true
        navController.navigationBar.topItem?.title = "Bulletin"
        navController.navigationBar.isTranslucent = true
        return navController
    }

    static func makeLegal(caseIndex: Int) -> UINavigationController {
        let legal = LegalViewController()
        legal.legalCase = caseIndex

        let navController = UINavigationController(rootViewController: legal)
        navController.view.backgroundColor = .systemBackground
        navController.navigationBar.prefersLargeTitles = false
        navController.navigationBar.isTranslucent = true
        return navController
    }

    static func makeChargerDetail(
        container: AppContainer?,
        libraryModel: LibraryModel,
        context: ChargerDetailContext
    )
        -> ChargerDetailViewController
    {
        let detail = ChargerDetailViewController()
        detail.container = container
        detail.libraryModel = libraryModel
        detail.isInIKB = context.isInIKB
        detail.model = ChargerDetailViewModel(
            title: context.title,
            selectedIndex: context.selectedIndex,
            content: context.content
        )
        return detail
    }

    static func makeChargerCheckout() -> CheckoutTableViewController {
        let checkout = CheckoutTableViewController()
        checkout.navigationItem.title = "Details"
        return checkout
    }
}
