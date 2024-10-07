#import "teaBASE.h"

@implementation teaBASE

- (void)mainViewDidLoad {
    for (NSTableColumn *col in self.gitExtensionsTable.tableColumns) {
        col.headerCell.attributedStringValue = [[NSAttributedString alloc] initWithString:col.title attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:10]}];
    }
}

- (void)willSelect {
    [self updateSSHStates];

    BOOL hasSignedCommits = [self gpgSignEnabled];
    
    [self.gpgSignSwitch setState:hasSignedCommits ? NSControlStateValueOn : NSControlStateValueOff];
    [self.homebrewSwitch setState:[self homebrewInstalled] ? NSControlStateValueOn : NSControlStateValueOff];
    [self.pkgxSwitch setState:[self pkgxInstalled] ? NSControlStateValueOn : NSControlStateValueOff];
        
    [self updateVersions];
    
    if ([self.defaultsController.defaults boolForKey:@"xyz.tea.BASE.integrated-GitHub"]) {
        self.greenCheckGitHubIntegration.hidden = NO;
    }
    if ([self.defaultsController.defaults boolForKey:@"xyz.tea.BASE.printed-GPG-emergency-kit"]) {
        self.greenCheckGPGBackup.hidden = NO;
    }
    
    [self calculateSecurityRating];
    
    [self updateGitGudListing];
}

- (void)calculateSecurityRating {
    BOOL hasSignedCommits = self.gpgSignSwitch.state == NSControlStateValueOn;
    BOOL hasSSHPassPhrase = self.sshPassPhraseSwitch.state == NSControlStateValueOn;
    BOOL hasSSH = self.sshSwitch.state == NSControlStateValueOn;
    BOOL hasGitHubIntegration = self.greenCheckGitHubIntegration.hidden == NO;
    BOOL hasGPGBackup = self.greenCheckGPGBackup.hidden == NO;
    
    float rating = hasSignedCommits + hasSSHPassPhrase + hasSSH + hasGitHubIntegration + hasGPGBackup;
    [self.ratingIndicator setIntValue:rating];
    
    if (self.ratingIndicator.intValue >= self.ratingIndicator.maxValue) {
        [self.ratingIndicator setFillColor:[NSColor systemGreenColor]];
    } else if (self.ratingIndicator.intValue <= 1) {
        [self.ratingIndicator setFillColor:[NSColor systemRedColor]];
    }
}

- (void)updateSSHStates {
    BOOL hasSSH = [self checkForSSH];
    BOOL hasSSHPassPhrase = hasSSH && [self checkForSSHPassPhrase]; // check both ∵ our pp-check is false-positive if no key file
    BOOL hasICloudIntegration = hasSSH && hasSSHPassPhrase && [self checkForSSHPassphraseICloudKeychainIntegration];
    
    [self.sshSwitch setState:hasSSH ? NSControlStateValueOn : NSControlStateValueOff];
    [self.sshPassPhraseSwitch setState:hasSSHPassPhrase ? NSControlStateValueOn : NSControlStateValueOff];
    [self.sshPassphraseICloudIntegrationSwitch setState:hasICloudIntegration ? NSControlStateValueOn : NSControlStateValueOff];
    
    self.sshPassPhraseSwitch.enabled = hasSSH;
    self.sshPassphraseICloudIntegrationSwitch.enabled = hasSSH;
}

- (BOOL)checkForSSH {
    NSURL *home = [NSFileManager.defaultManager homeDirectoryForCurrentUser];
    NSString *id_rsa = [home.path stringByAppendingPathComponent: @".ssh/id_rsa"];
    return [NSFileManager.defaultManager isReadableFileAtPath:id_rsa];
}

- (BOOL)checkForSSHPassPhrase {
    id path = [NSString stringWithFormat:@"%@/.ssh/id_rsa", NSFileManager.defaultManager.homeDirectoryForCurrentUser.path];
    
    // attempts to decrypt the key, if there’s a passphrase this will fail
    return run(@"/usr/bin/ssh-keygen", @[@"-y", @"-f", path, @"-P", @""], nil) == NO;
}

- (BOOL)checkForSSHPassphraseICloudKeychainIntegration {
    NSURL *home = [NSFileManager.defaultManager homeDirectoryForCurrentUser];
    id path = [home.path stringByAppendingPathComponent:@".ssh/config"];
    return file_contains(path, @"UseKeychain yes");
}

- (void)updateVersions {
    NSString *brew_out = output(@"/opt/homebrew/bin/brew", @[@"--version"]);
    NSString *pkgx_out = output(@"/usr/local/bin/pkgx", @[@"--version"]);
    
    BOOL has_clt = [NSFileManager.defaultManager isExecutableFileAtPath:@"/Library/Developer/CommandLineTools/usr/bin/git"];
    //TODO Xcode can be installed anywhere, instead check for the bundle ID with spotlight API or mdfind
    BOOL has_xcode = [NSFileManager.defaultManager isExecutableFileAtPath:@"/Applications/Xcode.app"];
    // emulate login shell to ensure PATH contains everything the user has configured
    // ∵ GUI apps do not have full user PATH set otherwise
    NSString *git_out = nil;
    if (has_clt || has_xcode) {
        // only check if clt or xcode otherwise this may trigger the XcodeCLT installation GUI flow
        git_out = output(@"/bin/sh", @[@"-l", @"-c", @"git --version"]);
    }
    
    brew_out = [[brew_out componentsSeparatedByString:@" "] lastObject];    // Homebrew 1.2.3
    pkgx_out = [[pkgx_out componentsSeparatedByString:@" "] lastObject];    // pkgx 1.2.3
    git_out = [[git_out componentsSeparatedByString:@" "] objectAtIndex:2]; // git version 1.2.3
    
    self.brewVersion.stringValue = brew_out ? [NSString stringWithFormat:@"v%@", brew_out] : @"";
    self.pkgxVersion.stringValue = pkgx_out ? [NSString stringWithFormat:@"v%@", pkgx_out] : @"";
    self.gitVersion.stringValue = git_out ? [NSString stringWithFormat:@"v%@", git_out] : @"";
    
    [self.installGitButton setHidden:git_out != nil];
}

- (BOOL)gpgSignEnabled {
    NSURL *home = [NSFileManager.defaultManager homeDirectoryForCurrentUser];
    NSString *path = [home.path stringByAppendingPathComponent:@".gitconfig"];
    return file_contains(path, @"gpgsign = true");
}

- (BOOL)homebrewInstalled {
    return [NSFileManager.defaultManager isReadableFileAtPath:@"/opt/homebrew/bin/brew"];
}

- (BOOL)pkgxInstalled {
    //TODO need to check more locations
    return [NSFileManager.defaultManager isReadableFileAtPath:@"/usr/local/bin/pkgx"];
}

- (IBAction)modalCancel:(NSButton *)sender {
    [NSApp endSheet:[sender window] returnCode:NSModalResponseCancel];
}

- (IBAction)modalOK:(NSButton *)sender {
    [NSApp endSheet:[sender window] returnCode:NSModalResponseOK];
}

- (IBAction)openGitHub:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://github.com/pkgxdev/teaBASE"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)onShareClicked:(id)sender {
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Unimplemented. Soz.";
    [alert runModal];
}

@end


@implementation teaBASE (SSH)

- (IBAction)createSSHPrivateKey:(NSSwitch *)sender {
    id path = [NSString stringWithFormat:@"%@/.ssh/id_rsa", NSFileManager.defaultManager.homeDirectoryForCurrentUser.path];
    
    if (sender.state == NSControlStateValueOn) {
        NSArray *arguments = @[@"-t", @"rsa", @"-b", @"4096", @"-f", path, @"-N", @""];
        
        if (run(@"/usr/bin/ssh-keygen", arguments, nil)) {
            [self calculateSecurityRating];
            [self updateSSHStates];
        } else {
            NSAlert *alert = [NSAlert new];
            alert.messageText = @"ssh-keygen failed";
            [alert runModal];
            [self.sshSwitch setState:NSControlStateValueOff];
        }
    } else {
        NSAlert *alert = [NSAlert new];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"Data Loss Warning";
        alert.informativeText = @"Deleting your SSH key pair cannot be undone by teaBASE.";
        
        NSButton *deleteButton = [alert addButtonWithTitle:@"Delete Keys"];
        deleteButton.hasDestructiveAction = YES;
        
        [alert addButtonWithTitle:@"Cancel"];
        
        [alert beginSheetModalForWindow:sender.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                id err;
                if (![NSFileManager.defaultManager removeItemAtPath:path error:&err]) {
                    [[NSAlert alertWithError:err] runModal];
                    return;
                }
                id pubpath = [NSString stringWithFormat:@"%@.pub", path];
                if (![NSFileManager.defaultManager removeItemAtPath:pubpath error:&err]) {
                    [[NSAlert alertWithError:err] runModal];
                }
            }
            [self updateSSHStates];
        }];
    }
}

- (IBAction)createSSHPassPhrase:(NSSwitch *)sender {
    if (sender.state == NSControlStateValueOn) {
        [NSApp.mainWindow beginSheet:self.sshPassphraseWindow completionHandler:^(NSModalResponse returnCode) {
            
            //TODO should not remove passphrase window until complete in case of failure
            
            if (returnCode == NSModalResponseCancel) {
                [self.sshPassPhraseSwitch setState:NSControlStateValueOff];
                return;
            }
            
            id path = [NSString stringWithFormat:@"%@/.ssh/id_rsa", NSFileManager.defaultManager.homeDirectoryForCurrentUser.path];
            
            id passphrase = self.sshPassphraseTextField.stringValue;
            
            NSPipe *pipe = [NSPipe pipe];
            
            if (!run(@"/usr/bin/ssh-keygen", @[@"-p", @"-N", passphrase, @"-f", path], pipe)) {
                id stderr = [NSString stringWithUTF8String:[pipe.fileHandleForReading readDataToEndOfFile].bytes];
                
                NSAlert *alert = [NSAlert new];
                alert.messageText = @"ssh-keygen failed";
                alert.informativeText = stderr;
                [alert runModal];
                return;
            }
            
            [self.sshPassphraseTextField setStringValue:@""]; // get it out of memory ASAP
            [self.sshPassPhraseSwitch setEnabled:NO];
            [self updateSSHStates];
            [self calculateSecurityRating];
        }];
    } else {
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Unimplemented. Soz.";
        [alert runModal];
        
        [sender setState:NSControlStateValueOn];
    }
}

- (IBAction)createSSHPassPhraseStep2:(id)sender {
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Your passphrase won’t be stored";
    alert.informativeText = @"Please print the Emergency Kit and save it securely, or confirm you have another way to restore your credentials.\n\nDon’t worry—losing your SSH credentials is (usually—but tediously) recoverable.";
    [alert addButtonWithTitle:@"Print Kit"];
    [alert addButtonWithTitle:@"Proceed Without Kit"];
    [alert addButtonWithTitle:@"Cancel"];

    [alert beginSheetModalForWindow:self.sshPassphraseWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [self printSSHEmergencyKit:self.sshPassphraseTextField.stringValue sender:sender];
        } else if (returnCode == NSAlertSecondButtonReturn) {
            [NSApp endSheet:self.sshPassphraseWindow returnCode:NSModalResponseOK];
        }
    }];
}

- (void)printSSHEmergencyKit:(NSString *)passphrase sender:(id)sender {
    NSString *pubkey_path = [NSHomeDirectory() stringByAppendingPathComponent:@".ssh/id_rsa.pub"];
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:pubkey_path encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        [[NSAlert alertWithError:error] runModal];
        return;
    }

    content = [@"Recreate the following at: `~/.ssh/id_rsa.pub`:\n\n" stringByAppendingString:content];
    
    NSString *privkey_path = [NSHomeDirectory() stringByAppendingPathComponent:@".ssh/id_rsa"];
    NSString *privkey_content = [NSString stringWithContentsOfFile:privkey_path encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        [[NSAlert alertWithError:error] runModal];
        return;
    }
    
    content = [content stringByAppendingString:@"\n\n"];
    content = [content stringByAppendingString:@"Recreate the following at: `~/.ssh/id_rsa`:\n\n"];
    content = [content stringByAppendingString:privkey_content];
    content = [content stringByAppendingString:@"\n\n"];
    
    content = [content stringByAppendingString:@"Passphrase:\n\n"];
    content = [content stringByAppendingString:passphrase];
        
    // Create an NSTextView and set the document content
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 612, 612)]; // Typical page size
    [textView setString:content];
    
    // Configure the print operation for the text view
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:textView];
    [printOperation setShowsPrintPanel:YES];
    [printOperation setShowsProgressPanel:YES];
    [printOperation setJobTitle:@"SSH_Emergency_Kit.pdf"];

    // Run the print operation (this will display the print dialog)
    [printOperation runOperationModalForWindow:[sender window] delegate:self didRunSelector:@selector(sshPrintOperationDidRun:success:) contextInfo:nil];
}

- (void)sshPrintOperationDidRun:(NSPrintOperation *)op success:(BOOL)success {
    if (success) {
        [NSApp endSheet:self.sshPassphraseWindow returnCode:NSModalResponseOK];
    }
}

- (IBAction)configureSSHPassphraseICloudKeychainIntegration:(NSSwitch *)sender {
    NSURL *home = [NSFileManager.defaultManager homeDirectoryForCurrentUser];
    NSString *ssh_config = [home.path stringByAppendingPathComponent: @".ssh/config"];
    NSString *content = @"Host *\n  UseKeychain yes";

    if (sender.state == NSControlStateValueOn) {
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:ssh_config];
        if (!exists) {
            [[NSFileManager defaultManager] createFileAtPath:ssh_config contents:nil attributes:nil];
        }
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:ssh_config];
        [fileHandle seekToEndOfFile];
        if (exists) {
            [fileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [fileHandle writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else {
        //TODO this can so easily fail to achieve the desired result
        
        id error;
        NSString *fileContent = [NSString stringWithContentsOfFile:ssh_config encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            [[NSAlert alertWithError:error] runModal];
            [sender setState:NSControlStateValueOn];
        } else {
            NSString *txt = [fileContent stringByReplacingOccurrencesOfString:content withString:@""];
            txt = [txt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            txt = [txt stringByAppendingString:@"\n"];  // we end files with newlines in this house
            [txt writeToFile:ssh_config atomically:YES encoding:NSUTF8StringEncoding error:&error];
        }
    }
}

@end

@implementation teaBASE (NSTextFieldDelegate)

- (void)controlTextDidChange:(NSNotification *)obj {
    self.sshApplyPassphraseButton.enabled = self.sshPassphraseTextField.stringValue.length > 0;
}

@end


@implementation teaBASE (GPG)

- (IBAction)signCommits:(NSSwitch *)sender {
    NSString *git = which(@"git");
        
    if (sender.state == NSControlStateValueOn) {
        //FIXME this isn’t sufficient to verify all is good
        if ([NSFileManager.defaultManager isReadableFileAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@".bpb_keys.toml"]]) {
            run(git, @[@"config", @"--global", @"commit.gpgsign", @"true"], nil);
            run(git, @[@"config", @"--global", @"gpg.program", @"bpb"], nil);
            [self calculateSecurityRating];
            return;
        }
        
        [NSApp.mainWindow beginSheet:self.gpgPassphraseWindow completionHandler:^(NSModalResponse returnCode) {
            if (returnCode != NSModalResponseOK) {
                [self.gpgSignSwitch setState:NSControlStateValueOff];
            } else {
                id username = self.setupGPGWindowUsername.stringValue;
                id email = self.setupGPGWindowEmail.stringValue;
                [self installBPB:username email:email];
                
                //TODO need to have a git installed first
                run(git, @[@"config", @"--global", @"commit.gpgsign", @"true"], nil);
                run(git, @[@"config", @"--global", @"gpg.program", @"bpb"], nil);
                [self calculateSecurityRating];
            }
        }];
    } else {
        run(git, @[@"config", @"--global", @"commit.gpgsign", @"false"], nil);
        [self calculateSecurityRating];
    }
}

- (void)installBPB:(id)username email:(id)email {
    [self installSubexecutable:@"bpb"];
    
    if ([NSFileManager.defaultManager isReadableFileAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@".bpb_keys.toml"]]) {
        //FIXME not really a thorough check
        return;
    }
 
    id initstr = [NSString stringWithFormat:@"%@ <%@>", username, email];
    run(@"/usr/local/bin/bpb", @[@"init", initstr], nil);
}

- (IBAction)printGPGEmergencyKit:(id)sender {
    NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:@".bpb_keys.toml"];
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    content = [@"Recreate the following at: `~/.bpb_keys.toml`:\n\n" stringByAppendingString:content];
    
    if (error) {
        [[NSAlert alertWithError:error] runModal];
        return;
    }
        
    // Create an NSTextView and set the document content
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 612, 612)]; // Typical page size
    [textView setString:content];
    
    // Configure the print operation for the text view
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:textView];
    [printOperation setShowsPrintPanel:YES];
    [printOperation setShowsProgressPanel:YES];
    [printOperation setJobTitle:@"BPB_Emergency_Kit.pdf"];

    // Run the print operation (this will display the print dialog)
    [printOperation runOperationModalForWindow:[sender window] delegate:self didRunSelector:@selector(didPrintGPGEmergencyKit:success:) contextInfo:nil];
}

- (void)didPrintGPGEmergencyKit:(NSPrintOperation *)op success:(BOOL)success {
    if (success) {
        self.greenCheckGPGBackup.hidden = NO;
        [self.defaultsController.defaults setValue:@YES forKey:@"xyz.tea.BASE.printed-GPG-emergency-kit"];
    }
}

@end


@implementation teaBASE (Integration)

//TODO use `gh` or its just too fiddly
- (IBAction)integrateWithGitHub:(id)sender {
    NSString *pkgx_PATH = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents/Executables"];
    NSString *script_path = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents/Scripts/github-integration.sh"];
    
    NSString *cmd = [NSString stringWithFormat:@"PATH=%@:$PATH %@", pkgx_PATH, script_path];
    NSString *script = [NSString stringWithFormat:
                        @"tell application \"Terminal\"\n"
                        "    do script \"%@\"\n"
                        "    activate\n"
                        "end tell", cmd];

    id err;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
    [appleScript executeAndReturnError:&err];
    
    if (err) {
        [[NSAlert alertWithError:err] runModal];
    } else {
        self.greenCheckGitHubIntegration.hidden = NO;
        [self.defaultsController.defaults setValue:@YES forKey:@"xyz.tea.BASE.integrated-GitHub"];
    }
}

@end


@implementation teaBASE (PMs)

- (IBAction)installBrew:(NSSwitch *)sender {
    if (sender.state == NSControlStateValueOn) {
        [NSApp.mainWindow beginSheet:self.brewInstallWindow completionHandler:^(NSModalResponse returnCode) {
            if (returnCode != NSModalResponseOK) {
                [self.homebrewSwitch setState:NSControlStateValueOff];
            } else {
                [self updateVersions];
            }
            [self.brewInstallWindowSpinner stopAnimation:sender];
        }];
    } else {
        // Get the contents of the directory
        NSError *error = nil;
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/opt/homebrew" error:&error];
        
        if (error) {
            [[NSAlert alertWithError:error] runModal];
            return;
        }
        
        // Iterate over each item in the directory
        for (NSString *item in contents) {
            NSString *itemPath = [@"/opt/homebrew" stringByAppendingPathComponent:item];
            
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:itemPath error:&error];
            if (!success) {
                [[NSAlert alertWithError:error] runModal];
                return;
            }
        }
        
        [self updateVersions];
    }
}

static BOOL installer(NSURL *url) {
    NSURL *newurl = [[url URLByDeletingPathExtension] URLByAppendingPathExtension:@".pkg"];
    [NSFileManager.defaultManager moveItemAtURL:url toURL:newurl error:nil];
            
    char *arguments[] = {"-pkg", (char*)newurl.fileSystemRepresentation, "-target", "/", NULL};
    
    return sudo_run_cmd("/usr/sbin/installer", arguments, @"Homebrew install failed");
}

- (IBAction)installBrewStep2:(NSButton *)sender {
    [sender setEnabled:NO];
    [self.brewInstallWindowSpinner startAnimation:sender];
    
    //TODO use API to determine latest release?
    id urlstr = @"https://github.com/Homebrew/brew/releases/download/4.4.3/Homebrew-4.4.3.pkg";
    NSURL *url = [NSURL URLWithString:urlstr];

    [[[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSAlert alertWithError:error] runModal];
                [NSApp endSheet:self.brewInstallWindow returnCode:NSModalResponseAbort];
                [sender setEnabled:YES];
            });
        } else if (installer(location)) {
                // ^^ runs the installer on the NSURLSession queue as the download
                // is deleted when it exits. afaict this is fine.
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (self.setupBrewShellEnvCheckbox.state == NSControlStateValueOn) {
                    NSString *zprofilePath = [NSHomeDirectory() stringByAppendingPathComponent:@".zprofile"];
                    NSString *cmdline = @"eval \"$(/opt/homebrew/bin/brew shellenv)\"";
                    
                    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:zprofilePath];
                    
                    // Check if the file exists, if not create it
                    if (!exists) {
                        [[NSFileManager defaultManager] createFileAtPath:zprofilePath contents:nil attributes:nil];
                    }
                    else if (!file_contains(zprofilePath, cmdline)) {
                        // Open the file for appending
                        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:zprofilePath];
                        if (fileHandle) {
                            [fileHandle seekToEndOfFile];
                            if (exists) {
                                [fileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
                            }
                            [fileHandle writeData:[cmdline dataUsingEncoding:NSUTF8StringEncoding]];
                            [fileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
                            [fileHandle closeFile];
                        } else {
                            //TODO
                        }
                    }
                }

                [NSApp endSheet:self.brewInstallWindow returnCode:NSModalResponseOK];
                [sender setEnabled:YES];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert new];
                alert.messageText = @"Installation Error";
                alert.informativeText = @"Unknown error occurred. Please install Homebrew manually.";
                [alert runModal];
                [NSApp endSheet:self.brewInstallWindow returnCode:NSModalResponseAbort];
                [sender setEnabled:YES];
            });
        }
    }] resume];
}

- (void)installPkgx:(NSSwitch *)sender {
    if (sender.state == NSControlStateValueOn) {
        [self installSubexecutable:@"pkgx"];
        [self updateVersions];
    } else {
        char *args[] = {"/usr/local/bin/pkgx", NULL};
        sudo_run_cmd("/bin/rm", args, @"Couldn’t delete /usr/local/bin/pkgx");
    }
}

- (IBAction)openPkgxHome:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://pkgx.sh"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)openHomebrewHome:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://brew.sh"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)gitAddOnsHelpButton:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://github.com/pkgxdev/git-gud"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end



@implementation teaBASE (git)

- (void)installGit:(NSComboButton *)sender {
    if (sender.selectedTag == 1) {
        run(@"/usr/bin/xcode-select", @[@"--install"], nil);
    } else {
        run(@"/opt/homebrew/bin/brew", @[@"install", @"git"], nil);
    }
}

- (void)updateGitGudListing {
    NSString *pkgx = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents/Executables/pkgx"];
    
    //FIXME deno will cache this permanantly, we need to version it or pkg this properly
    id url = @"https://raw.githubusercontent.com/pkgxdev/git-gud/refs/heads/main/src/app.ts";

    NSString *json = output(pkgx, @[
        @"deno~2.0", @"run", @"--unstable-kv", @"-A", url, @"lsij"
    ]);
    
    NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

    if (error) {
        [[NSAlert alertWithError:error] runModal];
    } else {
        gitGudInstalledListing = jsonObject;
        [self.gitExtensionsTable reloadData];
    }
}

- (IBAction)manageGitGud:(id)sender {
    if (!gitGudListing) {
        [self reloadGitGudListing:sender];
    }
    
    [NSApp.mainWindow beginSheet:self.gitGudWindow completionHandler:^(NSModalResponse returnCode) {
        
    }];
}

- (void)reloadGitGudListing:(id)sender{
    //TODO need to update this sometimes
    
    [self.gitGudWindowSpinner startAnimation:sender];
    
    NSString *pkgx = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents/Executables/pkgx"];
    id url = @"https://raw.githubusercontent.com/pkgxdev/git-gud/refs/heads/main/src/app.ts";
    
    NSString *json = output(pkgx, @[
        @"deno~2.0", @"run", @"--unstable-kv", @"-A", url, @"lsj"
    ]);
    
    NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error) {
        [[NSAlert alertWithError:error] runModal];
        return;
    }
    
    gitGudListing = jsonObject;
    
    [self.gitGudTableView reloadData];
    [self updateGitGudSelection];
    
    [self.gitGudWindowSpinner stopAnimation:sender];
}

- (IBAction)vetGitGudPackage:(id)sender {
    NSInteger row = self.gitGudTableView.selectedRow;
    if (row < 0 || row >= gitGudListing.count) return;
    NSString *name = [gitGudListing[row] objectForKey:@"name"];
    if (!name) return;
    
    NSString *pkgx = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents/Executables/pkgx"];
    id url = @"https://raw.githubusercontent.com/pkgxdev/git-gud/refs/heads/main/src/app.ts";
    
    run(pkgx, @[
        @"deno~2.0", @"run", @"--unstable-kv", @"-A", url, @"vet", name
    ], nil);
}

- (IBAction)installGitGudPackage:(id)sender {
    [self.gitGudWindowSpinner startAnimation:sender];
    
    NSInteger row = self.gitGudTableView.selectedRow;
    if (row < 0 || row >= gitGudListing.count) return;
    NSString *name = [gitGudListing[row] objectForKey:@"name"];
    if (!name) return;
    
    NSString *pkgx = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents/Executables/pkgx"];
    id url = @"https://raw.githubusercontent.com/pkgxdev/git-gud/refs/heads/main/src/app.ts";
    
    run(pkgx, @[
        @"deno~2.0", @"run", @"--unstable-kv", @"-A", url, @"install", name
    ], nil);
    
    [self reloadGitGudListing:sender];
}

- (IBAction)uninstallGitGudPackage:(id)sender {
    [self.gitGudWindowSpinner startAnimation:sender];
    
    NSInteger row = self.gitGudTableView.selectedRow;
    if (row < 0 || row >= gitGudListing.count) return;
    NSString *name = [gitGudListing[row] objectForKey:@"name"];
    if (!name) return;
    
    NSString *pkgx = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents/Executables/pkgx"];
    id url = @"https://raw.githubusercontent.com/pkgxdev/git-gud/refs/heads/main/src/app.ts";
    
    run(pkgx, @[
        @"deno~2.0", @"run", @"--unstable-kv", @"-A", url, @"uninstall", name
    ], nil);
    
    [self reloadGitGudListing:sender];
}

- (void)updateGitGudSelection {
    NSInteger row = [self.gitGudTableView selectedRow];
    if (row < 0 || row >= gitGudListing.count) {
        [self.gitGudInstallButton setEnabled:NO];
        [self.gitGudUninstallButton setEnabled:NO];
        [self.gitGudBVetButton setEnabled:NO];
    } else {
        BOOL installed = [gitGudListing[row] boolForKey:@"installed"];
        [self.gitGudInstallButton setEnabled:!installed];
        [self.gitGudUninstallButton setEnabled:installed];
        [self.gitGudBVetButton setEnabled:YES];
    }
}

@end



@implementation teaBASE (NSTableViewDataSource)

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.gitExtensionsTable) {
        return gitGudInstalledListing.count;
    } else {
        return gitGudListing.count;
    }
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.gitExtensionsTable) {
        if ([tableColumn.identifier isEqualToString:@"name"]) {
            return [gitGudInstalledListing[row] objectForKey:@"name"];
        } else if ([tableColumn.identifier isEqualToString:@"type"]) {
            return [gitGudInstalledListing[row] objectForKey:@"description"];
        }
    } else {
        if ([tableColumn.identifier isEqualToString:@"name"]) {
            return [gitGudListing[row] objectForKey:@"name"];
        } else if ([tableColumn.identifier isEqualToString:@"description"]) {
            return [gitGudListing[row] objectForKey:@"description"];
        } else if ([tableColumn.identifier isEqualToString:@"installed"]) {
            return [[gitGudListing[row] objectForKey:@"installed"] boolValue] ? @"✓" : @"";
        }
    }
    return @"";
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (notification.object == self.gitGudTableView) {
        [self updateGitGudSelection];
    }
}

@end


@implementation teaBASE (Helpers)

- (void)installSubexecutable:(NSString *)name {
    NSString *src = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"Contents/Executables/%@", name]];
    NSString *dst = [NSString stringWithFormat:@"/usr/local/bin/%@", name];
            
    char *arguments[] = {(char*)src.fileSystemRepresentation, (char*)dst.fileSystemRepresentation, NULL};

    //TODO needs to check we’re on the same filesystem before doing a hardlink
    sudo_run_cmd("/bin/ln", arguments, [NSString stringWithFormat:@"`%@` install failed", name]);
}

@end
