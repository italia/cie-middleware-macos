//
//  CarouselCard.h
//  CIE ID
//

#import <Cocoa/Cocoa.h>
#import "Cie.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CarouselCardSizeMode) {
    CarouselCardSizeModeSmall,
    CarouselCardSizeModeRegular,
};

@interface CarouselCard : NSView

- (void) setupWithSizeMode:(CarouselCardSizeMode)mode;
- (void) configureWithCard:(Cie *)card;

- (void) setNameLabelOnOneLine;

- (Cie *) getCard;

@end

NS_ASSUME_NONNULL_END
