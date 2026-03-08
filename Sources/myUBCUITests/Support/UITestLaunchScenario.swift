import XCTest

enum UITestLaunchScenario: String {
    case landingBaseline = "landing_baseline"
    case landingNotice = "landing_notice"
    case landingUpassOnly = "landing_upass_only"
    case landingTimerOnly = "landing_timer_only"
}

extension XCUIApplication {
    func launch(for scenario: UITestLaunchScenario) {
        launchArguments += ["UI_TESTING"]
        launchEnvironment["UI_TEST_SCENARIO"] = scenario.rawValue
        launch()
    }
}
