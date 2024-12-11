#import <PreferencePanes/PreferencePanes.h>

@interface teaBASE : NSPreferencePane<NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate> {
    NSArray *gitGudInstalledListing;
    NSArray *gitGudListing;
}

@property (weak) IBOutlet NSSwitch *sshSwitch;
@property (weak) IBOutlet NSSwitch *sshPassPhraseSwitch;
@property (weak) IBOutlet NSSwitch *gpgSignSwitch;

@property (weak) IBOutlet NSSwitch *xcodeCLTSwitch;
@property (weak) IBOutlet NSSwitch *homebrewSwitch;
@property (weak) IBOutlet NSSwitch *pkgxSwitch;
@property (weak) IBOutlet NSSwitch *dockerSwitch;

@property (weak) IBOutlet NSLevelIndicator *ratingIndicator;
@property (weak) IBOutlet NSTableView *gitExtensionsTable;
@property (weak) IBOutlet NSTextField *sshPassphraseTextField;
@property (weak) IBOutlet NSSwitch *sshPassphraseICloudIntegrationSwitch;
@property (weak) IBOutlet NSButton *sshApplyPassphraseButton;

@property (weak) IBOutlet NSImageView *greenCheckGPGBackup;
@property (weak) IBOutlet NSImageView *greenCheckGitHubIntegration;

@property (weak) IBOutlet NSTextField *gitVersion;
@property (weak) IBOutlet NSTextField *brewVersion;
@property (weak) IBOutlet NSTextField *pkgxVersion;
@property (weak) IBOutlet NSTextField *xcodeCLTVersion;
@property (weak) IBOutlet NSTextField *dockerVersion;

@property (weak) IBOutlet NSTextField *setupGPGWindowUsername;
@property (weak) IBOutlet NSTextField *setupGPGWindowEmail;

@property (weak) IBOutlet NSWindow *sshPassphraseWindow;
@property (weak) IBOutlet NSWindow *gpgPassphraseWindow;
@property (weak) IBOutlet NSWindow *brewInstallWindow;

@property (weak) IBOutlet NSProgressIndicator *brewInstallWindowSpinner;
@property (weak) IBOutlet NSButton *setupBrewShellEnvCheckbox;

@property (weak) IBOutlet NSUserDefaultsController *defaultsController;

@property (weak) IBOutlet NSComboButton *installGitButton;

@property (weak) IBOutlet NSWindow *gitGudWindow;
@property (weak) IBOutlet NSProgressIndicator *gitGudWindowSpinner;
@property (weak) IBOutlet NSTableView *gitGudTableView;
@property (weak) IBOutlet NSButton *gitGudInstallButton;
@property (weak) IBOutlet NSButton *gitGudUninstallButton;
@property (weak) IBOutlet NSButton *gitGudBVetButton;

@property (weak) IBOutlet NSTextView *brewManualInstallInstructions;

@property (weak) IBOutlet NSSwitch *dotfileSyncSwitch;
@property (weak) IBOutlet NSButton *dotfileSyncEditWhitelistButton;
@property (weak) IBOutlet NSButton *dotfileSyncViewRepoButton;

@property (weak) IBOutlet NSTextField *selfVersionLabel;

@end


@interface teaBASE (Helpers)
- (void)installSubexecutable:(NSString *)name;
@end

@interface teaBASE (git)
- (void)updateGitGudListing;
@end

@interface teaBASE (dotfileSync)
- (BOOL)dotfileSyncEnabled;
@end

@interface teaBASE (SelfUpdate)
- (void)checkForUpdates;
@end


BOOL run(NSString *cmd, NSArray *args, NSPipe *pipe);
BOOL file_contains(NSString *path, NSString *token);
BOOL sudo_run_cmd(char *cmd, char *arguments[], NSString *errorTitle);
NSString *output(NSString *cmd, NSArray *args);
NSString *which(NSString *cmd);
NSString *brewPath(void);
