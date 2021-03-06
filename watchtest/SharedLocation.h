//
//  SharedLocation.h
//  ???
//
//  Created by AndruX on 5/5/13.
//  Copyright (c) 2015 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


#ifndef watchtest_SharedLocation
#define watchtest_SharedLocation
    #define kLocationUpdateNotiffication @"kLocationUpdateNotiffication"
#endif

@interface SharedLocation : NSObject <CLLocationManagerDelegate>


    @property (strong,nonatomic) CLLocation *currentLocation;

    @property (strong,nonatomic) CLLocationManager *sharedManager;
    @property (strong,nonatomic) CLHeading *lastHeading;
    @property (strong,nonatomic) NSError* error;
    @property (nonatomic) CLLocationDirection direction;
    @property(nonatomic) BOOL status;



    @property (strong,nonatomic) CLLocation *dedugcurrentLocation;

+(SharedLocation *)sharedInstance ;
+(BOOL)isServiceEnabled;
+(NSString*)getHeaderLocation;
-(void)setMapLocation:(CLLocation *)location;
-(void)startLocator;
-(void)resetLocator;

//-(void)startBackgroundLocator;
//-(void)startForegraundLocator;

@end
