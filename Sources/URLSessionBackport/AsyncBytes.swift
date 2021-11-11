//
//  AsyncBytes.swift
//  URLSessionBackport
//
//  Created by Dimitri Bouniol on 2021-11-11.
//  Copyright © 2021 Mochi Development, Inc. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2)
extension URLSession.Backport {
    
    /// AsyncBytes conforms to AsyncSequence for data delivery. The sequence is single pass. Delegate will not be called for response and data delivery.
    public struct AsyncBytes : AsyncSequence {
        
        public typealias Element = UInt8
        public typealias AsyncIterator = Iterator
        
        @usableFromInline
        enum Storage {
            case standard(Any)
            case dataAccumulator(DataAccumulator)
        }
        
        /// Underlying data task providing the bytes.
        internal(set) public var task: URLSessionDataTask
        
        var storage: Storage
        
        init(task: URLSessionDataTask, dataAccumulator: DataAccumulator) {
            self.task = task
            self.storage = .dataAccumulator(dataAccumulator)
        }
        
        @available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
        init(_ asyncBytes: URLSession.AsyncBytes) {
            self.task = asyncBytes.task
            self.storage = .standard(asyncBytes)
        }
        
        public struct Iterator : AsyncIteratorProtocol {
            public typealias Element = UInt8
            
            @usableFromInline
            var storage: Storage
            
            init(_ storage: Storage) {
                self.storage = storage
            }
            
            @inlinable public mutating func next() async throws -> UInt8? {
                switch storage {
                case .standard(let any):
                    guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) else { preconditionFailure("Standard mistakenly set on older OS!") }
                    var iterator = any as! URLSession.AsyncBytes.Iterator
                    let value = try await iterator.next()
                    storage = .standard(iterator) // save the modified iterator
                    return value
                case .dataAccumulator(let dataAccumulator):
                    return try await dataAccumulator.consume()
                }
            }
        }
        
        public func makeAsyncIterator() -> Iterator {
            switch storage {
            case .standard(let any):
                guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) else { preconditionFailure("Standard mistakenly set on older OS!") }
                let sequence = any as! URLSession.AsyncBytes
                return Iterator(.standard(sequence.makeAsyncIterator()))
            case .dataAccumulator(let dataAccumulator):
                return Iterator(.dataAccumulator(dataAccumulator))
            }
        }
    }
}
#endif
