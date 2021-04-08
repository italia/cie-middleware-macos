//
//  ChangeView.h
//  CIE ID
//
//

#ifndef ChangeView_h
#define ChangeView_h

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>

@interface ChangeView : NSObject{
}

@property (strong, retain) NSArray *viewArray;

typedef NS_ENUM(NSUInteger, viewIndex) {
    HOME_FIRST_PAGE,
    HOME_SECOND_PAGE,
    HOME_THIRD_PAGE,
    HOME_FOURTH_PAGE,
    CAMBIO_PIN_PAGE,
    CAMBIO_PIN_OK_PAGE,
    SBLOCCO_PAGE,
    SBLOCCO_OK_PAGE,
    HELP_PAGE,
    INFO_PAGE,
    SELECT_FILE_PAGE,
    SELECT_OP_PAGE,
    SELECT_FIRMA_OP,
    FIRMA_PDF_PREVIEW,
    FIRMA_PIN_PAGE,
    PERSONALIZZA_FIRMA_PAGE,
    VERIFICA_PAGE,
    IMPOSTAZIONI
};

+ (ChangeView *)getInstance;

-(id)init;
-(void)showSubView: (viewIndex) viewIndex;
-(NSView*)getView: (viewIndex) viewIndex;

@end

#endif /* ChangeView_h */
