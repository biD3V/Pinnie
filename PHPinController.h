//
//  PHPinController.h
//  
//
//  Created by Sawyer Jester on 6/28/20.
//

@interface PHPinController : NSObject

@property (nonatomic) NSMutableArray *pinnedMessages;

+(instancetype)sharedInstance;
-(NSMutableArray *)pinnedMessages;
-(void)conversation:(CKConversation *)conversation setPinned:(BOOL)pinned;
-(BOOL)conversationIsPinned:(CKConversation *)conversation;

@end
