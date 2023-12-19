//
//  CarouselCard.m
//  CIE ID
//


#import "CarouselCard.h"

@interface CarouselCard() {
    Cie *cie;
}

@property (weak) IBOutlet NSImageView *cardImageView;
@property (weak) IBOutlet NSTextField *numeroCartaLabel;
@property (weak) IBOutlet NSTextField *numeroCartaValue;
@property (weak) IBOutlet NSTextField *intestatarioLabel;
@property (weak) IBOutlet NSTextField *intestatarioValue;

@property (weak) IBOutlet NSLayoutConstraint *cardImageHeight;

@property (weak) IBOutlet NSLayoutConstraint *cardBottomDistance;

@property (weak) IBOutlet NSLayoutConstraint *numeroCartaLabelHeight;
@property (weak) IBOutlet NSLayoutConstraint *numeroCartaValueHeight;

@property (weak) IBOutlet NSLayoutConstraint *fieldsDistance;

@property (weak) IBOutlet NSLayoutConstraint *intestatarioLabelHeight;
@property (weak) IBOutlet NSLayoutConstraint *intestatarioValueHeight;

@property (weak) IBOutlet NSLayoutConstraint *leading1;
@property (weak) IBOutlet NSLayoutConstraint *leading2;
@property (weak) IBOutlet NSLayoutConstraint *leading3;
@property (weak) IBOutlet NSLayoutConstraint *leading4;

@end

@implementation CarouselCard

- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    [self setupView];
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    [self setupView];
    return self;
}

- (void) setupView {
    NSView *view = [self viewFromNibForClass];
    
    [view setFrame:[self bounds]];
    [view setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin];

    [self addSubview:view];
}

// Loads a XIB file into a view and returns this view.
- (NSView *) viewFromNibForClass {
    NSArray *topLevelObjects;
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    if ([mainBundle loadNibNamed:@"CarouselCard" owner:self topLevelObjects:&topLevelObjects]) {
        for (id item in topLevelObjects) {
            if ([item isKindOfClass:[NSView class]]) {
                return item;
            }
        }
    }
    return nil;
}

#pragma mark - Public methods

- (void) setNameLabelOnOneLine {
    [_intestatarioValue setUsesSingleLineMode:YES];
}

- (void) setupWithSizeMode:(CarouselCardSizeMode)mode{
    
    NSRect newRect = _cardImageView.frame;
    newRect.size.width = self.frame.size.width;
    
    __weak __typeof__(self) weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        
        [strongSelf.cardImageView setFrame:newRect];

        switch (mode) {
            case CarouselCardSizeModeSmall:
                [strongSelf.cardImageView setImageScaling:NSImageScaleProportionallyDown];
                strongSelf.cardBottomDistance.constant = 0; //10;
                [strongSelf.numeroCartaLabel setFont: [NSFont systemFontOfSize:8]]; //9
                [strongSelf.numeroCartaValue setFont: [NSFont systemFontOfSize:10]]; // 12
                [strongSelf.intestatarioLabel setFont: [NSFont systemFontOfSize:8]]; //9
                [strongSelf.intestatarioValue setFont: [NSFont systemFontOfSize:10]]; // 12
                
                
//                strongSelf.cardImageHeight.constant = 76; //86;
                
                strongSelf.numeroCartaLabelHeight.constant = 11; //12;
                strongSelf.numeroCartaValueHeight.constant = 29; //33;
                strongSelf.fieldsDistance.constant = -10; //5;
                strongSelf.intestatarioLabelHeight.constant = 11; //12;
                strongSelf.intestatarioValueHeight.constant = 29; //33;
                strongSelf.leading1.constant = 30; //19;
                strongSelf.leading2.constant = 30; //19;
                strongSelf.leading3.constant = 30; //19;
                strongSelf.leading4.constant = 30; //19;
                break;
                
            case CarouselCardSizeModeRegular:
                [strongSelf.cardImageView setImageScaling:NSImageScaleNone];
                [strongSelf.numeroCartaLabel setFont: [NSFont systemFontOfSize:13]]; //14
                [strongSelf.numeroCartaValue setFont: [NSFont systemFontOfSize:15.5]]; // 20
                [strongSelf.intestatarioLabel setFont: [NSFont systemFontOfSize:13]]; // 14
                [strongSelf.intestatarioValue setFont: [NSFont systemFontOfSize:15.5]]; // 20
                strongSelf.cardImageHeight.constant = 113; //130;
                strongSelf.cardBottomDistance.constant = 25; //14; //16;
                strongSelf.numeroCartaLabelHeight.constant = 17; //20;
                strongSelf.numeroCartaValueHeight.constant = 25; //43; //50;
                strongSelf.fieldsDistance.constant = 0; //8;
                strongSelf.intestatarioLabelHeight.constant = 17; //20;
                strongSelf.intestatarioValueHeight.constant = 43; //50;
                strongSelf.leading1.constant = 15; //45; //30;
                strongSelf.leading2.constant = 15; //45; //30;
                strongSelf.leading3.constant = 15; //45; //30;
                strongSelf.leading4.constant = 15; //45; //30;
                
            default:
                break;
        }
        
        [strongSelf layoutSubtreeIfNeeded];
        strongSelf.wantsLayer = YES;
        strongSelf.needsLayout = YES;
        strongSelf.needsDisplay = YES;
        [strongSelf updateConstraints];
        
    });
}

- (void) configureWithCard:(Cie *)card{
    cie = card;
    
    __weak __typeof__(self) weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        [strongSelf.numeroCartaValue setStringValue: [card getSerialNumber]];
        [strongSelf.intestatarioValue setStringValue: [card getName]];
    });

}

- (Cie *) getCard {
    return cie;
}

@end
