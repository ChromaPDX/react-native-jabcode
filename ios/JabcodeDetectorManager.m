#import <CoreGraphics/CoreGraphics.h>

#import "JabcodeDetectorManager.h"
#import <React/RCTConvert.h>

@interface JabcodeDetectorManager ()
//@property(nonatomic, strong) JabcodeDetector *barcodeRecognizer;
@property(nonatomic, assign) float scaleX;
@property(nonatomic, assign) float scaleY;
@end

typedef enum { Jabcode8, Jabcode6, Jabcode4, Jabcode2 } JABCodeType;


jab_bitmap* createJabBitmap(UIImage * uiImage) {
    // First get the image into your data buffer
    CGImageRef image = [uiImage CGImage];
    NSUInteger width = CGImageGetWidth(image);
    NSUInteger height = CGImageGetHeight(image);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bitsPerComponent = CGImageGetBitsPerComponent(image);
    NSUInteger bitsPerPixel = CGImageGetBitsPerPixel(image);
    NSUInteger channel_count = bitsPerPixel / bitsPerComponent;
    NSUInteger bytesPerRow = (bitsPerPixel * width) / 8;
    
    size_t dataSize = height * width * channel_count;
    
    jab_bitmap *bitmap = (jab_bitmap *)calloc(1, sizeof(jab_bitmap) + dataSize);
    
    bitmap->width =  (jab_int32)width;
    bitmap->height = (jab_int32)height;
    

    bitmap->bits_per_channel = (jab_int32)bitsPerComponent;
    bitmap->bits_per_pixel = (jab_int32)bitsPerPixel;
    bitmap->channel_count = (jab_int32)channel_count;
    
    CGContextRef context = CGBitmapContextCreate(bitmap->pixel, width, height, bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGContextRelease(context);
    
    return bitmap;
}


NSDictionary * processBounds(CGRect bounds, CGPoint scale) {
    float width = bounds.size.width * scale.x;
    float height = bounds.size.height * scale.y;
    float originX = bounds.origin.x * scale.x;
    float originY = bounds.origin.y * scale.y;
    NSDictionary *boundsDict = @{
                                 @"size" : @{@"width" : @(width), @"height" : @(height)},
                                 @"origin" : @{@"x" : @(originX), @"y" : @(originY)}
                                 };
    return boundsDict;
}

NSMutableArray * processJabcodes(jab_data * data, CGPoint scale, UIImage* image) {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
    // Boundaries of a barcode in image
    CGSize size = [image size];
    NSDictionary *bounds = processBounds(CGRectMake(0, 0 , size.width, size.height), scale);
    [resultDict setObject:bounds forKey:@"bounds"];
    
    // TODO send points to javascript - implement on android at the same
    // Point[] corners = barcode.getCornerPoints();
    NSString *rawValue = [[NSString alloc] initWithBytes: data->data length: (NSUInteger)data->length encoding:NSUTF8StringEncoding];
    [resultDict setObject:rawValue forKey:@"dataRaw"];
    [resultDict setObject:rawValue forKey:@"data"];
    [result addObject:resultDict];
    
    return result;
}

NSException *jabError(NSString *reason){
    return [NSException
           exceptionWithName:@"JABCode"
           reason:reason
        userInfo:nil];
}

NSMutableArray* findJabcodesInFrame(UIImage* image, CGPoint scale){
    NSMutableArray *emptyResult = [[NSMutableArray alloc] init];
    jab_bitmap *bitmap = createJabBitmap(image);
    
    if (bitmap == NULL){
        return emptyResult;
    } else {
        // find and decode JABCode in the image
        jab_int32 decode_status;
        jab_decoded_symbol symbols[MAX_SYMBOL_NUMBER];
        jab_data *decoded_data = decodeJABCodeEx( bitmap, NORMAL_DECODE, &decode_status, symbols, MAX_SYMBOL_NUMBER);
        free(bitmap);
        if (decoded_data == NULL) {
            return emptyResult;
        }
        else {
            if (decode_status == 2) {
                 free(decoded_data);
                @throw jabError(@"JABCode only partly decoded. Some follower symbols have "
                                "not been decoded and are ignored.");
                 return emptyResult;
            } else {
                NSMutableArray* result = processJabcodes(decoded_data, scale, image);
                free(decoded_data);
                return result;
            }
        }
    }
}


@implementation JabcodeDetectorManager

- (instancetype)init {
    if (self = [super init]) {
//        @throw jabError(@"JabcodeDetectorManager");
    }
    return self;
}

- (BOOL)isRealDetector {
    return true;
}

+ (NSDictionary *)constants {
    return @{
             @"JABCODE_8" : @(Jabcode8),
             @"JABCODE_6" : @(Jabcode6),
             @"JABCODE_4" : @(Jabcode4),
             @"JABCODE_2" : @(Jabcode2),
             };
}

- (void)setType:(id)json queue:(dispatch_queue_t)sessionQueue {
    //  NSInteger requestedValue = [RCTConvert NSInteger:json];
    //  if (self.setOption != requestedValue) {
    //    if (sessionQueue) {
    //      dispatch_async(sessionQueue, ^{
    //      });
    //    }
    //  }
}


- (void)findBarcodesInFrame:(UIImage *)uiImage
                     scaleX:(float)scaleX
                     scaleY:(float)scaleY
                  completed:(void (^)(NSArray *result))completed {
    completed(findJabcodesInFrame(uiImage, CGPointMake(scaleX, scaleY)));
}


- (NSString *)getType:(int)type {
    NSString *barcodeType = @"UNKNOWN";
    switch (type) {
        default:
            barcodeType = @"Jabcode";
            break;
    }
    return barcodeType;
}

- (NSDictionary *)processBounds:(CGRect)bounds {
    float width = bounds.size.width * _scaleX;
    float height = bounds.size.height * _scaleY;
    float originX = bounds.origin.x * _scaleX;
    float originY = bounds.origin.y * _scaleY;
    NSDictionary *boundsDict = @{
                                 @"size" : @{@"width" : @(width), @"height" : @(height)},
                                 @"origin" : @{@"x" : @(originX), @"y" : @(originY)}
                                 };
    return boundsDict;
}
@end




