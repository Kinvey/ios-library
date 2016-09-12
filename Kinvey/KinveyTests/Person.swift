//
//  Person.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-05.
//  Copyright © 2016 Kinvey. All rights reserved.
//

@testable import Kinvey

class Person: Entity {
    
    dynamic var personId: String?
    dynamic var name: String?
    dynamic var age: Int = 0
    
    dynamic var address: Address?
    
    override class func collectionName() -> String {
        return "Person"
    }
    
    override func propertyMapping(map: Map) {
        super.propertyMapping(map)
        
        personId <- ("personId", map[PersistableIdKey])
        name <- map["name"]
        age <- map["age"]
        address <- ("address", map["address"], AddressTransform())
    }
    
}

class AddressTransform: TransformType {
    
    typealias Object = Address
    typealias JSON = [String : AnyObject]
    
    func transformFromJSON(value: AnyObject?) -> Object? {
        var jsonDict: [String : AnyObject]? = nil
        if let value = value as? String,
            let data = value.dataUsingEncoding(NSUTF8StringEncoding),
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
        {
            jsonDict = json as? [String : AnyObject]
        } else {
            jsonDict = value as? [String : AnyObject]
        }
        if let jsonDict = jsonDict {
            let address = Address()
            address.city = jsonDict["city"] as? String
            return address
        }
        return nil
    }
    
    func transformToJSON(value: Object?) -> JSON? {
        if let value = value {
            var json = [String : AnyObject]()
            if let city = value.city {
                json["city"] = city
            }
            return json
        }
        return nil
    }
    
}

class Address: Entity {
    
    dynamic var city: String?
    
}