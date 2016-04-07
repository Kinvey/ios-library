//
//  Query.h
//  Kinvey
//
//  Created by Victor Barros on 2016-02-12.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Query : NSObject

@property NSPredicate* predicate;
@property NSArray<NSSortDescriptor*>* sortDescriptors;

-(instancetype)initWithPredicate:(NSPredicate*)predicate
                 sortDescriptors:(NSArray<NSSortDescriptor*>*)sortDescriptors;

@end
