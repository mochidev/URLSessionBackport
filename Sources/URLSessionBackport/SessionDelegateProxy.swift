//
//  SessionDelegateProxy.swift
//  URLSessionBackport
//
//  Created by Dimitri Bouniol on 2021-11-11.
//  Copyright © 2021 Mochi Development, Inc. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2)
/// A delegate proxy for the real URLSession's delegate.
///
/// This class forwards all delegate methods supported pre iOS15/macOS 12 to both the underlying session delegate and any assigned task delegates, consisting of the majority of the backporting work.
class SessionDelegateProxy: NSObject {
    var originalDelegate: URLSessionDelegate?
    var taskMap: [Int : TaskDelegateHandler] = [:]
    
    init(originalDelegate: URLSessionDelegate?) {
        self.originalDelegate = originalDelegate
    }
    
    /// Add a new task delegate to track.
    /// - Parameters:
    ///   - task: The task to add.
    ///   - delegate: The delegate for the task.
    func addTaskDelegate(task: URLSessionTask, delegate: URLSessionTaskDelegate?, dataAccumulator: DataAccumulator? = nil, onResponse: ((URLSessionDataTask, DataAccumulator, Result<URLResponse, Error>) -> Void)? = nil) {
        dataAccumulator?.onResponse = onResponse
        taskMap[task.taskIdentifier] = TaskDelegateHandler(task: task, delegate: delegate, dataAccumulator: dataAccumulator)
    }
    
    /// Remove a task delegate when the task is finished.
    /// - Parameter task: the task to remove.
    func removeTaskDelegate(task: URLSessionTask) {
        taskMap.removeValue(forKey: task.taskIdentifier)
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
