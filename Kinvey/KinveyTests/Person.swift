//
//  Person.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-05.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import ObjectMapper
@testable import Kinvey

class Person: Entity {
    
    dynamic var personId: String?
    dynamic var name: String?
    dynamic var age: Int = 0
    
    override class func kinveyCollectionName() -> String {
        return "Person"
    }
    
    override class func kinveyObjectIdPropertyName() -> String {
        return "personId"
    }
    
    override func mapping(map: Map) {
        super.mapping(map)
        
        personId <- map[PersistableIdKey]
        name <- map["name"]
        age <- map["age"]
    }
    
}
