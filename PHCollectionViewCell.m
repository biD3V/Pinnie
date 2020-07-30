//
//  PHCollectionViewCell.m
//  
//
//  Created by Sawyer Jester on 6/27/20.
//

#import "PHCollectionViewCell.h"

@implementation PHCollectionViewCell

- (void)handleTapFrom:(UITapGestureRecognizer *)gesture {
//    NSURL *convo = [NSURL URLWithString:[NSString stringWithFormat:@"sms:%@", [self.conversation uniqueIdentifier]]];
//    if ([UIApplication.sharedApplication canOpenURL:convo]) {
//        [UIApplication.sharedApplication openURL:convo
//                                         options:@{}
//                               completionHandler:nil];
//    }
    NSDictionary *dict = [NSDictionary dictionaryWithObject:self.conversation
                                                     forKey:@"conversation"];
    [NSNotificationCenter.defaultCenter postNotificationName:@"CellTapped"
                                                      object:nil
                                                    userInfo:dict];
}

- (void)handleHoldFrom:(UILongPressGestureRecognizer *)gesture {
    PHPinController *pinsController = [PHPinController sharedInstance];
    [pinsController conversation:self.conversation
                       setPinned:false];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"PinRemoved"
                                                      object:nil
                                                    userInfo:nil];
}

- (void)unpin:(UIButton *)paramSender {
    PHPinController *pinsController = [PHPinController sharedInstance];
    [pinsController conversation:self.conversation
                       setPinned:false];
    [NSNotificationCenter.defaultCenter postNotificationName:@"PinRemoved"
                                                      object:nil
                                                    userInfo:nil];
}

@end
