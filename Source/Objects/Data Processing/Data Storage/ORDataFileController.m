//
//  ORDataFileController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 23 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ���Imported Files
#import "ORDataFileController.h"
#import "ORDataFileModel.h"
#import "ORSmartFolder.h"

enum {
    kData,
    kGzip,
    kStatus,
    kConfig
};

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
@interface ORDataFileController (private)
- (void)_stopSendingSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
@end
#endif

@implementation ORDataFileController

#pragma mark ���Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"DataFile"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: @"orca.ORDataFileMode.selectedtab"];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
    [[tabView tabViewItemAtIndex:kData] setView:[[model dataFolder]view]];
    [[tabView tabViewItemAtIndex:kGzip] setView:[[model gzipFolder]view]];
    [[tabView tabViewItemAtIndex:kStatus] setView:[[model statusFolder]view]];
    [[tabView tabViewItemAtIndex:kConfig] setView:[[model configFolder]view]];
	
    [model setTitles];
    [[model dataFolder] setWindow:[self window]];
    [[model gzipFolder] setWindow:[self window]];
    [[model statusFolder] setWindow:[self window]];
    [[model configFolder] setWindow:[self window]];
	
	[[model dataFolder] updateWindow];
    [[model gzipFolder] updateWindow];
	[[model statusFolder] updateWindow];
	[[model configFolder] updateWindow];
	
}

#pragma mark ���Accessors


#pragma  mark ���Actions
- (void) generateAuxDataFileAction:(id)sender
{
    [model setGenerateMD5:[[sender selectedItem] tag]&0x1 generateGzip:[[sender selectedItem] tag]&0x2];
}
- (IBAction) dataFileCheckIntervalAction:(id)sender
{
    [model setFileCheckTimeInterval:[sender intValue]];
}

- (IBAction) processLimitHighAction:(id)sender
{
	[model setProcessLimitHigh:[sender floatValue]];	
}

- (IBAction) useDatedFileNamesAction:(id)sender
{
	[model setUseDatedFileNames:[sender intValue]];	
}

- (IBAction) useDatedFileNamesV2Action:(id)sender
{
    [model setUseDatedFileNamesV2:[sender intValue]];
}

- (IBAction) useFileExtensionAction:(id)sender
{
    if([sender intValue]) [model setFileStaticSuffix:@".orca"];
    else [model setFileStaticSuffix:@""];
}

- (IBAction) useFolderStructureAction:(id)sender
{
	[model setUseFolderStructure:[sender intValue]];	
}

- (IBAction) filePrefixTextFieldAction:(id)sender
{
	[model setFilePrefix:[sender stringValue]];	
}

- (IBAction) maxFileSizeTextFieldAction:(id)sender
{
	[model setMaxFileSize:[sender floatValue]];	
}

- (IBAction) limitSizeAction:(id)sender
{
	[model setLimitSize:[sender intValue]];
	[self lockChanged:nil];	
}

- (IBAction) sizeLimitReachedAction:(NSMatrix*)sender
{
	[model setSizeLimitReachedAction:(int)[[sender selectedCell] tag]];
}

- (IBAction) lockButtonAction:(id)sender
{
    [gSecurity tryToSetLock:ORDataFileLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) saveConfigurationAction:(NSButton*)sender
{
	if([sender state] != [model saveConfiguration]){
	    [[self undoManager] setActionName: @"Set Save Configuration"];
	    [model setSaveConfiguration:[sender state]];
	}
}

- (IBAction) stopSendingAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Stop Sending Files?"];
    [alert setInformativeText:@"You can always send them later."];
    [alert addButtonWithTitle:@"Stop"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if(result == NSAlertFirstButtonReturn){
            [[model dataFolder] stopTheQueue];
            [[model gzipFolder] stopTheQueue];
            [[model statusFolder] stopTheQueue];
            [[model configFolder] stopTheQueue];
        }
    }];
#else
    NSBeginAlertSheet(@"Stop Sending Files?",
                      @"Stop",
                      @"Cancel",
                      nil,[self window],
                      self,
                      @selector(_stopSendingSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,
                      @"You can always send them later.");
#endif
}
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void)_stopSendingSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertFirstButtonReturn){
		[[model dataFolder] stopTheQueue];
        [[model gzipFolder] stopTheQueue];
		[[model statusFolder] stopTheQueue];
		[[model configFolder] stopTheQueue];
    }
}
#endif


#pragma mark ���Interface Management

- (void) generateMD5Changed:(NSNotification*)aNote
{
    if([model generateMD5]){
        if([model generateGzip]) [generateAuxDataFilePU selectItemWithTag:0x3];
        else [generateAuxDataFilePU selectItemWithTag:0x1];
    }
    else [generateAuxDataFilePU selectItemWithTag:0x0];
}

- (void) generateGzipChanged:(NSNotification*)aNote
{
    if([model generateGzip] && [model generateMD5]) [generateAuxDataFilePU selectItemWithTag:0x3];
    else{
        if([model generateMD5]) [generateAuxDataFilePU selectItemWithTag:0x1];
        else [generateAuxDataFilePU selectItemWithTag:0x0];
    }
}

- (void) processLimitHighChanged:(NSNotification*)aNote
{
	[processLimitHighField setFloatValue: [model processLimitHigh]];
}

- (void) useDatedFileNamesChanged:(NSNotification*)aNote
{
	[useDatedFileNamesCB setIntValue: [model useDatedFileNames]];
}

- (void) useDatedFileNamesV2Changed:(NSNotification*)aNote
{
    [useDatedFileNamesV2CB setIntValue: [model useDatedFileNamesV2]];
}

- (void) useFileExtensionChanged:(NSNotification*)aNote
{
    if([[model fileStaticSuffix] isEqualToString:@".orca"]) [useFileExtension setIntValue:YES];
    else [useFileExtension setIntValue:NO];
}

- (void) useFolderStructureChanged:(NSNotification*)aNote
{
	[useFolderStructureCB setIntValue: [model useFolderStructure]];
}

- (void) filePrefixChanged:(NSNotification*)aNote
{
	[filePrefixTextField setStringValue: [model filePrefix]];
}

- (void) maxFileSizeChanged:(NSNotification*)aNote
{
	[maxFileSizeTextField setFloatValue: [model maxFileSize]];
}

- (void) limitSizeChanged:(NSNotification*)aNote
{
	[limitSizeCB setIntValue: [model limitSize]];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(fileChanged:)
						 name : ORDataFileModelFileSegmentChanged
						object: model];

    [notifyCenter addObserver : self
					 selector : @selector(fileChanged:)
						 name : ORDataFileChangedNotification
						object: model];

    [notifyCenter addObserver : self
					 selector : @selector(fileStatusChanged:)
						 name : ORDataFileStatusChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(fileSizeChanged:)
						 name : ORDataFileSizeChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(saveConfigurationChanged:)
						 name : ORDataSaveConfigurationChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(dirChanged:)
						 name : ORFolderDirectoryNameChangedNotification
						object: [model dataFolder]];
    
    [notifyCenter addObserver : self
                     selector : @selector(dirChanged:)
                         name : ORFolderDirectoryNameChangedNotification
                       object : [model gzipFolder]];
 
	[notifyCenter addObserver : self
					 selector : @selector(dirChanged:)
						 name : ORFolderDirectoryNameChangedNotification
						object: [model statusFolder]];

	[notifyCenter addObserver : self
					 selector : @selector(dirChanged:)
						 name : ORFolderDirectoryNameChangedNotification
						object: [model configFolder]];
	
	[notifyCenter addObserver : self
					 selector : @selector(dirChanged:)
						 name : ORDataFileModelUseFolderStructureChanged
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(copyEnabledChanged:)
						 name : ORFolderCopyEnabledChangedNotification
						object: nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(deleteWhenCopiedChanged:)
						 name : ORFolderDeleteWhenCopiedChangedNotification
						object: nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(fileQueueStatusChanged:)
						 name : ORDataFileQueueRunningChangedNotification
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(drawerDidOpen:)
                         name : NSDrawerDidOpenNotification
						object: copyDrawer];
	
	[notifyCenter addObserver : self
                     selector : @selector(drawerDidClose:)
                         name : NSDrawerDidCloseNotification
						object: copyDrawer];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORDataFileLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(limitSizeChanged:)
                         name : ORDataFileModelLimitSizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(maxFileSizeChanged:)
                         name : ORDataFileModelMaxFileSizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(filePrefixChanged:)
                         name : ORDataFileModelFilePrefixChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useFolderStructureChanged:)
                         name : ORDataFileModelUseFolderStructureChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useDatedFileNamesChanged:)
                         name : ORDataFileModelUseDatedFileNamesChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useDatedFileNamesV2Changed:)
                         name : ORDataFileModelUseDatedFileNamesV2Changed
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useFileExtensionChanged:)
                         name : ORDataFileModelFileStaticSuffixChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(sizeLimitReachedActionChanged:)
                         name : ORDataFileModelSizeLimitReachedActionChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(processLimitHighChanged:)
                         name : ORDataFileModelProcessLimitHighChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(generateMD5Changed:)
                         name : ORDataFileModelGenerateMD5Changed
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(generateGzipChanged:)
                         name : ORDataFileModelGenerateGzipChanged
                       object : model];
 
    [notifyCenter addObserver : self
                     selector : @selector(dataFileCheckIntervalChanged:)
                         name : ORDataFileCheckIntervalChanged
                       object : model];
    

}

- (void) updateWindow
{
    [super updateWindow];
    [self dataFileCheckIntervalChanged:nil];
    [self copyEnabledChanged:nil];
    [self deleteWhenCopiedChanged:nil];
    [self fileQueueStatusChanged:nil];
    [self dirChanged:nil];
    [self fileChanged:nil];
    [self fileStatusChanged:nil];
    [self saveConfigurationChanged:nil];
    [self lockChanged:nil];
	[self limitSizeChanged:nil];
	[self maxFileSizeChanged:nil];
	[self filePrefixChanged:nil];
	[self useFolderStructureChanged:nil];
    [self useDatedFileNamesChanged:nil];
    [self useDatedFileNamesV2Changed:nil];
    [self useFileExtensionChanged:nil];
	[self sizeLimitReachedActionChanged:nil];
	[self processLimitHighChanged:nil];
	[self generateMD5Changed:nil];
}


#pragma mark ���Interface Management
- (void) drawerDidOpen:(NSNotification *)note
{
	[[model dataFolder]	updateButtons];
    [[model gzipFolder] updateButtons];
	[[model statusFolder] updateButtons];
	[[model configFolder] updateButtons];
	[openLocationDrawerButton setTitle:@"Close Drawer"];
}

- (void) drawerDidClose:(NSNotification *)note
{
	[openLocationDrawerButton setTitle:@" Set File Locations and Send Options..."];
	
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    int index = (int)[tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.ORDataFileMode.selectedtab"];
	
}


- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORDataFileLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked    = [gSecurity isLocked: ORDataFileLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
    [lockButton setState: locked];
    [saveConfigurationCB setEnabled: !locked];
	[maxFileSizeTextField setEnabled: !(locked || isRunning) && [model limitSize]];
	[limitSizeCB setEnabled: !(locked || isRunning)];
	[sizeLimitActionMatrix setEnabled: !(locked || isRunning) && [model limitSize]];
	[filePrefixTextField setEnabled:!(locked || isRunning)];
	[useFolderStructureCB setEnabled:!(locked || isRunning)];
}

- (void) sizeLimitReachedActionChanged:(NSNotification*)note
{
	[sizeLimitActionMatrix selectCellWithTag:[model sizeLimitReachedAction]];
}

- (void) dataFileCheckIntervalChanged:(NSNotification*)note
{
    [fileCheckIntervalField setFloatValue:[model fileCheckTimeInterval]];
}

- (void) fileChanged:(NSNotification*)note
{
	if([model fileName]!=nil)[fileTextField setStringValue: [model fileName]];
	[self fileStatusChanged:nil];
}

- (void) copyEnabledChanged:(NSNotification*)note
{
    if(note == nil || [note object] == [model dataFolder]){
		[copyDataField setStringValue:[[model dataFolder]copyEnabled]?@"YES":@"NO"];
    }
    if(note == nil || [note object] == [model gzipFolder]){
        [copyGzipField setStringValue:[[model gzipFolder]copyEnabled]?@"YES":@"NO"];
    }
    if(note == nil || [note object] == [model statusFolder]){
		[copyStatusField setStringValue:[[model statusFolder]copyEnabled]?@"YES":@"NO"];
    }
    if(note == nil || [note object] == [model configFolder]){
		[copyConfigField setStringValue:[[model configFolder]copyEnabled]?@"YES":@"NO"];
    }
}

- (void) deleteWhenCopiedChanged:(NSNotification*)note
{
    if(note == nil || [note object] == [model dataFolder]){
		[deleteDataField setStringValue:[[model dataFolder]deleteWhenCopied]?@"YES":@"NO"];
    }
    if(note == nil || [note object] == [model gzipFolder]){
        [deleteGzipField setStringValue:[[model gzipFolder]deleteWhenCopied]?@"YES":@"NO"];
    }
    if(note == nil || [note object] == [model statusFolder]){
		[deleteStatusField setStringValue:[[model statusFolder]deleteWhenCopied]?@"YES":@"NO"];
    }
    if(note == nil || [note object] == [model configFolder]){
		[deleteConfigField setStringValue:[[model configFolder]deleteWhenCopied]?@"YES":@"NO"];
    }
}

- (void) fileQueueStatusChanged:(NSNotification*)note
{
    if(note == nil || [note object] == [model dataFolder]){
		[queueDataField setStringValue:[[model dataFolder]queueStatusString]];
    }
    if(note == nil || [note object] == [model gzipFolder]){
        [queueGzipField setStringValue:[[model gzipFolder]queueStatusString]];
    }
    if(note == nil || [note object] == [model statusFolder]){
		[queueStatusField setStringValue:[[model statusFolder]queueStatusString]];
    }
    if(note == nil || [note object] == [model configFolder]){
		[queueConfigField setStringValue:[[model configFolder]queueStatusString]];
    }
    
    [stopSendingButton setEnabled: [[model dataFolder]queueIsRunning] ||
        [[model gzipFolder]queueIsRunning]   ||
		[[model statusFolder]queueIsRunning] ||
		[[model configFolder]queueIsRunning]];
}



- (void) dirChanged:(NSNotification*)note
{    
    ORSmartFolder* theDataFolder   = [model dataFolder];
    if(note==nil || [note object] == theDataFolder || [note object] == model){
		if([theDataFolder finalDirectoryName]!=nil)[dirTextField setStringValue: [theDataFolder finalDirectoryName]];
    }
    
    ORSmartFolder* theGzipFolder = [model gzipFolder];
    if(note==nil || [note object] == theGzipFolder || [note object] == model){
        if([theGzipFolder finalDirectoryName]!=nil)[gzipTextField setStringValue:[theGzipFolder finalDirectoryName]];
    }
	
	ORSmartFolder* theStatusFolder = [model statusFolder];
    if(note==nil || [note object] == theStatusFolder || [note object] == model){
		if([theStatusFolder finalDirectoryName]!=nil)[logTextField setStringValue: [theStatusFolder finalDirectoryName]];
    }
	
	ORSmartFolder* theConfigFolder = [model configFolder];
	if(note==nil || [note object] == theConfigFolder || [note object] == model){
		if(![model saveConfiguration])[configTextField setStringValue:@"No Config Snap Shot (option above)"];
		else if([theConfigFolder finalDirectoryName]!=nil)[configTextField setStringValue: [theConfigFolder finalDirectoryName]];
    }
}

- (void) fileStatusChanged:(NSNotification*)note
{
	if([model filePointer]){
		[statusTextField setStringValue: @"Running / File Is Open"];			
	}
	else {
		[statusTextField setStringValue: @"Not Running"];			
	}
}

- (void) fileSizeChanged:(NSNotification*)note
{
	uint64_t theSize = [model dataFileSize];
	if(theSize<1000UL)[sizeTextField setStringValue: [NSString stringWithFormat:@"%u Bytes",(uint32_t)[model dataFileSize]]];
	else if(theSize<100000UL)[sizeTextField setStringValue: [NSString stringWithFormat:@"%.2f KB",(uint32_t)[model dataFileSize]/1000.]];
	else if(theSize<1000000000UL)[sizeTextField setStringValue: [NSString stringWithFormat:@"%.2f MB",[model dataFileSize]/1000000.]];
	else [sizeTextField setStringValue: [NSString stringWithFormat:@"%.2f GB",[model dataFileSize]/1000000000.]];
}

- (void) saveConfigurationChanged:(NSNotification*)note
{
	[saveConfigurationCB setState:[model saveConfiguration]];
	[self dirChanged:note];
}



@end

