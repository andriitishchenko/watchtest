//
//  SharedLocation.m
//  ??
//
//  Created by AndruX on 5/5/13.
//  Copyright (c) 2013 cpcs. All rights reserved.
//

#import "SharedLocation.h"



#define RAD_TO_DEG(r) ((r) * (180 / M_PI))
#define DEG_TO_RAD(angle) ((angle) / 180.0 * M_PI)

@interface CLLocation (Direction)
- (CLLocationDirection)directionToLocation:(CLLocation *)location;
@end

@implementation CLLocation (Direction)

- (CLLocationDirection)directionToLocation:(CLLocation *)location {
    
    CLLocationCoordinate2D coord1 = self.coordinate;
    CLLocationCoordinate2D coord2 = location.coordinate;
    
    CLLocationDegrees deltaLong = coord2.longitude - coord1.longitude;
    CLLocationDegrees yComponent = sin(deltaLong) * cos(coord2.latitude);
    CLLocationDegrees xComponent = (cos(coord1.latitude) * sin(coord2.latitude)) - (sin(coord1.latitude) * cos(coord2.latitude) * cos(deltaLong));
    
    CLLocationDegrees radians = atan2(yComponent, xComponent);
    CLLocationDegrees degrees = RAD_TO_DEG(radians) + 360;
    
    return fmod(degrees, 360);
}

@end

static NSString *geolocationCgenType[] = { @"map", @"gps", @"sgps"};
typedef NS_ENUM(NSUInteger, GeolocationCgenType) {
    geolocationCgenTypeMAP = 0,//map
    geolocationCgenTypeGPS = 1, //GPS device
    geolocationCgenTypeSGPS = 2 //GPS device CHINA
};

@interface SharedLocation()
    @property (nonatomic) GeolocationCgenType cgenType;
@end

@implementation SharedLocation


+ (SharedLocation *)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        
//        [sharedInstance startLocator];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        
        self.sharedManager = [CLLocationManager new];
        self.sharedManager.delegate = self;
        self.sharedManager.distanceFilter = 10;
        self.sharedManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        self.sharedManager.headingFilter = 5;
        self.direction = -1;
        
        [self.sharedManager allowDeferredLocationUpdatesUntilTraveled:10 timeout:CLTimeIntervalMax];
        

//#if DEBUG
//        self.currentLocation = [[CLLocation alloc] initWithLatitude:1 longitude:1];
//#else
        self.currentLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
//#endif        
        self.cgenType = geolocationCgenTypeGPS;
    }
    
    return self;
}

+(BOOL)isServiceEnabled
{
    BOOL REZ = YES;
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if ([CLLocationManager locationServicesEnabled] == NO) {
        REZ = NO;
    } else if (status == kCLAuthorizationStatusDenied) {
        REZ = NO;
    } else if (status == kCLAuthorizationStatusRestricted) {
        REZ = NO;
    } else if (status == kCLAuthorizationStatusNotDetermined) {
        REZ = NO;
    }
    
//    kCLAuthorizationStatusAuthorized Location services start without an alert
//    kCLAuthorizationStatusAuthorizedAlways Location services start without an alert
//    kCLAuthorizationStatusAuthorizedWhenInUse Location services start (Always included WhenInUse authorization)
    
    
//    if(REZ==NO && [self.sharedManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
//        //        [sm requestAlwaysAuthorization];
//        [self.sharedManager requestWhenInUseAuthorization];
//    }
    CLLocationManager *sm = [SharedLocation sharedInstance].sharedManager;
    if (REZ==NO && [sm respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [sm requestAlwaysAuthorization];
//        [sm requestWhenInUseAuthorization];
    }
    
    return YES;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
//    BOOL isRuning = NO;
//    switch (status) {
//        case kCLAuthorizationStatusAuthorized:
//            isRuning = YES;
//            break;
//        case kCLAuthorizationStatusAuthorizedWhenInUse:
//            isRuning = YES;
//            break;
//        default:
//            break;
//    }

    [self startLocator];
}

-(void)startLocator
{
    [self resetLocator];

    if ([SharedLocation isServiceEnabled]==YES) {
        [self.sharedManager startUpdatingLocation];
        [self.sharedManager startUpdatingHeading];
        
//        [self.sharedManager startMonitoringSignificantLocationChanges];
    }
}

-(void)resetLocator
{
    if(self.sharedManager)
    {
        [self.sharedManager stopUpdatingHeading];
        [self.sharedManager stopUpdatingLocation];
//        [self.sharedManager stopMonitoringSignificantLocationChanges];

    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    self.currentLocation = [locations objectAtIndex:0];
    NSLog(@"%@",locations);
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateNotiffication object:nil];
//    ALog(@"Your location: lat %f - lon %f", self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude);
}


- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading{
//     NSLog(@"locationManager didUpdateHeading %@", newHeading);
    
    if (newHeading.headingAccuracy < 0)
        return;
    
    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
                                       newHeading.trueHeading : newHeading.magneticHeading);
     self.direction = theHeading;
     self.lastHeading = newHeading;
    
    if (self.error) {
        self.error = nil;
    }
    
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"locationManager didFailWithError %@", error);
    self.error = error;
    if (!self.currentLocation) {
        self.currentLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    }

    [self resetLocator];
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(restartLocator:) userInfo:nil repeats:NO];

}

-(void)restartLocator:(NSTimer*)timer
{
    [self startLocator];
}

-(void)setMapLocation:(CLLocation *)location
{
    if (location) {
        [self resetLocator];
        self.currentLocation = location;
        self.cgenType = geolocationCgenTypeMAP;
    }
}

+(NSString*)getHeaderLocation{
    SharedLocation*sl = [SharedLocation sharedInstance];
    NSString*string;
    if (sl.currentLocation) {
        NSString*mask = @"geo:%0.8f,%0.8f;cgen=%@;u=100";
        string = [NSString stringWithFormat:mask, sl.currentLocation.coordinate.latitude, sl.currentLocation.coordinate.longitude, geolocationCgenType[sl.cgenType]];
    }
    else
    {
        string = @"geo:0.0,0.0;cgen=gps;u=100";
    }
    return string;
}

@end
