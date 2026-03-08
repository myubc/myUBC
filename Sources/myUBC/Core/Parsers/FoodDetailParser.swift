//
//  FoodDetailParser.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation
import SwiftSoup

enum FoodDetailParser {
    static func parse(html: String) throws -> FoodDetailItem {
        let doc: Document = try SwiftSoup.parse(html)
        let description = extractDescription(from: doc)
        let flags = extractMealPlanFlags(from: doc, fallbackHtml: html)
        let images = extractImages(from: doc)

        return FoodDetailItem(
            description: description,
            carryover: flags.carryover,
            ubccard: flags.ubccard,
            mealplan: flags.mealplan,
            images: images,
            address: extractAddress(from: doc)
        )
    }

    private static func extractMealPlanFlags(from doc: Document, fallbackHtml: String) -> (mealplan: Bool, ubccard: Bool, carryover: Bool) {
        var mealplan = false
        var ubccard = false
        var carryover = false

        if let mealPlanSection = findToggleSection(titleContains: "Meal Plans", in: doc) {
            let text = (try? mealPlanSection.text())?.lowercased() ?? ""
            mealplan = text.contains("meal plan")
            ubccard = text.contains("ubccard") || text.contains("ubc card")
            carryover = text.contains("carryover")
        } else {
            let lower = fallbackHtml.lowercased()
            mealplan = lower.contains("meal plan")
            ubccard = lower.contains("ubccard") || lower.contains("ubc card")
            carryover = lower.contains("carryover")
        }

        return (mealplan, ubccard, carryover)
    }

    private static func findToggleSection(titleContains title: String, in doc: Document) -> Element? {
        guard let titles = try? doc.select(".elementor-toggle-title").array() else { return nil }
        for titleElement in titles {
            let text = (try? titleElement.text()) ?? ""
            if text.localizedCaseInsensitiveContains(title) {
                if
                    let parent = titleElement.parent(),
                    let grandParent = parent.parent(),
                    let content = try? grandParent.select(".elementor-tab-content").first()
                {
                    return content
                }
            }
        }
        return nil
    }

    private static func extractDescription(from doc: Document) -> String {
        let selectors = [
            ".elementor-text-editor.elementor-clearfix p",
            ".elementor-text-editor p",
            ".elementor-widget-text-editor p",
            ".entry-content p",
            "main p",
            "article p"
        ]
        var paragraphs: [Element] = []
        for selector in selectors where paragraphs.isEmpty {
            paragraphs = (try? doc.select(selector).array()) ?? []
        }

        var lines: [String] = []
        for paragraph in paragraphs {
            let text = (try? paragraph.text()) ?? ""
            if text.isEmpty { continue }
            if
                text.contains("feedback") ||
                text.contains("Musqueam") ||
                text.contains("About") ||
                text.contains("Careers") ||
                text.contains("Gifts") ||
                text.contains("Events") ||
                text.contains("Contact") ||
                text.contains("Sponsorship")
            {
                continue
            }
            // Skip tiny boilerplate lines and keep only meaningful copy.
            if text.count < 18 { continue }
            lines.append(text)
        }

        if !lines.isEmpty {
            return Array(lines.prefix(4)).joined(separator: "\n\n")
        }

        // Fallback to metadata when page body selectors change.
        if
            let meta = try? doc.select("meta[property=og:description]").first(),
            let content = try? meta.attr("content"),
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return content
        }
        if
            let meta = try? doc.select("meta[name=description]").first(),
            let content = try? meta.attr("content"),
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return content
        }
        return ""
    }

    private static func extractImages(from doc: Document) -> [String] {
        let images = (try? doc.select("img").array()) ?? []
        var urls: [String] = []
        for img in images {
            guard let src = try? img.attr("src"), !src.isEmpty else { continue }
            let lower = src.lowercased()
            if !lower.contains("wp-content/uploads") { continue }
            if lower.contains("icon") || lower.contains("logo") || lower.contains("button") { continue }
            urls.append(src)
        }
        let unique = Array(NSOrderedSet(array: urls)) as? [String] ?? urls
        return Array(unique.prefix(3))
    }

    private static func extractAddress(from doc: Document) -> String? {
        // Prefer the text block adjacent to "Location & Hours".
        if let headings = try? doc.select(".elementor-widget-heading").array() {
            for heading in headings {
                let title = ((try? heading.text()) ?? "").lowercased()
                guard title.contains("location"), title.contains("hour") else { continue }
                if
                    let parent = heading.parent(),
                    let editorContainers = try? parent.select(".elementor-widget-text-editor .elementor-widget-container").array()
                {
                    for editor in editorContainers {
                        if let normalized = normalizeAddressText(fromHTML: (try? editor.html()) ?? ""), !normalized.isEmpty {
                            return normalized
                        }
                    }
                }
            }
        }

        // Fallback: any text-editor block that looks like a campus address.
        if let editors = try? doc.select(".elementor-widget-text-editor .elementor-widget-container").array() {
            for editor in editors {
                if let normalized = normalizeAddressText(fromHTML: (try? editor.html()) ?? ""), !normalized.isEmpty {
                    return normalized
                }
            }
        }
        return nil
    }

    private static func normalizeAddressText(fromHTML html: String) -> String? {
        guard !html.isEmpty else { return nil }
        var textHTML = html
            .replacingOccurrences(of: "<br>", with: ", ")
            .replacingOccurrences(of: "<br/>", with: ", ")
            .replacingOccurrences(of: "<br />", with: ", ")
        textHTML = textHTML.replacingOccurrences(of: "&nbsp;", with: " ")
        let plain = (try? SwiftSoup.parseBodyFragment(textHTML).text()) ?? ""
        var normalized = plain
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s*,\\s*", with: ", ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty { return nil }

        // Strip trailing phone numbers and labels that are not part of the address.
        if let phoneRange = normalized.range(of: #"(?:\+?1[\s\.-]?)?(?:\(?\d{3}\)?[\s\.-]?)\d{3}[\s\.-]?\d{4}"#, options: .regularExpression) {
            normalized = String(normalized[..<phoneRange.lowerBound]).trimmingCharacters(in: CharacterSet(charactersIn: ", ").union(.whitespacesAndNewlines))
        }
        let lower = normalized.lowercased()
        let looksLikeAddress = lower.contains("vancouver") || lower.contains("road") || lower.contains("street") || lower.contains("mall")
        return looksLikeAddress ? normalized : nil
    }
}
