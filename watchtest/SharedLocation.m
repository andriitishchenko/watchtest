//
//  SharedLocation.m
//  ??
//
//  Created by AndruX on 5/5/13.
//  Copyright (c) 2013 cpcs. All rights reserved.
//

#import "SharedLocation.h"
#import <math.h>


static const NSInteger R = 6371007.2;// 6371000;

#define RAD_TO_DEG(r) ((r) * (180 / M_PI))
#define DEG_TO_RAD(angle) ((angle) / 180.0 * M_PI)
#define MID(value1,value2)((value1+value2)/2)

#define FILTERhorizontalAccuracy 60.0f

@interface CLLocation (Direction)
- (CLLocationDirection)directionToLocation:(CLLocation *)location;
- (CLLocation *)midpointWithLocation:(const CLLocation *)location;
- (CLLocation *)maxAccuracy:(CLLocation *)location;
- (CLLocation *)destinationLocationWithInitialBearing:(double)bearing distance:(CLLocationDistance)distance;
@end

@implementation CLLocation (Direction)


- (CLLocation *)destinationLocationWithInitialBearing:(double)bearing distance:(CLLocationDistance)distance {
    double angularDistance = distance/R;
    double brng = DEG_TO_RAD(bearing);
    double lat1 = DEG_TO_RAD(self.coordinate.latitude);
    double lon1 = DEG_TO_RAD(self.coordinate.longitude);
    
    double lat2 = asin( sin(lat1) * cos(angularDistance) +
                       cos(lat1) * sin(angularDistance) * cos(brng) );
    double lon2 = lon1 + atan2( sin(brng) * sin(angularDistance) * cos(lat1),
                               cos(angularDistance) - sin(lat1) * sin(lat2) );
    lon2 = fmod( lon2 + 3 * M_PI, 2 * M_PI ) - M_PI;  // normalise to -180..+180º
    
    return [[CLLocation alloc] initWithLatitude:RAD_TO_DEG(lat2) longitude: RAD_TO_DEG(lon2)];
    
//    [[CLLocation alloc] initWithRadianLatitude:lat2 radianLongitude:lon2];
}

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

- (CLLocation *)midpointWithLocation:(const CLLocation *)location
{
    double dLon = DEG_TO_RAD(location.coordinate.longitude - self.coordinate.longitude);
    double lat1 = DEG_TO_RAD(self.coordinate.latitude);
    double lat2 = DEG_TO_RAD(location.coordinate.latitude);
    double lon1 = DEG_TO_RAD(self.coordinate.longitude);
    
    double Bx = cos(lat2) * cos(dLon);
    double By = cos(lat2) * sin(dLon);
    double lat3 = atan2(sin(lat1) + sin(lat2), sqrt( (cos(lat1)+Bx) * (cos(lat1)+Bx) + By*By ) );
    double lon3 = lon1 + atan2(By, cos(lat1) + Bx);
    CLLocationCoordinate2D crd = {RAD_TO_DEG(lat3),RAD_TO_DEG(lon3)};
    double midAltitude = MID(self.altitude,location.altitude);
    double midHorizontalAccuracy  = MID(self.horizontalAccuracy,location.horizontalAccuracy);
    double midVerticalAccuracy = MID(self.verticalAccuracy,location.verticalAccuracy);
    double midCourse = MID(self.course,location.course);
    double midSpeed = MID(self.speed,location.speed);
    
//    NSTimeInterval difference = [end timeIntervalSinceDate:start];
//    NSDate *middle = [NSDate dateWithTimeInterval:difference / 2 sinceDate:start];
    
//    NSDate* midTimestamp = [NSDate dateWithTimeIntervalSince1970:([self.timestamp timeIntervalSince1970]+[location.timestamp timeIntervalSince1970])/2.0];
    
    CLLocation *rez = [[CLLocation alloc] initWithCoordinate:crd
                                        altitude:midAltitude
                                        horizontalAccuracy:midHorizontalAccuracy
                                        verticalAccuracy:midVerticalAccuracy
                                        course:midCourse
                                        speed:midSpeed
                                        timestamp:[NSDate dateWithTimeIntervalSince1970:MIN([self.timestamp timeIntervalSince1970],[location.timestamp timeIntervalSince1970])]];
    
//    [self initWithLatitude:radiansToDegrees(lat3) longitude:radiansToDegrees(lon3)];
//    rez.course = (self.speed+location.speed)/2;
    
    
    return rez;
    //[[CLLocation alloc] initWithRadianLatitude:lat3 radianLongitude:lon3];
}


-(CLLocation *)maxAccuracy:(CLLocation *)location{
    if (self.horizontalAccuracy > 0 && self.horizontalAccuracy < location.horizontalAccuracy) {
        return self;
    }
    else
        return location;
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
    @property (strong,nonatomic) NSMutableArray* rawData;
    @property (nonatomic) BOOL isStopLocation;
    @property (nonatomic) double dynamicAccuracy;
    @property (strong,nonatomic) CLLocation* rawUndefinedLocation;
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
        self.status = NO;
        self.dynamicAccuracy = FILTERhorizontalAccuracy;
        self.sharedManager = [CLLocationManager new];
        self.sharedManager.delegate = self;
        self.sharedManager.distanceFilter = 10;
//#if DEBUG
//        self.sharedManager.desiredAccuracy = kCLLocationAccuracyBest;
//#else
        self.sharedManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
//#endif
        self.sharedManager.headingFilter = 5;
        self.direction = -1;
        
        [self.sharedManager allowDeferredLocationUpdatesUntilTraveled:10 timeout:CLTimeIntervalMax];
        

//#if DEBUG
//        self.currentLocation = [[CLLocation alloc] initWithLatitude:1 longitude:1];
//#else
//        self.currentLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
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

//    [self startLocator];
}

-(void)startLocator
{
    [self resetLocator];
     UIApplication* app = [UIApplication sharedApplication];
    

    if ([SharedLocation isServiceEnabled]==YES) {
        self.rawData = [NSMutableArray new];
        self.status = YES;
        
        if([app applicationState]==UIApplicationStateActive){
            [self.sharedManager startUpdatingLocation];
            [self.sharedManager startUpdatingHeading];
        }
        else
        {
            [self.sharedManager startMonitoringSignificantLocationChanges];
        }
    }
}

-(void)resetLocator
{
    
    UIApplication* app = [UIApplication sharedApplication];
    self.status = NO;
    if(self.sharedManager)
    {
        [self.rawData removeAllObjects];
        
        
        if([app applicationState]==UIApplicationStateActive){
            [self.sharedManager stopUpdatingHeading];
            [self.sharedManager stopUpdatingLocation];
        }
        else
        {
            [self.sharedManager stopMonitoringSignificantLocationChanges];
        }
    }
}

-(void)calcAproximalLocation:(CLLocation *)validLocation{
    
    if ([self.rawData count]==0) {
        return;
    }
    //middle Accuracy
    NSNumber *horizontalAccuracy = [self.rawData valueForKeyPath:@"@avg.horizontalAccuracy"];
    //filter relevant data
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(horizontalAccuracy >= %@)", horizontalAccuracy];
    NSArray*filtered =[self.rawData filteredArrayUsingPredicate:predicate];
    //get middle point
    CLLocation *midPoint = [self getMiddleLocation:filtered];
    self.currentLocation = midPoint;
}


-(CLLocation*)getMiddleLocation:(NSArray*)list
{
    if ([list count]>=2) {
        CLLocation *max = [list valueForKeyPath:@"@max.coordinate.latitude"];
        CLLocation *min = [list valueForKeyPath:@"@min.coordinate.latitude"];
        CLLocation *midPoint = [max midpointWithLocation:min];
        NSMutableArray* updated = [NSMutableArray arrayWithArray:list];
        [updated addObject:midPoint];
        [updated removeObject:max];
        [updated removeObject:min];
        return  [self getMiddleLocation:updated];
    }
    else if([list count]==1)
    {
        return list[0];
    }
    return nil;
}


-(void)processDebugLocation:(CLLocation*)location
{
    
    CLLocation *tmpLocation = location;
    if (!self.dedugcurrentLocation) {
        self.dedugcurrentLocation = tmpLocation;
        return;
    }
    
    if (tmpLocation.speed<0) {
        //        [self.rawData addObject:tmpLocation];
        if (self.isStopLocation) {
            if (tmpLocation.horizontalAccuracy<self.dynamicAccuracy && tmpLocation.horizontalAccuracy<self.dedugcurrentLocation.horizontalAccuracy) {
                self.dedugcurrentLocation = tmpLocation;
            }
            
            return;
        }
        
        self.isStopLocation = YES;
//        self.dedugcurrentLocation = [self.dedugcurrentLocation maxAccuracy:tmpLocation];
        return;
    }
    else
    {
        if (self.isStopLocation) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateNotiffication object:nil];
            self.isStopLocation = NO;
        }
        
        //        [self calcAproximalLocation:tmpLocation];
        //        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateNotiffication object:nil];
        //        [self.rawData removeAllObjects];
        
        
        
        
        //check if new location is not fake:
        if (tmpLocation.horizontalAccuracy > self.dynamicAccuracy) {
            
            NSLog(@"CORRECTION!");
            //fake candidat
            //check potentional distance
            NSTimeInterval timeSince = fabs([self.dedugcurrentLocation.timestamp timeIntervalSinceNow]);
            double distance = self.dedugcurrentLocation.speed*timeSince;
            
            //check direction
            if (self.dedugcurrentLocation.course!=-1 && self.dedugcurrentLocation.speed>0) {
                
                
                
                
                
                
                
                CLLocation*testLocation = [self.dedugcurrentLocation destinationLocationWithInitialBearing: self.dedugcurrentLocation.course distance:distance];
                
                
                //                    CLLocation*testLocation2 = [self.currentLocation destinationLocationWithInitialBearing: tmpLocation.course distance:distance];
                
                
                
                double test_distance = [tmpLocation distanceFromLocation:self.dedugcurrentLocation];
                
                
                CLLocation *newLocation;
                
                if (test_distance/distance > 1) {
//                    newLocation = [[CLLocation alloc] initWithCoordinate:testLocation.coordinate altitude:tmpLocation.altitude horizontalAccuracy:self.dynamicAccuracy verticalAccuracy:self.dynamicAccuracy course:self.dedugcurrentLocation.course speed:self.dedugcurrentLocation.speed timestamp:tmpLocation.timestamp];
                    
                    CLLocation*midLocation = [tmpLocation midpointWithLocation:testLocation];
                    
                    newLocation = [[CLLocation alloc] initWithCoordinate:midLocation.coordinate altitude:midLocation.altitude horizontalAccuracy:self.dynamicAccuracy verticalAccuracy:self.dynamicAccuracy course:self.dedugcurrentLocation.course speed:self.dedugcurrentLocation.speed timestamp:tmpLocation.timestamp];
                    
                    NSLog(@"Corrected");
                }
                else
                {
                    
                    
                    newLocation = tmpLocation;
                }
                
                self.dedugcurrentLocation = newLocation;
                
            }
            else
            {
                
                //TODO:finish this
                self.dedugcurrentLocation = tmpLocation;
                
            }
        }else
        {
            self.dedugcurrentLocation = tmpLocation;
        }
//        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateNotiffication object:nil];
    }
    
    self.dynamicAccuracy= (self.dynamicAccuracy+tmpLocation.horizontalAccuracy)/2.0;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    for (CLLocation *location in locations) {
        NSLog(@"%@",location);
        self.currentLocation = location;
        [self processDebugLocation:location];
        
        
        if (location.speed<=0) {
            if (!self.rawUndefinedLocation) {
                self.rawUndefinedLocation = location;
                continue;
            }
            
            if (location.horizontalAccuracy<self.rawUndefinedLocation.horizontalAccuracy) {
                self.rawUndefinedLocation = location;
            }
            continue;
        }
        else
        {
            if (self.rawUndefinedLocation) {
                self.currentLocation = self.rawUndefinedLocation;
                [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateNotiffication object:nil userInfo:@{@"data":[self.rawUndefinedLocation copy]}];
                self.rawUndefinedLocation = nil;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdateNotiffication object:nil userInfo:@{@"data":location}];
        }
    }
    
    

    
//    return;
    ////debug
    
    
   
    
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


//-(void)startBackgroundLocator{
//    if (self.status == YES) {
//        [self resetLocator];
//        [self.sharedManager startMonitoringSignificantLocationChanges];
//    }
//}
//-(void)startForegraundLocator{
//    if (self.status) {
//        [self.sharedManager stopMonitoringSignificantLocationChanges];
//        [self resetLocator];
//        [self startLocator];
//    }
//}

@end
