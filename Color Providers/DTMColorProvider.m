//
//  ColorProvider.m
//  DTMHeatMapExample
//
//  Created by Bryan Oltman on 1/8/15.
//  Copyright (c) 2015 Dataminr. All rights reserved.
//

#import "DTMColorProvider.h"
#import <AHEasing/easing.h>

@implementation DTMColorProvider

- (void)colorForValue:(double)value
                  red:(CGFloat *)red
                green:(CGFloat *)green
                 blue:(CGFloat *)blue
                alpha:(CGFloat *)alpha
{
    value = MIN(1, MAX(0, value));
    //value = CubicEaseOut(value);

    /*
    NSArray *colors = @[
                        @[@(73), @(113), @(71)],
                        @[@(73), @(113), @(71)],
                        @[@(33), @(92), @(32)],
                        @[@(34), @(140), @(62)],
                        @[@(39), @(223), @(36)],
                        ];
     
     */

    NSArray *colors = @[
                        @[@(38), @(210), @(35)],
                        @[@(38), @(210), @(35)],
                        @[@(51), @(232), @(136)],
                        @[@(14), @(226), @(10)],
                        @[@(32), @(244), @(21)],
                        ];

    NSArray *points = @[
                        @(0.0),
                        @(0.2),
                        @(0.4),
                        @(0.8),
                        @(1.0),
                        ];

    NSArray *opacities = @[
                           @(0.0),
                           @(0.8),
                           @(1),
                           @(1),
                           @(1),
                           ];

    // getting index for low
    int index = 0;
    while (index < points.count && [[points objectAtIndex:index] doubleValue] < value) {
        index++;
    }
    index--;

    // getting points
    double pLow = [[points objectAtIndex:index] doubleValue];
    double pHight = [[points objectAtIndex:index+1] doubleValue];

    // getting colors
    NSArray *color1 = [colors objectAtIndex:index];
    NSArray *color2 = [colors objectAtIndex:index+1];

    // getting color ratios
    double color2Ratio = (value - pLow) / (pHight - pLow);
    double color1Ratio = 1 - color2Ratio;

    double opacity = ([[opacities objectAtIndex:index] doubleValue] * color1Ratio) +
                     ([[opacities objectAtIndex:index+1] doubleValue] * color2Ratio);

    *red = ([[color1 objectAtIndex:0] doubleValue] * color1Ratio) + ([[color2 objectAtIndex:0] doubleValue] * color2Ratio);
    *green = ([[color1 objectAtIndex:1] doubleValue] * color1Ratio) + ([[color2 objectAtIndex:1] doubleValue] * color2Ratio);
    *blue = ([[color1 objectAtIndex:2] doubleValue] * color1Ratio) + ([[color2 objectAtIndex:2] doubleValue] * color2Ratio);

    *red *= opacity;
    *green *= opacity;
    *blue *= opacity;
    *alpha = opacity * 255.0;

}

@end
