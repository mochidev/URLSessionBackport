import XCTest
@testable import URLSessionBackport

final class URLSessionBackportTests: XCTestCase {
    func testBackport() throws {
        let _ = URLSession.shared.backport
    }
}
