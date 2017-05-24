//
//  RemoveByIdOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class RemoveByIdOperation<T: Persistable>: RemoveOperation<T> where T: NSObject {
    
    let objectId: String
    
    internal init(objectId: String, writePolicy: WritePolicy, sync: AnySync? = nil, cache: AnyCache<T>? = nil, client: Client) {
        self.objectId = objectId
        let query = Query(format: "\(T.entityIdProperty()) == %@", objectId as Any)
        let httpRequest = client.networkRequestFactory.buildAppDataRemoveById(collectionName: T.collectionName(), objectId: objectId)
        super.init(query: query, httpRequest: httpRequest, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
    }
    
}
