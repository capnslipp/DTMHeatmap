//
//  ColorProvider.m
//  DTMHeatMapExample
//
//  Created by Bryan Oltman on 1/8/15.
//  Copyright (c) 2015 Dataminr. All rights reserved.
//

#import "DTMColorProvider.h"
#import <AHEasing/easing.h>

int pointCount = 4;

double colors[4][3] = {
    /*
    Simon Broström [2:55 PM]
    ‘rgba(119, 27, 189, 0)’,
    ‘rgba(18, 157, 218, 1)’,
    ‘rgba(0, 255, 201, 1)’,
    ‘rgba(106, 252, 156, 1)’,
    */
    {119, 27, 189},
    {18, 157, 218},
    {0, 255, 201},
    {106, 252, 156},
};

double points[4] = {0.0, 0.4, 0.6, 1.0};
double opacities[4] = {0.0, 1, 1, 1};

@implementation DTMColorProvider

- (void)colorForValue:(double)value
                  red:(CGFloat *)red
                green:(CGFloat *)green
                 blue:(CGFloat *)blue
                alpha:(CGFloat *)alpha
{
    value = MIN(1, MAX(0, value));
    if (value > 1.0) {
        value = 1.0;
    } else if (value < 0.0) {
        value = 0.0;
    }

    // getting index for low
    int index = 0;
    while (index < pointCount && points[index] < value) {
        index++;
    }
    index--;

    // getting points
    double pLow = points[index];
    double pHight = points[index+1];

    // getting color ratios
    double color2Ratio = (value - pLow) / (pHight - pLow);
    double color1Ratio = 1 - color2Ratio;

    double opacity = (opacities[index] * color1Ratio) + (opacities[index+1] * color2Ratio);

    *red = (colors[index][0] * color1Ratio) + (colors[index+1][0] * color2Ratio);
    *green = (colors[index][1] * color1Ratio) + (colors[index+1][1] * color2Ratio);
    *blue = (colors[index][2] * color1Ratio) + (colors[index+1][2] * color2Ratio);

    *red *= opacity;
    *green *= opacity;
    *blue *= opacity;
    *alpha = opacity * 255.0;
}

@end

