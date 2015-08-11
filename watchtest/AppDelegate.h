//
//  AppDelegate.h
//  watchtest
//
//  Created by Andrii Tishchenko on 23.07.15.
//  Copyright (c) 2015 Andrii Tishchenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (assign, nonatomic) UIBackgroundTaskIdentifier* backgroundTask;
@property (nonatomic) BOOL inBackground;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

-(void)saveLocation;
//- (void)saveChangesInContext:(NSManagedObjectContext *)managedObjectContext;

@end

