//
//  AppDelegate.m
//  watchtest
//
//  Created by Andrii Tishchenko on 23.07.15.
//  Copyright (c) 2015 Andrii Tishchenko. All rights reserved.
//

#import "AppDelegate.h"
#import "SharedLocation.h"
#import "Location.h"
#import "UINavigationController+backhack.h"
@interface AppDelegate ()
// = UIBackgroundTaskInvalid
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    UIAlertView * alert;
    if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"The app doesn't work without the Background App Refresh enabled. To turn it on, go to Settings > General > Background App Refresh"
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"The functions of this app are limited because the Background App Refresh is disable."
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    } else{
        
            
            //if app was closed while recording and resumed by system
            if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey]) {
                NSLog(@"UIApplicationLaunchOptionsLocationKey");
                [[SharedRecorder sharedInstance] startRecording];
            }
            else //new run
            {
                if ([SharedLocation sharedInstance].status == NO ) {
                    [[SharedLocation sharedInstance] startLocator];
                    double delayInSeconds = 3.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [[SharedLocation sharedInstance] resetLocator];
                    });
                }
            }
            

    }
    
    

    return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [self saveContext];
    [[SharedRecorder sharedInstance] resumeRecording];
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//    [self extendBackgroundRunningTime];
//    _inBackground = YES;
}

//- (void)extendBackgroundRunningTime {
//    if (_backgroundTask != UIBackgroundTaskInvalid) {
//        return;
//    }
//    NSLog(@"Attempting to extend background running time");
//    
////    __block Boolean self_terminate = YES;
//    
//    _backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"DummyTask" expirationHandler:^{
//        NSLog(@"Background task expired by iOS");
//        [ApplicationDelegate saveContext];
////        if (self_terminate) {
////            [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
////            _backgroundTask = UIBackgroundTaskInvalid;
////        }
//    }];
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        NSLog(@"Background task started");        
////        while (true) {
////            NSLog(@"background time remaining: %8.2f", [UIApplication sharedApplication].backgroundTimeRemaining);
////            [NSThread sleepForTimeInterval:1];
////        }
//        
//    });
//}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    SharedLocation *sm = [SharedLocation sharedInstance];
//    [sm startLocator];
    
    [[SharedRecorder sharedInstance] resumeRecording];
//    _inBackground = NO;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.watchtest" in the application's documents directory.
    NSLog(@"%@",[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask] lastObject]);

    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"watchtest" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"watchtest.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void ( ^)( NSDictionary * ))reply
{
    __block UIBackgroundTaskIdentifier watchKitHandler;
    watchKitHandler = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"backgroundTask"
                                                                   expirationHandler:^{
                                                                       watchKitHandler = UIBackgroundTaskInvalid;
                                                                   }];
    SharedLocation *sm = [SharedLocation sharedInstance];
    
    
    if (!sm) {
       [sm startLocator];
    }
    
    CLLocation*l = [SharedLocation sharedInstance].currentLocation;
    
    reply(@{@"lat": @(l.coordinate.latitude),
            @"long": @(l.coordinate.longitude),
            @"alt": @(l.altitude),
            }
          );
    
        NSLog(@"HWHEHEHE");
//    if ( [[userInfo objectForKey:@"request"] isEqualToString:@"getData"] )
//    {
//        
//    
//    }
    
    dispatch_after( dispatch_time( DISPATCH_TIME_NOW, (int64_t)NSEC_PER_SEC * 1 ), dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        [[UIApplication sharedApplication] endBackgroundTask:watchKitHandler];
    } );
}


//- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void ( ^)( NSDictionary * ))reply
//{
//    __block UIBackgroundTaskIdentifier watchKitHandler;
//    
//    watchKitHandler = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"backgroundTask" expirationHandler:^{
//                                                                       watchKitHandler = UIBackgroundTaskInvalid;
//                                                                   }];
//    
//    NSMutableDictionary *response = [NSMutableDictionary dictionary];
//    
//    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
//    
//    [ClassObject getDataWithBlock:^(BOOL succeeded, NSError *error){
//        
//        if (succeeded)
//        {
//            [response setObject:@"update succeded" forKey:@"updateKey"];
//        }
//        else
//        {
//            if (error)
//            {
//                [response setObject:[NSString stringWithFormat:@"update failed: %@", error.description] forKey:@"updateKey"];
//            }
//            else
//            {
//                [response setObject:@"update failed with no error" forKey:@"updateKey"];
//            }
//        }
//        
//        reply(response);
//        dispatch_semaphore_signal(sema);
//    }];
//    
//    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
//    
//    dispatch_after(dispatch_time( DISPATCH_TIME_NOW, (int64_t)NSEC_PER_SEC * 1), dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [[UIApplication sharedApplication] endBackgroundTask:watchKitHandler];
//    });
//}

@end
