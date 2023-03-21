//
//  ColorProvider.m
//  DTMHeatMapExample
//
//  Created by Bryan Oltman on 1/8/15.
//  Copyright (c) 2015 Dataminr. All rights reserved.
//

#import "DTMColorProvider.h"

@implementation DTMColorProvider

- (void)colorForValue:(double)value
                  red:(CGFloat *)red
                green:(CGFloat *)green
                 blue:(CGFloat *)blue
                alpha:(CGFloat *)alpha
{
    static int maxVal = 255;
    static double maxOpacity = 0.7;

    value = MIN(1, MAX(0, value));
    value = sqrt(value);


    double a = value * 9;
    a = MIN(maxOpacity, MAX(0, a));

    static double p1 = 0.17;
    if (value < p1) {
        double w1 = value / p1;
        double w2 = 1 - w1;

        *red = (50 * w1) + (0 * w2);
        *green = (150 * w1) + (0 * w2);
        *blue = (50 * w1) + (120 * w2);
    } else {
        double w1 = (value-p1) / (1-p1);
        double w2 = 1 - w1;

        *red = (102 * w1) + (50 * w2);
        *green = (225 * w1) + (150 * w2);
        *blue = (0 * w1) + (50 * w2);
    }

    *alpha = a * maxVal;

}

@end
