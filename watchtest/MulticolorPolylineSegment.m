//
//  MulticolorPolylineSegment.m
//  MoonRunner
//
//  Created by Matt Luedke on 5/30/14.
//  Copyright (c) 2014 Matt Luedke. All rights reserved.
//

#import "MulticolorPolylineSegment.h"

@implementation MulticolorPolylineSegment
@synthesize color=_color;


-(UIColor*)color
{
    if (!_color) {
        _color = [UIColor greenColor];
    }
    return _color;
}

@end
