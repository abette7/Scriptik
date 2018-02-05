//
//  AppDelegate.m
//  TableView
//
//  Created by Adam Betterton on 1/10/16.
//  Copyright © 2016 Adam Betterton. All rights reserved.
//

#import "AppDelegate.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>

#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2
#define SCRIPT_MSG   3
#define FILE_MSG     4

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]
dispatch_queue_t socketQueue;
dispatch_queue_t timerQueue;
GCDAsyncSocket *listenSocket;
NSMutableArray *connectedSockets;


//Globals
int isRunning = 0;

NSString *getMSG = @"";
NSString *addEntryScript = @"";
NSString *addEntryInFolder = @"";
NSString *addEntryOutFolder = @"";
NSString *addEntryScriptType = @"";
NSString *addEntryIsEnabled = @"";
bool EditFlag = false;
NSString *serverEnabled = @"false";
NSString *Autostart = @"false";
NSString *validateError = @"false";
NSString *emailError = @"";
NSString *myEmailAddress = @"";
NSString *autoReport=@"false";
NSString *reportDidFire=@"false";
int port = 8081;
bool stillExecuting = false;

@interface AppDelegate ()
@property (nonatomic, retain) NSTimer * theTimer;
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

@synthesize arrayController;
@synthesize theTable;
@synthesize HelpWebView;
@synthesize PreferencesEmailAddressTextBox;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self initSystem];
    [self populateTable];
    [self updateInterfaceInit];
    [self initAddEntryPanel];
    [_StartStopButton setTitle:@"Start"];
    [self initPrefs];
    //[self startTimers];
    [self HelpViewLoad];
    



}
//CocoaAsyncSockets Functions
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    // This method is executed on the socketQueue (not the main thread)
    
    @synchronized(connectedSockets)
    {
        [connectedSockets addObject:newSocket];
    }
    
    NSString *host = [newSocket connectedHost];
    UInt16 port = [newSocket connectedPort];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            
          //  [self logInfo:FORMAT(@"Accepted client %@:%hu", host, port)];
            
        }
    });
    
    NSString *welcomeMsg = @"Connected to Scriptik.\r\n";
    NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
    
    [newSocket writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
    
    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    // This method is executed on the socketQueue (not the main thread)
    
    if (tag == ECHO_MSG)
    {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
    }
    if (tag == SCRIPT_MSG)
    {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
    }
    if (tag == FILE_MSG)
    {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    // This method is executed on the socketQueue (not the main thread)
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            
            NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
            NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
            NSString *getMSG = msg;
            if(getMSG){
                if ([getMSG isEqualToString:@"get"]){
                        NSString *myNetString = @"";
                    
                        NSString *myStatus = [_currStatus stringValue];
                        myNetString = [NSString stringWithFormat: @"%@\r\n",myStatus];
                    
                    
                    NSData *myNetData = [myNetString dataUsingEncoding:NSUTF8StringEncoding];
                    [sock writeData:myNetData withTimeout:-1 tag:ECHO_MSG];
                    return;
                }
                
                if ([getMSG isEqualToString:@"getScript"]){
                    NSString *myNetString = @"";
                    
                    NSString *myStatus = [_currScript stringValue];
                    myNetString = [NSString stringWithFormat: @"%@\r\n",myStatus];
                    
                    
                    NSData *myNetData = [myNetString dataUsingEncoding:NSUTF8StringEncoding];
                    [sock writeData:myNetData withTimeout:-1 tag:SCRIPT_MSG];
                    return;
                }

                if ([getMSG isEqualToString:@"getFile"]){
                    NSString *myNetString = @"";
                    
                    NSString *myStatus = [_currFile stringValue];
                    myNetString = [NSString stringWithFormat: @"%@\r\n",myStatus];
                    
                    
                    NSData *myNetData = [myNetString dataUsingEncoding:NSUTF8StringEncoding];
                    [sock writeData:myNetData withTimeout:-1 tag:FILE_MSG];
                    return;
                }
                
//                if ([getMSG isEqualToString:@"stop"]){
//                    [_StartStopButton setTitle:@"Start"];
//                    [self stopTimers];
//                    isRunning = 0;
//                    NSString *myNetString = @"";
//    
//                    NSString *myStatus = @"stopping";
//                    myNetString = [NSString stringWithFormat: @"%@\r\n",myStatus];
//    
//    
//                    NSData *myNetData = [myNetString dataUsingEncoding:NSUTF8StringEncoding];
//                    [sock writeData:myNetData withTimeout:-1 tag:FILE_MSG];
//                    return;
//                }
//                if ([getMSG isEqualToString:@"start"]){
//                    [_StartStopButton setTitle:@"Stop"];
//                    [self startTimers];
//                    isRunning = 1;
//                    NSString *myNetString = @"";
//    
//                    NSString *myStatus = @"starting";
//                    myNetString = [NSString stringWithFormat: @"%@\r\n",myStatus];
//    
//    
//                    NSData *myNetData = [myNetString dataUsingEncoding:NSUTF8StringEncoding];
//                    [sock writeData:myNetData withTimeout:-1 tag:FILE_MSG];
//                    return;
//                }
               
                
            
            else{
                NSString *myNetString = @"";
                
                NSString *myStatus = @"input error";
                myNetString = [NSString stringWithFormat: @"%@\r\n",myStatus];
                NSData *myNetData = [myNetString dataUsingEncoding:NSUTF8StringEncoding];
                [sock writeData:myNetData withTimeout:-1 tag:FILE_MSG];
                return;
            }
    }
        }
    });
    
    // Echo message back to client
  // [sock writeData:data withTimeout:-1 tag:ECHO_MSG];
   
}

/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    if (elapsed <= READ_TIMEOUT)
    {
        NSString *warningMsg = @"Are you still there?\r\n";
        NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
        
        [sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
        
        return READ_TIMEOUT_EXTENSION;
    }
    
    return 0.0;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (sock != listenSocket)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                
              //  [self logInfo:FORMAT(@"Client Disconnected")];
                
            }
        });
        
        @synchronized(connectedSockets)
        {
            [connectedSockets removeObject:sock];
        }
    }
}
//^^^End of CocoaAsyncSockets Functions^^^


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
[self.theTimer invalidate];

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}


- (void) populateTable
{

    
    
    [arrayController setContent:nil];
    NSString *xmlPath = @"~/Scriptik/config.xml";
    NSString *expandedXMLPath = [xmlPath stringByExpandingTildeInPath];
    NSError         *error=nil;
    NSXMLDocument   *xmlDOC=[[NSXMLDocument alloc]
                             initWithContentsOfURL:[NSURL fileURLWithPath:expandedXMLPath]
                             options:NSXMLNodeOptionsNone
                             error:&error
                             ];
    
    if(!xmlDOC)
    {
        NSLog(@"Error opening '%@': %@",xmlPath,error);
        
        return;
    }
    
    NSXMLElement    *rootElement=[xmlDOC rootElement];
    NSArray         *theScripts=[rootElement nodesForXPath:@"theScript" error:&error];
    NSArray         *inFolders=[rootElement nodesForXPath:@"inFolder" error:&error];
    NSArray         *outFolders=[rootElement nodesForXPath:@"outFolder" error:&error];
    NSArray         *ScriptTypes=[rootElement nodesForXPath:@"ScriptType" error:&error];
    NSArray         *Enableds=[rootElement nodesForXPath:@"Enabled" error:&error];
    if(!inFolders)
    {
        NSLog(@"Unable to get 'XMLElement' %@",error);
        
        return;
    }
    
    
    int i, count = [inFolders count];
    
    //loop through each child
    for (i=0; i < count; i++) {
        NSXMLNode *theScript = [[theScripts objectAtIndex:i]stringValue];
        NSXMLNode *inFolder = [[inFolders objectAtIndex:i]stringValue];
        NSXMLNode *outFolder = [[outFolders objectAtIndex:i]stringValue];
        NSXMLNode *ScriptType = [[ScriptTypes objectAtIndex:i]stringValue];
        NSXMLNode *Enabled = [[Enableds objectAtIndex:i]stringValue];

        NSString *niceScript = theScript;
        NSArray *tScript = [niceScript componentsSeparatedByString: @"/"];
        NSString *truncScript = [tScript lastObject];
        
        NSString *niceInFolder = inFolder;
        NSArray *tInFolder = [niceInFolder componentsSeparatedByString: @"/"];
        int inCount = [tInFolder count] -2;
        NSString *mytruncInFolder = [tInFolder objectAtIndex:inCount];
        NSString *truncInFolder = [mytruncInFolder stringByAppendingString:@"/"];
        
        NSString *niceOutFolder = outFolder;
        NSArray *tOutFolder = [niceOutFolder componentsSeparatedByString: @"/"];
        int outCount = [tOutFolder count] -2;
        NSString *mytruncOutFolder = [tOutFolder objectAtIndex:inCount];
        NSString *truncOutFolder = [mytruncOutFolder stringByAppendingString:@"/"];
        
        NSString *niceEnabled = Enabled;
       
        NSString *truncEnabled = @"rutro";
        if ([niceEnabled isEqualToString:@"true"]){
            truncEnabled = @"√";
            
        }
        else{
            truncEnabled = @"";
        }
        

        
        NSMutableDictionary *value = [[NSMutableDictionary alloc] init];

        [value setObject:theScript forKey:@"Script"];
        [value setObject:inFolder forKey:@"inFolder"];
        [value setObject:outFolder forKey:@"outFolder"];
        [value setObject:ScriptType forKey:@"ScriptType"];
        [value setObject:Enabled forKey:@"Enabled"];
        [value setObject:truncScript forKey:@"tScript"];
        [value setObject:truncInFolder forKey:@"tinFolder"];
        [value setObject:truncOutFolder forKey:@"toutFolder"];
        [value setObject:truncEnabled forKey:@"tEnabled"];
        
        [arrayController addObject:value];
        
        //[value release];
        
        [theTable reloadData];
    }
}


- (IBAction)StartStopButton:(id)sender {
    if(isRunning == 0){


        [self startTimers];
        
        [_StartStopButton setTitle:@"Stop"];
        isRunning = 1;
        
        
    }
    
    else {
        [_StartStopButton setTitle:@"Start"];
    

        [self stopTimers];
        isRunning = 0;
    }
   }



- (void) startTimers
{
   //Using GCD to thread the NSTimer that fires the script runner engine.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        dispatch_async( dispatch_get_main_queue(), ^{
            
            self.theTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector: @selector(timerFired:) userInfo: nil repeats: YES];

            
        });
    });
    NSLog(@"Start");
    if((stillExecuting == true) && (isRunning == 0)){
        [_currStatus setStringValue:@"Queueing. . ."];
        [_currSpinner startAnimation:nil];
    }
    
}

- (void) stopTimers
{
    NSLog(@"Stop");
  [self.theTimer invalidate];
    [self updateInterfaceInit];
    
}

- (void) timerFired:(NSTimer*)theTimer{

    if(!stillExecuting){
        stillExecuting = true;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
        [_currStatus setStringValue:@"Idle. . ."];
        });
    NSString *xmlPath = @"~/Scriptik/config.xml";
    NSString *expandedXMLPath = [xmlPath stringByExpandingTildeInPath];
    NSError         *error=nil;
    NSXMLDocument   *xmlDOC=[[NSXMLDocument alloc]
                             initWithContentsOfURL:[NSURL fileURLWithPath:expandedXMLPath]
                             options:NSXMLNodeOptionsNone
                             error:&error
                             ];
    
    if(!xmlDOC)
    {
        NSLog(@"Error reading '%@': %@",xmlPath,error);
        
        return;
    }
    
    NSXMLElement    *rootElement=[xmlDOC rootElement];
    NSArray         *theScripts=[rootElement nodesForXPath:@"theScript" error:&error];
    NSArray         *inFolders=[rootElement nodesForXPath:@"inFolder" error:&error];
    NSArray         *outFolders=[rootElement nodesForXPath:@"outFolder" error:&error];
    NSArray         *ScriptTypes=[rootElement nodesForXPath:@"ScriptType" error:&error];
    NSArray         *Enableds=[rootElement nodesForXPath:@"Enabled" error:&error];
    if(!inFolders)
    {
        NSLog(@"Unable to get 'XMLElement': %@",error);
        
        return;
    }

    
    int i, count = [inFolders count];
    
    
    for (i=0; i < count; i++) {
        stillExecuting = true;
        NSString *theScript = [[theScripts objectAtIndex:i]stringValue];
        NSString *inFolder = [[inFolders objectAtIndex:i]stringValue];
        NSString *outFolder = [[outFolders objectAtIndex:i]stringValue];
        NSString *ScriptType = [[ScriptTypes objectAtIndex:i]stringValue];
        NSString *Enabled = [[Enableds objectAtIndex:i]stringValue];
        
        NSString *isEnabled = Enabled;
        if ([Enabled isEqualToString:@"true"])
            
        {
            NSString *pathValidate = [self validateCheck:theScript:inFolder:outFolder];
            
            if ([pathValidate isEqualToString:@"true"]){
                
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSArray *theFiles =  [fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:inFolder]
                                            includingPropertiesForKeys:[NSArray arrayWithObject:NSURLNameKey]
                                                               options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 error:nil];
            NSMutableArray *theFilesOnly=[NSMutableArray array];
            
            for (NSURL *theURL in theFiles) {
                
                // Retrieve the file name. From NSURLNameKey, cached during the enumeration.
                NSString *myfileName;
                [theURL getResourceValue:&myfileName forKey:NSURLNameKey error:NULL];
                
                // Retrieve whether a directory. From NSURLIsDirectoryKey, also
                // cached during the enumeration.
                
                NSNumber *isDirectory;
                [theURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
                
                if([isDirectory boolValue] == NO)
                {
                    [theFilesOnly addObject: myfileName];
                }
            }

            if ([theFilesOnly count] != 0){
                if (isRunning == 0){
                    stillExecuting = false;
                    return;
                }
            NSURL *fileName = [theFilesOnly objectAtIndex:0];
            NSString *fileNamewithPath = (@"%@",[inFolder stringByAppendingPathComponent:fileName]);

                
                    dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateInterface:theScript:fileNamewithPath];
                    });
                  //the if statements below filter execution to the correct handler
                if ([ScriptType isEqualToString:@"AppleScript"]){


                NSString *interpreter = @"/usr/bin/osascript";
                NSArray *setArguments = [NSArray arrayWithObjects:theScript, fileNamewithPath, inFolder, outFolder, nil];
                    [self updateLog:theScript:fileNamewithPath:inFolder:outFolder];

                [[NSTask launchedTaskWithLaunchPath:interpreter arguments:setArguments]waitUntilExit];
                

                }
                if ([ScriptType isEqualToString:@"InDesign"]){
                    

                    NSString *tildeHandler = @"~/Scriptik/Handlers/IDHandler";
                    NSString *handler = [tildeHandler stringByExpandingTildeInPath];
                    NSString *interpreter = @"/usr/bin/osascript";
                    NSArray *setArguments = [NSArray arrayWithObjects:handler, theScript, fileNamewithPath, inFolder, outFolder, nil];
                    [self updateLog:theScript:fileNamewithPath:inFolder:outFolder];

                    [[NSTask launchedTaskWithLaunchPath:interpreter arguments:setArguments]waitUntilExit];
                    

                }
                if ([ScriptType isEqualToString:@"ShellScript"]){
                    

                    NSString *interpreter = theScript;
                    NSArray *setArguments = [NSArray arrayWithObjects:fileNamewithPath, inFolder, outFolder, nil];
                    [self updateLog:theScript:fileNamewithPath:inFolder:outFolder];

                    [[NSTask launchedTaskWithLaunchPath:interpreter arguments:setArguments]waitUntilExit];
                    
                    
                }
                if ([ScriptType isEqualToString:@"Photoshop"]){
                    

                    NSString *tildeHandler = @"~/Scriptik/Handlers/PhotoshopHandler";
                    NSString *handler = [tildeHandler stringByExpandingTildeInPath];
                    NSString *interpreter = @"/usr/bin/osascript";
                    NSArray *setArguments = [NSArray arrayWithObjects:handler, theScript, fileNamewithPath, inFolder, outFolder, nil];
                    [self updateLog:theScript:fileNamewithPath:inFolder:outFolder];

                    [[NSTask launchedTaskWithLaunchPath:interpreter arguments:setArguments]waitUntilExit];
                    
                    
                }

                }
                dispatch_async(dispatch_get_main_queue(), ^{
                [self updateInterfaceFinish];
                [_currSpinner stopAnimation:nil];
                });
                stillExecuting = false;
            }
                    
            
                }
        if ([autoReport isEqualToString:@"true"]){
            NSDateFormatter *reportDateFormatter=[[NSDateFormatter alloc] init];
            [reportDateFormatter setDateFormat:@"dd"];
            NSString *myReportDate = [reportDateFormatter stringFromDate:[NSDate date]];
            NSString *reportDateLine = [NSString stringWithFormat:@"\r%@\r\r\r", myReportDate];
            NSLog(@"%@",reportDateLine);
            if ([myReportDate isEqualToString:@"01"]){
                if ([reportDidFire isEqualToString:@"false"]){
                    [self generateReport];
                    [self purgeLog];
                    reportDidFire = @"true";
                }
                if (![myReportDate isEqualToString:@"01"]){
                    reportDidFire = @"false";
    
                }

            }
        } //end autoReport if Statement
        
            }
        }); //end main dispatch
        
    }
        }
        
- (void) updateInterface: (NSString*)theScript : (NSString*)fileNamewithPath{
    NSString *myScriptLabel = @"Script: ";
    NSString *labelScript = [myScriptLabel stringByAppendingString:theScript];
    NSString *myFileLabel = @"File: ";
    NSString *labelFile = [myFileLabel stringByAppendingString:fileNamewithPath];
    [_currScript setStringValue:labelScript];
    [_currFile setStringValue: labelFile];
    [_currStatus setStringValue:@"Processing. . ."];
    [_currSpinner startAnimation:nil];
}

- (void) updateInterfaceFinish{
    NSString *myScriptLabel = @"Script: ";
    NSString *myFileLabel = @"File: ";
    [_currScript setStringValue: myScriptLabel];
    [_currFile setStringValue: myFileLabel];
    [_currSpinner stopAnimation:nil];
    
}
- (void) updateInterfaceInit{
    NSString *myScriptLabel = @"Script: ";
    NSString *myFileLabel = @"File: ";
    [_currScript setStringValue: myScriptLabel];
    [_currFile setStringValue: myFileLabel];
    [_currStatus setStringValue:@"stopped."];
    [_currSpinner stopAnimation:nil];
    
}

//Add/ChangeEntry Panel

- (IBAction)loadScriptButton:(id)sender {

    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        for( NSURL* URL in [openDlg URLs] )
        {
            
            addEntryScript = [URL path];

            [_loadScriptLabel setStringValue: addEntryScript];
        }
    }
}

- (IBAction)loadInFolderButton:(id)sender {

    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        for( NSURL* URL in [openDlg URLs] )
        {
            
            addEntryInFolder = [CFBridgingRelease(CFURLCopyPath((CFURLRef)URL)) stringByRemovingPercentEncoding];

            [_loadInFolderLabel setStringValue: addEntryInFolder];
        }
    }
}

- (IBAction)loadOutFolderButton:(id)sender {

    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        for( NSURL* URL in [openDlg URLs] )
        {
            
            addEntryOutFolder = [CFBridgingRelease(CFURLCopyPath((CFURLRef)URL)) stringByRemovingPercentEncoding];

            [_loadOutFolderLabel setStringValue: addEntryOutFolder];
        }
    }
}

- (IBAction)ScriptTypeRadioGroup:(id)sender {

    bool ShellRadioState = [_ShellRadio state];
    bool AppleScriptRadioState = [_AppleScriptRadio state];
    bool InDesignRadioState = [_InDesignRadio state];
    bool PhotoshopRadioState = [_PhotoshopRadio state];
    if (ShellRadioState == true){

        addEntryScriptType = @"ShellScript";
    }
    if (AppleScriptRadioState == true){

        addEntryScriptType = @"AppleScript";
    }
    if (InDesignRadioState == true){

        addEntryScriptType = @"InDesign";
    }
    if (PhotoshopRadioState == true){

        addEntryScriptType = @"Photoshop";
    }

}

- (IBAction)scriptEnabledCheckBox:(id)sender {

    bool EnabledCheckBoxState = [_EnabledCheckBox state];
    if (EnabledCheckBoxState == true){
        addEntryIsEnabled = @"true";

    }
        else
        {
            addEntryIsEnabled =@"false";
        }
    }


- (IBAction)addChangeEntrySaveButton:(id)sender {

    NSMutableDictionary *value = [[NSMutableDictionary alloc] init];
    int mySelection = [arrayController selectionIndex];
    [value setObject:addEntryScript forKey:@"Script"];
    [value setObject:addEntryInFolder forKey:@"inFolder"];
    [value setObject:addEntryOutFolder forKey:@"outFolder"];
    [value setObject:addEntryScriptType forKey:@"ScriptType"];
    [value setObject:addEntryIsEnabled forKey:@"Enabled"];
    
    NSString *niceScript = addEntryScript;
    NSArray *tScript = [niceScript componentsSeparatedByString: @"/"];
    NSString *truncScript = [tScript lastObject];

    NSString *niceEnabled = addEntryIsEnabled;
    
    NSString *truncEnabled = @"rutro";
    if ([niceEnabled isEqualToString:@"true"]){
        truncEnabled = @"√";
        
    }
    else{
        truncEnabled = @"";
    }

    [value setObject:truncScript forKey:@"tScript"];
    [value setObject:truncEnabled forKey:@"tEnabled"];

    if (EditFlag == true){
        [arrayController removeObjectAtArrangedObjectIndex:mySelection];
        [arrayController insertObject:value atArrangedObjectIndex:mySelection];

        
           }
    else{
    [arrayController addObject:value];
    }


    [self saveXML];
    //[self populateTable];
    [theTable reloadData];
    
    [_AddChangeEntryWindow orderOut:self];
    [theTable setEnabled:YES];
   
}

- (IBAction)addChangeEntryCancelButton:(id)sender {
    [self initAddEntryPanel];
    [_AddChangeEntryWindow orderOut:self];
    [theTable setEnabled:YES];
    [_ManageWindow makeKeyAndOrderFront:self];

}

- (void) initAddEntryPanel{
addEntryScript = @"";
    [_loadScriptLabel setStringValue: addEntryScript];
addEntryInFolder = @"";
    [_loadInFolderLabel setStringValue: addEntryInFolder];
addEntryOutFolder = @"null";
    [_loadOutFolderLabel setStringValue: addEntryOutFolder];
addEntryScriptType = @"ShellScript";
    [_ShellRadio setState:true];
addEntryIsEnabled = @"true";
    [_EnabledCheckBox setState:true];
    EditFlag = false;

}

- (IBAction)AddEntryButton:(id)sender {
    [self initAddEntryPanel];
    [_AddChangeEntryWindow makeKeyAndOrderFront:self];
    [theTable setEnabled:NO];
    
}

- (IBAction)EditButton:(id)sender {
    
    [self initAddEntryPanel];
    [_AddChangeEntryWindow makeKeyAndOrderFront:self];
    [theTable setEnabled:NO];
    EditFlag = true;
    NSArray *theIndex = [arrayController arrangedObjects];
    NSString *myScript = [[[theIndex valueForKey:@"Script"] allObjects]objectAtIndex: [arrayController selectionIndex]];
    NSString *myInFolder = [[[theIndex valueForKey:@"inFolder"] allObjects]objectAtIndex:[arrayController selectionIndex]];
    NSString *myOutFolder = [[[theIndex valueForKey:@"outFolder"] allObjects]objectAtIndex:[arrayController selectionIndex]];
    NSString *myScriptType = [[[theIndex valueForKey:@"ScriptType"] allObjects]objectAtIndex:[arrayController selectionIndex]];
    NSString *myEnabled = [[[theIndex valueForKey:@"Enabled"] allObjects]objectAtIndex:[arrayController selectionIndex]];


    addEntryScript = myScript;
    [_loadScriptLabel setStringValue: addEntryScript];
    addEntryInFolder = myInFolder;
    [_loadInFolderLabel setStringValue: addEntryInFolder];
    addEntryOutFolder = myOutFolder;
    [_loadOutFolderLabel setStringValue: addEntryOutFolder];
    addEntryScriptType = myScriptType;
    if ([addEntryScriptType isEqualToString:@"ShellScript"]){
        [_ShellRadio setState:true];
    }
    if ([addEntryScriptType isEqualToString:@"AppleScript"]){
        [_AppleScriptRadio setState:true];
    }
    if ([addEntryScriptType isEqualToString:@"InDesign"]){
        [_InDesignRadio setState:true];
    }
    if ([addEntryScriptType isEqualToString:@"Photoshop"]){
        [_PhotoshopRadio setState:true];
    }
    addEntryIsEnabled = myEnabled;
    if ([addEntryIsEnabled isEqualToString:@"true"]){
        [_EnabledCheckBox setState:true];
    }
    if ([addEntryIsEnabled isEqualToString:@"false"]){
        [_EnabledCheckBox setState:false];
    }
    
}

- (IBAction)RemoveEntryButton:(id)sender {
    int mySelection = [arrayController selectionIndex];
    [arrayController removeObjectAtArrangedObjectIndex:mySelection];
    [self saveXML];
    
}


- (IBAction)DoneButton:(id)sender {
    [_ManageWindow orderOut:self];
    [_MainWindow makeKeyAndOrderFront:self];
}


- (void) saveXML{
    NSArray *theIndex = [arrayController arrangedObjects];
    int indexCount = [theIndex count];
    
    NSString *mypathname = [@"~/Scriptik/config.xml" stringByExpandingTildeInPath];
    NSURL *myurl = [NSURL fileURLWithPath:mypathname];
    
    
    NSXMLElement *myroot = [NSXMLNode elementWithName:@"Config"];
    NSXMLDocument *myxmlDoc = [[NSXMLDocument alloc] initWithRootElement:myroot];
    
    for (int i = 0; i < [theIndex count]; i++){
        NSString *myScript = [[[theIndex valueForKey:@"Script"] allObjects]objectAtIndex:i];
        NSString *myInFolder = [[[theIndex valueForKey:@"inFolder"] allObjects]objectAtIndex:i];
        NSString *myOutFolder = [[[theIndex valueForKey:@"outFolder"] allObjects]objectAtIndex:i];
        NSString *myScriptType = [[[theIndex valueForKey:@"ScriptType"] allObjects]objectAtIndex:i];
        NSString *myEnabled = [[[theIndex valueForKey:@"Enabled"] allObjects]objectAtIndex:i];
        
        id item0 = [NSXMLNode elementWithName:@"theScript" stringValue:myScript];
        id item1 = [NSXMLNode elementWithName:@"inFolder" stringValue:myInFolder];
        id item2 = [NSXMLNode elementWithName:@"outFolder" stringValue:myOutFolder];
        id item3 = [NSXMLNode elementWithName:@"ScriptType" stringValue:myScriptType];
        id item4 = [NSXMLNode elementWithName:@"Enabled" stringValue:myEnabled];
        
        [myroot insertChild:item4 atIndex:0];
        [myroot insertChild:item3 atIndex:0];
        [myroot insertChild:item2 atIndex:0];
        [myroot insertChild:item1 atIndex:0];
        [myroot insertChild:item0 atIndex:0];
    }

    NSData *mydata = [myxmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
    [mydata writeToURL:myurl atomically:YES];
    

}

- (void) initServer{
    socketQueue = dispatch_queue_create("socketQueue", NULL);
    
    listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];

    NSError *error = nil;
    if(![listenSocket acceptOnPort:port error:&error])
    {
        NSLog(@"Error starting server:");
        //    return;
    }
    
    NSLog(@"Status server started on port %hu", [listenSocket localPort]);

}

- (void) initSystem{
    

    
    NSString *pathToFile = @"~/Scriptik";
    NSString *expandedPathToFile = [pathToFile stringByExpandingTildeInPath];
    BOOL isDir = NO;
    BOOL isFile = [[NSFileManager defaultManager] fileExistsAtPath:expandedPathToFile isDirectory:&isDir];
    
    if(isFile)
    {
        
    }
    else
    {
        NSError * error = nil;
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath: expandedPathToFile
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:&error];
        if (!success){
            NSLog(@"Error");
        }
        else{
            NSLog(@"Success");;
        }
    }
    NSString *configPathToFile = @"~/Scriptik/config.xml";
    NSString *expandedConfigPathToFile = [configPathToFile stringByExpandingTildeInPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:expandedConfigPathToFile]){

    }
    else{


        NSXMLElement *myroot = [NSXMLNode elementWithName:@"Config"];
        NSXMLDocument *myxmlDoc = [[NSXMLDocument alloc] initWithRootElement:myroot];
        
        NSData *mydata = [myxmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
        [[NSFileManager defaultManager] createFileAtPath:expandedConfigPathToFile
                                                contents:mydata
                                              attributes:nil];
    }
    NSString *pathToHandlers = @"~/Scriptik/Handlers";
    NSString *expandedPathToHandlers = [pathToHandlers stringByExpandingTildeInPath];
    BOOL isDirHandle = NO;
    BOOL isFileHandle = [[NSFileManager defaultManager] fileExistsAtPath:expandedPathToHandlers isDirectory:&isDirHandle];
    
    if(isFileHandle)
    {
        
    }
    else
    {
        NSError * error = nil;
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath: expandedPathToHandlers
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:&error];
        if (!success){
            NSLog(@"Error");
        }
        else{
            NSLog(@"Success");;
        }
    }
    NSString *configPathToInDesignHandler = @"~/Scriptik/Handlers/IDHandler";
    NSString *expandedPathToInDesignHandler = [configPathToInDesignHandler stringByExpandingTildeInPath];

    if ([[NSFileManager defaultManager] fileExistsAtPath:expandedPathToInDesignHandler]){

    }
    else{
        NSString *myIDHandler = @"#!/usr/bin/osascript\n\
        on run (theScript, fileName, inFolder, outFolder)\n\
        --set fileName to posix file filename as string\n\
        --set inFolder to posix file inFolder as string\n\
        --set outFolder to posix file outFolder as string\n\
        tell application id \"com.adobe.InDesign\"\n\
        \n\
        set aScript to \"#include \"& (the quoted form of theScript) & \";\" & return\n\
        --set aScript to aScript & \"alert(\\\"hello\\\");\" & return\n\
        set aScript to aScript & \"main(arguments);\" & return\n\
        --set argv to FileName & inFolder & outFolder as list\n\
        do script aScript language javascript with arguments {fileName, inFolder, outFolder}\n\
        end tell\n\
        \n\
        end run";
        NSData *IDHandlerContents = [myIDHandler dataUsingEncoding:NSUTF8StringEncoding];
        [[NSFileManager defaultManager] createFileAtPath:expandedPathToInDesignHandler
                                                contents:IDHandlerContents
                                              attributes:nil];
    }
    NSString *configPathToPhotoshopHandler = @"~/Scriptik/Handlers/PhotoshopHandler";
    NSString *expandedPathToPhotoshopHandler = [configPathToPhotoshopHandler stringByExpandingTildeInPath];

    if ([[NSFileManager defaultManager] fileExistsAtPath:expandedPathToPhotoshopHandler]){

    }
    else{
        NSString *myPhotoshopHandler = @"#!/usr/bin/osascript\n\
        on run (theScript, fileName, inFolder, outFolder)\n\
        tell application id \"com.adobe.Photoshop\"\n\
        --set fileName to posix path of fileName\n\
        --set inFolder to posix path of inFolder\n\
        --set outFolder to posix path of outFolder\n\
        -- display dialog fileName as string\n\
        set aScript to \"#include \"& (the quoted form of theScript) & \";\" & return\n\
        set aScript to aScript & \"main(arguments);\" & return\n\
        --set argv to FileName & inFolder & outFolder as list\n\
        do javascript aScript with arguments {fileName, inFolder, outFolder}\n\
        \n\
        end tell\n\
        \n\
        end run";
        NSData *PhotoshopContents = [myPhotoshopHandler dataUsingEncoding:NSUTF8StringEncoding];
        [[NSFileManager defaultManager] createFileAtPath:expandedPathToPhotoshopHandler
                                                contents:PhotoshopContents
                                              attributes:nil];
    }
    NSString *configPathPrefFile = @"~/Scriptik/prefs.xml";
    NSString *expandedConfigPathToPrefFile = [configPathPrefFile stringByExpandingTildeInPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:expandedConfigPathToPrefFile]){

    }
    else{
        
        
        NSXMLElement *myPrefroot = [NSXMLNode elementWithName:@"Pref"];
        NSXMLDocument *myPrefxmlDoc = [[NSXMLDocument alloc] initWithRootElement:myPrefroot];
        
        NSData *myPrefData = [myPrefxmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
        [[NSFileManager defaultManager] createFileAtPath:expandedConfigPathToPrefFile
                                                contents:myPrefData
                                              attributes:nil];
    }

}
- (IBAction)PreferencesCloseButton:(id)sender {
    NSString *emailAddressFromBox = [PreferencesEmailAddressTextBox stringValue];
    NSString *mypathname = [@"~/Scriptik/prefs.xml" stringByExpandingTildeInPath];
    NSString *portField = [_PreferencesPortField stringValue];
    NSURL *myurl = [NSURL fileURLWithPath:mypathname];
    
    
    NSXMLElement *myroot = [NSXMLNode elementWithName:@"Pref"];
    NSXMLDocument *myxmlDoc = [[NSXMLDocument alloc] initWithRootElement:myroot];
    id myAutostart = [NSXMLNode elementWithName:@"Autostart" stringValue:Autostart ];
    id myEmailError = [NSXMLNode elementWithName:@"emailError" stringValue:emailError ];
    id myEmailAddressFromBox = [NSXMLNode elementWithName:@"emailAddress" stringValue:emailAddressFromBox];
    id myAutoReport = [NSXMLNode elementWithName:@"autoReport" stringValue:autoReport ];
    id myServerEnabled = [NSXMLNode elementWithName:@"serverEnabled" stringValue:serverEnabled ];
    id myPortField = [NSXMLNode elementWithName:@"serverPort" stringValue:portField ];
    [myroot insertChild:myAutostart atIndex:0];
    [myroot insertChild:myEmailError atIndex:1];
    [myroot insertChild:myEmailAddressFromBox atIndex:2];
    [myroot insertChild:myAutoReport atIndex:3];
    [myroot insertChild:myServerEnabled atIndex:4];
    [myroot insertChild:myPortField atIndex:5];
    NSData *mydata = [myxmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
    [mydata writeToURL:myurl atomically:YES];

    
    [_PreferencesWindow orderOut:self];
    [self initPrefs];
}


- (IBAction)PreferencesServerEnabledCheckBox:(id)sender {
    bool ServerEnabledCheckBoxState = [_PreferencesServerEnabledCheckBox state];
    if (ServerEnabledCheckBoxState == true){
        serverEnabled = @"true";
            }
    else{
        serverEnabled = @"false";
    }
}

- (IBAction)PreferencesAutostartCheckBox:(id)sender {
    bool AutostartCheckBoxState = [_PreferencesAutostartCheckBox state];
    if (AutostartCheckBoxState == true){
        Autostart = @"true";
        
    }
    else
    {
        Autostart = @"false";
    }

}

- (IBAction)PreferencesEmailErrorCheckBox:(id)sender {
    bool EmailErrorCheckBoxState = [_PreferencesEmailErrorCheckBox state];
    if (EmailErrorCheckBoxState == true){
        emailError = @"true";
        
    }
    else
    {
        emailError = @"false";
    }
    
}

- (IBAction)PreferencesAutoReportCheckBox:(id)sender {
    bool autoReportCheckBoxState = [_PrefrencesAutoReportCheckBox state];
    if (autoReportCheckBoxState == true){
        autoReport = @"true";
    }
    else
    {
        autoReport = @"false";
    }
}

- (void) initPrefs{
    NSString *xmlPath = @"~/Scriptik/prefs.xml";
    NSString *expandedXMLPath = [xmlPath stringByExpandingTildeInPath];
    NSError         *error=nil;
    NSXMLDocument   *xmlDOC=[[NSXMLDocument alloc]
                             initWithContentsOfURL:[NSURL fileURLWithPath:expandedXMLPath]
                             options:NSXMLNodeOptionsNone
                             error:&error
                             ];
    
    if(!xmlDOC)
    {
        NSLog(@"Error reading '%@': %@",xmlPath,error);
        
        return;
    }
    
    NSXMLElement    *rootElement=[xmlDOC rootElement];
    NSArray         *theAutostart=[rootElement nodesForXPath:@"Autostart" error:&error];
    NSXMLNode *theAutostartValue = [[theAutostart objectAtIndex:0]stringValue];
    NSString *myAutostartValue = theAutostartValue;

    NSArray         *theEmailError=[rootElement nodesForXPath:@"emailError" error:&error];
    NSXMLNode *theEmailErrorValue = [[theEmailError objectAtIndex:0]stringValue];
    NSString *myEmailErrorValue = theEmailErrorValue;
    
    NSArray         *theEmailAddress=[rootElement nodesForXPath:@"emailAddress" error:&error];
    NSXMLNode *theEmailAddressValue = [[theEmailAddress objectAtIndex:0]stringValue];
    NSString *myEmailAddressValue = theEmailAddressValue;
    
    NSArray         *theAutoReport=[rootElement nodesForXPath:@"autoReport" error:&error];
    NSXMLNode   *theAutoReportValue = [[theAutoReport objectAtIndex:0]stringValue];
    NSString    *myAutoReportValue = theAutoReportValue;
    
    NSArray         *theServerEnabled=[rootElement nodesForXPath:@"serverEnabled" error:&error];
    NSXMLNode   *theServerEnabledValue = [[theServerEnabled objectAtIndex:0]stringValue];
    NSString    *myServerEnabledValue = theServerEnabledValue;
    
    NSArray         *theServerPort=[rootElement nodesForXPath:@"serverPort" error:&error];
    NSXMLNode   *theServerPortValue = [[theServerPort objectAtIndex:0]stringValue];
    NSString    *myServerPortValue = theServerPortValue;
 
    if([myServerEnabledValue isEqualToString:@"true"]){
        [listenSocket disconnect];
        serverEnabled = @"true";
        [_PreferencesServerEnabledCheckBox setState:true];
        NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
        port = [[formatter numberFromString:theServerPortValue] unsignedShortValue];
        [self initServer];
    }
    else {
        [listenSocket disconnect];
        
        @synchronized(connectedSockets)
        {
            NSUInteger i;
            for (i = 0; i < [connectedSockets count]; i++)
            {
                // Call disconnect on the socket,
                // which will invoke the socketDidDisconnect: method,
                // which will remove the socket from the list.
                [[connectedSockets objectAtIndex:i] disconnect];
            }
        }
        NSLog(@"Server stopped");
        serverEnabled = @"false";
    }
    [_PreferencesPortField setStringValue:myServerPortValue];
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    port = [[formatter numberFromString:theServerPortValue] unsignedShortValue];
    if ([myAutoReportValue isEqualToString:@"true"]){
        autoReport = @"true";
        [_PrefrencesAutoReportCheckBox setState:true];
    }
    else {
        autoReport = @"false";
        [_PrefrencesAutoReportCheckBox setState:false];
    }
    
    if ([myAutostartValue isEqualToString:@"true"]){
        Autostart = @"true";
    }
    else{
        Autostart = @"false";
    }
    if ([Autostart isEqualToString:@"true"]){
        [_PreferencesAutostartCheckBox setState:true];


            [self startTimers];
            [_StartStopButton setTitle:@"Stop"];
            isRunning = 1;
            
            }
        else{
            [_PreferencesAutostartCheckBox setState:false];
            Autostart = @"false";
        }
    if ([myEmailErrorValue isEqualToString:@"true"]){
        emailError = @"true";
        [_PreferencesEmailErrorCheckBox setState:true];
        NSArray         *theEmailAddress=[rootElement nodesForXPath:@"emailAddress" error:&error];
        NSXMLNode *theEmailAddressValue = [[theEmailAddress objectAtIndex:0]stringValue];
        myEmailAddress = theEmailAddressValue;
    
    }
    else{
        [_PreferencesEmailErrorCheckBox setState:false];
        emailError = @"false";
    }
    [PreferencesEmailAddressTextBox setStringValue:myEmailAddressValue];
}

- (IBAction)ExportConfigMenuItem:(id)sender {
    NSString *configPath = @"~/Scriptik/config.xml";
    NSString *expandedPath = [configPath stringByExpandingTildeInPath];


    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        for( NSURL *URL in [openDlg URLs] )
        {
          NSString *exportPath = [CFBridgingRelease(CFURLCopyPath((CFURLRef)URL)) stringByRemovingPercentEncoding];
 
            
            NSFileManager *manager = [[NSFileManager alloc] init];
            NSError *error = nil;
            [manager copyItemAtPath:expandedPath toPath:[exportPath stringByAppendingPathComponent:@"config.xml"] error:&error];
        }
    }

}

- (IBAction)ImportConfigMenuItem:(id)sender {
    


    NSString *configPath = @"~/Scriptik/config.xml";
    NSString *expandedPath = [configPath stringByExpandingTildeInPath];


    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        for( NSURL *URL in [openDlg URLs] )
        {
            NSString *importPath = [CFBridgingRelease(CFURLCopyPath((CFURLRef)URL)) stringByRemovingPercentEncoding];


            
        NSFileManager *manager = [[NSFileManager alloc] init];
        NSError *error = nil;

            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:expandedPath];
            if (fileHandle){
                        [manager removeItemAtPath:expandedPath error:&error];
                [manager copyItemAtPath:importPath toPath:expandedPath error:&error];
                
            }
            else{
                [manager copyItemAtPath:importPath toPath:expandedPath error:&error];
            }

            [self populateTable];
        
        }
    }

    
}

- (IBAction)GenerateReportMenuItem:(id)sender {
    NSLog(@"Generate Report");
    [self generateReport];
}

- (IBAction)PurgeLogMenuItem:(id)sender {

    [self purgeLog];

}

- (IBAction)AlertOkButton:(id)sender {
    [_alertWindow orderOut:self];
    validateError = @"false";
}

- (void) updateLog:(NSString*)theScript : (NSString*) fileNamewithPath : (NSString*) inFolder : (NSString*) outFolder{

    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSString *myDate = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *logString = [NSString stringWithFormat:@"%@ %@, %@, %@, %@\r",myDate,theScript,fileNamewithPath,inFolder,outFolder];


    NSString *logPath = @"~/Scriptik/scriptRunner.log";
    NSString *expandedlogPath = [logPath stringByExpandingTildeInPath];

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:expandedlogPath];
    if (fileHandle){
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[logString dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
    }
    else{
        [logString writeToFile:expandedlogPath
                  atomically:NO
                    encoding:NSStringEncodingConversionAllowLossy
                       error:nil];
    }
    
}

- (void) purgeLog{
    NSString *logPath = @"~/Scriptik/scriptRunner.log";
    NSString *expandedlogPath = [logPath stringByExpandingTildeInPath];
    NSLog(@"Purge Log");
    NSFileManager *manager = [[NSFileManager alloc] init];
    NSError *error = nil;
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:expandedlogPath];
    if (fileHandle){
        [manager removeItemAtPath:expandedlogPath error:&error];
        
        
    }
    else{
        NSLog(@"No log to remove");
    }
}

- (void) generateReport{
    NSString *xmlPath = @"~/Scriptik/config.xml";
    NSString *expandedXMLPath = [xmlPath stringByExpandingTildeInPath];
    NSError         *error=nil;
    NSXMLDocument   *xmlDOC=[[NSXMLDocument alloc]
                             initWithContentsOfURL:[NSURL fileURLWithPath:expandedXMLPath]
                             options:NSXMLNodeOptionsNone
                             error:&error
                             ];
    
    if(!xmlDOC)
    {
        NSLog(@"Error reading '%@': %@",xmlPath,error);
        
        return;
    }
    
    NSXMLElement    *rootElement=[xmlDOC rootElement];
    NSArray         *theScripts=[rootElement nodesForXPath:@"theScript" error:&error];
    NSArray         *inFolders=[rootElement nodesForXPath:@"inFolder" error:&error];
    NSArray         *outFolders=[rootElement nodesForXPath:@"outFolder" error:&error];
    NSArray         *ScriptTypes=[rootElement nodesForXPath:@"ScriptType" error:&error];
    NSArray         *Enableds=[rootElement nodesForXPath:@"Enabled" error:&error];
    if(!inFolders)
    {
        NSLog(@"Unable to get 'XMLElement': %@",error);
        
        return;
    }
 
    NSDateFormatter *dateFormatter2=[[NSDateFormatter alloc] init];
    [dateFormatter2 setDateFormat:@"yyyy-MM-dd"];
    NSString *myDate2 = [dateFormatter2 stringFromDate:[NSDate date]];
    
    
    NSString *reportPath = [NSString stringWithFormat:@"~/Desktop/ScriptReport_'%@'.txt",myDate2];
    NSString *expandedreportPath = [reportPath stringByExpandingTildeInPath];
    
    NSString *logPath = @"~/Scriptik/scriptRunner.log";
    NSString *expandedlogPath = [logPath stringByExpandingTildeInPath];
    NSString *reportLine = @"";
    int i, count = [inFolders count];
    
    int totalCount = 0;
    for (i=0; i < count; i++) {
        NSString *theScript = [[theScripts objectAtIndex:i]stringValue];
        NSString *inFolder = [[inFolders objectAtIndex:i]stringValue];
        NSString *outFolder = [[outFolders objectAtIndex:i]stringValue];
        NSString *ScriptType = [[ScriptTypes objectAtIndex:i]stringValue];
        NSString *Enabled = [[Enableds objectAtIndex:i]stringValue];

        NSTask *task;
        task = [[NSTask alloc] init];
        [task setLaunchPath: @"/usr/bin/grep"];
        [task waitUntilExit];

        NSString *words = [NSString stringWithFormat:@"'%@'",inFolder];
        NSString *quotedLogPath = [NSString stringWithFormat:@"'%@'",expandedlogPath];
        NSArray *arguments;
        arguments = [NSArray arrayWithObjects: @"-o", inFolder, expandedlogPath, nil];
        
        [task setArguments: arguments];
        
        NSPipe *pipe;
        pipe = [NSPipe pipe];
        [task setStandardOutput: pipe];
        
        NSFileHandle *file;
        file = [pipe fileHandleForReading];
        
        [task launch];
        
        NSData *data;
        data = [file readDataToEndOfFile];
        
        NSString *string;
        string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        
        NSArray *myList = [string componentsSeparatedByString:@"\n"];
        int myCount = ([myList count] - 1) / 2 ;
        reportLine = [NSString stringWithFormat:@"%@ %@ [%d executions]\r\r",reportLine,inFolder, myCount];
        totalCount = totalCount + myCount;
        

    }
    NSString *initLogFile = @"";
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:expandedreportPath];
    if (fileHandle){
      //  [fileHandle seekToEndOfFile];
      //  [fileHandle writeData:[initLogFile dataUsingEncoding:NSUTF8StringEncoding]];
      //  [fileHandle closeFile];
    }
    else{
        [initLogFile writeToFile:expandedreportPath
                    atomically:NO
                      encoding:NSStringEncodingConversionAllowLossy
                         error:nil];
    }

    
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSString *myDate = [dateFormatter stringFromDate:[NSDate date]];
    NSString *dateLine = [NSString stringWithFormat:@"\r%@\r\r\r", myDate];

    NSString *reportTotalLine = [NSString stringWithFormat:@"\rTotal Executions: %d",totalCount];
    
    NSString *reportString = [NSString stringWithFormat:@"%@\n\
%@\n\
\n\
                              %@", dateLine, reportLine, reportTotalLine];
    NSFileHandle *fileUpdate = [NSFileHandle fileHandleForWritingAtPath:expandedreportPath];
    if (fileUpdate){

        
        [fileUpdate seekToEndOfFile];
        [fileUpdate writeData:[reportString dataUsingEncoding:NSUTF8StringEncoding]];

        [fileUpdate closeFile];
    }

}
- (void) HelpViewLoad {
    NSURL *helpFile = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]];
    [[self.HelpWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:helpFile]];
}

- (IBAction)HelpMenuHelp:(id)sender {
    [self HelpViewLoad];
    [_HelpWindow makeKeyAndOrderFront:self];
}
- (NSString*) validateCheck: (NSString*)theScript : (NSString*) inFolder : (NSString*) outFolder{

    NSArray *checkArray = @[theScript, inFolder, outFolder];

    int i, count = [checkArray count];
    for (i=0; i < count; i++) {
    NSString *checkPath = checkArray[i];
    NSString *expandedCheckPath = [checkPath stringByExpandingTildeInPath];

    
    BOOL fileHandle = [[NSFileManager defaultManager] fileExistsAtPath:expandedCheckPath];
    if (fileHandle){
       // NSLog(@"%@",checkPath);
    }
    else{
        NSString *myCheck = @"null";
        if (i==0){
             myCheck = @"Script";
        }
        if (i==1){
             myCheck = @"inFolder";
        }
        if (i==2){
             myCheck = @"outFolder";
        }
        NSString *alertString = [NSString stringWithFormat:@"Warning: Can't find %@\r%@", myCheck, checkPath];
        [_alertWindow orderFront:self];
        [_alertMessage setStringValue:alertString];

        NSImage *warningImage = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Warning" ofType:@"png"]];
        [_alertIcon setImage:warningImage];
        
        if ([validateError  isEqual: @"false"]){
            if ([emailError isEqual: @"true"]){
            NSDictionary* errorDict;
            NSAppleEventDescriptor* returnDescriptor = NULL;
            NSString *emailScript = [NSString stringWithFormat:@"\
                                     tell application \"Mail\"\n\
                                     set theMessage to make new outgoing message with properties {subject:\"Scriptik Error\", content:\"%@\", visible:false}\n\
                                     tell theMessage\n\
                                     make new to recipient with properties {address:\"%@\"}\n\
                                     send\n\
                                     end tell\n\
                                     end tell\n\
                                     tell application \"Mail\" to close windows",alertString, myEmailAddress];

            NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource: emailScript];

            returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
      
            validateError = @"true";
            NSLog(@"%@",myEmailAddress);
            }
        }
        return @"false";
    }
    }
    return @"true";
}

@end
