//
//  URLSessionBackport.swift
//  DynamicCodable
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
    public var backport: Backport {
        Backport(self)
    }
}

#if compiler(>=5.5.2)
@available(macOS, introduced: 10.15, deprecated: 12.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in methods instead.")
@available(iOS, introduced: 13.0, deprecated: 15.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in methods instead.")
@available(watchOS, introduced: 6.0, deprecated: 8.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in methods instead.")
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
                let task = session.dataTask(with: request) { data, response, error in
                    switch (data, response, error) {
                    case (.some(let data), .some(let response), .none):
                        continuation.resume(returning: (data, response))
                    case (.none, .none, .some(let error)):
                        continuation.resume(throwing: error)
                    default:
                        preconditionFailure("The data task returned incompatible data")
                    }
                }
                
                task.resume()
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
                let task = session.dataTask(with: url) { data, response, error in
                    switch (data, response, error) {
                    case (.some(let data), .some(let response), .none):
                        continuation.resume(returning: (data, response))
                    case (.none, .none, .some(let error)):
                        continuation.resume(throwing: error)
                    default:
                        preconditionFailure("The data task returned incompatible data")
                    }
                }
                
                task.resume()
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
                let task = session.uploadTask(with: request, fromFile: fileURL) { data, response, error in
                    switch (data, response, error) {
                    case (.some(let data), .some(let response), .none):
                        continuation.resume(returning: (data, response))
                    case (.none, .none, .some(let error)):
                        continuation.resume(throwing: error)
                    default:
                        preconditionFailure("The upload task returned incompatible data")
                    }
                }
                
                task.resume()
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
                let task = session.uploadTask(with: request, from: bodyData) { data, response, error in
                    switch (data, response, error) {
                    case (.some(let data), .some(let response), .none):
                        continuation.resume(returning: (data, response))
                    case (.none, .none, .some(let error)):
                        continuation.resume(throwing: error)
                    default:
                        preconditionFailure("The upload task returned incompatible data")
                    }
                }
                
                task.resume()
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
                let task = session.downloadTask(with: request) { data, response, error in
                    switch (data, response, error) {
                    case (.some(let data), .some(let response), .none):
                        continuation.resume(returning: (data, response))
                    case (.none, .none, .some(let error)):
                        continuation.resume(throwing: error)
                    default:
                        preconditionFailure("The download task returned incompatible data")
                    }
                }
                
                task.resume()
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
                let task = session.downloadTask(with: url) { data, response, error in
                    switch (data, response, error) {
                    case (.some(let data), .some(let response), .none):
                        continuation.resume(returning: (data, response))
                    case (.none, .none, .some(let error)):
                        continuation.resume(throwing: error)
                    default:
                        preconditionFailure("The download task returned incompatible data")
                    }
                }
                
                task.resume()
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
                let task = session.downloadTask(withResumeData: resumeData) { data, response, error in
                    switch (data, response, error) {
                    case (.some(let data), .some(let response), .none):
                        continuation.resume(returning: (data, response))
                    case (.none, .none, .some(let error)):
                        continuation.resume(throwing: error)
                    default:
                        preconditionFailure("The download task returned incompatible data")
                    }
                }
                
                task.resume()
            }
        }
    }
}
#endif
