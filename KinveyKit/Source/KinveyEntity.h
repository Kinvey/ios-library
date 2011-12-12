//
//  KinveyEntity.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/17/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KinveyPersistable.h"
#import "KCSClient.h"

/*!  Describes required selectors for requesting entities from the Kinvey Service.
*
* This Protocol should be implemented by a client for processing the results of an Entity request against the KCS
* service.
*/
@protocol KCSEntityDelegate <NSObject>

/*!
*  Called when a request fails for some reason (including network failure, internal server failure, request issues...)
 @param entity The Object that was attempting to be fetched.
 @param error An object that encodes our error message (Documentation TBD)
*/
- (void) entity: (id <KCSPersistable>)entity fetchDidFailWithError: (NSError *)error;

/*!
* Called when a request completes successfully.
 @param entity The Object that was attempting to be fetched.
 @param result The result of the completed request (Typically NSData encoded JSON)
*/
- (void) entity: (id <KCSPersistable>)entity fetchDidCompleteWithResult: (NSObject *)result;

@end

/*!  Add ActiveRecord capabilities to the built-in root object (NSObject) of the AppKit/Foundation system.
*
* This category is used to cause any NSObject to be able to be persisted into the Kinvey Cloud Service.
*/
@interface NSObject (KCSEntity) <KCSPersistable>

/*! Fetch one instance of this entity from KCS
*
* @param collection Collection to pull the entity from
* @param query Arbitrary JSON query to execute on KCS (See Queries in KCS documentation for details on Queries)
* @param delegate Delegate object to inform upon completion or failure of this request 
*/
- (void)fetchOneFromCollection: (KCSCollection *)collection matchingQuery: (NSString *)query withDelegate: (id<KCSEntityDelegate>)delegate;

/*! Fetch first entity with a given Boolean value for a property
*
* @param property property to query
* @param value Boolean value (YES or NO) to query against value
* @param collection Collection to pull the entity from
* @param delegate Delegate object to inform upon completion or failure of this request
*/
- (void)findEntityWithProperty: (NSString *)property matchingBoolValue: (BOOL)value fromCollection: (KCSCollection *)collection withDelegate: (id<KCSEntityDelegate>)delegate;

/*! Fetch first entity with a given Double value for a property
*
* @param property property to query
* @param value Real value to query against value
* @param collection Collection to pull the entity from
* @param delegate Delegate object to inform upon completion or failure of this request
*/
- (void)findEntityWithProperty: (NSString *)property matchingDoubleValue: (double)value fromCollection: (KCSCollection *)collection withDelegate: (id<KCSEntityDelegate>)delegate;

/*! Fetch first entity with a given Integer value for a property
*
* @param property property to query
* @param value Integer to query against value
* @param collection Collection to pull the entity from
* @param delegate Delegate object to inform upon completion or failure of this request
*/
- (void)findEntityWithProperty: (NSString *)property matchingIntegerValue: (int)value fromCollection: (KCSCollection *)collection withDelegate: (id<KCSEntityDelegate>)delegate;

/*! Fetch first entity with a given String value for a property
*
* @param property property to query
* @param value String to query against value
* @param collection Collection to pull the entity from
* @param delegate Delegate object to inform upon completion or failure of this request
*/
- (void)findEntityWithProperty: (NSString *)property matchingStringValue: (NSString *)value fromCollection: (KCSCollection *)collection withDelegate: (id<KCSEntityDelegate>)delegate;

/*! Return the "_id" value for this entity
*
* @returns the "_id" value for this entity.
*/
- (NSString *)kinveyObjectId;

/*! Returns the value for a given property in this entity
*
* @param property The property that we're interested in.
* @returns the value of this property.
*/
//- (NSString *)valueForProperty: (NSString *)property;

/*! Set a value for a given property
* @param value The value to set for the given property
* @param property The property to assign this value to.
*/
- (void)setValue: (NSString *)value forProperty: (NSString *)property;


/*! Load an entity with a specific ID and replace the current object
* @param objectID The ID of the entity to request
* @param collection Collection to pull the entity from
* @param delegate The delegate to notify upon completion of the load.
*/
- (void)loadObjectWithID: (NSString *)objectID fromCollection: (KCSCollection *)collection withDelegate:(id <KCSEntityDelegate>)delegate;

@end
