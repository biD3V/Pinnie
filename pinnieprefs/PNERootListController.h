#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface PSListController (iOS12Plus)

- (BOOL)containsSpecifier:(id)arg1;

@end

@interface PNERootListController : PSListController

@property (nonatomic,retain) NSMutableDictionary *normalSpecifiers;
@property (nonatomic,retain) NSMutableDictionary *glowSpecifiers;

- (void)onLayoutSelected:(NSNotification *)notification;
- (void)loadHeaderForTableView:(UITableView *)tableView;

@end

@protocol PNELayoutSelectorView

//- (id)initWithSpecifier:(PSSpecifier *)specifier;
- (CGFloat)preferredHeightForWidth:(CGFloat)width;

@end

@interface PNELayoutOptionView : UIView

@property (nonatomic,retain) IBOutlet UIView *containerView;
@property (nonatomic,retain) IBOutlet UIImageView *preview;
@property (nonatomic,retain) IBOutlet UILabel *name;
@property (nonatomic,retain) IBOutlet UIImageView *checkmark;
@property (nonatomic,assign) BOOL checkmarkChecked;

-(void)updateCheckmark;
-(void)setPreviewImageNamed:(NSString *)imageName;

@end

@interface PNELayoutSelectorCell : PSTableCell <PNELayoutSelectorView>

@property (nonatomic,retain) UIStackView *stack;
@property (nonatomic,retain) PNELayoutOptionView *normal;
@property (nonatomic,retain) PNELayoutOptionView *compact;
//@property (nonatomic) int selectedLayout;

-(int)selectedLayoutFromSpecifier:(PSSpecifier *)specifier;

@end

@interface PNEStaticTextNoSeparatorCell : PSTableCell

@property (nonatomic,strong) UIColor * separatorColor;

@end
