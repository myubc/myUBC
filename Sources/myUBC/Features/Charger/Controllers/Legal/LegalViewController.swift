//
//  LegalViewController.swift
//  myUBC
//
//  Created by myUBC on 2020-02-21.
//

// swiftlint:disable line_length
import UIKit

@MainActor
class LegalViewController: UIViewController {
    private let legalTitle = UILabel()
    private let legalSubtitle = UILabel()
    private let textView = UILabel()
    private let contentScrollView = UIScrollView()
    private let contentView = UIView()

    var legalCase: Int = 0
    var defaultHeight: CGFloat = 0
    let model: [Legal] = [
        Legal(
            title: "Push Notification",
            subtitle: "To receive reminders as push notifications on your device, you must authorize myUBC to send you notifications. You may change this setting at any time.",
            content: "You acknowledge that we are not affiliated with The University of British Columbia and that we shall not be liable for any losses or inconveniences incurred as a result of reliance on information provided in this application.\n\nTo enable push notifications for myUBC, please follow the steps below:\n\n1. Tap the Settings icon on your device’s Home screen to launch the Settings app.\n2. Tap 'Notification Center.'\n3. Select myUBC from the list and set all available switches to ON. You may also allow Banners or Alerts from myUBC."
        ),
        Legal(
            title: "Terms of Service",
            subtitle: "By using this application, you acknowledge that you have read and agree to abide by the terms described below. If you do not agree with these terms, please exit this application and delete it from your device(s).",
            content: "By using or accessing this application, including the services provided herein, you accept all terms of this disclaimer notice. If you do not agree with any part of this notice, you must not use or access this application.\n\nWhile we make every effort to ensure the safety of this application and the accuracy of the information provided or uploaded, we do not warrant that the servers making this application available will be error-free or bug-free. You accept that it is your responsibility to make adequate provisions for this.\n\nThe information in this application may contain technical inaccuracies or typographical errors. We reserve the right to make changes or improvements to the information at any time. While the content is provided in good faith, we do not warrant that the information will be up to date, true, accurate, or not misleading, nor that the site will always be available for use.\n\nAll information on this application is provided on an \"As Is\" basis, without warranties of any kind, either express or implied. The inclusion or offering of any products or services on this application does not constitute an endorsement or recommendation by us, our affiliates, or our respective suppliers. We may make improvements and/or changes to this application at any time.\n\nWe do not warrant that the functions contained in this application will be uninterrupted or error-free, that defects will be corrected, or that this application or the servers that make it available are free of viruses or other harmful components, though we endeavor to ensure your fullest satisfaction.\n\nWe make no representations regarding the use or results of the use of the information, products, or services contained in this application in terms of their completeness, correctness, accuracy, reliability, suitability, or availability. Any actions you take based on information in this application are strictly at your own risk, and we are not liable for any losses or damages in connection with the use of our application.\n\nWe may provide hyperlinks enabling you to visit other applications. While we strive to provide links only to useful and ethical applications, we have no control over the content or nature of these sites. The presence of links does not imply a recommendation for all content found on those sites. When you leave our application, other sites may have different privacy policies and terms beyond our control.\n\nYou acknowledge that this application and the services specified are provided pursuant to the terms and conditions of the application. Your uninterrupted access or use of the application may be affected by factors outside our reasonable control, including, without limitation, the unavailability, inoperability, or interruption of the Internet or other telecommunications services, or as a result of any maintenance or other service work performed on the application. We do not accept any responsibility and will not be liable for any loss or damage suffered by you as a result of any inability to access or use the application.\n\nYou further acknowledge that this application merely provides intermediary services to facilitate the highest quality of service to you. We are not the last–mile service provider and therefore shall not be responsible for any lack or deficiency of services provided by any person, including agencies involved in facilitating such services. Accordingly, we do not guarantee the correctness of information or data provided or uploaded by users.\n\nWe take all reasonable steps to ensure that this application is available 24 hours a day, 365 days a year. However, applications may encounter downtime due to server or technical issues. Therefore, we will not be liable if this application is unavailable at any time.\n\nWe will not be liable to you or any other person for any direct, indirect, incidental, punitive, or consequential loss, damage, cost, or expense of any kind whatsoever (including loss of data) arising from your use of this application or the services provided. In no event shall we, our affiliates, or their suppliers be liable for any direct, indirect, punitive, incidental, special, or consequential damages connected with your access to, display of, or use of this application, or the delay or inability to access or use this application (including reliance on opinions, computer viruses, information, software, linked sites, products, and services obtained through this application), whether based on negligence, contract, tort, strict liability, or otherwise, even if advised of the possibility of such damages.\n\nTo the extent that this application and the information and services are provided free of charge, we will not be liable for any loss or damage of any nature.\n\nWe will not be liable to you or any other person in respect of any business losses, including (without limitation) loss of or damage to profits, income, revenue, use, production, anticipated savings, business, reputation, contracts, commercial opportunities, or goodwill. We are not liable for any loss or corruption of any data, database, or software.\n\nWe shall not be held liable for any improper or incorrect use of information or services on this application and assume no responsibility for anyone’s use of them. You agree to defend and indemnify us, including our officers, directors, employees, agents, affiliates, and suppliers, from and against any claims, causes of action, demands, recoveries, losses, damages, fines, penalties, or other costs or expenses (including reasonable legal and accounting fees) brought by third parties as a result of: (a) your breach of the User Agreement; or (b) your violation of any law or the rights of a third party.\n\nIf any portion of this disclaimer is found to be illegal, invalid, or unenforceable under applicable law, that will not affect the enforceability of the remainder of the notice; any illegal, invalid, or unenforceable part shall be amended to the minimum extent necessary to render it legal, valid, and enforceable.\n\nWe may revise this disclaimer from time to time. The revised disclaimer will apply to the use of our application from the date of its publication. Please check this page regularly to ensure you are familiar with the current version.\n\nThis disclaimer notice shall be interpreted and governed by the laws of Canada, and any disputes regarding it are subject to the jurisdiction of the courts in Vancouver, BC, Canada."
        ),
        Legal(
            title: "Loan Period",
            subtitle: "Please be advised that information regarding fine rates and loan periods may change at any time without notice.\n\nmyUBC is as diligent as possible in compiling and updating the information in this application. However, myUBC does not guarantee the accuracy or completeness of the information provided.",
            content: "Please check with library staff before you check out any item. The following information is provided by UBC Wiki.\n\n• Loan Time: 4-hour loan period. Items are due before the Learning Commons closes.\n\n• Item Information:\nMicro USB Charger.\n\nCompatible with Blackberry, Android, Samsung, and Sony.\nCompatible with iPhone 5/6/7/8/X. 85W MagSafe 2, 60W MagSafe, USB-C power adapters for Apple computers, and the Nekteck 72W USB-C wall charger station. Universal AV adaptor with 8 connectors.\n\n• USB and wall outlet options.\n\n• Fine Rate: $1/hour\n\nAt UBC Library you may borrow equipment with your UBC card. Most equipment is available on a first-come, first-served basis through the Chapman Learning Commons desk located on the 3rd floor of Irving K. Barber Learning Centre.\n\nAll chargers have a 4-hour loan period. No extended loans are available for these items."
        ),
        Legal(
            title: "Your Privacy",
            subtitle: "We believe privacy is a fundamental human right. Our app is designed to minimize the use of your information.",
            content: "We will not collect your CWL credentials; you must enter them manually on the Translink website.\n\nYou should never store or enter your CWL credentials on any third-party website or application. Enabling two-factor authentication is also recommended if possible.\n\nThe use of your CWL is subject to the 'UBC Campus-wide Login (CWL) Account Terms of Use.' Failure to comply with these terms may result in account suspension or termination.\n\nFor more information, please visit:\nhttps://www.ubc.ca/site/legal.html\nhttps://it.ubc.ca/services/accounts-passwords/campus-wide-login-cwl/\nand\nhttps://it.ubc.ca/services/accounts-passwords/campus-wide-login-cwl/terms-use\n\n"
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewHierarchy()
        setupNavigation()
        setupContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        defaultHeight = legalTitle.frame.height
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.setNeedsLayout()
        }
    }

    func setupContent() {
        contentScrollView.delegate = self
        legalTitle.text = model[legalCase].title
        legalSubtitle.text = model[legalCase].subtitle
        textView.text = model[legalCase].content
    }

    func setupNavigation() {
        let titleView = ConcealingTitleView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        titleView.text = model[legalCase].title
        navigationItem.titleView = titleView
        navigationItem.rightBarButtonItem = UIBarButtonItem.appNavIcon(
            systemName: "xmark",
            target: self,
            action: #selector(didCloseView(_:)),
            accessibilityLabel: "Close legal information"
        )

        /*
         let navBarAppearance = UINavigationBarAppearance()
         navBarAppearance.configureWithOpaqueBackground()
         navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
         navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
         navBarAppearance.backgroundColor = .systemBackground
         self.navigationController?.navigationBar.standardAppearance = navBarAppearance
         self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance

         self.navigationController?.navigationItem.title = model[legalCase].title
         self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
         self.navigationController?.navigationBar.shadowImage = UIImage()
         self.navigationController?.navigationBar.layoutIfNeeded()*/
    }

    @IBAction func didCloseView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    private func setupViewHierarchy() {
        view.backgroundColor = .systemBackground

        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        legalTitle.font = .boldSystemFont(ofSize: 25)
        legalTitle.numberOfLines = 0
        legalTitle.textAlignment = .center
        legalTitle.translatesAutoresizingMaskIntoConstraints = false

        legalSubtitle.font = .systemFont(ofSize: 17, weight: .medium)
        legalSubtitle.numberOfLines = 0
        legalSubtitle.textAlignment = .center
        legalSubtitle.translatesAutoresizingMaskIntoConstraints = false

        textView.font = .systemFont(ofSize: 16)
        textView.numberOfLines = 0
        textView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(contentScrollView)
        contentScrollView.addSubview(contentView)
        [legalTitle, legalSubtitle, textView].forEach(contentView.addSubview)

        NSLayoutConstraint.activate([
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor),

            legalTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            legalTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            legalTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),

            legalSubtitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            legalSubtitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            legalSubtitle.topAnchor.constraint(equalTo: legalTitle.bottomAnchor, constant: 20),

            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textView.topAnchor.constraint(equalTo: legalSubtitle.bottomAnchor, constant: 20),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}

// swiftlint:enable line_length

extension LegalViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let titleView = navigationItem.titleView as? ConcealingTitleView else {
            return
        }
        titleView.scrollViewDidScroll(scrollView, threshold: defaultHeight)
    }
}

struct Legal {
    var title: String
    var subtitle: String
    var content: String
}
