//
//  MyDocument.h
//  CueCut
//
//  Created by Roland Rabien on 03/12/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface CueSheet : NSDocument
{
	IBOutlet NSTextField* mp3FilePath;
	IBOutlet NSTextField* outputFilePath;
	IBOutlet NSButton* chooseMp3;
	IBOutlet NSButton* chooseOutput;
	IBOutlet NSButton* cut;
	IBOutlet NSWindow* progressWindow;
	IBOutlet NSProgressIndicator* progressBar;
	IBOutlet NSTextField* logLabel;
	
	NSString* cue;
	NSTimer* timer;
	NSString* taskOutputFile;
	
	int numTracks;
}

- (IBAction)chooseMp3:(id)sender;
- (IBAction)chooseOutput:(id)sender;
- (IBAction)cutNow:(id)sender;

- (BOOL)hasCommand:(NSString*)key inString: (NSString*)str;
- (NSString*)getQuotedString:(NSString*)str;

- (void)taskFinished:(NSNotification *)notification;

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)code contextInfo:(void*) context;

- (void)taskTimer:(NSTimer*)theTimer;

- (NSString*)createTmpFile;

- (NSArray*)getLinesInString:(NSString*)file;

@end
