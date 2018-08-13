//
//  AppDelegate.h
//  TableView
//
//  Created by Adam Betterton on 1/10/16.
//  Copyright © 2016 Adam Betterton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <CocoaAsyncSocket/CocoaAsyncSocket.h>
@class GCDAsyncSocket;



@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet NSTableView *theTable;


//MainWindow

@property (weak) IBOutlet NSWindow *MainWindow;

@property (weak) IBOutlet NSButton *StartStopButton;

@property (weak) IBOutlet NSTextField *currScript;
@property (weak) IBOutlet NSTextField *currFile;
@property (weak) IBOutlet NSTextField *currStatus;

@property (weak) IBOutlet NSProgressIndicator *currSpinner;

//ManageWindow


@property (weak) IBOutlet NSWindow *ManageWindow;
@property (weak) IBOutlet NSButton *AddEntryButton;
@property (weak) IBOutlet NSButton *EditButton;
@property (weak) IBOutlet NSButton *RemoveEntryButton;

@property (weak) IBOutlet NSButtonCell *DoneButton;

//Add/Change Entry Window
@property (weak) IBOutlet NSWindow *AddChangeEntryWindow;

@property (weak) IBOutlet NSButton *loadScriptButton;
@property (weak) IBOutlet NSTextField *loadScriptLabel;

@property (weak) IBOutlet NSButton *loadInFolderButton;
@property (weak) IBOutlet NSTextField *loadInFolderLabel;

@property (weak) IBOutlet NSButton *loadOutFolderButton;
@property (weak) IBOutlet NSTextField *loadOutFolderLabel;

@property (weak) IBOutlet NSButton *ShellRadio;
@property (weak) IBOutlet NSButton *AppleScriptRadio;
@property (weak) IBOutlet NSButton *InDesignRadio;
@property (weak) IBOutlet NSButton *PhotoshopRadio;

@property (weak) IBOutlet NSButton *EnabledCheckBox;

@property (weak) IBOutlet NSButton *saveEntryButton;
@property (weak) IBOutlet NSButton *saveEntryCancelButton;

//Preferences Window
@property (weak) IBOutlet NSWindow *PreferencesWindow;
@property (weak) IBOutlet NSButton *PreferencesCloseButton;
@property (weak) IBOutlet NSButton *PreferencesAutostartCheckBox;

@property (weak) IBOutlet NSButton *PreferencesEmailErrorCheckBox;
@property (weak) IBOutlet NSTextField *PreferencesEmailAddressTextBox;
@property (weak) IBOutlet NSButton *PrefrencesAutoReportCheckBox;

@property (weak) IBOutlet NSButton *PreferencesServerEnabledCheckBox;
@property (weak) IBOutlet NSTextField *PreferencesPortField;
//File Menu
@property (weak) IBOutlet NSMenuItem *ExportConfigMenuItem;
@property (weak) IBOutlet NSMenuItem *ImportConfigMenuItem;
@property (weak) IBOutlet NSMenuItem *GenerateReportMenuItem;
@property (weak) IBOutlet NSMenuItem *PurgeLogMenuItem;

//Help Menu
@property (weak) IBOutlet NSMenuItem *HelpMenuHelpItem;

//Help Window
@property (weak) IBOutlet NSWindow *HelpWindow;
@property (weak) IBOutlet WebView *HelpWebView;

//alert Window
@property (weak) IBOutlet NSWindow *alertWindow;
@property (weak) IBOutlet NSTextField *alertMessage;
@property (weak) IBOutlet NSButton *alertOkButton;
@property (weak) IBOutlet NSImageCell *alertIcon;


//
- (void) populateTable;
- (void) startTimers;
- (void) stopTimers;
- (void) updateInterface:(NSString*)theScript : (NSString*)fileNamewithPath;
- (void) updateInterfaceFinish;
- (void) updateInterfaceInit;
- (void) initAddEntryPanel;
- (void) saveXML;
- (void) initSystem;
- (void) initPrefs;
- (void) updateLog:(NSString*)theScript : (NSString*) fileNamewithPath : (NSString*) inFolder : (NSString*) outFolder;
- (void) generateReport;
- (void) purgeLog;
- (void) HelpViewLoad;
- (NSString*) validateCheck: (NSString*)theScript : (NSString*) inFolder : (NSString*) outFolder : (NSString*) ScriptType;

@end

