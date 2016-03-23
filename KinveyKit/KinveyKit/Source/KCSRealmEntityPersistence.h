//
//  KCSRealmManager.h
//  Kinvey
//
//  Created by Victor Barros on 2015-12-16.
//  Copyright © 2015 Kinvey. All rights reserved.
//

@import Foundation;
@import Realm;

#import "KCSCache.h"
#import "KCSSync.h"

@interface KCSRealmEntityPersistence : NSObject <KCSCache, KCSSync>

+(RLMRealmConfiguration*)configurationForPersistenceId:(NSString *)persistenceId;

-(instancetype)initWithPersistenceId:(NSString *)persistenceId
                      collectionName:(NSString *)collectionName;

@end
