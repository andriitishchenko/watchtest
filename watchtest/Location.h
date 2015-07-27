//
//  Location.h
//  watchtest
//
//  Created by Andrii Tishchenko on 27.07.15.
//  Copyright (c) 2015 Andrii Tishchenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Track;

@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * altitude;
@property (nonatomic, retain) NSNumber * direction;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * speed;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSNumber * horizontalAccuracy;
@property (nonatomic, retain) NSNumber * verticalAccuracy;
@property (nonatomic, retain) Track *track;

@end
