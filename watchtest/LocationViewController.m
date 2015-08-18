//
//  ViewController.m
//  watchtest
//
//  Created by Andrii Tishchenko on 23.07.15.
//  Copyright (c) 2015 Andrii Tishchenko. All rights reserved.
//

#import "LocationViewController.h"
#import <MapKit/MapKit.h>

#import "Track.h"
#import "Location.h"
#import "MulticolorPolylineSegment.h"
#import <AudioToolbox/AudioServices.h>


static void * const MyClassKVOContext = (void*)&MyClassKVOContext; // unique context

@interface LocationViewController ()<UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet UIButton *buttonStart;


//@property (nonatomic, retain) MKPolyline *routeLine; //your line
//@property (nonatomic, retain) MKPolylineView *routeLineView; //overlay view

@property (nonatomic, strong)  NSMutableArray *colorSegments;

@property (nonatomic,strong)  NSMutableArray *livePath;
@property (nonatomic,strong)  NSMutableArray *livePathCorected;

//@property (nonatomic) BOOL autoUpdatePosition;

@end

@implementation LocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.navigationController.navigationBar.delegate = self;
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Tracks" style:UIBarButtonItemStylePlain target:self action:@selector(home:)];
    self.navigationItem.leftBarButtonItem=newBackButton;
    
//    self.autoUpdatePosition = YES;
    [[SharedLocation sharedInstance] addObserver:self forKeyPath:@"currentLocation" options:NSKeyValueObservingOptionNew context:MyClassKVOContext];
    [[SharedLocation sharedInstance] addObserver:self forKeyPath:@"dedugcurrentLocation" options:NSKeyValueObservingOptionNew context:MyClassKVOContext];
    UIPanGestureRecognizer* panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDragMap:)];
    [panRec setDelegate:self];
    [self.map addGestureRecognizer:panRec];
    
    MKUserTrackingBarButtonItem *buttonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.map];
    self.navigationItem.rightBarButtonItem = buttonItem;
    
    // Do any additional setup after loading the view, typically from a nib.
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:kLocationUpdateNotiffication object:nil];
}

-(void)home:(UIBarButtonItem *)sender {
    if ([SharedRecorder sharedInstance].status == NO) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{

            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:NSLocalizedString(@"Action",@"Action")
                                                  message:NSLocalizedString( @"Stop recording?",@"Stop recording?")
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"No", @"No")
                                           style:UIAlertActionStyleCancel
                                           handler:^(UIAlertAction *action)
                                           {}];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Yes", @"Yes")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           [self.navigationController popViewControllerAnimated:YES];
                                       }];
            [alertController addAction:cancelAction];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)didDragMap:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
//        self.autoUpdatePosition = NO;
        
        [self.map setUserTrackingMode:MKUserTrackingModeNone animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)actionStartTracing:(id)sender {
    if (self.trackID) {
        
        if (self.colorSegments) {
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:NSLocalizedString(@"Action",@"Action")
                                                  message:NSLocalizedString( @"Continue or reset?",@"Continue or reset?")
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *resetlAction = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"Reset", @"Reset")
                                           style:UIAlertActionStyleDestructive
                                           handler:^(UIAlertAction *action)
                                           {
                                               NSManagedObjectContext *moc = [SharedRecorder managedObjectContext];
                                               NSError *error;
                                               Track*track = (Track*)[moc existingObjectWithID:self.trackID error:&error];
                                               for (Location *items in track.waypoints) {
                                                   [moc deleteObject:items];
                                               }
                                               [SharedRecorder saveChanges:moc];
                                               [self startRecordingTrack];
                                               [self loadData];
                                           }];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Continue", @"Continue")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           [self startRecordingTrack];
                                       }];
            
            
            UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action)
                                       {

                                       }];
            

            [alertController addAction:okAction];
            [alertController addAction:resetlAction];
            [alertController addAction:cancelAction];

            [self presentViewController:alertController animated:YES completion:nil];

        }
        else{
            [self startRecordingTrack];
        }
        
            [self.buttonStart setEnabled:NO];
    }
}


-(void)startRecordingTrack{
    [SharedRecorder sharedInstance].trackID = self.trackID;
    [[SharedRecorder sharedInstance] startRecording];
    [self.buttonStart setTitle:@"Running" forState:UIControlStateNormal];
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    [self.map setUserTrackingMode:MKUserTrackingModeFollow animated:YES];

    self.livePath = [NSMutableArray new];
    self.livePathCorected = [NSMutableArray new];
    
    
    
    
}

//-(void)zoomToFitMapAnnotations:(MKMapView*)mapView
//{
//    if([mapView.annotations count] == 0)
//        return;

//    CLLocationCoordinate2D topLeftCoord;
//    topLeftCoord.latitude = -90;
//    topLeftCoord.longitude = 180;
//    
//    CLLocationCoordinate2D bottomRightCoord;
//    bottomRightCoord.latitude = 90;
//    bottomRightCoord.longitude = -180;
//    
//    for(MapAnnotation* annotation in mapView.annotations)
//    {
//        topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
//        topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
//        
//        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
//        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
//    }
//    
//    MKCoordinateRegion region;
//    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
//    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
//    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.1; // Add a little extra space on the sides
//    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.1; // Add a little extra space on the sides
//    
//    region = [mapView regionThatFits:region];
//    [mapView setRegion:region animated:YES];
//}




- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    
//    if ([SharedLocation sharedInstance].status) {
//        [self setVisibleRegion:userLocation.location];
//    }
}

-(void)setVisibleRegion:(CLLocation*)location
{
    
//    if (self.autoUpdatePosition) {
        float spanX = 0.00725;
        float spanY = 0.00725;
        //    float spanX = 0.014;
        //    float spanY = 0.014;
        //
        MKCoordinateRegion region =  MKCoordinateRegionMakeWithDistance (location.coordinate, 20000, 20000);
        region.span.latitudeDelta = spanX;
        region.span.longitudeDelta = spanY;
        [self.map setRegion:region animated:NO];
        //    [self.map setCenterCoordinate:location.coordinate animated:YES];
        
//    }

}

//- (void)locationUpdated:(NSNotification*)notification {
//    [self locationDidUpdated];
//}
//
//-(void)locationDidUpdated
//{
//    CLLocation *location = [SharedLocation sharedInstance].currentLocation;
//    
//    NSLog(@"%@", [NSString stringWithFormat:@" %f, %f", location.coordinate.latitude, location.coordinate.longitude]);
////    self.userPositionMarker.position = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
////    self.userPositionMarker.map = self.mapView;
//}
//



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadData];
}




-(void)loadData
{
    [self.map setShowsUserLocation:YES];
//    [self.map removeOverlay:self.colorSegments];
    
    for (id<MKOverlay> overlayToRemove in self.map.overlays)
    {
        if ([overlayToRemove isKindOfClass:[MulticolorPolylineSegment class]])
        {
            [self.map removeOverlay:overlayToRemove];
        }
    }
    
    
    NSManagedObjectContext *moc = [ApplicationDelegate managedObjectContext];
    
    
    NSError *error;
    
    
    Track*track = [moc existingObjectWithID:self.trackID error:&error];
    
   
    
//    NSEntityDescription *entityDescription = [NSEntityDescription
//                                              entityForName:@"Location" inManagedObjectContext:moc];
//    
//    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//    [request setEntity:entityDescription];
//    
////    // Set example predicate and sort orderings...
////    NSPredicate *predicate = [NSPredicate predicateWithFormat:
////                              @"(lastName LIKE[c] 'Worsley') AND (salary > %@)", minimumSalary];
////    [request setPredicate:predicate];
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
//                                        initWithKey:@"time" ascending:YES];
//    [request setSortDescriptors:@[sortDescriptor]];
    

//    NSArray *locations = [moc executeFetchRequest:request error:&error];
    
    NSArray*locations = [track sotredWaypoints];
    if (!locations && error)
    {
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Error fatching data"
                                      message:[error localizedDescription]
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
       [alert addAction:ok];
    
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if ([locations count]!=0)
    {
        
        self.colorSegments = [NSMutableArray array];
        
        NSArray*slopes = [self slopesDetect:locations];
        for (int i = 1; i < locations.count; i++) {
        
            Location *firstLoc = [locations objectAtIndex:(i-1)];
            Location *secondLoc = [locations objectAtIndex:i];
            
            CLLocationCoordinate2D coords[2];
            coords[0].latitude = firstLoc.latitude.doubleValue;
            coords[0].longitude = firstLoc.longitude.doubleValue;
            
            coords[1].latitude = secondLoc.latitude.doubleValue;
            coords[1].longitude = secondLoc.longitude.doubleValue;
            
//            NSNumber *speed = secondLoc.speed;// [smoothSpeeds objectAtIndex:(i-1)];
            UIColor *color = [UIColor redColor];
            
            if ([slopes containsObject:@(i)]) {
                color = [UIColor greenColor];
            }
            MulticolorPolylineSegment *segment = [MulticolorPolylineSegment polylineWithCoordinates:coords count:2];
            segment.color = color;
            [self.colorSegments addObject:segment];
        }
        
//        
//        
//        
//        
//        NSNumber *average = [locations valueForKeyPath:@"@avg.speed"];
//        NSNumber *max = [locations valueForKeyPath:@"@max.speed"];
//        NSNumber *min = [locations valueForKeyPath:@"@min.speed"];
//        
////        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"" argumentArray:<#(NSArray *)#>
//                                  ////                              @"(lastName LIKE[c] 'Worsley') AND (salary > %@)", minimumSalary];
//        
//        // find median
//        double medianSpeed = average.doubleValue;
//        double maxSpeed = max.doubleValue;
//        double minSpeed = ABS(min.doubleValue);
//        
//        double step = (maxSpeed - minSpeed)/locations.count;
//        
//        CGFloat mid = 255.0f/2/255.0f;
//        CGFloat r = 1.0f;
//        CGFloat g = 1.0f;
//        
//        double spedTest = 0;
//
//        
//        for (int i = 1; i < locations.count; i++) {
//            
//            Location *firstLoc = [locations objectAtIndex:(i-1)];
//            
//            NSLog(@"hA=%4.2f, Di=%4.2f,  Alt=%4.2f, Sp=%4.2f",
//                  firstLoc.horizontalAccuracy.doubleValue,
//                  firstLoc.direction.doubleValue,
//                  firstLoc.altitude.doubleValue,
//                  firstLoc.speed.doubleValue);
//
//            Location *secondLoc = [locations objectAtIndex:i];
//            
//            CLLocationCoordinate2D coords[2];
//            coords[0].latitude = firstLoc.latitude.doubleValue;
//            coords[0].longitude = firstLoc.longitude.doubleValue;
//            
//            coords[1].latitude = secondLoc.latitude.doubleValue;
//            coords[1].longitude = secondLoc.longitude.doubleValue;
//            
//            NSNumber *speed = secondLoc.speed;// [smoothSpeeds objectAtIndex:(i-1)];
//            UIColor *color = [UIColor greenColor];
//
//            // between red and yellow
//            if (speed.doubleValue <= medianSpeed) {
//
//                double ratio = minSpeed*255.0f/medianSpeed;
//                color = [UIColor colorWithRed:r green:ABS(speed.doubleValue)*ratio/255.0f blue:0 alpha:1.0f];
////                color = [UIColor colorWithRed:r green: (spedTest*ratio)/255.0f blue:0 alpha:1.0f];
//                // between yellow and green
//            } else {
//                double ratio = medianSpeed*255.0f/maxSpeed;
//                color = [UIColor colorWithRed:(255.0f - ABS(speed.doubleValue)*ratio)/255.0f green:1.0f blue:0 alpha:1.0f];
////                color = [UIColor colorWithRed:(255.0-spedTest*ratio)/255.0f green:1.0f blue:0 alpha:1.0f];
//            }
//            
//            MulticolorPolylineSegment *segment = [MulticolorPolylineSegment polylineWithCoordinates:coords count:2];
//            segment.color = color;
//            
//            [self.colorSegments addObject:segment];
//            
//        }
        
        [self.map addOverlays:self.colorSegments];
        
        
        MKMapRect zoomRect = MKMapRectNull;
        for(Location* item in locations)
        {
            CLLocationCoordinate2D tmp = {item.latitude.doubleValue, item.longitude.doubleValue};
            MKMapPoint point = MKMapPointForCoordinate(tmp);
            MKMapRect pointRect = MKMapRectMake(point.x, point.y, 0.1,0.1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
        
        double dx = zoomRect.size.width * CGRectGetWidth(self.map.bounds)/CGRectGetWidth(self.view.bounds);
        double dy = zoomRect.size.height * CGRectGetHeight(self.map.bounds)/CGRectGetHeight(self.view.bounds);
        zoomRect =  MKMapRectInset(zoomRect,-dx/2,-dy/2);
        [self.map setVisibleMapRect:zoomRect animated:YES];
        self.map.showsUserLocation=NO;
        

    }
    else{
//        [self setVisibleRegion:[SharedLocation sharedInstance].currentLocation];
//        self.map.showsUserLocation=YES;
        [self.map setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    }
}


#pragma mark - MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
//    if ([overlay isKindOfClass:[MKPolyline class]]) {
//        MKPolyline *polyLine = (MKPolyline *)overlay;
//        MKPolylineRenderer *aRenderer = [[MKPolylineRenderer alloc] initWithPolyline:polyLine];
//        aRenderer.strokeColor = [UIColor greenColor];
//        aRenderer.lineWidth = 3;
//        return aRenderer;
//    }
    if ([overlay isKindOfClass:[MulticolorPolylineSegment class]]) {
        MulticolorPolylineSegment *polyLine = (MulticolorPolylineSegment *)overlay;
        MKPolylineRenderer *aRenderer = [[MKPolylineRenderer alloc] initWithPolyline:polyLine];
        aRenderer.strokeColor = polyLine.color;
        aRenderer.lineWidth = 1;
        return aRenderer;
    }
    else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *polyLine = (MKPolyline *)overlay;
        MKPolylineRenderer *aRenderer = [[MKPolylineRenderer alloc] initWithPolyline:polyLine];
        aRenderer.strokeColor = [UIColor blueColor];
        aRenderer.lineWidth = 1;
        return aRenderer;
    }

    return nil;
}

//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation
//{
//    BadgeAnnotation *badgeAnnotation = (BadgeAnnotation *)annotation;
//    
//    MKAnnotationView *annView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"checkpoint"];
//    if (!annView) {
//        annView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"checkpoint"];
//        annView.image = [UIImage imageNamed:@"mapPin"];
//        annView.canShowCallout = YES;
//    }
//    
//    UIImageView *badgeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 75, 50)];
//    badgeImageView.image = [UIImage imageNamed:badgeAnnotation.imageName];
//    badgeImageView.contentMode = UIViewContentModeScaleAspectFit;
//    annView.leftCalloutAccessoryView = badgeImageView;
//    
//    return annView;
//}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[SharedRecorder sharedInstance] stopRecording];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"currentLocation"]) {
        if([object valueForKeyPath:keyPath] != [NSNull null]) {
            CLLocation*location = (CLLocation*)[object valueForKeyPath:keyPath];
            [self drawLine:location];
        }
    }
    
    if([keyPath isEqualToString:@"dedugcurrentLocation"]) {
        if([object valueForKeyPath:keyPath] != [NSNull null]) {
            CLLocation*location = (CLLocation*)[object valueForKeyPath:keyPath];
            
            if (location) {
                [self drawLineCorected:location];
            }
            else
            {
                NSLog(@"NIL LOCATION!!!");
            }

        }
    }
}


- (void)dealloc
{
//    if ([self observationInfo]) {
        @try {
            [[SharedLocation sharedInstance] removeObserver:self forKeyPath:@"currentLocation" context:MyClassKVOContext];
            
            [[SharedLocation sharedInstance] removeObserver:self forKeyPath:@"dedugcurrentLocation" context:MyClassKVOContext];
        }
        @catch (NSException *exception) {
            NSLog(@"%@",[exception description] );
        }
//    }
}


-(void)drawLine:(CLLocation*)newLocation
{
    NSInteger cnt = [self.livePath count];
    if (cnt>0) {
        CLLocation* oldLocation = [self.livePath lastObject];
        CLLocationCoordinate2D coords[2];
        coords[0] = oldLocation.coordinate;
        coords[1] = newLocation.coordinate;
        
//        MKCoordinateRegion region =
//        MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 500, 500);
//        [self.mapView setRegion:region animated:YES];
        
        [self.map addOverlay:[MKPolyline polylineWithCoordinates:coords count:2]];
        
        [self.livePath removeObjectAtIndex:0];
    }
    if (self.livePath) {
        [self.livePath addObject:newLocation];
    }
}

-(void)drawLineCorected:(CLLocation*)newLocation
{
    NSInteger cnt = [self.livePathCorected count];
    if (cnt>0) {
        CLLocation* oldLocation = [self.livePathCorected lastObject];
        CLLocationCoordinate2D coords[2];
        coords[0] = oldLocation.coordinate;
        coords[1] = newLocation.coordinate;
        [self.map addOverlay:[MulticolorPolylineSegment polylineWithCoordinates:coords count:2]];
        [self.livePathCorected removeObjectAtIndex:0];
    }
    if (self.livePathCorected) {
        [self.livePathCorected addObject:newLocation];
    }
}

//
//- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
//    //handle the action here
//    return YES;
//    if ([SharedRecorder sharedInstance].status == NO) {
//        return YES;
//    }
//    else{
////    __block BOOL rez = NO;
////    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//        
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                           UIAlertController *alertController = [UIAlertController
//                                                                 alertControllerWithTitle:NSLocalizedString(@"Action",@"Action")
//                                                                 message:NSLocalizedString( @"Stop recording?",@"Stop recording?")
//                                                                 preferredStyle:UIAlertControllerStyleAlert];
//                           UIAlertAction *cancelAction = [UIAlertAction
//                                                          actionWithTitle:NSLocalizedString(@"No", @"No")
//                                                          style:UIAlertActionStyleCancel
//                                                          handler:^(UIAlertAction *action)
//                                                          {
////                                                              dispatch_semaphore_signal(semaphore);
//                                                          }];
//                           
//                           UIAlertAction *okAction = [UIAlertAction
//                                                      actionWithTitle:NSLocalizedString(@"Yes", @"Yes")
//                                                      style:UIAlertActionStyleDefault
//                                                      handler:^(UIAlertAction *action)
//                                                      {
//                                                          dispatch_async(dispatch_get_main_queue(), ^(){
//                                                              
//                                                              [self.navigationController popViewControllerAnimated:YES];
//                                                              
//                                                          });
////                                                          rez = YES;
////                                                          dispatch_semaphore_signal(semaphore);
//                                                      }];
//                           [alertController addAction:cancelAction];
//                           [alertController addAction:okAction];
//                           dispatch_async(dispatch_get_main_queue(), ^(){
//
//                               [self presentViewController:alertController animated:YES completion:nil];
//                               
//                            });
////            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//        });
//        
//
//    return NO;
//    }
//}

-(NSArray*)slopesDetect:(NSArray*)list{
    
    //5 meter slope
    // find min and max, then devide for pices of 5 meter slopes
    double slopeHeigth = 5.0;
    NSMutableArray*rez = [NSMutableArray new];
    
//    NSNumber *average = [list valueForKeyPath:@"@avg.speed"];
    NSNumber *max = [list valueForKeyPath:@"@max.altitude"];
    NSNumber *min = [list valueForKeyPath:@"@min.altitude"];
    
//    double medianSpeed = average.doubleValue;
    double maxAltitude = max.doubleValue;
    double minAltitude = min.doubleValue;
    NSInteger count = floor((maxAltitude - minAltitude)/slopeHeigth) +1;
    
    NSMutableArray*ranges =  [NSMutableArray new];
    double stepper = minAltitude;
    for (NSInteger i = 0; i<count; i++) {
        stepper = floor(stepper+i*slopeHeigth);
        NSRange r = NSMakeRange(stepper,slopeHeigth);
        [ranges addObject:[NSValue valueWithRange:r]];
    }
    
    NSInteger slopeCount = 0;
    NSInteger climbCount = 0;
    
    NSInteger lastIndex= 0;
    
    NSInteger direction = -1;//1 up, 0 = down;
    
    for (Location*item in list) {
        NSNumber*altitudse = item.altitude;
        
        for (NSInteger i = 0; i<count; i++) {
            NSRange r = [ranges[i] rangeValue];
            if ( NSLocationInRange(altitudse.doubleValue,r)) {
                if (lastIndex < i) { //move up
                    if (direction != 1) {
                        direction = 1;
                        climbCount+=1;
                        lastIndex = i;
                        
                    }
                }
                else if (lastIndex > i)//move down
                {
                
                    if (direction != 0) {
                        direction = 0;
                        slopeCount+=1;
                        lastIndex = i;
                    }
                    [rez addObject:@([list indexOfObject:item])];
                }
                else //contimue previous move
                {
                    if (direction == 0) {
                        [rez addObject:@([list indexOfObject:item])];
                    }
                }
                
                break;
            }
//            NSLog(@"Index= %ld",(long)lastIndex);
        }
    }
    
    NSLog(@"Count= %ld",(long)slopeCount);

    
    return rez;
    
    
    
    
    
    
//    if (list && [list count] > 0) {
//        double minalt = 0; //((Location*)[list firstObject]).altitude.doubleValue;
//        double maxalt = ceil(((Location*)[list firstObject]).altitude.doubleValue);
//        for (Location*item in list) {
//            if ( ceil(item.altitude.doubleValue) < maxalt) {
//                if (minalt == 0) {
//                    count++;
//                }
//                minalt = item.altitude.doubleValue;
//            }
//            else if (ceil(item.altitude.doubleValue) > maxalt)
//            {
////                maxalt = item.altitude.doubleValue;
//                minalt = 0;
//            }
//            maxalt = ceil( item.altitude.doubleValue);
//        }
//    }

}

@end
