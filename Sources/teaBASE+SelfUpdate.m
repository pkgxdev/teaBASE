#import "teaBASE.h"

@implementation teaBASE (SelfUpdate)

- (void)checkForUpdates {
    id current_version = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    current_version = [@"v" stringByAppendingString:current_version ?: @"0.0.0"];
    
    id url = @"https://api.github.com/repos/teaxyz/teaBASE/releases/latest";
    url = [NSURL URLWithString:url];

    NSMutableURLRequest *rq = [NSMutableURLRequest requestWithURL:url];
    [rq setValue:@"application/vnd.github+json" forHTTPHeaderField:@"Accept"];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:rq completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) return NSLog(@"teaBASE: fetch error: %@", error.localizedDescription);
        if (!data) return NSLog(@"teaBASE: no data from: %@", url);
        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) return NSLog(@"Error parsing JSON: %@", jsonError.localizedDescription);
        
        NSString *latest_version = json[@"tag_name"];
        
        if ([latest_version isEqualToString:current_version]) return;
        
        id fmt = [NSString stringWithFormat:@"-%@.dmg", [latest_version substringFromIndex:1]];
        for (NSDictionary *asset in json[@"assets"]) {
            if ([asset[@"name"] hasSuffix:fmt]) {
                return dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    download(asset[@"browser_download_url"], self);
                });
            }
        }
    }];
    [task resume];
}

void download(id url, teaBASE *self) {
#if DEBUG
    NSLog(@"teaBASE: would update to: %@", url);
#else
    id bundle_path = [[NSBundle bundleForClass:[self class]] bundlePath];
    id script_path = [bundle_path stringByAppendingPathComponent:@"Contents/Scripts/self-update.sh"];

    run(script_path, @[url, bundle_path], nil);
#endif
}

@end
