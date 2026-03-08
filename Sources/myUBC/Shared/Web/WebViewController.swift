//
//  WebViewController.swift
//  myUBC
//
//  Created by myUBC on 2020-03-13.
//

import UIKit
import WebKit

@MainActor
class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    @IBOutlet var webContentView: WKWebView!
    @IBOutlet var navigationBar: UINavigationBar!
    // let progressView = UIProgressView(progressViewStyle: .default)
    @IBOutlet var progressView: UIProgressView!
    private var estimatedProgressObserver: NSKeyValueObservation?
    var configuration = WebViewConfiguration.ubc(url: "")

    @IBOutlet var addressLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationButtons()
        setupAddressTitleView()
        setupEstimatedProgressObserver()
        webContentView.uiDelegate = self
        webContentView.navigationDelegate = self

        guard let url = URL(string: configuration.requestURL) else {
            return
        }

        webContentView.load(URLRequest(url: url))
    }

    func setupNavigationButtons() {
        let refresh = UIBarButtonItem.appNavIcon(
            systemName: "arrow.clockwise",
            target: self,
            action: #selector(didRefresh(_:)),
            accessibilityLabel: "Refresh webpage"
        )
        let close = UIBarButtonItem.appNavIcon(
            systemName: "xmark",
            target: self,
            action: #selector(didDismiss(_:)),
            accessibilityLabel: "Close webpage"
        )
        navigationBar.topItem?.setLeftBarButton(refresh, animated: false)
        navigationBar.topItem?.setRightBarButton(close, animated: false)
    }

    func setupAddressTitleView() {
        let icon = UIImageView(image: UIImage(systemName: "lock.fill"))
        icon.tintColor = .systemGreen
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = configuration.address
        label.font = .systemFont(ofSize: 17)
        label.textColor = .systemGreen
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            container.widthAnchor.constraint(lessThanOrEqualToConstant: 250)
        ])
        navigationBar.topItem?.titleView = container
        addressLabel = label
    }

    func setupEstimatedProgressObserver() {
        estimatedProgressObserver = webContentView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.progressView.progress = Float(webView.estimatedProgress)
            }
        }
    }

    @IBAction func didRefresh(_ sender: Any) {
        webContentView.reload()
    }

    @IBAction func didDismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension WebViewController {
    func policy(for url: URL?) -> WKNavigationActionPolicy {
        configuration.navigationPolicy.navigationPolicy(for: url)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        debugPrint("didCommit")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugPrint("didFail")
    }

    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        debugPrint("didStartProvisionalNavigation")
        if progressView.isHidden {
            // Make sure our animation is visible.
            progressView.isHidden = false
        }

        UIView.animate(
            withDuration: 0.33,
            animations: {
                self.progressView.alpha = 1.0
            }
        )
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        debugPrint("didFailProvisionalNavigation")
        debugPrint(error.localizedDescription)
        debugPrint(WKNavigationActionPolicy.allow)
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        // debugPrint("didFinish")
        UIView.animate(
            withDuration: 0.33,
            animations: {
                self.progressView.alpha = 0.0
            },
            completion: { isFinished in
                // Update `isHidden` flag accordingly:
                //  - set to `true` in case animation was completly finished.
                //  - set to `false` in case animation was interrupted, e.g. due to starting of another animation.
                self.progressView.isHidden = isFinished
            }
        )
        if configuration.navigationPolicy.blocksPageInteractions {
            webContentView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none'")
            webContentView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none'")
            webContentView
                .evaluateJavaScript(
                    "var elems = document.getElementsByTagName('a'); for (var i = 0; i < elems.length; i++) { elems[i]['href'] = 'javascript:(void)'; }"
                )
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(policy(for: navigationAction.request.url))
    }

    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKContextMenuElementInfo) -> Bool {
        return !configuration.navigationPolicy.blocksPageInteractions
    }
}
