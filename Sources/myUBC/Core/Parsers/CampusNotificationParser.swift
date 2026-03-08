//
//  CampusNotificationParser.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation
import SwiftSoup

enum CampusNotificationParser {
    static func parse(html: String) throws -> [CampusNotification] {
        let doc: Document = try SwiftSoup.parse(html)
        let content: Elements = try doc.select(Constants.notificationCSS)
        let sections: [Element] = content.array()
        var result: [CampusNotification] = []

        for section in sections {
            let articles = try section.getElementsByTag("article")
            for news in articles {
                let id = news.id()
                let title = try news.getElementsByTag("h2").text()
                let contents = try news.getElementsByTag("p").text()
                if let time = try news.getElementsByTag("strong").first()?.text() {
                    if !title.contains("no campus notifications") {
                        result.append(CampusNotification(
                            title: title,
                            time: time,
                            content: contents,
                            notificationID: id
                        ))
                    }
                }
            }
        }

        return result
    }
}
