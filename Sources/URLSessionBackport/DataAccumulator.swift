//
//  DataAccumulator.swift
//  URLSessionBackport
//
//  Created by Dimitri Bouniol on 2021-11-11.
//  Copyright © 2021 Mochi Development, Inc. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2)
@usableFromInline
class DataAccumulator {
    var currentOffset: Int = 0
    var remainingDataBuffers: [Data] = []
    var result: Result<Void, Error>? = nil {
        didSet {
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
        guard !data.isEmpty else { return }
        remainingDataBuffers.append(data)
        
        if let continuation = continuation {
            let first = remainingDataBuffers.first!
            let nextByte = first[currentOffset]
            currentOffset += 1
            if currentOffset >= first.count {
                currentOffset = 0
                remainingDataBuffers.removeFirst()
            }
            continuation.resume(returning: nextByte)
        }
        continuation = nil
    }
    
    @usableFromInline
    func consume() async throws -> UInt8? {
        if let first = remainingDataBuffers.first { // pull the next byte off the stack
            let byte = first[currentOffset]
            currentOffset += 1
            if currentOffset >= first.count {
                currentOffset = 0
                remainingDataBuffers.removeFirst()
            }
            return byte
        } else if try result?.get() == nil { // waiting for more data
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        } else { // finished
            return nil
        }
    }
}
#endif
