//
//  KCSObjectMapper.h
//  KinveyKit
//
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KinveyPersistable.h"

@interface KCSKinveyRef : NSObject
@property (nonatomic, strong) id<KCSPersistable>object;
@property (nonatomic, copy) NSString* collectionName;
@end

@interface KCSSerializedObject : NSObject
@property (nonatomic, readonly) BOOL isPostRequest;
@property (nonatomic, readonly) NSString *objectId;
@property (strong, nonatomic, readonly) NSDictionary *dataToSerialize;
@property (strong, nonatomic, readonly) NSArray* resourcesToSave;
@property (strong, nonatomic, readonly) NSArray* referencesToSave;
@property (strong, nonatomic, readonly) id<KCSPersistable> handleToOriginalObject;
@property (nonatomic, strong) NSDictionary* userInfo;
- (void) restoreReferences:(KCSSerializedObject*)previousObject;
@end

@interface KCSObjectMapper : NSObject

+ (id)populateObject:(id)object withData: (NSDictionary *)data;
+ (id)populateExistingObject:(KCSSerializedObject*)serializedObject withNewData:(NSDictionary*)data;
+ (id)makeObjectOfType:(Class)objectClass withData: (NSDictionary *)data;
+ (id)makeObjectWithResourcesOfType:(Class)objectClass withData:(NSDictionary *)data withResourceDictionary:(NSMutableDictionary*)resources;
+ (KCSSerializedObject *)makeKinveyDictionaryFromObject:(id)object error:(NSError**)error;
+ (KCSSerializedObject *)makeResourceEntityDictionaryFromObject:(id)object forCollection:(NSString*)collectionName error:(NSError**)error;

@end
