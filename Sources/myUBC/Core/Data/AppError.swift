//
//  AppError.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

enum AppError: Error {
    case network(Error)
    case offline
    case invalidResponse
    case decoding(Error)
    case parsing
    case cacheMiss
    case unknown

    var userMessage: String {
        switch self {
        case .offline:
            return NSLocalizedString("error.offline", comment: "Offline error message")
        case .network:
            return NSLocalizedString("error.network", comment: "Network error message")
        case .invalidResponse, .decoding, .parsing:
            return NSLocalizedString("error.parse", comment: "Parsing error message")
        case .cacheMiss:
            return NSLocalizedString("error.cache", comment: "Cache error message")
        case .unknown:
            return NSLocalizedString("error.unknown", comment: "Unknown error message")
        }
    }
}

extension AppError {
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return .offline
        }
        return .network(error)
    }
}
