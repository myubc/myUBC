//
//  AppDelegate.swift
//  myUBC
//
//  Created by myUBC on 2020-01-20.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    private let generatorNotice = UINotificationFeedbackGenerator()
    private let generatorImpact = UIImpactFeedbackGenerator(style: .light)
    fileprivate lazy var appContainer: AppContainer = UITestLaunchConfiguration.makeAppContainer()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UITestLaunchConfiguration.prepareRuntime()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.getPendingNotificationRequests { requests in
            self.updateFlag(requests: requests)
        }
        generatorImpact.prepare()
        generatorNotice.prepare()

        // increment app launch count (used for beta invite eligibility)
        let launches = UserDefaults.standard.integer(forKey: Constants.userdefault_launchCount) + 1
        UserDefaults.standard.set(launches, forKey: Constants.userdefault_launchCount)

        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    )
        -> UISceneConfiguration
    {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    func applicationWillEnterForeground(_ application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.getPendingNotificationRequests { requests in
            self.updateFlag(requests: requests)
        }
    }

    func updateFlag(requests: [UNNotificationRequest]) {
        ReminderStateStore.syncPendingChargerTimer(requests: requests)
    }

    // MARK: - Push Notification

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let identifier = notification.request.identifier
        let categoryIdentifier = notification.request.content.categoryIdentifier

        if identifier == Constants.notification_timer_identify {
            ReminderStateStore.clearChargerTimer()
        }

        if identifier == Constants.notification_timer_identify || categoryIdentifier == Constants.notification_upass_identifier {
            completionHandler([.badge])
            return
        }

        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.actionIdentifier

        if response.notification.request.identifier == Constants.notification_timer_identify {
            ReminderStateStore.clearChargerTimer()
        }

        if identifier == Constants.notification_timer_action {
            let content = UNMutableNotificationContent()
            content.title = "Return Your Charger"
            content.subtitle = "Final Reminder"
            content.body = "Overdue fines of $1 per hour may apply. Confirm current lending terms with UBC Library staff."
            content.sound = UNNotificationSound.defaultCritical

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 300,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: Constants.notification_timer_identify,
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(
                request, withCompletionHandler: { _ in
                    ReminderStateStore.setChargerTimer(targetDate: Date().addingTimeInterval(300))
                }
            )
        }

        if response.notification.request.content.categoryIdentifier == Constants.notification_upass_identifier {
            if
                UIApplication.shared.applicationState == .active,
                let presenter = currentTopViewController()
            {
                AppRoutePresenter.present(.reminders, from: presenter)
            } else {
                Task {
                    await appContainer.pendingRouteStore.set(.reminders)
                }
            }
        }

        completionHandler()
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        // myubc://main?event=new-layout&source=appstore
        if Self.shouldResetWhatsNewVersion(for: url) {
            UserDefaults.standard.setValue("n/a", forKey: "whats_new_version")
        }
        return true
    }

    static func shouldResetWhatsNewVersion(for url: URL) -> Bool {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return false }
        return queryItems.contains(where: { $0.name == "event" })
    }

    private func currentKeyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
    }

    private func currentTopViewController() -> UIViewController? {
        guard let root = currentKeyWindow()?.rootViewController else { return nil }
        var current = root
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let root: UIViewController
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            root = AppScreenFactory.makeRoot(container: delegate.appContainer)
        } else {
            root = UIViewController()
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = root
        self.window = window
        window.makeKeyAndVisible()
    }
}

@MainActor
enum AppVersionCoordinator {
    static let whatsNewVersionKey = "whats_new_version"

    static var currentVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    static func shouldPresentWhatsNew(currentVersion: String?, lastSeenVersion: String?) -> Bool {
        guard let currentVersion, !currentVersion.isEmpty else {
            return false
        }
        return lastSeenVersion != currentVersion
    }

    static func presentWhatsNewIfNeeded(from presenter: UIViewController) {
        let current = currentVersion
        let lastSeenVersion = UserDefaults.standard.string(forKey: whatsNewVersionKey)
        guard shouldPresentWhatsNew(currentVersion: current, lastSeenVersion: lastSeenVersion) else {
            return
        }
        let whatsnewView = WhatsNewTableViewController(nibName: "WhatsNewTableViewController", bundle: nil)
        presenter.present(whatsnewView, animated: true, completion: {
            UserDefaults.standard.setValue(current, forKey: whatsNewVersionKey)
        })
    }

    static func check(
        with service: SanityCheckServicing?,
        onResult: @escaping @MainActor (SanityCheckResult) -> Void = { _ in },
        onNewVersion: @escaping @MainActor () -> Void,
        onNoNewVersion: @escaping @MainActor () -> Void
    ) {
        guard let service else {
            onNoNewVersion()
            return
        }

        Task { @MainActor in
            let result = await service.fetch()
            switch result {
            case let .success(check):
                onResult(check)
                if check.isNewVersionAvailable {
                    onNewVersion()
                } else {
                    onNoNewVersion()
                }
            case .failure:
                onNoNewVersion()
            }
        }
    }
}

enum ReminderStateStore {
    private static let defaults = UserDefaults.standard

    static func hasPendingUpassReminder() -> Bool {
        defaults.bool(forKey: Constants.userdefault_upasscheck)
    }

    static func upassReminderComponents() -> DateComponents? {
        guard let data = defaults.data(forKey: Constants.userdefault_upass_combo) else {
            return nil
        }
        return try? JSONDecoder().decode(DateComponents.self, from: data)
    }

    static func setUpassReminder(_ components: DateComponents) {
        defaults.set(true, forKey: Constants.userdefault_upasscheck)
        if let data = try? JSONEncoder().encode(components) {
            defaults.set(data, forKey: Constants.userdefault_upass_combo)
        }
    }

    static func clearUpassReminder() {
        defaults.set(false, forKey: Constants.userdefault_upasscheck)
        defaults.removeObject(forKey: Constants.userdefault_upass_combo)
    }

    static func pendingReminderCount(now: Date = Date()) -> Int {
        var count = 0
        if hasPendingUpassReminder() {
            count += 1
        }
        if hasPendingChargerTimer(now: now) {
            count += 1
        }
        return count
    }

    static func hasPendingChargerTimer(now: Date = Date()) -> Bool {
        if let targetDate = chargerTimerTargetDate(now: now) {
            return targetDate > now
        }
        return defaults.bool(forKey: Constants.userdefault_timerCheck)
    }

    static func chargerTimerTargetDate(now: Date = Date()) -> Date? {
        guard let targetDate = defaults.object(forKey: Constants.userdefault_key_timer) as? Date else {
            return nil
        }
        guard targetDate > now else {
            clearChargerTimer()
            return nil
        }
        return targetDate
    }

    static func setChargerTimer(targetDate: Date) {
        defaults.set(true, forKey: Constants.userdefault_timerCheck)
        defaults.set(targetDate, forKey: Constants.userdefault_key_timer)
    }

    static func clearChargerTimer() {
        defaults.set(false, forKey: Constants.userdefault_timerCheck)
        defaults.removeObject(forKey: Constants.userdefault_key_timer)
    }

    static func syncPendingChargerTimer(requests: [UNNotificationRequest]) {
        let hasPendingTimer = requests.contains { $0.identifier == Constants.notification_timer_identify }
        if hasPendingTimer {
            defaults.set(true, forKey: Constants.userdefault_timerCheck)
        } else {
            clearChargerTimer()
        }
    }
}
