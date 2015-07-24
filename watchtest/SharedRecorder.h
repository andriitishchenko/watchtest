//
//  SharedRecorder.h
//  watchtest
//
//  Created by Andrii Tishchenko on 24.07.15.
//  Copyright (c) 2015 Andrii Tishchenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SharedRecorder : NSObject
    @property(strong,nonatomic) NSManagedObjectID*trackID;

+(SharedRecorder *)sharedInstance ;
-(void)startRecording;
-(void)stopRecording;
@end
