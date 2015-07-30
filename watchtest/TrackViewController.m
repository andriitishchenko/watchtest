//
//  TrackViewController.m
//  watchtest
//
//  Created by Andrii Tishchenko on 24.07.15.
//  Copyright (c) 2015 Andrii Tishchenko. All rights reserved.
//

#import "TrackViewController.h"
#import "Track.h"
#import "LocationViewController.h"
@interface TrackViewController ()
        @property(strong,nonatomic) NSManagedObjectID*trackID;
        @property(strong,nonatomic) CLGeocoder* geocoder;
@end


@interface TrackViewController () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation TrackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Tracks", @"Tracks");
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"New", @"New")
                                                                              style:UIBarButtonItemStylePlain target:self action:@selector(actionNewRecord:)];
    
    NSManagedObjectContext *moc = [ApplicationDelegate managedObjectContext];
    
    // Initialize Fetch Request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Track"];
    
    // Add Sort Descriptors
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
    
    // Initialize Fetched Results Controller
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
    
    // Configure Fetched Results Controller
    [self.fetchedResultsController setDelegate:self];
    
    // Perform Fetch
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    
    if (error) {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, error.localizedDescription);
    }
    
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self configureCell:(UITableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

-(IBAction)actionNewRecord:(id)sender{
    
    NSManagedObjectContext *moc = [ApplicationDelegate managedObjectContext];
    Track*item = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:moc];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSDate *date = [NSDate date];
    [dateFormat setTimeZone:[NSTimeZone localTimeZone]];

    item.time = @([date timeIntervalSince1970]);
    item.title = [dateFormat stringFromDate:[NSDate date]];
    [ApplicationDelegate saveChangesInContext:moc];
    __block NSManagedObjectID*trackid = item.objectID;
    
    
    if (!self.geocoder)
        self.geocoder = [[CLGeocoder alloc] init];
    
    [self.geocoder reverseGeocodeLocation:[SharedLocation sharedInstance].currentLocation completionHandler:
     ^(NSArray* placemarks, NSError* error){
         if ([placemarks count] > 0)
         {
             NSManagedObjectContext *moc = [ApplicationDelegate managedObjectContext];
            Track*track = (Track*)[moc existingObjectWithID:trackid error:nil];
//             NSLog(@"%@",placemarks);
             if (track) {
                 CLPlacemark*lc = [placemarks objectAtIndex:0];
                 NSDictionary*adress = lc.addressDictionary;
                 NSString  *addresstring = [[adress objectForKey:@"FormattedAddressLines"] componentsJoinedByString:@","];
                 item.title = addresstring;
                 [moc save:nil];
             }
         }
         
     }];
    

    
    
    
//    [ApplicationDelegate saveChangesInContext:moc];
    self.trackID = item.objectID;
    [self performSegueWithIdentifier:@"showlocationcontroller" sender:sender];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [self.fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"trackCell" forIndexPath:indexPath];
    
    // Configure Table View Cell
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // Fetch Record
     Track*record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Update Cell
    [cell.textLabel setText:record.title];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Track*record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.trackID = record.objectID;
    [self performSegueWithIdentifier:@"showlocationcontroller" sender:self];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Track*record = [self.fetchedResultsController objectAtIndexPath:indexPath];
        if (record) {
            [self.fetchedResultsController.managedObjectContext deleteObject:record];
        }
    }
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showlocationcontroller"]) {
        LocationViewController *vc = (LocationViewController *)[segue destinationViewController];
        vc.trackID = self.trackID;
        
        
    }
//    else if ([segue.identifier isEqualToString:@"updateToDoViewController"]) {
//        // Obtain Reference to View Controller
//        TSPUpdateToDoViewController *vc = (TSPUpdateToDoViewController *)[segue destinationViewController];
//        
//        // Configure View Controller
//        [vc setManagedObjectContext:self.managedObjectContext];
//        
//        if (self.selection) {
//            // Fetch Record
//            NSManagedObject *record = [self.fetchedResultsController objectAtIndexPath:self.selection];
//            
//            if (record) {
//                [vc setRecord:record];
//            }
//            
//            // Reset Selection
//            [self setSelection:nil];
//        }
//    }
}

@end
