//
//  RemoveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVRemoveOperation)
internal class RemoveOperation: WriteOperation {
    
    let query: Query
    
    internal init(query: Query, writePolicy: WritePolicy, sync: Sync? = nil, persistableType: Persistable.Type, cache: Cache? = nil, client: Client) {
        self.query = query
        super.init(writePolicy: writePolicy, sync: sync, persistableType: persistableType, cache: cache, client: client)
    }
    
    override func executeLocal(completionHandler: CompletionHandler? = nil) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            let objects = self.cache?.findEntityByQuery(self.query)
            let count = self.cache?.removeEntitiesByQuery(self.query)
            let request = self.client.networkRequestFactory.buildAppDataRemoveByQuery(collectionName: self.persistableType.kinveyCollectionName(), query: self.query)
            let idKey = self.persistableType.idKey
            if let objects = objects {
                for object in objects {
                    if let objectId = object[idKey] as? String, let sync = self.sync {
                        if objectId.hasPrefix(ObjectIdTmpPrefix) {
                            sync.removeAllPendingOperations(objectId)
                        } else {
                            sync.savePendingOperation(sync.createPendingOperation(request.request, objectId: objectId))
                        }
                    }
                }
            }
            completionHandler?(count, nil)
        }
        return request
    }
    
    override func executeNetwork(completionHandler: CompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildAppDataRemoveByQuery(collectionName: self.persistableType.kinveyCollectionName(), query: query)
        request.execute() { data, response, error in
            if let response = response where response.isResponseOK,
                let results = self.client.responseParser.parse(data),
                let count = results["count"] as? UInt
            {
                self.cache?.removeEntitiesByQuery(self.query)
                completionHandler?(count, nil)
            } else if let error = error {
                completionHandler?(nil, error)
            } else {
                completionHandler?(nil, Error.InvalidResponse)
            }
        }
        return request
    }
    
}
