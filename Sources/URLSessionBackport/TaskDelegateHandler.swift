//
//  TaskDelegateHandler.swift
//  URLSessionBackport
//
//  Created by Dimitri Bouniol on 2021-11-11.
//  Copyright © 2021 Mochi Development, Inc. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2)
/// A handler for individual task delegates.
///
/// This type boxes the task, user-provided delegate, and data accumulator (for streamed asyc methods) so it can be easily accessed by the main session delegate proxy.
/// Note that the handler should be discarded when no longer in use to clean up the task, delegate, and dataAccumulator.
struct TaskDelegateHandler {
    weak var task: URLSessionTask? {
        didSet { // Note: Not sure if this works when ARC sets the weak variable to nil…
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
