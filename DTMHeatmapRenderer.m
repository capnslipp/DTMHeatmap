//
//  DTMHeatmapRenderer.m
//  HeatMapTest
//
//  Created by Bryan Oltman on 1/6/15.
//  Copyright (c) 2015 Dataminr. All rights reserved.
//

#import "DTMHeatmapRenderer.h"
#import "DTMColorProvider.h"
#import "easing.h"

// This sets the spread of the heat from each map point (in screen pts.)
//static const NSInteger kSBHeatRadiusInPoints = 350;
static const NSInteger kSBHeatRadiusInPoints = 350;

@interface DTMHeatmapRenderer ()
@property (nonatomic, readonly) float *scaleMatrix;
@end

@implementation DTMHeatmapRenderer

- (id)initWithOverlay:(id <MKOverlay>)overlay
{
    if (self = [super initWithOverlay:overlay]) {
        _scaleMatrix = malloc(2 * kSBHeatRadiusInPoints * 2 * kSBHeatRadiusInPoints * sizeof(float));
        [self populateScaleMatrix];
    }
    
    return self;
}

- (void)dealloc
{
    free(_scaleMatrix);
}

- (void)populateScaleMatrix
{
    for (int i = 0; i < 2 * kSBHeatRadiusInPoints; i++) {
        for (int j = 0; j < 2 * kSBHeatRadiusInPoints; j++) {
            float distance = sqrt((i - kSBHeatRadiusInPoints) * (i - kSBHeatRadiusInPoints) + (j - kSBHeatRadiusInPoints) * (j - kSBHeatRadiusInPoints));
            float scaleFactor = 1 - distance / kSBHeatRadiusInPoints;
            if (scaleFactor < 0) {
                scaleFactor = 0;
            } else if (scaleFactor > 1) {
                scaleFactor = 1;
            }
            
            _scaleMatrix[j * 2 * kSBHeatRadiusInPoints + i] = scaleFactor;
        }
    }
}

- (void)drawMapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale
          inContext:(CGContextRef)context
{

    double scaleFix = 1 - zoomScale/0.5;
    if (scaleFix > 1) {
        scaleFix = 1;
    }

    if (scaleFix >= 0.999) {
        scaleFix *= 0.97;
    } else if (scaleFix >= 0.998) {
        scaleFix *= 0.98;
    } else {
        scaleFix *= 0.99;
    }


    CGRect usRect = [self rectForMapRect:mapRect]; //rect in user space coordinates (NOTE: not in screen points)
    //MKMapRect visibleRect = [self.overlay boundingMapRect];
    //MKMapRect mapIntersect = MKMapRectIntersection(mapRect, visibleRect);
    //CGRect usIntersect = [self rectForMapRect:mapIntersect]; //rect in user space coordinates (NOTE: not in screen points)
    CGRect usIntersect = usRect;

    int columns = ceil(CGRectGetWidth(usRect) * zoomScale);
    int rows = ceil(CGRectGetHeight(usRect) * zoomScale);
    int arrayLen = columns * rows;

    // allocate an array matching the screen point size of the rect
    float *pointValues = calloc(arrayLen, sizeof(float));

    if (!pointValues) {
        return;
    }

    // pad out the mapRect with the radius on all sides.
    // we care about points that are not in (but close to) this rect
    CGRect paddedRect = [self rectForMapRect:mapRect];
    paddedRect.origin.x -= kSBHeatRadiusInPoints / zoomScale;
    paddedRect.origin.y -= kSBHeatRadiusInPoints / zoomScale;
    paddedRect.size.width += 2 * kSBHeatRadiusInPoints / zoomScale;
    paddedRect.size.height += 2 * kSBHeatRadiusInPoints / zoomScale;
    MKMapRect paddedMapRect = [self mapRectForRect:paddedRect];

    // Get the dictionary of values out of the model for this mapRect and zoomScale.
    DTMHeatmap *hm = (DTMHeatmap *)self.overlay;
    NSDictionary *heat = [hm mapPointsWithHeatInMapRect:paddedMapRect
                                                atScale:zoomScale];

    for (NSValue *key in heat) {
        // convert key to mapPoint
        MKMapPoint mapPoint;
        [key getValue:&mapPoint];
        double value = [[heat objectForKey:key] doubleValue];

        // figure out the correspoinding array index
        CGPoint usPoint = [self pointForMapPoint:mapPoint];

        CGPoint matrixCoord = CGPointMake((usPoint.x - usRect.origin.x) * zoomScale + 1,
                                          (usPoint.y - usRect.origin.y) * zoomScale + 1);

        if (value != 0 && !isnan(value)) { // don't bother with 0 or NaN
            // just looping through the indices with values
            NSInteger newRadius = kSBHeatRadiusInPoints * (1-scaleFix);
            if (newRadius > kSBHeatRadiusInPoints) {
                newRadius = kSBHeatRadiusInPoints;
            }
            NSInteger excess = kSBHeatRadiusInPoints - newRadius;
            // iterate through surrounding pixels and increase
            for (int i = 0; i < 2 * newRadius; i++) {
                for (int j = 0; j < 2 * newRadius; j++) {

                    // find the array index
                    int column = floor(matrixCoord.x - newRadius + i);
                    int row = floor(matrixCoord.y - newRadius + j);

                    // make sure this is a valid array index
                    if (row >= 0 && column >= 0 && row < rows && column < columns) {
                        int index = columns * row + column;
                        double m = _scaleMatrix[(j+excess) * 2 * kSBHeatRadiusInPoints + (i+excess)] - scaleFix;
                        m /= (1.0-(scaleFix));
                        if (m < 0) {
                            m = 0;
                            continue;
                        }
                        double addVal = value * m;
                        pointValues[index] += addVal;
                    }
                }
            }
        }
    }

    CGFloat red, green, blue, alpha;
    uint indexOrigin;
    
    unsigned int size = arrayLen * 4;
    unsigned char *rgba = (unsigned char *)calloc(size, sizeof(unsigned char));
    DTMColorProvider *colorProvider = [hm colorProvider];


    for (int i = 0; i < arrayLen; i++) {
        if (pointValues[i] != 0) {
            indexOrigin = 4 * i;
            [colorProvider colorForValue:pointValues[i]
                                     red:&red
                                   green:&green
                                    blue:&blue
                                   alpha:&alpha];

            rgba[indexOrigin] = red;
            rgba[indexOrigin + 1] = green;
            rgba[indexOrigin + 2] = blue;
            rgba[indexOrigin + 3] = alpha;
        }
    }

    /*
    int r = arc4random_uniform(255);
    for (int i = 0; i < arrayLen; i++) {
        indexOrigin = 4 * i;

        rgba[indexOrigin] = r;
        rgba[indexOrigin + 1] = r;
        rgba[indexOrigin + 2] = r;
        rgba[indexOrigin + 3] = 255;
    }
      */

    free(pointValues);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(rgba,
                                                       columns,
                                                       rows,
                                                       8, // bitsPerComponent
                                                       4 * columns, // bytesPerRow
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);


    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    UIImage *img = [UIImage imageWithCGImage:cgImage];
    UIGraphicsPushContext(context);
    //[img drawInRect:usIntersect];
    [img drawInRect:usIntersect blendMode:kCGBlendModeNormal alpha:0.5];
    UIGraphicsPopContext();

    CFRelease(cgImage);
    CFRelease(bitmapContext);
    CFRelease(colorSpace);
    free(rgba);
}

@end
