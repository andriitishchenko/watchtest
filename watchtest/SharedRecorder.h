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
    @property(nonatomic) BOOL status;


+(SharedRecorder *)sharedInstance ;
-(void)startRecording;
-(void)stopRecording;
-(void)resumeRecording;
@end
