//
//  myUBC_widgets.swift
//  myUBC.widgets
//
//  Created by myUBC on 2020-09-29.
//

import AppIntents
import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: FoodWidgetIntent(), statuses: FoodStatus.placeholder)
    }

    func snapshot(for configuration: FoodWidgetIntent, in context: Context) async -> SimpleEntry {
        let statuses = await FoodStatusProvider.fetchStatuses(for: configuration.places)
        return SimpleEntry(date: Date(), configuration: configuration, statuses: statuses)
    }

    func timeline(for configuration: FoodWidgetIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let statuses = await FoodStatusProvider.fetchStatuses(for: configuration.places)
        let entry = SimpleEntry(date: Date(), configuration: configuration, statuses: statuses)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        return Timeline(entries: [entry], policy: .after(next))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: FoodWidgetIntent
    let statuses: [FoodStatus]
}

struct MyUBCWidgetsEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            contentView(title: "Starbucks", subtitle: "at UBC", maxItems: 1)
        case .systemMedium:
            contentView(title: "Campus Eats", subtitle: "Now", maxItems: 2)
        case .systemLarge:
            contentView(title: "Campus Eats", subtitle: "Now", maxItems: 4)
        default:
            Text("Some other WidgetFamily in the future.")
        }
    }

    private func contentView(title: String, subtitle: String, maxItems: Int) -> some View {
        VStack(alignment: .leading, spacing: 0.0) {
            HStack(alignment: .center, spacing: 0.0) {
                VStack(alignment: .leading, spacing: 0.0) {
                    Text(title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                        .multilineTextAlignment(.leading)
                        .opacity(0.8)
                    Text(subtitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                        .multilineTextAlignment(.leading)
                        .opacity(0.8)
                }
            }
            .padding([.leading, .trailing], 5)
            Divider()
                .padding(.vertical, 5.0)
            VStack {
                ForEach(entry.statuses.prefix(maxItems)) { status in
                    HStack(spacing: 0.0) {
                        Image(status.indicatorAsset)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(2.0)
                            .accessibilityHidden(true)
                        Text(status.displayName).multilineTextAlignment(.leading).font(.system(size: 12)).foregroundColor(Color(UIColor.label))
                            .accessibilityLabel("\(status.displayName) status")
                        Spacer()
                    }
                }
            }
        }
        .padding(.all, 15)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

@main
struct MyUBCWidgets: Widget {
    let kind: String = "myUBC_widgets"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: FoodWidgetIntent.self,
            provider: Provider()
        ) { entry in
            MyUBCWidgetsEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .configurationDisplayName("myUBC Food Widget")
        .description("Pick your favorite places.")
    }
}

private enum FoodStatusParser {
    private static let rules = FoodStatusRules.load(bundle: .main)

    static func parse(html: String) -> Bool? {
        let lower = html.lowercased()
        if rules.openClassTokens.contains(where: { lower.contains($0.lowercased()) }) {
            return true
        }
        if rules.closedClassTokens.contains(where: { lower.contains($0.lowercased()) }) {
            return false
        }
        if rules.openTextPatterns.contains(where: { lower.contains($0.lowercased()) }) {
            return true
        }
        if rules.closedTextPatterns.contains(where: { lower.contains($0.lowercased()) }) {
            return false
        }
        return nil
    }
}

struct FoodStatus: Identifiable, Hashable {
    let id = UUID()
    let displayName: String
    let isOpen: Bool?

    var indicatorAsset: String {
        switch isOpen {
        case .some(true):
            return "green"
        case .some(false):
            return "red"
        default:
            return "grey"
        }
    }

    static let placeholder: [FoodStatus] = [
        FoodStatus(displayName: "Fred Kaiser", isOpen: true),
        FoodStatus(displayName: "Life Building", isOpen: false),
        FoodStatus(displayName: "Bookstore", isOpen: nil)
    ]
}

enum FoodStatusProvider {
    static func fetchStatuses(for places: [FoodPlace]) async -> [FoodStatus] {
        await withTaskGroup(of: FoodStatus.self) { group in
            let defaults = FoodPlace.defaults
            let resolvedPlaces = places.isEmpty ? defaults : places
            for place in resolvedPlaces {
                group.addTask {
                    await fetchStatus(urlString: place.url, displayName: place.displayName)
                }
            }
            var result: [FoodStatus] = []
            for await status in group {
                result.append(status)
            }
            if result.isEmpty {
                return FoodStatus.placeholder
            }
            return result.sorted { lhs, rhs in
                defaults.firstIndex(where: { $0.displayName == lhs.displayName }) ?? 0 <
                    FoodPlace.defaults.firstIndex(where: { $0.displayName == rhs.displayName }) ?? 0
            }
        }
    }

    private static func fetchStatus(urlString: String, displayName: String) async -> FoodStatus {
        guard let url = URL(string: urlString) else {
            return FoodStatus(displayName: displayName, isOpen: nil)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("food.ubc.ca", forHTTPHeaderField: "Host")
        request.setValue("https://food.ubc.ca/feedme/", forHTTPHeaderField: "Referer")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                return FoodStatus(displayName: displayName, isOpen: nil)
            }
            guard let html = String(data: data, encoding: .utf8) else {
                return FoodStatus(displayName: displayName, isOpen: nil)
            }
            let isOpen = FoodStatusParser.parse(html: html)
            return FoodStatus(displayName: displayName, isOpen: isOpen)
        } catch {
            return FoodStatus(displayName: displayName, isOpen: nil)
        }
    }
}

struct FoodPlace: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Food Place")
    static var defaultQuery = FoodPlaceQuery()

    let id: String
    let displayName: String
    let url: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }

    static var defaults: [FoodPlace] {
        FoodPlaceLoader.loadDefaults()
    }
}

enum FoodPlaceLoader {
    static func loadDefaults() -> [FoodPlace] {
        guard let url = Bundle.main.url(forResource: "FoodPlaces", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let array = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [[String: Any]]
        else {
            return []
        }
        let mapped: [(order: Int, place: FoodPlace, widgetDefault: Bool)] = array.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let name = dict["displayName"] as? String,
                  let link = dict["url"] as? String
            else { return nil }
            let order = dict["sortOrder"] as? Int ?? 0
            let widgetDefault = dict["widgetDefault"] as? Bool ?? false
            return (order, FoodPlace(id: id, displayName: name, url: link), widgetDefault)
        }
        let sorted = mapped.sorted(by: { $0.order < $1.order })
        let defaults = sorted.filter { $0.widgetDefault }
        let resolved = defaults.isEmpty ? sorted : defaults
        return resolved.map { $0.place }
    }
}

struct FoodPlaceQuery: EntityQuery {
    func entities(for identifiers: [FoodPlace.ID]) async throws -> [FoodPlace] {
        FoodPlace.defaults.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [FoodPlace] {
        FoodPlace.defaults
    }

    func defaultResult() async -> FoodPlace? {
        FoodPlace.defaults.first
    }
}

struct FoodWidgetIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Food Places"
    static var description = IntentDescription("Pick the places to show in the widget.")

    @Parameter(title: "Places", default: FoodPlace.defaults)
    var places: [FoodPlace]

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$places)")
    }
}

struct MyUBCWidgetsPreviews: PreviewProvider {
    static var previews: some View {
        MyUBCWidgetsEntryView(entry: SimpleEntry(date: Date(), configuration: FoodWidgetIntent(), statuses: FoodStatus.placeholder))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

        MyUBCWidgetsEntryView(entry: SimpleEntry(date: Date(), configuration: FoodWidgetIntent(), statuses: FoodStatus.placeholder))
            .redacted(reason: .placeholder)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
