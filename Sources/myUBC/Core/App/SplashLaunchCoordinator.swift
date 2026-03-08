//
//  SplashLaunchCoordinator.swift
//  myUBC
//
//  Created by myUBC on 2025-07-07.
//

import Foundation

struct SplashLaunchResult {
    let statusSummary: DataHub.StatusSummary?
    let didTimeout: Bool
}

enum SplashLaunchCoordinator {
    static func prepareLaunch(
        using hub: DataHub,
        minimumDelay: TimeInterval = 1,
        timeout: TimeInterval = 2
    ) async
        -> SplashLaunchResult
    {
        async let launchResult = loadLaunchState(using: hub, timeout: timeout)
        async let delay: Void = sleep(for: minimumDelay)

        let result = await launchResult
        _ = await delay
        return result
    }

    private static func loadLaunchState(using hub: DataHub, timeout: TimeInterval) async -> SplashLaunchResult {
        await withTaskGroup(of: SplashLaunchResult.self) { group in
            group.addTask {
                let summary = await hub.refreshAll()
                return SplashLaunchResult(statusSummary: summary, didTimeout: false)
            }
            group.addTask {
                await sleep(for: timeout)
                return SplashLaunchResult(statusSummary: nil, didTimeout: true)
            }

            let result = await group.next() ?? SplashLaunchResult(statusSummary: nil, didTimeout: true)
            group.cancelAll()
            return result
        }
    }

    private static func sleep(for duration: TimeInterval) async {
        let nanoseconds = UInt64(max(duration, 0) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}
