//
//  NetworkClient.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation
import OSLog

enum NetworkError: Error {
    case invalidResponse
    case httpStatus(Int)
    case emptyData
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response (non-HTTP)."
        case let .httpStatus(status):
            return "HTTP status \(status)."
        case .emptyData:
            return "Empty response data."
        }
    }
}

actor NetworkClient {
    private let session: URLSession
    private let defaultAcceptLanguage: String

    init(session: URLSession = NetworkClient.makeSession()) {
        self.session = session
        defaultAcceptLanguage = NetworkClient.makeAcceptLanguage()
    }

    private static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }

    private static func makeAcceptLanguage() -> String {
        let preferred = Locale.preferredLanguages.prefix(3)
        guard !preferred.isEmpty else { return "en" }

        var quality = 1.0
        let step = 0.1
        return preferred.map { language in
            defer { quality = max(quality - step, 0.1) }
            if quality >= 0.999 {
                return language
            }
            return "\(language);q=\(String(format: "%.1f", quality))"
        }.joined(separator: ",")
    }

    func data(from url: URL, policy: RetryPolicy = .default) async throws -> Data {
        let request = URLRequest(url: url)
        return try await data(for: request, policy: policy)
    }

    func data(for request: URLRequest, policy: RetryPolicy = .default) async throws -> Data {
        var request = request
        if request.value(forHTTPHeaderField: "Accept-Language") == nil {
            request.setValue(defaultAcceptLanguage, forHTTPHeaderField: "Accept-Language")
        }

        var attempt = 0
        var lastError: Error?

        while attempt <= policy.maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    let urlString = request.url?.absoluteString ?? "unknown"
                    AppLogger.network.error("Non-HTTP response for \(urlString, privacy: .public)")
                    NSLog("NETWORK non-HTTP response url=%@", urlString)
                    throw NetworkError.invalidResponse
                }
                if !httpResponse.isResponseOK() {
                    let urlString = request.url?.absoluteString ?? "unknown"
                    AppLogger.network.error("HTTP \(httpResponse.statusCode) for \(urlString, privacy: .public)")
                    NSLog("NETWORK HTTP %ld url=%@", httpResponse.statusCode, urlString)
                    throw NetworkError.httpStatus(httpResponse.statusCode)
                }
                guard !data.isEmpty else {
                    let urlString = request.url?.absoluteString ?? "unknown"
                    NSLog("NETWORK empty data url=%@", urlString)
                    throw NetworkError.emptyData
                }
                let urlString = request.url?.absoluteString ?? "unknown"
                NSLog("NETWORK success url=%@ bytes=%ld", urlString, data.count)
                return data
            } catch {
                lastError = error
                if !policy.shouldRetry(error: error) || attempt == policy.maxRetries {
                    let urlString = request.url?.absoluteString ?? "unknown"
                    let nsError = error as NSError
                    AppLogger.network.error("Request failed: \(urlString, privacy: .public) error=\(nsError.localizedDescription, privacy: .public)")
                    NSLog("NETWORK failed url=%@ domain=%@ code=%ld desc=%@", urlString, nsError.domain, nsError.code, nsError.localizedDescription)
                    throw error
                }
                let delay = policy.delay(forAttempt: attempt)
                try await Task.sleep(nanoseconds: delay)
            }
            attempt += 1
        }

        throw lastError ?? NetworkError.invalidResponse
    }
}

struct RetryPolicy {
    let maxRetries: Int
    let baseDelay: UInt64
    let maxDelay: UInt64

    static let `default` = RetryPolicy(maxRetries: 2, baseDelay: 300_000_000, maxDelay: 2_000_000_000)
    static let noRetry = RetryPolicy(maxRetries: 0, baseDelay: 0, maxDelay: 0)

    func delay(forAttempt attempt: Int) -> UInt64 {
        let multiplier = UInt64(1 << attempt)
        return min(baseDelay * multiplier, maxDelay)
    }

    func shouldRetry(error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost:
                return true
            default:
                return false
            }
        }
        if let networkError = error as? NetworkError {
            switch networkError {
            case let .httpStatus(status):
                return (500 ... 599).contains(status)
            default:
                return false
            }
        }
        return false
    }
}
