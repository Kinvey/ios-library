//
//  NetworkStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class NetworkStore<T: Persistable>: BaseStore<T> {
    
    internal override init(client: Client = Kinvey.sharedClient()) {
        super.init(client: client)
    }
    
    public override func get(id: String, completionHandler: ObjectCompletionHandler?) {
        super.get(id, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    public override func find(query: Query, completionHandler: ArrayCompletionHandler?) {
        super.find(query, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    public override func save(persistable: T, completionHandler: ObjectCompletionHandler?) {
        super.save(persistable, completionHandler: dispatchAsyncTo(completionHandler))
    }
    
    public override func remove(query: Query, completionHandler: IntCompletionHandler?) {
        super.remove(query, completionHandler: dispatchAsyncTo(completionHandler))
    }

}
