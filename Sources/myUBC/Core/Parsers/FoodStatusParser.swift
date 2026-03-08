//
//  FoodStatusParser.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation
import SwiftSoup

enum FoodStatusParser {
    struct FeedStatusEntry {
        let title: String
        let slug: String
        let url: String
        let isOpen: Bool
        let statusText: String
    }

    private static let rules: FoodStatusRules = .load()

    static func isOpen(html: String) -> Bool {
        parseStatus(html: html).isOpen
    }

    static func parse(html: String, name: String) -> FoodLocation {
        let status = parseStatus(html: html)
        let fallbackKey = status.isOpen ? "food.status.open" : "food.status.closed"
        let fallback = NSLocalizedString(fallbackKey, comment: "Food location status")
        let statusText = status.text ?? fallback
        return FoodLocation(name: name, isOpen: status.isOpen, statusText: statusText)
    }

    static func parseFeedStatuses(html: String) -> [FeedStatusEntry] {
        guard let doc = try? SwiftSoup.parse(html) else { return [] }
        var entries: [FeedStatusEntry] = []
        let titleElements = (try? doc.select("a[href*='/places/'] > div.ae-element-post-title").array()) ?? []
        var seenURLs = Set<String>()
        for titleElement in titleElements {
            guard let anchor = titleElement.parent() else { continue }
            let href = ((try? anchor.attr("href")) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !href.isEmpty, let normalizedURL = normalizedFoodURL(from: href), !seenURLs.contains(normalizedURL) else { continue }
            guard let slug = slug(from: normalizedURL) else { continue }
            let title = ((try? titleElement.text()) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
            // Skip cards without a valid hours/status block. These are typically non-UBC listings.
            guard let status = nearestStatus(for: anchor), !status.text.isEmpty else { continue }
            seenURLs.insert(normalizedURL)
            entries.append(FeedStatusEntry(
                title: title,
                slug: slug,
                url: normalizedURL,
                isOpen: status.isOpen,
                statusText: status.text
            ))
        }
        return entries
    }

    private static func nearestStatus(for anchor: Element) -> (isOpen: Bool, text: String)? {
        var node: Element? = anchor
        for _ in 0 ..< 8 {
            guard let current = node else { break }
            if let statusNode = try? current.select(".mb-bhi-display").first() {
                let className = ((try? statusNode.attr("class")) ?? "").lowercased()
                let text = ((try? statusNode.select(".mb-bhi-oc-text").first()?.text()) ?? (try? statusNode.text())) ?? ""
                let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let isOpen = classify(text: normalizedText, fallbackHtml: className)
                return (isOpen, normalizedText)
            }
            node = current.parent()
        }
        return nil
    }

    private static func normalizedFoodURL(from href: String) -> String? {
        guard let url = URL(string: href) else { return nil }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        components?.fragment = nil
        if var path = components?.path, !path.hasSuffix("/") {
            path += "/"
            components?.path = path
        }
        return components?.url?.absoluteString
    }

    private static func slug(from href: String) -> String? {
        guard let url = URL(string: href) else { return nil }
        return url.pathComponents.last(where: { $0 != "/" && !$0.isEmpty })?.lowercased()
    }

    private static func parseStatus(html: String) -> (isOpen: Bool, text: String?) {
        guard let doc = try? SwiftSoup.parse(html) else {
            return (html.localizedCaseInsensitiveContains("mb-bhi-open"), nil)
        }

        if let text = findStatusText(in: doc) {
            let isOpen = classify(text: text, fallbackHtml: html)
            return (isOpen, text)
        }

        if let status = findStatusByClass(in: doc) {
            return (status, nil)
        }

        return (classify(text: html, fallbackHtml: html), nil)
    }

    private static func findStatusText(in doc: Document) -> String? {
        for selector in rules.statusTextSelectors {
            if let element = try? doc.select(selector).first() {
                let text = (try? element.text()) ?? ""
                if !text.isEmpty { return text }
            }
        }

        if let element = try? doc.select(".mb-bhi-display").first() {
            let text = (try? element.text()) ?? ""
            if !text.isEmpty { return text }
        }

        return nil
    }

    private static func findStatusByClass(in doc: Document) -> Bool? {
        for selector in rules.statusContainerSelectors {
            if let element = try? doc.select(selector).first() {
                let className = (try? element.attr("class")) ?? ""
                if matchesAny(tokenList: rules.openClassTokens, in: className) {
                    return true
                }
                if matchesAny(tokenList: rules.closedClassTokens, in: className) {
                    return false
                }
            }
        }

        if let element = try? doc.select("[class*=mb-bhi]").first() {
            let className = (try? element.attr("class")) ?? ""
            if matchesAny(tokenList: rules.openClassTokens, in: className) {
                return true
            }
            if matchesAny(tokenList: rules.closedClassTokens, in: className) {
                return false
            }
        }

        return nil
    }

    private static func classify(text: String, fallbackHtml: String) -> Bool {
        let haystack = text
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if isFutureOpenPhrase(haystack) {
            return false
        }
        if rules.closedTextPatterns.contains(where: { haystack.contains($0) }) {
            return false
        }
        if rules.openTextPatterns.contains(where: { haystack.contains($0) }) {
            return true
        }
        return fallbackHtml.localizedCaseInsensitiveContains("mb-bhi-open")
    }

    private static func isFutureOpenPhrase(_ text: String) -> Bool {
        if matchesWord("opens", in: text) || matchesWord("opening", in: text) {
            return true
        }

        if text.hasPrefix("open "), !text.contains("open till"), !text.contains("open until"), !text.contains("open now") {
            let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
            if weekdays.contains(where: { text.contains($0) }) {
                return true
            }
            if text.contains("tomorrow") || text.contains("next ") || text.contains(" at ") {
                return true
            }
        }

        return false
    }

    private static func matchesWord(_ word: String, in text: String) -> Bool {
        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: word) + "\\b"
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    private static func matchesAny(tokenList: [String], in value: String) -> Bool {
        let lower = value.lowercased()
        return tokenList.contains(where: { lower.contains($0.lowercased()) })
    }
}
