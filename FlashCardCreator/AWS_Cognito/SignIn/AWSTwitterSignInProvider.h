//
//  AWSTwitterSignInProvider.h


#import <Foundation/Foundation.h>
#import "AWSSignInProvider.h"

@interface AWSTwitterSignInProvider : NSObject <AWSSignInProvider>

+ (instancetype)sharedInstance;

@end
