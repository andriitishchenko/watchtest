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
@synthesize trackID=_trackID;

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
        
        self.status = NO;
    }
    
    return self;
}


- (void)locationUpdated:(NSNotification*)notification {
    
    CLLocation*location =(CLLocation*)[[notification userInfo] valueForKey:@"data"];
    [self saveLocation:location];
}

-(void)saveLocation:(CLLocation*)location{
    NSLog(@"new location");
    if (location) {
        if (self.trackID) {
        NSManagedObjectContext *moc = [SharedRecorder managedObjectContext];
        Track*track = (Track*)[moc existingObjectWithID:self.trackID error:nil];
//        CLLocation *location = [SharedLocation sharedInstance].currentLocation;
            
            Location*item = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:moc];
            item.latitude = @(location.coordinate.latitude);
            item.longitude = @(location.coordinate.longitude);
            item.altitude = @(location.altitude);
            item.time = @([[NSDate date] timeIntervalSince1970] * 1000);
            item.speed = @(location.speed);
            item.horizontalAccuracy = @(location.horizontalAccuracy);
            item.verticalAccuracy = @(location.verticalAccuracy);
            item.direction = @(location.course);//location.course //north is 0 degrees, east is 90 degrees, south is 180 degrees, and so on
            item.track = track;
            
            [track addWaypointsObject:item];
            
            [SharedRecorder saveChanges:moc];
        }
    }
}

-(void)resumeRecording{
    if (self.status == YES) {
        [[SharedLocation sharedInstance] startLocator];
    }
}

-(void)startRecording{
    if (self.trackID) {
        self.status = YES;
        SharedLocation *sm = [SharedLocation sharedInstance];
        [sm startLocator];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:kLocationUpdateNotiffication object:nil];
    }
}

-(void)stopRecording{
    self.status = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SharedLocation *sm = [SharedLocation sharedInstance];
    [sm resetLocator];
    self.trackID = nil;
}
-(void)dealloc
{
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    @catch (NSException *exception) {
        
    }
}
-(void)setTrackID:(NSManagedObjectID *)trackID
{
    if (trackID) {
        [[NSUserDefaults standardUserDefaults] setURL:[trackID URIRepresentation]
                                               forKey:@"trackID"];
        
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"trackID"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    _trackID = trackID;
}

-(NSManagedObjectID*)trackID
{
    if (_trackID) {
        return _trackID;
    }
    _trackID = nil;
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"trackID"] != nil) {
        AppDelegate*ap = ApplicationDelegate;
        
        NSURL *uri = [[NSUserDefaults standardUserDefaults] URLForKey:@"trackID"];
        _trackID = [ap.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
    }
    return _trackID;
}

+(NSManagedObjectContext *)managedObjectContext{
    NSManagedObjectContext *moc;
    if ([NSThread isMainThread]) {
        moc = [ApplicationDelegate managedObjectContext];
    }
    else{
    
    NSPersistentStoreCoordinator *coordinator = [ApplicationDelegate  persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    moc = [[NSManagedObjectContext alloc] init];
        [moc setPersistentStoreCoordinator:coordinator];
    }
    return moc;
}


+ (void)saveChanges:(NSManagedObjectContext *)managedObjectContext
{
    NSError *error = nil;
    if ([NSThread isMainThread]) {
        [ApplicationDelegate saveContext];
    }
    else{
        if ([managedObjectContext hasChanges] && [managedObjectContext save:&error]) {
            NSLog(@"CORE saveContext YES");
        }
        if (error!=nil) {
            NSLog(@"CORE saveContext NO with error: %@, %@", error, [error userInfo]);
        }
    }
    
}

@end
