import XCTest

extension XCTestCase {
    func landingScreenshotAttachment(
        app: XCUIApplication,
        named name: String
    )
        -> XCTAttachment
    {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        return attachment
    }
}
