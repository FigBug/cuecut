//
//  MyDocument.m
//  CueCut
//
//  Created by Roland Rabien on 03/12/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import "CueSheet.h"

@implementation CueSheet

- (id)init
{
    self = [super init];
    if (self) 
	{   
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskFinished:) name:@"NSTaskDidTerminateNotification" object:nil];
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)windowNibName
{
    return @"CueSheet";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	
	[mp3FilePath setEditable: NO];
	[outputFilePath setEditable: NO];
	
	NSURL* url = [self fileURL];
	
	NSString* rootPath = [[url path] stringByDeletingLastPathComponent];

	NSArray* lines = [self getLinesInString:cue];
	
	numTracks = 0;
	for (int i = 0; i < [lines count]; i++)
	{
		NSString* line = [lines objectAtIndex: i];
		if ([self hasCommand:@"FILE" inString:line])
		{
			NSString* mp3file = [self getQuotedString: [lines objectAtIndex: i]];
			NSString* mp3path = [[NSString pathWithComponents: [NSArray arrayWithObjects: @"/", rootPath,  mp3file, nil]] stringByStandardizingPath];
			
			[mp3FilePath setStringValue: mp3path];
		}
		else if ([self hasCommand:@"TRACK" inString:line])
		{
			numTracks++;
		}
	}
	
	[outputFilePath setStringValue: rootPath];	
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	if (outError != NULL)
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:readErr userInfo:NULL];

	if ([data length] == 0) 
		return NO;
	
	NSURL* url = [self fileURL];
	if (![url isFileURL])
		return NO;
	
	cue = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
    return YES;
}

- (BOOL)hasCommand:(NSString*)key inString: (NSString*)str
{
	NSString* clean = [str stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
	return [clean hasPrefix: key];
}

- (NSString*)getQuotedString:(NSString*)str
{
	NSRange range = { -1, -1 };
	
	int len = [str length];
	
	for (int i = 0; i < len; i++)
	{
		if ([str characterAtIndex: i] == '\"')
		{
			if (range.location == -1)
			{
				range.location = i + 1;
			}
			else
			{
				range.length = i - (range.location - 1) - 1;
				break;
			}
		}
	}
	if (range.location != -1 && range.length > 0)
		return [str substringWithRange: range];	
	else
		return nil;
}

- (IBAction)chooseMp3:(id)sender
{
	NSOpenPanel* open = [NSOpenPanel openPanel];
	[open setCanChooseFiles: YES];
	[open setCanChooseDirectories: NO];
	[open setResolvesAliases: YES];
	[open setAllowsMultipleSelection: NO];
    [open setAllowedFileTypes:[NSArray arrayWithObject: @"mp3"]];
	
	if ([open runModal] == NSFileHandlingPanelOKButton)
    {
        NSURL* url = [[open URLs] objectAtIndex: 0];
		[mp3FilePath setStringValue: [url path]];
	}
}

- (IBAction)chooseOutput:(id)sender
{
	NSOpenPanel* open = [NSOpenPanel openPanel];
	[open setCanChooseFiles: NO];
	[open setCanChooseDirectories: YES];
	[open setResolvesAliases: YES];
	[open setAllowsMultipleSelection: NO];
    [open setDirectoryURL:[NSURL fileURLWithPath:[outputFilePath stringValue]]];
	
    if ([open runModal] == NSFileHandlingPanelOKButton)
	{
        NSURL* url = [[open URLs] objectAtIndex: 0];
		[outputFilePath setStringValue: [url path]];
	}
}

- (IBAction)cutNow:(id)sender
{
	NSBundle* bundle = [NSBundle mainBundle];
	NSString* exec   = [bundle executablePath];
	
	NSString* inp = [[self fileURL] path];	
	NSString* jar = [[exec stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"pcutmp3.jar"];
	NSString* dir = [outputFilePath stringValue];
	NSString* mp3 = [mp3FilePath stringValue];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL isDir;
	if (![fm fileExistsAtPath: mp3 isDirectory: &isDir] || isDir)
	{
		[[NSAlert alertWithMessageText:nil defaultButton: @"OK" alternateButton:nil otherButton:nil informativeTextWithFormat: @"The source MP3 file can not be found."] runModal];
		return;
	}
	if (![fm fileExistsAtPath: dir isDirectory: &isDir] || !isDir)
	{
		[[NSAlert alertWithMessageText:nil defaultButton: @"OK" alternateButton:nil otherButton:nil informativeTextWithFormat: @"The destination folder can not be found."] runModal];
		return;
	}
	
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath: @"/usr/bin/java"];
	
	NSArray* args = [NSArray arrayWithObjects: @"-jar", jar, @"--cue", inp, @"--dir", dir, mp3, nil];
	[task setArguments: args];
	
	taskOutputFile = [self createTmpFile];
	NSFileHandle* taskOutput = [NSFileHandle fileHandleForWritingAtPath:taskOutputFile];
	
	[task setStandardOutput: taskOutput];
	
	[task launch];
	if ([task isRunning])
	{
		[mp3FilePath setEnabled: NO];
		[outputFilePath setEnabled: NO];		
		[chooseMp3 setEnabled: NO];
		[chooseOutput setEnabled: NO];
		[cut setEnabled: NO];
		
		[progressBar setMinValue: 0.0];
		[progressBar setMaxValue: (double)numTracks];
		[progressBar setDoubleValue: 0.0];
		
		[NSApp beginSheet: progressWindow modalForWindow: [self windowForSheet] modalDelegate: self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		timer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(taskTimer:) userInfo:nil repeats:YES];
	}
}

- (void)taskTimer:(NSTimer*)theTimer
{
	NSFileHandle* file = [NSFileHandle fileHandleForReadingAtPath:taskOutputFile];
	NSData* data = [file readDataToEndOfFile];
	NSString* str = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
	
	NSArray* lines = [self getLinesInString:str];
	
	int numTracksFinished = 0;
	NSString* lastLine = nil;
	for (int i = 0; i < [lines count]; i++)
	{
		NSString* line = [lines objectAtIndex: i];
		if ([self hasCommand:@"writing" inString:line])
			numTracksFinished++;
		if ([self hasCommand:@"writing" inString:line] || [self hasCommand:@"scanning" inString:line])
			lastLine = line;
	}
	[progressBar setDoubleValue: (double)numTracksFinished];
	
	if (lastLine)
	{
		NSString* fileName = [[self getQuotedString:lastLine] lastPathComponent];
		if ([self hasCommand:@"scanning" inString:lastLine])
			[logLabel setStringValue: [NSString stringWithFormat: @"Scanning: %@", fileName]];
		else
			[logLabel setStringValue: [NSString stringWithFormat: @"Creating: %@", fileName]];
	}
}

- (void)taskFinished:(NSNotification *)notification
{
	[self taskTimer:nil];
	[timer invalidate];
	
	[[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:taskOutputFile] error:nil];
	
	[mp3FilePath setEnabled: YES];
	[outputFilePath setEnabled: YES];		
	[chooseMp3 setEnabled: YES];
	[chooseOutput setEnabled: YES];
	[cut setEnabled: YES];	

	[progressWindow orderOut: self];
	[NSApp endSheet:progressWindow returnCode: 1];
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)code contextInfo:(void*) context
{
}

- (NSString*)createTmpFile
{
	NSString* str = [NSString stringWithFormat: @"%@XXXXXXXX", NSTemporaryDirectory()];
	
	char tempFile[1024];
	strcpy(tempFile, [str UTF8String]);
	
	mktemp(tempFile);
	
	NSString* path = [NSString stringWithCString: tempFile encoding:NSUTF8StringEncoding];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	[fm createFileAtPath:path contents:[NSData data] attributes:nil];
	
	return path;
}

- (NSArray*)getLinesInString:(NSString*)string
{
	NSUInteger length = [string length];
	NSUInteger paraStart = 0, paraEnd = 0, contentsEnd = 0;
	
	NSMutableArray *array = [NSMutableArray array];
	NSRange currentRange;
	
	while (paraEnd < length)
	{
		[string getParagraphStart:&paraStart end:&paraEnd contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
		currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
		[array addObject:[string substringWithRange:currentRange]];
	}
	return array;
}

@end
