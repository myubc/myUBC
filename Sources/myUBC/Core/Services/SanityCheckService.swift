//
//  SanityCheckService.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

struct SanityNotice {
    let title: String
    let detail: String
    let link: String?
    let skipVersions: [String]

    func shouldShow(for currentVersion: String?) -> Bool {
        guard let currentVersion, !currentVersion.isEmpty else {
            return true
        }
        return !skipVersions.contains(currentVersion)
    }
}

struct SanityCheckResult {
    let isStaging: Bool
    let isNewVersionAvailable: Bool
    let notice: SanityNotice?
}

protocol SanityCheckServicing {
    func fetch() async -> Result<SanityCheckResult, AppError>
}

actor SanityCheckService: SanityCheckServicing {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func fetch() async -> Result<SanityCheckResult, AppError> {
        guard let url = URL(string: Constants.sanityCheck) else {
            return .failure(.invalidResponse)
        }
        do {
            let data = try await client.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return .failure(.invalidResponse)
            }
            let staging = json["staging"] as? Bool ?? true
            guard
                let newVersion = json["version"] as? String,
                let inreview = json["inreview"] as? String,
                let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            else {
                return .success(SanityCheckResult(
                    isStaging: staging,
                    isNewVersionAvailable: false,
                    notice: Self.parseNotice(from: json)
                ))
            }
            let isNew = (inreview != current) ? (newVersion != current) : false
            return .success(SanityCheckResult(
                isStaging: staging,
                isNewVersionAvailable: isNew,
                notice: Self.parseNotice(from: json)
            ))
        } catch {
            return .failure(.network(error))
        }
    }

    private static func parseNotice(from json: [String: Any]) -> SanityNotice? {
        guard
            let raw = json["notice"] as? [String: Any],
            let title = raw["title"] as? String,
            let detail = raw["detail"] as? String
        else {
            return nil
        }
        let link = raw["link"] as? String
        let skipVersions = raw["skip"] as? [String] ?? []
        return SanityNotice(title: title, detail: detail, link: link, skipVersions: skipVersions)
    }
}
