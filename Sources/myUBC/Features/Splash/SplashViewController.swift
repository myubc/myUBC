//
//  SplashViewController.swift
//  myUBC
//
//  Created by myUBC on 2020-01-20.
//

import UIKit

@MainActor
class SplashViewController: UIViewController, AppContainerInjectable {
    private let wave1 = UIImageView(image: UIImage(named: "wave"))
    private let wave2 = UIImageView(image: UIImage(named: "wave"))
    private let background = UIImageView(image: UIImage(named: "splash"))
    private let logo = UIImageView(image: UIImage(named: "ubclogo"))
    private let text = UILabel()
    private var waveTravelDistance: CGFloat = 0

    private let generatorNotice = UINotificationFeedbackGenerator()
    private let generatorImpact = UIImpactFeedbackGenerator(style: .light)
    private var launchTask: Task<Void, Never>?
    var container: AppContainer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewHierarchy()
        setupWaves()
        animateBackground()
        initialNetworkCalls()
    }

    private func setupViewHierarchy() {
        view.backgroundColor = .black

        background.contentMode = .scaleAspectFill
        background.alpha = 1
        background.translatesAutoresizingMaskIntoConstraints = false

        for item in [wave1, wave2] {
            item.contentMode = .scaleToFill
            item.translatesAutoresizingMaskIntoConstraints = false
        }

        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false

        text.text = "Connecting..."
        text.alpha = 0
        text.textAlignment = .center
        text.font = .systemFont(ofSize: 14, weight: .medium)
        text.textColor = .white
        text.translatesAutoresizingMaskIntoConstraints = false

        for subview in [background, wave1, wave2, logo, text] {
            view.addSubview(subview)
        }

        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            background.topAnchor.constraint(equalTo: view.topAnchor),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 90),
            logo.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            logo.heightAnchor.constraint(equalToConstant: 220),

            text.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            text.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            text.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -220),

            wave1.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 2),
            wave1.heightAnchor.constraint(equalTo: background.heightAnchor, multiplier: 0.2),
            wave1.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wave1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 110),

            wave2.leadingAnchor.constraint(equalTo: wave1.trailingAnchor),
            wave2.widthAnchor.constraint(equalTo: wave1.widthAnchor),
            wave2.heightAnchor.constraint(equalTo: wave1.heightAnchor),
            wave2.centerYAnchor.constraint(equalTo: wave1.centerYAnchor)
        ])
    }

    func setupWaves() {
        view.layoutIfNeeded()
        waveTravelDistance = wave1.bounds.width
    }

    func initialNetworkCalls() {
        guard let hub = container?.dataHub else {
            presentMain()
            return
        }
        launchTask = Task { [weak self] in
            _ = await SplashLaunchCoordinator.prepareLaunch(using: hub)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.presentMain()
            }
        }
    }

    private func showAlert(
        withTitle title: String,
        andMessage msg: String,
        withBtnLabel btn: String,
        andAction callback: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: btn, style: .cancel, handler: { _ in
            callback()
        }))
        present(alert, animated: true, completion: nil)
    }

    private func animateBackground() {
        UIView.animate(withDuration: 4, delay: 0, options: [.curveEaseIn], animations: {
            self.background.alpha = 0.2
        }, completion: { _ in
            UIView.animate(withDuration: 3, animations: {
                self.text.alpha = 1
                UIView.transition(
                    with: self.text,
                    duration: 1,
                    options: .curveEaseIn,
                    animations: { [weak self] in
                        self?.text.text = "Please Wait..."
                        self?.text.alpha = 1
                    },
                    completion: nil
                )
            }, completion: { _ in
                UIView.animate(withDuration: 3, animations: {
                    self.text.alpha = 0.0
                }, completion: { _ in
                    UIView.transition(
                        with: self.text,
                        duration: 1,
                        options: .curveEaseIn,
                        animations: { [weak self] in
                            self?.text.text = "Still Connecting..."
                            self?.text.alpha = 1
                        },
                        completion: nil
                    )
                })
            })
        })

        UIView.animate(
            withDuration: 8.0,
            delay: 0.0,
            options: [.repeat, .curveLinear],
            animations: {
                self.wave1.transform = CGAffineTransform(translationX: -self.waveTravelDistance, y: 0)
                self.wave2.transform = CGAffineTransform(translationX: -self.waveTravelDistance, y: 0)
            },
            completion: nil
        )
    }

    private func presentMain() {
        let landing = LandingViewController(nibName: "LandingViewController", bundle: nil)
        generatorNotice.notificationOccurred(.success)
        landing.modalPresentationStyle = .currentContext
        landing.container = container
        present(landing, animated: true)
    }

    deinit {
        launchTask?.cancel()
    }
}
