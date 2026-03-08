import Foundation

extension Result {
    func successValue() -> Success? {
        if case let .success(value) = self {
            return value
        }
        return nil
    }
}
