//
//  ReadOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class ReadOperation<T: Persistable, R, E>: Operation<T> where T: NSObject {
    
    typealias CompletionHandler = (Result<R, E>) -> Void
    
    let readPolicy: ReadPolicy
    
    init(
        readPolicy: ReadPolicy,
        cache: AnyCache<T>?,
        options: Options?
    ) {
        self.readPolicy = readPolicy
        super.init(
            cache: cache,
            options: options
        )
    }
    
}

protocol ReadOperationType {
    
    associatedtype SuccessType
    associatedtype FailureType
    typealias CompletionHandler = (Result<SuccessType, FailureType>) -> Void
    
    var readPolicy: ReadPolicy { get }
    
    @discardableResult
    func executeLocal(_ completionHandler: CompletionHandler?) -> Request
    
    @discardableResult
    func executeNetwork(_ completionHandler: CompletionHandler?) -> Request
    
}

extension ReadOperationType {
    
    @discardableResult
    func execute(_ completionHandler: CompletionHandler? = nil) -> Request {
        switch readPolicy {
        case .forceLocal:
            return executeLocal(completionHandler)
        case .forceNetwork:
            return executeNetwork(completionHandler)
        case .both:
            let request = MultiRequest()
            executeLocal() { result in
                completionHandler?(result)
                request.addRequest(self.executeNetwork(completionHandler))
            }
            return request
        }
    }
    
}
