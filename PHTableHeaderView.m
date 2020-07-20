//
//  PHTableViewCell.m
//  
//
//  Created by Sawyer Jester on 6/27/20.
//

#import "Tweak.h"
#import "PHTableHeaderView.h"

@implementation PHTableHeaderView

@synthesize pins;

CGFloat viewWidth;
CGFloat spacing;
CGFloat twoSpacing;
CGFloat fourSpacing;

+(instancetype)sharedInstance {
    static PHTableHeaderView *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PHTableHeaderView alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    pins = [[PHPinController sharedInstance] pinnedMessages];
    NSBundle *bundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/Pinnie/Pinnie.bundle"];
    self = [bundle loadNibNamed:@"PHTableHeaderView"
                          owner:self
                        options:nil].firstObject;
    return self;
}

- (CGFloat)heightForPins:(NSMutableArray *)pinConvos {
    CGFloat height;
    UITableView *tableView = (UITableView *)self.superview;
    CGFloat width = tableView.frame.size.width;
    CGFloat pinCount = pinConvos.count;
    NSLog(@"[Pinnie] pinConvos.count = %f", pinCount);
    NSLog(@"[Pinnie] layout = %d", layout);
    switch (columns) {
        case 0:
            if (layout == 0) {
                if (pinCount == 0) {
                    height = 0;
                } else if (pinCount <= 2 && pinCount > 0) {
                    height = width * 7 / 16;
                } else if (pinCount <= 4 && pinCount > 2) {
                    height = width * 3 / 4;
                } else {
                    height = width;
                }
            } else {
                height = width * .3;
            }
            break;
        case 2:
            if (layout == 0) {
                if (pinCount == 0) {
                    height = 0;
                } else if (pinCount <= 4 && pinCount > 0) {
                    height = width * .35;
                } else if (pinCount <= 8 && pinCount > 4) {
                    height = width * .7;
                } else {
                    height = width * .8;
                }
            } else {
                height = width * .3;
            }
            break;
        default:
            if (layout == 0) {
                if (pinCount == 0) {
                    height = 0;
                } else if (pinCount <= 3 && pinCount > 0) {
                    height = width * 7 / 16;
                } else if (pinCount <= 6 && pinCount > 3) {
                    height = width * 3 / 4;
                } else {
                    height = width;
                }
            } else {
                height = width * .3;
            }
            break;
    }
    NSLog(@"[Pinnie] pins = %@", pins);
    return height;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    viewWidth = self.bounds.size.width;
    
    if (layout == 0) {
        if (avatarSize == 0) {
            spacing = viewWidth * 0.1;
        } else {
            spacing = viewWidth / 16;
        }
    } else {
        spacing = viewWidth / 5 / 7;
    }
    
    twoSpacing = viewWidth * .5 / 3;
    fourSpacing = viewWidth * .04;
}

- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage{

    //  Create our blurred image
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];

    //  Setting up Gaussian Blur
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    CGFloat blurLevel = 15;
    [filter setValue:[NSNumber numberWithFloat:blurLevel] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];

    UIImage *retVal = [UIImage imageWithCGImage:cgImage];

    if (cgImage) {
        CGImageRelease(cgImage);
    }

    return retVal;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"PHCollectionViewCell" bundle:[[NSBundle alloc] initWithPath:@"/Library/Application Support/Pinnie/Pinnie.bundle"]] forCellWithReuseIdentifier:@"phCollectionCell"];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.pins.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"phCollectionCell" forIndexPath:indexPath];
    if (self.pins[indexPath.item]) {
        CKConversation *conversation = self.pins[indexPath.item];
        if ([conversation hasDisplayName]) {
            cell.name.text = conversation.displayName;
        } else {
            cell.name.text = conversation.name;
        }
        if (layout == 0 && avatarSize == 0) {
            [cell.name setNumberOfLines:2];
        } else {
            [cell.name setNumberOfLines:1];
        }
        
        [cell.avatarView setContacts:[conversation orderedContactsForAvatarView]];
        [cell.avatarView setFrame:CGRectMake(0,0,cell.frame.size.width * .98,cell.frame.size.height * .98)]; // have to set frame smaller since it gets cut off even with clipsToBounds = false
        
        cell.avatarImage = cell.avatarView.contentImage;
        if (dropGlowEnabled) {
            cell.backDrop.image = [self blurredImageWithImage:cell.avatarImage];
            cell.backDrop.alpha = dropGlowAlpha;
        } else {
            cell.backDrop.alpha = 0;
        }
        
        if (@available(iOS 13, *)) {
            cell.unreadDot.image = [UIImage systemImageNamed:@"circle.fill"];
            [cell.unpinButton setImage:[UIImage systemImageNamed:@"minus.circle.fill"]
                              forState:UIControlStateNormal];
        } else {
            NSBundle *bundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/Pinnie/Pinnie.bundle"];
            
            UIImage *circleImage = [UIImage imageNamed:@"circle.fill"
                                               inBundle:bundle
                          compatibleWithTraitCollection:nil];
            
            UIImage *minusImage = [UIImage imageNamed:@"minus.circle.fill"
                                             inBundle:bundle
                        compatibleWithTraitCollection:nil];
            
            cell.unreadDot.image = [circleImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [cell.unpinButton setImage:[minusImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                              forState:UIControlStateNormal];
        }
        
        cell.unreadDot.tintColor = [UIColor systemBlueColor];
        cell.unpinButton.tintColor = [UIColor systemRedColor];
        
        if (conversation.unreadCount > 0) {
            cell.unreadDot.alpha = 1;
        } else {
            cell.unreadDot.alpha = 0;
        }
        
        [cell.unpinButton addTarget:cell
                             action:@selector(unpin:)
                   forControlEvents:UIControlEventTouchUpInside];
        if (self.editing) {
            cell.unpinButton.userInteractionEnabled = 1;
            cell.unpinButton.alpha = 1;
        } else {
            cell.unpinButton.userInteractionEnabled = 0;
            cell.unpinButton.alpha = 0;
        }
        
        cell.conversation = conversation;
        
        UITapGestureRecognizer *getConversation = [[UITapGestureRecognizer alloc] initWithTarget:cell
                                                                                          action:@selector(handleTapFrom:)];
        
        UILongPressGestureRecognizer *unpin = [[UILongPressGestureRecognizer alloc] initWithTarget:cell
                                                                                           action:@selector(handleHoldFrom:)];
        
        [cell addGestureRecognizer:getConversation];
        [cell addGestureRecognizer:unpin];
    }
    return cell;
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView
    contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath
                                         point:(CGPoint)point API_AVAILABLE(ios(13)) {
    PHCollectionViewCell *cell = [self collectionView:collectionView
                               cellForItemAtIndexPath:indexPath];
    
    UIAction *unpin = [UIAction actionWithTitle:@"Unpin"
                                          image:[UIImage systemImageNamed:@"pin.slash.fill"]
                                     identifier:nil
                                        handler:^(UIAction *action){
        
        PHPinController *pinsController = [PHPinController sharedInstance];
        [pinsController conversation:cell.conversation
                           setPinned:false];
        [NSNotificationCenter.defaultCenter postNotificationName:@"PinRemoved"
                                                          object:nil
                                                        userInfo:nil];
    }];
    
    NSString *title;
    
    if ([cell.conversation hasDisplayName]) {
        title = cell.conversation.displayName;
    } else {
        title = cell.conversation.name;
    }
    
    UIMenu *menu = [UIMenu menuWithTitle:title
                                children:@[unpin]];
    
//    CKTranscriptPreviewController *transcript = [[CKTranscriptPreviewController alloc] init];
//    [cell.conversation setLimitToLoad:50];
//    [transcript setConversation:cell.conversation];
    
    UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                                                        previewProvider:nil
                                                                                         actionProvider:^(NSArray *menuAction){return menu;}];
    return configuration;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (layout == 0) {
        if (avatarSize == 0) {
            return CGSizeMake(viewWidth / 5, viewWidth / 5);
        } else {
            return CGSizeMake(viewWidth / 4, viewWidth / 4);
        }
    } else {
        return CGSizeMake(viewWidth / 5, viewWidth / 5);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (layout == 0) {
        if (avatarSize == 0) {
            switch (columns) {
                case 0:
                    return UIEdgeInsetsMake(spacing, spacing, spacing + spacing / 2, spacing);
                    break;
                case 2:
                    return UIEdgeInsetsMake(fourSpacing, fourSpacing, fourSpacing + fourSpacing / 2, fourSpacing);
                    break;
                default:
                    return UIEdgeInsetsMake(spacing, spacing, spacing + spacing / 2, spacing);
                    break;
            }
        } else {
            switch (columns) {
                case 0:
                    return UIEdgeInsetsMake(spacing, twoSpacing, spacing + spacing / 2, twoSpacing);
                    break;
                case 2:
                    return UIEdgeInsetsMake(spacing, spacing, spacing + spacing / 2, spacing);
                    break;
                default:
                    return UIEdgeInsetsMake(spacing, spacing, spacing + spacing / 2, spacing);
                    break;
            }
        }
    } else {
        return UIEdgeInsetsMake(spacing, spacing, spacing + viewWidth / 32, spacing);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if (avatarSize == 0) {
        switch (columns) {
            case 0:
                return spacing;
                break;
            case 2:
                return fourSpacing;
                break;
            default:
                return spacing;
                break;
        }
    } else {
        switch (columns) {
            case 0:
                return twoSpacing;
                break;
            case 2:
                return spacing;
                break;
            default:
                return spacing;
                break;
        }
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (layout == 0) {
        if (avatarSize == 0) {
            switch (columns) {
                case 0:
                    return spacing;
                    break;
                case 2:
                    return viewWidth * 1 / 8;
                    break;
                default:
                    return spacing * 1.2;
                    break;
            }
        } else {
            return viewWidth * 3 / 32;
        }
    } else {
        return spacing;
    }
}

- (void)setPins:(NSMutableArray *)pinned {
    pins = pinned;
}



@end
