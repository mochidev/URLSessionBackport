//
//  URLSessionBackport.swift
//  DynamicCodable
//
//  Created by Dimitri Bouniol on 2021-11-10.
//  Copyright © 2021 Mochi Development, Inc. All rights reserved.
//

import Foundation

extension URLSession {
    
    /// Access backported methods that are inter-compatible with older and newer OSs.
    ///
    /// This uses Dave DeLong's naming convention: https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/
    public var backport: Backport {
        Backport(self)
    }
    
    /// This is the namespace for backward compatible API.
    public struct Backport {
        let session: URLSession
        
        init(_ session: URLSession) {
            self.session = session
        }
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)
@available(macOS, introduced: 10.15, deprecated: 12.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in methods instead.")
@available(iOS, introduced: 13.0, deprecated: 15.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in methods instead.")
@available(watchOS, introduced: 6.0, deprecated: 8.0, message: "This override is no longer necessary; you should remove `.backport` and use the built-in methods instead.")
extension URLSession.Backport {
    
}
#endif
