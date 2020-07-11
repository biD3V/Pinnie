#import "Tweak.h"
#import "PHPinController.m"
#import "PHTableViewCell.m"
#import "PHCollectionViewCell.m"

@interface CKConversationListController : UITableViewController

-(void)onCellTapped:(NSNotification *)notification;

@end

%hook CKConversationListController

UICollectionView *collectionView;

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

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    %orig;
    if (!pinsEnabled) return %orig;
    if (section == 0) {
        return 1;
    } else {
        return %orig;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    if (!pinsEnabled) return %orig;
    if (indexPath == [NSIndexPath indexPathForRow:0 inSection:0]) {
        
        PHTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"phCell"];
        if (!cell) {
            [tableView registerNib:[UINib nibWithNibName:@"PHTableViewCell" bundle:[[NSBundle alloc] initWithPath:@"/Library/Application Support/Pinnie/Pinnie.bundle"]] forCellReuseIdentifier:@"phCell"];
            cell = [tableView dequeueReusableCellWithIdentifier:@"phCell"];
        }
        
        collectionView = cell.collectionView;
        
        PHPinController *pins = [PHPinController sharedInstance];
        [cell setPins:pins.pinnedMessages];
        
        [cell.collectionView performBatchUpdates:^{
            [cell.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        } completion:nil];
        
        if (layout == 1) {
            [(UICollectionViewFlowLayout *)cell.collectionView.collectionViewLayout setScrollDirection:1];
        } else {
            [(UICollectionViewFlowLayout *)cell.collectionView.collectionViewLayout setScrollDirection:0];
        }
        
        return cell;
    } else {
        
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
        return %orig;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    if (!pinsEnabled) return %orig;
    PHTableViewCell *cell = (PHTableViewCell *)[self tableView:tableView
                                         cellForRowAtIndexPath:indexPath];
    
    CKConversationListStandardCell *convoCell = (CKConversationListStandardCell *)[self tableView:tableView
                                                                            cellForRowAtIndexPath:indexPath];
    
    PHPinController *pins = [PHPinController sharedInstance];
    
    if (![cell isKindOfClass:%c(PHTableViewCell)]) {
        if ([convoCell isKindOfClass:%c(CKConversationListStandardCell)] && [pins conversationIsPinned:convoCell.conversation]) {
            return 0;
        } else {
            return %orig;
        }
    } else {
        CGFloat height;
        CGFloat cellWidth = cell.frame.size.width;
        if (layout == 0) {
            if (cell.pins.count == 0) {
                height = 0;
            } else if (cell.pins.count <= 3 && cell.pins.count != 0) {
                height = cellWidth * 3 / 8;
            } else if (cell.pins.count <= 6 && cell.pins.count > 3) {
                height = cellWidth * 11 / 16;
            } else {
                height = cellWidth * 3 / 4;
            }
        } else {
            height = cellWidth * .3;
        }
        return height;
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
    [self.tableView performBatchUpdates:^{
        [self.tableView reloadData];
    } completion:nil];
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
        [tableView performBatchUpdates:^{
            [tableView reloadData];
        } completion:nil];
        completionHandler(true);
    }];
    
    pinAction.backgroundColor = [UIColor systemOrangeColor];
    NSMutableArray *actions = [NSMutableArray new];
    
    [actions addObject:pinAction];
    return [UISwipeActionsConfiguration configurationWithActions:actions];
}

%new
- (void)reloadTable:(NSNotification *)notification {
    [self.tableView performBatchUpdates:^{
        [self.tableView reloadData];
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
