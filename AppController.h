//
//  AppController.h
//  CueCut
//
//  Created by Roland Rabien on 03/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
	BOOL once;
}

- (id)init;
- (void)dealloc;

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;

- (IBAction)onlineHelp:(id)sender;

@end
