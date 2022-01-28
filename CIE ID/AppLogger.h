//
//  Logger.h
//  CIE ID
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AppLogLevel)
{
    AppLogLevel_NONE = 0,
    AppLogLevel_DEBUG = 1,
    AppLogLevel_INFO = 2,
    AppLogLevel_ERROR = 3,
};


@interface AppLogger : NSObject

@property AppLogLevel level;
@property (readonly) AppLogLevel defaultLevel;

+ (instancetype)sharedInstance;
+ (instancetype)sharedInstanceWithLogLevel:(int) level;
+ (instancetype)sharedInstanceWithDefaultLogLevel;

// -(id) initWithLoglevel:(int) level;
-(void) debug:(NSString *) message;
-(void) info:(NSString *) message;
-(void) error:(NSString *) message;
-(void) log:(NSString *) message withMessageLevel:(AppLogLevel) messageLevel;
-(void) writeToLogFile:(NSString *) message;

@end

NS_ASSUME_NONNULL_END
