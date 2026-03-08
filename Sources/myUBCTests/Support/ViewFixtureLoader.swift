import UIKit
import XCTest

@MainActor
protocol ViewFixtureLoading {}

@MainActor
extension ViewFixtureLoading where Self: XCTestCase {
    func loadViewFromNib<T: UIView>(named nibName: String, as type: T.Type = T.self) throws -> T {
        let bundle = Bundle(for: type)
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: nil).compactMap { $0 as? T }.first
        return try XCTUnwrap(view, "Unable to load nib '\(nibName)' as \(type).")
    }

    func firstSubview<T: UIView>(of type: T.Type, in view: UIView) -> T? {
        if let view = view as? T {
            return view
        }

        for subview in view.subviews {
            if let nested = firstSubview(of: type, in: subview) {
                return nested
            }
        }

        return nil
    }
}
