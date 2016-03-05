//
//  PendingOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(KCSPendingOperation)
public protocol PendingOperation {
    
    var objectId: String? { get }
    
    func buildRequest() -> NSURLRequest
    
}
