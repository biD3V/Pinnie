//
//  PHCollectionViewCell.h
//  
//
//  Created by Sawyer Jester on 6/27/20.
//

#import <UIKit/UIKit.h>
#import "Tweak.h"
#import "PHPinController.h"

NS_ASSUME_NONNULL_BEGIN

@interface PHCollectionViewCell : UICollectionViewCell

@property (nonatomic) IBOutlet UILabel *name;
@property (nonatomic) IBOutlet CKAvatarView *avatarView;
@property (nonatomic) IBOutlet UIImageView *backDrop;
@property (nonatomic) CKConversation *conversation;
@property (nonatomic) UIImage * avatarImage;
@property (nonatomic) IBOutlet UIImageView *unreadDot;
@property (nonatomic) IBOutlet UIButton *unpinButton;

@end

NS_ASSUME_NONNULL_END
