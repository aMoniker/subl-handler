#import "App.h"

#import "NSURL+L0URLParsing.h"
#import "RegexKitLite.h"

@implementation App

NSString *defaultPath = @"/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl";

-(void)awakeFromNib {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    path = [d objectForKey:@"path"];

    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

-(void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    if (nil == path) path = defaultPath;

    NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];

    if (url && [[url host] isEqualToString:@"open"]) {
        NSDictionary *params = [url dictionaryByDecodingQueryString];
        NSMutableArray *all_files = [NSMutableArray array];

        NSString *url_string = [params objectForKey:@"url"];
        NSString *files_string = [url_string stringByReplacingOccurrencesOfRegex:@"^file://" withString:@""];
        NSString *root_dir = [files_string stringByMatching:@"^.+?//"];
        
        if (!root_dir) {
            root_dir = @"";
            [all_files addObject:files_string];
        } else {
            files_string = [files_string stringByReplacingOccurrencesOfRegex:@"^.+?//" withString:@""];
            files_string = [@"/" stringByAppendingString:files_string];
            root_dir = [root_dir stringByReplacingOccurrencesOfRegex:@"//$" withString:@""];
            
            NSArray *all_files_immutable = [files_string componentsSeparatedByRegex:@" "];
            all_files = [all_files_immutable mutableCopy];
        }
        
        root_dir = [@"file://" stringByAppendingString:root_dir];
        
        NSMutableArray *full_path_files = [NSMutableArray array];
        
        [all_files enumerateObjectsUsingBlock:^(id file, NSUInteger idx, BOOL *stop) {
            NSURL *file_url = [NSURL URLWithString:[root_dir stringByAppendingString:file]];
            
            if (file_url && [[file_url scheme] isEqualToString:@"file"]) {
                NSString *file = [file_url path];
                NSString *line = [params objectForKey:@"line"];
                NSString *column = [params objectForKey:@"column"];
                
                file_url = [NSString stringWithFormat:@"%@:%lu:%lu", file, [line integerValue], [column integerValue]];
                
                [full_path_files addObject:file_url];
            }
        }];
            
        if ([full_path_files count] > 0) {
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:path];
            [task setArguments:full_path_files];
            [task launch];
            [task release];
        }
    }

    if (![prefPanel isVisible]) {
        [NSApp terminate:self];
    }
}

-(IBAction)showPrefPanel:(id)sender {
    if (path) {
        [textField setStringValue:path];
    } else {
        [textField setStringValue:defaultPath];
    }
    [prefPanel makeKeyAndOrderFront:nil];
}

-(IBAction)applyChange:(id)sender {
    path = [textField stringValue];

    if (path) {
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        [d setObject:path forKey:@"path"];
    }

    [prefPanel orderOut:nil];
}

@end
