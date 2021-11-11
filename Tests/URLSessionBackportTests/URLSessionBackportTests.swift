import XCTest
@testable import URLSessionBackport

final class URLSessionBackportTests: XCTestCase {
    func testBackportBasics() throws {
        let _ = URLSession.shared.backport
        
        let backportedURLSession = URLSession.backport(configuration: .default)
        
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            XCTAssertNil(backportedURLSession.delegate)
        } else {
            XCTAssertTrue(backportedURLSession.delegate is SessionDelegateProxy)
        }
    }
    
    func testContinuationTaskCompletionHandler() async throws {
        enum DummyError: Error {
            case error
        }
        
        do {
            let _: (String, String) = try await withUnsafeThrowingContinuation { continuation in
                continuation.taskCompletionHandler("A", nil, nil)
            }
            XCTFail()
        } catch URLSession.Backport.Error.unexpectedTaskCompletionHandler(true, false, false) {
            // Got the expected case!
        } catch {
            XCTFail()
        }
        
        do {
            let _: (String, String) = try await withUnsafeThrowingContinuation { continuation in
                continuation.taskCompletionHandler(nil, "B", nil)
            }
            XCTFail()
        } catch URLSession.Backport.Error.unexpectedTaskCompletionHandler(false, true, false) {
            // Got the expected case!
        } catch {
            XCTFail()
        }
        
        do {
            let _: (String, String) = try await withUnsafeThrowingContinuation { continuation in
                continuation.taskCompletionHandler(nil, nil, DummyError.error)
            }
            XCTFail()
        } catch DummyError.error {
            // Got the expected case!
        } catch {
            XCTFail()
        }
        
        do {
            let result: (String, String) = try await withUnsafeThrowingContinuation { continuation in
                continuation.taskCompletionHandler("A", "B", nil)
            }
            XCTAssert(result == ("A", "B"))
        } catch {
            XCTFail()
        }
        
        do {
            let _: (String, String) = try await withUnsafeThrowingContinuation { continuation in
                continuation.taskCompletionHandler("A", nil, DummyError.error)
            }
            XCTFail()
        } catch URLSession.Backport.Error.unexpectedTaskCompletionHandler(true, false, true) {
            // Got the expected case!
        } catch {
            XCTFail()
        }
        
        do {
            let _: (String, String) = try await withUnsafeThrowingContinuation { continuation in
                continuation.taskCompletionHandler(nil, "B", DummyError.error)
            }
            XCTFail()
        } catch URLSession.Backport.Error.unexpectedTaskCompletionHandler(false, true, true) {
            // Got the expected case!
        } catch {
            XCTFail()
        }
        
        do {
            let _: (String, String) = try await withUnsafeThrowingContinuation { continuation in
                continuation.taskCompletionHandler("A", "B", DummyError.error)
            }
            XCTFail()
        } catch URLSession.Backport.Error.unexpectedTaskCompletionHandler(true, true, true) {
            // Got the expected case!
        } catch {
            XCTFail()
        }
    }
}
