//
//  SharedRecorder.m
//  watchtest
//
//  Created by Andrii Tishchenko on 24.07.15.
//  Copyright (c) 2015 Andrii Tishchenko. All rights reserved.
//

#import "SharedRecorder.h"
#import "Track.h"
#import "Location.h"


@implementation SharedRecorder

+ (SharedRecorder *)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        
    }
    
    return self;
}


- (void)locationUpdated:(NSNotification*)notification {
    [self saveLocation];
}

-(void)saveLocation{
    
    
    if (self.trackID) {
        NSManagedObjectContext *moc = [ApplicationDelegate managedObjectContext];
        Track*track = [moc existingObjectWithID:self.trackID error:nil];
        CLLocation *location = [SharedLocation sharedInstance].currentLocation;
        
        if (location) {
            
            Location*item = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:moc];
            item.latitude = @(location.coordinate.latitude);
            item.longitude = @(location.coordinate.longitude);
            item.altitude = @(location.altitude);
            item.time = @([[NSDate date] timeIntervalSince1970] * 1000);
            item.speed = @(location.speed);
//            location.course //north is 0 degrees, east is 90 degrees, south is 180 degrees, and so on
            item.direction = @(location.course);
//           
            item.track = track;
            
             [track addWaypointsObject:item];
            
            [ApplicationDelegate saveChangesInContext:moc];
        }
    }
}

-(void)startRecording{
    SharedLocation *sm = [SharedLocation sharedInstance];
    [sm startLocator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:kLocationUpdateNotiffication object:nil];
}

-(void)stopRecording{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SharedLocation *sm = [SharedLocation sharedInstance];
    [sm resetLocator];
}
-(void)dealloc
{
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    @catch (NSException *exception) {
        
    }
}



@end
