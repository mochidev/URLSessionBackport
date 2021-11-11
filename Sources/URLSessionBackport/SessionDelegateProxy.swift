//
//  SessionDelegateProxy.swift
//  URLSessionBackport
//
//  Created by Dimitri Bouniol on 2021-11-11.
//  Copyright © 2021 Mochi Development, Inc. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2)
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
#endif
