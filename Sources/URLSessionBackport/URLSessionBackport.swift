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

// MARK: - Delegate Proxies

extension SessionDelegateProxy: URLSessionDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        originalDelegate?.urlSession?(session, didBecomeInvalidWithError: error)
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        switch aSelector {
        case #selector(urlSession(_:didReceive:completionHandler:)):
            /// `urlSession(_:didReceive:completionHandler:)` has specific fallback handling when the delegate does not implement the method, so hide our implementation if the ``originalDelegate`` also doesn't implement the method: "if you do not implement this method, the session calls its delegate’s  `urlSession(_:task:didReceive:completionHandler:)` method instead."
            if originalDelegate?.urlSession(_:didReceive:completionHandler:) == nil {
                return false
            }
            return super.responds(to: aSelector)
        default:
            return super.responds(to: aSelector)
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let delegateMethod = originalDelegate?.urlSession(_:didReceive:completionHandler:) {
            delegateMethod(session, challenge, completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    @available(macOS 11.0, *)
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        originalDelegate?.urlSessionDidFinishEvents?(forBackgroundURLSession: session)
    }
}

/// Note that some of these delegate proxies may be misshandled. If you encounter bugs with some of the more esoteric task delegates, especially compared with how modern OSs handled tiering for task-based delegates, please file an issue or submit a fix to: https://github.com/mochidev/URLSessionBackport/issues
/// Some of the methods use a tiered approach, specifically those that require completion handlers, while others call all applicable delegates one after another.
extension SessionDelegateProxy: URLSessionTaskDelegate {
    var originalTaskDelegate: URLSessionTaskDelegate? { originalDelegate as? URLSessionTaskDelegate }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        if let taskDelegateMethod = taskMap[task.taskIdentifier]?.delegate?.urlSession(_:task:willBeginDelayedRequest:completionHandler:) {
            taskDelegateMethod(session, task, request, completionHandler)
        } else if let delegateMethod = originalTaskDelegate?.urlSession(_:task:willBeginDelayedRequest:completionHandler:) {
            delegateMethod(session, task, request, completionHandler)
        } else {
            completionHandler(.continueLoading, nil)
        }
    }
    
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        taskMap[task.taskIdentifier]?.delegate?.urlSession?(session, taskIsWaitingForConnectivity: task)
        originalTaskDelegate?.urlSession?(session, taskIsWaitingForConnectivity: task)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if let taskDelegateMethod = taskMap[task.taskIdentifier]?.delegate?.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:) {
            taskDelegateMethod(session, task, response, request, completionHandler)
        } else if let delegateMethod = originalTaskDelegate?.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:) {
            delegateMethod(session, task, response, request, completionHandler)
        } else {
            completionHandler(request)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let taskDelegateMethod = taskMap[task.taskIdentifier]?.delegate?.urlSession(_:task:didReceive:completionHandler:) {
            taskDelegateMethod(session, task, challenge, completionHandler)
        } else if let delegateMethod = originalTaskDelegate?.urlSession(_:task:didReceive:completionHandler:) {
            delegateMethod(session, task, challenge, completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        if let taskDelegateMethod = taskMap[task.taskIdentifier]?.delegate?.urlSession(_:task:needNewBodyStream:) {
            taskDelegateMethod(session, task, completionHandler)
        } else if let delegateMethod = originalTaskDelegate?.urlSession(_:task:needNewBodyStream:) {
            delegateMethod(session, task, completionHandler)
        } else {
            completionHandler(nil)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        taskMap[task.taskIdentifier]?.delegate?.urlSession?(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
        originalTaskDelegate?.urlSession?(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    
    // This is not implemented, since it was introduced along with macOS 12/iOS 15, and the proxy won't be used on that OS version anyways.
    // func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics)
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let taskDelegate = taskMap[task.taskIdentifier]
        if let accumulator = taskDelegate?.dataAccumulator {
            if let error = error {
                // An accumulator will only be set for data tasks, so we can assume this is the case if one is available.
                accumulator.onResponse?(task as! URLSessionDataTask, accumulator, .failure(error))
                taskDelegate?.dataAccumulator?.result = .failure(error)
            } else {
                taskDelegate?.dataAccumulator?.result = .success(())
            }
            
            accumulator.onResponse = nil
        }
        
        taskDelegate?.delegate?.urlSession?(session, task: task, didCompleteWithError: error)
        originalTaskDelegate?.urlSession?(session, task: task, didCompleteWithError: error)
        
        removeTaskDelegate(task: task)
    }
}

extension SessionDelegateProxy: URLSessionDataDelegate {
    var originalDataDelegate: URLSessionDataDelegate? { originalDelegate as? URLSessionDataDelegate }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // Note from AsyncBytes documentation: "Delegate will not be called for response and data delivery."
        let taskDelegate = taskMap[dataTask.taskIdentifier]
        
        func verifyDisposition(_ disposition: URLSession.ResponseDisposition) {
            // If we have an accumulator, we are interested in the results of the disposition!
            if case .allow = disposition, let accumulator = taskDelegate?.dataAccumulator {
                accumulator.onResponse?(dataTask, accumulator, .success(response))
                accumulator.onResponse = nil
            }
            completionHandler(disposition)
        }
        
        if let taskDelegateMethod = taskDelegate?.dataDelegate?.urlSession(_:dataTask:didReceive:completionHandler:) {
            taskDelegateMethod(session, dataTask, response, verifyDisposition)
        } else if let delegateMethod = originalDataDelegate?.urlSession(_:dataTask:didReceive:completionHandler:) {
            delegateMethod(session, dataTask, response, verifyDisposition)
        } else {
            verifyDisposition(.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        taskMap[dataTask.taskIdentifier]?.dataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
        originalDataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
        // Note: The continuation in an accumulator may leak at this point, and should be verified.
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        taskMap[dataTask.taskIdentifier]?.dataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
        originalDataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
        // Note: The continuation in an accumulator may leak at this point, and should be verified.
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Note from AsyncBytes documentation: "Delegate will not be called for response and data delivery."
        let taskDelegate = taskMap[dataTask.taskIdentifier]
        taskDelegate?.dataAccumulator?.addBuffer(data)
        taskDelegate?.dataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: data)
        originalDataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        if let taskDelegateMethod = taskMap[dataTask.taskIdentifier]?.dataDelegate?.urlSession(_:dataTask:willCacheResponse:completionHandler:) {
            taskDelegateMethod(session, dataTask, proposedResponse, completionHandler)
        } else if let delegateMethod = originalDataDelegate?.urlSession(_:dataTask:willCacheResponse:completionHandler:) {
            delegateMethod(session, dataTask, proposedResponse, completionHandler)
        } else {
            completionHandler(proposedResponse)
        }
    }
}

extension SessionDelegateProxy: URLSessionDownloadDelegate {
    var originalDownloadDelegate: URLSessionDownloadDelegate? { originalDelegate as? URLSessionDownloadDelegate }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Note that these methods are considered to be mandatory, which might cause issues?
        if let taskDownloadDelegate = taskMap[downloadTask.taskIdentifier]?.downloadDelegate,
           taskDownloadDelegate.responds(to: #selector(urlSession(_:downloadTask:didFinishDownloadingTo:))) {
            taskMap[downloadTask.taskIdentifier]?.downloadDelegate?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
        }
        if let originalDownloadDelegate = originalDownloadDelegate,
           originalDownloadDelegate.responds(to: #selector(urlSession(_:downloadTask:didFinishDownloadingTo:))) {
            originalDownloadDelegate.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        taskMap[downloadTask.taskIdentifier]?.downloadDelegate?.urlSession?(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        originalDownloadDelegate?.urlSession?(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        taskMap[downloadTask.taskIdentifier]?.downloadDelegate?.urlSession?(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
        originalDownloadDelegate?.urlSession?(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
    }
}

extension SessionDelegateProxy: URLSessionStreamDelegate {
    var originalStreamDelegate: URLSessionStreamDelegate? { originalDelegate as? URLSessionStreamDelegate }
    
    func urlSession(_ session: URLSession, readClosedFor streamTask: URLSessionStreamTask) {
        taskMap[streamTask.taskIdentifier]?.streamDelegate?.urlSession?(session, readClosedFor: streamTask)
        originalStreamDelegate?.urlSession?(session, readClosedFor: streamTask)
    }
    
    func urlSession(_ session: URLSession, writeClosedFor streamTask: URLSessionStreamTask) {
        taskMap[streamTask.taskIdentifier]?.streamDelegate?.urlSession?(session, writeClosedFor: streamTask)
        originalStreamDelegate?.urlSession?(session, writeClosedFor: streamTask)
    }
    
    func urlSession(_ session: URLSession, betterRouteDiscoveredFor streamTask: URLSessionStreamTask) {
        taskMap[streamTask.taskIdentifier]?.streamDelegate?.urlSession?(session, betterRouteDiscoveredFor: streamTask)
        originalStreamDelegate?.urlSession?(session, betterRouteDiscoveredFor: streamTask)
    }
    
    func urlSession(_ session: URLSession, streamTask: URLSessionStreamTask, didBecome inputStream: InputStream, outputStream: OutputStream) {
        taskMap[streamTask.taskIdentifier]?.streamDelegate?.urlSession?(session, streamTask: streamTask, didBecome: inputStream, outputStream: outputStream)
        originalStreamDelegate?.urlSession?(session, streamTask: streamTask, didBecome: inputStream, outputStream: outputStream)
    }
}

extension SessionDelegateProxy: URLSessionWebSocketDelegate {
    var originalWebSocketDelegate: URLSessionWebSocketDelegate? { originalDelegate as? URLSessionWebSocketDelegate }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        taskMap[webSocketTask.taskIdentifier]?.webSocketDelegate?.urlSession?(session, webSocketTask: webSocketTask, didOpenWithProtocol: `protocol`)
        originalWebSocketDelegate?.urlSession?(session, webSocketTask: webSocketTask, didOpenWithProtocol: `protocol`)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        taskMap[webSocketTask.taskIdentifier]?.webSocketDelegate?.urlSession?(session, webSocketTask: webSocketTask, didCloseWith: closeCode, reason: reason)
        originalWebSocketDelegate?.urlSession?(session, webSocketTask: webSocketTask, didCloseWith: closeCode, reason: reason)
    }
}
#endif
