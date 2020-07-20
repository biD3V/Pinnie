//
//  PHTableViewCell.h
//  
//
//  Created by Sawyer Jester on 6/27/20.
//

#import <UIKit/UIKit.h>
#import "PHCollectionViewCell.h"
#import "PHPinController.h"

NS_ASSUME_NONNULL_BEGIN

@interface PHTableHeaderView : UIView <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) NSMutableArray *pins;
@property (nonatomic) CAGradientLayer *gradient;
@property (nonatomic) BOOL editing;

+(instancetype)sharedInstance;
-(CGFloat)heightForPins:(NSMutableArray *)pinConvos;
-(UIImage *)blurredImageWithImage:(UIImage *)sourceImage;

@end

NS_ASSUME_NONNULL_END
