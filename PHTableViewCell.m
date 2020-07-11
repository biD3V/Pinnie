//
//  PHTableViewCell.m
//  
//
//  Created by Sawyer Jester on 6/27/20.
//

#import "PHTableViewCell.h"

@implementation PHTableViewCell

@synthesize pins;

CGFloat viewWidth;
CGFloat spacing;

+(instancetype)sharedInstance {
    static PHTableViewCell *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PHTableViewCell alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
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
            cell.backDrop.image = nil;
        }
        
        if (conversation.unreadCount > 0) {
            if (@available(iOS 13, *)) {
                cell.unreadDot.image = [UIImage systemImageNamed:@"circle.fill"];
            } else {
                NSBundle *bundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/Pinnie/Pinnie.bundle"];
                
                UIImage *circleImage = [UIImage imageNamed:@"circle.fill"
                                                   inBundle:bundle
                              compatibleWithTraitCollection:nil];
                
                cell.unreadDot.image = [circleImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            
            cell.unreadDot.tintColor = [UIColor systemBlueColor];
        } else {
            cell.unreadDot.image = nil;
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
    if (layout == 0 && avatarSize == 0) {
        return UIEdgeInsetsMake(spacing, spacing, spacing + spacing / 2, spacing);
    } else {
        return UIEdgeInsetsMake(spacing, spacing, spacing + viewWidth / 32, spacing);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return spacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (layout == 0) {
        if (avatarSize == 0) {
            return spacing * 1.2;
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
