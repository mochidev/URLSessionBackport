//
//  URLSessionBackport.swift
//  URLSessionBackport
//
//  Created by Dimitri Bouniol on 2021-11-10.
//  Copyright © 2021 Mochi Development, Inc. All rights reserved.
//

import Foundation

extension URLSession {
    
    /// This is the namespace for backward compatible API.
    public struct Backport {
        let session: URLSession
        
        init(_ session: URLSession) {
            self.session = session
        }
    }
    
    /// Access backported methods that are inter-compatible with older and newer OSs.
    ///
    /// This uses Dave DeLong's naming convention: https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/
    @available(macOS, introduced: 10.15, deprecated: 12.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in methods instead.")
    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in methods instead.")
    @available(watchOS, introduced: 6.0, deprecated: 8.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in methods instead.")
    public var backport: Backport {
        Backport(self)
    }
    
    /// Creates a backported session with the specified session configuration, delegate, and operation queue.
    /// - Parameters:
    ///   - configuration: A configuration object that specifies certain behaviors, such as caching policies, timeouts, proxies, pipelining, TLS versions to support, cookie policies, and credential storage.
    ///
    ///     See ``URLSessionConfiguration`` for more information.
    ///   - delegate: A session delegate object that handles requests for authentication and other session-related events. This delegate object is responsible for handling authentication challenges, for making caching decisions, and for handling other session-related events. If `nil`, the class should be used only with methods that take completion handlers.
    ///     ### Important
    ///     The session object keeps a strong reference to the delegate until your app exits or explicitly invalidates the session. If you do not invalidate the session by calling the ``invalidateAndCancel()`` or ``finishTasksAndInvalidate()`` method, your app leaks memory until it exits.
    ///   - queue: An operation queue for scheduling the delegate calls and completion handlers. The queue should be a serial queue, in order to ensure the correct ordering of callbacks. If `nil`, the session creates a serial operation queue for performing all delegate method calls and completion handler calls.
    /// - Returns: An initialized URL session with a backported delegate.
    @available(macOS, introduced: 10.15, deprecated: 12.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in initializer instead.")
    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in initializer instead.")
    @available(watchOS, introduced: 6.0, deprecated: 8.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in initializer instead.")
    public static func backport(configuration: URLSessionConfiguration, delegate: URLSessionDelegate? = nil, delegateQueue queue: OperationQueue? = nil) -> URLSession {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            return URLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
        } else {
            return URLSession(configuration: configuration, delegate: SessionDelegateProxy(originalDelegate: delegate), delegateQueue: queue)
        }
    }
}

// MARK: - Backported Asyncronous Methods

#if compiler(>=5.5.2)
extension UnsafeContinuation {
    /// A generic completion handler for URLSession-based tasks
    func taskCompletionHandler<A, B>(_ a: A?, _ b: B?, _ error: E?) where T == (A, B) {
        switch (a, b, error) {
        case (.some(let a), .some(let b), .none):
            resume(returning: (a, b))
        case (.none, .none, .some(let error)):
            resume(throwing: error)
        default:
            preconditionFailure("The task returned incompatible data")
        }
    }
}

extension URLSession.Backport {
    /// Resume a task, and schedule the delegate to receive callbacks through the backported proxy.
    /// - Parameters:
    ///   - task: The task to resume.
    ///   - delegate: The delegate to schedule, if provided.
    ///   - function: The calling function, for logging purposes.
    func resume(_ task: URLSessionTask, with delegate: URLSessionTaskDelegate?, _ function: String = #function) {
        if let delegate = delegate {
            if let sessionDelegate = session.delegate as? SessionDelegateProxy {
                sessionDelegate.addTaskDelegate(task: task, delegate: delegate)
            } else {
                #if DEBUG
                print("Runtime Warning: You provided a delegate to \(function), but did not initialize the URLSession with `URLSession.backport(configuration:delegate:delegateQueue:)`, which is necessary to proxy the delegate methods properly.")
                #endif
            }
        }
        
        task.resume()
    }
}

extension URLSession.Backport {
    
    /// Backported convenience method to load data using an URLRequest, creates and resumes an URLSessionDataTask internally.
    ///
    /// - Parameter request: The URLRequest for which to load data.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data and response.
    public func data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            return try await session.data(for: request, delegate: delegate)
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                resume(session.dataTask(with: request, completionHandler: continuation.taskCompletionHandler), with: delegate)
            }
        }
    }
    
    /// Backported convenience method to load data using an URL, creates and resumes an URLSessionDataTask internally.
    ///
    /// - Parameter url: The URL for which to load data.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data and response.
    public func data(from url: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            return try await session.data(from: url, delegate: delegate)
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                resume(session.dataTask(with: url, completionHandler: continuation.taskCompletionHandler), with: delegate)
            }
        }
    }
    
    /// Backported convenience method to upload data using an URLRequest, creates and resumes an URLSessionUploadTask internally.
    ///
    /// - Parameter request: The URLRequest for which to upload data.
    /// - Parameter fileURL: File to upload.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data and response.
    public func upload(for request: URLRequest, fromFile fileURL: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            return try await session.upload(for: request, fromFile: fileURL, delegate: delegate)
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                resume(session.uploadTask(with: request, fromFile: fileURL, completionHandler: continuation.taskCompletionHandler), with: delegate)
            }
        }
    }
    
    /// Backported convenience method to upload data using an URLRequest, creates and resumes an URLSessionUploadTask internally.
    ///
    /// - Parameter request: The URLRequest for which to upload data.
    /// - Parameter bodyData: Data to upload.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data and response.
    public func upload(for request: URLRequest, from bodyData: Data, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            return try await session.upload(for: request, from: bodyData, delegate: delegate)
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                resume(session.uploadTask(with: request, from: bodyData, completionHandler: continuation.taskCompletionHandler), with: delegate)
            }
        }
    }
    
    /// Backported convenience method to download using an URLRequest, creates and resumes an URLSessionDownloadTask internally.
    ///
    /// - Parameter request: The URLRequest for which to download.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
    public func download(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (URL, URLResponse) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            return try await session.download(for: request, delegate: delegate)
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                resume(session.downloadTask(with: request, completionHandler: continuation.taskCompletionHandler), with: delegate)
            }
        }
    }
    
    /// Backported convenience method to download using an URL, creates and resumes an URLSessionDownloadTask internally.
    ///
    /// - Parameter url: The URL for which to download.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
    public func download(from url: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (URL, URLResponse) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            return try await session.download(from: url, delegate: delegate)
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                resume(session.downloadTask(with: url, completionHandler: continuation.taskCompletionHandler), with: delegate)
            }
        }
    }
    
    /// Backported convenience method to resume download, creates and resumes an URLSessionDownloadTask internally.
    ///
    /// - Parameter resumeData: Resume data from an incomplete download.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
    public func download(resumeFrom resumeData: Data, delegate: URLSessionTaskDelegate? = nil) async throws -> (URL, URLResponse) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            return try await session.download(resumeFrom: resumeData, delegate: delegate)
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                resume(session.downloadTask(withResumeData: resumeData, completionHandler: continuation.taskCompletionHandler), with: delegate)
            }
        }
    }
    
    /// Returns a byte stream that conforms to AsyncSequence protocol.
    ///
    /// - Parameter url: The URL for which to load data.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data stream and response.
    public func bytes(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (AsyncBytes, URLResponse) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            let results = try await session.bytes(for: request, delegate: delegate)
            return (AsyncBytes(results.0), results.1)
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                let task = session.dataTask(with: request)
                
                guard let sessionDelegate = session.delegate as? SessionDelegateProxy else {
                    preconditionFailure("Runtime Failure: You must initialize the URLSession with `URLSession.backport(configuration:delegate:delegateQueue:)`, which is necessary to proxy the delegate methods properly.")
                }
                
                let accumulator = DataAccumulator()
                
                sessionDelegate.addTaskDelegate(task: task, delegate: delegate, dataAccumulator: accumulator) { task, accumulator, results in
                    switch results {
                    case .success(let response):
                        continuation.resume(returning: (AsyncBytes(task: task, dataAccumulator: accumulator), response))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                task.resume()
            }
        }
    }
    
    /// Returns a byte stream that conforms to AsyncSequence protocol.
    ///
    /// - Parameter request: The URLRequest for which to load data.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data stream and response.
    public func bytes(from url: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (AsyncBytes, URLResponse) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
            let results = try await session.bytes(from: url, delegate: delegate)
            return (AsyncBytes(results.0), results.1)
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                let task = session.dataTask(with: url)
                
                guard let sessionDelegate = session.delegate as? SessionDelegateProxy else {
                    preconditionFailure("Runtime Failure: You must initialize the URLSession with `URLSession.backport(configuration:delegate:delegateQueue:)`, which is necessary to proxy the delegate methods properly.")
                }
                
                let accumulator = DataAccumulator()
                
                sessionDelegate.addTaskDelegate(task: task, delegate: delegate, dataAccumulator: accumulator) { task, accumulator, results in
                    switch results {
                    case .success(let response):
                        continuation.resume(returning: (AsyncBytes(task: task, dataAccumulator: accumulator), response))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                task.resume()
            }
        }
    }
}
#endif
