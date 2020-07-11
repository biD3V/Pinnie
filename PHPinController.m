//
//  PHPinController.m
//  
//
//  Created by Sawyer Jester on 6/28/20.
//

#import "PHPinController.h"

@implementation PHPinController

@synthesize pinnedMessages;

+ (instancetype)sharedInstance {
    static PHPinController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PHPinController alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

-(NSMutableArray *)pinnedMessages {
    if (!pinnedMessages) {
        pinnedMessages = [NSMutableArray new];
    }
    return pinnedMessages;
}

- (BOOL)conversationIsPinned:(CKConversation *)conversation {
    if ([pinnedMessagesIDs containsObject:[conversation uniqueIdentifier]] && ![pinnedMessages containsObject:conversation]) {
        [pinnedMessages addObject:conversation];
    }
    return [pinnedMessagesIDs containsObject:[conversation uniqueIdentifier]];
}

- (void)conversation:(CKConversation *)conversation setPinned:(BOOL)pinned {
    userDefaults = [NSUserDefaults standardUserDefaults];
    if (pinned) {
        [pinnedMessages addObject:conversation];
        [pinnedMessagesIDs addObject:[conversation uniqueIdentifier]];
    } else {
        [pinnedMessages removeObject:conversation];
        [pinnedMessagesIDs removeObject:[conversation uniqueIdentifier]];
    }
    persistDefaults();
    NSLog(@"[Pinnie] %@", pinnedMessagesIDs);
    NSLog(@"[Pinnie] %@", [userDefaults objectForKey:pinnedMessagesIDsKey]);
}

@end
