//
//  PHTableViewCell.h
//  
//
//  Created by Sawyer Jester on 6/27/20.
//

#import <UIKit/UIKit.h>
#import "PHCollectionViewCell.m"
#import "PHPinController.m"

NS_ASSUME_NONNULL_BEGIN

@interface PHTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) NSMutableArray *pins;
@property (nonatomic) CAGradientLayer *gradient;

+(instancetype)sharedInstance;
-(UIImage *)blurredImageWithImage:(UIImage *)sourceImage;

@end

NS_ASSUME_NONNULL_END
