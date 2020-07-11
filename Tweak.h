static NSUserDefaults *userDefaults;
static NSMutableArray *pinnedMessagesIDs;
static NSString *pinnedMessagesIDsKey = @"com.bid3v.pinnie.pinnedmessagesids";
static int layout;
static int avatarSize;
static BOOL pinsEnabled;
static BOOL dropGlowEnabled;
static float dropGlowAlpha;

static void restoreDefaults() {
    if (!userDefaults) return;
    pinnedMessagesIDs = [userDefaults arrayForKey:pinnedMessagesIDsKey] ? [[userDefaults arrayForKey:pinnedMessagesIDsKey] mutableCopy] : [NSMutableArray new];
}

static void persistDefaults() {
    if (!userDefaults) return;
    [userDefaults setObject:pinnedMessagesIDs forKey:pinnedMessagesIDsKey];
}

#define PNEPreferencePath @"/User/Library/Preferences/com.bid3v.pinnieprefs.plist"

#define PNEObserver(funcToCall, listener) CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)funcToCall, CFSTR(listener), NULL, CFNotificationSuspensionBehaviorCoalesce);

#define PNESyncPrefs()\
NSDictionary *PNESettings = [NSDictionary dictionaryWithContentsOfFile:PNEPreferencePath];

#define STRINGIFY_(x) #x
#define STRINGIFY(x) STRINGIFY_(x)

#define PNEBoolPref(var, key, default) do {\
    NSNumber *key = PNESettings[@STRINGIFY(key)];\
    var = key ? [key boolValue] : default;\
} while (0)

#define PNEIntPref(var, key, default) do {\
    NSNumber *key = PNESettings[@STRINGIFY(key)];\
    var = key ? [key intValue] : default;\
} while (0)

#define PNEFloatPref(var, key, default) do {\
    NSNumber *key = PNESettings[@STRINGIFY(key)];\
    var = key ? [key floatValue] : default;\
} while (0)



static void loadPrefs() {
    PNESyncPrefs();
    
    
    NSLog(@"[PinniePrefs] %@", PNESettings);
    PNEIntPref(layout, PinLayout, 0);
    PNEIntPref(avatarSize, AvatarSize, 1);
    PNEBoolPref(pinsEnabled, PinsEnabled, YES);
    PNEBoolPref(dropGlowEnabled, DrowGlowEnabled, YES);
    PNEFloatPref(dropGlowAlpha, GlowAlpha, 0.75);
}

static void reloadTable () {
    [NSNotificationCenter.defaultCenter postNotificationName:@"ReloadTable"
                                                      object:nil
                                                    userInfo:nil];
}

@interface CNContact : NSObject
@end

@interface CKEntity : NSObject

@property (nonatomic,retain) CNContact * cnContact;

@end

@interface CNAvatarView : UIView

@property (nonatomic,retain) CNContact * contact;
@property (nonatomic,retain) NSArray * contacts;
@property (nonatomic,copy) UIImageView * imageView;
@property (nonatomic,readonly) UIImage * contentImage;

-(id)initWithContact:(id)arg1;

@end

@interface CKAvatarView : CNAvatarView
@end

@interface CKConversation : NSObject

@property (nonatomic,readonly) NSString * name;
@property (nonatomic,readonly) CKEntity * recipient;
@property (nonatomic,readonly) NSArray * recipients;
@property (nonatomic,readonly) NSUInteger recipientCount;
@property (nonatomic,readonly) NSUInteger unreadCount;
@property (nonatomic,readonly) BOOL hasDisplayName;
@property (assign,nonatomic) NSString * displayName;
@property (assign,getter=isPinned,nonatomic) BOOL pinned;

-(id)uniqueIdentifier;
-(id)orderedContactsForAvatarView;
-(BOOL)isPinned;
-(void)setPinned:(BOOL)arg1;
-(BOOL)hasDisplayName;
-(void)loadAllMessages;
-(void)setNeedsReload;
-(void)setLimitToLoad:(unsigned int)arg1;
-(void)loadMoreMessages;

@end

@interface CKConversationListCell : UITableViewCell

@property (nonatomic,retain) CKConversation * conversation;
@property (nonatomic,readonly) CKAvatarView * avatarView;

@end

@interface CKConversationListStandardCell : CKConversationListCell
@end

@interface CKViewController : UIViewController

@end

@interface CKScrollViewController : CKViewController

@end

@interface CKCoreChatController : CKScrollViewController

@property (nonatomic,retain) CKConversation * conversation;

-(id)initWithConversation:(CKConversation *)conversation;
-(void)_updateNavigationButtons;

@end

@interface CKChatController : CKCoreChatController

-(void)_initializeNavigationBarCanvasViewIfNecessary;

@end

@interface CKTranscriptCollectionViewController : CKViewController

-(id)initWithConversation:(id)arg1 delegate:(id)arg2 balloonMaxWidth:(double)arg3 marginInsets:(UIEdgeInsets)arg4;

@end

@interface CKNavigationController : UINavigationController

@end

@interface CKTranscriptPreviewController : CKViewController

-(void)setConversation:(CKConversation *)conversation;

@end
