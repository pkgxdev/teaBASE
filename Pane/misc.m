@import Foundation;
@import AppKit;

BOOL run(NSString *cmd, NSArray *args, NSPipe *pipe) {
    NSTask *task = [NSTask new];
    [task setLaunchPath:cmd];
    [task setArguments:args];
    // need to add other PATHs to PATH since GUI apps don’t operate with the user’s shell rc added
    [task setEnvironment:@{
        @"PATH": @"/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
        @"HOME": NSHomeDirectory()
    }];
    if (pipe) [task setStandardError:pipe];
    id error;
    [task launchAndReturnError:&error]; // configures task to not throw and thus potentially break us
    if (!error) {
        [task waitUntilExit];
        return task.terminationStatus == 0;
    } else {
        return -1;
    }
}

NSString *which(NSString *cmd) {
    NSArray *paths = @[@"/opt/homebrew/bin", @"/usr/local/bin", @"/usr/bin", @"/bin", @"/usr/sbin", @"/sbin"];
    
    for (NSString *dir in paths) {
        NSString *path = [dir stringByAppendingPathComponent:cmd];
        if ([[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
            return path;
        }
    }
    
    return cmd; //ohwell
}

NSString *output(NSString *cmd, NSArray *args) {
    NSTask *task = [NSTask new];
    [task setLaunchPath:cmd];
    [task setArguments:args];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    id error;
    [task launchAndReturnError:&error]; // configures task to not throw and thus potentially break us
    if (error) return nil;
    [task waitUntilExit];
    if (task.terminationStatus == 0) {
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

BOOL file_contains(NSString *path, NSString *token) {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    
    if (fileHandle == nil) {
        return NO; // TODO error condition
    }
    
    // Read the first 1024 bytes (or less if the file is shorter)
    NSData *fileData = [fileHandle readDataOfLength:1024];
    [fileHandle closeFile];
    
    if (fileData == nil || [fileData length] == 0) {
        return NO; // TODO error condition
    }
    
    // Convert the data to a string
    NSString *fileContents = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    
    if (fileContents == nil) {
        return NO; // TODO error condition
    }
    
    // FIXME whitespace can vary
    NSRange range = [fileContents rangeOfString:token];
    
    return (range.location != NSNotFound);
}

BOOL sudo_run_cmd(char *cmd, char *arguments[], NSString *errorTitle) {
    
    #define DIE() { dispatch_async(dispatch_get_main_queue(), ^{ \
            NSAlert *alert = [NSAlert new]; \
            alert.messageText = errorTitle; \
            alert.informativeText = @"dunno why"; \
            [alert runModal]; \
            AuthorizationFree(authorization, kAuthorizationFlagDefaults); \
    }); return NO; }

    AuthorizationRef authorization;
    OSStatus status = AuthorizationCreate(NULL, NULL, kAuthorizationFlagDefaults, &authorization);
    if (status != errAuthorizationSuccess) DIE();

    AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &items};
    status = AuthorizationCopyRights(authorization, &rights, NULL, kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights | kAuthorizationFlagPreAuthorize, NULL);

    if (status != errAuthorizationSuccess) DIE();
    
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    status = AuthorizationExecuteWithPrivileges(authorization, cmd, kAuthorizationFlagDefaults, arguments, NULL);
  #pragma clang diagnostic pop
    
    if (status != errAuthorizationSuccess) DIE();
    
    int wait_status;
    pid_t pid = wait(&wait_status);
    if (pid == -1 || !WIFEXITED(wait_status) || WEXITSTATUS(wait_status) != 0) {
        DIE();
    }

    AuthorizationFree(authorization, kAuthorizationFlagDefaults);
    
    return YES;
    
    #undef DIE
}

@interface VerticallyAlignedTextFieldCell: NSTextFieldCell
@end

@implementation VerticallyAlignedTextFieldCell

- (NSRect)titleRectForBounds:(NSRect)theRect {
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSSize titleSize = [[self attributedStringValue] size];
    titleFrame.origin.y = theRect.origin.y - .5 + (theRect.size.height - titleSize.height) / 2.0;
    return titleFrame;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawInRect:titleRect];
}

@end
