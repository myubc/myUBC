//
//  LandingPageModel.swift
//  myUBC
//
//  Created by myUBC on 2022-09-08.
//

import Foundation

enum LandingPageModel {
    static let sections: [LandingPageSection] = {
        let flags = FeatureFlags.shared
        var sections: [LandingPageSection] = []

        if flags.showFood {
            sections.append(LandingPageSection(
                sectionTitle: NSLocalizedString("landing.food.title", comment: "Landing food section title"),
                linkLabel: NSLocalizedString("landing.showAll", comment: "Landing show all"),
                type: .food,
                items: [
                    LandingPageItem(isSummary: true),
                    LandingPageItem(isSummary: false),
                    LandingPageItem(isSummary: false),
                    LandingPageItem(isSummary: false),
                    LandingPageItem(isSummary: false)
                ]
            ))
        }

        if flags.showCharger {
            sections.append(LandingPageSection(
                sectionTitle: NSLocalizedString("landing.charger.title", comment: "Landing charger section title"),
                linkLabel: NSLocalizedString("landing.showAll", comment: "Landing show all"),
                type: .charger,
                items: [
                    LandingPageItem(isSummary: false),
                    LandingPageItem(isSummary: false),
                    LandingPageItem(isSummary: false)
                ]
            ))
        }

        if flags.showCalendar {
            sections.append(LandingPageSection(
                sectionTitle: NSLocalizedString("landing.calendar.title", comment: "Landing calendar section title"),
                linkLabel: NSLocalizedString("landing.learnMore", comment: "Landing learn more"),
                type: .calendar,
                items: [
                    LandingPageItem(isSummary: true),
                    LandingPageItem(isSummary: true)
                ]
            ))
        }

        if flags.showParking {
            sections.append(LandingPageSection(
                sectionTitle: NSLocalizedString("landing.parking.title", comment: "Landing parking section title"),
                linkLabel: NSLocalizedString("landing.showAll", comment: "Landing show all"),
                type: .parking,
                items: [
                    LandingPageItem(isSummary: true),
                    LandingPageItem(isSummary: false),
                    LandingPageItem(isSummary: false),
                    LandingPageItem(isSummary: false),
                    LandingPageItem(isSummary: false),
                    LandingPageItem(isSummary: false),
                    LandingPageItem(isSummary: false)
                ]
            ))
        }

        if flags.showUpass {
            sections.append(LandingPageSection(
                sectionTitle: NSLocalizedString("landing.upass.title", comment: "Landing upass section title"),
                linkLabel: NSLocalizedString("landing.details", comment: "Landing details"),
                type: .upass,
                items: [
                    LandingPageItem(isSummary: true)
                ]
            ))
        }

        if flags.showInfo {
            sections.append(LandingPageSection(
                sectionTitle: NSLocalizedString("landing.info.title", comment: "Landing info section title"),
                linkLabel: NSLocalizedString("landing.learnMore", comment: "Landing learn more"),
                type: .info,
                items: [
                    LandingPageItem(isSummary: true)
                ]
            ))
        }

        return sections
    }()
}

struct LandingPageSection {
    let sectionTitle: String
    let linkLabel: String
    let type: LandingPageSectionType
    let items: [LandingPageItem]
}

struct LandingPageItem {
    let isSummary: Bool
}

enum LandingPageSectionType: Int {
    case food = 0, charger, calendar, parking, upass, info
}
