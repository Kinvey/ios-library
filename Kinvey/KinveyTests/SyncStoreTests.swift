//
//  SyncedStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-17.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class SyncStoreTests: StoreTestCase {
    
    class CheckForNetworkURLProtocol: NSURLProtocol {
        
        override class func canInitWithRequest(request: NSURLRequest) -> Bool {
            XCTFail()
            return false
        }
        
    }
    
    override func setUp() {
        super.setUp()
        
        signUp()
        
        store = DataStore<Person>.collection(.Sync)
    }
    
    func testCustomTag() {
        let fileManager = NSFileManager.defaultManager()
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        XCTAssertEqual(paths.count, 1)
        if let path = paths.first {
            let tag = "Custom Identifier"
            let customPath = "\(path)/\(client.appKey!)/\(tag).realm"
            
            let removeFiles: () -> Void = {
                if fileManager.fileExistsAtPath(customPath) {
                    try! fileManager.removeItemAtPath(customPath)
                }
                
                let lockPath = (customPath as NSString).stringByAppendingPathExtension("lock")!
                if fileManager.fileExistsAtPath(lockPath) {
                    try! fileManager.removeItemAtPath(lockPath)
                }
                
                let logPath = (customPath as NSString).stringByAppendingPathExtension("log")!
                if fileManager.fileExistsAtPath(logPath) {
                    try! fileManager.removeItemAtPath(logPath)
                }
                
                let logAPath = (customPath as NSString).stringByAppendingPathExtension("log_a")!
                if fileManager.fileExistsAtPath(logAPath) {
                    try! fileManager.removeItemAtPath(logAPath)
                }
                
                let logBPath = (customPath as NSString).stringByAppendingPathExtension("log_b")!
                if fileManager.fileExistsAtPath(logBPath) {
                    try! fileManager.removeItemAtPath(logBPath)
                }
            }
            
            removeFiles()
            XCTAssertFalse(fileManager.fileExistsAtPath(customPath))
            
            store = DataStore<Person>.collection(.Sync, tag: tag)
            defer {
                removeFiles()
                XCTAssertFalse(fileManager.fileExistsAtPath(customPath))
            }
            XCTAssertTrue(fileManager.fileExistsAtPath(customPath))
        }
    }
    
    func testPurge() {
        save()
        
        XCTAssertEqual(store.syncCount(), 1)
        
        weak var expectationPurge = expectationWithDescription("Purge")
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        store.purge(query) { (count, error) -> Void in
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(count, 1)
            }
            
            expectationPurge?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationPurge = nil
        }
        
        XCTAssertEqual(store.syncCount(), 0)
    }
    
    func testPurgeInvalidDataStoreType() {
        save()
        
        store = DataStore<Person>.collection(.Network)
        
        weak var expectationPurge = expectationWithDescription("Purge")
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        store.purge(query) { (count, error) -> Void in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            
            if let error = error as? NSError {
                XCTAssertEqual(error, Error.InvalidDataStoreType.error)
            }
            
            expectationPurge?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationPurge = nil
        }
    }
    
    func testPurgeTimeoutError() {
        let person = save()
        person.age = person.age + 1
        save(person)
        
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationPurge = expectationWithDescription("Purge")
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        store.purge(query) { (count, error) -> Void in
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            
            expectationPurge?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationPurge = nil
        }
    }
    
    func testSync() {
        save()
        
        XCTAssertEqual(store.syncCount(), 1)
        
        weak var expectationSync = expectationWithDescription("Sync")
        
        store.sync() { count, results, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(Int(count), 1)
            }
            
            expectationSync?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSync = nil
        }

        XCTAssertEqual(store.syncCount(), 0)

    }
    
    func testSyncInvalidDataStoreType() {
        save()
        
        store = DataStore<Person>.collection(.Network)
        
        weak var expectationSync = expectationWithDescription("Sync")
        
        store.sync() { count, results, errors in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(errors)
            
            if let errors = errors {
                if let error = errors.first as? Error {
                    switch error {
                    case .InvalidDataStoreType:
                        break
                    default:
                        XCTFail()
                    }
                }
            }
            
            expectationSync?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSync = nil
        }
    }
    
    func testSyncTimeoutError() {
        save()
        
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationSync = expectationWithDescription("Sync")
        
        store.sync() { count, results, error in
            self.assertThread()
            XCTAssertEqual(count, 0)
            XCTAssertNil(results)
            XCTAssertNotNil(error)
            
            expectationSync?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSync = nil
        }
        XCTAssertEqual(store.syncCount(), 1)
    }
    
    func testSyncNoCompletionHandler() {
        save()
        
        let request = store.sync()
        
        XCTAssertTrue(request is NSObject)
        if let request = request as? NSObject {
            waitValueForObject(request, keyPath: "executing", expectedValue: false)
        }
    }
    
    func testPush() {
        save()
        
        XCTAssertEqual(store.syncCount(), 1)
        
        weak var expectationPush = expectationWithDescription("Push")
        
        store.push() { count, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(Int(count), 1)
            }
            
            expectationPush?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationPush = nil
        }
        
        XCTAssertEqual(store.syncCount(), 0)
    }
    
    func testPushInvalidDataStoreType() {
        //save()
        
        store = DataStore<Person>.collection(.Network)
        
        weak var expectationPush = expectationWithDescription("Push")
        
        store.push() { count, errors in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(errors)
            
            if let errors = errors {
                if let error = errors.first as? Error {
                    switch error {
                    case .InvalidDataStoreType:
                        break
                    default:
                        XCTFail()
                    }
                }
            }
            
            expectationPush?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationPush = nil
        }
    }
    
    func testPushNoCompletionHandler() {
        save()
        
        let request = store.push()
        
        XCTAssertTrue(request is NSObject)
        if let request = request as? NSObject {
            waitValueForObject(request, keyPath: "executing", expectedValue: false)
        }
    }
    
    func testPull() {
        MockKinveyBackend.kid = client.appKey!
        setURLProtocol(MockKinveyBackend.self)
        defer {
            setURLProtocol(nil)
        }
        
        let lmt = NSDate()
        
        MockKinveyBackend.appdata = [
            "Person" : [
                Person { $0.personId = "Victor"; $0.metadata = Metadata { $0.lastModifiedTime = lmt } }.toJSON(),
                Person { $0.personId = "Hugo"; $0.metadata = Metadata { $0.lastModifiedTime = lmt } }.toJSON(),
                Person { $0.personId = "Barros"; $0.metadata = Metadata { $0.lastModifiedTime = lmt } }.toJSON()
            ]
        ]
        
        do {
            weak var expectationPull = expectationWithDescription("Pull")
            
            store.clearCache()
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 3)
                    
                    let cacheCount = Int((self.store.cache?.count())!)
                    XCTAssertEqual(cacheCount, results.count)

                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            let query = Query(format: "personId == %@", "Victor")
            
            weak var expectationPull = expectationWithDescription("Pull")
         
            store.clearCache()
            
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
                    
                    let cacheCount = Int((self.store.cache?.count())!)
                    XCTAssertEqual(cacheCount, results.count)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.personId, "Victor")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        MockKinveyBackend.appdata = [
            "Person" : [
                Person { $0.personId = "Hugo"; $0.metadata = Metadata { $0.lastModifiedTime = lmt } }.toJSON()
            ]
        ]
        
        do {
            let query = Query(format: "personId == %@", "Victor")
            
            weak var expectationPull = expectationWithDescription("Pull")
            
            store.clearCache()
            
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 0)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.personId, "Victor")
                        
                        let cacheCount = Int((self.store.cache?.count())!)
                        XCTAssertEqual(cacheCount, results.count)

                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        MockKinveyBackend.appdata = [
            "Person" : [
                Person { $0.personId = "Victor"; $0.metadata = Metadata { $0.lastModifiedTime = lmt } }.toJSON()
            ]
        ]
        
        
        
        do {
            let query = Query(format: "personId == %@", "Victor")
            
            weak var expectationPull = expectationWithDescription("Pull")
        
            store.clearCache()
            
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.personId, "Victor")
                        
                        let cacheCount = Int((self.store.cache?.count())!)
                        XCTAssertEqual(cacheCount, results.count)

                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    
    func testPullPendingSyncItems() {
        save()
        
        weak var expectationPull = expectationWithDescription("Pull")
        
        store.pull() { results, error in
            self.assertThread()
            XCTAssertNil(results)
            XCTAssertNotNil(error)
            
            expectationPull?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationPull = nil
        }
        
    }
    func testPullInvalidDataStoreType() {
        //save()
        
        store = DataStore<Person>.collection(.Network)
        
        weak var expectationPull = expectationWithDescription("Pull")
        
        store.pull() { results, error in
            self.assertThread()
            XCTAssertNil(results)
            XCTAssertNotNil(error)
            
            if let error = error as? NSError {
                XCTAssertEqual(error, Error.InvalidDataStoreType.error)
            }
            
            expectationPull?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationPull = nil
        }
    }
    
    func testFindById() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        guard let personId = person.personId else { return }
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find(personId) { result, error in
            self.assertThread()
            XCTAssertNotNil(result)
            XCTAssertNil(error)
            
            if let result = result {
                XCTAssertEqual(result.personId, personId)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testFindByQuery() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        guard let personId = person.personId else { return }
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        let query = Query(format: "personId == %@", personId)
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find(query) { results, error in
            self.assertThread()
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertNotNil(results.first)
                if let result = results.first {
                    XCTAssertEqual(result.personId, personId)
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testRemovePersistable() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectationWithDescription("Remove")
        
        do {
            try store.remove(person) { count, error in
                self.assertThread()
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 1)
                }
                
                expectationRemove?.fulfill()
            }
        } catch {
            XCTFail()
            expectationRemove?.fulfill()
        }
            
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemovePersistableIdMissing() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectationWithDescription("Remove")
        
        do {
            person.personId = nil
            try store.remove(person) { count, error in
                XCTFail()
                
                expectationRemove?.fulfill()
            }
            XCTFail()
        } catch {
            expectationRemove?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemovePersistableArray() {
        let person1 = save(newPerson)
        let person2 = save(newPerson)
        
        XCTAssertNotNil(person1.personId)
        XCTAssertNotNil(person2.personId)
        
        guard let personId1 = person1.personId, let personId2 = person2.personId else { return }
        
        XCTAssertNotEqual(personId1, personId2)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectationWithDescription("Remove")
        
        store.remove([person1, person2]) { count, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(count, 2)
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemoveAll() {
        let person1 = save(newPerson)
        let person2 = save(newPerson)
        
        XCTAssertNotNil(person1.personId)
        XCTAssertNotNil(person2.personId)
        
        guard let personId1 = person1.personId, let personId2 = person2.personId else { return }
        
        XCTAssertNotEqual(personId1, personId2)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectationWithDescription("Remove")
        
        store.removeAll() { count, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(count, 2)
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testExpiredTTL() {
        store.ttl = 1.seconds
        
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        NSThread.sleepForTimeInterval(1)
        
        if let personId = person.personId {
            weak var expectationGet = expectationWithDescription("Get")
            
            let query = Query(format: "personId == %@", personId)
            store.find(query, readPolicy: .ForceLocal) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 0)
                }
                
                expectationGet?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationGet = nil
            }
        }
        
        store.ttl = nil
        
        if let personId = person.personId {
            weak var expectationGet = expectationWithDescription("Get")
            
            let query = Query(format: "personId == %@", personId)
            store.find(query, readPolicy: .ForceLocal) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 1)
                }
                
                expectationGet?.fulfill()
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationGet = nil
            }
        }
    }
    
}
