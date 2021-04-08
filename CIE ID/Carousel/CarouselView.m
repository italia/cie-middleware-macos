//
//  CarouselView.m
//  CIE ID
//


#import "CarouselView.h"
#import "CarouselCard.h"
#import "ChangeView.h"
#import "MainViewController.h"

#define RADIO_BUTTON_LEADING 5
#define RADIO_BUTTON_WIDTH 22
#define RADIO_BUTTON_HEIGHT 18

@interface CarouselView(){
    NSInteger index;
    NSArray <Cie *> *cards;
    
    NSMutableArray <NSButton *> *radioButtons;
    NSButton *lastInsertedRadioButton;
    NSView *radioButtonsSubContainer;
}

@property (weak) IBOutlet NSView *singleCardContainerView;
@property (weak) IBOutlet NSView *multipleCardContainerView;
@property (weak) IBOutlet NSView *selectCIEView;
@property (weak) IBOutlet NSButton *nextButton;
@property (weak) IBOutlet NSButton *backButton;
@property (weak) IBOutlet CarouselCard *leftCard;
@property (weak) IBOutlet CarouselCard *rightCard;
@property (weak) IBOutlet CarouselCard *mainCard;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (weak) IBOutlet NSView *radioButtonsContainer;

@end

@implementation CarouselView

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
    
    [_leftCard setupWithSizeMode:CarouselCardSizeModeSmall];
    [_rightCard setupWithSizeMode:CarouselCardSizeModeSmall];
    [_mainCard setupWithSizeMode:CarouselCardSizeModeRegular];
    //[_mainCard setNameLabelOnOneLine];
    
    [_progressIndicator startAnimation:nil];
    
    [_leftCard setAlphaValue:0.5];
    [_rightCard setAlphaValue:0.5];

    [self addSubview:view];
}

// Loads a XIB file into a view and returns this view.
- (NSView *) viewFromNibForClass {
    NSArray *topLevelObjects;
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    if ([mainBundle loadNibNamed:@"CarouselView" owner:self topLevelObjects:&topLevelObjects]) {
        for (id item in topLevelObjects) {
            if ([item isKindOfClass:[NSView class]]) {
                return item;
            }
        }
    }
    return nil;
}

#pragma mark - Public methods

- (void) configureWithCards:(NSArray <Cie *> * _Nonnull)cardList {

    __weak __typeof__(self) weakSelf = self;
    
    if ([cardList count] == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            [strongSelf.singleCardContainerView setHidden:YES];
            [strongSelf.multipleCardContainerView setHidden:YES];
            [strongSelf.selectCIEView setHidden:YES];
            [strongSelf.backButton setHidden:YES];
            [strongSelf.nextButton setHidden:YES];
            [strongSelf.rightCard setHidden:YES];
            [strongSelf.leftCard setHidden:YES];
            [strongSelf.backButton setHidden:YES];
            [strongSelf.nextButton setHidden:YES];
        });
    }
    else if ([cardList count] > 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            [strongSelf.singleCardContainerView setHidden:YES];
            [strongSelf.multipleCardContainerView setHidden:NO];
            [strongSelf.selectCIEView setHidden:YES];
            [strongSelf.backButton setHidden:NO];
            [strongSelf.nextButton setHidden:NO];

            [strongSelf.rightCard setHidden:NO];
            [strongSelf.leftCard setHidden:[cardList count] == 2];
            [strongSelf.backButton setEnabled:[cardList count] < 2];
            [strongSelf.nextButton setEnabled:[cardList count] == 2];
            
            [strongSelf.backButton setEnabled:[cardList count] >= 3];
            [strongSelf.nextButton setEnabled:[cardList count] >= 3];
        });
    }
    else if ([cardList count] == 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            [strongSelf.singleCardContainerView setHidden:NO];
            [strongSelf.multipleCardContainerView setHidden:YES];
            [strongSelf.selectCIEView setHidden:YES];
            [strongSelf.backButton setHidden:YES];
            [strongSelf.nextButton setHidden:YES];
            [strongSelf.rightCard setHidden:YES];
            [strongSelf.leftCard setHidden:YES];
        });
    }

    index = 0;
    
    cards = cardList;
    
    [self configureRadioButtons];

    if ([cardList count] > 0) {
        [self updateCards];
    }
    
}

- (void) changeButtonViews
{
    [self.selectCIEView setHidden:NO];
    [self.singleCardContainerView setHidden:YES];
    [self.multipleCardContainerView setHidden:YES];
}

- (Cie *) getSelectedCard {
    return [_mainCard getCard];
}

#pragma mark - IBActions

- (IBAction)removeCardPressed:(id)sender {
    if (self.delegate){
        if ([self.delegate respondsToSelector:@selector(shouldRemoveCard:)]){
            [self.delegate shouldRemoveCard:[_mainCard getCard]];
        }
    }
    
}

- (IBAction)addCardPressed:(id)sender {
    
    if (self.delegate){
        if ([self.delegate respondsToSelector:@selector(shouldAddCard)]){
            [self.delegate shouldAddCard];
        }
    }
}

- (IBAction)removeAll:(id)sender {

    if (self.delegate){
        if ([self.delegate respondsToSelector:@selector(shouldRemoveAllCards)]){
            [self.delegate shouldRemoveAllCards];
        }
    }
}

- (IBAction)selectCie:(id)sender {
    
    Cie* selectedCard = [self getSelectedCard];
    ChangeView *cG = [ChangeView getInstance];
    
    NSTextField* lblCustomSign = (NSTextField*)[[cG getView:SELECT_FILE_PAGE] viewWithTag:40];
    NSTextField* lblDefaultSign = (NSTextField*)[[cG getView:SELECT_FILE_PAGE] viewWithTag:20];
    NSButton* btnPersonalizza = (NSButton*)[[cG getView:SELECT_FILE_PAGE] viewWithTag:30];
    if([selectedCard getCustomSign])
    {
        
        [lblCustomSign setHidden:NO];
        [lblDefaultSign setHidden:YES];
        
    }else{
        [btnPersonalizza setTitle:@"Personalizza"];
        [lblCustomSign setHidden:YES];
        [lblDefaultSign setHidden:NO];
    }
    
    [cG showSubView:SELECT_FILE_PAGE];
    
}

- (IBAction)backPressed:(id)sender {

    
    index--;
    
    if (index < 0) {
        index = [cards count] - 1;
    }
    
    [self updateCards];
    
    [self updateRadioButtonAppearance];
}

- (IBAction)nextPressed:(id)sender {
    index++;
     
     if (index > ([cards count] - 1)) {
         index = 0;
     }
     
     [self updateCards];
     
     [self updateRadioButtonAppearance];
}

#pragma mark - Private methods

- (void) configureRadioButtons{
    if (radioButtons) {
        for (NSButton *button in radioButtons) {
            [button removeFromSuperview];
        }
        
        [radioButtons removeAllObjects];
    }
    
    radioButtons = [NSMutableArray new];
    
    if (radioButtonsSubContainer) {
        [radioButtonsSubContainer removeFromSuperview];
    }
    
    radioButtonsSubContainer = [[NSView alloc] init];
    
    lastInsertedRadioButton = nil;

    if ([cards count] > 0){

        for(int i = 0; i < [cards count]; i++){
            NSButton *radioButton = [self buildRadioButtonWithIndex:i];
            
            if (i == 0) {
                [radioButton setState:NSOnState];
            }
            
            [self enqueueRadioButton:radioButton];
            
            [radioButtons addObject:radioButton];
        }
        
        CGFloat width = ([radioButtons count] * RADIO_BUTTON_WIDTH) + (([radioButtons count] -1) * RADIO_BUTTON_LEADING);

        [radioButtonsSubContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.radioButtonsContainer addSubview:radioButtonsSubContainer];
        
        [radioButtonsSubContainer addConstraint:[NSLayoutConstraint constraintWithItem:radioButtonsSubContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:width]];
        
        [radioButtonsSubContainer addConstraint:[NSLayoutConstraint constraintWithItem:radioButtonsSubContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:RADIO_BUTTON_HEIGHT]];
        
        [self.radioButtonsContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.radioButtonsContainer attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:radioButtonsSubContainer attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        
        [self.radioButtonsContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.radioButtonsContainer attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:radioButtonsSubContainer attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
    }
}

- (NSButton *) buildRadioButtonWithIndex:(NSInteger)index{
    NSButton *radioButton = [NSButton radioButtonWithTitle:@"" target:self action:@selector(radioButtonPressed:)];
    [radioButton setTag:index];
    [radioButton setAutoresizingMask:NSViewNotSizable];
    
    return radioButton;
}

- (void) enqueueRadioButton:(NSButton *) button {
    
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [radioButtonsSubContainer addSubview:button];
    
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:RADIO_BUTTON_WIDTH]];
    
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:RADIO_BUTTON_HEIGHT]];
    
    [radioButtonsSubContainer addConstraint:[NSLayoutConstraint constraintWithItem:radioButtonsSubContainer attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    
    if (lastInsertedRadioButton) {
        [radioButtonsSubContainer addConstraint:[NSLayoutConstraint constraintWithItem:lastInsertedRadioButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeLeading multiplier:1 constant:-RADIO_BUTTON_LEADING]];
    }
    else {
        [radioButtonsSubContainer addConstraint:[NSLayoutConstraint constraintWithItem:radioButtonsSubContainer attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    }

    lastInsertedRadioButton = button;
}

- (void) radioButtonPressed:(NSButton *)sender {
    index = sender.tag;
    [self updateCards];
}

- (void) updateRadioButtonAppearance{
    if (!radioButtons) {
        return;
    }
    
    for (int i = 0; i<radioButtons.count; i++) {
        NSButton *current = radioButtons[i];
        if (i == index) {
            [current setState:NSOnState];
        }
        else {
            [current setState:NSOffState];
        }
    }
}

- (void) updateCards {
    if ([cards count] == 0) {
        return;
    }
    
    NSInteger rightIndex = index + 1;
    
    if (rightIndex > ([cards count] - 1)) {
        rightIndex = 0;
    }
    
    NSInteger leftIndex = index - 1;
    
    if (leftIndex < 0) {
        leftIndex = [cards count] - 1;
    }
    
    [self.mainCard configureWithCard:cards[index]];
    [self.leftCard configureWithCard:cards[leftIndex]];
    [self.rightCard configureWithCard:cards[rightIndex]];
    
    __weak __typeof__(self) weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;

        [strongSelf.mainCard setHidden:NO];

        if ([strongSelf->cards count] == 2) {
            if (strongSelf->index == 0) {
                [strongSelf.rightCard setHidden:NO];
                [strongSelf.leftCard setHidden:YES];
                [strongSelf.backButton setEnabled:NO];
                [strongSelf.nextButton setEnabled:YES ];
            }
            else {
                [strongSelf.rightCard setHidden:YES];
                [strongSelf.leftCard setHidden:NO];
                //[strongSelf.backButton setHidden:YES];
                [strongSelf.backButton setEnabled:YES];
                [strongSelf.nextButton setEnabled:NO];
            }
        }
        
        [strongSelf.progressIndicator setHidden:YES];
    });
}

@end
