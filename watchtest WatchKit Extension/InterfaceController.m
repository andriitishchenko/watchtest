//
//  InterfaceController.m
//  watchtest WatchKit Extension
//
//  Created by Andrii Tishchenko on 23.07.15.
//  Copyright (c) 2015 Andrii Tishchenko. All rights reserved.
//

#import "InterfaceController.h"


@interface InterfaceController()

@property (strong, nonatomic) IBOutlet WKInterfaceMap *map;

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *Labellat;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *Labellong;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *Labelalt;
@property (strong,nonatomic) NSDictionary*datasource;

@property (strong,nonatomic)  NSTimer *timer;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    NSLog(@"%@",context);
    

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [self update];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self
                                           selector:@selector(timerTick:) userInfo:nil repeats:YES];

    
    
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    
    [self.timer invalidate];
    
    [super didDeactivate];
}

-(void)updateUI
{
    self.Labelalt.text = @"1";
    self.Labellong.text = @"2";
    self.Labelalt.text = @"3";
    
    
    if (self.datasource) {
        self.Labellat.text = [(NSNumber*)self.datasource[@"lat"] stringValue];
        self.Labellong.text = [(NSNumber*)self.datasource[@"long"] stringValue];
        self.Labelalt.text = [(NSNumber*)self.datasource[@"alt"] stringValue];
        
        
        
        
        // get the serialized location object
//        NSDictionary *location = self.datasource[@"location"];
        
        // pull out the speed (it's an NSNumber)
//        NSNumber *speed = location[@"speed"];
        
        // and convert it to a string for our label
//        NSString *speedString = [NSString stringWithFormat:@"Speed: %g", speed.doubleValue];
        
        // update our label with the newest location's speed
//        [_speedLabel setText:speedString];
        
        // next, get the lat/lon
        NSNumber *latitude = (NSNumber*)self.datasource[@"lat"];
        NSNumber *longitude = (NSNumber*)self.datasource[@"long"];
        
        // and update our map
        MKCoordinateSpan span = MKCoordinateSpanMake(0.5, 0.5);
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
        
        // drop a pin where the user is currently
        [self.map addAnnotation:coordinate withPinColor:WKInterfaceMapPinColorRed];
        
        // and give it a region to display
        MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
        [self.map setRegion:region];
        
        
        
        
    }
    
//    self.map set
}

-(void)update{
    [WKInterfaceController openParentApplication:@{@"test":@"reg1"} reply:^(NSDictionary *replyInfo, NSError *error) {
        if (replyInfo && !error) {
            self.datasource = replyInfo;
            [self updateUI];
        }
        else {
            NSLog(@"not connected");
        
        }
    }];
}

- (void) timerTick:(NSTimer *)incomingTimer
{
    [self update];
}

@end



