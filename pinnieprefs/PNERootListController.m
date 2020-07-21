#include "PNERootListController.h"

@implementation PNERootListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(onLayoutSelected:)
                                               name:@"LayoutSelected"
                                             object:nil];
    
    //From my testing, at this point we can't get the value of a specifier yet as they haven't loaded
      //Instead you can just read your switch value from your preferences file
    
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.bid3v.pinnieprefs.plist"];
    if ([preferences[@"PinLayout"] intValue] == 1) {
        [self removeContiguousSpecifiers:@[self.normalSpecifiers[@"SizeSelector"],
                                           self.normalSpecifiers[@"ColumnSelectorTitle"],
                                           self.normalSpecifiers[@"ColumnSelector"]]
                                animated:YES];
    }
    if ([preferences[@"AvatarSize"] intValue] == 1) {
        [self.normalSpecifiers[@"ColumnSelector"] setValues:@[@0,@1] titles:@[@"2",@"3"]];
    } else {
        [self.normalSpecifiers[@"ColumnSelector"] setValues:@[@0,@1,@2] titles:@[@"2",@"3",@"4"]];
    }
    [self readPreferenceValue:self.normalSpecifiers[@"ColumnSelector"]];
    [self reloadSpecifier:self.normalSpecifiers[@"ColumnSelector"]
                 animated:YES];
    if (![preferences[@"DropGlowEnabled"] boolValue]) {
        [self removeContiguousSpecifiers:@[self.glowSpecifiers[@"GlowAlphaTitle"],      self.glowSpecifiers[@"GlowAlphaSlider"]]
                                animated:YES];
    }
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
        
        //Code to save certain specifiers
        //Add the id of the specifier to the chosenIDs array.
        //Only add the IDs of the specifiers you want to hide
        NSArray *normalIDs = @[@"SizeSelector", @"ColumnSelectorTitle", @"ColumnSelector"];
        self.normalSpecifiers = (!self.normalSpecifiers) ? [[NSMutableDictionary alloc] init] : self.normalSpecifiers;
        for(PSSpecifier *specifier in _specifiers) {
            if([normalIDs containsObject:[specifier propertyForKey:@"id"]]) {
                [self.normalSpecifiers setObject:specifier
                                          forKey:[specifier propertyForKey:@"id"]];
            }
        }
        
        NSArray *glowIDs = @[@"GlowAlphaTitle", @"GlowAlphaSlider"];
        self.glowSpecifiers = (!self.glowSpecifiers) ? [[NSMutableDictionary alloc] init] : self.glowSpecifiers;
        for (PSSpecifier *specifier in _specifiers) {
            if ([glowIDs containsObject:[specifier propertyForKey:@"id"]]) {
                [self.glowSpecifiers setObject:specifier
                                        forKey:[specifier propertyForKey:@"id"]];
            }
        }
	}

	return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    [settings setObject:value forKey:specifier.properties[@"key"]];
    [settings writeToFile:path atomically:YES];
    CFStringRef notificationName = (CFStringRef)CFBridgingRetain(specifier.properties[@"PostNotification"]);
    if (notificationName) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
    }
    
    //Here we check if the switch is on based of the key of the PSSwitchCell, then hide the specifier
    //We then hide the cell using the id of it. If its already hidden we reinsert the cell below a certain specifier based on its ID
    NSString *key = [specifier propertyForKey:@"key"];
    if ([key isEqualToString:@"PinLayout"]) {
        if ([value intValue] == 1) {
            [self removeContiguousSpecifiers:@[self.normalSpecifiers[@"SizeSelector"],
                                               self.normalSpecifiers[@"ColumnSelectorTitle"],
                                               self.normalSpecifiers[@"ColumnSelector"]]
                                    animated:YES];
        } else if(![self containsSpecifier:self.normalSpecifiers[@"SizeSelector"]] && ![self containsSpecifier:self.normalSpecifiers[@"ColumnSelectorTitle"]] && ![self containsSpecifier:self.normalSpecifiers[@"ColumnSelector"]]) {
            [self insertContiguousSpecifiers:@[self.normalSpecifiers[@"SizeSelector"],
                                               self.normalSpecifiers[@"ColumnSelectorTitle"],
                                               self.normalSpecifiers[@"ColumnSelector"]]
                            afterSpecifierID:@"LayoutSelector"
                                    animated:YES];
        }
    } else if ([key isEqualToString:@"DropGlowEnabled"]) {
        if(![value boolValue]) {
            [self removeContiguousSpecifiers:@[self.glowSpecifiers[@"GlowAlphaTitle"],      self.glowSpecifiers[@"GlowAlphaSlider"]]
                                    animated:YES];
        } else if(![self containsSpecifier:self.glowSpecifiers[@"GlowAlphaTitle"]] && ![self containsSpecifier:self.glowSpecifiers[@"GlowAlphaSlider"]]) {
            [self insertContiguousSpecifiers:@[self.glowSpecifiers[@"GlowAlphaTitle"], self.glowSpecifiers[@"GlowAlphaSlider"]]
                            afterSpecifierID:@"GlowSwitch"
                                    animated:YES];
        }
    } else if ([key isEqualToString:@"AvatarSize"]) {
        if ([value intValue] == 1) {
            [self.normalSpecifiers[@"ColumnSelector"] setValues:@[@0,@1] titles:@[@"2",@"3"]];
        } else {
            [self.normalSpecifiers[@"ColumnSelector"] setValues:@[@0,@1,@2] titles:@[@"2",@"3",@"4"]];
        }
        [self readPreferenceValue:self.normalSpecifiers[@"ColumnSelector"]];
        [self reloadSpecifier:self.normalSpecifiers[@"ColumnSelector"]
                     animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath == [self indexPathForSpecifier:[self specifierForID:@"LayoutSelector"]]) {
        return tableView.bounds.size.width / 2;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self loadHeaderForTableView:tableView];
    
    return [super tableView:tableView
      cellForRowAtIndexPath:indexPath];
}

- (void)onLayoutSelected:(NSNotification *)notification {
    NSDictionary *dict = [notification userInfo];
    PSSpecifier *specifier = [dict objectForKey:@"specifier"];
    NSNumber *layout = [NSNumber numberWithInteger:[[dict objectForKey:@"layout"] intValue]];
    
    [self setPreferenceValue:layout
                   specifier:specifier];
}

-(void)reloadSpecifiers {
    [super reloadSpecifiers];

    //This will look the exact same as step 5, where we only check if specifiers need to be removed
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.bid3v.pinnieprefs.plist"];
    if([preferences[@"PinLayout"] intValue] == 1) {
        [self removeContiguousSpecifiers:@[self.normalSpecifiers[@"SizeSelector"],
                                           self.normalSpecifiers[@"ColumnSelectorTitle"],
                                           self.normalSpecifiers[@"ColumnSelector"]]
                                animated:YES];
    }
    if ([preferences[@"AvatarSize"] intValue] == 1) {
        [self.normalSpecifiers[@"ColumnSelector"] setValues:@[@0,@1] titles:@[@"2",@"3"]];
    } else {
        [self.normalSpecifiers[@"ColumnSelector"] setValues:@[@0,@1,@2] titles:@[@"2",@"3",@"4"]];
    }
    [self readPreferenceValue:self.normalSpecifiers[@"ColumnSelector"]];
    [self reloadSpecifier:self.normalSpecifiers[@"ColumnSelector"]
                 animated:YES];
    if (![preferences[@"DropGlowEnabled"] boolValue]) {
        [self removeContiguousSpecifiers:@[self.glowSpecifiers[@"GlowAlphaTitle"],      self.glowSpecifiers[@"GlowAlphaSlider"]]
                                animated:YES];
    }
}

- (void)loadHeaderForTableView:(UITableView *)tableView {
    CGFloat width = tableView.bounds.size.width;
    UIImageView *header = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,width,width * 4 / 9)];
    
    NSBundle *bundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/Pinnie/Pinnie.bundle"];
    
    UIImage *headerImage = [UIImage imageNamed:@"header"
                                      inBundle:bundle
                 compatibleWithTraitCollection:nil];
    
    header.image = headerImage;
    
    [tableView setTableHeaderView:header];
}


@end

@implementation PNELayoutOptionView

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (id)init {
    NSBundle *bundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/Pinnie/Pinnie.bundle"];
    
    self = [bundle loadNibNamed:@"PNELayoutOptionView"
                          owner:self
                        options:nil].firstObject;
    [self updateCheckmark];
    
    return self;
}

-(void)updateCheckmark {
    if (_checkmarkChecked) {
        if (@available(iOS 13, *)) {
            _checkmark.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
        } else {
            NSBundle *bundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/Pinnie/Pinnie.bundle"];
            
            UIImage *checkImage = [UIImage imageNamed:@"checkmark.circle.fill"
                                               inBundle:bundle
                          compatibleWithTraitCollection:nil];
            
            _checkmark.image = [checkImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        _checkmark.tintColor = self.tintColor;
    } else {
        if (@available(iOS 13, *)) {
            _checkmark.image = [UIImage systemImageNamed:@"circle"];
            _checkmark.tintColor = [UIColor systemFillColor];
        } else {
            NSBundle *bundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/Pinnie/Pinnie.bundle"];
            
            UIImage *circleImage = [UIImage imageNamed:@"circle"
                                               inBundle:bundle
                          compatibleWithTraitCollection:nil];
            
            _checkmark.image = [circleImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            [_checkmark setTintColor:[UIColor colorWithRed:120.0 / 255.0
                                                     green:120.0 / 255.0
                                                      blue:128.0 / 255.0
                                                     alpha:0.2]];
        }
    }
}

-(void)setPreviewImageNamed:(NSString *)imageName {
    NSBundle *bundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/Pinnie/Pinnie.bundle"];
    
    UIImage *previewImage = [UIImage imageNamed:imageName
                                       inBundle:bundle
                  compatibleWithTraitCollection:nil];
    
    if (@available(iOS 13, *)) {
        _preview.image = [previewImage imageWithTintColor:self.tintColor];
    } else {
        _preview.image = [previewImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_preview setTintColor:self.tintColor];
    }
}

@end

@implementation PNELayoutSelectorCell

@synthesize stack;
@synthesize normal;
@synthesize compact;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier {
    
    self = [super initWithStyle:style
                reuseIdentifier:identifier
                      specifier:specifier];
    
    if (self) {
        if (@available(iOS 13, *)) {
            [self setBackgroundColor:[UIColor systemBackgroundColor]];
        } else {
            [self setBackgroundColor:[UIColor whiteColor]];
        }
        
        normal = [[PNELayoutOptionView alloc] init];
        [normal setPreviewImageNamed:@"normal"];
        normal.name.text = @"Normal";
        
        UITapGestureRecognizer *selectNormal = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(selectedNormal:)];
        [normal addGestureRecognizer:selectNormal];
        
        compact = [[PNELayoutOptionView alloc] init];
        [compact setPreviewImageNamed:@"compact"];
        compact.name.text = @"Compact";
        
        UITapGestureRecognizer *selectCompact = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(selectedCompact:)];
        [compact addGestureRecognizer:selectCompact];
        
        CGRect newFrame = self.frame;
        newFrame.size.height = [UIScreen mainScreen].bounds.size.width / 2;
        newFrame.size.width = [UIScreen mainScreen].bounds.size.width;
        self.frame = newFrame;
        
        stack = [[UIStackView alloc] initWithFrame:self.frame];
        [stack setDistribution:UIStackViewDistributionFillEqually];
        
        [stack addArrangedSubview:normal];
        [stack addArrangedSubview:compact];
        
        [self.contentView addSubview:stack];
        
        NSLog(@"[Pinnie] layout %d", [self selectedLayoutFromSpecifier:specifier]);
        
        if ([self selectedLayoutFromSpecifier:specifier] == 0) {
            [compact setCheckmarkChecked:false];
            [compact updateCheckmark];
            [normal setCheckmarkChecked:true];
            [normal updateCheckmark];
        } else  {
            [normal setCheckmarkChecked:false];
            [normal updateCheckmark];
            [compact setCheckmarkChecked:true];
            [compact updateCheckmark];
        }
    }
    
    
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    CGRect newFrame = stack.frame;
    newFrame.size.height = width / 2;
    stack.frame = newFrame;
    return width / 2;
}

- (void)selectedNormal:(UITapGestureRecognizer *)recognizer {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.specifier,@"specifier",@(0),@"layout",nil];
    [NSNotificationCenter.defaultCenter postNotificationName:@"LayoutSelected"
                                                      object:nil
                                                    userInfo:dict];
    [compact setCheckmarkChecked:false];
    [compact updateCheckmark];
    [normal setCheckmarkChecked:true];
    [normal updateCheckmark];
}

- (void)selectedCompact:(UITapGestureRecognizer *)recognizer {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.specifier,@"specifier",@(1),@"layout",nil];
    [NSNotificationCenter.defaultCenter postNotificationName:@"LayoutSelected"
                                                      object:nil
                                                    userInfo:dict];
    [normal setCheckmarkChecked:false];
    [normal updateCheckmark];
    [compact setCheckmarkChecked:true];
    [compact updateCheckmark];
}

- (int)selectedLayoutFromSpecifier:(PSSpecifier *)specifier {
    NSLog(@"[PinniePrefs] defaults %@", specifier.properties[@"defaults"]);
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    return ([settings[specifier.properties[@"key"]] intValue]) ?: [specifier.properties[@"default"] intValue];
}

@end

@implementation PNEStaticTextNoSeparatorCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style
                reuseIdentifier:identifier
                      specifier:specifier];
    
    [self setSeparatorColor:[UIColor clearColor]];
    
    return self;
}
@end
