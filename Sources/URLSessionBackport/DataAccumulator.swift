//
//  DataAccumulator.swift
//  URLSessionBackport
//
//  Created by Dimitri Bouniol on 2021-11-11.
//  Copyright © 2021 Mochi Development, Inc. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2)
/// A data accumulator compatible with AsyncSequence.AsyncIterator to facilitate pulling data from the delegate to a compatible AsyncBytes structure.
///
/// First, the user of this class is expected to call onResponse either as soon as the response is available, or an error is thrown, which will signal that the process should continue or fail respectively. onResponse should then be set to nil so it isn't called again.
/// As buffers are accumulated, they should be passed to ``addBuffer(_:)`` so they can be forwarded when the consumer is ready.
/// When data dries up, or an error is thrown, result should be set to a non-`nil` value, indicating either success or failure accordingly.
@usableFromInline
class DataAccumulator: BytesProvider {
    /// The current offset within the first-in-line data buffer.
    var currentOffset: Int = 0
    /// A FIFO data buffer queue to propogate to AsyncBytes, one byte at a time.
    var remainingDataBuffers: [Data] = []
    var result: Result<Void, Error>? = nil {
        didSet {
            /// If we were waiting on a continuation, that means there is no data available, so just use it:
            if let continuation = continuation {
                switch result {
                case .none:                 return
                case .success:              continuation.resume(returning: nil)
                case .failure(let error):   continuation.resume(throwing: error)
                }
            }
            continuation = nil
        }
    }
    
    /// The continuation to resume if anything is waiting on the accumulator for more data. This is set only when the accumulator had no more data when more was requested.
    var continuation: CheckedContinuation<UInt8?, Error>?
    
    /// The closure to call when the first response, or error, is encountered.
    var onResponse: ((URLSessionDataTask, DataAccumulator, Result<URLResponse, Error>) -> Void)?
    
    init() {}
    
    func addBuffer(_ data: Data) {
        /// Skip situations where data is empty, since we'll fail to pull anything from it down the line.
        guard !data.isEmpty else { return }
        remainingDataBuffers.append(data)
        
        /// If we were waiting on a continuation, that means there is no data currently available, so just use it:
        if let continuation = continuation {
            /// Pull the next byte off the stack, and cycle the buffers if necessary.
            let nextByte = data[currentOffset]
            currentOffset += 1
            if currentOffset >= data.count {
                currentOffset = 0
                remainingDataBuffers.removeFirst()
            }
            continuation.resume(returning: nextByte)
        }
        continuation = nil
    }
    
    @usableFromInline
    func next() async throws -> UInt8? {
        switch (remainingDataBuffers.first, result) {
        case (.some(let first), _):
            /// We have bytes to give, so pull the next byte off the stack, and cycle the buffers if necessary.
            let byte = first[currentOffset]
            currentOffset += 1
            if currentOffset >= first.count {
                currentOffset = 0
                remainingDataBuffers.removeFirst()
            }
            return byte
        
        /// We ran out of data, so check the result to determine what to do next:
        case (_, .none):
            /// There is no explicit end in sight, so prepare a continuation to get updated when there is more.
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        case (_, .success):
            /// We don't expect any more data, so return `nil` to signal the end.
            return nil
        case (_, .failure(let error)):
            /// An error was delivered, so now is a good time to process it.
            throw error
        }
    }
}
#endif
