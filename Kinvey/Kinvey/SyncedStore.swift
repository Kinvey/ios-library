//
//  SyncedStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class SyncedStore<T: Persistable>: BaseStore<T> {
    
    internal override init(client: Client = Kinvey.sharedClient()) {
        super.init(client: client)
    }
    
    public func initialize(query: Query) {
    }
    
    public func push() {
    }
    
    public func sync(query: Query) {
    }
    
    public func purge() {
    }

}
