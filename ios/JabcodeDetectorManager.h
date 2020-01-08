
#import <UIKit/UIKit.h>
#include "jabcode.h"

NSMutableArray* findJabcodesInFrame(UIImage* image, CGPoint scale);

@interface JabcodeDetectorManager : NSObject
typedef void (^postRecognitionBlock)(NSArray *barcodes);

- (instancetype)init;
- (BOOL)isRealDetector;
- (void)setType:(id)json queue:(dispatch_queue_t)sessionQueue;
- (void)findBarcodesInFrame:(UIImage *)image
                     scaleX:(float)scaleX
                     scaleY:(float)scaleY
                  completed:(postRecognitionBlock)completed;
+ (NSDictionary *)constants;

@end
