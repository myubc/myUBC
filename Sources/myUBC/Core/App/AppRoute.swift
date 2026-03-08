//
//  AppRoute.swift
//  myUBC
//
//  Created by myUBC on 2025-07-07.
//

import UIKit
import WebKit

enum WebNavigationPolicy: Equatable {
    case ubcOnly
    case unrestricted
    case ubcReadOnly

    var allowsExternalHosts: Bool {
        self == .unrestricted
    }

    var blocksPageInteractions: Bool {
        self == .ubcReadOnly
    }

    func navigationPolicy(for url: URL?) -> WKNavigationActionPolicy {
        guard allowsExternalHosts else {
            guard let host = url?.host, host.contains("ubc.ca") else {
                return .cancel
            }
            return .allow
        }
        return .allow
    }
}

struct WebViewConfiguration: Equatable {
    let requestURL: String
    let address: String
    let navigationPolicy: WebNavigationPolicy

    static func ubc(url: String, address: String = "ubc.ca") -> Self {
        Self(requestURL: url, address: address, navigationPolicy: .ubcOnly)
    }

    static func unrestricted(url: String, address: String) -> Self {
        Self(requestURL: url, address: address, navigationPolicy: .unrestricted)
    }

    static func ubcReadOnly(url: String, address: String = "ubc.ca") -> Self {
        Self(requestURL: url, address: address, navigationPolicy: .ubcReadOnly)
    }

    static func upassRenewal() -> Self {
        .unrestricted(url: Constants.upassLink, address: "Secure Connection")
    }
}

enum AppRoute: Equatable {
    case web(WebViewConfiguration)
    case reminders
}

actor PendingAppRouteStore {
    private var pendingRoute: AppRoute?

    func set(_ route: AppRoute) {
        pendingRoute = route
    }

    func consume() -> AppRoute? {
        defer { pendingRoute = nil }
        return pendingRoute
    }
}

@MainActor
enum AppRoutePresenter {
    static func presentPendingIfNeeded(from presenter: UIViewController, store: PendingAppRouteStore) async {
        guard let route = await store.consume() else {
            return
        }
        present(route, from: presenter)
    }

    static func present(_ route: AppRoute, from presenter: UIViewController) {
        switch route {
        case let .web(configuration):
            presentWeb(configuration, from: presenter)
        case .reminders:
            presentReminders(from: presenter)
        }
    }

    private static func presentWeb(_ configuration: WebViewConfiguration, from presenter: UIViewController) {
        let webView = WebViewController(nibName: Constants.webViewNib, bundle: nil)
        webView.configuration = configuration
        presenter.topPresentedViewController.present(webView, animated: true, completion: nil)
    }

    private static func presentReminders(from presenter: UIViewController) {
        let reminder = RemindersTableViewController()
        let navController = UINavigationController(rootViewController: reminder)
        navController.navigationBar.prefersLargeTitles = true
        navController.navigationBar.topItem?.title = "Reminder"
        navController.navigationBar.isTranslucent = true
        presenter.topPresentedViewController.present(navController, animated: true, completion: nil)
    }
}

private extension UIViewController {
    var topPresentedViewController: UIViewController {
        var current = self
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}
