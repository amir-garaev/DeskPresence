#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
@class NSImage; 

NS_ASSUME_NONNULL_BEGIN
@interface OpenCVWrapper : NSObject
+ (NSImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
    NS_SWIFT_NAME(image(from:));
@end
NS_ASSUME_NONNULL_END
