//
//  Track.h
//  watchtest
//
//  Created by Andrii Tishchenko on 24.07.15.
//  Copyright (c) 2015 Andrii Tishchenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface Track : NSManagedObject

@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSSet *waypoints;
@end

@interface Track (CoreDataGeneratedAccessors)

- (void)addWaypointsObject:(Location *)value;
- (void)removeWaypointsObject:(Location *)value;
- (void)addWaypoints:(NSSet *)values;
- (void)removeWaypoints:(NSSet *)values;

- (NSArray *)sotredWaypoints;
@end
