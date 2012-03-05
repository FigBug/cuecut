//
//  AppController.m
//  CueCut
//
//  Created by Roland Rabien on 03/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"

@implementation AppController

- (id)init
{
	if (self = [super init])
	{
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	if (!once)
	{
		once = YES;
	
		NSApplication* app = [NSApplication sharedApplication];
		[app sendAction:@selector(openDocument:) to:nil from:self];
	}
	return NO;
}

- (IBAction)onlineHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.socalabs.com"]];
}

@end
