//
//  AsyncBytes.swift
//  URLSessionBackport
//
//  Created by Dimitri Bouniol on 2021-11-11.
//  Copyright © 2021 Mochi Development, Inc. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2)
/// A type erased provider of bytes that multiple types can successfully conform to.
@usableFromInline
protocol BytesProvider {
    mutating func next() async throws -> UInt8?
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
extension URLSession.AsyncBytes.Iterator: BytesProvider {}

extension URLSession.Backport {
    
    /// AsyncBytes conforms to AsyncSequence for data delivery. The sequence is single pass. Delegate will not be called for response and data delivery.
    public struct AsyncBytes : AsyncSequence {
        
        public typealias Element = UInt8
        public typealias AsyncIterator = Iterator
        
        /// Underlying data task providing the bytes.
        internal(set) public var task: URLSessionDataTask
        
        /// A type erased provider of bytes, so this type can wrap either ``DataAccumulator`` or ``URLSession.AsyncBytes.Iterator``.
        var bytesProvider: BytesProvider
        
        /// Initialize ``AsyncBytes`` with a ``URLSessionDataTask`` and ``DataAccumulator``. This path is taken by the backported methods.
        /// - Parameters:
        ///   - task: The URL task for reference.
        ///   - dataAccumulator: The data accumulator that consumes data from the URLSession's delegate.
        init(task: URLSessionDataTask, dataAccumulator: DataAccumulator) {
            self.task = task
            self.bytesProvider = dataAccumulator
        }
        
        /// Initialize ``AsyncBytes`` with ``URLSession.AsyncBytes``. This path is taken on modern OSs.
        /// - Parameter asyncBytes: The AsyncBytes to read from.
        @available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
        init(_ asyncBytes: URLSession.AsyncBytes) {
            self.task = asyncBytes.task
            self.bytesProvider = asyncBytes.makeAsyncIterator()
        }
        
        public struct Iterator : AsyncIteratorProtocol {
            public typealias Element = UInt8
            
            @usableFromInline
            var bytesProvider: BytesProvider
            
            @inlinable public mutating func next() async throws -> UInt8? {
                try await bytesProvider.next()
            }
        }
        
        public func makeAsyncIterator() -> Iterator {
            Iterator(bytesProvider: bytesProvider)
        }
    }
}
#endif
