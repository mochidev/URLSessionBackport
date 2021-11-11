import XCTest
@testable import URLSessionBackport

final class URLSessionBackportTests: XCTestCase {
    func testBackportBasics() throws {
        let _ = URLSession.shared.backport
        
        let backportedURLSession = URLSession.backport(configuration: .default)
        
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            XCTAssertNil(backportedURLSession.delegate)
        } else {
            XCTAssertTrue(backportedURLSession.delegate is URLSession.Backport.Delegate)
        }
    }
}
