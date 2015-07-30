//
//  Track.m
//  watchtest
//
//  Created by Andrii Tishchenko on 24.07.15.
//  Copyright (c) 2015 Andrii Tishchenko. All rights reserved.
//

#import "Track.h"
#import "Location.h"


@implementation Track

@dynamic time;
@dynamic waypoints;
@dynamic title;


- (NSArray *)sotredWaypoints
{
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
    return [self.waypoints sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
}
@end
