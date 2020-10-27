//
//  CarouselView.h
//  CIE ID
//


#import <Cocoa/Cocoa.h>
#import "Cie.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CarouselViewDelegate <NSObject>

- (void) shouldAddCard;
- (void) shouldRemoveCard:(Cie *)card;
- (void) shouldRemoveAllCards;

@end

@interface CarouselView : NSView

@property (nonatomic, weak, nullable) id<CarouselViewDelegate> delegate;

- (void) configureWithCards:(NSArray <Cie *> * _Nonnull)cardList;

- (Cie *) getSelectedCard;

@end

NS_ASSUME_NONNULL_END
