//
//    AppLogger.m
//    CIE ID
//

//

#import "AppLogger.h"

static AppLogLevel AppLoggerDefaultLogLevel = AppLogLevel_INFO;

@implementation AppLogger

@synthesize level;

- (AppLogLevel) defaultLevel {
        return AppLoggerDefaultLogLevel;
}

+ (instancetype)sharedInstance {
    static AppLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AppLogger alloc] init];
    });
    return sharedInstance;
}

+ (instancetype)sharedInstanceWithLogLevel:(int)level {
    AppLogger *sharedInstance = [AppLogger sharedInstance];
    [sharedInstance setLevel:level];
    return sharedInstance;
}

+ (instancetype)sharedInstanceWithDefaultLogLevel {
    AppLogger *sharedInstance = [AppLogger sharedInstance];
    [sharedInstance setLevel:AppLoggerDefaultLogLevel];
    return sharedInstance;
}

- (id)initWithLoglevel:(int)level {
    // Info($"Init della classe AppLogger, livello di log {AppLogLevel}");
    // Level = AppLogLevel;
    return self;
}

- (void)debug:(NSString *)message {
//    NSLog(@"debug:%@", message);
    [self log:[NSString stringWithFormat:@"[D] %@", message]
            withMessageLevel:AppLogLevel_DEBUG];
};

- (void)info:(NSString *)message {
//    NSLog(@"info:%@", message);
    [self log:[NSString stringWithFormat:@"[I] %@", message]
            withMessageLevel:AppLogLevel_INFO];
};

- (void)error:(NSString *)message {
//    NSLog(@"error:%@", message);
    [self log:[NSString stringWithFormat:@"[E] %@", message]
            withMessageLevel:AppLogLevel_ERROR];
};

- (void)log:(NSString *)message withMessageLevel:(AppLogLevel)messageLevel {
//    NSLog(@"  log:%@ withMessageLevel:%ld", message, messageLevel);
//    NSLog(@"[self level]:%ld", [self level]);
//    NSLog(@"messageLevel:%ld", messageLevel);
//    NSLog(@"[self level]:%ld > 0 && [self level]:%ld <= messageLevel:%lu) = %d", [self level], [self level], messageLevel, ([self level] > 0 && [self level] <= messageLevel));
    if ([self level] > 0 && [self level] <= messageLevel) {
//        NSLog(@"    ->  YES");
        [self writeToLogFile: message];
    }
};

- (void)writeToLogFile:(NSString *)message {
    NSDate *date;
    NSDateFormatter *dateFormatter;
    NSFileManager *fileManager;
    NSString *currentDate;
    NSString *logFilePath;
    NSString *timestamp;
    NSString *timestampedMessage;

    date = [NSDate date];
    dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"YYYY-MM-dd"];
    currentDate = [dateFormatter stringFromDate:date];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    timestamp = [dateFormatter stringFromDate:date];
    logFilePath = [NSString stringWithFormat:@"%@/.CIEPKI/CIEID_%@.log",
                                                        NSHomeDirectory(),
                                                        currentDate];

    timestampedMessage = [NSString stringWithFormat:@"%@    %@", timestamp, message];
    NSLog(@"writeToLogFile:    logFilePath:%@    message:%@", logFilePath, timestampedMessage);
    @try {
        // [timestampedMessage writeToFile:logFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        FILE *fp = fopen([logFilePath UTF8String], "a+");
        if(fp == NULL) {
            NSLog(@"Non posso aprire il file di log");
            return;
        }
        fprintf(fp, "%s\n", [timestampedMessage UTF8String]);
        fclose(fp);
    } @catch (NSException *exception) {
        NSLog( @"Exception: name:%@, reason:%@, message:%@", [exception name], [exception reason], timestampedMessage);
    }
}

@end
