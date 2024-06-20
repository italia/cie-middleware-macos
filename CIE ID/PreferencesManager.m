#import "PreferencesManager.h"

@implementation PreferencesManager

-(id) init {
    return self;
};

+(instancetype) sharedInstance {
    static PreferencesManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PreferencesManager alloc] init];
    });
    return sharedInstance;
};

-(BOOL) runInBackground {
    return YES;
};

-(NSString *) getConfigKeyValue: (NSString *) configOptionName {
    NSString *configFilePath;
    configFilePath = [NSString stringWithFormat:@"%@/.CIEPKI/config", NSHomeDirectory()];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:configFilePath] == YES) {
        NSString *content = [NSString stringWithContentsOfFile:configFilePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *settings = [content componentsSeparatedByString:@"\n"];
        
        for(int i = 0; i < [settings count]; i++) {
            NSArray *parsedLine = [(NSString *)[settings objectAtIndex:i] componentsSeparatedByString:@"="];
            
            if([parsedLine count] == 2) {
                NSString *key = (NSString *)[parsedLine objectAtIndex: 0];
                NSString *value = (NSString *)[parsedLine objectAtIndex: 1];
                
                if([key isEqualToString:configOptionName])
                    return value;
            }
        }
    }
    
    return @"";
}

-(void) setConfigKeyValue: (NSString *) configOptionName : (NSString *) optionValue {
    NSString *configFilePath;
    NSString *configLines = @"";
    BOOL optionFound = NO;
    
    configFilePath = [NSString stringWithFormat:@"%@/.CIEPKI/config", NSHomeDirectory()];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:configFilePath] == YES) {
        
        NSString *content = [NSString stringWithContentsOfFile:configFilePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *settings = [content componentsSeparatedByString:@"\n"];
        
        for(int i = 0; i < [settings count]; i++) {
            NSArray *parsedLine = [(NSString *)[settings objectAtIndex:i] componentsSeparatedByString:@"="];
            
            if([parsedLine count] == 2) {
                NSString *key = (NSString *)[parsedLine objectAtIndex: 0];
                NSString *value = (NSString *)[parsedLine objectAtIndex: 1];
                
                if([key isEqualToString:configOptionName]) {
                    value = optionValue;
                    optionFound = YES;
                }
                
                configLines = [configLines stringByAppendingString:[NSString stringWithFormat:@"%@=%@\n", key, value]];
                NSLog(@"Key Config Option %@", key);
                NSLog(@"Key Value: %@", value);
                NSLog(@"ConfigLines: %@", configLines);
            }
        }
    }
    
    if(!optionFound) {
        configLines = [configLines stringByAppendingFormat:@"%@=%@\n", configOptionName, optionValue];
    }
    
    if ([configLines writeToFile:configFilePath atomically:NO encoding:NSUTF8StringEncoding error:nil] == NO) {
        NSString *message = @"Errore nel salvare il file di configurazione dei log";
        NSLog(message);
    }
}

@end
