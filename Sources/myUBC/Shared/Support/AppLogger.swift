//
//  AppLogger.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation
import OSLog

enum AppLogger {
    static let network = Logger(subsystem: "org.opensource.myubc", category: "network")
    static let parsing = Logger(subsystem: "org.opensource.myubc", category: "parsing")
    static let cache = Logger(subsystem: "org.opensource.myubc", category: "cache")
}
