#import <opencv2/opencv.hpp>
#import <AppKit/AppKit.h>
#import <CoreImage/CoreImage.h>
#import "OpenCVWrapper.h"

@implementation OpenCVWrapper
+ (NSImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) return nil;

    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    const OSType fmt = CVPixelBufferGetPixelFormatType(pixelBuffer);
    size_t w = CVPixelBufferGetWidth(pixelBuffer);
    size_t h = CVPixelBufferGetHeight(pixelBuffer);

    NSImage *result = nil;

    if (fmt == kCVPixelFormatType_32BGRA) {
        void *base    = CVPixelBufferGetBaseAddress(pixelBuffer);
        size_t stride = CVPixelBufferGetBytesPerRow(pixelBuffer);

        cv::Mat bgra((int)h, (int)w, CV_8UC4, base, stride);
        cv::Mat bgr;
        cv::cvtColor(bgra, bgr, cv::COLOR_BGRA2BGR);

        cv::flip(bgr, bgr, 1);
        cv::Mat rgba;
        cv::cvtColor(bgr, rgba, cv::COLOR_BGR2RGBA);

        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
            initWithBitmapDataPlanes:NULL
            pixelsWide:rgba.cols
            pixelsHigh:rgba.rows
            bitsPerSample:8
            samplesPerPixel:4
            hasAlpha:YES
            isPlanar:NO
            colorSpaceName:NSCalibratedRGBColorSpace
            bitmapFormat:NSBitmapFormatAlphaNonpremultiplied
            bytesPerRow:(int)rgba.step
            bitsPerPixel:32];

        memcpy([rep bitmapData], rgba.data, rgba.total() * rgba.elemSize());

        NSImage *img = [[NSImage alloc] initWithSize:NSMakeSize(rgba.cols, rgba.rows)];
        [img addRepresentation:rep];
        result = img;
    } else {
        CIImage *ci = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        CIContext *ctx = [[CIContext alloc] init];
        CGImageRef cg = [ctx createCGImage:ci fromRect:CGRectMake(0,0,w,h)];
        result = [[NSImage alloc] initWithCGImage:cg size:NSMakeSize(w,h)];
        CGImageRelease(cg);
    }


    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    return result;
}
@end
