//
//  TaskDelegateHandler.swift
//  URLSessionBackport
//
//  Created by Dimitri Bouniol on 2021-11-11.
//  Copyright © 2021 Mochi Development, Inc. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2)
struct TaskDelegateHandler {
    weak var task: URLSessionTask? {
        didSet {
            if task == nil {
                delegate = nil
                dataAccumulator = nil
            }
        }
    }
    var delegate: URLSessionTaskDelegate?
    var dataAccumulator: DataAccumulator?
    
    // MARK: - Convenience Casts
    
    var dataDelegate: URLSessionDataDelegate? { delegate as? URLSessionDataDelegate }
    var downloadDelegate: URLSessionDownloadDelegate? { delegate as? URLSessionDownloadDelegate }
    var streamDelegate: URLSessionStreamDelegate? { delegate as? URLSessionStreamDelegate }
    var webSocketDelegate: URLSessionWebSocketDelegate? { delegate as? URLSessionWebSocketDelegate }
}
#endif
