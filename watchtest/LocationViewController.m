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

@interface LocationViewController ()
@property (strong, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet UIView *buttonStart;


//@property (nonatomic, retain) MKPolyline *routeLine; //your line
//@property (nonatomic, retain) MKPolylineView *routeLineView; //overlay view

@property (nonatomic, strong)  NSMutableArray *colorSegments;

@end

@implementation LocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:kLocationUpdateNotiffication object:nil];
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
            UIAlertAction *cancelAction = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"Reset", @"Reset")
                                           style:UIAlertActionStyleCancel
                                           handler:^(UIAlertAction *action)
                                           {
                                               NSManagedObjectContext *moc = [ApplicationDelegate managedObjectContext];
                                               NSError *error;
                                               Track*track = (Track*)[moc existingObjectWithID:self.trackID error:&error];
                                               for (Location *items in track.waypoints) {
                                                   [moc deleteObject:items];
                                               }
                                               [ApplicationDelegate saveChangesInContext:moc];
                                               [self startRecordingTrack];
                                               [self loadData];
                                           }];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Continue?", @"Continue?")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           [self startRecordingTrack];
                                       }];
            
            [alertController addAction:cancelAction];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];

        }
        else{
            [self startRecordingTrack];
        }
        
            [self.buttonStart setHidden:YES];
    }
}


-(void)startRecordingTrack{
    [SharedRecorder sharedInstance].trackID = self.trackID;
    [[SharedRecorder sharedInstance] startRecording];
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
    
    if ([SharedLocation sharedInstance].status) {
        float spanX = 0.00725;
        float spanY = 0.00725;
        MKCoordinateRegion region =  MKCoordinateRegionMakeWithDistance (
                                                                         userLocation.location.coordinate, 20000, 20000);
        region.span.latitudeDelta = spanX;
        region.span.longitudeDelta = spanY;
        [self.map setRegion:region animated:NO];
        [self.map setCenterCoordinate:userLocation.coordinate animated:YES];
    }
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
    else if (locations)
    {
        
        self.colorSegments = [NSMutableArray array];
        
        
        NSNumber *average = [locations valueForKeyPath:@"@avg.speed"];
        NSNumber *max = [locations valueForKeyPath:@"@max.speed"];
        NSNumber *min = [locations valueForKeyPath:@"@min.speed"];
        
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"" argumentArray:<#(NSArray *)#>
                                  ////                              @"(lastName LIKE[c] 'Worsley') AND (salary > %@)", minimumSalary];
        
        // find median
        double medianSpeed = average.doubleValue;
        double maxSpeed = max.doubleValue;
        double minSpeed = ABS(min.doubleValue);
        
        double step = (maxSpeed - minSpeed)/locations.count;
        
        CGFloat mid = 255.0f/2/255.0f;
        CGFloat r = 1.0f;
        CGFloat g = 1.0f;
        
        double spedTest = 0;

        
        for (int i = 1; i < locations.count; i++) {
            
            Location *firstLoc = [locations objectAtIndex:(i-1)];

            Location *secondLoc = [locations objectAtIndex:i];
            
            CLLocationCoordinate2D coords[2];
            coords[0].latitude = firstLoc.latitude.doubleValue;
            coords[0].longitude = firstLoc.longitude.doubleValue;
            
            coords[1].latitude = secondLoc.latitude.doubleValue;
            coords[1].longitude = secondLoc.longitude.doubleValue;
            
            NSNumber *speed = secondLoc.speed;// [smoothSpeeds objectAtIndex:(i-1)];
            UIColor *color = [UIColor greenColor];

            // between red and yellow
            if (speed.doubleValue <= medianSpeed) {

                double ratio = minSpeed*255.0f/medianSpeed;
                color = [UIColor colorWithRed:r green:ABS(speed.doubleValue)*ratio/255.0f blue:0 alpha:1.0f];
//                color = [UIColor colorWithRed:r green: (spedTest*ratio)/255.0f blue:0 alpha:1.0f];
                // between yellow and green
            } else {
                double ratio = medianSpeed*255.0f/maxSpeed;
                color = [UIColor colorWithRed:(255.0f - ABS(speed.doubleValue)*ratio)/255.0f green:1.0f blue:0 alpha:1.0f];
//                color = [UIColor colorWithRed:(255.0-spedTest*ratio)/255.0f green:1.0f blue:0 alpha:1.0f];
            }
            
            MulticolorPolylineSegment *segment = [MulticolorPolylineSegment polylineWithCoordinates:coords count:2];
            segment.color = color;
            
            [self.colorSegments addObject:segment];
            
        }
        
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
    }
    else{
        NSLog(@"Empty");
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
        aRenderer.lineWidth = 3;
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

@end
