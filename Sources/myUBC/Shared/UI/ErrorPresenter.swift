//
//  ErrorPresenter.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import UIKit

extension AppError {
    var alertTitle: String {
        switch self {
        case .network:
            return NSLocalizedString("alert.network.title", comment: "Network error title")
        case .offline:
            return NSLocalizedString("alert.offline.title", comment: "Offline error title")
        default:
            return NSLocalizedString("alert.error.title", comment: "Generic error title")
        }
    }
}

@MainActor
extension UIViewController {
    func presentError(_ error: AppError, onDismiss: (() -> Void)? = nil) {
        let alert = UIAlertController(title: error.alertTitle, message: error.userMessage, preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("alert.ok", comment: "Alert OK"), style: .default) { _ in
            onDismiss?()
        }
        alert.addAction(action)
        present(alert, animated: true)
    }
}
