#import "teaBASE.h"

@implementation teaBASE (CleanInstall)

- (IBAction)generateCleanInstallPack:(id)sender {
    NSString *script_path = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents/Scripts/make-clean-install-pack.command"];

    run(@"/usr/bin/open", @[script_path], nil);    
}

- (IBAction)openCleanInstallGuide:(id)sender {
    
}

@end
