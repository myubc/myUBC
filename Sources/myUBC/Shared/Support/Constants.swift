//
//  Constants.swift
//  myUBC
//
//  Created by myUBC on 2020-01-20.
//

import Foundation

enum Constants {
    // MARK: - library stuff

    static let libraryURL_iphone1 = "https://resolve.library.ubc.ca/cgi-bin/catsearch?bid=8412835"
    static let libraryURL_iphone2 = "https://resolve.library.ubc.ca/cgi-bin/catsearch?bid=8523316"
    static let libraryKeyword_iphone1 = "subfieldData"

    static let libraryURL_android1 = "https://resolve.library.ubc.ca/cgi-bin/catsearch?bid=8456915"
    static let libraryURL_android2 = "https://resolve.library.ubc.ca/cgi-bin/catsearch?bid=8586554"
    static let libraryKeyword_android1 = "subfieldData"

    static let libraryURL_mac1 = "https://resolve.library.ubc.ca/cgi-bin/catsearch?bid=8463562"
    static let libraryURL_mac2 = "https://resolve.library.ubc.ca/cgi-bin/catsearch?bid=8586558"
    static let libraryKeyword_mac = "subfieldData"

    static let selector = "ul[title='Holdings Record Display']"
    static let classname = "subfieldData"

    static let loanPolicy = "https://lc2016.sites.olt.ubc.ca/files/2019/04/2019-CLC-Equipment-Loan-Policies.pdf"

    static let chargerCellIdentifier = "chargerCell"
    static let chargerCellNib = "ChargerTableViewCell"

    static let chargerCellDetailNib_mapCell = "MapTableViewCell"
    static let chargerCellDetailIdentifier_mapCell = "mapcell"

    static let chargerCellDetailNib_deviceCell = "DeviceDetailCell"
    static let chargerCellDetailIdentifier_deviceCell = "devicecell"

    static let chargerCellDetailNib_errorCell = "ErrorTableViewCell"
    static let chargerCellDetailIdentifier_errorCell = "errorcell"

    static let chargerCheckoutNib_viewCell = "CheckoutTableViewCell"
    static let chargerCheckout_viewCell = "checkoutCell"

    static let chargerCheckoutNib_timerCell = "CheckoutTimerTableViewCell"
    static let chargerCheckout_timerCell = "checkoutTimer"

    static let userdefault_libraryAgent = "libraryAgent"
    static let userdefault_launchCount = "app_launch_count"

    static let regular_date = "((0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])-[12]\\d{3}( \\d\\d:\\d\\d:\\d\\d)?)"

    static let loanPolicyURL = "https://services.library.ubc.ca/computers-technology/technology-borrowing/"

    // MARK: - Notification stuff

    static let notification_timer_identify = "myubc.timer.charger"
    static let notification_timer_category = "timer.snooze"
    static let notification_timer_action = "snooze"

    // MARK: - Timer stuff

    static let userdefault_key_timer = "timer"
    static let userdefault_timerCheck = "timercheck"
    static let countdownCellNib = "TimerTableViewCell"
    static let countdownCell = "countdowncell"

    // MARK: - Home View stuff

    static let campusInfoURL = "https://www.ubc.ca/campus-notifications/"
    static let notificationCSS = "#campus-notification"
    static let sanityCheck = "https://example.com/myubc.json"
    static let webViewNib = "WebViewController"
    static let foodBaseURL = "food.ubc.ca"
    static let totalModules = 4
    static let mainSegue = "showMain"
    static let homeItems = [
        HomeItem(
            title: "Food",
            subtitle: "Hours and Locations",
            imageName: "foodAll",
            segue: "showFood",
            detailText: "Cafés & bistros, residence dining rooms, food trucks, restaurants, and much more."
        ),
        HomeItem(
            title: "Chargers",
            subtitle: "Available at Chapman and Canaccord Learning Commons",
            imageName: "cableAll",
            segue: "showCharger",
            detailText: "Borrow a charger with your UBC card on a first-come, first-served basis."
        ),
        HomeItem(
            title: "Calendar",
            subtitle: "Important Dates and Deadlines",
            imageName: "calendar",
            segue: "showCalendar",
            detailText: "Course registration, tuition deadlines, and other important dates."
        ),
        HomeItem(
            title: "Parking",
            subtitle: "Availability on Campus",
            imageName: "parking-cover",
            segue: "showParking",
            detailText: "Current availability for regular and EV parking on campus."
        ),
        HomeItem(
            title: "Upass",
            subtitle: "Monthly Renewal Reminder",
            imageName: "upass",
            segue: "showUpass",
            detailText: "Set a monthly reminder and renew your U-Pass with less friction."
        ),
        HomeItem(
            title: "Bulletin",
            subtitle: "Campus-Wide Notifications",
            imageName: "infoAll",
            segue: "showBulletin",
            detailText: "Campus closures, service notices, and other official announcements."
        )
    ]

    // MARK: - UPass stuff

    static let upassLink = "https://upassadfs.translink.ca/adfs/ls/?wa=wsignin1.0&wtrealm=https%3a%2f%2fupassbc.translink.ca%2ffs%2f&whr=https://authentication.ubc.ca&wreply=https%3a%2f%2fupassbc.translink.ca%2ffs%2f"
    static let notification_upass_identifier = "upassnotification"
    static let userdefault_upasscheck = "upassuserdefault"
    static let userdefault_upass_combo = "upassuserdefaultcombo"
    static let upassViewIdentifier = "UpassControlTableViewCell"

    // MARK: - Food stuff

    static let foodLink = "https://food.ubc.ca/feedme/"
    static let userdefault_food = "foodtime"
    static var foodItems: [FoodItem] {
        FoodCatalog.load()
    }

    static var foodLinks: [String: String] {
        FoodPlaceCatalog.asDictionary()
    }

    static let foodViewIdentifier = "FoodTableViewCell"
    static let foodTableIdentifier = "ControlTableViewCell"
    static let foodPlaceholderIdentifier = "EmptyTableViewCell"
    static let foodOpenIcon = "checkmark.circle.fill"
    static let foodClosedIcon = "exclamationmark.circle.fill"
    static let foodDetail = "FoodDetailTableViewController"

    // MARK: - Info stuff

    static let userdefualt_info = "infotime"
    static let titleTableIdentifier = "TitleTableViewCell"
    static let notificationTableIdentifier = "NotificationTableViewCell"

    // MARK: - Parking

    static let parkingIDSelector = "block-ubc-parking-availability-block-ubc-parking-availability"
}
