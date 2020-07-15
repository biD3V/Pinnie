#import "Tweak.h"
#import "PHPinController.h"
#import "PHTableHeaderView.h"
#import "PHCollectionViewCell.h"

void restoreDefaults() {
    if (!userDefaults) return;
    pinnedMessagesIDsKey = @"com.bid3v.pinnie.pinnedmessagesids";
    pinnedMessagesIDs = [userDefaults arrayForKey:pinnedMessagesIDsKey] ? [[userDefaults arrayForKey:pinnedMessagesIDsKey] mutableCopy] : [NSMutableArray new];
}

void persistDefaults() {
    if (!userDefaults) return;
    [userDefaults setObject:pinnedMessagesIDs forKey:pinnedMessagesIDsKey];
}

void loadPrefs() {
    PNESyncPrefs();
    
    
    NSLog(@"[PinniePrefs] %@", PNESettings);
    PNEIntPref(layout, PinLayout, 0);
    PNEIntPref(avatarSize, AvatarSize, 1);
    PNEBoolPref(pinsEnabled, PinsEnabled, YES);
    PNEBoolPref(dropGlowEnabled, DrowGlowEnabled, YES);
    PNEFloatPref(dropGlowAlpha, GlowAlpha, 0.75);
}

void reloadTable () {
    [NSNotificationCenter.defaultCenter postNotificationName:@"ReloadTable"
                                                      object:nil
                                                    userInfo:nil];
}

@interface CKConversationListController : UITableViewController

-(void)onCellTapped:(NSNotification *)notification;

@end

%hook CKConversationListController

UICollectionView *collectionView;

- (void)viewWillAppear:(BOOL)appear {
    %orig;
    if (pinsEnabled) {
        
        if (!self.tableView.tableHeaderView) {
            PHTableHeaderView *tableHeader = [[PHTableHeaderView alloc] init];
            
            collectionView = tableHeader.collectionView;
            
            [self.tableView setTableHeaderView:tableHeader];
            
            PHPinController *conPins = [PHPinController sharedInstance];
            [tableHeader setPins:conPins.pinnedMessages];
            
            reloadTable();
            
//            if (layout == 1) {
//                [(UICollectionViewFlowLayout *)tableHeader.collectionView.collectionViewLayout setScrollDirection:1];
//            } else {
//                [(UICollectionViewFlowLayout *)tableHeader.collectionView.collectionViewLayout setScrollDirection:0];
//            }
        }
        
    }
}

-(void)viewDidLoad {
    %orig;
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(onCellTapped:)
                                               name:@"CellTapped"
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(onPinRemoved:)
                                               name:@"PinRemoved"
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(reloadTable:)
                                               name:@"ReloadTable"
                                             object:nil];
}

- (void)viewDidLayoutSubviews {
    %orig;
    PHTableHeaderView *headerView = (PHTableHeaderView *)self.tableView.tableHeaderView;
    CGFloat width = self.tableView.bounds.size.width - self.tableView.safeAreaInsets.left - self.tableView.safeAreaInsets.right;
    [headerView setFrame:CGRectMake(0,0,width,[headerView heightForPins:[PHPinController sharedInstance].pinnedMessages])];
    if (layout == 1) {
        [(UICollectionViewFlowLayout *)headerView.collectionView.collectionViewLayout setScrollDirection:1];
    } else {
        [(UICollectionViewFlowLayout *)headerView.collectionView.collectionViewLayout setScrollDirection:0];
    }
    [headerView setNeedsLayout];
    [headerView layoutIfNeeded];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    if (!pinsEnabled) return %orig;
    
    CKConversationListStandardCell *convoCell = (CKConversationListStandardCell *)%orig;
    PHPinController *pins = [PHPinController sharedInstance];
    
    if ([convoCell isKindOfClass:%c(CKConversationListStandardCell)] && [pins conversationIsPinned:convoCell.conversation]) {
        
        [UIView transitionWithView:convoCell
                          duration:0.5
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void){
            [convoCell setHidden:true];
        } completion:nil];
        
        return convoCell;
    } else {
        return %orig;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    if (!pinsEnabled) return %orig;
    
    CKConversationListStandardCell *convoCell = (CKConversationListStandardCell *)[self tableView:tableView
                                                                            cellForRowAtIndexPath:indexPath];
    
    PHPinController *pins = [PHPinController sharedInstance];
    
    if ([convoCell isKindOfClass:%c(CKConversationListStandardCell)] && [pins conversationIsPinned:convoCell.conversation]) {
        return 0;
    } else {
        return %orig;
    }
}

%new
-(void)onCellTapped:(NSNotification *)notification {
    
    NSDictionary *dict = [notification userInfo];
    CKNavigationController *nav = [[CKNavigationController alloc] init];
    CKChatController *chat = [[CKChatController alloc] initWithConversation:[dict objectForKey:@"conversation"]];
    
    [nav addChildViewController:chat];
    
    [chat.conversation setLimitToLoad:50];
    [chat.conversation loadMoreMessages];
    
    [self.navigationController pushViewController:nav
                                         animated:YES];
}

%new
-(void)onPinRemoved:(NSNotification *)notification {
    reloadTable();
}

%new
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CKConversationListStandardCell *cell = (CKConversationListStandardCell *)[self tableView:tableView
                                                                       cellForRowAtIndexPath:indexPath];
    CKConversation *conversation = [cell conversation];
    PHPinController *pins = [PHPinController sharedInstance];
    UIContextualAction *pinAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                            title:@"Pin"
                                                                          handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [pins conversation:conversation
                 setPinned:true];
        reloadTable();
        completionHandler(true);
    }];
    
    pinAction.backgroundColor = [UIColor systemOrangeColor];
    NSMutableArray *actions = [NSMutableArray new];
    
    [actions addObject:pinAction];
    return [UISwipeActionsConfiguration configurationWithActions:actions];
}

%new
- (void)reloadTable:(NSNotification *)notification {
    self.tableView.tableHeaderView = self.tableView.tableHeaderView;
    [self.tableView performBatchUpdates:^{
        NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
        NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
        [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:nil];
    
    [collectionView performBatchUpdates:^{
        [collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    } completion:nil];
}

%end

%ctor {
    userDefaults = [NSUserDefaults standardUserDefaults];
    restoreDefaults();
    
    loadPrefs();
    PNEObserver(loadPrefs, "com.bid3v.pinnieprefs-prefschanged");
    PNEObserver(reloadTable, "com.bid3v.pinnieprefs-prefschanged");
}
